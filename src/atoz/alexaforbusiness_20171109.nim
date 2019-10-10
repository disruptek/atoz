
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Alexa For Business
## version: 2017-11-09
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Alexa for Business helps you use Alexa in your organization. Alexa for Business provides you with the tools to manage Alexa devices, enroll your users, and assign skills, at scale. You can build your own context-aware voice skills using the Alexa Skills Kit and the Alexa for Business API operations. You can also make these available as private skills for your organization. Alexa for Business makes it efficient to voice-enable your products and services, thus providing context-aware voice experiences for your customers. Device makers building with the Alexa Voice Service (AVS) can create fully integrated solutions, register their products with Alexa for Business, and manage them as shared devices in their organization. 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/a4b/
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "a4b.ap-northeast-1.amazonaws.com", "ap-southeast-1": "a4b.ap-southeast-1.amazonaws.com",
                           "us-west-2": "a4b.us-west-2.amazonaws.com",
                           "eu-west-2": "a4b.eu-west-2.amazonaws.com", "ap-northeast-3": "a4b.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "a4b.eu-central-1.amazonaws.com",
                           "us-east-2": "a4b.us-east-2.amazonaws.com",
                           "us-east-1": "a4b.us-east-1.amazonaws.com", "cn-northwest-1": "a4b.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "a4b.ap-south-1.amazonaws.com",
                           "eu-north-1": "a4b.eu-north-1.amazonaws.com", "ap-northeast-2": "a4b.ap-northeast-2.amazonaws.com",
                           "us-west-1": "a4b.us-west-1.amazonaws.com",
                           "us-gov-east-1": "a4b.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "a4b.eu-west-3.amazonaws.com",
                           "cn-north-1": "a4b.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "a4b.sa-east-1.amazonaws.com",
                           "eu-west-1": "a4b.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "a4b.us-gov-west-1.amazonaws.com", "ap-southeast-2": "a4b.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "a4b.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "a4b.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "a4b.ap-southeast-1.amazonaws.com",
      "us-west-2": "a4b.us-west-2.amazonaws.com",
      "eu-west-2": "a4b.eu-west-2.amazonaws.com",
      "ap-northeast-3": "a4b.ap-northeast-3.amazonaws.com",
      "eu-central-1": "a4b.eu-central-1.amazonaws.com",
      "us-east-2": "a4b.us-east-2.amazonaws.com",
      "us-east-1": "a4b.us-east-1.amazonaws.com",
      "cn-northwest-1": "a4b.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "a4b.ap-south-1.amazonaws.com",
      "eu-north-1": "a4b.eu-north-1.amazonaws.com",
      "ap-northeast-2": "a4b.ap-northeast-2.amazonaws.com",
      "us-west-1": "a4b.us-west-1.amazonaws.com",
      "us-gov-east-1": "a4b.us-gov-east-1.amazonaws.com",
      "eu-west-3": "a4b.eu-west-3.amazonaws.com",
      "cn-north-1": "a4b.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "a4b.sa-east-1.amazonaws.com",
      "eu-west-1": "a4b.eu-west-1.amazonaws.com",
      "us-gov-west-1": "a4b.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "a4b.ap-southeast-2.amazonaws.com",
      "ca-central-1": "a4b.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "alexaforbusiness"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_ApproveSkill_602803 = ref object of OpenApiRestCall_602466
proc url_ApproveSkill_602805(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ApproveSkill_602804(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a skill with the organization under the customer's AWS account. If a skill is private, the user implicitly accepts access to this skill during enablement.
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
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "AlexaForBusiness.ApproveSkill"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_ApproveSkill_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill with the organization under the customer's AWS account. If a skill is private, the user implicitly accepts access to this skill during enablement.
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_ApproveSkill_602803; body: JsonNode): Recallable =
  ## approveSkill
  ## Associates a skill with the organization under the customer's AWS account. If a skill is private, the user implicitly accepts access to this skill during enablement.
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var approveSkill* = Call_ApproveSkill_602803(name: "approveSkill",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ApproveSkill",
    validator: validate_ApproveSkill_602804, base: "/", url: url_ApproveSkill_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateContactWithAddressBook_603072 = ref object of OpenApiRestCall_602466
proc url_AssociateContactWithAddressBook_603074(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateContactWithAddressBook_603073(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a contact with a given address book.
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
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateContactWithAddressBook"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_AssociateContactWithAddressBook_603072;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a contact with a given address book.
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_AssociateContactWithAddressBook_603072; body: JsonNode): Recallable =
  ## associateContactWithAddressBook
  ## Associates a contact with a given address book.
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var associateContactWithAddressBook* = Call_AssociateContactWithAddressBook_603072(
    name: "associateContactWithAddressBook", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateContactWithAddressBook",
    validator: validate_AssociateContactWithAddressBook_603073, base: "/",
    url: url_AssociateContactWithAddressBook_603074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateDeviceWithNetworkProfile_603087 = ref object of OpenApiRestCall_602466
proc url_AssociateDeviceWithNetworkProfile_603089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateDeviceWithNetworkProfile_603088(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a device with the specified network profile.
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
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateDeviceWithNetworkProfile"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_AssociateDeviceWithNetworkProfile_603087;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a device with the specified network profile.
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_AssociateDeviceWithNetworkProfile_603087;
          body: JsonNode): Recallable =
  ## associateDeviceWithNetworkProfile
  ## Associates a device with the specified network profile.
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var associateDeviceWithNetworkProfile* = Call_AssociateDeviceWithNetworkProfile_603087(
    name: "associateDeviceWithNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateDeviceWithNetworkProfile",
    validator: validate_AssociateDeviceWithNetworkProfile_603088, base: "/",
    url: url_AssociateDeviceWithNetworkProfile_603089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateDeviceWithRoom_603102 = ref object of OpenApiRestCall_602466
proc url_AssociateDeviceWithRoom_603104(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateDeviceWithRoom_603103(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a device with a given room. This applies all the settings from the room profile to the device, and all the skills in any skill groups added to that room. This operation requires the device to be online, or else a manual sync is required. 
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
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateDeviceWithRoom"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_AssociateDeviceWithRoom_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a device with a given room. This applies all the settings from the room profile to the device, and all the skills in any skill groups added to that room. This operation requires the device to be online, or else a manual sync is required. 
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_AssociateDeviceWithRoom_603102; body: JsonNode): Recallable =
  ## associateDeviceWithRoom
  ## Associates a device with a given room. This applies all the settings from the room profile to the device, and all the skills in any skill groups added to that room. This operation requires the device to be online, or else a manual sync is required. 
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var associateDeviceWithRoom* = Call_AssociateDeviceWithRoom_603102(
    name: "associateDeviceWithRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateDeviceWithRoom",
    validator: validate_AssociateDeviceWithRoom_603103, base: "/",
    url: url_AssociateDeviceWithRoom_603104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillGroupWithRoom_603117 = ref object of OpenApiRestCall_602466
proc url_AssociateSkillGroupWithRoom_603119(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateSkillGroupWithRoom_603118(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a skill group with a given room. This enables all skills in the associated skill group on all devices in the room.
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
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillGroupWithRoom"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_AssociateSkillGroupWithRoom_603117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill group with a given room. This enables all skills in the associated skill group on all devices in the room.
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_AssociateSkillGroupWithRoom_603117; body: JsonNode): Recallable =
  ## associateSkillGroupWithRoom
  ## Associates a skill group with a given room. This enables all skills in the associated skill group on all devices in the room.
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var associateSkillGroupWithRoom* = Call_AssociateSkillGroupWithRoom_603117(
    name: "associateSkillGroupWithRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillGroupWithRoom",
    validator: validate_AssociateSkillGroupWithRoom_603118, base: "/",
    url: url_AssociateSkillGroupWithRoom_603119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillWithSkillGroup_603132 = ref object of OpenApiRestCall_602466
proc url_AssociateSkillWithSkillGroup_603134(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateSkillWithSkillGroup_603133(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a skill with a skill group.
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
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillWithSkillGroup"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_AssociateSkillWithSkillGroup_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill with a skill group.
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_AssociateSkillWithSkillGroup_603132; body: JsonNode): Recallable =
  ## associateSkillWithSkillGroup
  ## Associates a skill with a skill group.
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var associateSkillWithSkillGroup* = Call_AssociateSkillWithSkillGroup_603132(
    name: "associateSkillWithSkillGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillWithSkillGroup",
    validator: validate_AssociateSkillWithSkillGroup_603133, base: "/",
    url: url_AssociateSkillWithSkillGroup_603134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillWithUsers_603147 = ref object of OpenApiRestCall_602466
proc url_AssociateSkillWithUsers_603149(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateSkillWithUsers_603148(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Makes a private skill available for enrolled users to enable on their devices.
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
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillWithUsers"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_AssociateSkillWithUsers_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Makes a private skill available for enrolled users to enable on their devices.
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_AssociateSkillWithUsers_603147; body: JsonNode): Recallable =
  ## associateSkillWithUsers
  ## Makes a private skill available for enrolled users to enable on their devices.
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var associateSkillWithUsers* = Call_AssociateSkillWithUsers_603147(
    name: "associateSkillWithUsers", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillWithUsers",
    validator: validate_AssociateSkillWithUsers_603148, base: "/",
    url: url_AssociateSkillWithUsers_603149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAddressBook_603162 = ref object of OpenApiRestCall_602466
proc url_CreateAddressBook_603164(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAddressBook_603163(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates an address book with the specified details.
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
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateAddressBook"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_CreateAddressBook_603162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an address book with the specified details.
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_CreateAddressBook_603162; body: JsonNode): Recallable =
  ## createAddressBook
  ## Creates an address book with the specified details.
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var createAddressBook* = Call_CreateAddressBook_603162(name: "createAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateAddressBook",
    validator: validate_CreateAddressBook_603163, base: "/",
    url: url_CreateAddressBook_603164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBusinessReportSchedule_603177 = ref object of OpenApiRestCall_602466
proc url_CreateBusinessReportSchedule_603179(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateBusinessReportSchedule_603178(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a recurring schedule for usage reports to deliver to the specified S3 location with a specified daily or weekly interval.
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
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateBusinessReportSchedule"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_CreateBusinessReportSchedule_603177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a recurring schedule for usage reports to deliver to the specified S3 location with a specified daily or weekly interval.
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_CreateBusinessReportSchedule_603177; body: JsonNode): Recallable =
  ## createBusinessReportSchedule
  ## Creates a recurring schedule for usage reports to deliver to the specified S3 location with a specified daily or weekly interval.
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var createBusinessReportSchedule* = Call_CreateBusinessReportSchedule_603177(
    name: "createBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateBusinessReportSchedule",
    validator: validate_CreateBusinessReportSchedule_603178, base: "/",
    url: url_CreateBusinessReportSchedule_603179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConferenceProvider_603192 = ref object of OpenApiRestCall_602466
proc url_CreateConferenceProvider_603194(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConferenceProvider_603193(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds a new conference provider under the user's AWS account.
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
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateConferenceProvider"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_CreateConferenceProvider_603192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new conference provider under the user's AWS account.
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_CreateConferenceProvider_603192; body: JsonNode): Recallable =
  ## createConferenceProvider
  ## Adds a new conference provider under the user's AWS account.
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var createConferenceProvider* = Call_CreateConferenceProvider_603192(
    name: "createConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateConferenceProvider",
    validator: validate_CreateConferenceProvider_603193, base: "/",
    url: url_CreateConferenceProvider_603194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateContact_603207 = ref object of OpenApiRestCall_602466
proc url_CreateContact_603209(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateContact_603208(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a contact with the specified details.
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
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateContact"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_CreateContact_603207; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a contact with the specified details.
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_CreateContact_603207; body: JsonNode): Recallable =
  ## createContact
  ## Creates a contact with the specified details.
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var createContact* = Call_CreateContact_603207(name: "createContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateContact",
    validator: validate_CreateContact_603208, base: "/", url: url_CreateContact_603209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGatewayGroup_603222 = ref object of OpenApiRestCall_602466
proc url_CreateGatewayGroup_603224(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateGatewayGroup_603223(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates a gateway group with the specified details.
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
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateGatewayGroup"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_CreateGatewayGroup_603222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a gateway group with the specified details.
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_CreateGatewayGroup_603222; body: JsonNode): Recallable =
  ## createGatewayGroup
  ## Creates a gateway group with the specified details.
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var createGatewayGroup* = Call_CreateGatewayGroup_603222(
    name: "createGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateGatewayGroup",
    validator: validate_CreateGatewayGroup_603223, base: "/",
    url: url_CreateGatewayGroup_603224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_603237 = ref object of OpenApiRestCall_602466
proc url_CreateNetworkProfile_603239(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateNetworkProfile_603238(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a network profile with the specified details.
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
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603242 = header.getOrDefault("X-Amz-Target")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateNetworkProfile"))
  if valid_603242 != nil:
    section.add "X-Amz-Target", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Content-Sha256", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Algorithm")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Algorithm", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Credential")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Credential", valid_603247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_CreateNetworkProfile_603237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a network profile with the specified details.
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_CreateNetworkProfile_603237; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile with the specified details.
  ##   body: JObject (required)
  var body_603251 = newJObject()
  if body != nil:
    body_603251 = body
  result = call_603250.call(nil, nil, nil, nil, body_603251)

var createNetworkProfile* = Call_CreateNetworkProfile_603237(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_603238, base: "/",
    url: url_CreateNetworkProfile_603239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProfile_603252 = ref object of OpenApiRestCall_602466
proc url_CreateProfile_603254(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProfile_603253(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new room profile with the specified details.
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
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Security-Token")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Security-Token", valid_603256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603257 = header.getOrDefault("X-Amz-Target")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateProfile"))
  if valid_603257 != nil:
    section.add "X-Amz-Target", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Content-Sha256", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-SignedHeaders", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Credential")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Credential", valid_603262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603264: Call_CreateProfile_603252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new room profile with the specified details.
  ## 
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_CreateProfile_603252; body: JsonNode): Recallable =
  ## createProfile
  ## Creates a new room profile with the specified details.
  ##   body: JObject (required)
  var body_603266 = newJObject()
  if body != nil:
    body_603266 = body
  result = call_603265.call(nil, nil, nil, nil, body_603266)

var createProfile* = Call_CreateProfile_603252(name: "createProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateProfile",
    validator: validate_CreateProfile_603253, base: "/", url: url_CreateProfile_603254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoom_603267 = ref object of OpenApiRestCall_602466
proc url_CreateRoom_603269(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRoom_603268(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a room with the specified details.
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
  var valid_603270 = header.getOrDefault("X-Amz-Date")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Date", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603272 = header.getOrDefault("X-Amz-Target")
  valid_603272 = validateParameter(valid_603272, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateRoom"))
  if valid_603272 != nil:
    section.add "X-Amz-Target", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Content-Sha256", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Algorithm")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Algorithm", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_CreateRoom_603267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a room with the specified details.
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_CreateRoom_603267; body: JsonNode): Recallable =
  ## createRoom
  ## Creates a room with the specified details.
  ##   body: JObject (required)
  var body_603281 = newJObject()
  if body != nil:
    body_603281 = body
  result = call_603280.call(nil, nil, nil, nil, body_603281)

var createRoom* = Call_CreateRoom_603267(name: "createRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.CreateRoom",
                                      validator: validate_CreateRoom_603268,
                                      base: "/", url: url_CreateRoom_603269,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSkillGroup_603282 = ref object of OpenApiRestCall_602466
proc url_CreateSkillGroup_603284(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSkillGroup_603283(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a skill group with a specified name and description.
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
  var valid_603285 = header.getOrDefault("X-Amz-Date")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Date", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603287 = header.getOrDefault("X-Amz-Target")
  valid_603287 = validateParameter(valid_603287, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateSkillGroup"))
  if valid_603287 != nil:
    section.add "X-Amz-Target", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603294: Call_CreateSkillGroup_603282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a skill group with a specified name and description.
  ## 
  let valid = call_603294.validator(path, query, header, formData, body)
  let scheme = call_603294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603294.url(scheme.get, call_603294.host, call_603294.base,
                         call_603294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603294, url, valid)

proc call*(call_603295: Call_CreateSkillGroup_603282; body: JsonNode): Recallable =
  ## createSkillGroup
  ## Creates a skill group with a specified name and description.
  ##   body: JObject (required)
  var body_603296 = newJObject()
  if body != nil:
    body_603296 = body
  result = call_603295.call(nil, nil, nil, nil, body_603296)

var createSkillGroup* = Call_CreateSkillGroup_603282(name: "createSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateSkillGroup",
    validator: validate_CreateSkillGroup_603283, base: "/",
    url: url_CreateSkillGroup_603284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_603297 = ref object of OpenApiRestCall_602466
proc url_CreateUser_603299(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUser_603298(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a user.
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
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603302 = header.getOrDefault("X-Amz-Target")
  valid_603302 = validateParameter(valid_603302, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateUser"))
  if valid_603302 != nil:
    section.add "X-Amz-Target", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Content-Sha256", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Algorithm")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Algorithm", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Signature")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Signature", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-SignedHeaders", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Credential")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Credential", valid_603307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_CreateUser_603297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user.
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_CreateUser_603297; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user.
  ##   body: JObject (required)
  var body_603311 = newJObject()
  if body != nil:
    body_603311 = body
  result = call_603310.call(nil, nil, nil, nil, body_603311)

var createUser* = Call_CreateUser_603297(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.CreateUser",
                                      validator: validate_CreateUser_603298,
                                      base: "/", url: url_CreateUser_603299,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAddressBook_603312 = ref object of OpenApiRestCall_602466
proc url_DeleteAddressBook_603314(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteAddressBook_603313(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes an address book by the address book ARN.
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
  var valid_603315 = header.getOrDefault("X-Amz-Date")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Date", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603317 = header.getOrDefault("X-Amz-Target")
  valid_603317 = validateParameter(valid_603317, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteAddressBook"))
  if valid_603317 != nil:
    section.add "X-Amz-Target", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Content-Sha256", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Algorithm")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Algorithm", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Credential")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Credential", valid_603322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603324: Call_DeleteAddressBook_603312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an address book by the address book ARN.
  ## 
  let valid = call_603324.validator(path, query, header, formData, body)
  let scheme = call_603324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603324.url(scheme.get, call_603324.host, call_603324.base,
                         call_603324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603324, url, valid)

proc call*(call_603325: Call_DeleteAddressBook_603312; body: JsonNode): Recallable =
  ## deleteAddressBook
  ## Deletes an address book by the address book ARN.
  ##   body: JObject (required)
  var body_603326 = newJObject()
  if body != nil:
    body_603326 = body
  result = call_603325.call(nil, nil, nil, nil, body_603326)

var deleteAddressBook* = Call_DeleteAddressBook_603312(name: "deleteAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteAddressBook",
    validator: validate_DeleteAddressBook_603313, base: "/",
    url: url_DeleteAddressBook_603314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBusinessReportSchedule_603327 = ref object of OpenApiRestCall_602466
proc url_DeleteBusinessReportSchedule_603329(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteBusinessReportSchedule_603328(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the recurring report delivery schedule with the specified schedule ARN.
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
  var valid_603330 = header.getOrDefault("X-Amz-Date")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Date", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603332 = header.getOrDefault("X-Amz-Target")
  valid_603332 = validateParameter(valid_603332, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteBusinessReportSchedule"))
  if valid_603332 != nil:
    section.add "X-Amz-Target", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Content-Sha256", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Algorithm")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Algorithm", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Signature")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Signature", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-SignedHeaders", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Credential")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Credential", valid_603337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_DeleteBusinessReportSchedule_603327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the recurring report delivery schedule with the specified schedule ARN.
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_DeleteBusinessReportSchedule_603327; body: JsonNode): Recallable =
  ## deleteBusinessReportSchedule
  ## Deletes the recurring report delivery schedule with the specified schedule ARN.
  ##   body: JObject (required)
  var body_603341 = newJObject()
  if body != nil:
    body_603341 = body
  result = call_603340.call(nil, nil, nil, nil, body_603341)

var deleteBusinessReportSchedule* = Call_DeleteBusinessReportSchedule_603327(
    name: "deleteBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteBusinessReportSchedule",
    validator: validate_DeleteBusinessReportSchedule_603328, base: "/",
    url: url_DeleteBusinessReportSchedule_603329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConferenceProvider_603342 = ref object of OpenApiRestCall_602466
proc url_DeleteConferenceProvider_603344(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteConferenceProvider_603343(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a conference provider.
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
  var valid_603345 = header.getOrDefault("X-Amz-Date")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Date", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Security-Token")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Security-Token", valid_603346
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603347 = header.getOrDefault("X-Amz-Target")
  valid_603347 = validateParameter(valid_603347, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteConferenceProvider"))
  if valid_603347 != nil:
    section.add "X-Amz-Target", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Content-Sha256", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Algorithm")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Algorithm", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Signature")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Signature", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-SignedHeaders", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Credential")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Credential", valid_603352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603354: Call_DeleteConferenceProvider_603342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a conference provider.
  ## 
  let valid = call_603354.validator(path, query, header, formData, body)
  let scheme = call_603354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603354.url(scheme.get, call_603354.host, call_603354.base,
                         call_603354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603354, url, valid)

proc call*(call_603355: Call_DeleteConferenceProvider_603342; body: JsonNode): Recallable =
  ## deleteConferenceProvider
  ## Deletes a conference provider.
  ##   body: JObject (required)
  var body_603356 = newJObject()
  if body != nil:
    body_603356 = body
  result = call_603355.call(nil, nil, nil, nil, body_603356)

var deleteConferenceProvider* = Call_DeleteConferenceProvider_603342(
    name: "deleteConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteConferenceProvider",
    validator: validate_DeleteConferenceProvider_603343, base: "/",
    url: url_DeleteConferenceProvider_603344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteContact_603357 = ref object of OpenApiRestCall_602466
proc url_DeleteContact_603359(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteContact_603358(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a contact by the contact ARN.
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
  var valid_603360 = header.getOrDefault("X-Amz-Date")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Date", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Security-Token")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Security-Token", valid_603361
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603362 = header.getOrDefault("X-Amz-Target")
  valid_603362 = validateParameter(valid_603362, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteContact"))
  if valid_603362 != nil:
    section.add "X-Amz-Target", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Content-Sha256", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Algorithm")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Algorithm", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Signature")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Signature", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-SignedHeaders", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Credential")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Credential", valid_603367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603369: Call_DeleteContact_603357; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a contact by the contact ARN.
  ## 
  let valid = call_603369.validator(path, query, header, formData, body)
  let scheme = call_603369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603369.url(scheme.get, call_603369.host, call_603369.base,
                         call_603369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603369, url, valid)

proc call*(call_603370: Call_DeleteContact_603357; body: JsonNode): Recallable =
  ## deleteContact
  ## Deletes a contact by the contact ARN.
  ##   body: JObject (required)
  var body_603371 = newJObject()
  if body != nil:
    body_603371 = body
  result = call_603370.call(nil, nil, nil, nil, body_603371)

var deleteContact* = Call_DeleteContact_603357(name: "deleteContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteContact",
    validator: validate_DeleteContact_603358, base: "/", url: url_DeleteContact_603359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevice_603372 = ref object of OpenApiRestCall_602466
proc url_DeleteDevice_603374(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDevice_603373(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a device from Alexa For Business.
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
  var valid_603375 = header.getOrDefault("X-Amz-Date")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Date", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Security-Token")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Security-Token", valid_603376
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603377 = header.getOrDefault("X-Amz-Target")
  valid_603377 = validateParameter(valid_603377, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteDevice"))
  if valid_603377 != nil:
    section.add "X-Amz-Target", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Content-Sha256", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Algorithm")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Algorithm", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Signature")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Signature", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-SignedHeaders", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Credential")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Credential", valid_603382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603384: Call_DeleteDevice_603372; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a device from Alexa For Business.
  ## 
  let valid = call_603384.validator(path, query, header, formData, body)
  let scheme = call_603384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603384.url(scheme.get, call_603384.host, call_603384.base,
                         call_603384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603384, url, valid)

proc call*(call_603385: Call_DeleteDevice_603372; body: JsonNode): Recallable =
  ## deleteDevice
  ## Removes a device from Alexa For Business.
  ##   body: JObject (required)
  var body_603386 = newJObject()
  if body != nil:
    body_603386 = body
  result = call_603385.call(nil, nil, nil, nil, body_603386)

var deleteDevice* = Call_DeleteDevice_603372(name: "deleteDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteDevice",
    validator: validate_DeleteDevice_603373, base: "/", url: url_DeleteDevice_603374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceUsageData_603387 = ref object of OpenApiRestCall_602466
proc url_DeleteDeviceUsageData_603389(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDeviceUsageData_603388(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## When this action is called for a specified shared device, it allows authorized users to delete the device's entire previous history of voice input data and associated response data. This action can be called once every 24 hours for a specific shared device.
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
  var valid_603390 = header.getOrDefault("X-Amz-Date")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Date", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Security-Token")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Security-Token", valid_603391
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603392 = header.getOrDefault("X-Amz-Target")
  valid_603392 = validateParameter(valid_603392, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteDeviceUsageData"))
  if valid_603392 != nil:
    section.add "X-Amz-Target", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Content-Sha256", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Algorithm")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Algorithm", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Signature")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Signature", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-SignedHeaders", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Credential")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Credential", valid_603397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603399: Call_DeleteDeviceUsageData_603387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## When this action is called for a specified shared device, it allows authorized users to delete the device's entire previous history of voice input data and associated response data. This action can be called once every 24 hours for a specific shared device.
  ## 
  let valid = call_603399.validator(path, query, header, formData, body)
  let scheme = call_603399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603399.url(scheme.get, call_603399.host, call_603399.base,
                         call_603399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603399, url, valid)

proc call*(call_603400: Call_DeleteDeviceUsageData_603387; body: JsonNode): Recallable =
  ## deleteDeviceUsageData
  ## When this action is called for a specified shared device, it allows authorized users to delete the device's entire previous history of voice input data and associated response data. This action can be called once every 24 hours for a specific shared device.
  ##   body: JObject (required)
  var body_603401 = newJObject()
  if body != nil:
    body_603401 = body
  result = call_603400.call(nil, nil, nil, nil, body_603401)

var deleteDeviceUsageData* = Call_DeleteDeviceUsageData_603387(
    name: "deleteDeviceUsageData", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteDeviceUsageData",
    validator: validate_DeleteDeviceUsageData_603388, base: "/",
    url: url_DeleteDeviceUsageData_603389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayGroup_603402 = ref object of OpenApiRestCall_602466
proc url_DeleteGatewayGroup_603404(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteGatewayGroup_603403(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a gateway group.
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
  var valid_603405 = header.getOrDefault("X-Amz-Date")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Date", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Security-Token")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Security-Token", valid_603406
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603407 = header.getOrDefault("X-Amz-Target")
  valid_603407 = validateParameter(valid_603407, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteGatewayGroup"))
  if valid_603407 != nil:
    section.add "X-Amz-Target", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Content-Sha256", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Algorithm")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Algorithm", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Signature")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Signature", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-SignedHeaders", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Credential")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Credential", valid_603412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603414: Call_DeleteGatewayGroup_603402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a gateway group.
  ## 
  let valid = call_603414.validator(path, query, header, formData, body)
  let scheme = call_603414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603414.url(scheme.get, call_603414.host, call_603414.base,
                         call_603414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603414, url, valid)

proc call*(call_603415: Call_DeleteGatewayGroup_603402; body: JsonNode): Recallable =
  ## deleteGatewayGroup
  ## Deletes a gateway group.
  ##   body: JObject (required)
  var body_603416 = newJObject()
  if body != nil:
    body_603416 = body
  result = call_603415.call(nil, nil, nil, nil, body_603416)

var deleteGatewayGroup* = Call_DeleteGatewayGroup_603402(
    name: "deleteGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteGatewayGroup",
    validator: validate_DeleteGatewayGroup_603403, base: "/",
    url: url_DeleteGatewayGroup_603404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_603417 = ref object of OpenApiRestCall_602466
proc url_DeleteNetworkProfile_603419(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteNetworkProfile_603418(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a network profile by the network profile ARN.
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
  var valid_603420 = header.getOrDefault("X-Amz-Date")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Date", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Security-Token")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Security-Token", valid_603421
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603422 = header.getOrDefault("X-Amz-Target")
  valid_603422 = validateParameter(valid_603422, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteNetworkProfile"))
  if valid_603422 != nil:
    section.add "X-Amz-Target", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Content-Sha256", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Algorithm")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Algorithm", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Signature")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Signature", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-SignedHeaders", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Credential")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Credential", valid_603427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603429: Call_DeleteNetworkProfile_603417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a network profile by the network profile ARN.
  ## 
  let valid = call_603429.validator(path, query, header, formData, body)
  let scheme = call_603429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603429.url(scheme.get, call_603429.host, call_603429.base,
                         call_603429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603429, url, valid)

proc call*(call_603430: Call_DeleteNetworkProfile_603417; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile by the network profile ARN.
  ##   body: JObject (required)
  var body_603431 = newJObject()
  if body != nil:
    body_603431 = body
  result = call_603430.call(nil, nil, nil, nil, body_603431)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_603417(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_603418, base: "/",
    url: url_DeleteNetworkProfile_603419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProfile_603432 = ref object of OpenApiRestCall_602466
proc url_DeleteProfile_603434(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteProfile_603433(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a room profile by the profile ARN.
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
  var valid_603435 = header.getOrDefault("X-Amz-Date")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Date", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Security-Token")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Security-Token", valid_603436
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603437 = header.getOrDefault("X-Amz-Target")
  valid_603437 = validateParameter(valid_603437, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteProfile"))
  if valid_603437 != nil:
    section.add "X-Amz-Target", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Content-Sha256", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Algorithm")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Algorithm", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Signature")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Signature", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-SignedHeaders", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Credential")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Credential", valid_603442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603444: Call_DeleteProfile_603432; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a room profile by the profile ARN.
  ## 
  let valid = call_603444.validator(path, query, header, formData, body)
  let scheme = call_603444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603444.url(scheme.get, call_603444.host, call_603444.base,
                         call_603444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603444, url, valid)

proc call*(call_603445: Call_DeleteProfile_603432; body: JsonNode): Recallable =
  ## deleteProfile
  ## Deletes a room profile by the profile ARN.
  ##   body: JObject (required)
  var body_603446 = newJObject()
  if body != nil:
    body_603446 = body
  result = call_603445.call(nil, nil, nil, nil, body_603446)

var deleteProfile* = Call_DeleteProfile_603432(name: "deleteProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteProfile",
    validator: validate_DeleteProfile_603433, base: "/", url: url_DeleteProfile_603434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoom_603447 = ref object of OpenApiRestCall_602466
proc url_DeleteRoom_603449(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRoom_603448(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a room by the room ARN.
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
  var valid_603450 = header.getOrDefault("X-Amz-Date")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Date", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Security-Token")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Security-Token", valid_603451
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603452 = header.getOrDefault("X-Amz-Target")
  valid_603452 = validateParameter(valid_603452, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteRoom"))
  if valid_603452 != nil:
    section.add "X-Amz-Target", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Content-Sha256", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Algorithm")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Algorithm", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Signature")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Signature", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-SignedHeaders", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Credential")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Credential", valid_603457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603459: Call_DeleteRoom_603447; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a room by the room ARN.
  ## 
  let valid = call_603459.validator(path, query, header, formData, body)
  let scheme = call_603459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603459.url(scheme.get, call_603459.host, call_603459.base,
                         call_603459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603459, url, valid)

proc call*(call_603460: Call_DeleteRoom_603447; body: JsonNode): Recallable =
  ## deleteRoom
  ## Deletes a room by the room ARN.
  ##   body: JObject (required)
  var body_603461 = newJObject()
  if body != nil:
    body_603461 = body
  result = call_603460.call(nil, nil, nil, nil, body_603461)

var deleteRoom* = Call_DeleteRoom_603447(name: "deleteRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DeleteRoom",
                                      validator: validate_DeleteRoom_603448,
                                      base: "/", url: url_DeleteRoom_603449,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoomSkillParameter_603462 = ref object of OpenApiRestCall_602466
proc url_DeleteRoomSkillParameter_603464(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRoomSkillParameter_603463(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes room skill parameter details by room, skill, and parameter key ID.
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
  var valid_603465 = header.getOrDefault("X-Amz-Date")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Date", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Security-Token")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Security-Token", valid_603466
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603467 = header.getOrDefault("X-Amz-Target")
  valid_603467 = validateParameter(valid_603467, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteRoomSkillParameter"))
  if valid_603467 != nil:
    section.add "X-Amz-Target", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Content-Sha256", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Algorithm")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Algorithm", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Signature")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Signature", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-SignedHeaders", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Credential")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Credential", valid_603472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603474: Call_DeleteRoomSkillParameter_603462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes room skill parameter details by room, skill, and parameter key ID.
  ## 
  let valid = call_603474.validator(path, query, header, formData, body)
  let scheme = call_603474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603474.url(scheme.get, call_603474.host, call_603474.base,
                         call_603474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603474, url, valid)

proc call*(call_603475: Call_DeleteRoomSkillParameter_603462; body: JsonNode): Recallable =
  ## deleteRoomSkillParameter
  ## Deletes room skill parameter details by room, skill, and parameter key ID.
  ##   body: JObject (required)
  var body_603476 = newJObject()
  if body != nil:
    body_603476 = body
  result = call_603475.call(nil, nil, nil, nil, body_603476)

var deleteRoomSkillParameter* = Call_DeleteRoomSkillParameter_603462(
    name: "deleteRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteRoomSkillParameter",
    validator: validate_DeleteRoomSkillParameter_603463, base: "/",
    url: url_DeleteRoomSkillParameter_603464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSkillAuthorization_603477 = ref object of OpenApiRestCall_602466
proc url_DeleteSkillAuthorization_603479(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSkillAuthorization_603478(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Unlinks a third-party account from a skill.
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
  var valid_603480 = header.getOrDefault("X-Amz-Date")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Date", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Security-Token")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Security-Token", valid_603481
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603482 = header.getOrDefault("X-Amz-Target")
  valid_603482 = validateParameter(valid_603482, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteSkillAuthorization"))
  if valid_603482 != nil:
    section.add "X-Amz-Target", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Content-Sha256", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Algorithm")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Algorithm", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Signature")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Signature", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-SignedHeaders", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Credential")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Credential", valid_603487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603489: Call_DeleteSkillAuthorization_603477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Unlinks a third-party account from a skill.
  ## 
  let valid = call_603489.validator(path, query, header, formData, body)
  let scheme = call_603489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603489.url(scheme.get, call_603489.host, call_603489.base,
                         call_603489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603489, url, valid)

proc call*(call_603490: Call_DeleteSkillAuthorization_603477; body: JsonNode): Recallable =
  ## deleteSkillAuthorization
  ## Unlinks a third-party account from a skill.
  ##   body: JObject (required)
  var body_603491 = newJObject()
  if body != nil:
    body_603491 = body
  result = call_603490.call(nil, nil, nil, nil, body_603491)

var deleteSkillAuthorization* = Call_DeleteSkillAuthorization_603477(
    name: "deleteSkillAuthorization", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteSkillAuthorization",
    validator: validate_DeleteSkillAuthorization_603478, base: "/",
    url: url_DeleteSkillAuthorization_603479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSkillGroup_603492 = ref object of OpenApiRestCall_602466
proc url_DeleteSkillGroup_603494(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSkillGroup_603493(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a skill group by skill group ARN.
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
  var valid_603495 = header.getOrDefault("X-Amz-Date")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Date", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Security-Token")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Security-Token", valid_603496
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603497 = header.getOrDefault("X-Amz-Target")
  valid_603497 = validateParameter(valid_603497, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteSkillGroup"))
  if valid_603497 != nil:
    section.add "X-Amz-Target", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Content-Sha256", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Algorithm")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Algorithm", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Signature")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Signature", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-SignedHeaders", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Credential")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Credential", valid_603502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603504: Call_DeleteSkillGroup_603492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a skill group by skill group ARN.
  ## 
  let valid = call_603504.validator(path, query, header, formData, body)
  let scheme = call_603504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603504.url(scheme.get, call_603504.host, call_603504.base,
                         call_603504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603504, url, valid)

proc call*(call_603505: Call_DeleteSkillGroup_603492; body: JsonNode): Recallable =
  ## deleteSkillGroup
  ## Deletes a skill group by skill group ARN.
  ##   body: JObject (required)
  var body_603506 = newJObject()
  if body != nil:
    body_603506 = body
  result = call_603505.call(nil, nil, nil, nil, body_603506)

var deleteSkillGroup* = Call_DeleteSkillGroup_603492(name: "deleteSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteSkillGroup",
    validator: validate_DeleteSkillGroup_603493, base: "/",
    url: url_DeleteSkillGroup_603494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_603507 = ref object of OpenApiRestCall_602466
proc url_DeleteUser_603509(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteUser_603508(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified user by user ARN and enrollment ARN.
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
  var valid_603510 = header.getOrDefault("X-Amz-Date")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Date", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Security-Token")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Security-Token", valid_603511
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603512 = header.getOrDefault("X-Amz-Target")
  valid_603512 = validateParameter(valid_603512, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteUser"))
  if valid_603512 != nil:
    section.add "X-Amz-Target", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Content-Sha256", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Algorithm")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Algorithm", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Signature")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Signature", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-SignedHeaders", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Credential")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Credential", valid_603517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603519: Call_DeleteUser_603507; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified user by user ARN and enrollment ARN.
  ## 
  let valid = call_603519.validator(path, query, header, formData, body)
  let scheme = call_603519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603519.url(scheme.get, call_603519.host, call_603519.base,
                         call_603519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603519, url, valid)

proc call*(call_603520: Call_DeleteUser_603507; body: JsonNode): Recallable =
  ## deleteUser
  ## Deletes a specified user by user ARN and enrollment ARN.
  ##   body: JObject (required)
  var body_603521 = newJObject()
  if body != nil:
    body_603521 = body
  result = call_603520.call(nil, nil, nil, nil, body_603521)

var deleteUser* = Call_DeleteUser_603507(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DeleteUser",
                                      validator: validate_DeleteUser_603508,
                                      base: "/", url: url_DeleteUser_603509,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateContactFromAddressBook_603522 = ref object of OpenApiRestCall_602466
proc url_DisassociateContactFromAddressBook_603524(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateContactFromAddressBook_603523(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates a contact from a given address book.
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
  var valid_603525 = header.getOrDefault("X-Amz-Date")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Date", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Security-Token")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Security-Token", valid_603526
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603527 = header.getOrDefault("X-Amz-Target")
  valid_603527 = validateParameter(valid_603527, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateContactFromAddressBook"))
  if valid_603527 != nil:
    section.add "X-Amz-Target", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Content-Sha256", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Algorithm")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Algorithm", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Signature")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Signature", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-SignedHeaders", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Credential")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Credential", valid_603532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603534: Call_DisassociateContactFromAddressBook_603522;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a contact from a given address book.
  ## 
  let valid = call_603534.validator(path, query, header, formData, body)
  let scheme = call_603534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603534.url(scheme.get, call_603534.host, call_603534.base,
                         call_603534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603534, url, valid)

proc call*(call_603535: Call_DisassociateContactFromAddressBook_603522;
          body: JsonNode): Recallable =
  ## disassociateContactFromAddressBook
  ## Disassociates a contact from a given address book.
  ##   body: JObject (required)
  var body_603536 = newJObject()
  if body != nil:
    body_603536 = body
  result = call_603535.call(nil, nil, nil, nil, body_603536)

var disassociateContactFromAddressBook* = Call_DisassociateContactFromAddressBook_603522(
    name: "disassociateContactFromAddressBook", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DisassociateContactFromAddressBook",
    validator: validate_DisassociateContactFromAddressBook_603523, base: "/",
    url: url_DisassociateContactFromAddressBook_603524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDeviceFromRoom_603537 = ref object of OpenApiRestCall_602466
proc url_DisassociateDeviceFromRoom_603539(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateDeviceFromRoom_603538(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates a device from its current room. The device continues to be connected to the Wi-Fi network and is still registered to the account. The device settings and skills are removed from the room.
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
  var valid_603540 = header.getOrDefault("X-Amz-Date")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Date", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Security-Token")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Security-Token", valid_603541
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603542 = header.getOrDefault("X-Amz-Target")
  valid_603542 = validateParameter(valid_603542, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateDeviceFromRoom"))
  if valid_603542 != nil:
    section.add "X-Amz-Target", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Content-Sha256", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Algorithm")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Algorithm", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Signature")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Signature", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-SignedHeaders", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Credential")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Credential", valid_603547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603549: Call_DisassociateDeviceFromRoom_603537; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a device from its current room. The device continues to be connected to the Wi-Fi network and is still registered to the account. The device settings and skills are removed from the room.
  ## 
  let valid = call_603549.validator(path, query, header, formData, body)
  let scheme = call_603549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603549.url(scheme.get, call_603549.host, call_603549.base,
                         call_603549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603549, url, valid)

proc call*(call_603550: Call_DisassociateDeviceFromRoom_603537; body: JsonNode): Recallable =
  ## disassociateDeviceFromRoom
  ## Disassociates a device from its current room. The device continues to be connected to the Wi-Fi network and is still registered to the account. The device settings and skills are removed from the room.
  ##   body: JObject (required)
  var body_603551 = newJObject()
  if body != nil:
    body_603551 = body
  result = call_603550.call(nil, nil, nil, nil, body_603551)

var disassociateDeviceFromRoom* = Call_DisassociateDeviceFromRoom_603537(
    name: "disassociateDeviceFromRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateDeviceFromRoom",
    validator: validate_DisassociateDeviceFromRoom_603538, base: "/",
    url: url_DisassociateDeviceFromRoom_603539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillFromSkillGroup_603552 = ref object of OpenApiRestCall_602466
proc url_DisassociateSkillFromSkillGroup_603554(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateSkillFromSkillGroup_603553(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates a skill from a skill group.
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
  var valid_603555 = header.getOrDefault("X-Amz-Date")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Date", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Security-Token")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Security-Token", valid_603556
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603557 = header.getOrDefault("X-Amz-Target")
  valid_603557 = validateParameter(valid_603557, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillFromSkillGroup"))
  if valid_603557 != nil:
    section.add "X-Amz-Target", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Content-Sha256", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Algorithm")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Algorithm", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Signature")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Signature", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-SignedHeaders", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Credential")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Credential", valid_603562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603564: Call_DisassociateSkillFromSkillGroup_603552;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a skill from a skill group.
  ## 
  let valid = call_603564.validator(path, query, header, formData, body)
  let scheme = call_603564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603564.url(scheme.get, call_603564.host, call_603564.base,
                         call_603564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603564, url, valid)

proc call*(call_603565: Call_DisassociateSkillFromSkillGroup_603552; body: JsonNode): Recallable =
  ## disassociateSkillFromSkillGroup
  ## Disassociates a skill from a skill group.
  ##   body: JObject (required)
  var body_603566 = newJObject()
  if body != nil:
    body_603566 = body
  result = call_603565.call(nil, nil, nil, nil, body_603566)

var disassociateSkillFromSkillGroup* = Call_DisassociateSkillFromSkillGroup_603552(
    name: "disassociateSkillFromSkillGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillFromSkillGroup",
    validator: validate_DisassociateSkillFromSkillGroup_603553, base: "/",
    url: url_DisassociateSkillFromSkillGroup_603554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillFromUsers_603567 = ref object of OpenApiRestCall_602466
proc url_DisassociateSkillFromUsers_603569(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateSkillFromUsers_603568(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Makes a private skill unavailable for enrolled users and prevents them from enabling it on their devices.
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
  var valid_603570 = header.getOrDefault("X-Amz-Date")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Date", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Security-Token")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Security-Token", valid_603571
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603572 = header.getOrDefault("X-Amz-Target")
  valid_603572 = validateParameter(valid_603572, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillFromUsers"))
  if valid_603572 != nil:
    section.add "X-Amz-Target", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Content-Sha256", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Algorithm")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Algorithm", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Signature")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Signature", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-SignedHeaders", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Credential")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Credential", valid_603577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603579: Call_DisassociateSkillFromUsers_603567; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Makes a private skill unavailable for enrolled users and prevents them from enabling it on their devices.
  ## 
  let valid = call_603579.validator(path, query, header, formData, body)
  let scheme = call_603579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603579.url(scheme.get, call_603579.host, call_603579.base,
                         call_603579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603579, url, valid)

proc call*(call_603580: Call_DisassociateSkillFromUsers_603567; body: JsonNode): Recallable =
  ## disassociateSkillFromUsers
  ## Makes a private skill unavailable for enrolled users and prevents them from enabling it on their devices.
  ##   body: JObject (required)
  var body_603581 = newJObject()
  if body != nil:
    body_603581 = body
  result = call_603580.call(nil, nil, nil, nil, body_603581)

var disassociateSkillFromUsers* = Call_DisassociateSkillFromUsers_603567(
    name: "disassociateSkillFromUsers", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillFromUsers",
    validator: validate_DisassociateSkillFromUsers_603568, base: "/",
    url: url_DisassociateSkillFromUsers_603569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillGroupFromRoom_603582 = ref object of OpenApiRestCall_602466
proc url_DisassociateSkillGroupFromRoom_603584(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateSkillGroupFromRoom_603583(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates a skill group from a specified room. This disables all skills in the skill group on all devices in the room.
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
  var valid_603585 = header.getOrDefault("X-Amz-Date")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Date", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Security-Token")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Security-Token", valid_603586
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603587 = header.getOrDefault("X-Amz-Target")
  valid_603587 = validateParameter(valid_603587, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillGroupFromRoom"))
  if valid_603587 != nil:
    section.add "X-Amz-Target", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Content-Sha256", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Algorithm")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Algorithm", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Signature")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Signature", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-SignedHeaders", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Credential")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Credential", valid_603592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603594: Call_DisassociateSkillGroupFromRoom_603582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a skill group from a specified room. This disables all skills in the skill group on all devices in the room.
  ## 
  let valid = call_603594.validator(path, query, header, formData, body)
  let scheme = call_603594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603594.url(scheme.get, call_603594.host, call_603594.base,
                         call_603594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603594, url, valid)

proc call*(call_603595: Call_DisassociateSkillGroupFromRoom_603582; body: JsonNode): Recallable =
  ## disassociateSkillGroupFromRoom
  ## Disassociates a skill group from a specified room. This disables all skills in the skill group on all devices in the room.
  ##   body: JObject (required)
  var body_603596 = newJObject()
  if body != nil:
    body_603596 = body
  result = call_603595.call(nil, nil, nil, nil, body_603596)

var disassociateSkillGroupFromRoom* = Call_DisassociateSkillGroupFromRoom_603582(
    name: "disassociateSkillGroupFromRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillGroupFromRoom",
    validator: validate_DisassociateSkillGroupFromRoom_603583, base: "/",
    url: url_DisassociateSkillGroupFromRoom_603584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgetSmartHomeAppliances_603597 = ref object of OpenApiRestCall_602466
proc url_ForgetSmartHomeAppliances_603599(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ForgetSmartHomeAppliances_603598(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Forgets smart home appliances associated to a room.
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
  var valid_603600 = header.getOrDefault("X-Amz-Date")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Date", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Security-Token")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Security-Token", valid_603601
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603602 = header.getOrDefault("X-Amz-Target")
  valid_603602 = validateParameter(valid_603602, JString, required = true, default = newJString(
      "AlexaForBusiness.ForgetSmartHomeAppliances"))
  if valid_603602 != nil:
    section.add "X-Amz-Target", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Content-Sha256", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Algorithm")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Algorithm", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Signature")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Signature", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-SignedHeaders", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Credential")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Credential", valid_603607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603609: Call_ForgetSmartHomeAppliances_603597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Forgets smart home appliances associated to a room.
  ## 
  let valid = call_603609.validator(path, query, header, formData, body)
  let scheme = call_603609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603609.url(scheme.get, call_603609.host, call_603609.base,
                         call_603609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603609, url, valid)

proc call*(call_603610: Call_ForgetSmartHomeAppliances_603597; body: JsonNode): Recallable =
  ## forgetSmartHomeAppliances
  ## Forgets smart home appliances associated to a room.
  ##   body: JObject (required)
  var body_603611 = newJObject()
  if body != nil:
    body_603611 = body
  result = call_603610.call(nil, nil, nil, nil, body_603611)

var forgetSmartHomeAppliances* = Call_ForgetSmartHomeAppliances_603597(
    name: "forgetSmartHomeAppliances", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ForgetSmartHomeAppliances",
    validator: validate_ForgetSmartHomeAppliances_603598, base: "/",
    url: url_ForgetSmartHomeAppliances_603599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddressBook_603612 = ref object of OpenApiRestCall_602466
proc url_GetAddressBook_603614(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddressBook_603613(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets address the book details by the address book ARN.
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
  var valid_603615 = header.getOrDefault("X-Amz-Date")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Date", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Security-Token")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Security-Token", valid_603616
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603617 = header.getOrDefault("X-Amz-Target")
  valid_603617 = validateParameter(valid_603617, JString, required = true, default = newJString(
      "AlexaForBusiness.GetAddressBook"))
  if valid_603617 != nil:
    section.add "X-Amz-Target", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Content-Sha256", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Algorithm")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Algorithm", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Signature")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Signature", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-SignedHeaders", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Credential")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Credential", valid_603622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603624: Call_GetAddressBook_603612; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets address the book details by the address book ARN.
  ## 
  let valid = call_603624.validator(path, query, header, formData, body)
  let scheme = call_603624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603624.url(scheme.get, call_603624.host, call_603624.base,
                         call_603624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603624, url, valid)

proc call*(call_603625: Call_GetAddressBook_603612; body: JsonNode): Recallable =
  ## getAddressBook
  ## Gets address the book details by the address book ARN.
  ##   body: JObject (required)
  var body_603626 = newJObject()
  if body != nil:
    body_603626 = body
  result = call_603625.call(nil, nil, nil, nil, body_603626)

var getAddressBook* = Call_GetAddressBook_603612(name: "getAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetAddressBook",
    validator: validate_GetAddressBook_603613, base: "/", url: url_GetAddressBook_603614,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConferencePreference_603627 = ref object of OpenApiRestCall_602466
proc url_GetConferencePreference_603629(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConferencePreference_603628(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the existing conference preferences.
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
  var valid_603630 = header.getOrDefault("X-Amz-Date")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Date", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Security-Token")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Security-Token", valid_603631
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603632 = header.getOrDefault("X-Amz-Target")
  valid_603632 = validateParameter(valid_603632, JString, required = true, default = newJString(
      "AlexaForBusiness.GetConferencePreference"))
  if valid_603632 != nil:
    section.add "X-Amz-Target", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Content-Sha256", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Algorithm")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Algorithm", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Signature")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Signature", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-SignedHeaders", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Credential")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Credential", valid_603637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603639: Call_GetConferencePreference_603627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the existing conference preferences.
  ## 
  let valid = call_603639.validator(path, query, header, formData, body)
  let scheme = call_603639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603639.url(scheme.get, call_603639.host, call_603639.base,
                         call_603639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603639, url, valid)

proc call*(call_603640: Call_GetConferencePreference_603627; body: JsonNode): Recallable =
  ## getConferencePreference
  ## Retrieves the existing conference preferences.
  ##   body: JObject (required)
  var body_603641 = newJObject()
  if body != nil:
    body_603641 = body
  result = call_603640.call(nil, nil, nil, nil, body_603641)

var getConferencePreference* = Call_GetConferencePreference_603627(
    name: "getConferencePreference", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetConferencePreference",
    validator: validate_GetConferencePreference_603628, base: "/",
    url: url_GetConferencePreference_603629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConferenceProvider_603642 = ref object of OpenApiRestCall_602466
proc url_GetConferenceProvider_603644(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConferenceProvider_603643(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets details about a specific conference provider.
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
  var valid_603645 = header.getOrDefault("X-Amz-Date")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Date", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Security-Token")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Security-Token", valid_603646
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603647 = header.getOrDefault("X-Amz-Target")
  valid_603647 = validateParameter(valid_603647, JString, required = true, default = newJString(
      "AlexaForBusiness.GetConferenceProvider"))
  if valid_603647 != nil:
    section.add "X-Amz-Target", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Content-Sha256", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Algorithm")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Algorithm", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Signature")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Signature", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-SignedHeaders", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Credential")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Credential", valid_603652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603654: Call_GetConferenceProvider_603642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a specific conference provider.
  ## 
  let valid = call_603654.validator(path, query, header, formData, body)
  let scheme = call_603654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603654.url(scheme.get, call_603654.host, call_603654.base,
                         call_603654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603654, url, valid)

proc call*(call_603655: Call_GetConferenceProvider_603642; body: JsonNode): Recallable =
  ## getConferenceProvider
  ## Gets details about a specific conference provider.
  ##   body: JObject (required)
  var body_603656 = newJObject()
  if body != nil:
    body_603656 = body
  result = call_603655.call(nil, nil, nil, nil, body_603656)

var getConferenceProvider* = Call_GetConferenceProvider_603642(
    name: "getConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetConferenceProvider",
    validator: validate_GetConferenceProvider_603643, base: "/",
    url: url_GetConferenceProvider_603644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContact_603657 = ref object of OpenApiRestCall_602466
proc url_GetContact_603659(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetContact_603658(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the contact details by the contact ARN.
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
  var valid_603660 = header.getOrDefault("X-Amz-Date")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Date", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Security-Token")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Security-Token", valid_603661
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603662 = header.getOrDefault("X-Amz-Target")
  valid_603662 = validateParameter(valid_603662, JString, required = true, default = newJString(
      "AlexaForBusiness.GetContact"))
  if valid_603662 != nil:
    section.add "X-Amz-Target", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Content-Sha256", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-Algorithm")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Algorithm", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Signature")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Signature", valid_603665
  var valid_603666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-SignedHeaders", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-Credential")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Credential", valid_603667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603669: Call_GetContact_603657; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contact details by the contact ARN.
  ## 
  let valid = call_603669.validator(path, query, header, formData, body)
  let scheme = call_603669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603669.url(scheme.get, call_603669.host, call_603669.base,
                         call_603669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603669, url, valid)

proc call*(call_603670: Call_GetContact_603657; body: JsonNode): Recallable =
  ## getContact
  ## Gets the contact details by the contact ARN.
  ##   body: JObject (required)
  var body_603671 = newJObject()
  if body != nil:
    body_603671 = body
  result = call_603670.call(nil, nil, nil, nil, body_603671)

var getContact* = Call_GetContact_603657(name: "getContact",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetContact",
                                      validator: validate_GetContact_603658,
                                      base: "/", url: url_GetContact_603659,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_603672 = ref object of OpenApiRestCall_602466
proc url_GetDevice_603674(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevice_603673(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the details of a device by device ARN.
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
  var valid_603675 = header.getOrDefault("X-Amz-Date")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Date", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Security-Token")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Security-Token", valid_603676
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603677 = header.getOrDefault("X-Amz-Target")
  valid_603677 = validateParameter(valid_603677, JString, required = true, default = newJString(
      "AlexaForBusiness.GetDevice"))
  if valid_603677 != nil:
    section.add "X-Amz-Target", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-Content-Sha256", valid_603678
  var valid_603679 = header.getOrDefault("X-Amz-Algorithm")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Algorithm", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-Signature")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Signature", valid_603680
  var valid_603681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "X-Amz-SignedHeaders", valid_603681
  var valid_603682 = header.getOrDefault("X-Amz-Credential")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Credential", valid_603682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603684: Call_GetDevice_603672; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details of a device by device ARN.
  ## 
  let valid = call_603684.validator(path, query, header, formData, body)
  let scheme = call_603684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603684.url(scheme.get, call_603684.host, call_603684.base,
                         call_603684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603684, url, valid)

proc call*(call_603685: Call_GetDevice_603672; body: JsonNode): Recallable =
  ## getDevice
  ## Gets the details of a device by device ARN.
  ##   body: JObject (required)
  var body_603686 = newJObject()
  if body != nil:
    body_603686 = body
  result = call_603685.call(nil, nil, nil, nil, body_603686)

var getDevice* = Call_GetDevice_603672(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetDevice",
                                    validator: validate_GetDevice_603673,
                                    base: "/", url: url_GetDevice_603674,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGateway_603687 = ref object of OpenApiRestCall_602466
proc url_GetGateway_603689(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGateway_603688(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the details of a gateway.
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
  var valid_603690 = header.getOrDefault("X-Amz-Date")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Date", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Security-Token")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Security-Token", valid_603691
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603692 = header.getOrDefault("X-Amz-Target")
  valid_603692 = validateParameter(valid_603692, JString, required = true, default = newJString(
      "AlexaForBusiness.GetGateway"))
  if valid_603692 != nil:
    section.add "X-Amz-Target", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Content-Sha256", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Algorithm")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Algorithm", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Signature")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Signature", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-SignedHeaders", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Credential")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Credential", valid_603697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603699: Call_GetGateway_603687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details of a gateway.
  ## 
  let valid = call_603699.validator(path, query, header, formData, body)
  let scheme = call_603699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603699.url(scheme.get, call_603699.host, call_603699.base,
                         call_603699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603699, url, valid)

proc call*(call_603700: Call_GetGateway_603687; body: JsonNode): Recallable =
  ## getGateway
  ## Retrieves the details of a gateway.
  ##   body: JObject (required)
  var body_603701 = newJObject()
  if body != nil:
    body_603701 = body
  result = call_603700.call(nil, nil, nil, nil, body_603701)

var getGateway* = Call_GetGateway_603687(name: "getGateway",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetGateway",
                                      validator: validate_GetGateway_603688,
                                      base: "/", url: url_GetGateway_603689,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayGroup_603702 = ref object of OpenApiRestCall_602466
proc url_GetGatewayGroup_603704(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGatewayGroup_603703(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves the details of a gateway group.
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
  var valid_603705 = header.getOrDefault("X-Amz-Date")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Date", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-Security-Token")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Security-Token", valid_603706
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603707 = header.getOrDefault("X-Amz-Target")
  valid_603707 = validateParameter(valid_603707, JString, required = true, default = newJString(
      "AlexaForBusiness.GetGatewayGroup"))
  if valid_603707 != nil:
    section.add "X-Amz-Target", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Content-Sha256", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-Algorithm")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Algorithm", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Signature")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Signature", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-SignedHeaders", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-Credential")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Credential", valid_603712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603714: Call_GetGatewayGroup_603702; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details of a gateway group.
  ## 
  let valid = call_603714.validator(path, query, header, formData, body)
  let scheme = call_603714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603714.url(scheme.get, call_603714.host, call_603714.base,
                         call_603714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603714, url, valid)

proc call*(call_603715: Call_GetGatewayGroup_603702; body: JsonNode): Recallable =
  ## getGatewayGroup
  ## Retrieves the details of a gateway group.
  ##   body: JObject (required)
  var body_603716 = newJObject()
  if body != nil:
    body_603716 = body
  result = call_603715.call(nil, nil, nil, nil, body_603716)

var getGatewayGroup* = Call_GetGatewayGroup_603702(name: "getGatewayGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetGatewayGroup",
    validator: validate_GetGatewayGroup_603703, base: "/", url: url_GetGatewayGroup_603704,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationConfiguration_603717 = ref object of OpenApiRestCall_602466
proc url_GetInvitationConfiguration_603719(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInvitationConfiguration_603718(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the configured values for the user enrollment invitation email template.
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
  var valid_603720 = header.getOrDefault("X-Amz-Date")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Date", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-Security-Token")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Security-Token", valid_603721
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603722 = header.getOrDefault("X-Amz-Target")
  valid_603722 = validateParameter(valid_603722, JString, required = true, default = newJString(
      "AlexaForBusiness.GetInvitationConfiguration"))
  if valid_603722 != nil:
    section.add "X-Amz-Target", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Content-Sha256", valid_603723
  var valid_603724 = header.getOrDefault("X-Amz-Algorithm")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Algorithm", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Signature")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Signature", valid_603725
  var valid_603726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-SignedHeaders", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Credential")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Credential", valid_603727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603729: Call_GetInvitationConfiguration_603717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the configured values for the user enrollment invitation email template.
  ## 
  let valid = call_603729.validator(path, query, header, formData, body)
  let scheme = call_603729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603729.url(scheme.get, call_603729.host, call_603729.base,
                         call_603729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603729, url, valid)

proc call*(call_603730: Call_GetInvitationConfiguration_603717; body: JsonNode): Recallable =
  ## getInvitationConfiguration
  ## Retrieves the configured values for the user enrollment invitation email template.
  ##   body: JObject (required)
  var body_603731 = newJObject()
  if body != nil:
    body_603731 = body
  result = call_603730.call(nil, nil, nil, nil, body_603731)

var getInvitationConfiguration* = Call_GetInvitationConfiguration_603717(
    name: "getInvitationConfiguration", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetInvitationConfiguration",
    validator: validate_GetInvitationConfiguration_603718, base: "/",
    url: url_GetInvitationConfiguration_603719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_603732 = ref object of OpenApiRestCall_602466
proc url_GetNetworkProfile_603734(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetNetworkProfile_603733(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Gets the network profile details by the network profile ARN.
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
  var valid_603735 = header.getOrDefault("X-Amz-Date")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Date", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Security-Token")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Security-Token", valid_603736
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603737 = header.getOrDefault("X-Amz-Target")
  valid_603737 = validateParameter(valid_603737, JString, required = true, default = newJString(
      "AlexaForBusiness.GetNetworkProfile"))
  if valid_603737 != nil:
    section.add "X-Amz-Target", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-Content-Sha256", valid_603738
  var valid_603739 = header.getOrDefault("X-Amz-Algorithm")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Algorithm", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-Signature")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-Signature", valid_603740
  var valid_603741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "X-Amz-SignedHeaders", valid_603741
  var valid_603742 = header.getOrDefault("X-Amz-Credential")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Credential", valid_603742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603744: Call_GetNetworkProfile_603732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the network profile details by the network profile ARN.
  ## 
  let valid = call_603744.validator(path, query, header, formData, body)
  let scheme = call_603744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603744.url(scheme.get, call_603744.host, call_603744.base,
                         call_603744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603744, url, valid)

proc call*(call_603745: Call_GetNetworkProfile_603732; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Gets the network profile details by the network profile ARN.
  ##   body: JObject (required)
  var body_603746 = newJObject()
  if body != nil:
    body_603746 = body
  result = call_603745.call(nil, nil, nil, nil, body_603746)

var getNetworkProfile* = Call_GetNetworkProfile_603732(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetNetworkProfile",
    validator: validate_GetNetworkProfile_603733, base: "/",
    url: url_GetNetworkProfile_603734, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProfile_603747 = ref object of OpenApiRestCall_602466
proc url_GetProfile_603749(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetProfile_603748(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the details of a room profile by profile ARN.
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
  var valid_603750 = header.getOrDefault("X-Amz-Date")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Date", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Security-Token")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Security-Token", valid_603751
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603752 = header.getOrDefault("X-Amz-Target")
  valid_603752 = validateParameter(valid_603752, JString, required = true, default = newJString(
      "AlexaForBusiness.GetProfile"))
  if valid_603752 != nil:
    section.add "X-Amz-Target", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Content-Sha256", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-Algorithm")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-Algorithm", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Signature")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Signature", valid_603755
  var valid_603756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603756 = validateParameter(valid_603756, JString, required = false,
                                 default = nil)
  if valid_603756 != nil:
    section.add "X-Amz-SignedHeaders", valid_603756
  var valid_603757 = header.getOrDefault("X-Amz-Credential")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "X-Amz-Credential", valid_603757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603759: Call_GetProfile_603747; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details of a room profile by profile ARN.
  ## 
  let valid = call_603759.validator(path, query, header, formData, body)
  let scheme = call_603759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603759.url(scheme.get, call_603759.host, call_603759.base,
                         call_603759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603759, url, valid)

proc call*(call_603760: Call_GetProfile_603747; body: JsonNode): Recallable =
  ## getProfile
  ## Gets the details of a room profile by profile ARN.
  ##   body: JObject (required)
  var body_603761 = newJObject()
  if body != nil:
    body_603761 = body
  result = call_603760.call(nil, nil, nil, nil, body_603761)

var getProfile* = Call_GetProfile_603747(name: "getProfile",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetProfile",
                                      validator: validate_GetProfile_603748,
                                      base: "/", url: url_GetProfile_603749,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoom_603762 = ref object of OpenApiRestCall_602466
proc url_GetRoom_603764(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRoom_603763(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets room details by room ARN.
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
  var valid_603765 = header.getOrDefault("X-Amz-Date")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Date", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Security-Token")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Security-Token", valid_603766
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603767 = header.getOrDefault("X-Amz-Target")
  valid_603767 = validateParameter(valid_603767, JString, required = true, default = newJString(
      "AlexaForBusiness.GetRoom"))
  if valid_603767 != nil:
    section.add "X-Amz-Target", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Content-Sha256", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-Algorithm")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Algorithm", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-Signature")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Signature", valid_603770
  var valid_603771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603771 = validateParameter(valid_603771, JString, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "X-Amz-SignedHeaders", valid_603771
  var valid_603772 = header.getOrDefault("X-Amz-Credential")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "X-Amz-Credential", valid_603772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603774: Call_GetRoom_603762; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets room details by room ARN.
  ## 
  let valid = call_603774.validator(path, query, header, formData, body)
  let scheme = call_603774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603774.url(scheme.get, call_603774.host, call_603774.base,
                         call_603774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603774, url, valid)

proc call*(call_603775: Call_GetRoom_603762; body: JsonNode): Recallable =
  ## getRoom
  ## Gets room details by room ARN.
  ##   body: JObject (required)
  var body_603776 = newJObject()
  if body != nil:
    body_603776 = body
  result = call_603775.call(nil, nil, nil, nil, body_603776)

var getRoom* = Call_GetRoom_603762(name: "getRoom", meth: HttpMethod.HttpPost,
                                host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetRoom",
                                validator: validate_GetRoom_603763, base: "/",
                                url: url_GetRoom_603764,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoomSkillParameter_603777 = ref object of OpenApiRestCall_602466
proc url_GetRoomSkillParameter_603779(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRoomSkillParameter_603778(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets room skill parameter details by room, skill, and parameter key ARN.
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
  var valid_603780 = header.getOrDefault("X-Amz-Date")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Date", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Security-Token")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Security-Token", valid_603781
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603782 = header.getOrDefault("X-Amz-Target")
  valid_603782 = validateParameter(valid_603782, JString, required = true, default = newJString(
      "AlexaForBusiness.GetRoomSkillParameter"))
  if valid_603782 != nil:
    section.add "X-Amz-Target", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Content-Sha256", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-Algorithm")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-Algorithm", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-Signature")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Signature", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-SignedHeaders", valid_603786
  var valid_603787 = header.getOrDefault("X-Amz-Credential")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-Credential", valid_603787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603789: Call_GetRoomSkillParameter_603777; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets room skill parameter details by room, skill, and parameter key ARN.
  ## 
  let valid = call_603789.validator(path, query, header, formData, body)
  let scheme = call_603789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603789.url(scheme.get, call_603789.host, call_603789.base,
                         call_603789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603789, url, valid)

proc call*(call_603790: Call_GetRoomSkillParameter_603777; body: JsonNode): Recallable =
  ## getRoomSkillParameter
  ## Gets room skill parameter details by room, skill, and parameter key ARN.
  ##   body: JObject (required)
  var body_603791 = newJObject()
  if body != nil:
    body_603791 = body
  result = call_603790.call(nil, nil, nil, nil, body_603791)

var getRoomSkillParameter* = Call_GetRoomSkillParameter_603777(
    name: "getRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetRoomSkillParameter",
    validator: validate_GetRoomSkillParameter_603778, base: "/",
    url: url_GetRoomSkillParameter_603779, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSkillGroup_603792 = ref object of OpenApiRestCall_602466
proc url_GetSkillGroup_603794(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSkillGroup_603793(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets skill group details by skill group ARN.
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
  var valid_603795 = header.getOrDefault("X-Amz-Date")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-Date", valid_603795
  var valid_603796 = header.getOrDefault("X-Amz-Security-Token")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Security-Token", valid_603796
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603797 = header.getOrDefault("X-Amz-Target")
  valid_603797 = validateParameter(valid_603797, JString, required = true, default = newJString(
      "AlexaForBusiness.GetSkillGroup"))
  if valid_603797 != nil:
    section.add "X-Amz-Target", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Content-Sha256", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Algorithm")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Algorithm", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Signature")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Signature", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-SignedHeaders", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-Credential")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Credential", valid_603802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603804: Call_GetSkillGroup_603792; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets skill group details by skill group ARN.
  ## 
  let valid = call_603804.validator(path, query, header, formData, body)
  let scheme = call_603804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603804.url(scheme.get, call_603804.host, call_603804.base,
                         call_603804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603804, url, valid)

proc call*(call_603805: Call_GetSkillGroup_603792; body: JsonNode): Recallable =
  ## getSkillGroup
  ## Gets skill group details by skill group ARN.
  ##   body: JObject (required)
  var body_603806 = newJObject()
  if body != nil:
    body_603806 = body
  result = call_603805.call(nil, nil, nil, nil, body_603806)

var getSkillGroup* = Call_GetSkillGroup_603792(name: "getSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetSkillGroup",
    validator: validate_GetSkillGroup_603793, base: "/", url: url_GetSkillGroup_603794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBusinessReportSchedules_603807 = ref object of OpenApiRestCall_602466
proc url_ListBusinessReportSchedules_603809(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBusinessReportSchedules_603808(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the details of the schedules that a user configured.
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
  var valid_603810 = query.getOrDefault("NextToken")
  valid_603810 = validateParameter(valid_603810, JString, required = false,
                                 default = nil)
  if valid_603810 != nil:
    section.add "NextToken", valid_603810
  var valid_603811 = query.getOrDefault("MaxResults")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "MaxResults", valid_603811
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
  var valid_603812 = header.getOrDefault("X-Amz-Date")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "X-Amz-Date", valid_603812
  var valid_603813 = header.getOrDefault("X-Amz-Security-Token")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-Security-Token", valid_603813
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603814 = header.getOrDefault("X-Amz-Target")
  valid_603814 = validateParameter(valid_603814, JString, required = true, default = newJString(
      "AlexaForBusiness.ListBusinessReportSchedules"))
  if valid_603814 != nil:
    section.add "X-Amz-Target", valid_603814
  var valid_603815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-Content-Sha256", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-Algorithm")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-Algorithm", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-Signature")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-Signature", valid_603817
  var valid_603818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-SignedHeaders", valid_603818
  var valid_603819 = header.getOrDefault("X-Amz-Credential")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "X-Amz-Credential", valid_603819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603821: Call_ListBusinessReportSchedules_603807; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the details of the schedules that a user configured.
  ## 
  let valid = call_603821.validator(path, query, header, formData, body)
  let scheme = call_603821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603821.url(scheme.get, call_603821.host, call_603821.base,
                         call_603821.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603821, url, valid)

proc call*(call_603822: Call_ListBusinessReportSchedules_603807; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listBusinessReportSchedules
  ## Lists the details of the schedules that a user configured.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603823 = newJObject()
  var body_603824 = newJObject()
  add(query_603823, "NextToken", newJString(NextToken))
  if body != nil:
    body_603824 = body
  add(query_603823, "MaxResults", newJString(MaxResults))
  result = call_603822.call(nil, query_603823, nil, nil, body_603824)

var listBusinessReportSchedules* = Call_ListBusinessReportSchedules_603807(
    name: "listBusinessReportSchedules", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListBusinessReportSchedules",
    validator: validate_ListBusinessReportSchedules_603808, base: "/",
    url: url_ListBusinessReportSchedules_603809,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConferenceProviders_603826 = ref object of OpenApiRestCall_602466
proc url_ListConferenceProviders_603828(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListConferenceProviders_603827(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists conference providers under a specific AWS account.
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
  var valid_603829 = query.getOrDefault("NextToken")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "NextToken", valid_603829
  var valid_603830 = query.getOrDefault("MaxResults")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "MaxResults", valid_603830
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
  var valid_603831 = header.getOrDefault("X-Amz-Date")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-Date", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-Security-Token")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Security-Token", valid_603832
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603833 = header.getOrDefault("X-Amz-Target")
  valid_603833 = validateParameter(valid_603833, JString, required = true, default = newJString(
      "AlexaForBusiness.ListConferenceProviders"))
  if valid_603833 != nil:
    section.add "X-Amz-Target", valid_603833
  var valid_603834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "X-Amz-Content-Sha256", valid_603834
  var valid_603835 = header.getOrDefault("X-Amz-Algorithm")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-Algorithm", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Signature")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Signature", valid_603836
  var valid_603837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-SignedHeaders", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-Credential")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Credential", valid_603838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603840: Call_ListConferenceProviders_603826; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists conference providers under a specific AWS account.
  ## 
  let valid = call_603840.validator(path, query, header, formData, body)
  let scheme = call_603840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603840.url(scheme.get, call_603840.host, call_603840.base,
                         call_603840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603840, url, valid)

proc call*(call_603841: Call_ListConferenceProviders_603826; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listConferenceProviders
  ## Lists conference providers under a specific AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603842 = newJObject()
  var body_603843 = newJObject()
  add(query_603842, "NextToken", newJString(NextToken))
  if body != nil:
    body_603843 = body
  add(query_603842, "MaxResults", newJString(MaxResults))
  result = call_603841.call(nil, query_603842, nil, nil, body_603843)

var listConferenceProviders* = Call_ListConferenceProviders_603826(
    name: "listConferenceProviders", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListConferenceProviders",
    validator: validate_ListConferenceProviders_603827, base: "/",
    url: url_ListConferenceProviders_603828, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceEvents_603844 = ref object of OpenApiRestCall_602466
proc url_ListDeviceEvents_603846(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeviceEvents_603845(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists the device event history, including device connection status, for up to 30 days.
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
  var valid_603847 = query.getOrDefault("NextToken")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "NextToken", valid_603847
  var valid_603848 = query.getOrDefault("MaxResults")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "MaxResults", valid_603848
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
  var valid_603849 = header.getOrDefault("X-Amz-Date")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-Date", valid_603849
  var valid_603850 = header.getOrDefault("X-Amz-Security-Token")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-Security-Token", valid_603850
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603851 = header.getOrDefault("X-Amz-Target")
  valid_603851 = validateParameter(valid_603851, JString, required = true, default = newJString(
      "AlexaForBusiness.ListDeviceEvents"))
  if valid_603851 != nil:
    section.add "X-Amz-Target", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Content-Sha256", valid_603852
  var valid_603853 = header.getOrDefault("X-Amz-Algorithm")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-Algorithm", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-Signature")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-Signature", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-SignedHeaders", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-Credential")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Credential", valid_603856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603858: Call_ListDeviceEvents_603844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the device event history, including device connection status, for up to 30 days.
  ## 
  let valid = call_603858.validator(path, query, header, formData, body)
  let scheme = call_603858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603858.url(scheme.get, call_603858.host, call_603858.base,
                         call_603858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603858, url, valid)

proc call*(call_603859: Call_ListDeviceEvents_603844; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDeviceEvents
  ## Lists the device event history, including device connection status, for up to 30 days.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603860 = newJObject()
  var body_603861 = newJObject()
  add(query_603860, "NextToken", newJString(NextToken))
  if body != nil:
    body_603861 = body
  add(query_603860, "MaxResults", newJString(MaxResults))
  result = call_603859.call(nil, query_603860, nil, nil, body_603861)

var listDeviceEvents* = Call_ListDeviceEvents_603844(name: "listDeviceEvents",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListDeviceEvents",
    validator: validate_ListDeviceEvents_603845, base: "/",
    url: url_ListDeviceEvents_603846, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGatewayGroups_603862 = ref object of OpenApiRestCall_602466
proc url_ListGatewayGroups_603864(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGatewayGroups_603863(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
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
  var valid_603865 = query.getOrDefault("NextToken")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "NextToken", valid_603865
  var valid_603866 = query.getOrDefault("MaxResults")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "MaxResults", valid_603866
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
  var valid_603867 = header.getOrDefault("X-Amz-Date")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Date", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-Security-Token")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Security-Token", valid_603868
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603869 = header.getOrDefault("X-Amz-Target")
  valid_603869 = validateParameter(valid_603869, JString, required = true, default = newJString(
      "AlexaForBusiness.ListGatewayGroups"))
  if valid_603869 != nil:
    section.add "X-Amz-Target", valid_603869
  var valid_603870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Content-Sha256", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Algorithm")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Algorithm", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Signature")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Signature", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-SignedHeaders", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Credential")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Credential", valid_603874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603876: Call_ListGatewayGroups_603862; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
  ## 
  let valid = call_603876.validator(path, query, header, formData, body)
  let scheme = call_603876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603876.url(scheme.get, call_603876.host, call_603876.base,
                         call_603876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603876, url, valid)

proc call*(call_603877: Call_ListGatewayGroups_603862; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listGatewayGroups
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603878 = newJObject()
  var body_603879 = newJObject()
  add(query_603878, "NextToken", newJString(NextToken))
  if body != nil:
    body_603879 = body
  add(query_603878, "MaxResults", newJString(MaxResults))
  result = call_603877.call(nil, query_603878, nil, nil, body_603879)

var listGatewayGroups* = Call_ListGatewayGroups_603862(name: "listGatewayGroups",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListGatewayGroups",
    validator: validate_ListGatewayGroups_603863, base: "/",
    url: url_ListGatewayGroups_603864, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGateways_603880 = ref object of OpenApiRestCall_602466
proc url_ListGateways_603882(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGateways_603881(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
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
  var valid_603883 = query.getOrDefault("NextToken")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "NextToken", valid_603883
  var valid_603884 = query.getOrDefault("MaxResults")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "MaxResults", valid_603884
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
  var valid_603885 = header.getOrDefault("X-Amz-Date")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Date", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Security-Token")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Security-Token", valid_603886
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603887 = header.getOrDefault("X-Amz-Target")
  valid_603887 = validateParameter(valid_603887, JString, required = true, default = newJString(
      "AlexaForBusiness.ListGateways"))
  if valid_603887 != nil:
    section.add "X-Amz-Target", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Content-Sha256", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-Algorithm")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Algorithm", valid_603889
  var valid_603890 = header.getOrDefault("X-Amz-Signature")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-Signature", valid_603890
  var valid_603891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "X-Amz-SignedHeaders", valid_603891
  var valid_603892 = header.getOrDefault("X-Amz-Credential")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "X-Amz-Credential", valid_603892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603894: Call_ListGateways_603880; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
  ## 
  let valid = call_603894.validator(path, query, header, formData, body)
  let scheme = call_603894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603894.url(scheme.get, call_603894.host, call_603894.base,
                         call_603894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603894, url, valid)

proc call*(call_603895: Call_ListGateways_603880; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listGateways
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603896 = newJObject()
  var body_603897 = newJObject()
  add(query_603896, "NextToken", newJString(NextToken))
  if body != nil:
    body_603897 = body
  add(query_603896, "MaxResults", newJString(MaxResults))
  result = call_603895.call(nil, query_603896, nil, nil, body_603897)

var listGateways* = Call_ListGateways_603880(name: "listGateways",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListGateways",
    validator: validate_ListGateways_603881, base: "/", url: url_ListGateways_603882,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkills_603898 = ref object of OpenApiRestCall_602466
proc url_ListSkills_603900(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSkills_603899(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all enabled skills in a specific skill group.
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
  var valid_603901 = query.getOrDefault("NextToken")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "NextToken", valid_603901
  var valid_603902 = query.getOrDefault("MaxResults")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "MaxResults", valid_603902
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
  var valid_603903 = header.getOrDefault("X-Amz-Date")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "X-Amz-Date", valid_603903
  var valid_603904 = header.getOrDefault("X-Amz-Security-Token")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Security-Token", valid_603904
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603905 = header.getOrDefault("X-Amz-Target")
  valid_603905 = validateParameter(valid_603905, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkills"))
  if valid_603905 != nil:
    section.add "X-Amz-Target", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-Content-Sha256", valid_603906
  var valid_603907 = header.getOrDefault("X-Amz-Algorithm")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-Algorithm", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Signature")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Signature", valid_603908
  var valid_603909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-SignedHeaders", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-Credential")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Credential", valid_603910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603912: Call_ListSkills_603898; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all enabled skills in a specific skill group.
  ## 
  let valid = call_603912.validator(path, query, header, formData, body)
  let scheme = call_603912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603912.url(scheme.get, call_603912.host, call_603912.base,
                         call_603912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603912, url, valid)

proc call*(call_603913: Call_ListSkills_603898; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSkills
  ## Lists all enabled skills in a specific skill group.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603914 = newJObject()
  var body_603915 = newJObject()
  add(query_603914, "NextToken", newJString(NextToken))
  if body != nil:
    body_603915 = body
  add(query_603914, "MaxResults", newJString(MaxResults))
  result = call_603913.call(nil, query_603914, nil, nil, body_603915)

var listSkills* = Call_ListSkills_603898(name: "listSkills",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ListSkills",
                                      validator: validate_ListSkills_603899,
                                      base: "/", url: url_ListSkills_603900,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkillsStoreCategories_603916 = ref object of OpenApiRestCall_602466
proc url_ListSkillsStoreCategories_603918(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSkillsStoreCategories_603917(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all categories in the Alexa skill store.
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
  var valid_603919 = query.getOrDefault("NextToken")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "NextToken", valid_603919
  var valid_603920 = query.getOrDefault("MaxResults")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "MaxResults", valid_603920
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
  var valid_603921 = header.getOrDefault("X-Amz-Date")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Date", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Security-Token")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Security-Token", valid_603922
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603923 = header.getOrDefault("X-Amz-Target")
  valid_603923 = validateParameter(valid_603923, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkillsStoreCategories"))
  if valid_603923 != nil:
    section.add "X-Amz-Target", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-Content-Sha256", valid_603924
  var valid_603925 = header.getOrDefault("X-Amz-Algorithm")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-Algorithm", valid_603925
  var valid_603926 = header.getOrDefault("X-Amz-Signature")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "X-Amz-Signature", valid_603926
  var valid_603927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603927 = validateParameter(valid_603927, JString, required = false,
                                 default = nil)
  if valid_603927 != nil:
    section.add "X-Amz-SignedHeaders", valid_603927
  var valid_603928 = header.getOrDefault("X-Amz-Credential")
  valid_603928 = validateParameter(valid_603928, JString, required = false,
                                 default = nil)
  if valid_603928 != nil:
    section.add "X-Amz-Credential", valid_603928
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603930: Call_ListSkillsStoreCategories_603916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all categories in the Alexa skill store.
  ## 
  let valid = call_603930.validator(path, query, header, formData, body)
  let scheme = call_603930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603930.url(scheme.get, call_603930.host, call_603930.base,
                         call_603930.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603930, url, valid)

proc call*(call_603931: Call_ListSkillsStoreCategories_603916; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSkillsStoreCategories
  ## Lists all categories in the Alexa skill store.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603932 = newJObject()
  var body_603933 = newJObject()
  add(query_603932, "NextToken", newJString(NextToken))
  if body != nil:
    body_603933 = body
  add(query_603932, "MaxResults", newJString(MaxResults))
  result = call_603931.call(nil, query_603932, nil, nil, body_603933)

var listSkillsStoreCategories* = Call_ListSkillsStoreCategories_603916(
    name: "listSkillsStoreCategories", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSkillsStoreCategories",
    validator: validate_ListSkillsStoreCategories_603917, base: "/",
    url: url_ListSkillsStoreCategories_603918,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkillsStoreSkillsByCategory_603934 = ref object of OpenApiRestCall_602466
proc url_ListSkillsStoreSkillsByCategory_603936(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSkillsStoreSkillsByCategory_603935(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all skills in the Alexa skill store by category.
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
  var valid_603937 = query.getOrDefault("NextToken")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "NextToken", valid_603937
  var valid_603938 = query.getOrDefault("MaxResults")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "MaxResults", valid_603938
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
  var valid_603939 = header.getOrDefault("X-Amz-Date")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Date", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-Security-Token")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-Security-Token", valid_603940
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603941 = header.getOrDefault("X-Amz-Target")
  valid_603941 = validateParameter(valid_603941, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkillsStoreSkillsByCategory"))
  if valid_603941 != nil:
    section.add "X-Amz-Target", valid_603941
  var valid_603942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "X-Amz-Content-Sha256", valid_603942
  var valid_603943 = header.getOrDefault("X-Amz-Algorithm")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "X-Amz-Algorithm", valid_603943
  var valid_603944 = header.getOrDefault("X-Amz-Signature")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "X-Amz-Signature", valid_603944
  var valid_603945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "X-Amz-SignedHeaders", valid_603945
  var valid_603946 = header.getOrDefault("X-Amz-Credential")
  valid_603946 = validateParameter(valid_603946, JString, required = false,
                                 default = nil)
  if valid_603946 != nil:
    section.add "X-Amz-Credential", valid_603946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603948: Call_ListSkillsStoreSkillsByCategory_603934;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all skills in the Alexa skill store by category.
  ## 
  let valid = call_603948.validator(path, query, header, formData, body)
  let scheme = call_603948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603948.url(scheme.get, call_603948.host, call_603948.base,
                         call_603948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603948, url, valid)

proc call*(call_603949: Call_ListSkillsStoreSkillsByCategory_603934;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSkillsStoreSkillsByCategory
  ## Lists all skills in the Alexa skill store by category.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603950 = newJObject()
  var body_603951 = newJObject()
  add(query_603950, "NextToken", newJString(NextToken))
  if body != nil:
    body_603951 = body
  add(query_603950, "MaxResults", newJString(MaxResults))
  result = call_603949.call(nil, query_603950, nil, nil, body_603951)

var listSkillsStoreSkillsByCategory* = Call_ListSkillsStoreSkillsByCategory_603934(
    name: "listSkillsStoreSkillsByCategory", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSkillsStoreSkillsByCategory",
    validator: validate_ListSkillsStoreSkillsByCategory_603935, base: "/",
    url: url_ListSkillsStoreSkillsByCategory_603936,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSmartHomeAppliances_603952 = ref object of OpenApiRestCall_602466
proc url_ListSmartHomeAppliances_603954(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSmartHomeAppliances_603953(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all of the smart home appliances associated with a room.
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
  var valid_603955 = query.getOrDefault("NextToken")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "NextToken", valid_603955
  var valid_603956 = query.getOrDefault("MaxResults")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "MaxResults", valid_603956
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
  var valid_603957 = header.getOrDefault("X-Amz-Date")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-Date", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-Security-Token")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-Security-Token", valid_603958
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603959 = header.getOrDefault("X-Amz-Target")
  valid_603959 = validateParameter(valid_603959, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSmartHomeAppliances"))
  if valid_603959 != nil:
    section.add "X-Amz-Target", valid_603959
  var valid_603960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "X-Amz-Content-Sha256", valid_603960
  var valid_603961 = header.getOrDefault("X-Amz-Algorithm")
  valid_603961 = validateParameter(valid_603961, JString, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "X-Amz-Algorithm", valid_603961
  var valid_603962 = header.getOrDefault("X-Amz-Signature")
  valid_603962 = validateParameter(valid_603962, JString, required = false,
                                 default = nil)
  if valid_603962 != nil:
    section.add "X-Amz-Signature", valid_603962
  var valid_603963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603963 = validateParameter(valid_603963, JString, required = false,
                                 default = nil)
  if valid_603963 != nil:
    section.add "X-Amz-SignedHeaders", valid_603963
  var valid_603964 = header.getOrDefault("X-Amz-Credential")
  valid_603964 = validateParameter(valid_603964, JString, required = false,
                                 default = nil)
  if valid_603964 != nil:
    section.add "X-Amz-Credential", valid_603964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603966: Call_ListSmartHomeAppliances_603952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all of the smart home appliances associated with a room.
  ## 
  let valid = call_603966.validator(path, query, header, formData, body)
  let scheme = call_603966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603966.url(scheme.get, call_603966.host, call_603966.base,
                         call_603966.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603966, url, valid)

proc call*(call_603967: Call_ListSmartHomeAppliances_603952; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSmartHomeAppliances
  ## Lists all of the smart home appliances associated with a room.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603968 = newJObject()
  var body_603969 = newJObject()
  add(query_603968, "NextToken", newJString(NextToken))
  if body != nil:
    body_603969 = body
  add(query_603968, "MaxResults", newJString(MaxResults))
  result = call_603967.call(nil, query_603968, nil, nil, body_603969)

var listSmartHomeAppliances* = Call_ListSmartHomeAppliances_603952(
    name: "listSmartHomeAppliances", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSmartHomeAppliances",
    validator: validate_ListSmartHomeAppliances_603953, base: "/",
    url: url_ListSmartHomeAppliances_603954, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_603970 = ref object of OpenApiRestCall_602466
proc url_ListTags_603972(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTags_603971(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all tags for the specified resource.
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
  var valid_603973 = query.getOrDefault("NextToken")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "NextToken", valid_603973
  var valid_603974 = query.getOrDefault("MaxResults")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "MaxResults", valid_603974
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
  var valid_603975 = header.getOrDefault("X-Amz-Date")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "X-Amz-Date", valid_603975
  var valid_603976 = header.getOrDefault("X-Amz-Security-Token")
  valid_603976 = validateParameter(valid_603976, JString, required = false,
                                 default = nil)
  if valid_603976 != nil:
    section.add "X-Amz-Security-Token", valid_603976
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603977 = header.getOrDefault("X-Amz-Target")
  valid_603977 = validateParameter(valid_603977, JString, required = true, default = newJString(
      "AlexaForBusiness.ListTags"))
  if valid_603977 != nil:
    section.add "X-Amz-Target", valid_603977
  var valid_603978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603978 = validateParameter(valid_603978, JString, required = false,
                                 default = nil)
  if valid_603978 != nil:
    section.add "X-Amz-Content-Sha256", valid_603978
  var valid_603979 = header.getOrDefault("X-Amz-Algorithm")
  valid_603979 = validateParameter(valid_603979, JString, required = false,
                                 default = nil)
  if valid_603979 != nil:
    section.add "X-Amz-Algorithm", valid_603979
  var valid_603980 = header.getOrDefault("X-Amz-Signature")
  valid_603980 = validateParameter(valid_603980, JString, required = false,
                                 default = nil)
  if valid_603980 != nil:
    section.add "X-Amz-Signature", valid_603980
  var valid_603981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603981 = validateParameter(valid_603981, JString, required = false,
                                 default = nil)
  if valid_603981 != nil:
    section.add "X-Amz-SignedHeaders", valid_603981
  var valid_603982 = header.getOrDefault("X-Amz-Credential")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "X-Amz-Credential", valid_603982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603984: Call_ListTags_603970; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags for the specified resource.
  ## 
  let valid = call_603984.validator(path, query, header, formData, body)
  let scheme = call_603984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603984.url(scheme.get, call_603984.host, call_603984.base,
                         call_603984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603984, url, valid)

proc call*(call_603985: Call_ListTags_603970; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listTags
  ## Lists all tags for the specified resource.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603986 = newJObject()
  var body_603987 = newJObject()
  add(query_603986, "NextToken", newJString(NextToken))
  if body != nil:
    body_603987 = body
  add(query_603986, "MaxResults", newJString(MaxResults))
  result = call_603985.call(nil, query_603986, nil, nil, body_603987)

var listTags* = Call_ListTags_603970(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ListTags",
                                  validator: validate_ListTags_603971, base: "/",
                                  url: url_ListTags_603972,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConferencePreference_603988 = ref object of OpenApiRestCall_602466
proc url_PutConferencePreference_603990(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutConferencePreference_603989(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the conference preferences on a specific conference provider at the account level.
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
  var valid_603991 = header.getOrDefault("X-Amz-Date")
  valid_603991 = validateParameter(valid_603991, JString, required = false,
                                 default = nil)
  if valid_603991 != nil:
    section.add "X-Amz-Date", valid_603991
  var valid_603992 = header.getOrDefault("X-Amz-Security-Token")
  valid_603992 = validateParameter(valid_603992, JString, required = false,
                                 default = nil)
  if valid_603992 != nil:
    section.add "X-Amz-Security-Token", valid_603992
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603993 = header.getOrDefault("X-Amz-Target")
  valid_603993 = validateParameter(valid_603993, JString, required = true, default = newJString(
      "AlexaForBusiness.PutConferencePreference"))
  if valid_603993 != nil:
    section.add "X-Amz-Target", valid_603993
  var valid_603994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603994 = validateParameter(valid_603994, JString, required = false,
                                 default = nil)
  if valid_603994 != nil:
    section.add "X-Amz-Content-Sha256", valid_603994
  var valid_603995 = header.getOrDefault("X-Amz-Algorithm")
  valid_603995 = validateParameter(valid_603995, JString, required = false,
                                 default = nil)
  if valid_603995 != nil:
    section.add "X-Amz-Algorithm", valid_603995
  var valid_603996 = header.getOrDefault("X-Amz-Signature")
  valid_603996 = validateParameter(valid_603996, JString, required = false,
                                 default = nil)
  if valid_603996 != nil:
    section.add "X-Amz-Signature", valid_603996
  var valid_603997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "X-Amz-SignedHeaders", valid_603997
  var valid_603998 = header.getOrDefault("X-Amz-Credential")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "X-Amz-Credential", valid_603998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604000: Call_PutConferencePreference_603988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the conference preferences on a specific conference provider at the account level.
  ## 
  let valid = call_604000.validator(path, query, header, formData, body)
  let scheme = call_604000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604000.url(scheme.get, call_604000.host, call_604000.base,
                         call_604000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604000, url, valid)

proc call*(call_604001: Call_PutConferencePreference_603988; body: JsonNode): Recallable =
  ## putConferencePreference
  ## Sets the conference preferences on a specific conference provider at the account level.
  ##   body: JObject (required)
  var body_604002 = newJObject()
  if body != nil:
    body_604002 = body
  result = call_604001.call(nil, nil, nil, nil, body_604002)

var putConferencePreference* = Call_PutConferencePreference_603988(
    name: "putConferencePreference", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutConferencePreference",
    validator: validate_PutConferencePreference_603989, base: "/",
    url: url_PutConferencePreference_603990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInvitationConfiguration_604003 = ref object of OpenApiRestCall_602466
proc url_PutInvitationConfiguration_604005(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutInvitationConfiguration_604004(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the email template for the user enrollment invitation with the specified attributes.
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
  var valid_604006 = header.getOrDefault("X-Amz-Date")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "X-Amz-Date", valid_604006
  var valid_604007 = header.getOrDefault("X-Amz-Security-Token")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "X-Amz-Security-Token", valid_604007
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604008 = header.getOrDefault("X-Amz-Target")
  valid_604008 = validateParameter(valid_604008, JString, required = true, default = newJString(
      "AlexaForBusiness.PutInvitationConfiguration"))
  if valid_604008 != nil:
    section.add "X-Amz-Target", valid_604008
  var valid_604009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604009 = validateParameter(valid_604009, JString, required = false,
                                 default = nil)
  if valid_604009 != nil:
    section.add "X-Amz-Content-Sha256", valid_604009
  var valid_604010 = header.getOrDefault("X-Amz-Algorithm")
  valid_604010 = validateParameter(valid_604010, JString, required = false,
                                 default = nil)
  if valid_604010 != nil:
    section.add "X-Amz-Algorithm", valid_604010
  var valid_604011 = header.getOrDefault("X-Amz-Signature")
  valid_604011 = validateParameter(valid_604011, JString, required = false,
                                 default = nil)
  if valid_604011 != nil:
    section.add "X-Amz-Signature", valid_604011
  var valid_604012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604012 = validateParameter(valid_604012, JString, required = false,
                                 default = nil)
  if valid_604012 != nil:
    section.add "X-Amz-SignedHeaders", valid_604012
  var valid_604013 = header.getOrDefault("X-Amz-Credential")
  valid_604013 = validateParameter(valid_604013, JString, required = false,
                                 default = nil)
  if valid_604013 != nil:
    section.add "X-Amz-Credential", valid_604013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604015: Call_PutInvitationConfiguration_604003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the email template for the user enrollment invitation with the specified attributes.
  ## 
  let valid = call_604015.validator(path, query, header, formData, body)
  let scheme = call_604015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604015.url(scheme.get, call_604015.host, call_604015.base,
                         call_604015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604015, url, valid)

proc call*(call_604016: Call_PutInvitationConfiguration_604003; body: JsonNode): Recallable =
  ## putInvitationConfiguration
  ## Configures the email template for the user enrollment invitation with the specified attributes.
  ##   body: JObject (required)
  var body_604017 = newJObject()
  if body != nil:
    body_604017 = body
  result = call_604016.call(nil, nil, nil, nil, body_604017)

var putInvitationConfiguration* = Call_PutInvitationConfiguration_604003(
    name: "putInvitationConfiguration", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutInvitationConfiguration",
    validator: validate_PutInvitationConfiguration_604004, base: "/",
    url: url_PutInvitationConfiguration_604005,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRoomSkillParameter_604018 = ref object of OpenApiRestCall_602466
proc url_PutRoomSkillParameter_604020(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutRoomSkillParameter_604019(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates room skill parameter details by room, skill, and parameter key ID. Not all skills have a room skill parameter.
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
  var valid_604021 = header.getOrDefault("X-Amz-Date")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "X-Amz-Date", valid_604021
  var valid_604022 = header.getOrDefault("X-Amz-Security-Token")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "X-Amz-Security-Token", valid_604022
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604023 = header.getOrDefault("X-Amz-Target")
  valid_604023 = validateParameter(valid_604023, JString, required = true, default = newJString(
      "AlexaForBusiness.PutRoomSkillParameter"))
  if valid_604023 != nil:
    section.add "X-Amz-Target", valid_604023
  var valid_604024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "X-Amz-Content-Sha256", valid_604024
  var valid_604025 = header.getOrDefault("X-Amz-Algorithm")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "X-Amz-Algorithm", valid_604025
  var valid_604026 = header.getOrDefault("X-Amz-Signature")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "X-Amz-Signature", valid_604026
  var valid_604027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "X-Amz-SignedHeaders", valid_604027
  var valid_604028 = header.getOrDefault("X-Amz-Credential")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "X-Amz-Credential", valid_604028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604030: Call_PutRoomSkillParameter_604018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room skill parameter details by room, skill, and parameter key ID. Not all skills have a room skill parameter.
  ## 
  let valid = call_604030.validator(path, query, header, formData, body)
  let scheme = call_604030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604030.url(scheme.get, call_604030.host, call_604030.base,
                         call_604030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604030, url, valid)

proc call*(call_604031: Call_PutRoomSkillParameter_604018; body: JsonNode): Recallable =
  ## putRoomSkillParameter
  ## Updates room skill parameter details by room, skill, and parameter key ID. Not all skills have a room skill parameter.
  ##   body: JObject (required)
  var body_604032 = newJObject()
  if body != nil:
    body_604032 = body
  result = call_604031.call(nil, nil, nil, nil, body_604032)

var putRoomSkillParameter* = Call_PutRoomSkillParameter_604018(
    name: "putRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutRoomSkillParameter",
    validator: validate_PutRoomSkillParameter_604019, base: "/",
    url: url_PutRoomSkillParameter_604020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSkillAuthorization_604033 = ref object of OpenApiRestCall_602466
proc url_PutSkillAuthorization_604035(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutSkillAuthorization_604034(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Links a user's account to a third-party skill provider. If this API operation is called by an assumed IAM role, the skill being linked must be a private skill. Also, the skill must be owned by the AWS account that assumed the IAM role.
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
  var valid_604036 = header.getOrDefault("X-Amz-Date")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-Date", valid_604036
  var valid_604037 = header.getOrDefault("X-Amz-Security-Token")
  valid_604037 = validateParameter(valid_604037, JString, required = false,
                                 default = nil)
  if valid_604037 != nil:
    section.add "X-Amz-Security-Token", valid_604037
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604038 = header.getOrDefault("X-Amz-Target")
  valid_604038 = validateParameter(valid_604038, JString, required = true, default = newJString(
      "AlexaForBusiness.PutSkillAuthorization"))
  if valid_604038 != nil:
    section.add "X-Amz-Target", valid_604038
  var valid_604039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "X-Amz-Content-Sha256", valid_604039
  var valid_604040 = header.getOrDefault("X-Amz-Algorithm")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Algorithm", valid_604040
  var valid_604041 = header.getOrDefault("X-Amz-Signature")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-Signature", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-SignedHeaders", valid_604042
  var valid_604043 = header.getOrDefault("X-Amz-Credential")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "X-Amz-Credential", valid_604043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604045: Call_PutSkillAuthorization_604033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Links a user's account to a third-party skill provider. If this API operation is called by an assumed IAM role, the skill being linked must be a private skill. Also, the skill must be owned by the AWS account that assumed the IAM role.
  ## 
  let valid = call_604045.validator(path, query, header, formData, body)
  let scheme = call_604045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604045.url(scheme.get, call_604045.host, call_604045.base,
                         call_604045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604045, url, valid)

proc call*(call_604046: Call_PutSkillAuthorization_604033; body: JsonNode): Recallable =
  ## putSkillAuthorization
  ## Links a user's account to a third-party skill provider. If this API operation is called by an assumed IAM role, the skill being linked must be a private skill. Also, the skill must be owned by the AWS account that assumed the IAM role.
  ##   body: JObject (required)
  var body_604047 = newJObject()
  if body != nil:
    body_604047 = body
  result = call_604046.call(nil, nil, nil, nil, body_604047)

var putSkillAuthorization* = Call_PutSkillAuthorization_604033(
    name: "putSkillAuthorization", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutSkillAuthorization",
    validator: validate_PutSkillAuthorization_604034, base: "/",
    url: url_PutSkillAuthorization_604035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterAVSDevice_604048 = ref object of OpenApiRestCall_602466
proc url_RegisterAVSDevice_604050(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterAVSDevice_604049(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Registers an Alexa-enabled device built by an Original Equipment Manufacturer (OEM) using Alexa Voice Service (AVS).
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
  var valid_604051 = header.getOrDefault("X-Amz-Date")
  valid_604051 = validateParameter(valid_604051, JString, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "X-Amz-Date", valid_604051
  var valid_604052 = header.getOrDefault("X-Amz-Security-Token")
  valid_604052 = validateParameter(valid_604052, JString, required = false,
                                 default = nil)
  if valid_604052 != nil:
    section.add "X-Amz-Security-Token", valid_604052
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604053 = header.getOrDefault("X-Amz-Target")
  valid_604053 = validateParameter(valid_604053, JString, required = true, default = newJString(
      "AlexaForBusiness.RegisterAVSDevice"))
  if valid_604053 != nil:
    section.add "X-Amz-Target", valid_604053
  var valid_604054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "X-Amz-Content-Sha256", valid_604054
  var valid_604055 = header.getOrDefault("X-Amz-Algorithm")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "X-Amz-Algorithm", valid_604055
  var valid_604056 = header.getOrDefault("X-Amz-Signature")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "X-Amz-Signature", valid_604056
  var valid_604057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "X-Amz-SignedHeaders", valid_604057
  var valid_604058 = header.getOrDefault("X-Amz-Credential")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "X-Amz-Credential", valid_604058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604060: Call_RegisterAVSDevice_604048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers an Alexa-enabled device built by an Original Equipment Manufacturer (OEM) using Alexa Voice Service (AVS).
  ## 
  let valid = call_604060.validator(path, query, header, formData, body)
  let scheme = call_604060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604060.url(scheme.get, call_604060.host, call_604060.base,
                         call_604060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604060, url, valid)

proc call*(call_604061: Call_RegisterAVSDevice_604048; body: JsonNode): Recallable =
  ## registerAVSDevice
  ## Registers an Alexa-enabled device built by an Original Equipment Manufacturer (OEM) using Alexa Voice Service (AVS).
  ##   body: JObject (required)
  var body_604062 = newJObject()
  if body != nil:
    body_604062 = body
  result = call_604061.call(nil, nil, nil, nil, body_604062)

var registerAVSDevice* = Call_RegisterAVSDevice_604048(name: "registerAVSDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.RegisterAVSDevice",
    validator: validate_RegisterAVSDevice_604049, base: "/",
    url: url_RegisterAVSDevice_604050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectSkill_604063 = ref object of OpenApiRestCall_602466
proc url_RejectSkill_604065(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RejectSkill_604064(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates a skill from the organization under a user's AWS account. If the skill is a private skill, it moves to an AcceptStatus of PENDING. Any private or public skill that is rejected can be added later by calling the ApproveSkill API. 
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
  var valid_604066 = header.getOrDefault("X-Amz-Date")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "X-Amz-Date", valid_604066
  var valid_604067 = header.getOrDefault("X-Amz-Security-Token")
  valid_604067 = validateParameter(valid_604067, JString, required = false,
                                 default = nil)
  if valid_604067 != nil:
    section.add "X-Amz-Security-Token", valid_604067
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604068 = header.getOrDefault("X-Amz-Target")
  valid_604068 = validateParameter(valid_604068, JString, required = true, default = newJString(
      "AlexaForBusiness.RejectSkill"))
  if valid_604068 != nil:
    section.add "X-Amz-Target", valid_604068
  var valid_604069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604069 = validateParameter(valid_604069, JString, required = false,
                                 default = nil)
  if valid_604069 != nil:
    section.add "X-Amz-Content-Sha256", valid_604069
  var valid_604070 = header.getOrDefault("X-Amz-Algorithm")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "X-Amz-Algorithm", valid_604070
  var valid_604071 = header.getOrDefault("X-Amz-Signature")
  valid_604071 = validateParameter(valid_604071, JString, required = false,
                                 default = nil)
  if valid_604071 != nil:
    section.add "X-Amz-Signature", valid_604071
  var valid_604072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "X-Amz-SignedHeaders", valid_604072
  var valid_604073 = header.getOrDefault("X-Amz-Credential")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "X-Amz-Credential", valid_604073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604075: Call_RejectSkill_604063; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a skill from the organization under a user's AWS account. If the skill is a private skill, it moves to an AcceptStatus of PENDING. Any private or public skill that is rejected can be added later by calling the ApproveSkill API. 
  ## 
  let valid = call_604075.validator(path, query, header, formData, body)
  let scheme = call_604075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604075.url(scheme.get, call_604075.host, call_604075.base,
                         call_604075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604075, url, valid)

proc call*(call_604076: Call_RejectSkill_604063; body: JsonNode): Recallable =
  ## rejectSkill
  ## Disassociates a skill from the organization under a user's AWS account. If the skill is a private skill, it moves to an AcceptStatus of PENDING. Any private or public skill that is rejected can be added later by calling the ApproveSkill API. 
  ##   body: JObject (required)
  var body_604077 = newJObject()
  if body != nil:
    body_604077 = body
  result = call_604076.call(nil, nil, nil, nil, body_604077)

var rejectSkill* = Call_RejectSkill_604063(name: "rejectSkill",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.RejectSkill",
                                        validator: validate_RejectSkill_604064,
                                        base: "/", url: url_RejectSkill_604065,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResolveRoom_604078 = ref object of OpenApiRestCall_602466
proc url_ResolveRoom_604080(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResolveRoom_604079(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Determines the details for the room from which a skill request was invoked. This operation is used by skill developers.
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
  var valid_604081 = header.getOrDefault("X-Amz-Date")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-Date", valid_604081
  var valid_604082 = header.getOrDefault("X-Amz-Security-Token")
  valid_604082 = validateParameter(valid_604082, JString, required = false,
                                 default = nil)
  if valid_604082 != nil:
    section.add "X-Amz-Security-Token", valid_604082
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604083 = header.getOrDefault("X-Amz-Target")
  valid_604083 = validateParameter(valid_604083, JString, required = true, default = newJString(
      "AlexaForBusiness.ResolveRoom"))
  if valid_604083 != nil:
    section.add "X-Amz-Target", valid_604083
  var valid_604084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604084 = validateParameter(valid_604084, JString, required = false,
                                 default = nil)
  if valid_604084 != nil:
    section.add "X-Amz-Content-Sha256", valid_604084
  var valid_604085 = header.getOrDefault("X-Amz-Algorithm")
  valid_604085 = validateParameter(valid_604085, JString, required = false,
                                 default = nil)
  if valid_604085 != nil:
    section.add "X-Amz-Algorithm", valid_604085
  var valid_604086 = header.getOrDefault("X-Amz-Signature")
  valid_604086 = validateParameter(valid_604086, JString, required = false,
                                 default = nil)
  if valid_604086 != nil:
    section.add "X-Amz-Signature", valid_604086
  var valid_604087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "X-Amz-SignedHeaders", valid_604087
  var valid_604088 = header.getOrDefault("X-Amz-Credential")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "X-Amz-Credential", valid_604088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604090: Call_ResolveRoom_604078; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Determines the details for the room from which a skill request was invoked. This operation is used by skill developers.
  ## 
  let valid = call_604090.validator(path, query, header, formData, body)
  let scheme = call_604090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604090.url(scheme.get, call_604090.host, call_604090.base,
                         call_604090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604090, url, valid)

proc call*(call_604091: Call_ResolveRoom_604078; body: JsonNode): Recallable =
  ## resolveRoom
  ## Determines the details for the room from which a skill request was invoked. This operation is used by skill developers.
  ##   body: JObject (required)
  var body_604092 = newJObject()
  if body != nil:
    body_604092 = body
  result = call_604091.call(nil, nil, nil, nil, body_604092)

var resolveRoom* = Call_ResolveRoom_604078(name: "resolveRoom",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ResolveRoom",
                                        validator: validate_ResolveRoom_604079,
                                        base: "/", url: url_ResolveRoom_604080,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeInvitation_604093 = ref object of OpenApiRestCall_602466
proc url_RevokeInvitation_604095(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RevokeInvitation_604094(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Revokes an invitation and invalidates the enrollment URL.
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
  var valid_604096 = header.getOrDefault("X-Amz-Date")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-Date", valid_604096
  var valid_604097 = header.getOrDefault("X-Amz-Security-Token")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "X-Amz-Security-Token", valid_604097
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604098 = header.getOrDefault("X-Amz-Target")
  valid_604098 = validateParameter(valid_604098, JString, required = true, default = newJString(
      "AlexaForBusiness.RevokeInvitation"))
  if valid_604098 != nil:
    section.add "X-Amz-Target", valid_604098
  var valid_604099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-Content-Sha256", valid_604099
  var valid_604100 = header.getOrDefault("X-Amz-Algorithm")
  valid_604100 = validateParameter(valid_604100, JString, required = false,
                                 default = nil)
  if valid_604100 != nil:
    section.add "X-Amz-Algorithm", valid_604100
  var valid_604101 = header.getOrDefault("X-Amz-Signature")
  valid_604101 = validateParameter(valid_604101, JString, required = false,
                                 default = nil)
  if valid_604101 != nil:
    section.add "X-Amz-Signature", valid_604101
  var valid_604102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604102 = validateParameter(valid_604102, JString, required = false,
                                 default = nil)
  if valid_604102 != nil:
    section.add "X-Amz-SignedHeaders", valid_604102
  var valid_604103 = header.getOrDefault("X-Amz-Credential")
  valid_604103 = validateParameter(valid_604103, JString, required = false,
                                 default = nil)
  if valid_604103 != nil:
    section.add "X-Amz-Credential", valid_604103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604105: Call_RevokeInvitation_604093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes an invitation and invalidates the enrollment URL.
  ## 
  let valid = call_604105.validator(path, query, header, formData, body)
  let scheme = call_604105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604105.url(scheme.get, call_604105.host, call_604105.base,
                         call_604105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604105, url, valid)

proc call*(call_604106: Call_RevokeInvitation_604093; body: JsonNode): Recallable =
  ## revokeInvitation
  ## Revokes an invitation and invalidates the enrollment URL.
  ##   body: JObject (required)
  var body_604107 = newJObject()
  if body != nil:
    body_604107 = body
  result = call_604106.call(nil, nil, nil, nil, body_604107)

var revokeInvitation* = Call_RevokeInvitation_604093(name: "revokeInvitation",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.RevokeInvitation",
    validator: validate_RevokeInvitation_604094, base: "/",
    url: url_RevokeInvitation_604095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAddressBooks_604108 = ref object of OpenApiRestCall_602466
proc url_SearchAddressBooks_604110(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchAddressBooks_604109(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
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
  var valid_604111 = query.getOrDefault("NextToken")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "NextToken", valid_604111
  var valid_604112 = query.getOrDefault("MaxResults")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "MaxResults", valid_604112
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
  var valid_604113 = header.getOrDefault("X-Amz-Date")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-Date", valid_604113
  var valid_604114 = header.getOrDefault("X-Amz-Security-Token")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-Security-Token", valid_604114
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604115 = header.getOrDefault("X-Amz-Target")
  valid_604115 = validateParameter(valid_604115, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchAddressBooks"))
  if valid_604115 != nil:
    section.add "X-Amz-Target", valid_604115
  var valid_604116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604116 = validateParameter(valid_604116, JString, required = false,
                                 default = nil)
  if valid_604116 != nil:
    section.add "X-Amz-Content-Sha256", valid_604116
  var valid_604117 = header.getOrDefault("X-Amz-Algorithm")
  valid_604117 = validateParameter(valid_604117, JString, required = false,
                                 default = nil)
  if valid_604117 != nil:
    section.add "X-Amz-Algorithm", valid_604117
  var valid_604118 = header.getOrDefault("X-Amz-Signature")
  valid_604118 = validateParameter(valid_604118, JString, required = false,
                                 default = nil)
  if valid_604118 != nil:
    section.add "X-Amz-Signature", valid_604118
  var valid_604119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604119 = validateParameter(valid_604119, JString, required = false,
                                 default = nil)
  if valid_604119 != nil:
    section.add "X-Amz-SignedHeaders", valid_604119
  var valid_604120 = header.getOrDefault("X-Amz-Credential")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "X-Amz-Credential", valid_604120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604122: Call_SearchAddressBooks_604108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_604122.validator(path, query, header, formData, body)
  let scheme = call_604122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604122.url(scheme.get, call_604122.host, call_604122.base,
                         call_604122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604122, url, valid)

proc call*(call_604123: Call_SearchAddressBooks_604108; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchAddressBooks
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604124 = newJObject()
  var body_604125 = newJObject()
  add(query_604124, "NextToken", newJString(NextToken))
  if body != nil:
    body_604125 = body
  add(query_604124, "MaxResults", newJString(MaxResults))
  result = call_604123.call(nil, query_604124, nil, nil, body_604125)

var searchAddressBooks* = Call_SearchAddressBooks_604108(
    name: "searchAddressBooks", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchAddressBooks",
    validator: validate_SearchAddressBooks_604109, base: "/",
    url: url_SearchAddressBooks_604110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchContacts_604126 = ref object of OpenApiRestCall_602466
proc url_SearchContacts_604128(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchContacts_604127(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
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
  var valid_604129 = query.getOrDefault("NextToken")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "NextToken", valid_604129
  var valid_604130 = query.getOrDefault("MaxResults")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "MaxResults", valid_604130
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
  var valid_604131 = header.getOrDefault("X-Amz-Date")
  valid_604131 = validateParameter(valid_604131, JString, required = false,
                                 default = nil)
  if valid_604131 != nil:
    section.add "X-Amz-Date", valid_604131
  var valid_604132 = header.getOrDefault("X-Amz-Security-Token")
  valid_604132 = validateParameter(valid_604132, JString, required = false,
                                 default = nil)
  if valid_604132 != nil:
    section.add "X-Amz-Security-Token", valid_604132
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604133 = header.getOrDefault("X-Amz-Target")
  valid_604133 = validateParameter(valid_604133, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchContacts"))
  if valid_604133 != nil:
    section.add "X-Amz-Target", valid_604133
  var valid_604134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604134 = validateParameter(valid_604134, JString, required = false,
                                 default = nil)
  if valid_604134 != nil:
    section.add "X-Amz-Content-Sha256", valid_604134
  var valid_604135 = header.getOrDefault("X-Amz-Algorithm")
  valid_604135 = validateParameter(valid_604135, JString, required = false,
                                 default = nil)
  if valid_604135 != nil:
    section.add "X-Amz-Algorithm", valid_604135
  var valid_604136 = header.getOrDefault("X-Amz-Signature")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "X-Amz-Signature", valid_604136
  var valid_604137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604137 = validateParameter(valid_604137, JString, required = false,
                                 default = nil)
  if valid_604137 != nil:
    section.add "X-Amz-SignedHeaders", valid_604137
  var valid_604138 = header.getOrDefault("X-Amz-Credential")
  valid_604138 = validateParameter(valid_604138, JString, required = false,
                                 default = nil)
  if valid_604138 != nil:
    section.add "X-Amz-Credential", valid_604138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604140: Call_SearchContacts_604126; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_604140.validator(path, query, header, formData, body)
  let scheme = call_604140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604140.url(scheme.get, call_604140.host, call_604140.base,
                         call_604140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604140, url, valid)

proc call*(call_604141: Call_SearchContacts_604126; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchContacts
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604142 = newJObject()
  var body_604143 = newJObject()
  add(query_604142, "NextToken", newJString(NextToken))
  if body != nil:
    body_604143 = body
  add(query_604142, "MaxResults", newJString(MaxResults))
  result = call_604141.call(nil, query_604142, nil, nil, body_604143)

var searchContacts* = Call_SearchContacts_604126(name: "searchContacts",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchContacts",
    validator: validate_SearchContacts_604127, base: "/", url: url_SearchContacts_604128,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchDevices_604144 = ref object of OpenApiRestCall_602466
proc url_SearchDevices_604146(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchDevices_604145(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches devices and lists the ones that meet a set of filter criteria.
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
  var valid_604147 = query.getOrDefault("NextToken")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "NextToken", valid_604147
  var valid_604148 = query.getOrDefault("MaxResults")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "MaxResults", valid_604148
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
  var valid_604149 = header.getOrDefault("X-Amz-Date")
  valid_604149 = validateParameter(valid_604149, JString, required = false,
                                 default = nil)
  if valid_604149 != nil:
    section.add "X-Amz-Date", valid_604149
  var valid_604150 = header.getOrDefault("X-Amz-Security-Token")
  valid_604150 = validateParameter(valid_604150, JString, required = false,
                                 default = nil)
  if valid_604150 != nil:
    section.add "X-Amz-Security-Token", valid_604150
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604151 = header.getOrDefault("X-Amz-Target")
  valid_604151 = validateParameter(valid_604151, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchDevices"))
  if valid_604151 != nil:
    section.add "X-Amz-Target", valid_604151
  var valid_604152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604152 = validateParameter(valid_604152, JString, required = false,
                                 default = nil)
  if valid_604152 != nil:
    section.add "X-Amz-Content-Sha256", valid_604152
  var valid_604153 = header.getOrDefault("X-Amz-Algorithm")
  valid_604153 = validateParameter(valid_604153, JString, required = false,
                                 default = nil)
  if valid_604153 != nil:
    section.add "X-Amz-Algorithm", valid_604153
  var valid_604154 = header.getOrDefault("X-Amz-Signature")
  valid_604154 = validateParameter(valid_604154, JString, required = false,
                                 default = nil)
  if valid_604154 != nil:
    section.add "X-Amz-Signature", valid_604154
  var valid_604155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604155 = validateParameter(valid_604155, JString, required = false,
                                 default = nil)
  if valid_604155 != nil:
    section.add "X-Amz-SignedHeaders", valid_604155
  var valid_604156 = header.getOrDefault("X-Amz-Credential")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "X-Amz-Credential", valid_604156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604158: Call_SearchDevices_604144; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches devices and lists the ones that meet a set of filter criteria.
  ## 
  let valid = call_604158.validator(path, query, header, formData, body)
  let scheme = call_604158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604158.url(scheme.get, call_604158.host, call_604158.base,
                         call_604158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604158, url, valid)

proc call*(call_604159: Call_SearchDevices_604144; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchDevices
  ## Searches devices and lists the ones that meet a set of filter criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604160 = newJObject()
  var body_604161 = newJObject()
  add(query_604160, "NextToken", newJString(NextToken))
  if body != nil:
    body_604161 = body
  add(query_604160, "MaxResults", newJString(MaxResults))
  result = call_604159.call(nil, query_604160, nil, nil, body_604161)

var searchDevices* = Call_SearchDevices_604144(name: "searchDevices",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchDevices",
    validator: validate_SearchDevices_604145, base: "/", url: url_SearchDevices_604146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchNetworkProfiles_604162 = ref object of OpenApiRestCall_602466
proc url_SearchNetworkProfiles_604164(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchNetworkProfiles_604163(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
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
  var valid_604165 = query.getOrDefault("NextToken")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "NextToken", valid_604165
  var valid_604166 = query.getOrDefault("MaxResults")
  valid_604166 = validateParameter(valid_604166, JString, required = false,
                                 default = nil)
  if valid_604166 != nil:
    section.add "MaxResults", valid_604166
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
  var valid_604167 = header.getOrDefault("X-Amz-Date")
  valid_604167 = validateParameter(valid_604167, JString, required = false,
                                 default = nil)
  if valid_604167 != nil:
    section.add "X-Amz-Date", valid_604167
  var valid_604168 = header.getOrDefault("X-Amz-Security-Token")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "X-Amz-Security-Token", valid_604168
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604169 = header.getOrDefault("X-Amz-Target")
  valid_604169 = validateParameter(valid_604169, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchNetworkProfiles"))
  if valid_604169 != nil:
    section.add "X-Amz-Target", valid_604169
  var valid_604170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604170 = validateParameter(valid_604170, JString, required = false,
                                 default = nil)
  if valid_604170 != nil:
    section.add "X-Amz-Content-Sha256", valid_604170
  var valid_604171 = header.getOrDefault("X-Amz-Algorithm")
  valid_604171 = validateParameter(valid_604171, JString, required = false,
                                 default = nil)
  if valid_604171 != nil:
    section.add "X-Amz-Algorithm", valid_604171
  var valid_604172 = header.getOrDefault("X-Amz-Signature")
  valid_604172 = validateParameter(valid_604172, JString, required = false,
                                 default = nil)
  if valid_604172 != nil:
    section.add "X-Amz-Signature", valid_604172
  var valid_604173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604173 = validateParameter(valid_604173, JString, required = false,
                                 default = nil)
  if valid_604173 != nil:
    section.add "X-Amz-SignedHeaders", valid_604173
  var valid_604174 = header.getOrDefault("X-Amz-Credential")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "X-Amz-Credential", valid_604174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604176: Call_SearchNetworkProfiles_604162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_604176.validator(path, query, header, formData, body)
  let scheme = call_604176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604176.url(scheme.get, call_604176.host, call_604176.base,
                         call_604176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604176, url, valid)

proc call*(call_604177: Call_SearchNetworkProfiles_604162; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchNetworkProfiles
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604178 = newJObject()
  var body_604179 = newJObject()
  add(query_604178, "NextToken", newJString(NextToken))
  if body != nil:
    body_604179 = body
  add(query_604178, "MaxResults", newJString(MaxResults))
  result = call_604177.call(nil, query_604178, nil, nil, body_604179)

var searchNetworkProfiles* = Call_SearchNetworkProfiles_604162(
    name: "searchNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchNetworkProfiles",
    validator: validate_SearchNetworkProfiles_604163, base: "/",
    url: url_SearchNetworkProfiles_604164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProfiles_604180 = ref object of OpenApiRestCall_602466
proc url_SearchProfiles_604182(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchProfiles_604181(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
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
  var valid_604183 = query.getOrDefault("NextToken")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "NextToken", valid_604183
  var valid_604184 = query.getOrDefault("MaxResults")
  valid_604184 = validateParameter(valid_604184, JString, required = false,
                                 default = nil)
  if valid_604184 != nil:
    section.add "MaxResults", valid_604184
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
  var valid_604185 = header.getOrDefault("X-Amz-Date")
  valid_604185 = validateParameter(valid_604185, JString, required = false,
                                 default = nil)
  if valid_604185 != nil:
    section.add "X-Amz-Date", valid_604185
  var valid_604186 = header.getOrDefault("X-Amz-Security-Token")
  valid_604186 = validateParameter(valid_604186, JString, required = false,
                                 default = nil)
  if valid_604186 != nil:
    section.add "X-Amz-Security-Token", valid_604186
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604187 = header.getOrDefault("X-Amz-Target")
  valid_604187 = validateParameter(valid_604187, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchProfiles"))
  if valid_604187 != nil:
    section.add "X-Amz-Target", valid_604187
  var valid_604188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604188 = validateParameter(valid_604188, JString, required = false,
                                 default = nil)
  if valid_604188 != nil:
    section.add "X-Amz-Content-Sha256", valid_604188
  var valid_604189 = header.getOrDefault("X-Amz-Algorithm")
  valid_604189 = validateParameter(valid_604189, JString, required = false,
                                 default = nil)
  if valid_604189 != nil:
    section.add "X-Amz-Algorithm", valid_604189
  var valid_604190 = header.getOrDefault("X-Amz-Signature")
  valid_604190 = validateParameter(valid_604190, JString, required = false,
                                 default = nil)
  if valid_604190 != nil:
    section.add "X-Amz-Signature", valid_604190
  var valid_604191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604191 = validateParameter(valid_604191, JString, required = false,
                                 default = nil)
  if valid_604191 != nil:
    section.add "X-Amz-SignedHeaders", valid_604191
  var valid_604192 = header.getOrDefault("X-Amz-Credential")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "X-Amz-Credential", valid_604192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604194: Call_SearchProfiles_604180; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
  ## 
  let valid = call_604194.validator(path, query, header, formData, body)
  let scheme = call_604194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604194.url(scheme.get, call_604194.host, call_604194.base,
                         call_604194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604194, url, valid)

proc call*(call_604195: Call_SearchProfiles_604180; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchProfiles
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604196 = newJObject()
  var body_604197 = newJObject()
  add(query_604196, "NextToken", newJString(NextToken))
  if body != nil:
    body_604197 = body
  add(query_604196, "MaxResults", newJString(MaxResults))
  result = call_604195.call(nil, query_604196, nil, nil, body_604197)

var searchProfiles* = Call_SearchProfiles_604180(name: "searchProfiles",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchProfiles",
    validator: validate_SearchProfiles_604181, base: "/", url: url_SearchProfiles_604182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchRooms_604198 = ref object of OpenApiRestCall_602466
proc url_SearchRooms_604200(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchRooms_604199(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
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
  var valid_604201 = query.getOrDefault("NextToken")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "NextToken", valid_604201
  var valid_604202 = query.getOrDefault("MaxResults")
  valid_604202 = validateParameter(valid_604202, JString, required = false,
                                 default = nil)
  if valid_604202 != nil:
    section.add "MaxResults", valid_604202
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
  var valid_604203 = header.getOrDefault("X-Amz-Date")
  valid_604203 = validateParameter(valid_604203, JString, required = false,
                                 default = nil)
  if valid_604203 != nil:
    section.add "X-Amz-Date", valid_604203
  var valid_604204 = header.getOrDefault("X-Amz-Security-Token")
  valid_604204 = validateParameter(valid_604204, JString, required = false,
                                 default = nil)
  if valid_604204 != nil:
    section.add "X-Amz-Security-Token", valid_604204
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604205 = header.getOrDefault("X-Amz-Target")
  valid_604205 = validateParameter(valid_604205, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchRooms"))
  if valid_604205 != nil:
    section.add "X-Amz-Target", valid_604205
  var valid_604206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604206 = validateParameter(valid_604206, JString, required = false,
                                 default = nil)
  if valid_604206 != nil:
    section.add "X-Amz-Content-Sha256", valid_604206
  var valid_604207 = header.getOrDefault("X-Amz-Algorithm")
  valid_604207 = validateParameter(valid_604207, JString, required = false,
                                 default = nil)
  if valid_604207 != nil:
    section.add "X-Amz-Algorithm", valid_604207
  var valid_604208 = header.getOrDefault("X-Amz-Signature")
  valid_604208 = validateParameter(valid_604208, JString, required = false,
                                 default = nil)
  if valid_604208 != nil:
    section.add "X-Amz-Signature", valid_604208
  var valid_604209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604209 = validateParameter(valid_604209, JString, required = false,
                                 default = nil)
  if valid_604209 != nil:
    section.add "X-Amz-SignedHeaders", valid_604209
  var valid_604210 = header.getOrDefault("X-Amz-Credential")
  valid_604210 = validateParameter(valid_604210, JString, required = false,
                                 default = nil)
  if valid_604210 != nil:
    section.add "X-Amz-Credential", valid_604210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604212: Call_SearchRooms_604198; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_604212.validator(path, query, header, formData, body)
  let scheme = call_604212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604212.url(scheme.get, call_604212.host, call_604212.base,
                         call_604212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604212, url, valid)

proc call*(call_604213: Call_SearchRooms_604198; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchRooms
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604214 = newJObject()
  var body_604215 = newJObject()
  add(query_604214, "NextToken", newJString(NextToken))
  if body != nil:
    body_604215 = body
  add(query_604214, "MaxResults", newJString(MaxResults))
  result = call_604213.call(nil, query_604214, nil, nil, body_604215)

var searchRooms* = Call_SearchRooms_604198(name: "searchRooms",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.SearchRooms",
                                        validator: validate_SearchRooms_604199,
                                        base: "/", url: url_SearchRooms_604200,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSkillGroups_604216 = ref object of OpenApiRestCall_602466
proc url_SearchSkillGroups_604218(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchSkillGroups_604217(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
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
  var valid_604219 = query.getOrDefault("NextToken")
  valid_604219 = validateParameter(valid_604219, JString, required = false,
                                 default = nil)
  if valid_604219 != nil:
    section.add "NextToken", valid_604219
  var valid_604220 = query.getOrDefault("MaxResults")
  valid_604220 = validateParameter(valid_604220, JString, required = false,
                                 default = nil)
  if valid_604220 != nil:
    section.add "MaxResults", valid_604220
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
  var valid_604221 = header.getOrDefault("X-Amz-Date")
  valid_604221 = validateParameter(valid_604221, JString, required = false,
                                 default = nil)
  if valid_604221 != nil:
    section.add "X-Amz-Date", valid_604221
  var valid_604222 = header.getOrDefault("X-Amz-Security-Token")
  valid_604222 = validateParameter(valid_604222, JString, required = false,
                                 default = nil)
  if valid_604222 != nil:
    section.add "X-Amz-Security-Token", valid_604222
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604223 = header.getOrDefault("X-Amz-Target")
  valid_604223 = validateParameter(valid_604223, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchSkillGroups"))
  if valid_604223 != nil:
    section.add "X-Amz-Target", valid_604223
  var valid_604224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604224 = validateParameter(valid_604224, JString, required = false,
                                 default = nil)
  if valid_604224 != nil:
    section.add "X-Amz-Content-Sha256", valid_604224
  var valid_604225 = header.getOrDefault("X-Amz-Algorithm")
  valid_604225 = validateParameter(valid_604225, JString, required = false,
                                 default = nil)
  if valid_604225 != nil:
    section.add "X-Amz-Algorithm", valid_604225
  var valid_604226 = header.getOrDefault("X-Amz-Signature")
  valid_604226 = validateParameter(valid_604226, JString, required = false,
                                 default = nil)
  if valid_604226 != nil:
    section.add "X-Amz-Signature", valid_604226
  var valid_604227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604227 = validateParameter(valid_604227, JString, required = false,
                                 default = nil)
  if valid_604227 != nil:
    section.add "X-Amz-SignedHeaders", valid_604227
  var valid_604228 = header.getOrDefault("X-Amz-Credential")
  valid_604228 = validateParameter(valid_604228, JString, required = false,
                                 default = nil)
  if valid_604228 != nil:
    section.add "X-Amz-Credential", valid_604228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604230: Call_SearchSkillGroups_604216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_604230.validator(path, query, header, formData, body)
  let scheme = call_604230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604230.url(scheme.get, call_604230.host, call_604230.base,
                         call_604230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604230, url, valid)

proc call*(call_604231: Call_SearchSkillGroups_604216; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchSkillGroups
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604232 = newJObject()
  var body_604233 = newJObject()
  add(query_604232, "NextToken", newJString(NextToken))
  if body != nil:
    body_604233 = body
  add(query_604232, "MaxResults", newJString(MaxResults))
  result = call_604231.call(nil, query_604232, nil, nil, body_604233)

var searchSkillGroups* = Call_SearchSkillGroups_604216(name: "searchSkillGroups",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchSkillGroups",
    validator: validate_SearchSkillGroups_604217, base: "/",
    url: url_SearchSkillGroups_604218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchUsers_604234 = ref object of OpenApiRestCall_602466
proc url_SearchUsers_604236(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchUsers_604235(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
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
  var valid_604237 = query.getOrDefault("NextToken")
  valid_604237 = validateParameter(valid_604237, JString, required = false,
                                 default = nil)
  if valid_604237 != nil:
    section.add "NextToken", valid_604237
  var valid_604238 = query.getOrDefault("MaxResults")
  valid_604238 = validateParameter(valid_604238, JString, required = false,
                                 default = nil)
  if valid_604238 != nil:
    section.add "MaxResults", valid_604238
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
  var valid_604239 = header.getOrDefault("X-Amz-Date")
  valid_604239 = validateParameter(valid_604239, JString, required = false,
                                 default = nil)
  if valid_604239 != nil:
    section.add "X-Amz-Date", valid_604239
  var valid_604240 = header.getOrDefault("X-Amz-Security-Token")
  valid_604240 = validateParameter(valid_604240, JString, required = false,
                                 default = nil)
  if valid_604240 != nil:
    section.add "X-Amz-Security-Token", valid_604240
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604241 = header.getOrDefault("X-Amz-Target")
  valid_604241 = validateParameter(valid_604241, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchUsers"))
  if valid_604241 != nil:
    section.add "X-Amz-Target", valid_604241
  var valid_604242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604242 = validateParameter(valid_604242, JString, required = false,
                                 default = nil)
  if valid_604242 != nil:
    section.add "X-Amz-Content-Sha256", valid_604242
  var valid_604243 = header.getOrDefault("X-Amz-Algorithm")
  valid_604243 = validateParameter(valid_604243, JString, required = false,
                                 default = nil)
  if valid_604243 != nil:
    section.add "X-Amz-Algorithm", valid_604243
  var valid_604244 = header.getOrDefault("X-Amz-Signature")
  valid_604244 = validateParameter(valid_604244, JString, required = false,
                                 default = nil)
  if valid_604244 != nil:
    section.add "X-Amz-Signature", valid_604244
  var valid_604245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = nil)
  if valid_604245 != nil:
    section.add "X-Amz-SignedHeaders", valid_604245
  var valid_604246 = header.getOrDefault("X-Amz-Credential")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "X-Amz-Credential", valid_604246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604248: Call_SearchUsers_604234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_604248.validator(path, query, header, formData, body)
  let scheme = call_604248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604248.url(scheme.get, call_604248.host, call_604248.base,
                         call_604248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604248, url, valid)

proc call*(call_604249: Call_SearchUsers_604234; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchUsers
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604250 = newJObject()
  var body_604251 = newJObject()
  add(query_604250, "NextToken", newJString(NextToken))
  if body != nil:
    body_604251 = body
  add(query_604250, "MaxResults", newJString(MaxResults))
  result = call_604249.call(nil, query_604250, nil, nil, body_604251)

var searchUsers* = Call_SearchUsers_604234(name: "searchUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.SearchUsers",
                                        validator: validate_SearchUsers_604235,
                                        base: "/", url: url_SearchUsers_604236,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAnnouncement_604252 = ref object of OpenApiRestCall_602466
proc url_SendAnnouncement_604254(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendAnnouncement_604253(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Triggers an asynchronous flow to send text, SSML, or audio announcements to rooms that are identified by a search or filter. 
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
  var valid_604255 = header.getOrDefault("X-Amz-Date")
  valid_604255 = validateParameter(valid_604255, JString, required = false,
                                 default = nil)
  if valid_604255 != nil:
    section.add "X-Amz-Date", valid_604255
  var valid_604256 = header.getOrDefault("X-Amz-Security-Token")
  valid_604256 = validateParameter(valid_604256, JString, required = false,
                                 default = nil)
  if valid_604256 != nil:
    section.add "X-Amz-Security-Token", valid_604256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604257 = header.getOrDefault("X-Amz-Target")
  valid_604257 = validateParameter(valid_604257, JString, required = true, default = newJString(
      "AlexaForBusiness.SendAnnouncement"))
  if valid_604257 != nil:
    section.add "X-Amz-Target", valid_604257
  var valid_604258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604258 = validateParameter(valid_604258, JString, required = false,
                                 default = nil)
  if valid_604258 != nil:
    section.add "X-Amz-Content-Sha256", valid_604258
  var valid_604259 = header.getOrDefault("X-Amz-Algorithm")
  valid_604259 = validateParameter(valid_604259, JString, required = false,
                                 default = nil)
  if valid_604259 != nil:
    section.add "X-Amz-Algorithm", valid_604259
  var valid_604260 = header.getOrDefault("X-Amz-Signature")
  valid_604260 = validateParameter(valid_604260, JString, required = false,
                                 default = nil)
  if valid_604260 != nil:
    section.add "X-Amz-Signature", valid_604260
  var valid_604261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604261 = validateParameter(valid_604261, JString, required = false,
                                 default = nil)
  if valid_604261 != nil:
    section.add "X-Amz-SignedHeaders", valid_604261
  var valid_604262 = header.getOrDefault("X-Amz-Credential")
  valid_604262 = validateParameter(valid_604262, JString, required = false,
                                 default = nil)
  if valid_604262 != nil:
    section.add "X-Amz-Credential", valid_604262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604264: Call_SendAnnouncement_604252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Triggers an asynchronous flow to send text, SSML, or audio announcements to rooms that are identified by a search or filter. 
  ## 
  let valid = call_604264.validator(path, query, header, formData, body)
  let scheme = call_604264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604264.url(scheme.get, call_604264.host, call_604264.base,
                         call_604264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604264, url, valid)

proc call*(call_604265: Call_SendAnnouncement_604252; body: JsonNode): Recallable =
  ## sendAnnouncement
  ## Triggers an asynchronous flow to send text, SSML, or audio announcements to rooms that are identified by a search or filter. 
  ##   body: JObject (required)
  var body_604266 = newJObject()
  if body != nil:
    body_604266 = body
  result = call_604265.call(nil, nil, nil, nil, body_604266)

var sendAnnouncement* = Call_SendAnnouncement_604252(name: "sendAnnouncement",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SendAnnouncement",
    validator: validate_SendAnnouncement_604253, base: "/",
    url: url_SendAnnouncement_604254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendInvitation_604267 = ref object of OpenApiRestCall_602466
proc url_SendInvitation_604269(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendInvitation_604268(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Sends an enrollment invitation email with a URL to a user. The URL is valid for 30 days or until you call this operation again, whichever comes first. 
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
  var valid_604270 = header.getOrDefault("X-Amz-Date")
  valid_604270 = validateParameter(valid_604270, JString, required = false,
                                 default = nil)
  if valid_604270 != nil:
    section.add "X-Amz-Date", valid_604270
  var valid_604271 = header.getOrDefault("X-Amz-Security-Token")
  valid_604271 = validateParameter(valid_604271, JString, required = false,
                                 default = nil)
  if valid_604271 != nil:
    section.add "X-Amz-Security-Token", valid_604271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604272 = header.getOrDefault("X-Amz-Target")
  valid_604272 = validateParameter(valid_604272, JString, required = true, default = newJString(
      "AlexaForBusiness.SendInvitation"))
  if valid_604272 != nil:
    section.add "X-Amz-Target", valid_604272
  var valid_604273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604273 = validateParameter(valid_604273, JString, required = false,
                                 default = nil)
  if valid_604273 != nil:
    section.add "X-Amz-Content-Sha256", valid_604273
  var valid_604274 = header.getOrDefault("X-Amz-Algorithm")
  valid_604274 = validateParameter(valid_604274, JString, required = false,
                                 default = nil)
  if valid_604274 != nil:
    section.add "X-Amz-Algorithm", valid_604274
  var valid_604275 = header.getOrDefault("X-Amz-Signature")
  valid_604275 = validateParameter(valid_604275, JString, required = false,
                                 default = nil)
  if valid_604275 != nil:
    section.add "X-Amz-Signature", valid_604275
  var valid_604276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604276 = validateParameter(valid_604276, JString, required = false,
                                 default = nil)
  if valid_604276 != nil:
    section.add "X-Amz-SignedHeaders", valid_604276
  var valid_604277 = header.getOrDefault("X-Amz-Credential")
  valid_604277 = validateParameter(valid_604277, JString, required = false,
                                 default = nil)
  if valid_604277 != nil:
    section.add "X-Amz-Credential", valid_604277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604279: Call_SendInvitation_604267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends an enrollment invitation email with a URL to a user. The URL is valid for 30 days or until you call this operation again, whichever comes first. 
  ## 
  let valid = call_604279.validator(path, query, header, formData, body)
  let scheme = call_604279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604279.url(scheme.get, call_604279.host, call_604279.base,
                         call_604279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604279, url, valid)

proc call*(call_604280: Call_SendInvitation_604267; body: JsonNode): Recallable =
  ## sendInvitation
  ## Sends an enrollment invitation email with a URL to a user. The URL is valid for 30 days or until you call this operation again, whichever comes first. 
  ##   body: JObject (required)
  var body_604281 = newJObject()
  if body != nil:
    body_604281 = body
  result = call_604280.call(nil, nil, nil, nil, body_604281)

var sendInvitation* = Call_SendInvitation_604267(name: "sendInvitation",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SendInvitation",
    validator: validate_SendInvitation_604268, base: "/", url: url_SendInvitation_604269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeviceSync_604282 = ref object of OpenApiRestCall_602466
proc url_StartDeviceSync_604284(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartDeviceSync_604283(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Resets a device and its account to the known default settings. This clears all information and settings set by previous users in the following ways:</p> <ul> <li> <p>Bluetooth - This unpairs all bluetooth devices paired with your echo device.</p> </li> <li> <p>Volume - This resets the echo device's volume to the default value.</p> </li> <li> <p>Notifications - This clears all notifications from your echo device.</p> </li> <li> <p>Lists - This clears all to-do items from your echo device.</p> </li> <li> <p>Settings - This internally syncs the room's profile (if the device is assigned to a room), contacts, address books, delegation access for account linking, and communications (if enabled on the room profile).</p> </li> </ul>
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
  var valid_604285 = header.getOrDefault("X-Amz-Date")
  valid_604285 = validateParameter(valid_604285, JString, required = false,
                                 default = nil)
  if valid_604285 != nil:
    section.add "X-Amz-Date", valid_604285
  var valid_604286 = header.getOrDefault("X-Amz-Security-Token")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "X-Amz-Security-Token", valid_604286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604287 = header.getOrDefault("X-Amz-Target")
  valid_604287 = validateParameter(valid_604287, JString, required = true, default = newJString(
      "AlexaForBusiness.StartDeviceSync"))
  if valid_604287 != nil:
    section.add "X-Amz-Target", valid_604287
  var valid_604288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604288 = validateParameter(valid_604288, JString, required = false,
                                 default = nil)
  if valid_604288 != nil:
    section.add "X-Amz-Content-Sha256", valid_604288
  var valid_604289 = header.getOrDefault("X-Amz-Algorithm")
  valid_604289 = validateParameter(valid_604289, JString, required = false,
                                 default = nil)
  if valid_604289 != nil:
    section.add "X-Amz-Algorithm", valid_604289
  var valid_604290 = header.getOrDefault("X-Amz-Signature")
  valid_604290 = validateParameter(valid_604290, JString, required = false,
                                 default = nil)
  if valid_604290 != nil:
    section.add "X-Amz-Signature", valid_604290
  var valid_604291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604291 = validateParameter(valid_604291, JString, required = false,
                                 default = nil)
  if valid_604291 != nil:
    section.add "X-Amz-SignedHeaders", valid_604291
  var valid_604292 = header.getOrDefault("X-Amz-Credential")
  valid_604292 = validateParameter(valid_604292, JString, required = false,
                                 default = nil)
  if valid_604292 != nil:
    section.add "X-Amz-Credential", valid_604292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604294: Call_StartDeviceSync_604282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets a device and its account to the known default settings. This clears all information and settings set by previous users in the following ways:</p> <ul> <li> <p>Bluetooth - This unpairs all bluetooth devices paired with your echo device.</p> </li> <li> <p>Volume - This resets the echo device's volume to the default value.</p> </li> <li> <p>Notifications - This clears all notifications from your echo device.</p> </li> <li> <p>Lists - This clears all to-do items from your echo device.</p> </li> <li> <p>Settings - This internally syncs the room's profile (if the device is assigned to a room), contacts, address books, delegation access for account linking, and communications (if enabled on the room profile).</p> </li> </ul>
  ## 
  let valid = call_604294.validator(path, query, header, formData, body)
  let scheme = call_604294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604294.url(scheme.get, call_604294.host, call_604294.base,
                         call_604294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604294, url, valid)

proc call*(call_604295: Call_StartDeviceSync_604282; body: JsonNode): Recallable =
  ## startDeviceSync
  ## <p>Resets a device and its account to the known default settings. This clears all information and settings set by previous users in the following ways:</p> <ul> <li> <p>Bluetooth - This unpairs all bluetooth devices paired with your echo device.</p> </li> <li> <p>Volume - This resets the echo device's volume to the default value.</p> </li> <li> <p>Notifications - This clears all notifications from your echo device.</p> </li> <li> <p>Lists - This clears all to-do items from your echo device.</p> </li> <li> <p>Settings - This internally syncs the room's profile (if the device is assigned to a room), contacts, address books, delegation access for account linking, and communications (if enabled on the room profile).</p> </li> </ul>
  ##   body: JObject (required)
  var body_604296 = newJObject()
  if body != nil:
    body_604296 = body
  result = call_604295.call(nil, nil, nil, nil, body_604296)

var startDeviceSync* = Call_StartDeviceSync_604282(name: "startDeviceSync",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.StartDeviceSync",
    validator: validate_StartDeviceSync_604283, base: "/", url: url_StartDeviceSync_604284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSmartHomeApplianceDiscovery_604297 = ref object of OpenApiRestCall_602466
proc url_StartSmartHomeApplianceDiscovery_604299(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartSmartHomeApplianceDiscovery_604298(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Initiates the discovery of any smart home appliances associated with the room.
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
  var valid_604300 = header.getOrDefault("X-Amz-Date")
  valid_604300 = validateParameter(valid_604300, JString, required = false,
                                 default = nil)
  if valid_604300 != nil:
    section.add "X-Amz-Date", valid_604300
  var valid_604301 = header.getOrDefault("X-Amz-Security-Token")
  valid_604301 = validateParameter(valid_604301, JString, required = false,
                                 default = nil)
  if valid_604301 != nil:
    section.add "X-Amz-Security-Token", valid_604301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604302 = header.getOrDefault("X-Amz-Target")
  valid_604302 = validateParameter(valid_604302, JString, required = true, default = newJString(
      "AlexaForBusiness.StartSmartHomeApplianceDiscovery"))
  if valid_604302 != nil:
    section.add "X-Amz-Target", valid_604302
  var valid_604303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604303 = validateParameter(valid_604303, JString, required = false,
                                 default = nil)
  if valid_604303 != nil:
    section.add "X-Amz-Content-Sha256", valid_604303
  var valid_604304 = header.getOrDefault("X-Amz-Algorithm")
  valid_604304 = validateParameter(valid_604304, JString, required = false,
                                 default = nil)
  if valid_604304 != nil:
    section.add "X-Amz-Algorithm", valid_604304
  var valid_604305 = header.getOrDefault("X-Amz-Signature")
  valid_604305 = validateParameter(valid_604305, JString, required = false,
                                 default = nil)
  if valid_604305 != nil:
    section.add "X-Amz-Signature", valid_604305
  var valid_604306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604306 = validateParameter(valid_604306, JString, required = false,
                                 default = nil)
  if valid_604306 != nil:
    section.add "X-Amz-SignedHeaders", valid_604306
  var valid_604307 = header.getOrDefault("X-Amz-Credential")
  valid_604307 = validateParameter(valid_604307, JString, required = false,
                                 default = nil)
  if valid_604307 != nil:
    section.add "X-Amz-Credential", valid_604307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604309: Call_StartSmartHomeApplianceDiscovery_604297;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Initiates the discovery of any smart home appliances associated with the room.
  ## 
  let valid = call_604309.validator(path, query, header, formData, body)
  let scheme = call_604309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604309.url(scheme.get, call_604309.host, call_604309.base,
                         call_604309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604309, url, valid)

proc call*(call_604310: Call_StartSmartHomeApplianceDiscovery_604297;
          body: JsonNode): Recallable =
  ## startSmartHomeApplianceDiscovery
  ## Initiates the discovery of any smart home appliances associated with the room.
  ##   body: JObject (required)
  var body_604311 = newJObject()
  if body != nil:
    body_604311 = body
  result = call_604310.call(nil, nil, nil, nil, body_604311)

var startSmartHomeApplianceDiscovery* = Call_StartSmartHomeApplianceDiscovery_604297(
    name: "startSmartHomeApplianceDiscovery", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.StartSmartHomeApplianceDiscovery",
    validator: validate_StartSmartHomeApplianceDiscovery_604298, base: "/",
    url: url_StartSmartHomeApplianceDiscovery_604299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_604312 = ref object of OpenApiRestCall_602466
proc url_TagResource_604314(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_604313(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds metadata tags to a specified resource.
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
  var valid_604315 = header.getOrDefault("X-Amz-Date")
  valid_604315 = validateParameter(valid_604315, JString, required = false,
                                 default = nil)
  if valid_604315 != nil:
    section.add "X-Amz-Date", valid_604315
  var valid_604316 = header.getOrDefault("X-Amz-Security-Token")
  valid_604316 = validateParameter(valid_604316, JString, required = false,
                                 default = nil)
  if valid_604316 != nil:
    section.add "X-Amz-Security-Token", valid_604316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604317 = header.getOrDefault("X-Amz-Target")
  valid_604317 = validateParameter(valid_604317, JString, required = true, default = newJString(
      "AlexaForBusiness.TagResource"))
  if valid_604317 != nil:
    section.add "X-Amz-Target", valid_604317
  var valid_604318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604318 = validateParameter(valid_604318, JString, required = false,
                                 default = nil)
  if valid_604318 != nil:
    section.add "X-Amz-Content-Sha256", valid_604318
  var valid_604319 = header.getOrDefault("X-Amz-Algorithm")
  valid_604319 = validateParameter(valid_604319, JString, required = false,
                                 default = nil)
  if valid_604319 != nil:
    section.add "X-Amz-Algorithm", valid_604319
  var valid_604320 = header.getOrDefault("X-Amz-Signature")
  valid_604320 = validateParameter(valid_604320, JString, required = false,
                                 default = nil)
  if valid_604320 != nil:
    section.add "X-Amz-Signature", valid_604320
  var valid_604321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604321 = validateParameter(valid_604321, JString, required = false,
                                 default = nil)
  if valid_604321 != nil:
    section.add "X-Amz-SignedHeaders", valid_604321
  var valid_604322 = header.getOrDefault("X-Amz-Credential")
  valid_604322 = validateParameter(valid_604322, JString, required = false,
                                 default = nil)
  if valid_604322 != nil:
    section.add "X-Amz-Credential", valid_604322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604324: Call_TagResource_604312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to a specified resource.
  ## 
  let valid = call_604324.validator(path, query, header, formData, body)
  let scheme = call_604324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604324.url(scheme.get, call_604324.host, call_604324.base,
                         call_604324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604324, url, valid)

proc call*(call_604325: Call_TagResource_604312; body: JsonNode): Recallable =
  ## tagResource
  ## Adds metadata tags to a specified resource.
  ##   body: JObject (required)
  var body_604326 = newJObject()
  if body != nil:
    body_604326 = body
  result = call_604325.call(nil, nil, nil, nil, body_604326)

var tagResource* = Call_TagResource_604312(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.TagResource",
                                        validator: validate_TagResource_604313,
                                        base: "/", url: url_TagResource_604314,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_604327 = ref object of OpenApiRestCall_602466
proc url_UntagResource_604329(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_604328(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes metadata tags from a specified resource.
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
  var valid_604330 = header.getOrDefault("X-Amz-Date")
  valid_604330 = validateParameter(valid_604330, JString, required = false,
                                 default = nil)
  if valid_604330 != nil:
    section.add "X-Amz-Date", valid_604330
  var valid_604331 = header.getOrDefault("X-Amz-Security-Token")
  valid_604331 = validateParameter(valid_604331, JString, required = false,
                                 default = nil)
  if valid_604331 != nil:
    section.add "X-Amz-Security-Token", valid_604331
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604332 = header.getOrDefault("X-Amz-Target")
  valid_604332 = validateParameter(valid_604332, JString, required = true, default = newJString(
      "AlexaForBusiness.UntagResource"))
  if valid_604332 != nil:
    section.add "X-Amz-Target", valid_604332
  var valid_604333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604333 = validateParameter(valid_604333, JString, required = false,
                                 default = nil)
  if valid_604333 != nil:
    section.add "X-Amz-Content-Sha256", valid_604333
  var valid_604334 = header.getOrDefault("X-Amz-Algorithm")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "X-Amz-Algorithm", valid_604334
  var valid_604335 = header.getOrDefault("X-Amz-Signature")
  valid_604335 = validateParameter(valid_604335, JString, required = false,
                                 default = nil)
  if valid_604335 != nil:
    section.add "X-Amz-Signature", valid_604335
  var valid_604336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604336 = validateParameter(valid_604336, JString, required = false,
                                 default = nil)
  if valid_604336 != nil:
    section.add "X-Amz-SignedHeaders", valid_604336
  var valid_604337 = header.getOrDefault("X-Amz-Credential")
  valid_604337 = validateParameter(valid_604337, JString, required = false,
                                 default = nil)
  if valid_604337 != nil:
    section.add "X-Amz-Credential", valid_604337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604339: Call_UntagResource_604327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from a specified resource.
  ## 
  let valid = call_604339.validator(path, query, header, formData, body)
  let scheme = call_604339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604339.url(scheme.get, call_604339.host, call_604339.base,
                         call_604339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604339, url, valid)

proc call*(call_604340: Call_UntagResource_604327; body: JsonNode): Recallable =
  ## untagResource
  ## Removes metadata tags from a specified resource.
  ##   body: JObject (required)
  var body_604341 = newJObject()
  if body != nil:
    body_604341 = body
  result = call_604340.call(nil, nil, nil, nil, body_604341)

var untagResource* = Call_UntagResource_604327(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UntagResource",
    validator: validate_UntagResource_604328, base: "/", url: url_UntagResource_604329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAddressBook_604342 = ref object of OpenApiRestCall_602466
proc url_UpdateAddressBook_604344(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAddressBook_604343(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates address book details by the address book ARN.
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
  var valid_604345 = header.getOrDefault("X-Amz-Date")
  valid_604345 = validateParameter(valid_604345, JString, required = false,
                                 default = nil)
  if valid_604345 != nil:
    section.add "X-Amz-Date", valid_604345
  var valid_604346 = header.getOrDefault("X-Amz-Security-Token")
  valid_604346 = validateParameter(valid_604346, JString, required = false,
                                 default = nil)
  if valid_604346 != nil:
    section.add "X-Amz-Security-Token", valid_604346
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604347 = header.getOrDefault("X-Amz-Target")
  valid_604347 = validateParameter(valid_604347, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateAddressBook"))
  if valid_604347 != nil:
    section.add "X-Amz-Target", valid_604347
  var valid_604348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604348 = validateParameter(valid_604348, JString, required = false,
                                 default = nil)
  if valid_604348 != nil:
    section.add "X-Amz-Content-Sha256", valid_604348
  var valid_604349 = header.getOrDefault("X-Amz-Algorithm")
  valid_604349 = validateParameter(valid_604349, JString, required = false,
                                 default = nil)
  if valid_604349 != nil:
    section.add "X-Amz-Algorithm", valid_604349
  var valid_604350 = header.getOrDefault("X-Amz-Signature")
  valid_604350 = validateParameter(valid_604350, JString, required = false,
                                 default = nil)
  if valid_604350 != nil:
    section.add "X-Amz-Signature", valid_604350
  var valid_604351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604351 = validateParameter(valid_604351, JString, required = false,
                                 default = nil)
  if valid_604351 != nil:
    section.add "X-Amz-SignedHeaders", valid_604351
  var valid_604352 = header.getOrDefault("X-Amz-Credential")
  valid_604352 = validateParameter(valid_604352, JString, required = false,
                                 default = nil)
  if valid_604352 != nil:
    section.add "X-Amz-Credential", valid_604352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604354: Call_UpdateAddressBook_604342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates address book details by the address book ARN.
  ## 
  let valid = call_604354.validator(path, query, header, formData, body)
  let scheme = call_604354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604354.url(scheme.get, call_604354.host, call_604354.base,
                         call_604354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604354, url, valid)

proc call*(call_604355: Call_UpdateAddressBook_604342; body: JsonNode): Recallable =
  ## updateAddressBook
  ## Updates address book details by the address book ARN.
  ##   body: JObject (required)
  var body_604356 = newJObject()
  if body != nil:
    body_604356 = body
  result = call_604355.call(nil, nil, nil, nil, body_604356)

var updateAddressBook* = Call_UpdateAddressBook_604342(name: "updateAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateAddressBook",
    validator: validate_UpdateAddressBook_604343, base: "/",
    url: url_UpdateAddressBook_604344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBusinessReportSchedule_604357 = ref object of OpenApiRestCall_602466
proc url_UpdateBusinessReportSchedule_604359(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateBusinessReportSchedule_604358(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the configuration of the report delivery schedule with the specified schedule ARN.
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
  var valid_604360 = header.getOrDefault("X-Amz-Date")
  valid_604360 = validateParameter(valid_604360, JString, required = false,
                                 default = nil)
  if valid_604360 != nil:
    section.add "X-Amz-Date", valid_604360
  var valid_604361 = header.getOrDefault("X-Amz-Security-Token")
  valid_604361 = validateParameter(valid_604361, JString, required = false,
                                 default = nil)
  if valid_604361 != nil:
    section.add "X-Amz-Security-Token", valid_604361
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604362 = header.getOrDefault("X-Amz-Target")
  valid_604362 = validateParameter(valid_604362, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateBusinessReportSchedule"))
  if valid_604362 != nil:
    section.add "X-Amz-Target", valid_604362
  var valid_604363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604363 = validateParameter(valid_604363, JString, required = false,
                                 default = nil)
  if valid_604363 != nil:
    section.add "X-Amz-Content-Sha256", valid_604363
  var valid_604364 = header.getOrDefault("X-Amz-Algorithm")
  valid_604364 = validateParameter(valid_604364, JString, required = false,
                                 default = nil)
  if valid_604364 != nil:
    section.add "X-Amz-Algorithm", valid_604364
  var valid_604365 = header.getOrDefault("X-Amz-Signature")
  valid_604365 = validateParameter(valid_604365, JString, required = false,
                                 default = nil)
  if valid_604365 != nil:
    section.add "X-Amz-Signature", valid_604365
  var valid_604366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604366 = validateParameter(valid_604366, JString, required = false,
                                 default = nil)
  if valid_604366 != nil:
    section.add "X-Amz-SignedHeaders", valid_604366
  var valid_604367 = header.getOrDefault("X-Amz-Credential")
  valid_604367 = validateParameter(valid_604367, JString, required = false,
                                 default = nil)
  if valid_604367 != nil:
    section.add "X-Amz-Credential", valid_604367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604369: Call_UpdateBusinessReportSchedule_604357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration of the report delivery schedule with the specified schedule ARN.
  ## 
  let valid = call_604369.validator(path, query, header, formData, body)
  let scheme = call_604369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604369.url(scheme.get, call_604369.host, call_604369.base,
                         call_604369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604369, url, valid)

proc call*(call_604370: Call_UpdateBusinessReportSchedule_604357; body: JsonNode): Recallable =
  ## updateBusinessReportSchedule
  ## Updates the configuration of the report delivery schedule with the specified schedule ARN.
  ##   body: JObject (required)
  var body_604371 = newJObject()
  if body != nil:
    body_604371 = body
  result = call_604370.call(nil, nil, nil, nil, body_604371)

var updateBusinessReportSchedule* = Call_UpdateBusinessReportSchedule_604357(
    name: "updateBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateBusinessReportSchedule",
    validator: validate_UpdateBusinessReportSchedule_604358, base: "/",
    url: url_UpdateBusinessReportSchedule_604359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConferenceProvider_604372 = ref object of OpenApiRestCall_602466
proc url_UpdateConferenceProvider_604374(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateConferenceProvider_604373(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing conference provider's settings.
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
  var valid_604375 = header.getOrDefault("X-Amz-Date")
  valid_604375 = validateParameter(valid_604375, JString, required = false,
                                 default = nil)
  if valid_604375 != nil:
    section.add "X-Amz-Date", valid_604375
  var valid_604376 = header.getOrDefault("X-Amz-Security-Token")
  valid_604376 = validateParameter(valid_604376, JString, required = false,
                                 default = nil)
  if valid_604376 != nil:
    section.add "X-Amz-Security-Token", valid_604376
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604377 = header.getOrDefault("X-Amz-Target")
  valid_604377 = validateParameter(valid_604377, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateConferenceProvider"))
  if valid_604377 != nil:
    section.add "X-Amz-Target", valid_604377
  var valid_604378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604378 = validateParameter(valid_604378, JString, required = false,
                                 default = nil)
  if valid_604378 != nil:
    section.add "X-Amz-Content-Sha256", valid_604378
  var valid_604379 = header.getOrDefault("X-Amz-Algorithm")
  valid_604379 = validateParameter(valid_604379, JString, required = false,
                                 default = nil)
  if valid_604379 != nil:
    section.add "X-Amz-Algorithm", valid_604379
  var valid_604380 = header.getOrDefault("X-Amz-Signature")
  valid_604380 = validateParameter(valid_604380, JString, required = false,
                                 default = nil)
  if valid_604380 != nil:
    section.add "X-Amz-Signature", valid_604380
  var valid_604381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604381 = validateParameter(valid_604381, JString, required = false,
                                 default = nil)
  if valid_604381 != nil:
    section.add "X-Amz-SignedHeaders", valid_604381
  var valid_604382 = header.getOrDefault("X-Amz-Credential")
  valid_604382 = validateParameter(valid_604382, JString, required = false,
                                 default = nil)
  if valid_604382 != nil:
    section.add "X-Amz-Credential", valid_604382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604384: Call_UpdateConferenceProvider_604372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing conference provider's settings.
  ## 
  let valid = call_604384.validator(path, query, header, formData, body)
  let scheme = call_604384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604384.url(scheme.get, call_604384.host, call_604384.base,
                         call_604384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604384, url, valid)

proc call*(call_604385: Call_UpdateConferenceProvider_604372; body: JsonNode): Recallable =
  ## updateConferenceProvider
  ## Updates an existing conference provider's settings.
  ##   body: JObject (required)
  var body_604386 = newJObject()
  if body != nil:
    body_604386 = body
  result = call_604385.call(nil, nil, nil, nil, body_604386)

var updateConferenceProvider* = Call_UpdateConferenceProvider_604372(
    name: "updateConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateConferenceProvider",
    validator: validate_UpdateConferenceProvider_604373, base: "/",
    url: url_UpdateConferenceProvider_604374, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContact_604387 = ref object of OpenApiRestCall_602466
proc url_UpdateContact_604389(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateContact_604388(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the contact details by the contact ARN.
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
  var valid_604390 = header.getOrDefault("X-Amz-Date")
  valid_604390 = validateParameter(valid_604390, JString, required = false,
                                 default = nil)
  if valid_604390 != nil:
    section.add "X-Amz-Date", valid_604390
  var valid_604391 = header.getOrDefault("X-Amz-Security-Token")
  valid_604391 = validateParameter(valid_604391, JString, required = false,
                                 default = nil)
  if valid_604391 != nil:
    section.add "X-Amz-Security-Token", valid_604391
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604392 = header.getOrDefault("X-Amz-Target")
  valid_604392 = validateParameter(valid_604392, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateContact"))
  if valid_604392 != nil:
    section.add "X-Amz-Target", valid_604392
  var valid_604393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604393 = validateParameter(valid_604393, JString, required = false,
                                 default = nil)
  if valid_604393 != nil:
    section.add "X-Amz-Content-Sha256", valid_604393
  var valid_604394 = header.getOrDefault("X-Amz-Algorithm")
  valid_604394 = validateParameter(valid_604394, JString, required = false,
                                 default = nil)
  if valid_604394 != nil:
    section.add "X-Amz-Algorithm", valid_604394
  var valid_604395 = header.getOrDefault("X-Amz-Signature")
  valid_604395 = validateParameter(valid_604395, JString, required = false,
                                 default = nil)
  if valid_604395 != nil:
    section.add "X-Amz-Signature", valid_604395
  var valid_604396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604396 = validateParameter(valid_604396, JString, required = false,
                                 default = nil)
  if valid_604396 != nil:
    section.add "X-Amz-SignedHeaders", valid_604396
  var valid_604397 = header.getOrDefault("X-Amz-Credential")
  valid_604397 = validateParameter(valid_604397, JString, required = false,
                                 default = nil)
  if valid_604397 != nil:
    section.add "X-Amz-Credential", valid_604397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604399: Call_UpdateContact_604387; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the contact details by the contact ARN.
  ## 
  let valid = call_604399.validator(path, query, header, formData, body)
  let scheme = call_604399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604399.url(scheme.get, call_604399.host, call_604399.base,
                         call_604399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604399, url, valid)

proc call*(call_604400: Call_UpdateContact_604387; body: JsonNode): Recallable =
  ## updateContact
  ## Updates the contact details by the contact ARN.
  ##   body: JObject (required)
  var body_604401 = newJObject()
  if body != nil:
    body_604401 = body
  result = call_604400.call(nil, nil, nil, nil, body_604401)

var updateContact* = Call_UpdateContact_604387(name: "updateContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateContact",
    validator: validate_UpdateContact_604388, base: "/", url: url_UpdateContact_604389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevice_604402 = ref object of OpenApiRestCall_602466
proc url_UpdateDevice_604404(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDevice_604403(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the device name by device ARN.
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
  var valid_604405 = header.getOrDefault("X-Amz-Date")
  valid_604405 = validateParameter(valid_604405, JString, required = false,
                                 default = nil)
  if valid_604405 != nil:
    section.add "X-Amz-Date", valid_604405
  var valid_604406 = header.getOrDefault("X-Amz-Security-Token")
  valid_604406 = validateParameter(valid_604406, JString, required = false,
                                 default = nil)
  if valid_604406 != nil:
    section.add "X-Amz-Security-Token", valid_604406
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604407 = header.getOrDefault("X-Amz-Target")
  valid_604407 = validateParameter(valid_604407, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateDevice"))
  if valid_604407 != nil:
    section.add "X-Amz-Target", valid_604407
  var valid_604408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604408 = validateParameter(valid_604408, JString, required = false,
                                 default = nil)
  if valid_604408 != nil:
    section.add "X-Amz-Content-Sha256", valid_604408
  var valid_604409 = header.getOrDefault("X-Amz-Algorithm")
  valid_604409 = validateParameter(valid_604409, JString, required = false,
                                 default = nil)
  if valid_604409 != nil:
    section.add "X-Amz-Algorithm", valid_604409
  var valid_604410 = header.getOrDefault("X-Amz-Signature")
  valid_604410 = validateParameter(valid_604410, JString, required = false,
                                 default = nil)
  if valid_604410 != nil:
    section.add "X-Amz-Signature", valid_604410
  var valid_604411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604411 = validateParameter(valid_604411, JString, required = false,
                                 default = nil)
  if valid_604411 != nil:
    section.add "X-Amz-SignedHeaders", valid_604411
  var valid_604412 = header.getOrDefault("X-Amz-Credential")
  valid_604412 = validateParameter(valid_604412, JString, required = false,
                                 default = nil)
  if valid_604412 != nil:
    section.add "X-Amz-Credential", valid_604412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604414: Call_UpdateDevice_604402; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the device name by device ARN.
  ## 
  let valid = call_604414.validator(path, query, header, formData, body)
  let scheme = call_604414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604414.url(scheme.get, call_604414.host, call_604414.base,
                         call_604414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604414, url, valid)

proc call*(call_604415: Call_UpdateDevice_604402; body: JsonNode): Recallable =
  ## updateDevice
  ## Updates the device name by device ARN.
  ##   body: JObject (required)
  var body_604416 = newJObject()
  if body != nil:
    body_604416 = body
  result = call_604415.call(nil, nil, nil, nil, body_604416)

var updateDevice* = Call_UpdateDevice_604402(name: "updateDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateDevice",
    validator: validate_UpdateDevice_604403, base: "/", url: url_UpdateDevice_604404,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGateway_604417 = ref object of OpenApiRestCall_602466
proc url_UpdateGateway_604419(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGateway_604418(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the details of a gateway. If any optional field is not provided, the existing corresponding value is left unmodified.
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
  var valid_604420 = header.getOrDefault("X-Amz-Date")
  valid_604420 = validateParameter(valid_604420, JString, required = false,
                                 default = nil)
  if valid_604420 != nil:
    section.add "X-Amz-Date", valid_604420
  var valid_604421 = header.getOrDefault("X-Amz-Security-Token")
  valid_604421 = validateParameter(valid_604421, JString, required = false,
                                 default = nil)
  if valid_604421 != nil:
    section.add "X-Amz-Security-Token", valid_604421
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604422 = header.getOrDefault("X-Amz-Target")
  valid_604422 = validateParameter(valid_604422, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateGateway"))
  if valid_604422 != nil:
    section.add "X-Amz-Target", valid_604422
  var valid_604423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604423 = validateParameter(valid_604423, JString, required = false,
                                 default = nil)
  if valid_604423 != nil:
    section.add "X-Amz-Content-Sha256", valid_604423
  var valid_604424 = header.getOrDefault("X-Amz-Algorithm")
  valid_604424 = validateParameter(valid_604424, JString, required = false,
                                 default = nil)
  if valid_604424 != nil:
    section.add "X-Amz-Algorithm", valid_604424
  var valid_604425 = header.getOrDefault("X-Amz-Signature")
  valid_604425 = validateParameter(valid_604425, JString, required = false,
                                 default = nil)
  if valid_604425 != nil:
    section.add "X-Amz-Signature", valid_604425
  var valid_604426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "X-Amz-SignedHeaders", valid_604426
  var valid_604427 = header.getOrDefault("X-Amz-Credential")
  valid_604427 = validateParameter(valid_604427, JString, required = false,
                                 default = nil)
  if valid_604427 != nil:
    section.add "X-Amz-Credential", valid_604427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604429: Call_UpdateGateway_604417; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details of a gateway. If any optional field is not provided, the existing corresponding value is left unmodified.
  ## 
  let valid = call_604429.validator(path, query, header, formData, body)
  let scheme = call_604429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604429.url(scheme.get, call_604429.host, call_604429.base,
                         call_604429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604429, url, valid)

proc call*(call_604430: Call_UpdateGateway_604417; body: JsonNode): Recallable =
  ## updateGateway
  ## Updates the details of a gateway. If any optional field is not provided, the existing corresponding value is left unmodified.
  ##   body: JObject (required)
  var body_604431 = newJObject()
  if body != nil:
    body_604431 = body
  result = call_604430.call(nil, nil, nil, nil, body_604431)

var updateGateway* = Call_UpdateGateway_604417(name: "updateGateway",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateGateway",
    validator: validate_UpdateGateway_604418, base: "/", url: url_UpdateGateway_604419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayGroup_604432 = ref object of OpenApiRestCall_602466
proc url_UpdateGatewayGroup_604434(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGatewayGroup_604433(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Updates the details of a gateway group. If any optional field is not provided, the existing corresponding value is left unmodified.
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
  var valid_604435 = header.getOrDefault("X-Amz-Date")
  valid_604435 = validateParameter(valid_604435, JString, required = false,
                                 default = nil)
  if valid_604435 != nil:
    section.add "X-Amz-Date", valid_604435
  var valid_604436 = header.getOrDefault("X-Amz-Security-Token")
  valid_604436 = validateParameter(valid_604436, JString, required = false,
                                 default = nil)
  if valid_604436 != nil:
    section.add "X-Amz-Security-Token", valid_604436
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604437 = header.getOrDefault("X-Amz-Target")
  valid_604437 = validateParameter(valid_604437, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateGatewayGroup"))
  if valid_604437 != nil:
    section.add "X-Amz-Target", valid_604437
  var valid_604438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604438 = validateParameter(valid_604438, JString, required = false,
                                 default = nil)
  if valid_604438 != nil:
    section.add "X-Amz-Content-Sha256", valid_604438
  var valid_604439 = header.getOrDefault("X-Amz-Algorithm")
  valid_604439 = validateParameter(valid_604439, JString, required = false,
                                 default = nil)
  if valid_604439 != nil:
    section.add "X-Amz-Algorithm", valid_604439
  var valid_604440 = header.getOrDefault("X-Amz-Signature")
  valid_604440 = validateParameter(valid_604440, JString, required = false,
                                 default = nil)
  if valid_604440 != nil:
    section.add "X-Amz-Signature", valid_604440
  var valid_604441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604441 = validateParameter(valid_604441, JString, required = false,
                                 default = nil)
  if valid_604441 != nil:
    section.add "X-Amz-SignedHeaders", valid_604441
  var valid_604442 = header.getOrDefault("X-Amz-Credential")
  valid_604442 = validateParameter(valid_604442, JString, required = false,
                                 default = nil)
  if valid_604442 != nil:
    section.add "X-Amz-Credential", valid_604442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604444: Call_UpdateGatewayGroup_604432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details of a gateway group. If any optional field is not provided, the existing corresponding value is left unmodified.
  ## 
  let valid = call_604444.validator(path, query, header, formData, body)
  let scheme = call_604444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604444.url(scheme.get, call_604444.host, call_604444.base,
                         call_604444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604444, url, valid)

proc call*(call_604445: Call_UpdateGatewayGroup_604432; body: JsonNode): Recallable =
  ## updateGatewayGroup
  ## Updates the details of a gateway group. If any optional field is not provided, the existing corresponding value is left unmodified.
  ##   body: JObject (required)
  var body_604446 = newJObject()
  if body != nil:
    body_604446 = body
  result = call_604445.call(nil, nil, nil, nil, body_604446)

var updateGatewayGroup* = Call_UpdateGatewayGroup_604432(
    name: "updateGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateGatewayGroup",
    validator: validate_UpdateGatewayGroup_604433, base: "/",
    url: url_UpdateGatewayGroup_604434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_604447 = ref object of OpenApiRestCall_602466
proc url_UpdateNetworkProfile_604449(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateNetworkProfile_604448(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a network profile by the network profile ARN.
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
  var valid_604450 = header.getOrDefault("X-Amz-Date")
  valid_604450 = validateParameter(valid_604450, JString, required = false,
                                 default = nil)
  if valid_604450 != nil:
    section.add "X-Amz-Date", valid_604450
  var valid_604451 = header.getOrDefault("X-Amz-Security-Token")
  valid_604451 = validateParameter(valid_604451, JString, required = false,
                                 default = nil)
  if valid_604451 != nil:
    section.add "X-Amz-Security-Token", valid_604451
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604452 = header.getOrDefault("X-Amz-Target")
  valid_604452 = validateParameter(valid_604452, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateNetworkProfile"))
  if valid_604452 != nil:
    section.add "X-Amz-Target", valid_604452
  var valid_604453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604453 = validateParameter(valid_604453, JString, required = false,
                                 default = nil)
  if valid_604453 != nil:
    section.add "X-Amz-Content-Sha256", valid_604453
  var valid_604454 = header.getOrDefault("X-Amz-Algorithm")
  valid_604454 = validateParameter(valid_604454, JString, required = false,
                                 default = nil)
  if valid_604454 != nil:
    section.add "X-Amz-Algorithm", valid_604454
  var valid_604455 = header.getOrDefault("X-Amz-Signature")
  valid_604455 = validateParameter(valid_604455, JString, required = false,
                                 default = nil)
  if valid_604455 != nil:
    section.add "X-Amz-Signature", valid_604455
  var valid_604456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604456 = validateParameter(valid_604456, JString, required = false,
                                 default = nil)
  if valid_604456 != nil:
    section.add "X-Amz-SignedHeaders", valid_604456
  var valid_604457 = header.getOrDefault("X-Amz-Credential")
  valid_604457 = validateParameter(valid_604457, JString, required = false,
                                 default = nil)
  if valid_604457 != nil:
    section.add "X-Amz-Credential", valid_604457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604459: Call_UpdateNetworkProfile_604447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a network profile by the network profile ARN.
  ## 
  let valid = call_604459.validator(path, query, header, formData, body)
  let scheme = call_604459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604459.url(scheme.get, call_604459.host, call_604459.base,
                         call_604459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604459, url, valid)

proc call*(call_604460: Call_UpdateNetworkProfile_604447; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates a network profile by the network profile ARN.
  ##   body: JObject (required)
  var body_604461 = newJObject()
  if body != nil:
    body_604461 = body
  result = call_604460.call(nil, nil, nil, nil, body_604461)

var updateNetworkProfile* = Call_UpdateNetworkProfile_604447(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_604448, base: "/",
    url: url_UpdateNetworkProfile_604449, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProfile_604462 = ref object of OpenApiRestCall_602466
proc url_UpdateProfile_604464(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProfile_604463(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing room profile by room profile ARN.
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
  var valid_604465 = header.getOrDefault("X-Amz-Date")
  valid_604465 = validateParameter(valid_604465, JString, required = false,
                                 default = nil)
  if valid_604465 != nil:
    section.add "X-Amz-Date", valid_604465
  var valid_604466 = header.getOrDefault("X-Amz-Security-Token")
  valid_604466 = validateParameter(valid_604466, JString, required = false,
                                 default = nil)
  if valid_604466 != nil:
    section.add "X-Amz-Security-Token", valid_604466
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604467 = header.getOrDefault("X-Amz-Target")
  valid_604467 = validateParameter(valid_604467, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateProfile"))
  if valid_604467 != nil:
    section.add "X-Amz-Target", valid_604467
  var valid_604468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604468 = validateParameter(valid_604468, JString, required = false,
                                 default = nil)
  if valid_604468 != nil:
    section.add "X-Amz-Content-Sha256", valid_604468
  var valid_604469 = header.getOrDefault("X-Amz-Algorithm")
  valid_604469 = validateParameter(valid_604469, JString, required = false,
                                 default = nil)
  if valid_604469 != nil:
    section.add "X-Amz-Algorithm", valid_604469
  var valid_604470 = header.getOrDefault("X-Amz-Signature")
  valid_604470 = validateParameter(valid_604470, JString, required = false,
                                 default = nil)
  if valid_604470 != nil:
    section.add "X-Amz-Signature", valid_604470
  var valid_604471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604471 = validateParameter(valid_604471, JString, required = false,
                                 default = nil)
  if valid_604471 != nil:
    section.add "X-Amz-SignedHeaders", valid_604471
  var valid_604472 = header.getOrDefault("X-Amz-Credential")
  valid_604472 = validateParameter(valid_604472, JString, required = false,
                                 default = nil)
  if valid_604472 != nil:
    section.add "X-Amz-Credential", valid_604472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604474: Call_UpdateProfile_604462; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing room profile by room profile ARN.
  ## 
  let valid = call_604474.validator(path, query, header, formData, body)
  let scheme = call_604474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604474.url(scheme.get, call_604474.host, call_604474.base,
                         call_604474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604474, url, valid)

proc call*(call_604475: Call_UpdateProfile_604462; body: JsonNode): Recallable =
  ## updateProfile
  ## Updates an existing room profile by room profile ARN.
  ##   body: JObject (required)
  var body_604476 = newJObject()
  if body != nil:
    body_604476 = body
  result = call_604475.call(nil, nil, nil, nil, body_604476)

var updateProfile* = Call_UpdateProfile_604462(name: "updateProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateProfile",
    validator: validate_UpdateProfile_604463, base: "/", url: url_UpdateProfile_604464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoom_604477 = ref object of OpenApiRestCall_602466
proc url_UpdateRoom_604479(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRoom_604478(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates room details by room ARN.
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
  var valid_604480 = header.getOrDefault("X-Amz-Date")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "X-Amz-Date", valid_604480
  var valid_604481 = header.getOrDefault("X-Amz-Security-Token")
  valid_604481 = validateParameter(valid_604481, JString, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "X-Amz-Security-Token", valid_604481
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604482 = header.getOrDefault("X-Amz-Target")
  valid_604482 = validateParameter(valid_604482, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateRoom"))
  if valid_604482 != nil:
    section.add "X-Amz-Target", valid_604482
  var valid_604483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604483 = validateParameter(valid_604483, JString, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "X-Amz-Content-Sha256", valid_604483
  var valid_604484 = header.getOrDefault("X-Amz-Algorithm")
  valid_604484 = validateParameter(valid_604484, JString, required = false,
                                 default = nil)
  if valid_604484 != nil:
    section.add "X-Amz-Algorithm", valid_604484
  var valid_604485 = header.getOrDefault("X-Amz-Signature")
  valid_604485 = validateParameter(valid_604485, JString, required = false,
                                 default = nil)
  if valid_604485 != nil:
    section.add "X-Amz-Signature", valid_604485
  var valid_604486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604486 = validateParameter(valid_604486, JString, required = false,
                                 default = nil)
  if valid_604486 != nil:
    section.add "X-Amz-SignedHeaders", valid_604486
  var valid_604487 = header.getOrDefault("X-Amz-Credential")
  valid_604487 = validateParameter(valid_604487, JString, required = false,
                                 default = nil)
  if valid_604487 != nil:
    section.add "X-Amz-Credential", valid_604487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604489: Call_UpdateRoom_604477; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room details by room ARN.
  ## 
  let valid = call_604489.validator(path, query, header, formData, body)
  let scheme = call_604489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604489.url(scheme.get, call_604489.host, call_604489.base,
                         call_604489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604489, url, valid)

proc call*(call_604490: Call_UpdateRoom_604477; body: JsonNode): Recallable =
  ## updateRoom
  ## Updates room details by room ARN.
  ##   body: JObject (required)
  var body_604491 = newJObject()
  if body != nil:
    body_604491 = body
  result = call_604490.call(nil, nil, nil, nil, body_604491)

var updateRoom* = Call_UpdateRoom_604477(name: "updateRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.UpdateRoom",
                                      validator: validate_UpdateRoom_604478,
                                      base: "/", url: url_UpdateRoom_604479,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSkillGroup_604492 = ref object of OpenApiRestCall_602466
proc url_UpdateSkillGroup_604494(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSkillGroup_604493(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates skill group details by skill group ARN.
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
  var valid_604495 = header.getOrDefault("X-Amz-Date")
  valid_604495 = validateParameter(valid_604495, JString, required = false,
                                 default = nil)
  if valid_604495 != nil:
    section.add "X-Amz-Date", valid_604495
  var valid_604496 = header.getOrDefault("X-Amz-Security-Token")
  valid_604496 = validateParameter(valid_604496, JString, required = false,
                                 default = nil)
  if valid_604496 != nil:
    section.add "X-Amz-Security-Token", valid_604496
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604497 = header.getOrDefault("X-Amz-Target")
  valid_604497 = validateParameter(valid_604497, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateSkillGroup"))
  if valid_604497 != nil:
    section.add "X-Amz-Target", valid_604497
  var valid_604498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604498 = validateParameter(valid_604498, JString, required = false,
                                 default = nil)
  if valid_604498 != nil:
    section.add "X-Amz-Content-Sha256", valid_604498
  var valid_604499 = header.getOrDefault("X-Amz-Algorithm")
  valid_604499 = validateParameter(valid_604499, JString, required = false,
                                 default = nil)
  if valid_604499 != nil:
    section.add "X-Amz-Algorithm", valid_604499
  var valid_604500 = header.getOrDefault("X-Amz-Signature")
  valid_604500 = validateParameter(valid_604500, JString, required = false,
                                 default = nil)
  if valid_604500 != nil:
    section.add "X-Amz-Signature", valid_604500
  var valid_604501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604501 = validateParameter(valid_604501, JString, required = false,
                                 default = nil)
  if valid_604501 != nil:
    section.add "X-Amz-SignedHeaders", valid_604501
  var valid_604502 = header.getOrDefault("X-Amz-Credential")
  valid_604502 = validateParameter(valid_604502, JString, required = false,
                                 default = nil)
  if valid_604502 != nil:
    section.add "X-Amz-Credential", valid_604502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604504: Call_UpdateSkillGroup_604492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates skill group details by skill group ARN.
  ## 
  let valid = call_604504.validator(path, query, header, formData, body)
  let scheme = call_604504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604504.url(scheme.get, call_604504.host, call_604504.base,
                         call_604504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604504, url, valid)

proc call*(call_604505: Call_UpdateSkillGroup_604492; body: JsonNode): Recallable =
  ## updateSkillGroup
  ## Updates skill group details by skill group ARN.
  ##   body: JObject (required)
  var body_604506 = newJObject()
  if body != nil:
    body_604506 = body
  result = call_604505.call(nil, nil, nil, nil, body_604506)

var updateSkillGroup* = Call_UpdateSkillGroup_604492(name: "updateSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateSkillGroup",
    validator: validate_UpdateSkillGroup_604493, base: "/",
    url: url_UpdateSkillGroup_604494, schemes: {Scheme.Https, Scheme.Http})
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
