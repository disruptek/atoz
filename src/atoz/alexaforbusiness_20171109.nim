
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_ApproveSkill_610996 = ref object of OpenApiRestCall_610658
proc url_ApproveSkill_610998(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ApproveSkill_610997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611123 = header.getOrDefault("X-Amz-Target")
  valid_611123 = validateParameter(valid_611123, JString, required = true, default = newJString(
      "AlexaForBusiness.ApproveSkill"))
  if valid_611123 != nil:
    section.add "X-Amz-Target", valid_611123
  var valid_611124 = header.getOrDefault("X-Amz-Signature")
  valid_611124 = validateParameter(valid_611124, JString, required = false,
                                 default = nil)
  if valid_611124 != nil:
    section.add "X-Amz-Signature", valid_611124
  var valid_611125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Content-Sha256", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Date")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Date", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Credential")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Credential", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Security-Token")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Security-Token", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Algorithm")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Algorithm", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-SignedHeaders", valid_611130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_ApproveSkill_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill with the organization under the customer's AWS account. If a skill is private, the user implicitly accepts access to this skill during enablement.
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_ApproveSkill_610996; body: JsonNode): Recallable =
  ## approveSkill
  ## Associates a skill with the organization under the customer's AWS account. If a skill is private, the user implicitly accepts access to this skill during enablement.
  ##   body: JObject (required)
  var body_611226 = newJObject()
  if body != nil:
    body_611226 = body
  result = call_611225.call(nil, nil, nil, nil, body_611226)

var approveSkill* = Call_ApproveSkill_610996(name: "approveSkill",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ApproveSkill",
    validator: validate_ApproveSkill_610997, base: "/", url: url_ApproveSkill_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateContactWithAddressBook_611265 = ref object of OpenApiRestCall_610658
proc url_AssociateContactWithAddressBook_611267(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateContactWithAddressBook_611266(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611268 = header.getOrDefault("X-Amz-Target")
  valid_611268 = validateParameter(valid_611268, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateContactWithAddressBook"))
  if valid_611268 != nil:
    section.add "X-Amz-Target", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Signature")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Signature", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Content-Sha256", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Date")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Date", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Credential")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Credential", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Security-Token")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Security-Token", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Algorithm")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Algorithm", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-SignedHeaders", valid_611275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611277: Call_AssociateContactWithAddressBook_611265;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a contact with a given address book.
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_AssociateContactWithAddressBook_611265; body: JsonNode): Recallable =
  ## associateContactWithAddressBook
  ## Associates a contact with a given address book.
  ##   body: JObject (required)
  var body_611279 = newJObject()
  if body != nil:
    body_611279 = body
  result = call_611278.call(nil, nil, nil, nil, body_611279)

var associateContactWithAddressBook* = Call_AssociateContactWithAddressBook_611265(
    name: "associateContactWithAddressBook", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateContactWithAddressBook",
    validator: validate_AssociateContactWithAddressBook_611266, base: "/",
    url: url_AssociateContactWithAddressBook_611267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateDeviceWithNetworkProfile_611280 = ref object of OpenApiRestCall_610658
proc url_AssociateDeviceWithNetworkProfile_611282(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateDeviceWithNetworkProfile_611281(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611283 = header.getOrDefault("X-Amz-Target")
  valid_611283 = validateParameter(valid_611283, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateDeviceWithNetworkProfile"))
  if valid_611283 != nil:
    section.add "X-Amz-Target", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Signature")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Signature", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Content-Sha256", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Date")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Date", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Credential")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Credential", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Security-Token")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Security-Token", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Algorithm")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Algorithm", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-SignedHeaders", valid_611290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611292: Call_AssociateDeviceWithNetworkProfile_611280;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a device with the specified network profile.
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_AssociateDeviceWithNetworkProfile_611280;
          body: JsonNode): Recallable =
  ## associateDeviceWithNetworkProfile
  ## Associates a device with the specified network profile.
  ##   body: JObject (required)
  var body_611294 = newJObject()
  if body != nil:
    body_611294 = body
  result = call_611293.call(nil, nil, nil, nil, body_611294)

var associateDeviceWithNetworkProfile* = Call_AssociateDeviceWithNetworkProfile_611280(
    name: "associateDeviceWithNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateDeviceWithNetworkProfile",
    validator: validate_AssociateDeviceWithNetworkProfile_611281, base: "/",
    url: url_AssociateDeviceWithNetworkProfile_611282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateDeviceWithRoom_611295 = ref object of OpenApiRestCall_610658
proc url_AssociateDeviceWithRoom_611297(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateDeviceWithRoom_611296(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611298 = header.getOrDefault("X-Amz-Target")
  valid_611298 = validateParameter(valid_611298, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateDeviceWithRoom"))
  if valid_611298 != nil:
    section.add "X-Amz-Target", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Signature")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Signature", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Content-Sha256", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Date")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Date", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Credential")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Credential", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Security-Token")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Security-Token", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Algorithm")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Algorithm", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-SignedHeaders", valid_611305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611307: Call_AssociateDeviceWithRoom_611295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a device with a given room. This applies all the settings from the room profile to the device, and all the skills in any skill groups added to that room. This operation requires the device to be online, or else a manual sync is required. 
  ## 
  let valid = call_611307.validator(path, query, header, formData, body)
  let scheme = call_611307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611307.url(scheme.get, call_611307.host, call_611307.base,
                         call_611307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611307, url, valid)

proc call*(call_611308: Call_AssociateDeviceWithRoom_611295; body: JsonNode): Recallable =
  ## associateDeviceWithRoom
  ## Associates a device with a given room. This applies all the settings from the room profile to the device, and all the skills in any skill groups added to that room. This operation requires the device to be online, or else a manual sync is required. 
  ##   body: JObject (required)
  var body_611309 = newJObject()
  if body != nil:
    body_611309 = body
  result = call_611308.call(nil, nil, nil, nil, body_611309)

var associateDeviceWithRoom* = Call_AssociateDeviceWithRoom_611295(
    name: "associateDeviceWithRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateDeviceWithRoom",
    validator: validate_AssociateDeviceWithRoom_611296, base: "/",
    url: url_AssociateDeviceWithRoom_611297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillGroupWithRoom_611310 = ref object of OpenApiRestCall_610658
proc url_AssociateSkillGroupWithRoom_611312(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateSkillGroupWithRoom_611311(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611313 = header.getOrDefault("X-Amz-Target")
  valid_611313 = validateParameter(valid_611313, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillGroupWithRoom"))
  if valid_611313 != nil:
    section.add "X-Amz-Target", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Signature")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Signature", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Content-Sha256", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Date")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Date", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Credential")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Credential", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Security-Token")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Security-Token", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Algorithm")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Algorithm", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-SignedHeaders", valid_611320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611322: Call_AssociateSkillGroupWithRoom_611310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill group with a given room. This enables all skills in the associated skill group on all devices in the room.
  ## 
  let valid = call_611322.validator(path, query, header, formData, body)
  let scheme = call_611322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611322.url(scheme.get, call_611322.host, call_611322.base,
                         call_611322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611322, url, valid)

proc call*(call_611323: Call_AssociateSkillGroupWithRoom_611310; body: JsonNode): Recallable =
  ## associateSkillGroupWithRoom
  ## Associates a skill group with a given room. This enables all skills in the associated skill group on all devices in the room.
  ##   body: JObject (required)
  var body_611324 = newJObject()
  if body != nil:
    body_611324 = body
  result = call_611323.call(nil, nil, nil, nil, body_611324)

var associateSkillGroupWithRoom* = Call_AssociateSkillGroupWithRoom_611310(
    name: "associateSkillGroupWithRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillGroupWithRoom",
    validator: validate_AssociateSkillGroupWithRoom_611311, base: "/",
    url: url_AssociateSkillGroupWithRoom_611312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillWithSkillGroup_611325 = ref object of OpenApiRestCall_610658
proc url_AssociateSkillWithSkillGroup_611327(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateSkillWithSkillGroup_611326(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611328 = header.getOrDefault("X-Amz-Target")
  valid_611328 = validateParameter(valid_611328, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillWithSkillGroup"))
  if valid_611328 != nil:
    section.add "X-Amz-Target", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Signature")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Signature", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Content-Sha256", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Date")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Date", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Credential")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Credential", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Security-Token")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Security-Token", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Algorithm")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Algorithm", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-SignedHeaders", valid_611335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611337: Call_AssociateSkillWithSkillGroup_611325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill with a skill group.
  ## 
  let valid = call_611337.validator(path, query, header, formData, body)
  let scheme = call_611337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611337.url(scheme.get, call_611337.host, call_611337.base,
                         call_611337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611337, url, valid)

proc call*(call_611338: Call_AssociateSkillWithSkillGroup_611325; body: JsonNode): Recallable =
  ## associateSkillWithSkillGroup
  ## Associates a skill with a skill group.
  ##   body: JObject (required)
  var body_611339 = newJObject()
  if body != nil:
    body_611339 = body
  result = call_611338.call(nil, nil, nil, nil, body_611339)

var associateSkillWithSkillGroup* = Call_AssociateSkillWithSkillGroup_611325(
    name: "associateSkillWithSkillGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillWithSkillGroup",
    validator: validate_AssociateSkillWithSkillGroup_611326, base: "/",
    url: url_AssociateSkillWithSkillGroup_611327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillWithUsers_611340 = ref object of OpenApiRestCall_610658
proc url_AssociateSkillWithUsers_611342(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateSkillWithUsers_611341(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611343 = header.getOrDefault("X-Amz-Target")
  valid_611343 = validateParameter(valid_611343, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillWithUsers"))
  if valid_611343 != nil:
    section.add "X-Amz-Target", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Signature")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Signature", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Content-Sha256", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Date")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Date", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Credential")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Credential", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Security-Token")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Security-Token", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Algorithm")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Algorithm", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-SignedHeaders", valid_611350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611352: Call_AssociateSkillWithUsers_611340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Makes a private skill available for enrolled users to enable on their devices.
  ## 
  let valid = call_611352.validator(path, query, header, formData, body)
  let scheme = call_611352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611352.url(scheme.get, call_611352.host, call_611352.base,
                         call_611352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611352, url, valid)

proc call*(call_611353: Call_AssociateSkillWithUsers_611340; body: JsonNode): Recallable =
  ## associateSkillWithUsers
  ## Makes a private skill available for enrolled users to enable on their devices.
  ##   body: JObject (required)
  var body_611354 = newJObject()
  if body != nil:
    body_611354 = body
  result = call_611353.call(nil, nil, nil, nil, body_611354)

var associateSkillWithUsers* = Call_AssociateSkillWithUsers_611340(
    name: "associateSkillWithUsers", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillWithUsers",
    validator: validate_AssociateSkillWithUsers_611341, base: "/",
    url: url_AssociateSkillWithUsers_611342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAddressBook_611355 = ref object of OpenApiRestCall_610658
proc url_CreateAddressBook_611357(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAddressBook_611356(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611358 = header.getOrDefault("X-Amz-Target")
  valid_611358 = validateParameter(valid_611358, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateAddressBook"))
  if valid_611358 != nil:
    section.add "X-Amz-Target", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Signature")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Signature", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Content-Sha256", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Date")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Date", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Credential")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Credential", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Security-Token")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Security-Token", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Algorithm")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Algorithm", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-SignedHeaders", valid_611365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611367: Call_CreateAddressBook_611355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an address book with the specified details.
  ## 
  let valid = call_611367.validator(path, query, header, formData, body)
  let scheme = call_611367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611367.url(scheme.get, call_611367.host, call_611367.base,
                         call_611367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611367, url, valid)

proc call*(call_611368: Call_CreateAddressBook_611355; body: JsonNode): Recallable =
  ## createAddressBook
  ## Creates an address book with the specified details.
  ##   body: JObject (required)
  var body_611369 = newJObject()
  if body != nil:
    body_611369 = body
  result = call_611368.call(nil, nil, nil, nil, body_611369)

var createAddressBook* = Call_CreateAddressBook_611355(name: "createAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateAddressBook",
    validator: validate_CreateAddressBook_611356, base: "/",
    url: url_CreateAddressBook_611357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBusinessReportSchedule_611370 = ref object of OpenApiRestCall_610658
proc url_CreateBusinessReportSchedule_611372(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBusinessReportSchedule_611371(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611373 = header.getOrDefault("X-Amz-Target")
  valid_611373 = validateParameter(valid_611373, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateBusinessReportSchedule"))
  if valid_611373 != nil:
    section.add "X-Amz-Target", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Signature")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Signature", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Content-Sha256", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Date")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Date", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Credential")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Credential", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Security-Token")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Security-Token", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Algorithm")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Algorithm", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-SignedHeaders", valid_611380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611382: Call_CreateBusinessReportSchedule_611370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a recurring schedule for usage reports to deliver to the specified S3 location with a specified daily or weekly interval.
  ## 
  let valid = call_611382.validator(path, query, header, formData, body)
  let scheme = call_611382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611382.url(scheme.get, call_611382.host, call_611382.base,
                         call_611382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611382, url, valid)

proc call*(call_611383: Call_CreateBusinessReportSchedule_611370; body: JsonNode): Recallable =
  ## createBusinessReportSchedule
  ## Creates a recurring schedule for usage reports to deliver to the specified S3 location with a specified daily or weekly interval.
  ##   body: JObject (required)
  var body_611384 = newJObject()
  if body != nil:
    body_611384 = body
  result = call_611383.call(nil, nil, nil, nil, body_611384)

var createBusinessReportSchedule* = Call_CreateBusinessReportSchedule_611370(
    name: "createBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateBusinessReportSchedule",
    validator: validate_CreateBusinessReportSchedule_611371, base: "/",
    url: url_CreateBusinessReportSchedule_611372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConferenceProvider_611385 = ref object of OpenApiRestCall_610658
proc url_CreateConferenceProvider_611387(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConferenceProvider_611386(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611388 = header.getOrDefault("X-Amz-Target")
  valid_611388 = validateParameter(valid_611388, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateConferenceProvider"))
  if valid_611388 != nil:
    section.add "X-Amz-Target", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Signature")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Signature", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Content-Sha256", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Date")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Date", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Credential")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Credential", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Security-Token")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Security-Token", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Algorithm")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Algorithm", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-SignedHeaders", valid_611395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611397: Call_CreateConferenceProvider_611385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new conference provider under the user's AWS account.
  ## 
  let valid = call_611397.validator(path, query, header, formData, body)
  let scheme = call_611397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611397.url(scheme.get, call_611397.host, call_611397.base,
                         call_611397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611397, url, valid)

proc call*(call_611398: Call_CreateConferenceProvider_611385; body: JsonNode): Recallable =
  ## createConferenceProvider
  ## Adds a new conference provider under the user's AWS account.
  ##   body: JObject (required)
  var body_611399 = newJObject()
  if body != nil:
    body_611399 = body
  result = call_611398.call(nil, nil, nil, nil, body_611399)

var createConferenceProvider* = Call_CreateConferenceProvider_611385(
    name: "createConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateConferenceProvider",
    validator: validate_CreateConferenceProvider_611386, base: "/",
    url: url_CreateConferenceProvider_611387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateContact_611400 = ref object of OpenApiRestCall_610658
proc url_CreateContact_611402(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateContact_611401(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611403 = header.getOrDefault("X-Amz-Target")
  valid_611403 = validateParameter(valid_611403, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateContact"))
  if valid_611403 != nil:
    section.add "X-Amz-Target", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Signature")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Signature", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Content-Sha256", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Date")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Date", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Credential")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Credential", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Security-Token")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Security-Token", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Algorithm")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Algorithm", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-SignedHeaders", valid_611410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611412: Call_CreateContact_611400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a contact with the specified details.
  ## 
  let valid = call_611412.validator(path, query, header, formData, body)
  let scheme = call_611412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611412.url(scheme.get, call_611412.host, call_611412.base,
                         call_611412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611412, url, valid)

proc call*(call_611413: Call_CreateContact_611400; body: JsonNode): Recallable =
  ## createContact
  ## Creates a contact with the specified details.
  ##   body: JObject (required)
  var body_611414 = newJObject()
  if body != nil:
    body_611414 = body
  result = call_611413.call(nil, nil, nil, nil, body_611414)

var createContact* = Call_CreateContact_611400(name: "createContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateContact",
    validator: validate_CreateContact_611401, base: "/", url: url_CreateContact_611402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGatewayGroup_611415 = ref object of OpenApiRestCall_610658
proc url_CreateGatewayGroup_611417(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGatewayGroup_611416(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611418 = header.getOrDefault("X-Amz-Target")
  valid_611418 = validateParameter(valid_611418, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateGatewayGroup"))
  if valid_611418 != nil:
    section.add "X-Amz-Target", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Signature")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Signature", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Content-Sha256", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Date")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Date", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Credential")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Credential", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Security-Token")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Security-Token", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Algorithm")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Algorithm", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-SignedHeaders", valid_611425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611427: Call_CreateGatewayGroup_611415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a gateway group with the specified details.
  ## 
  let valid = call_611427.validator(path, query, header, formData, body)
  let scheme = call_611427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611427.url(scheme.get, call_611427.host, call_611427.base,
                         call_611427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611427, url, valid)

proc call*(call_611428: Call_CreateGatewayGroup_611415; body: JsonNode): Recallable =
  ## createGatewayGroup
  ## Creates a gateway group with the specified details.
  ##   body: JObject (required)
  var body_611429 = newJObject()
  if body != nil:
    body_611429 = body
  result = call_611428.call(nil, nil, nil, nil, body_611429)

var createGatewayGroup* = Call_CreateGatewayGroup_611415(
    name: "createGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateGatewayGroup",
    validator: validate_CreateGatewayGroup_611416, base: "/",
    url: url_CreateGatewayGroup_611417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_611430 = ref object of OpenApiRestCall_610658
proc url_CreateNetworkProfile_611432(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNetworkProfile_611431(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611433 = header.getOrDefault("X-Amz-Target")
  valid_611433 = validateParameter(valid_611433, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateNetworkProfile"))
  if valid_611433 != nil:
    section.add "X-Amz-Target", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Signature")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Signature", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Content-Sha256", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Date")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Date", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Credential")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Credential", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Security-Token")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Security-Token", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Algorithm")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Algorithm", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-SignedHeaders", valid_611440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611442: Call_CreateNetworkProfile_611430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a network profile with the specified details.
  ## 
  let valid = call_611442.validator(path, query, header, formData, body)
  let scheme = call_611442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611442.url(scheme.get, call_611442.host, call_611442.base,
                         call_611442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611442, url, valid)

proc call*(call_611443: Call_CreateNetworkProfile_611430; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile with the specified details.
  ##   body: JObject (required)
  var body_611444 = newJObject()
  if body != nil:
    body_611444 = body
  result = call_611443.call(nil, nil, nil, nil, body_611444)

var createNetworkProfile* = Call_CreateNetworkProfile_611430(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_611431, base: "/",
    url: url_CreateNetworkProfile_611432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProfile_611445 = ref object of OpenApiRestCall_610658
proc url_CreateProfile_611447(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProfile_611446(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611448 = header.getOrDefault("X-Amz-Target")
  valid_611448 = validateParameter(valid_611448, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateProfile"))
  if valid_611448 != nil:
    section.add "X-Amz-Target", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Signature")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Signature", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Content-Sha256", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Date")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Date", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Credential")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Credential", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Security-Token")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Security-Token", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Algorithm")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Algorithm", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-SignedHeaders", valid_611455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611457: Call_CreateProfile_611445; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new room profile with the specified details.
  ## 
  let valid = call_611457.validator(path, query, header, formData, body)
  let scheme = call_611457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611457.url(scheme.get, call_611457.host, call_611457.base,
                         call_611457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611457, url, valid)

proc call*(call_611458: Call_CreateProfile_611445; body: JsonNode): Recallable =
  ## createProfile
  ## Creates a new room profile with the specified details.
  ##   body: JObject (required)
  var body_611459 = newJObject()
  if body != nil:
    body_611459 = body
  result = call_611458.call(nil, nil, nil, nil, body_611459)

var createProfile* = Call_CreateProfile_611445(name: "createProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateProfile",
    validator: validate_CreateProfile_611446, base: "/", url: url_CreateProfile_611447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoom_611460 = ref object of OpenApiRestCall_610658
proc url_CreateRoom_611462(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRoom_611461(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611463 = header.getOrDefault("X-Amz-Target")
  valid_611463 = validateParameter(valid_611463, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateRoom"))
  if valid_611463 != nil:
    section.add "X-Amz-Target", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Signature")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Signature", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Content-Sha256", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Date")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Date", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Credential")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Credential", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Security-Token")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Security-Token", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Algorithm")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Algorithm", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-SignedHeaders", valid_611470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611472: Call_CreateRoom_611460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a room with the specified details.
  ## 
  let valid = call_611472.validator(path, query, header, formData, body)
  let scheme = call_611472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611472.url(scheme.get, call_611472.host, call_611472.base,
                         call_611472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611472, url, valid)

proc call*(call_611473: Call_CreateRoom_611460; body: JsonNode): Recallable =
  ## createRoom
  ## Creates a room with the specified details.
  ##   body: JObject (required)
  var body_611474 = newJObject()
  if body != nil:
    body_611474 = body
  result = call_611473.call(nil, nil, nil, nil, body_611474)

var createRoom* = Call_CreateRoom_611460(name: "createRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.CreateRoom",
                                      validator: validate_CreateRoom_611461,
                                      base: "/", url: url_CreateRoom_611462,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSkillGroup_611475 = ref object of OpenApiRestCall_610658
proc url_CreateSkillGroup_611477(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSkillGroup_611476(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611478 = header.getOrDefault("X-Amz-Target")
  valid_611478 = validateParameter(valid_611478, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateSkillGroup"))
  if valid_611478 != nil:
    section.add "X-Amz-Target", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Signature")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Signature", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Content-Sha256", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Date")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Date", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Credential")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Credential", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Security-Token")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Security-Token", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Algorithm")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Algorithm", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-SignedHeaders", valid_611485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611487: Call_CreateSkillGroup_611475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a skill group with a specified name and description.
  ## 
  let valid = call_611487.validator(path, query, header, formData, body)
  let scheme = call_611487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611487.url(scheme.get, call_611487.host, call_611487.base,
                         call_611487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611487, url, valid)

proc call*(call_611488: Call_CreateSkillGroup_611475; body: JsonNode): Recallable =
  ## createSkillGroup
  ## Creates a skill group with a specified name and description.
  ##   body: JObject (required)
  var body_611489 = newJObject()
  if body != nil:
    body_611489 = body
  result = call_611488.call(nil, nil, nil, nil, body_611489)

var createSkillGroup* = Call_CreateSkillGroup_611475(name: "createSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateSkillGroup",
    validator: validate_CreateSkillGroup_611476, base: "/",
    url: url_CreateSkillGroup_611477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_611490 = ref object of OpenApiRestCall_610658
proc url_CreateUser_611492(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUser_611491(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611493 = header.getOrDefault("X-Amz-Target")
  valid_611493 = validateParameter(valid_611493, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateUser"))
  if valid_611493 != nil:
    section.add "X-Amz-Target", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Signature")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Signature", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Content-Sha256", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Date")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Date", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Credential")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Credential", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Security-Token")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Security-Token", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Algorithm")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Algorithm", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-SignedHeaders", valid_611500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611502: Call_CreateUser_611490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user.
  ## 
  let valid = call_611502.validator(path, query, header, formData, body)
  let scheme = call_611502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611502.url(scheme.get, call_611502.host, call_611502.base,
                         call_611502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611502, url, valid)

proc call*(call_611503: Call_CreateUser_611490; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user.
  ##   body: JObject (required)
  var body_611504 = newJObject()
  if body != nil:
    body_611504 = body
  result = call_611503.call(nil, nil, nil, nil, body_611504)

var createUser* = Call_CreateUser_611490(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.CreateUser",
                                      validator: validate_CreateUser_611491,
                                      base: "/", url: url_CreateUser_611492,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAddressBook_611505 = ref object of OpenApiRestCall_610658
proc url_DeleteAddressBook_611507(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAddressBook_611506(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611508 = header.getOrDefault("X-Amz-Target")
  valid_611508 = validateParameter(valid_611508, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteAddressBook"))
  if valid_611508 != nil:
    section.add "X-Amz-Target", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Signature")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Signature", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Content-Sha256", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Date")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Date", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Credential")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Credential", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Security-Token")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Security-Token", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Algorithm")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Algorithm", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-SignedHeaders", valid_611515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611517: Call_DeleteAddressBook_611505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an address book by the address book ARN.
  ## 
  let valid = call_611517.validator(path, query, header, formData, body)
  let scheme = call_611517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611517.url(scheme.get, call_611517.host, call_611517.base,
                         call_611517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611517, url, valid)

proc call*(call_611518: Call_DeleteAddressBook_611505; body: JsonNode): Recallable =
  ## deleteAddressBook
  ## Deletes an address book by the address book ARN.
  ##   body: JObject (required)
  var body_611519 = newJObject()
  if body != nil:
    body_611519 = body
  result = call_611518.call(nil, nil, nil, nil, body_611519)

var deleteAddressBook* = Call_DeleteAddressBook_611505(name: "deleteAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteAddressBook",
    validator: validate_DeleteAddressBook_611506, base: "/",
    url: url_DeleteAddressBook_611507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBusinessReportSchedule_611520 = ref object of OpenApiRestCall_610658
proc url_DeleteBusinessReportSchedule_611522(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBusinessReportSchedule_611521(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611523 = header.getOrDefault("X-Amz-Target")
  valid_611523 = validateParameter(valid_611523, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteBusinessReportSchedule"))
  if valid_611523 != nil:
    section.add "X-Amz-Target", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-Signature")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Signature", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Content-Sha256", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Date")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Date", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-Credential")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Credential", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Security-Token")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Security-Token", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Algorithm")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Algorithm", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-SignedHeaders", valid_611530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611532: Call_DeleteBusinessReportSchedule_611520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the recurring report delivery schedule with the specified schedule ARN.
  ## 
  let valid = call_611532.validator(path, query, header, formData, body)
  let scheme = call_611532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611532.url(scheme.get, call_611532.host, call_611532.base,
                         call_611532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611532, url, valid)

proc call*(call_611533: Call_DeleteBusinessReportSchedule_611520; body: JsonNode): Recallable =
  ## deleteBusinessReportSchedule
  ## Deletes the recurring report delivery schedule with the specified schedule ARN.
  ##   body: JObject (required)
  var body_611534 = newJObject()
  if body != nil:
    body_611534 = body
  result = call_611533.call(nil, nil, nil, nil, body_611534)

var deleteBusinessReportSchedule* = Call_DeleteBusinessReportSchedule_611520(
    name: "deleteBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteBusinessReportSchedule",
    validator: validate_DeleteBusinessReportSchedule_611521, base: "/",
    url: url_DeleteBusinessReportSchedule_611522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConferenceProvider_611535 = ref object of OpenApiRestCall_610658
proc url_DeleteConferenceProvider_611537(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConferenceProvider_611536(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611538 = header.getOrDefault("X-Amz-Target")
  valid_611538 = validateParameter(valid_611538, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteConferenceProvider"))
  if valid_611538 != nil:
    section.add "X-Amz-Target", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Signature")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Signature", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Content-Sha256", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Date")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Date", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-Credential")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Credential", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-Security-Token")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-Security-Token", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Algorithm")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Algorithm", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-SignedHeaders", valid_611545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611547: Call_DeleteConferenceProvider_611535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a conference provider.
  ## 
  let valid = call_611547.validator(path, query, header, formData, body)
  let scheme = call_611547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611547.url(scheme.get, call_611547.host, call_611547.base,
                         call_611547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611547, url, valid)

proc call*(call_611548: Call_DeleteConferenceProvider_611535; body: JsonNode): Recallable =
  ## deleteConferenceProvider
  ## Deletes a conference provider.
  ##   body: JObject (required)
  var body_611549 = newJObject()
  if body != nil:
    body_611549 = body
  result = call_611548.call(nil, nil, nil, nil, body_611549)

var deleteConferenceProvider* = Call_DeleteConferenceProvider_611535(
    name: "deleteConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteConferenceProvider",
    validator: validate_DeleteConferenceProvider_611536, base: "/",
    url: url_DeleteConferenceProvider_611537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteContact_611550 = ref object of OpenApiRestCall_610658
proc url_DeleteContact_611552(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteContact_611551(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611553 = header.getOrDefault("X-Amz-Target")
  valid_611553 = validateParameter(valid_611553, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteContact"))
  if valid_611553 != nil:
    section.add "X-Amz-Target", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Signature")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Signature", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Content-Sha256", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-Date")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Date", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Credential")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Credential", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-Security-Token")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Security-Token", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-Algorithm")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Algorithm", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-SignedHeaders", valid_611560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611562: Call_DeleteContact_611550; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a contact by the contact ARN.
  ## 
  let valid = call_611562.validator(path, query, header, formData, body)
  let scheme = call_611562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611562.url(scheme.get, call_611562.host, call_611562.base,
                         call_611562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611562, url, valid)

proc call*(call_611563: Call_DeleteContact_611550; body: JsonNode): Recallable =
  ## deleteContact
  ## Deletes a contact by the contact ARN.
  ##   body: JObject (required)
  var body_611564 = newJObject()
  if body != nil:
    body_611564 = body
  result = call_611563.call(nil, nil, nil, nil, body_611564)

var deleteContact* = Call_DeleteContact_611550(name: "deleteContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteContact",
    validator: validate_DeleteContact_611551, base: "/", url: url_DeleteContact_611552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevice_611565 = ref object of OpenApiRestCall_610658
proc url_DeleteDevice_611567(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDevice_611566(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611568 = header.getOrDefault("X-Amz-Target")
  valid_611568 = validateParameter(valid_611568, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteDevice"))
  if valid_611568 != nil:
    section.add "X-Amz-Target", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Signature")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Signature", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Content-Sha256", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Date")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Date", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Credential")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Credential", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Security-Token")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Security-Token", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Algorithm")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Algorithm", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-SignedHeaders", valid_611575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611577: Call_DeleteDevice_611565; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a device from Alexa For Business.
  ## 
  let valid = call_611577.validator(path, query, header, formData, body)
  let scheme = call_611577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611577.url(scheme.get, call_611577.host, call_611577.base,
                         call_611577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611577, url, valid)

proc call*(call_611578: Call_DeleteDevice_611565; body: JsonNode): Recallable =
  ## deleteDevice
  ## Removes a device from Alexa For Business.
  ##   body: JObject (required)
  var body_611579 = newJObject()
  if body != nil:
    body_611579 = body
  result = call_611578.call(nil, nil, nil, nil, body_611579)

var deleteDevice* = Call_DeleteDevice_611565(name: "deleteDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteDevice",
    validator: validate_DeleteDevice_611566, base: "/", url: url_DeleteDevice_611567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceUsageData_611580 = ref object of OpenApiRestCall_610658
proc url_DeleteDeviceUsageData_611582(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDeviceUsageData_611581(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611583 = header.getOrDefault("X-Amz-Target")
  valid_611583 = validateParameter(valid_611583, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteDeviceUsageData"))
  if valid_611583 != nil:
    section.add "X-Amz-Target", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Signature")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Signature", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Content-Sha256", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Date")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Date", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Credential")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Credential", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-Security-Token")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Security-Token", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Algorithm")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Algorithm", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-SignedHeaders", valid_611590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611592: Call_DeleteDeviceUsageData_611580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## When this action is called for a specified shared device, it allows authorized users to delete the device's entire previous history of voice input data and associated response data. This action can be called once every 24 hours for a specific shared device.
  ## 
  let valid = call_611592.validator(path, query, header, formData, body)
  let scheme = call_611592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611592.url(scheme.get, call_611592.host, call_611592.base,
                         call_611592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611592, url, valid)

proc call*(call_611593: Call_DeleteDeviceUsageData_611580; body: JsonNode): Recallable =
  ## deleteDeviceUsageData
  ## When this action is called for a specified shared device, it allows authorized users to delete the device's entire previous history of voice input data and associated response data. This action can be called once every 24 hours for a specific shared device.
  ##   body: JObject (required)
  var body_611594 = newJObject()
  if body != nil:
    body_611594 = body
  result = call_611593.call(nil, nil, nil, nil, body_611594)

var deleteDeviceUsageData* = Call_DeleteDeviceUsageData_611580(
    name: "deleteDeviceUsageData", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteDeviceUsageData",
    validator: validate_DeleteDeviceUsageData_611581, base: "/",
    url: url_DeleteDeviceUsageData_611582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayGroup_611595 = ref object of OpenApiRestCall_610658
proc url_DeleteGatewayGroup_611597(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGatewayGroup_611596(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611598 = header.getOrDefault("X-Amz-Target")
  valid_611598 = validateParameter(valid_611598, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteGatewayGroup"))
  if valid_611598 != nil:
    section.add "X-Amz-Target", valid_611598
  var valid_611599 = header.getOrDefault("X-Amz-Signature")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Signature", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Content-Sha256", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Date")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Date", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Credential")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Credential", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Security-Token")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Security-Token", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Algorithm")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Algorithm", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-SignedHeaders", valid_611605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611607: Call_DeleteGatewayGroup_611595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a gateway group.
  ## 
  let valid = call_611607.validator(path, query, header, formData, body)
  let scheme = call_611607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611607.url(scheme.get, call_611607.host, call_611607.base,
                         call_611607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611607, url, valid)

proc call*(call_611608: Call_DeleteGatewayGroup_611595; body: JsonNode): Recallable =
  ## deleteGatewayGroup
  ## Deletes a gateway group.
  ##   body: JObject (required)
  var body_611609 = newJObject()
  if body != nil:
    body_611609 = body
  result = call_611608.call(nil, nil, nil, nil, body_611609)

var deleteGatewayGroup* = Call_DeleteGatewayGroup_611595(
    name: "deleteGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteGatewayGroup",
    validator: validate_DeleteGatewayGroup_611596, base: "/",
    url: url_DeleteGatewayGroup_611597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_611610 = ref object of OpenApiRestCall_610658
proc url_DeleteNetworkProfile_611612(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNetworkProfile_611611(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611613 = header.getOrDefault("X-Amz-Target")
  valid_611613 = validateParameter(valid_611613, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteNetworkProfile"))
  if valid_611613 != nil:
    section.add "X-Amz-Target", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-Signature")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Signature", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Content-Sha256", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Date")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Date", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Credential")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Credential", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Security-Token")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Security-Token", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-Algorithm")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Algorithm", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-SignedHeaders", valid_611620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611622: Call_DeleteNetworkProfile_611610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a network profile by the network profile ARN.
  ## 
  let valid = call_611622.validator(path, query, header, formData, body)
  let scheme = call_611622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611622.url(scheme.get, call_611622.host, call_611622.base,
                         call_611622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611622, url, valid)

proc call*(call_611623: Call_DeleteNetworkProfile_611610; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile by the network profile ARN.
  ##   body: JObject (required)
  var body_611624 = newJObject()
  if body != nil:
    body_611624 = body
  result = call_611623.call(nil, nil, nil, nil, body_611624)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_611610(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_611611, base: "/",
    url: url_DeleteNetworkProfile_611612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProfile_611625 = ref object of OpenApiRestCall_610658
proc url_DeleteProfile_611627(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProfile_611626(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611628 = header.getOrDefault("X-Amz-Target")
  valid_611628 = validateParameter(valid_611628, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteProfile"))
  if valid_611628 != nil:
    section.add "X-Amz-Target", valid_611628
  var valid_611629 = header.getOrDefault("X-Amz-Signature")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Signature", valid_611629
  var valid_611630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-Content-Sha256", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Date")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Date", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Credential")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Credential", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Security-Token")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Security-Token", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Algorithm")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Algorithm", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-SignedHeaders", valid_611635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611637: Call_DeleteProfile_611625; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a room profile by the profile ARN.
  ## 
  let valid = call_611637.validator(path, query, header, formData, body)
  let scheme = call_611637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611637.url(scheme.get, call_611637.host, call_611637.base,
                         call_611637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611637, url, valid)

proc call*(call_611638: Call_DeleteProfile_611625; body: JsonNode): Recallable =
  ## deleteProfile
  ## Deletes a room profile by the profile ARN.
  ##   body: JObject (required)
  var body_611639 = newJObject()
  if body != nil:
    body_611639 = body
  result = call_611638.call(nil, nil, nil, nil, body_611639)

var deleteProfile* = Call_DeleteProfile_611625(name: "deleteProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteProfile",
    validator: validate_DeleteProfile_611626, base: "/", url: url_DeleteProfile_611627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoom_611640 = ref object of OpenApiRestCall_610658
proc url_DeleteRoom_611642(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRoom_611641(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611643 = header.getOrDefault("X-Amz-Target")
  valid_611643 = validateParameter(valid_611643, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteRoom"))
  if valid_611643 != nil:
    section.add "X-Amz-Target", valid_611643
  var valid_611644 = header.getOrDefault("X-Amz-Signature")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "X-Amz-Signature", valid_611644
  var valid_611645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "X-Amz-Content-Sha256", valid_611645
  var valid_611646 = header.getOrDefault("X-Amz-Date")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "X-Amz-Date", valid_611646
  var valid_611647 = header.getOrDefault("X-Amz-Credential")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-Credential", valid_611647
  var valid_611648 = header.getOrDefault("X-Amz-Security-Token")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Security-Token", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-Algorithm")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Algorithm", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-SignedHeaders", valid_611650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611652: Call_DeleteRoom_611640; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a room by the room ARN.
  ## 
  let valid = call_611652.validator(path, query, header, formData, body)
  let scheme = call_611652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611652.url(scheme.get, call_611652.host, call_611652.base,
                         call_611652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611652, url, valid)

proc call*(call_611653: Call_DeleteRoom_611640; body: JsonNode): Recallable =
  ## deleteRoom
  ## Deletes a room by the room ARN.
  ##   body: JObject (required)
  var body_611654 = newJObject()
  if body != nil:
    body_611654 = body
  result = call_611653.call(nil, nil, nil, nil, body_611654)

var deleteRoom* = Call_DeleteRoom_611640(name: "deleteRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DeleteRoom",
                                      validator: validate_DeleteRoom_611641,
                                      base: "/", url: url_DeleteRoom_611642,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoomSkillParameter_611655 = ref object of OpenApiRestCall_610658
proc url_DeleteRoomSkillParameter_611657(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRoomSkillParameter_611656(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611658 = header.getOrDefault("X-Amz-Target")
  valid_611658 = validateParameter(valid_611658, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteRoomSkillParameter"))
  if valid_611658 != nil:
    section.add "X-Amz-Target", valid_611658
  var valid_611659 = header.getOrDefault("X-Amz-Signature")
  valid_611659 = validateParameter(valid_611659, JString, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "X-Amz-Signature", valid_611659
  var valid_611660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611660 = validateParameter(valid_611660, JString, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "X-Amz-Content-Sha256", valid_611660
  var valid_611661 = header.getOrDefault("X-Amz-Date")
  valid_611661 = validateParameter(valid_611661, JString, required = false,
                                 default = nil)
  if valid_611661 != nil:
    section.add "X-Amz-Date", valid_611661
  var valid_611662 = header.getOrDefault("X-Amz-Credential")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-Credential", valid_611662
  var valid_611663 = header.getOrDefault("X-Amz-Security-Token")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Security-Token", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-Algorithm")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Algorithm", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-SignedHeaders", valid_611665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611667: Call_DeleteRoomSkillParameter_611655; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes room skill parameter details by room, skill, and parameter key ID.
  ## 
  let valid = call_611667.validator(path, query, header, formData, body)
  let scheme = call_611667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611667.url(scheme.get, call_611667.host, call_611667.base,
                         call_611667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611667, url, valid)

proc call*(call_611668: Call_DeleteRoomSkillParameter_611655; body: JsonNode): Recallable =
  ## deleteRoomSkillParameter
  ## Deletes room skill parameter details by room, skill, and parameter key ID.
  ##   body: JObject (required)
  var body_611669 = newJObject()
  if body != nil:
    body_611669 = body
  result = call_611668.call(nil, nil, nil, nil, body_611669)

var deleteRoomSkillParameter* = Call_DeleteRoomSkillParameter_611655(
    name: "deleteRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteRoomSkillParameter",
    validator: validate_DeleteRoomSkillParameter_611656, base: "/",
    url: url_DeleteRoomSkillParameter_611657, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSkillAuthorization_611670 = ref object of OpenApiRestCall_610658
proc url_DeleteSkillAuthorization_611672(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSkillAuthorization_611671(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611673 = header.getOrDefault("X-Amz-Target")
  valid_611673 = validateParameter(valid_611673, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteSkillAuthorization"))
  if valid_611673 != nil:
    section.add "X-Amz-Target", valid_611673
  var valid_611674 = header.getOrDefault("X-Amz-Signature")
  valid_611674 = validateParameter(valid_611674, JString, required = false,
                                 default = nil)
  if valid_611674 != nil:
    section.add "X-Amz-Signature", valid_611674
  var valid_611675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611675 = validateParameter(valid_611675, JString, required = false,
                                 default = nil)
  if valid_611675 != nil:
    section.add "X-Amz-Content-Sha256", valid_611675
  var valid_611676 = header.getOrDefault("X-Amz-Date")
  valid_611676 = validateParameter(valid_611676, JString, required = false,
                                 default = nil)
  if valid_611676 != nil:
    section.add "X-Amz-Date", valid_611676
  var valid_611677 = header.getOrDefault("X-Amz-Credential")
  valid_611677 = validateParameter(valid_611677, JString, required = false,
                                 default = nil)
  if valid_611677 != nil:
    section.add "X-Amz-Credential", valid_611677
  var valid_611678 = header.getOrDefault("X-Amz-Security-Token")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-Security-Token", valid_611678
  var valid_611679 = header.getOrDefault("X-Amz-Algorithm")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Algorithm", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-SignedHeaders", valid_611680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611682: Call_DeleteSkillAuthorization_611670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Unlinks a third-party account from a skill.
  ## 
  let valid = call_611682.validator(path, query, header, formData, body)
  let scheme = call_611682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611682.url(scheme.get, call_611682.host, call_611682.base,
                         call_611682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611682, url, valid)

proc call*(call_611683: Call_DeleteSkillAuthorization_611670; body: JsonNode): Recallable =
  ## deleteSkillAuthorization
  ## Unlinks a third-party account from a skill.
  ##   body: JObject (required)
  var body_611684 = newJObject()
  if body != nil:
    body_611684 = body
  result = call_611683.call(nil, nil, nil, nil, body_611684)

var deleteSkillAuthorization* = Call_DeleteSkillAuthorization_611670(
    name: "deleteSkillAuthorization", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteSkillAuthorization",
    validator: validate_DeleteSkillAuthorization_611671, base: "/",
    url: url_DeleteSkillAuthorization_611672, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSkillGroup_611685 = ref object of OpenApiRestCall_610658
proc url_DeleteSkillGroup_611687(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSkillGroup_611686(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611688 = header.getOrDefault("X-Amz-Target")
  valid_611688 = validateParameter(valid_611688, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteSkillGroup"))
  if valid_611688 != nil:
    section.add "X-Amz-Target", valid_611688
  var valid_611689 = header.getOrDefault("X-Amz-Signature")
  valid_611689 = validateParameter(valid_611689, JString, required = false,
                                 default = nil)
  if valid_611689 != nil:
    section.add "X-Amz-Signature", valid_611689
  var valid_611690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611690 = validateParameter(valid_611690, JString, required = false,
                                 default = nil)
  if valid_611690 != nil:
    section.add "X-Amz-Content-Sha256", valid_611690
  var valid_611691 = header.getOrDefault("X-Amz-Date")
  valid_611691 = validateParameter(valid_611691, JString, required = false,
                                 default = nil)
  if valid_611691 != nil:
    section.add "X-Amz-Date", valid_611691
  var valid_611692 = header.getOrDefault("X-Amz-Credential")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = nil)
  if valid_611692 != nil:
    section.add "X-Amz-Credential", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-Security-Token")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Security-Token", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Algorithm")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Algorithm", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-SignedHeaders", valid_611695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611697: Call_DeleteSkillGroup_611685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a skill group by skill group ARN.
  ## 
  let valid = call_611697.validator(path, query, header, formData, body)
  let scheme = call_611697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611697.url(scheme.get, call_611697.host, call_611697.base,
                         call_611697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611697, url, valid)

proc call*(call_611698: Call_DeleteSkillGroup_611685; body: JsonNode): Recallable =
  ## deleteSkillGroup
  ## Deletes a skill group by skill group ARN.
  ##   body: JObject (required)
  var body_611699 = newJObject()
  if body != nil:
    body_611699 = body
  result = call_611698.call(nil, nil, nil, nil, body_611699)

var deleteSkillGroup* = Call_DeleteSkillGroup_611685(name: "deleteSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteSkillGroup",
    validator: validate_DeleteSkillGroup_611686, base: "/",
    url: url_DeleteSkillGroup_611687, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_611700 = ref object of OpenApiRestCall_610658
proc url_DeleteUser_611702(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUser_611701(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611703 = header.getOrDefault("X-Amz-Target")
  valid_611703 = validateParameter(valid_611703, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteUser"))
  if valid_611703 != nil:
    section.add "X-Amz-Target", valid_611703
  var valid_611704 = header.getOrDefault("X-Amz-Signature")
  valid_611704 = validateParameter(valid_611704, JString, required = false,
                                 default = nil)
  if valid_611704 != nil:
    section.add "X-Amz-Signature", valid_611704
  var valid_611705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "X-Amz-Content-Sha256", valid_611705
  var valid_611706 = header.getOrDefault("X-Amz-Date")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-Date", valid_611706
  var valid_611707 = header.getOrDefault("X-Amz-Credential")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Credential", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-Security-Token")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Security-Token", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-Algorithm")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Algorithm", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-SignedHeaders", valid_611710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611712: Call_DeleteUser_611700; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified user by user ARN and enrollment ARN.
  ## 
  let valid = call_611712.validator(path, query, header, formData, body)
  let scheme = call_611712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611712.url(scheme.get, call_611712.host, call_611712.base,
                         call_611712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611712, url, valid)

proc call*(call_611713: Call_DeleteUser_611700; body: JsonNode): Recallable =
  ## deleteUser
  ## Deletes a specified user by user ARN and enrollment ARN.
  ##   body: JObject (required)
  var body_611714 = newJObject()
  if body != nil:
    body_611714 = body
  result = call_611713.call(nil, nil, nil, nil, body_611714)

var deleteUser* = Call_DeleteUser_611700(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DeleteUser",
                                      validator: validate_DeleteUser_611701,
                                      base: "/", url: url_DeleteUser_611702,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateContactFromAddressBook_611715 = ref object of OpenApiRestCall_610658
proc url_DisassociateContactFromAddressBook_611717(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateContactFromAddressBook_611716(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611718 = header.getOrDefault("X-Amz-Target")
  valid_611718 = validateParameter(valid_611718, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateContactFromAddressBook"))
  if valid_611718 != nil:
    section.add "X-Amz-Target", valid_611718
  var valid_611719 = header.getOrDefault("X-Amz-Signature")
  valid_611719 = validateParameter(valid_611719, JString, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "X-Amz-Signature", valid_611719
  var valid_611720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611720 = validateParameter(valid_611720, JString, required = false,
                                 default = nil)
  if valid_611720 != nil:
    section.add "X-Amz-Content-Sha256", valid_611720
  var valid_611721 = header.getOrDefault("X-Amz-Date")
  valid_611721 = validateParameter(valid_611721, JString, required = false,
                                 default = nil)
  if valid_611721 != nil:
    section.add "X-Amz-Date", valid_611721
  var valid_611722 = header.getOrDefault("X-Amz-Credential")
  valid_611722 = validateParameter(valid_611722, JString, required = false,
                                 default = nil)
  if valid_611722 != nil:
    section.add "X-Amz-Credential", valid_611722
  var valid_611723 = header.getOrDefault("X-Amz-Security-Token")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-Security-Token", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Algorithm")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Algorithm", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-SignedHeaders", valid_611725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611727: Call_DisassociateContactFromAddressBook_611715;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a contact from a given address book.
  ## 
  let valid = call_611727.validator(path, query, header, formData, body)
  let scheme = call_611727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611727.url(scheme.get, call_611727.host, call_611727.base,
                         call_611727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611727, url, valid)

proc call*(call_611728: Call_DisassociateContactFromAddressBook_611715;
          body: JsonNode): Recallable =
  ## disassociateContactFromAddressBook
  ## Disassociates a contact from a given address book.
  ##   body: JObject (required)
  var body_611729 = newJObject()
  if body != nil:
    body_611729 = body
  result = call_611728.call(nil, nil, nil, nil, body_611729)

var disassociateContactFromAddressBook* = Call_DisassociateContactFromAddressBook_611715(
    name: "disassociateContactFromAddressBook", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DisassociateContactFromAddressBook",
    validator: validate_DisassociateContactFromAddressBook_611716, base: "/",
    url: url_DisassociateContactFromAddressBook_611717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDeviceFromRoom_611730 = ref object of OpenApiRestCall_610658
proc url_DisassociateDeviceFromRoom_611732(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateDeviceFromRoom_611731(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611733 = header.getOrDefault("X-Amz-Target")
  valid_611733 = validateParameter(valid_611733, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateDeviceFromRoom"))
  if valid_611733 != nil:
    section.add "X-Amz-Target", valid_611733
  var valid_611734 = header.getOrDefault("X-Amz-Signature")
  valid_611734 = validateParameter(valid_611734, JString, required = false,
                                 default = nil)
  if valid_611734 != nil:
    section.add "X-Amz-Signature", valid_611734
  var valid_611735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611735 = validateParameter(valid_611735, JString, required = false,
                                 default = nil)
  if valid_611735 != nil:
    section.add "X-Amz-Content-Sha256", valid_611735
  var valid_611736 = header.getOrDefault("X-Amz-Date")
  valid_611736 = validateParameter(valid_611736, JString, required = false,
                                 default = nil)
  if valid_611736 != nil:
    section.add "X-Amz-Date", valid_611736
  var valid_611737 = header.getOrDefault("X-Amz-Credential")
  valid_611737 = validateParameter(valid_611737, JString, required = false,
                                 default = nil)
  if valid_611737 != nil:
    section.add "X-Amz-Credential", valid_611737
  var valid_611738 = header.getOrDefault("X-Amz-Security-Token")
  valid_611738 = validateParameter(valid_611738, JString, required = false,
                                 default = nil)
  if valid_611738 != nil:
    section.add "X-Amz-Security-Token", valid_611738
  var valid_611739 = header.getOrDefault("X-Amz-Algorithm")
  valid_611739 = validateParameter(valid_611739, JString, required = false,
                                 default = nil)
  if valid_611739 != nil:
    section.add "X-Amz-Algorithm", valid_611739
  var valid_611740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-SignedHeaders", valid_611740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611742: Call_DisassociateDeviceFromRoom_611730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a device from its current room. The device continues to be connected to the Wi-Fi network and is still registered to the account. The device settings and skills are removed from the room.
  ## 
  let valid = call_611742.validator(path, query, header, formData, body)
  let scheme = call_611742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611742.url(scheme.get, call_611742.host, call_611742.base,
                         call_611742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611742, url, valid)

proc call*(call_611743: Call_DisassociateDeviceFromRoom_611730; body: JsonNode): Recallable =
  ## disassociateDeviceFromRoom
  ## Disassociates a device from its current room. The device continues to be connected to the Wi-Fi network and is still registered to the account. The device settings and skills are removed from the room.
  ##   body: JObject (required)
  var body_611744 = newJObject()
  if body != nil:
    body_611744 = body
  result = call_611743.call(nil, nil, nil, nil, body_611744)

var disassociateDeviceFromRoom* = Call_DisassociateDeviceFromRoom_611730(
    name: "disassociateDeviceFromRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateDeviceFromRoom",
    validator: validate_DisassociateDeviceFromRoom_611731, base: "/",
    url: url_DisassociateDeviceFromRoom_611732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillFromSkillGroup_611745 = ref object of OpenApiRestCall_610658
proc url_DisassociateSkillFromSkillGroup_611747(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateSkillFromSkillGroup_611746(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611748 = header.getOrDefault("X-Amz-Target")
  valid_611748 = validateParameter(valid_611748, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillFromSkillGroup"))
  if valid_611748 != nil:
    section.add "X-Amz-Target", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-Signature")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-Signature", valid_611749
  var valid_611750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611750 = validateParameter(valid_611750, JString, required = false,
                                 default = nil)
  if valid_611750 != nil:
    section.add "X-Amz-Content-Sha256", valid_611750
  var valid_611751 = header.getOrDefault("X-Amz-Date")
  valid_611751 = validateParameter(valid_611751, JString, required = false,
                                 default = nil)
  if valid_611751 != nil:
    section.add "X-Amz-Date", valid_611751
  var valid_611752 = header.getOrDefault("X-Amz-Credential")
  valid_611752 = validateParameter(valid_611752, JString, required = false,
                                 default = nil)
  if valid_611752 != nil:
    section.add "X-Amz-Credential", valid_611752
  var valid_611753 = header.getOrDefault("X-Amz-Security-Token")
  valid_611753 = validateParameter(valid_611753, JString, required = false,
                                 default = nil)
  if valid_611753 != nil:
    section.add "X-Amz-Security-Token", valid_611753
  var valid_611754 = header.getOrDefault("X-Amz-Algorithm")
  valid_611754 = validateParameter(valid_611754, JString, required = false,
                                 default = nil)
  if valid_611754 != nil:
    section.add "X-Amz-Algorithm", valid_611754
  var valid_611755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611755 = validateParameter(valid_611755, JString, required = false,
                                 default = nil)
  if valid_611755 != nil:
    section.add "X-Amz-SignedHeaders", valid_611755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611757: Call_DisassociateSkillFromSkillGroup_611745;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a skill from a skill group.
  ## 
  let valid = call_611757.validator(path, query, header, formData, body)
  let scheme = call_611757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611757.url(scheme.get, call_611757.host, call_611757.base,
                         call_611757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611757, url, valid)

proc call*(call_611758: Call_DisassociateSkillFromSkillGroup_611745; body: JsonNode): Recallable =
  ## disassociateSkillFromSkillGroup
  ## Disassociates a skill from a skill group.
  ##   body: JObject (required)
  var body_611759 = newJObject()
  if body != nil:
    body_611759 = body
  result = call_611758.call(nil, nil, nil, nil, body_611759)

var disassociateSkillFromSkillGroup* = Call_DisassociateSkillFromSkillGroup_611745(
    name: "disassociateSkillFromSkillGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillFromSkillGroup",
    validator: validate_DisassociateSkillFromSkillGroup_611746, base: "/",
    url: url_DisassociateSkillFromSkillGroup_611747,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillFromUsers_611760 = ref object of OpenApiRestCall_610658
proc url_DisassociateSkillFromUsers_611762(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateSkillFromUsers_611761(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611763 = header.getOrDefault("X-Amz-Target")
  valid_611763 = validateParameter(valid_611763, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillFromUsers"))
  if valid_611763 != nil:
    section.add "X-Amz-Target", valid_611763
  var valid_611764 = header.getOrDefault("X-Amz-Signature")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-Signature", valid_611764
  var valid_611765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611765 = validateParameter(valid_611765, JString, required = false,
                                 default = nil)
  if valid_611765 != nil:
    section.add "X-Amz-Content-Sha256", valid_611765
  var valid_611766 = header.getOrDefault("X-Amz-Date")
  valid_611766 = validateParameter(valid_611766, JString, required = false,
                                 default = nil)
  if valid_611766 != nil:
    section.add "X-Amz-Date", valid_611766
  var valid_611767 = header.getOrDefault("X-Amz-Credential")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "X-Amz-Credential", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-Security-Token")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-Security-Token", valid_611768
  var valid_611769 = header.getOrDefault("X-Amz-Algorithm")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "X-Amz-Algorithm", valid_611769
  var valid_611770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "X-Amz-SignedHeaders", valid_611770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611772: Call_DisassociateSkillFromUsers_611760; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Makes a private skill unavailable for enrolled users and prevents them from enabling it on their devices.
  ## 
  let valid = call_611772.validator(path, query, header, formData, body)
  let scheme = call_611772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611772.url(scheme.get, call_611772.host, call_611772.base,
                         call_611772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611772, url, valid)

proc call*(call_611773: Call_DisassociateSkillFromUsers_611760; body: JsonNode): Recallable =
  ## disassociateSkillFromUsers
  ## Makes a private skill unavailable for enrolled users and prevents them from enabling it on their devices.
  ##   body: JObject (required)
  var body_611774 = newJObject()
  if body != nil:
    body_611774 = body
  result = call_611773.call(nil, nil, nil, nil, body_611774)

var disassociateSkillFromUsers* = Call_DisassociateSkillFromUsers_611760(
    name: "disassociateSkillFromUsers", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillFromUsers",
    validator: validate_DisassociateSkillFromUsers_611761, base: "/",
    url: url_DisassociateSkillFromUsers_611762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillGroupFromRoom_611775 = ref object of OpenApiRestCall_610658
proc url_DisassociateSkillGroupFromRoom_611777(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateSkillGroupFromRoom_611776(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611778 = header.getOrDefault("X-Amz-Target")
  valid_611778 = validateParameter(valid_611778, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillGroupFromRoom"))
  if valid_611778 != nil:
    section.add "X-Amz-Target", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Signature")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Signature", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-Content-Sha256", valid_611780
  var valid_611781 = header.getOrDefault("X-Amz-Date")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "X-Amz-Date", valid_611781
  var valid_611782 = header.getOrDefault("X-Amz-Credential")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "X-Amz-Credential", valid_611782
  var valid_611783 = header.getOrDefault("X-Amz-Security-Token")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-Security-Token", valid_611783
  var valid_611784 = header.getOrDefault("X-Amz-Algorithm")
  valid_611784 = validateParameter(valid_611784, JString, required = false,
                                 default = nil)
  if valid_611784 != nil:
    section.add "X-Amz-Algorithm", valid_611784
  var valid_611785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611785 = validateParameter(valid_611785, JString, required = false,
                                 default = nil)
  if valid_611785 != nil:
    section.add "X-Amz-SignedHeaders", valid_611785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611787: Call_DisassociateSkillGroupFromRoom_611775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a skill group from a specified room. This disables all skills in the skill group on all devices in the room.
  ## 
  let valid = call_611787.validator(path, query, header, formData, body)
  let scheme = call_611787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611787.url(scheme.get, call_611787.host, call_611787.base,
                         call_611787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611787, url, valid)

proc call*(call_611788: Call_DisassociateSkillGroupFromRoom_611775; body: JsonNode): Recallable =
  ## disassociateSkillGroupFromRoom
  ## Disassociates a skill group from a specified room. This disables all skills in the skill group on all devices in the room.
  ##   body: JObject (required)
  var body_611789 = newJObject()
  if body != nil:
    body_611789 = body
  result = call_611788.call(nil, nil, nil, nil, body_611789)

var disassociateSkillGroupFromRoom* = Call_DisassociateSkillGroupFromRoom_611775(
    name: "disassociateSkillGroupFromRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillGroupFromRoom",
    validator: validate_DisassociateSkillGroupFromRoom_611776, base: "/",
    url: url_DisassociateSkillGroupFromRoom_611777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgetSmartHomeAppliances_611790 = ref object of OpenApiRestCall_610658
proc url_ForgetSmartHomeAppliances_611792(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ForgetSmartHomeAppliances_611791(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611793 = header.getOrDefault("X-Amz-Target")
  valid_611793 = validateParameter(valid_611793, JString, required = true, default = newJString(
      "AlexaForBusiness.ForgetSmartHomeAppliances"))
  if valid_611793 != nil:
    section.add "X-Amz-Target", valid_611793
  var valid_611794 = header.getOrDefault("X-Amz-Signature")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Signature", valid_611794
  var valid_611795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-Content-Sha256", valid_611795
  var valid_611796 = header.getOrDefault("X-Amz-Date")
  valid_611796 = validateParameter(valid_611796, JString, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "X-Amz-Date", valid_611796
  var valid_611797 = header.getOrDefault("X-Amz-Credential")
  valid_611797 = validateParameter(valid_611797, JString, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "X-Amz-Credential", valid_611797
  var valid_611798 = header.getOrDefault("X-Amz-Security-Token")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "X-Amz-Security-Token", valid_611798
  var valid_611799 = header.getOrDefault("X-Amz-Algorithm")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "X-Amz-Algorithm", valid_611799
  var valid_611800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "X-Amz-SignedHeaders", valid_611800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611802: Call_ForgetSmartHomeAppliances_611790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Forgets smart home appliances associated to a room.
  ## 
  let valid = call_611802.validator(path, query, header, formData, body)
  let scheme = call_611802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611802.url(scheme.get, call_611802.host, call_611802.base,
                         call_611802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611802, url, valid)

proc call*(call_611803: Call_ForgetSmartHomeAppliances_611790; body: JsonNode): Recallable =
  ## forgetSmartHomeAppliances
  ## Forgets smart home appliances associated to a room.
  ##   body: JObject (required)
  var body_611804 = newJObject()
  if body != nil:
    body_611804 = body
  result = call_611803.call(nil, nil, nil, nil, body_611804)

var forgetSmartHomeAppliances* = Call_ForgetSmartHomeAppliances_611790(
    name: "forgetSmartHomeAppliances", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ForgetSmartHomeAppliances",
    validator: validate_ForgetSmartHomeAppliances_611791, base: "/",
    url: url_ForgetSmartHomeAppliances_611792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddressBook_611805 = ref object of OpenApiRestCall_610658
proc url_GetAddressBook_611807(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddressBook_611806(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611808 = header.getOrDefault("X-Amz-Target")
  valid_611808 = validateParameter(valid_611808, JString, required = true, default = newJString(
      "AlexaForBusiness.GetAddressBook"))
  if valid_611808 != nil:
    section.add "X-Amz-Target", valid_611808
  var valid_611809 = header.getOrDefault("X-Amz-Signature")
  valid_611809 = validateParameter(valid_611809, JString, required = false,
                                 default = nil)
  if valid_611809 != nil:
    section.add "X-Amz-Signature", valid_611809
  var valid_611810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-Content-Sha256", valid_611810
  var valid_611811 = header.getOrDefault("X-Amz-Date")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-Date", valid_611811
  var valid_611812 = header.getOrDefault("X-Amz-Credential")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-Credential", valid_611812
  var valid_611813 = header.getOrDefault("X-Amz-Security-Token")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Security-Token", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-Algorithm")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Algorithm", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-SignedHeaders", valid_611815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611817: Call_GetAddressBook_611805; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets address the book details by the address book ARN.
  ## 
  let valid = call_611817.validator(path, query, header, formData, body)
  let scheme = call_611817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611817.url(scheme.get, call_611817.host, call_611817.base,
                         call_611817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611817, url, valid)

proc call*(call_611818: Call_GetAddressBook_611805; body: JsonNode): Recallable =
  ## getAddressBook
  ## Gets address the book details by the address book ARN.
  ##   body: JObject (required)
  var body_611819 = newJObject()
  if body != nil:
    body_611819 = body
  result = call_611818.call(nil, nil, nil, nil, body_611819)

var getAddressBook* = Call_GetAddressBook_611805(name: "getAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetAddressBook",
    validator: validate_GetAddressBook_611806, base: "/", url: url_GetAddressBook_611807,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConferencePreference_611820 = ref object of OpenApiRestCall_610658
proc url_GetConferencePreference_611822(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConferencePreference_611821(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611823 = header.getOrDefault("X-Amz-Target")
  valid_611823 = validateParameter(valid_611823, JString, required = true, default = newJString(
      "AlexaForBusiness.GetConferencePreference"))
  if valid_611823 != nil:
    section.add "X-Amz-Target", valid_611823
  var valid_611824 = header.getOrDefault("X-Amz-Signature")
  valid_611824 = validateParameter(valid_611824, JString, required = false,
                                 default = nil)
  if valid_611824 != nil:
    section.add "X-Amz-Signature", valid_611824
  var valid_611825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "X-Amz-Content-Sha256", valid_611825
  var valid_611826 = header.getOrDefault("X-Amz-Date")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-Date", valid_611826
  var valid_611827 = header.getOrDefault("X-Amz-Credential")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "X-Amz-Credential", valid_611827
  var valid_611828 = header.getOrDefault("X-Amz-Security-Token")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-Security-Token", valid_611828
  var valid_611829 = header.getOrDefault("X-Amz-Algorithm")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-Algorithm", valid_611829
  var valid_611830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "X-Amz-SignedHeaders", valid_611830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611832: Call_GetConferencePreference_611820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the existing conference preferences.
  ## 
  let valid = call_611832.validator(path, query, header, formData, body)
  let scheme = call_611832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611832.url(scheme.get, call_611832.host, call_611832.base,
                         call_611832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611832, url, valid)

proc call*(call_611833: Call_GetConferencePreference_611820; body: JsonNode): Recallable =
  ## getConferencePreference
  ## Retrieves the existing conference preferences.
  ##   body: JObject (required)
  var body_611834 = newJObject()
  if body != nil:
    body_611834 = body
  result = call_611833.call(nil, nil, nil, nil, body_611834)

var getConferencePreference* = Call_GetConferencePreference_611820(
    name: "getConferencePreference", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetConferencePreference",
    validator: validate_GetConferencePreference_611821, base: "/",
    url: url_GetConferencePreference_611822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConferenceProvider_611835 = ref object of OpenApiRestCall_610658
proc url_GetConferenceProvider_611837(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConferenceProvider_611836(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611838 = header.getOrDefault("X-Amz-Target")
  valid_611838 = validateParameter(valid_611838, JString, required = true, default = newJString(
      "AlexaForBusiness.GetConferenceProvider"))
  if valid_611838 != nil:
    section.add "X-Amz-Target", valid_611838
  var valid_611839 = header.getOrDefault("X-Amz-Signature")
  valid_611839 = validateParameter(valid_611839, JString, required = false,
                                 default = nil)
  if valid_611839 != nil:
    section.add "X-Amz-Signature", valid_611839
  var valid_611840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611840 = validateParameter(valid_611840, JString, required = false,
                                 default = nil)
  if valid_611840 != nil:
    section.add "X-Amz-Content-Sha256", valid_611840
  var valid_611841 = header.getOrDefault("X-Amz-Date")
  valid_611841 = validateParameter(valid_611841, JString, required = false,
                                 default = nil)
  if valid_611841 != nil:
    section.add "X-Amz-Date", valid_611841
  var valid_611842 = header.getOrDefault("X-Amz-Credential")
  valid_611842 = validateParameter(valid_611842, JString, required = false,
                                 default = nil)
  if valid_611842 != nil:
    section.add "X-Amz-Credential", valid_611842
  var valid_611843 = header.getOrDefault("X-Amz-Security-Token")
  valid_611843 = validateParameter(valid_611843, JString, required = false,
                                 default = nil)
  if valid_611843 != nil:
    section.add "X-Amz-Security-Token", valid_611843
  var valid_611844 = header.getOrDefault("X-Amz-Algorithm")
  valid_611844 = validateParameter(valid_611844, JString, required = false,
                                 default = nil)
  if valid_611844 != nil:
    section.add "X-Amz-Algorithm", valid_611844
  var valid_611845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611845 = validateParameter(valid_611845, JString, required = false,
                                 default = nil)
  if valid_611845 != nil:
    section.add "X-Amz-SignedHeaders", valid_611845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611847: Call_GetConferenceProvider_611835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a specific conference provider.
  ## 
  let valid = call_611847.validator(path, query, header, formData, body)
  let scheme = call_611847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611847.url(scheme.get, call_611847.host, call_611847.base,
                         call_611847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611847, url, valid)

proc call*(call_611848: Call_GetConferenceProvider_611835; body: JsonNode): Recallable =
  ## getConferenceProvider
  ## Gets details about a specific conference provider.
  ##   body: JObject (required)
  var body_611849 = newJObject()
  if body != nil:
    body_611849 = body
  result = call_611848.call(nil, nil, nil, nil, body_611849)

var getConferenceProvider* = Call_GetConferenceProvider_611835(
    name: "getConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetConferenceProvider",
    validator: validate_GetConferenceProvider_611836, base: "/",
    url: url_GetConferenceProvider_611837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContact_611850 = ref object of OpenApiRestCall_610658
proc url_GetContact_611852(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetContact_611851(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611853 = header.getOrDefault("X-Amz-Target")
  valid_611853 = validateParameter(valid_611853, JString, required = true, default = newJString(
      "AlexaForBusiness.GetContact"))
  if valid_611853 != nil:
    section.add "X-Amz-Target", valid_611853
  var valid_611854 = header.getOrDefault("X-Amz-Signature")
  valid_611854 = validateParameter(valid_611854, JString, required = false,
                                 default = nil)
  if valid_611854 != nil:
    section.add "X-Amz-Signature", valid_611854
  var valid_611855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611855 = validateParameter(valid_611855, JString, required = false,
                                 default = nil)
  if valid_611855 != nil:
    section.add "X-Amz-Content-Sha256", valid_611855
  var valid_611856 = header.getOrDefault("X-Amz-Date")
  valid_611856 = validateParameter(valid_611856, JString, required = false,
                                 default = nil)
  if valid_611856 != nil:
    section.add "X-Amz-Date", valid_611856
  var valid_611857 = header.getOrDefault("X-Amz-Credential")
  valid_611857 = validateParameter(valid_611857, JString, required = false,
                                 default = nil)
  if valid_611857 != nil:
    section.add "X-Amz-Credential", valid_611857
  var valid_611858 = header.getOrDefault("X-Amz-Security-Token")
  valid_611858 = validateParameter(valid_611858, JString, required = false,
                                 default = nil)
  if valid_611858 != nil:
    section.add "X-Amz-Security-Token", valid_611858
  var valid_611859 = header.getOrDefault("X-Amz-Algorithm")
  valid_611859 = validateParameter(valid_611859, JString, required = false,
                                 default = nil)
  if valid_611859 != nil:
    section.add "X-Amz-Algorithm", valid_611859
  var valid_611860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611860 = validateParameter(valid_611860, JString, required = false,
                                 default = nil)
  if valid_611860 != nil:
    section.add "X-Amz-SignedHeaders", valid_611860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611862: Call_GetContact_611850; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contact details by the contact ARN.
  ## 
  let valid = call_611862.validator(path, query, header, formData, body)
  let scheme = call_611862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611862.url(scheme.get, call_611862.host, call_611862.base,
                         call_611862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611862, url, valid)

proc call*(call_611863: Call_GetContact_611850; body: JsonNode): Recallable =
  ## getContact
  ## Gets the contact details by the contact ARN.
  ##   body: JObject (required)
  var body_611864 = newJObject()
  if body != nil:
    body_611864 = body
  result = call_611863.call(nil, nil, nil, nil, body_611864)

var getContact* = Call_GetContact_611850(name: "getContact",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetContact",
                                      validator: validate_GetContact_611851,
                                      base: "/", url: url_GetContact_611852,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_611865 = ref object of OpenApiRestCall_610658
proc url_GetDevice_611867(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevice_611866(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611868 = header.getOrDefault("X-Amz-Target")
  valid_611868 = validateParameter(valid_611868, JString, required = true, default = newJString(
      "AlexaForBusiness.GetDevice"))
  if valid_611868 != nil:
    section.add "X-Amz-Target", valid_611868
  var valid_611869 = header.getOrDefault("X-Amz-Signature")
  valid_611869 = validateParameter(valid_611869, JString, required = false,
                                 default = nil)
  if valid_611869 != nil:
    section.add "X-Amz-Signature", valid_611869
  var valid_611870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611870 = validateParameter(valid_611870, JString, required = false,
                                 default = nil)
  if valid_611870 != nil:
    section.add "X-Amz-Content-Sha256", valid_611870
  var valid_611871 = header.getOrDefault("X-Amz-Date")
  valid_611871 = validateParameter(valid_611871, JString, required = false,
                                 default = nil)
  if valid_611871 != nil:
    section.add "X-Amz-Date", valid_611871
  var valid_611872 = header.getOrDefault("X-Amz-Credential")
  valid_611872 = validateParameter(valid_611872, JString, required = false,
                                 default = nil)
  if valid_611872 != nil:
    section.add "X-Amz-Credential", valid_611872
  var valid_611873 = header.getOrDefault("X-Amz-Security-Token")
  valid_611873 = validateParameter(valid_611873, JString, required = false,
                                 default = nil)
  if valid_611873 != nil:
    section.add "X-Amz-Security-Token", valid_611873
  var valid_611874 = header.getOrDefault("X-Amz-Algorithm")
  valid_611874 = validateParameter(valid_611874, JString, required = false,
                                 default = nil)
  if valid_611874 != nil:
    section.add "X-Amz-Algorithm", valid_611874
  var valid_611875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611875 = validateParameter(valid_611875, JString, required = false,
                                 default = nil)
  if valid_611875 != nil:
    section.add "X-Amz-SignedHeaders", valid_611875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611877: Call_GetDevice_611865; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details of a device by device ARN.
  ## 
  let valid = call_611877.validator(path, query, header, formData, body)
  let scheme = call_611877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611877.url(scheme.get, call_611877.host, call_611877.base,
                         call_611877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611877, url, valid)

proc call*(call_611878: Call_GetDevice_611865; body: JsonNode): Recallable =
  ## getDevice
  ## Gets the details of a device by device ARN.
  ##   body: JObject (required)
  var body_611879 = newJObject()
  if body != nil:
    body_611879 = body
  result = call_611878.call(nil, nil, nil, nil, body_611879)

var getDevice* = Call_GetDevice_611865(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetDevice",
                                    validator: validate_GetDevice_611866,
                                    base: "/", url: url_GetDevice_611867,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGateway_611880 = ref object of OpenApiRestCall_610658
proc url_GetGateway_611882(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGateway_611881(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611883 = header.getOrDefault("X-Amz-Target")
  valid_611883 = validateParameter(valid_611883, JString, required = true, default = newJString(
      "AlexaForBusiness.GetGateway"))
  if valid_611883 != nil:
    section.add "X-Amz-Target", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-Signature")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-Signature", valid_611884
  var valid_611885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611885 = validateParameter(valid_611885, JString, required = false,
                                 default = nil)
  if valid_611885 != nil:
    section.add "X-Amz-Content-Sha256", valid_611885
  var valid_611886 = header.getOrDefault("X-Amz-Date")
  valid_611886 = validateParameter(valid_611886, JString, required = false,
                                 default = nil)
  if valid_611886 != nil:
    section.add "X-Amz-Date", valid_611886
  var valid_611887 = header.getOrDefault("X-Amz-Credential")
  valid_611887 = validateParameter(valid_611887, JString, required = false,
                                 default = nil)
  if valid_611887 != nil:
    section.add "X-Amz-Credential", valid_611887
  var valid_611888 = header.getOrDefault("X-Amz-Security-Token")
  valid_611888 = validateParameter(valid_611888, JString, required = false,
                                 default = nil)
  if valid_611888 != nil:
    section.add "X-Amz-Security-Token", valid_611888
  var valid_611889 = header.getOrDefault("X-Amz-Algorithm")
  valid_611889 = validateParameter(valid_611889, JString, required = false,
                                 default = nil)
  if valid_611889 != nil:
    section.add "X-Amz-Algorithm", valid_611889
  var valid_611890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611890 = validateParameter(valid_611890, JString, required = false,
                                 default = nil)
  if valid_611890 != nil:
    section.add "X-Amz-SignedHeaders", valid_611890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611892: Call_GetGateway_611880; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details of a gateway.
  ## 
  let valid = call_611892.validator(path, query, header, formData, body)
  let scheme = call_611892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611892.url(scheme.get, call_611892.host, call_611892.base,
                         call_611892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611892, url, valid)

proc call*(call_611893: Call_GetGateway_611880; body: JsonNode): Recallable =
  ## getGateway
  ## Retrieves the details of a gateway.
  ##   body: JObject (required)
  var body_611894 = newJObject()
  if body != nil:
    body_611894 = body
  result = call_611893.call(nil, nil, nil, nil, body_611894)

var getGateway* = Call_GetGateway_611880(name: "getGateway",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetGateway",
                                      validator: validate_GetGateway_611881,
                                      base: "/", url: url_GetGateway_611882,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayGroup_611895 = ref object of OpenApiRestCall_610658
proc url_GetGatewayGroup_611897(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGatewayGroup_611896(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611898 = header.getOrDefault("X-Amz-Target")
  valid_611898 = validateParameter(valid_611898, JString, required = true, default = newJString(
      "AlexaForBusiness.GetGatewayGroup"))
  if valid_611898 != nil:
    section.add "X-Amz-Target", valid_611898
  var valid_611899 = header.getOrDefault("X-Amz-Signature")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-Signature", valid_611899
  var valid_611900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611900 = validateParameter(valid_611900, JString, required = false,
                                 default = nil)
  if valid_611900 != nil:
    section.add "X-Amz-Content-Sha256", valid_611900
  var valid_611901 = header.getOrDefault("X-Amz-Date")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "X-Amz-Date", valid_611901
  var valid_611902 = header.getOrDefault("X-Amz-Credential")
  valid_611902 = validateParameter(valid_611902, JString, required = false,
                                 default = nil)
  if valid_611902 != nil:
    section.add "X-Amz-Credential", valid_611902
  var valid_611903 = header.getOrDefault("X-Amz-Security-Token")
  valid_611903 = validateParameter(valid_611903, JString, required = false,
                                 default = nil)
  if valid_611903 != nil:
    section.add "X-Amz-Security-Token", valid_611903
  var valid_611904 = header.getOrDefault("X-Amz-Algorithm")
  valid_611904 = validateParameter(valid_611904, JString, required = false,
                                 default = nil)
  if valid_611904 != nil:
    section.add "X-Amz-Algorithm", valid_611904
  var valid_611905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611905 = validateParameter(valid_611905, JString, required = false,
                                 default = nil)
  if valid_611905 != nil:
    section.add "X-Amz-SignedHeaders", valid_611905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611907: Call_GetGatewayGroup_611895; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details of a gateway group.
  ## 
  let valid = call_611907.validator(path, query, header, formData, body)
  let scheme = call_611907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611907.url(scheme.get, call_611907.host, call_611907.base,
                         call_611907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611907, url, valid)

proc call*(call_611908: Call_GetGatewayGroup_611895; body: JsonNode): Recallable =
  ## getGatewayGroup
  ## Retrieves the details of a gateway group.
  ##   body: JObject (required)
  var body_611909 = newJObject()
  if body != nil:
    body_611909 = body
  result = call_611908.call(nil, nil, nil, nil, body_611909)

var getGatewayGroup* = Call_GetGatewayGroup_611895(name: "getGatewayGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetGatewayGroup",
    validator: validate_GetGatewayGroup_611896, base: "/", url: url_GetGatewayGroup_611897,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationConfiguration_611910 = ref object of OpenApiRestCall_610658
proc url_GetInvitationConfiguration_611912(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInvitationConfiguration_611911(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611913 = header.getOrDefault("X-Amz-Target")
  valid_611913 = validateParameter(valid_611913, JString, required = true, default = newJString(
      "AlexaForBusiness.GetInvitationConfiguration"))
  if valid_611913 != nil:
    section.add "X-Amz-Target", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-Signature")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-Signature", valid_611914
  var valid_611915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-Content-Sha256", valid_611915
  var valid_611916 = header.getOrDefault("X-Amz-Date")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-Date", valid_611916
  var valid_611917 = header.getOrDefault("X-Amz-Credential")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-Credential", valid_611917
  var valid_611918 = header.getOrDefault("X-Amz-Security-Token")
  valid_611918 = validateParameter(valid_611918, JString, required = false,
                                 default = nil)
  if valid_611918 != nil:
    section.add "X-Amz-Security-Token", valid_611918
  var valid_611919 = header.getOrDefault("X-Amz-Algorithm")
  valid_611919 = validateParameter(valid_611919, JString, required = false,
                                 default = nil)
  if valid_611919 != nil:
    section.add "X-Amz-Algorithm", valid_611919
  var valid_611920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611920 = validateParameter(valid_611920, JString, required = false,
                                 default = nil)
  if valid_611920 != nil:
    section.add "X-Amz-SignedHeaders", valid_611920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611922: Call_GetInvitationConfiguration_611910; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the configured values for the user enrollment invitation email template.
  ## 
  let valid = call_611922.validator(path, query, header, formData, body)
  let scheme = call_611922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611922.url(scheme.get, call_611922.host, call_611922.base,
                         call_611922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611922, url, valid)

proc call*(call_611923: Call_GetInvitationConfiguration_611910; body: JsonNode): Recallable =
  ## getInvitationConfiguration
  ## Retrieves the configured values for the user enrollment invitation email template.
  ##   body: JObject (required)
  var body_611924 = newJObject()
  if body != nil:
    body_611924 = body
  result = call_611923.call(nil, nil, nil, nil, body_611924)

var getInvitationConfiguration* = Call_GetInvitationConfiguration_611910(
    name: "getInvitationConfiguration", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetInvitationConfiguration",
    validator: validate_GetInvitationConfiguration_611911, base: "/",
    url: url_GetInvitationConfiguration_611912,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_611925 = ref object of OpenApiRestCall_610658
proc url_GetNetworkProfile_611927(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetNetworkProfile_611926(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611928 = header.getOrDefault("X-Amz-Target")
  valid_611928 = validateParameter(valid_611928, JString, required = true, default = newJString(
      "AlexaForBusiness.GetNetworkProfile"))
  if valid_611928 != nil:
    section.add "X-Amz-Target", valid_611928
  var valid_611929 = header.getOrDefault("X-Amz-Signature")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "X-Amz-Signature", valid_611929
  var valid_611930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "X-Amz-Content-Sha256", valid_611930
  var valid_611931 = header.getOrDefault("X-Amz-Date")
  valid_611931 = validateParameter(valid_611931, JString, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "X-Amz-Date", valid_611931
  var valid_611932 = header.getOrDefault("X-Amz-Credential")
  valid_611932 = validateParameter(valid_611932, JString, required = false,
                                 default = nil)
  if valid_611932 != nil:
    section.add "X-Amz-Credential", valid_611932
  var valid_611933 = header.getOrDefault("X-Amz-Security-Token")
  valid_611933 = validateParameter(valid_611933, JString, required = false,
                                 default = nil)
  if valid_611933 != nil:
    section.add "X-Amz-Security-Token", valid_611933
  var valid_611934 = header.getOrDefault("X-Amz-Algorithm")
  valid_611934 = validateParameter(valid_611934, JString, required = false,
                                 default = nil)
  if valid_611934 != nil:
    section.add "X-Amz-Algorithm", valid_611934
  var valid_611935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611935 = validateParameter(valid_611935, JString, required = false,
                                 default = nil)
  if valid_611935 != nil:
    section.add "X-Amz-SignedHeaders", valid_611935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611937: Call_GetNetworkProfile_611925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the network profile details by the network profile ARN.
  ## 
  let valid = call_611937.validator(path, query, header, formData, body)
  let scheme = call_611937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611937.url(scheme.get, call_611937.host, call_611937.base,
                         call_611937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611937, url, valid)

proc call*(call_611938: Call_GetNetworkProfile_611925; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Gets the network profile details by the network profile ARN.
  ##   body: JObject (required)
  var body_611939 = newJObject()
  if body != nil:
    body_611939 = body
  result = call_611938.call(nil, nil, nil, nil, body_611939)

var getNetworkProfile* = Call_GetNetworkProfile_611925(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetNetworkProfile",
    validator: validate_GetNetworkProfile_611926, base: "/",
    url: url_GetNetworkProfile_611927, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProfile_611940 = ref object of OpenApiRestCall_610658
proc url_GetProfile_611942(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetProfile_611941(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611943 = header.getOrDefault("X-Amz-Target")
  valid_611943 = validateParameter(valid_611943, JString, required = true, default = newJString(
      "AlexaForBusiness.GetProfile"))
  if valid_611943 != nil:
    section.add "X-Amz-Target", valid_611943
  var valid_611944 = header.getOrDefault("X-Amz-Signature")
  valid_611944 = validateParameter(valid_611944, JString, required = false,
                                 default = nil)
  if valid_611944 != nil:
    section.add "X-Amz-Signature", valid_611944
  var valid_611945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611945 = validateParameter(valid_611945, JString, required = false,
                                 default = nil)
  if valid_611945 != nil:
    section.add "X-Amz-Content-Sha256", valid_611945
  var valid_611946 = header.getOrDefault("X-Amz-Date")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "X-Amz-Date", valid_611946
  var valid_611947 = header.getOrDefault("X-Amz-Credential")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "X-Amz-Credential", valid_611947
  var valid_611948 = header.getOrDefault("X-Amz-Security-Token")
  valid_611948 = validateParameter(valid_611948, JString, required = false,
                                 default = nil)
  if valid_611948 != nil:
    section.add "X-Amz-Security-Token", valid_611948
  var valid_611949 = header.getOrDefault("X-Amz-Algorithm")
  valid_611949 = validateParameter(valid_611949, JString, required = false,
                                 default = nil)
  if valid_611949 != nil:
    section.add "X-Amz-Algorithm", valid_611949
  var valid_611950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611950 = validateParameter(valid_611950, JString, required = false,
                                 default = nil)
  if valid_611950 != nil:
    section.add "X-Amz-SignedHeaders", valid_611950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611952: Call_GetProfile_611940; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details of a room profile by profile ARN.
  ## 
  let valid = call_611952.validator(path, query, header, formData, body)
  let scheme = call_611952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611952.url(scheme.get, call_611952.host, call_611952.base,
                         call_611952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611952, url, valid)

proc call*(call_611953: Call_GetProfile_611940; body: JsonNode): Recallable =
  ## getProfile
  ## Gets the details of a room profile by profile ARN.
  ##   body: JObject (required)
  var body_611954 = newJObject()
  if body != nil:
    body_611954 = body
  result = call_611953.call(nil, nil, nil, nil, body_611954)

var getProfile* = Call_GetProfile_611940(name: "getProfile",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetProfile",
                                      validator: validate_GetProfile_611941,
                                      base: "/", url: url_GetProfile_611942,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoom_611955 = ref object of OpenApiRestCall_610658
proc url_GetRoom_611957(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRoom_611956(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611958 = header.getOrDefault("X-Amz-Target")
  valid_611958 = validateParameter(valid_611958, JString, required = true, default = newJString(
      "AlexaForBusiness.GetRoom"))
  if valid_611958 != nil:
    section.add "X-Amz-Target", valid_611958
  var valid_611959 = header.getOrDefault("X-Amz-Signature")
  valid_611959 = validateParameter(valid_611959, JString, required = false,
                                 default = nil)
  if valid_611959 != nil:
    section.add "X-Amz-Signature", valid_611959
  var valid_611960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611960 = validateParameter(valid_611960, JString, required = false,
                                 default = nil)
  if valid_611960 != nil:
    section.add "X-Amz-Content-Sha256", valid_611960
  var valid_611961 = header.getOrDefault("X-Amz-Date")
  valid_611961 = validateParameter(valid_611961, JString, required = false,
                                 default = nil)
  if valid_611961 != nil:
    section.add "X-Amz-Date", valid_611961
  var valid_611962 = header.getOrDefault("X-Amz-Credential")
  valid_611962 = validateParameter(valid_611962, JString, required = false,
                                 default = nil)
  if valid_611962 != nil:
    section.add "X-Amz-Credential", valid_611962
  var valid_611963 = header.getOrDefault("X-Amz-Security-Token")
  valid_611963 = validateParameter(valid_611963, JString, required = false,
                                 default = nil)
  if valid_611963 != nil:
    section.add "X-Amz-Security-Token", valid_611963
  var valid_611964 = header.getOrDefault("X-Amz-Algorithm")
  valid_611964 = validateParameter(valid_611964, JString, required = false,
                                 default = nil)
  if valid_611964 != nil:
    section.add "X-Amz-Algorithm", valid_611964
  var valid_611965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611965 = validateParameter(valid_611965, JString, required = false,
                                 default = nil)
  if valid_611965 != nil:
    section.add "X-Amz-SignedHeaders", valid_611965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611967: Call_GetRoom_611955; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets room details by room ARN.
  ## 
  let valid = call_611967.validator(path, query, header, formData, body)
  let scheme = call_611967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611967.url(scheme.get, call_611967.host, call_611967.base,
                         call_611967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611967, url, valid)

proc call*(call_611968: Call_GetRoom_611955; body: JsonNode): Recallable =
  ## getRoom
  ## Gets room details by room ARN.
  ##   body: JObject (required)
  var body_611969 = newJObject()
  if body != nil:
    body_611969 = body
  result = call_611968.call(nil, nil, nil, nil, body_611969)

var getRoom* = Call_GetRoom_611955(name: "getRoom", meth: HttpMethod.HttpPost,
                                host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetRoom",
                                validator: validate_GetRoom_611956, base: "/",
                                url: url_GetRoom_611957,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoomSkillParameter_611970 = ref object of OpenApiRestCall_610658
proc url_GetRoomSkillParameter_611972(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRoomSkillParameter_611971(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611973 = header.getOrDefault("X-Amz-Target")
  valid_611973 = validateParameter(valid_611973, JString, required = true, default = newJString(
      "AlexaForBusiness.GetRoomSkillParameter"))
  if valid_611973 != nil:
    section.add "X-Amz-Target", valid_611973
  var valid_611974 = header.getOrDefault("X-Amz-Signature")
  valid_611974 = validateParameter(valid_611974, JString, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "X-Amz-Signature", valid_611974
  var valid_611975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611975 = validateParameter(valid_611975, JString, required = false,
                                 default = nil)
  if valid_611975 != nil:
    section.add "X-Amz-Content-Sha256", valid_611975
  var valid_611976 = header.getOrDefault("X-Amz-Date")
  valid_611976 = validateParameter(valid_611976, JString, required = false,
                                 default = nil)
  if valid_611976 != nil:
    section.add "X-Amz-Date", valid_611976
  var valid_611977 = header.getOrDefault("X-Amz-Credential")
  valid_611977 = validateParameter(valid_611977, JString, required = false,
                                 default = nil)
  if valid_611977 != nil:
    section.add "X-Amz-Credential", valid_611977
  var valid_611978 = header.getOrDefault("X-Amz-Security-Token")
  valid_611978 = validateParameter(valid_611978, JString, required = false,
                                 default = nil)
  if valid_611978 != nil:
    section.add "X-Amz-Security-Token", valid_611978
  var valid_611979 = header.getOrDefault("X-Amz-Algorithm")
  valid_611979 = validateParameter(valid_611979, JString, required = false,
                                 default = nil)
  if valid_611979 != nil:
    section.add "X-Amz-Algorithm", valid_611979
  var valid_611980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611980 = validateParameter(valid_611980, JString, required = false,
                                 default = nil)
  if valid_611980 != nil:
    section.add "X-Amz-SignedHeaders", valid_611980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611982: Call_GetRoomSkillParameter_611970; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets room skill parameter details by room, skill, and parameter key ARN.
  ## 
  let valid = call_611982.validator(path, query, header, formData, body)
  let scheme = call_611982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611982.url(scheme.get, call_611982.host, call_611982.base,
                         call_611982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611982, url, valid)

proc call*(call_611983: Call_GetRoomSkillParameter_611970; body: JsonNode): Recallable =
  ## getRoomSkillParameter
  ## Gets room skill parameter details by room, skill, and parameter key ARN.
  ##   body: JObject (required)
  var body_611984 = newJObject()
  if body != nil:
    body_611984 = body
  result = call_611983.call(nil, nil, nil, nil, body_611984)

var getRoomSkillParameter* = Call_GetRoomSkillParameter_611970(
    name: "getRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetRoomSkillParameter",
    validator: validate_GetRoomSkillParameter_611971, base: "/",
    url: url_GetRoomSkillParameter_611972, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSkillGroup_611985 = ref object of OpenApiRestCall_610658
proc url_GetSkillGroup_611987(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSkillGroup_611986(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611988 = header.getOrDefault("X-Amz-Target")
  valid_611988 = validateParameter(valid_611988, JString, required = true, default = newJString(
      "AlexaForBusiness.GetSkillGroup"))
  if valid_611988 != nil:
    section.add "X-Amz-Target", valid_611988
  var valid_611989 = header.getOrDefault("X-Amz-Signature")
  valid_611989 = validateParameter(valid_611989, JString, required = false,
                                 default = nil)
  if valid_611989 != nil:
    section.add "X-Amz-Signature", valid_611989
  var valid_611990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611990 = validateParameter(valid_611990, JString, required = false,
                                 default = nil)
  if valid_611990 != nil:
    section.add "X-Amz-Content-Sha256", valid_611990
  var valid_611991 = header.getOrDefault("X-Amz-Date")
  valid_611991 = validateParameter(valid_611991, JString, required = false,
                                 default = nil)
  if valid_611991 != nil:
    section.add "X-Amz-Date", valid_611991
  var valid_611992 = header.getOrDefault("X-Amz-Credential")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "X-Amz-Credential", valid_611992
  var valid_611993 = header.getOrDefault("X-Amz-Security-Token")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "X-Amz-Security-Token", valid_611993
  var valid_611994 = header.getOrDefault("X-Amz-Algorithm")
  valid_611994 = validateParameter(valid_611994, JString, required = false,
                                 default = nil)
  if valid_611994 != nil:
    section.add "X-Amz-Algorithm", valid_611994
  var valid_611995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611995 = validateParameter(valid_611995, JString, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "X-Amz-SignedHeaders", valid_611995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611997: Call_GetSkillGroup_611985; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets skill group details by skill group ARN.
  ## 
  let valid = call_611997.validator(path, query, header, formData, body)
  let scheme = call_611997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611997.url(scheme.get, call_611997.host, call_611997.base,
                         call_611997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611997, url, valid)

proc call*(call_611998: Call_GetSkillGroup_611985; body: JsonNode): Recallable =
  ## getSkillGroup
  ## Gets skill group details by skill group ARN.
  ##   body: JObject (required)
  var body_611999 = newJObject()
  if body != nil:
    body_611999 = body
  result = call_611998.call(nil, nil, nil, nil, body_611999)

var getSkillGroup* = Call_GetSkillGroup_611985(name: "getSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetSkillGroup",
    validator: validate_GetSkillGroup_611986, base: "/", url: url_GetSkillGroup_611987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBusinessReportSchedules_612000 = ref object of OpenApiRestCall_610658
proc url_ListBusinessReportSchedules_612002(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBusinessReportSchedules_612001(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the details of the schedules that a user configured. A download URL of the report associated with each schedule is returned every time this action is called. A new download URL is returned each time, and is valid for 24 hours.
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
  var valid_612003 = query.getOrDefault("MaxResults")
  valid_612003 = validateParameter(valid_612003, JString, required = false,
                                 default = nil)
  if valid_612003 != nil:
    section.add "MaxResults", valid_612003
  var valid_612004 = query.getOrDefault("NextToken")
  valid_612004 = validateParameter(valid_612004, JString, required = false,
                                 default = nil)
  if valid_612004 != nil:
    section.add "NextToken", valid_612004
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
  var valid_612005 = header.getOrDefault("X-Amz-Target")
  valid_612005 = validateParameter(valid_612005, JString, required = true, default = newJString(
      "AlexaForBusiness.ListBusinessReportSchedules"))
  if valid_612005 != nil:
    section.add "X-Amz-Target", valid_612005
  var valid_612006 = header.getOrDefault("X-Amz-Signature")
  valid_612006 = validateParameter(valid_612006, JString, required = false,
                                 default = nil)
  if valid_612006 != nil:
    section.add "X-Amz-Signature", valid_612006
  var valid_612007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612007 = validateParameter(valid_612007, JString, required = false,
                                 default = nil)
  if valid_612007 != nil:
    section.add "X-Amz-Content-Sha256", valid_612007
  var valid_612008 = header.getOrDefault("X-Amz-Date")
  valid_612008 = validateParameter(valid_612008, JString, required = false,
                                 default = nil)
  if valid_612008 != nil:
    section.add "X-Amz-Date", valid_612008
  var valid_612009 = header.getOrDefault("X-Amz-Credential")
  valid_612009 = validateParameter(valid_612009, JString, required = false,
                                 default = nil)
  if valid_612009 != nil:
    section.add "X-Amz-Credential", valid_612009
  var valid_612010 = header.getOrDefault("X-Amz-Security-Token")
  valid_612010 = validateParameter(valid_612010, JString, required = false,
                                 default = nil)
  if valid_612010 != nil:
    section.add "X-Amz-Security-Token", valid_612010
  var valid_612011 = header.getOrDefault("X-Amz-Algorithm")
  valid_612011 = validateParameter(valid_612011, JString, required = false,
                                 default = nil)
  if valid_612011 != nil:
    section.add "X-Amz-Algorithm", valid_612011
  var valid_612012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612012 = validateParameter(valid_612012, JString, required = false,
                                 default = nil)
  if valid_612012 != nil:
    section.add "X-Amz-SignedHeaders", valid_612012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612014: Call_ListBusinessReportSchedules_612000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the details of the schedules that a user configured. A download URL of the report associated with each schedule is returned every time this action is called. A new download URL is returned each time, and is valid for 24 hours.
  ## 
  let valid = call_612014.validator(path, query, header, formData, body)
  let scheme = call_612014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612014.url(scheme.get, call_612014.host, call_612014.base,
                         call_612014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612014, url, valid)

proc call*(call_612015: Call_ListBusinessReportSchedules_612000; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listBusinessReportSchedules
  ## Lists the details of the schedules that a user configured. A download URL of the report associated with each schedule is returned every time this action is called. A new download URL is returned each time, and is valid for 24 hours.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612016 = newJObject()
  var body_612017 = newJObject()
  add(query_612016, "MaxResults", newJString(MaxResults))
  add(query_612016, "NextToken", newJString(NextToken))
  if body != nil:
    body_612017 = body
  result = call_612015.call(nil, query_612016, nil, nil, body_612017)

var listBusinessReportSchedules* = Call_ListBusinessReportSchedules_612000(
    name: "listBusinessReportSchedules", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListBusinessReportSchedules",
    validator: validate_ListBusinessReportSchedules_612001, base: "/",
    url: url_ListBusinessReportSchedules_612002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConferenceProviders_612019 = ref object of OpenApiRestCall_610658
proc url_ListConferenceProviders_612021(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConferenceProviders_612020(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists conference providers under a specific AWS account.
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
  var valid_612022 = query.getOrDefault("MaxResults")
  valid_612022 = validateParameter(valid_612022, JString, required = false,
                                 default = nil)
  if valid_612022 != nil:
    section.add "MaxResults", valid_612022
  var valid_612023 = query.getOrDefault("NextToken")
  valid_612023 = validateParameter(valid_612023, JString, required = false,
                                 default = nil)
  if valid_612023 != nil:
    section.add "NextToken", valid_612023
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
  var valid_612024 = header.getOrDefault("X-Amz-Target")
  valid_612024 = validateParameter(valid_612024, JString, required = true, default = newJString(
      "AlexaForBusiness.ListConferenceProviders"))
  if valid_612024 != nil:
    section.add "X-Amz-Target", valid_612024
  var valid_612025 = header.getOrDefault("X-Amz-Signature")
  valid_612025 = validateParameter(valid_612025, JString, required = false,
                                 default = nil)
  if valid_612025 != nil:
    section.add "X-Amz-Signature", valid_612025
  var valid_612026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612026 = validateParameter(valid_612026, JString, required = false,
                                 default = nil)
  if valid_612026 != nil:
    section.add "X-Amz-Content-Sha256", valid_612026
  var valid_612027 = header.getOrDefault("X-Amz-Date")
  valid_612027 = validateParameter(valid_612027, JString, required = false,
                                 default = nil)
  if valid_612027 != nil:
    section.add "X-Amz-Date", valid_612027
  var valid_612028 = header.getOrDefault("X-Amz-Credential")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "X-Amz-Credential", valid_612028
  var valid_612029 = header.getOrDefault("X-Amz-Security-Token")
  valid_612029 = validateParameter(valid_612029, JString, required = false,
                                 default = nil)
  if valid_612029 != nil:
    section.add "X-Amz-Security-Token", valid_612029
  var valid_612030 = header.getOrDefault("X-Amz-Algorithm")
  valid_612030 = validateParameter(valid_612030, JString, required = false,
                                 default = nil)
  if valid_612030 != nil:
    section.add "X-Amz-Algorithm", valid_612030
  var valid_612031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612031 = validateParameter(valid_612031, JString, required = false,
                                 default = nil)
  if valid_612031 != nil:
    section.add "X-Amz-SignedHeaders", valid_612031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612033: Call_ListConferenceProviders_612019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists conference providers under a specific AWS account.
  ## 
  let valid = call_612033.validator(path, query, header, formData, body)
  let scheme = call_612033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612033.url(scheme.get, call_612033.host, call_612033.base,
                         call_612033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612033, url, valid)

proc call*(call_612034: Call_ListConferenceProviders_612019; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listConferenceProviders
  ## Lists conference providers under a specific AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612035 = newJObject()
  var body_612036 = newJObject()
  add(query_612035, "MaxResults", newJString(MaxResults))
  add(query_612035, "NextToken", newJString(NextToken))
  if body != nil:
    body_612036 = body
  result = call_612034.call(nil, query_612035, nil, nil, body_612036)

var listConferenceProviders* = Call_ListConferenceProviders_612019(
    name: "listConferenceProviders", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListConferenceProviders",
    validator: validate_ListConferenceProviders_612020, base: "/",
    url: url_ListConferenceProviders_612021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceEvents_612037 = ref object of OpenApiRestCall_610658
proc url_ListDeviceEvents_612039(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeviceEvents_612038(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists the device event history, including device connection status, for up to 30 days.
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
  var valid_612040 = query.getOrDefault("MaxResults")
  valid_612040 = validateParameter(valid_612040, JString, required = false,
                                 default = nil)
  if valid_612040 != nil:
    section.add "MaxResults", valid_612040
  var valid_612041 = query.getOrDefault("NextToken")
  valid_612041 = validateParameter(valid_612041, JString, required = false,
                                 default = nil)
  if valid_612041 != nil:
    section.add "NextToken", valid_612041
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
  var valid_612042 = header.getOrDefault("X-Amz-Target")
  valid_612042 = validateParameter(valid_612042, JString, required = true, default = newJString(
      "AlexaForBusiness.ListDeviceEvents"))
  if valid_612042 != nil:
    section.add "X-Amz-Target", valid_612042
  var valid_612043 = header.getOrDefault("X-Amz-Signature")
  valid_612043 = validateParameter(valid_612043, JString, required = false,
                                 default = nil)
  if valid_612043 != nil:
    section.add "X-Amz-Signature", valid_612043
  var valid_612044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612044 = validateParameter(valid_612044, JString, required = false,
                                 default = nil)
  if valid_612044 != nil:
    section.add "X-Amz-Content-Sha256", valid_612044
  var valid_612045 = header.getOrDefault("X-Amz-Date")
  valid_612045 = validateParameter(valid_612045, JString, required = false,
                                 default = nil)
  if valid_612045 != nil:
    section.add "X-Amz-Date", valid_612045
  var valid_612046 = header.getOrDefault("X-Amz-Credential")
  valid_612046 = validateParameter(valid_612046, JString, required = false,
                                 default = nil)
  if valid_612046 != nil:
    section.add "X-Amz-Credential", valid_612046
  var valid_612047 = header.getOrDefault("X-Amz-Security-Token")
  valid_612047 = validateParameter(valid_612047, JString, required = false,
                                 default = nil)
  if valid_612047 != nil:
    section.add "X-Amz-Security-Token", valid_612047
  var valid_612048 = header.getOrDefault("X-Amz-Algorithm")
  valid_612048 = validateParameter(valid_612048, JString, required = false,
                                 default = nil)
  if valid_612048 != nil:
    section.add "X-Amz-Algorithm", valid_612048
  var valid_612049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612049 = validateParameter(valid_612049, JString, required = false,
                                 default = nil)
  if valid_612049 != nil:
    section.add "X-Amz-SignedHeaders", valid_612049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612051: Call_ListDeviceEvents_612037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the device event history, including device connection status, for up to 30 days.
  ## 
  let valid = call_612051.validator(path, query, header, formData, body)
  let scheme = call_612051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612051.url(scheme.get, call_612051.host, call_612051.base,
                         call_612051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612051, url, valid)

proc call*(call_612052: Call_ListDeviceEvents_612037; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDeviceEvents
  ## Lists the device event history, including device connection status, for up to 30 days.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612053 = newJObject()
  var body_612054 = newJObject()
  add(query_612053, "MaxResults", newJString(MaxResults))
  add(query_612053, "NextToken", newJString(NextToken))
  if body != nil:
    body_612054 = body
  result = call_612052.call(nil, query_612053, nil, nil, body_612054)

var listDeviceEvents* = Call_ListDeviceEvents_612037(name: "listDeviceEvents",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListDeviceEvents",
    validator: validate_ListDeviceEvents_612038, base: "/",
    url: url_ListDeviceEvents_612039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGatewayGroups_612055 = ref object of OpenApiRestCall_610658
proc url_ListGatewayGroups_612057(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGatewayGroups_612056(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
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
  var valid_612058 = query.getOrDefault("MaxResults")
  valid_612058 = validateParameter(valid_612058, JString, required = false,
                                 default = nil)
  if valid_612058 != nil:
    section.add "MaxResults", valid_612058
  var valid_612059 = query.getOrDefault("NextToken")
  valid_612059 = validateParameter(valid_612059, JString, required = false,
                                 default = nil)
  if valid_612059 != nil:
    section.add "NextToken", valid_612059
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
  var valid_612060 = header.getOrDefault("X-Amz-Target")
  valid_612060 = validateParameter(valid_612060, JString, required = true, default = newJString(
      "AlexaForBusiness.ListGatewayGroups"))
  if valid_612060 != nil:
    section.add "X-Amz-Target", valid_612060
  var valid_612061 = header.getOrDefault("X-Amz-Signature")
  valid_612061 = validateParameter(valid_612061, JString, required = false,
                                 default = nil)
  if valid_612061 != nil:
    section.add "X-Amz-Signature", valid_612061
  var valid_612062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612062 = validateParameter(valid_612062, JString, required = false,
                                 default = nil)
  if valid_612062 != nil:
    section.add "X-Amz-Content-Sha256", valid_612062
  var valid_612063 = header.getOrDefault("X-Amz-Date")
  valid_612063 = validateParameter(valid_612063, JString, required = false,
                                 default = nil)
  if valid_612063 != nil:
    section.add "X-Amz-Date", valid_612063
  var valid_612064 = header.getOrDefault("X-Amz-Credential")
  valid_612064 = validateParameter(valid_612064, JString, required = false,
                                 default = nil)
  if valid_612064 != nil:
    section.add "X-Amz-Credential", valid_612064
  var valid_612065 = header.getOrDefault("X-Amz-Security-Token")
  valid_612065 = validateParameter(valid_612065, JString, required = false,
                                 default = nil)
  if valid_612065 != nil:
    section.add "X-Amz-Security-Token", valid_612065
  var valid_612066 = header.getOrDefault("X-Amz-Algorithm")
  valid_612066 = validateParameter(valid_612066, JString, required = false,
                                 default = nil)
  if valid_612066 != nil:
    section.add "X-Amz-Algorithm", valid_612066
  var valid_612067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612067 = validateParameter(valid_612067, JString, required = false,
                                 default = nil)
  if valid_612067 != nil:
    section.add "X-Amz-SignedHeaders", valid_612067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612069: Call_ListGatewayGroups_612055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
  ## 
  let valid = call_612069.validator(path, query, header, formData, body)
  let scheme = call_612069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612069.url(scheme.get, call_612069.host, call_612069.base,
                         call_612069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612069, url, valid)

proc call*(call_612070: Call_ListGatewayGroups_612055; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGatewayGroups
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612071 = newJObject()
  var body_612072 = newJObject()
  add(query_612071, "MaxResults", newJString(MaxResults))
  add(query_612071, "NextToken", newJString(NextToken))
  if body != nil:
    body_612072 = body
  result = call_612070.call(nil, query_612071, nil, nil, body_612072)

var listGatewayGroups* = Call_ListGatewayGroups_612055(name: "listGatewayGroups",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListGatewayGroups",
    validator: validate_ListGatewayGroups_612056, base: "/",
    url: url_ListGatewayGroups_612057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGateways_612073 = ref object of OpenApiRestCall_610658
proc url_ListGateways_612075(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGateways_612074(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
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
  var valid_612076 = query.getOrDefault("MaxResults")
  valid_612076 = validateParameter(valid_612076, JString, required = false,
                                 default = nil)
  if valid_612076 != nil:
    section.add "MaxResults", valid_612076
  var valid_612077 = query.getOrDefault("NextToken")
  valid_612077 = validateParameter(valid_612077, JString, required = false,
                                 default = nil)
  if valid_612077 != nil:
    section.add "NextToken", valid_612077
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
  var valid_612078 = header.getOrDefault("X-Amz-Target")
  valid_612078 = validateParameter(valid_612078, JString, required = true, default = newJString(
      "AlexaForBusiness.ListGateways"))
  if valid_612078 != nil:
    section.add "X-Amz-Target", valid_612078
  var valid_612079 = header.getOrDefault("X-Amz-Signature")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "X-Amz-Signature", valid_612079
  var valid_612080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612080 = validateParameter(valid_612080, JString, required = false,
                                 default = nil)
  if valid_612080 != nil:
    section.add "X-Amz-Content-Sha256", valid_612080
  var valid_612081 = header.getOrDefault("X-Amz-Date")
  valid_612081 = validateParameter(valid_612081, JString, required = false,
                                 default = nil)
  if valid_612081 != nil:
    section.add "X-Amz-Date", valid_612081
  var valid_612082 = header.getOrDefault("X-Amz-Credential")
  valid_612082 = validateParameter(valid_612082, JString, required = false,
                                 default = nil)
  if valid_612082 != nil:
    section.add "X-Amz-Credential", valid_612082
  var valid_612083 = header.getOrDefault("X-Amz-Security-Token")
  valid_612083 = validateParameter(valid_612083, JString, required = false,
                                 default = nil)
  if valid_612083 != nil:
    section.add "X-Amz-Security-Token", valid_612083
  var valid_612084 = header.getOrDefault("X-Amz-Algorithm")
  valid_612084 = validateParameter(valid_612084, JString, required = false,
                                 default = nil)
  if valid_612084 != nil:
    section.add "X-Amz-Algorithm", valid_612084
  var valid_612085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612085 = validateParameter(valid_612085, JString, required = false,
                                 default = nil)
  if valid_612085 != nil:
    section.add "X-Amz-SignedHeaders", valid_612085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612087: Call_ListGateways_612073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
  ## 
  let valid = call_612087.validator(path, query, header, formData, body)
  let scheme = call_612087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612087.url(scheme.get, call_612087.host, call_612087.base,
                         call_612087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612087, url, valid)

proc call*(call_612088: Call_ListGateways_612073; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGateways
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612089 = newJObject()
  var body_612090 = newJObject()
  add(query_612089, "MaxResults", newJString(MaxResults))
  add(query_612089, "NextToken", newJString(NextToken))
  if body != nil:
    body_612090 = body
  result = call_612088.call(nil, query_612089, nil, nil, body_612090)

var listGateways* = Call_ListGateways_612073(name: "listGateways",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListGateways",
    validator: validate_ListGateways_612074, base: "/", url: url_ListGateways_612075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkills_612091 = ref object of OpenApiRestCall_610658
proc url_ListSkills_612093(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSkills_612092(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all enabled skills in a specific skill group.
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
  var valid_612094 = query.getOrDefault("MaxResults")
  valid_612094 = validateParameter(valid_612094, JString, required = false,
                                 default = nil)
  if valid_612094 != nil:
    section.add "MaxResults", valid_612094
  var valid_612095 = query.getOrDefault("NextToken")
  valid_612095 = validateParameter(valid_612095, JString, required = false,
                                 default = nil)
  if valid_612095 != nil:
    section.add "NextToken", valid_612095
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
  var valid_612096 = header.getOrDefault("X-Amz-Target")
  valid_612096 = validateParameter(valid_612096, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkills"))
  if valid_612096 != nil:
    section.add "X-Amz-Target", valid_612096
  var valid_612097 = header.getOrDefault("X-Amz-Signature")
  valid_612097 = validateParameter(valid_612097, JString, required = false,
                                 default = nil)
  if valid_612097 != nil:
    section.add "X-Amz-Signature", valid_612097
  var valid_612098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612098 = validateParameter(valid_612098, JString, required = false,
                                 default = nil)
  if valid_612098 != nil:
    section.add "X-Amz-Content-Sha256", valid_612098
  var valid_612099 = header.getOrDefault("X-Amz-Date")
  valid_612099 = validateParameter(valid_612099, JString, required = false,
                                 default = nil)
  if valid_612099 != nil:
    section.add "X-Amz-Date", valid_612099
  var valid_612100 = header.getOrDefault("X-Amz-Credential")
  valid_612100 = validateParameter(valid_612100, JString, required = false,
                                 default = nil)
  if valid_612100 != nil:
    section.add "X-Amz-Credential", valid_612100
  var valid_612101 = header.getOrDefault("X-Amz-Security-Token")
  valid_612101 = validateParameter(valid_612101, JString, required = false,
                                 default = nil)
  if valid_612101 != nil:
    section.add "X-Amz-Security-Token", valid_612101
  var valid_612102 = header.getOrDefault("X-Amz-Algorithm")
  valid_612102 = validateParameter(valid_612102, JString, required = false,
                                 default = nil)
  if valid_612102 != nil:
    section.add "X-Amz-Algorithm", valid_612102
  var valid_612103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612103 = validateParameter(valid_612103, JString, required = false,
                                 default = nil)
  if valid_612103 != nil:
    section.add "X-Amz-SignedHeaders", valid_612103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612105: Call_ListSkills_612091; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all enabled skills in a specific skill group.
  ## 
  let valid = call_612105.validator(path, query, header, formData, body)
  let scheme = call_612105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612105.url(scheme.get, call_612105.host, call_612105.base,
                         call_612105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612105, url, valid)

proc call*(call_612106: Call_ListSkills_612091; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSkills
  ## Lists all enabled skills in a specific skill group.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612107 = newJObject()
  var body_612108 = newJObject()
  add(query_612107, "MaxResults", newJString(MaxResults))
  add(query_612107, "NextToken", newJString(NextToken))
  if body != nil:
    body_612108 = body
  result = call_612106.call(nil, query_612107, nil, nil, body_612108)

var listSkills* = Call_ListSkills_612091(name: "listSkills",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ListSkills",
                                      validator: validate_ListSkills_612092,
                                      base: "/", url: url_ListSkills_612093,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkillsStoreCategories_612109 = ref object of OpenApiRestCall_610658
proc url_ListSkillsStoreCategories_612111(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSkillsStoreCategories_612110(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all categories in the Alexa skill store.
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
  var valid_612112 = query.getOrDefault("MaxResults")
  valid_612112 = validateParameter(valid_612112, JString, required = false,
                                 default = nil)
  if valid_612112 != nil:
    section.add "MaxResults", valid_612112
  var valid_612113 = query.getOrDefault("NextToken")
  valid_612113 = validateParameter(valid_612113, JString, required = false,
                                 default = nil)
  if valid_612113 != nil:
    section.add "NextToken", valid_612113
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
  var valid_612114 = header.getOrDefault("X-Amz-Target")
  valid_612114 = validateParameter(valid_612114, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkillsStoreCategories"))
  if valid_612114 != nil:
    section.add "X-Amz-Target", valid_612114
  var valid_612115 = header.getOrDefault("X-Amz-Signature")
  valid_612115 = validateParameter(valid_612115, JString, required = false,
                                 default = nil)
  if valid_612115 != nil:
    section.add "X-Amz-Signature", valid_612115
  var valid_612116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612116 = validateParameter(valid_612116, JString, required = false,
                                 default = nil)
  if valid_612116 != nil:
    section.add "X-Amz-Content-Sha256", valid_612116
  var valid_612117 = header.getOrDefault("X-Amz-Date")
  valid_612117 = validateParameter(valid_612117, JString, required = false,
                                 default = nil)
  if valid_612117 != nil:
    section.add "X-Amz-Date", valid_612117
  var valid_612118 = header.getOrDefault("X-Amz-Credential")
  valid_612118 = validateParameter(valid_612118, JString, required = false,
                                 default = nil)
  if valid_612118 != nil:
    section.add "X-Amz-Credential", valid_612118
  var valid_612119 = header.getOrDefault("X-Amz-Security-Token")
  valid_612119 = validateParameter(valid_612119, JString, required = false,
                                 default = nil)
  if valid_612119 != nil:
    section.add "X-Amz-Security-Token", valid_612119
  var valid_612120 = header.getOrDefault("X-Amz-Algorithm")
  valid_612120 = validateParameter(valid_612120, JString, required = false,
                                 default = nil)
  if valid_612120 != nil:
    section.add "X-Amz-Algorithm", valid_612120
  var valid_612121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612121 = validateParameter(valid_612121, JString, required = false,
                                 default = nil)
  if valid_612121 != nil:
    section.add "X-Amz-SignedHeaders", valid_612121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612123: Call_ListSkillsStoreCategories_612109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all categories in the Alexa skill store.
  ## 
  let valid = call_612123.validator(path, query, header, formData, body)
  let scheme = call_612123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612123.url(scheme.get, call_612123.host, call_612123.base,
                         call_612123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612123, url, valid)

proc call*(call_612124: Call_ListSkillsStoreCategories_612109; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSkillsStoreCategories
  ## Lists all categories in the Alexa skill store.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612125 = newJObject()
  var body_612126 = newJObject()
  add(query_612125, "MaxResults", newJString(MaxResults))
  add(query_612125, "NextToken", newJString(NextToken))
  if body != nil:
    body_612126 = body
  result = call_612124.call(nil, query_612125, nil, nil, body_612126)

var listSkillsStoreCategories* = Call_ListSkillsStoreCategories_612109(
    name: "listSkillsStoreCategories", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSkillsStoreCategories",
    validator: validate_ListSkillsStoreCategories_612110, base: "/",
    url: url_ListSkillsStoreCategories_612111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkillsStoreSkillsByCategory_612127 = ref object of OpenApiRestCall_610658
proc url_ListSkillsStoreSkillsByCategory_612129(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSkillsStoreSkillsByCategory_612128(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all skills in the Alexa skill store by category.
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
  var valid_612130 = query.getOrDefault("MaxResults")
  valid_612130 = validateParameter(valid_612130, JString, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "MaxResults", valid_612130
  var valid_612131 = query.getOrDefault("NextToken")
  valid_612131 = validateParameter(valid_612131, JString, required = false,
                                 default = nil)
  if valid_612131 != nil:
    section.add "NextToken", valid_612131
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
  var valid_612132 = header.getOrDefault("X-Amz-Target")
  valid_612132 = validateParameter(valid_612132, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkillsStoreSkillsByCategory"))
  if valid_612132 != nil:
    section.add "X-Amz-Target", valid_612132
  var valid_612133 = header.getOrDefault("X-Amz-Signature")
  valid_612133 = validateParameter(valid_612133, JString, required = false,
                                 default = nil)
  if valid_612133 != nil:
    section.add "X-Amz-Signature", valid_612133
  var valid_612134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612134 = validateParameter(valid_612134, JString, required = false,
                                 default = nil)
  if valid_612134 != nil:
    section.add "X-Amz-Content-Sha256", valid_612134
  var valid_612135 = header.getOrDefault("X-Amz-Date")
  valid_612135 = validateParameter(valid_612135, JString, required = false,
                                 default = nil)
  if valid_612135 != nil:
    section.add "X-Amz-Date", valid_612135
  var valid_612136 = header.getOrDefault("X-Amz-Credential")
  valid_612136 = validateParameter(valid_612136, JString, required = false,
                                 default = nil)
  if valid_612136 != nil:
    section.add "X-Amz-Credential", valid_612136
  var valid_612137 = header.getOrDefault("X-Amz-Security-Token")
  valid_612137 = validateParameter(valid_612137, JString, required = false,
                                 default = nil)
  if valid_612137 != nil:
    section.add "X-Amz-Security-Token", valid_612137
  var valid_612138 = header.getOrDefault("X-Amz-Algorithm")
  valid_612138 = validateParameter(valid_612138, JString, required = false,
                                 default = nil)
  if valid_612138 != nil:
    section.add "X-Amz-Algorithm", valid_612138
  var valid_612139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612139 = validateParameter(valid_612139, JString, required = false,
                                 default = nil)
  if valid_612139 != nil:
    section.add "X-Amz-SignedHeaders", valid_612139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612141: Call_ListSkillsStoreSkillsByCategory_612127;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all skills in the Alexa skill store by category.
  ## 
  let valid = call_612141.validator(path, query, header, formData, body)
  let scheme = call_612141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612141.url(scheme.get, call_612141.host, call_612141.base,
                         call_612141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612141, url, valid)

proc call*(call_612142: Call_ListSkillsStoreSkillsByCategory_612127;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSkillsStoreSkillsByCategory
  ## Lists all skills in the Alexa skill store by category.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612143 = newJObject()
  var body_612144 = newJObject()
  add(query_612143, "MaxResults", newJString(MaxResults))
  add(query_612143, "NextToken", newJString(NextToken))
  if body != nil:
    body_612144 = body
  result = call_612142.call(nil, query_612143, nil, nil, body_612144)

var listSkillsStoreSkillsByCategory* = Call_ListSkillsStoreSkillsByCategory_612127(
    name: "listSkillsStoreSkillsByCategory", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSkillsStoreSkillsByCategory",
    validator: validate_ListSkillsStoreSkillsByCategory_612128, base: "/",
    url: url_ListSkillsStoreSkillsByCategory_612129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSmartHomeAppliances_612145 = ref object of OpenApiRestCall_610658
proc url_ListSmartHomeAppliances_612147(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSmartHomeAppliances_612146(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all of the smart home appliances associated with a room.
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
  var valid_612148 = query.getOrDefault("MaxResults")
  valid_612148 = validateParameter(valid_612148, JString, required = false,
                                 default = nil)
  if valid_612148 != nil:
    section.add "MaxResults", valid_612148
  var valid_612149 = query.getOrDefault("NextToken")
  valid_612149 = validateParameter(valid_612149, JString, required = false,
                                 default = nil)
  if valid_612149 != nil:
    section.add "NextToken", valid_612149
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
  var valid_612150 = header.getOrDefault("X-Amz-Target")
  valid_612150 = validateParameter(valid_612150, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSmartHomeAppliances"))
  if valid_612150 != nil:
    section.add "X-Amz-Target", valid_612150
  var valid_612151 = header.getOrDefault("X-Amz-Signature")
  valid_612151 = validateParameter(valid_612151, JString, required = false,
                                 default = nil)
  if valid_612151 != nil:
    section.add "X-Amz-Signature", valid_612151
  var valid_612152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612152 = validateParameter(valid_612152, JString, required = false,
                                 default = nil)
  if valid_612152 != nil:
    section.add "X-Amz-Content-Sha256", valid_612152
  var valid_612153 = header.getOrDefault("X-Amz-Date")
  valid_612153 = validateParameter(valid_612153, JString, required = false,
                                 default = nil)
  if valid_612153 != nil:
    section.add "X-Amz-Date", valid_612153
  var valid_612154 = header.getOrDefault("X-Amz-Credential")
  valid_612154 = validateParameter(valid_612154, JString, required = false,
                                 default = nil)
  if valid_612154 != nil:
    section.add "X-Amz-Credential", valid_612154
  var valid_612155 = header.getOrDefault("X-Amz-Security-Token")
  valid_612155 = validateParameter(valid_612155, JString, required = false,
                                 default = nil)
  if valid_612155 != nil:
    section.add "X-Amz-Security-Token", valid_612155
  var valid_612156 = header.getOrDefault("X-Amz-Algorithm")
  valid_612156 = validateParameter(valid_612156, JString, required = false,
                                 default = nil)
  if valid_612156 != nil:
    section.add "X-Amz-Algorithm", valid_612156
  var valid_612157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612157 = validateParameter(valid_612157, JString, required = false,
                                 default = nil)
  if valid_612157 != nil:
    section.add "X-Amz-SignedHeaders", valid_612157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612159: Call_ListSmartHomeAppliances_612145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all of the smart home appliances associated with a room.
  ## 
  let valid = call_612159.validator(path, query, header, formData, body)
  let scheme = call_612159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612159.url(scheme.get, call_612159.host, call_612159.base,
                         call_612159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612159, url, valid)

proc call*(call_612160: Call_ListSmartHomeAppliances_612145; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSmartHomeAppliances
  ## Lists all of the smart home appliances associated with a room.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612161 = newJObject()
  var body_612162 = newJObject()
  add(query_612161, "MaxResults", newJString(MaxResults))
  add(query_612161, "NextToken", newJString(NextToken))
  if body != nil:
    body_612162 = body
  result = call_612160.call(nil, query_612161, nil, nil, body_612162)

var listSmartHomeAppliances* = Call_ListSmartHomeAppliances_612145(
    name: "listSmartHomeAppliances", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSmartHomeAppliances",
    validator: validate_ListSmartHomeAppliances_612146, base: "/",
    url: url_ListSmartHomeAppliances_612147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_612163 = ref object of OpenApiRestCall_610658
proc url_ListTags_612165(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTags_612164(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all tags for the specified resource.
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
  var valid_612166 = query.getOrDefault("MaxResults")
  valid_612166 = validateParameter(valid_612166, JString, required = false,
                                 default = nil)
  if valid_612166 != nil:
    section.add "MaxResults", valid_612166
  var valid_612167 = query.getOrDefault("NextToken")
  valid_612167 = validateParameter(valid_612167, JString, required = false,
                                 default = nil)
  if valid_612167 != nil:
    section.add "NextToken", valid_612167
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
  var valid_612168 = header.getOrDefault("X-Amz-Target")
  valid_612168 = validateParameter(valid_612168, JString, required = true, default = newJString(
      "AlexaForBusiness.ListTags"))
  if valid_612168 != nil:
    section.add "X-Amz-Target", valid_612168
  var valid_612169 = header.getOrDefault("X-Amz-Signature")
  valid_612169 = validateParameter(valid_612169, JString, required = false,
                                 default = nil)
  if valid_612169 != nil:
    section.add "X-Amz-Signature", valid_612169
  var valid_612170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612170 = validateParameter(valid_612170, JString, required = false,
                                 default = nil)
  if valid_612170 != nil:
    section.add "X-Amz-Content-Sha256", valid_612170
  var valid_612171 = header.getOrDefault("X-Amz-Date")
  valid_612171 = validateParameter(valid_612171, JString, required = false,
                                 default = nil)
  if valid_612171 != nil:
    section.add "X-Amz-Date", valid_612171
  var valid_612172 = header.getOrDefault("X-Amz-Credential")
  valid_612172 = validateParameter(valid_612172, JString, required = false,
                                 default = nil)
  if valid_612172 != nil:
    section.add "X-Amz-Credential", valid_612172
  var valid_612173 = header.getOrDefault("X-Amz-Security-Token")
  valid_612173 = validateParameter(valid_612173, JString, required = false,
                                 default = nil)
  if valid_612173 != nil:
    section.add "X-Amz-Security-Token", valid_612173
  var valid_612174 = header.getOrDefault("X-Amz-Algorithm")
  valid_612174 = validateParameter(valid_612174, JString, required = false,
                                 default = nil)
  if valid_612174 != nil:
    section.add "X-Amz-Algorithm", valid_612174
  var valid_612175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612175 = validateParameter(valid_612175, JString, required = false,
                                 default = nil)
  if valid_612175 != nil:
    section.add "X-Amz-SignedHeaders", valid_612175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612177: Call_ListTags_612163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags for the specified resource.
  ## 
  let valid = call_612177.validator(path, query, header, formData, body)
  let scheme = call_612177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612177.url(scheme.get, call_612177.host, call_612177.base,
                         call_612177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612177, url, valid)

proc call*(call_612178: Call_ListTags_612163; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTags
  ## Lists all tags for the specified resource.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612179 = newJObject()
  var body_612180 = newJObject()
  add(query_612179, "MaxResults", newJString(MaxResults))
  add(query_612179, "NextToken", newJString(NextToken))
  if body != nil:
    body_612180 = body
  result = call_612178.call(nil, query_612179, nil, nil, body_612180)

var listTags* = Call_ListTags_612163(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ListTags",
                                  validator: validate_ListTags_612164, base: "/",
                                  url: url_ListTags_612165,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConferencePreference_612181 = ref object of OpenApiRestCall_610658
proc url_PutConferencePreference_612183(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutConferencePreference_612182(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612184 = header.getOrDefault("X-Amz-Target")
  valid_612184 = validateParameter(valid_612184, JString, required = true, default = newJString(
      "AlexaForBusiness.PutConferencePreference"))
  if valid_612184 != nil:
    section.add "X-Amz-Target", valid_612184
  var valid_612185 = header.getOrDefault("X-Amz-Signature")
  valid_612185 = validateParameter(valid_612185, JString, required = false,
                                 default = nil)
  if valid_612185 != nil:
    section.add "X-Amz-Signature", valid_612185
  var valid_612186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612186 = validateParameter(valid_612186, JString, required = false,
                                 default = nil)
  if valid_612186 != nil:
    section.add "X-Amz-Content-Sha256", valid_612186
  var valid_612187 = header.getOrDefault("X-Amz-Date")
  valid_612187 = validateParameter(valid_612187, JString, required = false,
                                 default = nil)
  if valid_612187 != nil:
    section.add "X-Amz-Date", valid_612187
  var valid_612188 = header.getOrDefault("X-Amz-Credential")
  valid_612188 = validateParameter(valid_612188, JString, required = false,
                                 default = nil)
  if valid_612188 != nil:
    section.add "X-Amz-Credential", valid_612188
  var valid_612189 = header.getOrDefault("X-Amz-Security-Token")
  valid_612189 = validateParameter(valid_612189, JString, required = false,
                                 default = nil)
  if valid_612189 != nil:
    section.add "X-Amz-Security-Token", valid_612189
  var valid_612190 = header.getOrDefault("X-Amz-Algorithm")
  valid_612190 = validateParameter(valid_612190, JString, required = false,
                                 default = nil)
  if valid_612190 != nil:
    section.add "X-Amz-Algorithm", valid_612190
  var valid_612191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612191 = validateParameter(valid_612191, JString, required = false,
                                 default = nil)
  if valid_612191 != nil:
    section.add "X-Amz-SignedHeaders", valid_612191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612193: Call_PutConferencePreference_612181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the conference preferences on a specific conference provider at the account level.
  ## 
  let valid = call_612193.validator(path, query, header, formData, body)
  let scheme = call_612193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612193.url(scheme.get, call_612193.host, call_612193.base,
                         call_612193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612193, url, valid)

proc call*(call_612194: Call_PutConferencePreference_612181; body: JsonNode): Recallable =
  ## putConferencePreference
  ## Sets the conference preferences on a specific conference provider at the account level.
  ##   body: JObject (required)
  var body_612195 = newJObject()
  if body != nil:
    body_612195 = body
  result = call_612194.call(nil, nil, nil, nil, body_612195)

var putConferencePreference* = Call_PutConferencePreference_612181(
    name: "putConferencePreference", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutConferencePreference",
    validator: validate_PutConferencePreference_612182, base: "/",
    url: url_PutConferencePreference_612183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInvitationConfiguration_612196 = ref object of OpenApiRestCall_610658
proc url_PutInvitationConfiguration_612198(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutInvitationConfiguration_612197(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612199 = header.getOrDefault("X-Amz-Target")
  valid_612199 = validateParameter(valid_612199, JString, required = true, default = newJString(
      "AlexaForBusiness.PutInvitationConfiguration"))
  if valid_612199 != nil:
    section.add "X-Amz-Target", valid_612199
  var valid_612200 = header.getOrDefault("X-Amz-Signature")
  valid_612200 = validateParameter(valid_612200, JString, required = false,
                                 default = nil)
  if valid_612200 != nil:
    section.add "X-Amz-Signature", valid_612200
  var valid_612201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612201 = validateParameter(valid_612201, JString, required = false,
                                 default = nil)
  if valid_612201 != nil:
    section.add "X-Amz-Content-Sha256", valid_612201
  var valid_612202 = header.getOrDefault("X-Amz-Date")
  valid_612202 = validateParameter(valid_612202, JString, required = false,
                                 default = nil)
  if valid_612202 != nil:
    section.add "X-Amz-Date", valid_612202
  var valid_612203 = header.getOrDefault("X-Amz-Credential")
  valid_612203 = validateParameter(valid_612203, JString, required = false,
                                 default = nil)
  if valid_612203 != nil:
    section.add "X-Amz-Credential", valid_612203
  var valid_612204 = header.getOrDefault("X-Amz-Security-Token")
  valid_612204 = validateParameter(valid_612204, JString, required = false,
                                 default = nil)
  if valid_612204 != nil:
    section.add "X-Amz-Security-Token", valid_612204
  var valid_612205 = header.getOrDefault("X-Amz-Algorithm")
  valid_612205 = validateParameter(valid_612205, JString, required = false,
                                 default = nil)
  if valid_612205 != nil:
    section.add "X-Amz-Algorithm", valid_612205
  var valid_612206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612206 = validateParameter(valid_612206, JString, required = false,
                                 default = nil)
  if valid_612206 != nil:
    section.add "X-Amz-SignedHeaders", valid_612206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612208: Call_PutInvitationConfiguration_612196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the email template for the user enrollment invitation with the specified attributes.
  ## 
  let valid = call_612208.validator(path, query, header, formData, body)
  let scheme = call_612208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612208.url(scheme.get, call_612208.host, call_612208.base,
                         call_612208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612208, url, valid)

proc call*(call_612209: Call_PutInvitationConfiguration_612196; body: JsonNode): Recallable =
  ## putInvitationConfiguration
  ## Configures the email template for the user enrollment invitation with the specified attributes.
  ##   body: JObject (required)
  var body_612210 = newJObject()
  if body != nil:
    body_612210 = body
  result = call_612209.call(nil, nil, nil, nil, body_612210)

var putInvitationConfiguration* = Call_PutInvitationConfiguration_612196(
    name: "putInvitationConfiguration", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutInvitationConfiguration",
    validator: validate_PutInvitationConfiguration_612197, base: "/",
    url: url_PutInvitationConfiguration_612198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRoomSkillParameter_612211 = ref object of OpenApiRestCall_610658
proc url_PutRoomSkillParameter_612213(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRoomSkillParameter_612212(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612214 = header.getOrDefault("X-Amz-Target")
  valid_612214 = validateParameter(valid_612214, JString, required = true, default = newJString(
      "AlexaForBusiness.PutRoomSkillParameter"))
  if valid_612214 != nil:
    section.add "X-Amz-Target", valid_612214
  var valid_612215 = header.getOrDefault("X-Amz-Signature")
  valid_612215 = validateParameter(valid_612215, JString, required = false,
                                 default = nil)
  if valid_612215 != nil:
    section.add "X-Amz-Signature", valid_612215
  var valid_612216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612216 = validateParameter(valid_612216, JString, required = false,
                                 default = nil)
  if valid_612216 != nil:
    section.add "X-Amz-Content-Sha256", valid_612216
  var valid_612217 = header.getOrDefault("X-Amz-Date")
  valid_612217 = validateParameter(valid_612217, JString, required = false,
                                 default = nil)
  if valid_612217 != nil:
    section.add "X-Amz-Date", valid_612217
  var valid_612218 = header.getOrDefault("X-Amz-Credential")
  valid_612218 = validateParameter(valid_612218, JString, required = false,
                                 default = nil)
  if valid_612218 != nil:
    section.add "X-Amz-Credential", valid_612218
  var valid_612219 = header.getOrDefault("X-Amz-Security-Token")
  valid_612219 = validateParameter(valid_612219, JString, required = false,
                                 default = nil)
  if valid_612219 != nil:
    section.add "X-Amz-Security-Token", valid_612219
  var valid_612220 = header.getOrDefault("X-Amz-Algorithm")
  valid_612220 = validateParameter(valid_612220, JString, required = false,
                                 default = nil)
  if valid_612220 != nil:
    section.add "X-Amz-Algorithm", valid_612220
  var valid_612221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612221 = validateParameter(valid_612221, JString, required = false,
                                 default = nil)
  if valid_612221 != nil:
    section.add "X-Amz-SignedHeaders", valid_612221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612223: Call_PutRoomSkillParameter_612211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room skill parameter details by room, skill, and parameter key ID. Not all skills have a room skill parameter.
  ## 
  let valid = call_612223.validator(path, query, header, formData, body)
  let scheme = call_612223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612223.url(scheme.get, call_612223.host, call_612223.base,
                         call_612223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612223, url, valid)

proc call*(call_612224: Call_PutRoomSkillParameter_612211; body: JsonNode): Recallable =
  ## putRoomSkillParameter
  ## Updates room skill parameter details by room, skill, and parameter key ID. Not all skills have a room skill parameter.
  ##   body: JObject (required)
  var body_612225 = newJObject()
  if body != nil:
    body_612225 = body
  result = call_612224.call(nil, nil, nil, nil, body_612225)

var putRoomSkillParameter* = Call_PutRoomSkillParameter_612211(
    name: "putRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutRoomSkillParameter",
    validator: validate_PutRoomSkillParameter_612212, base: "/",
    url: url_PutRoomSkillParameter_612213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSkillAuthorization_612226 = ref object of OpenApiRestCall_610658
proc url_PutSkillAuthorization_612228(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutSkillAuthorization_612227(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612229 = header.getOrDefault("X-Amz-Target")
  valid_612229 = validateParameter(valid_612229, JString, required = true, default = newJString(
      "AlexaForBusiness.PutSkillAuthorization"))
  if valid_612229 != nil:
    section.add "X-Amz-Target", valid_612229
  var valid_612230 = header.getOrDefault("X-Amz-Signature")
  valid_612230 = validateParameter(valid_612230, JString, required = false,
                                 default = nil)
  if valid_612230 != nil:
    section.add "X-Amz-Signature", valid_612230
  var valid_612231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612231 = validateParameter(valid_612231, JString, required = false,
                                 default = nil)
  if valid_612231 != nil:
    section.add "X-Amz-Content-Sha256", valid_612231
  var valid_612232 = header.getOrDefault("X-Amz-Date")
  valid_612232 = validateParameter(valid_612232, JString, required = false,
                                 default = nil)
  if valid_612232 != nil:
    section.add "X-Amz-Date", valid_612232
  var valid_612233 = header.getOrDefault("X-Amz-Credential")
  valid_612233 = validateParameter(valid_612233, JString, required = false,
                                 default = nil)
  if valid_612233 != nil:
    section.add "X-Amz-Credential", valid_612233
  var valid_612234 = header.getOrDefault("X-Amz-Security-Token")
  valid_612234 = validateParameter(valid_612234, JString, required = false,
                                 default = nil)
  if valid_612234 != nil:
    section.add "X-Amz-Security-Token", valid_612234
  var valid_612235 = header.getOrDefault("X-Amz-Algorithm")
  valid_612235 = validateParameter(valid_612235, JString, required = false,
                                 default = nil)
  if valid_612235 != nil:
    section.add "X-Amz-Algorithm", valid_612235
  var valid_612236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612236 = validateParameter(valid_612236, JString, required = false,
                                 default = nil)
  if valid_612236 != nil:
    section.add "X-Amz-SignedHeaders", valid_612236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612238: Call_PutSkillAuthorization_612226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Links a user's account to a third-party skill provider. If this API operation is called by an assumed IAM role, the skill being linked must be a private skill. Also, the skill must be owned by the AWS account that assumed the IAM role.
  ## 
  let valid = call_612238.validator(path, query, header, formData, body)
  let scheme = call_612238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612238.url(scheme.get, call_612238.host, call_612238.base,
                         call_612238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612238, url, valid)

proc call*(call_612239: Call_PutSkillAuthorization_612226; body: JsonNode): Recallable =
  ## putSkillAuthorization
  ## Links a user's account to a third-party skill provider. If this API operation is called by an assumed IAM role, the skill being linked must be a private skill. Also, the skill must be owned by the AWS account that assumed the IAM role.
  ##   body: JObject (required)
  var body_612240 = newJObject()
  if body != nil:
    body_612240 = body
  result = call_612239.call(nil, nil, nil, nil, body_612240)

var putSkillAuthorization* = Call_PutSkillAuthorization_612226(
    name: "putSkillAuthorization", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutSkillAuthorization",
    validator: validate_PutSkillAuthorization_612227, base: "/",
    url: url_PutSkillAuthorization_612228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterAVSDevice_612241 = ref object of OpenApiRestCall_610658
proc url_RegisterAVSDevice_612243(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterAVSDevice_612242(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612244 = header.getOrDefault("X-Amz-Target")
  valid_612244 = validateParameter(valid_612244, JString, required = true, default = newJString(
      "AlexaForBusiness.RegisterAVSDevice"))
  if valid_612244 != nil:
    section.add "X-Amz-Target", valid_612244
  var valid_612245 = header.getOrDefault("X-Amz-Signature")
  valid_612245 = validateParameter(valid_612245, JString, required = false,
                                 default = nil)
  if valid_612245 != nil:
    section.add "X-Amz-Signature", valid_612245
  var valid_612246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612246 = validateParameter(valid_612246, JString, required = false,
                                 default = nil)
  if valid_612246 != nil:
    section.add "X-Amz-Content-Sha256", valid_612246
  var valid_612247 = header.getOrDefault("X-Amz-Date")
  valid_612247 = validateParameter(valid_612247, JString, required = false,
                                 default = nil)
  if valid_612247 != nil:
    section.add "X-Amz-Date", valid_612247
  var valid_612248 = header.getOrDefault("X-Amz-Credential")
  valid_612248 = validateParameter(valid_612248, JString, required = false,
                                 default = nil)
  if valid_612248 != nil:
    section.add "X-Amz-Credential", valid_612248
  var valid_612249 = header.getOrDefault("X-Amz-Security-Token")
  valid_612249 = validateParameter(valid_612249, JString, required = false,
                                 default = nil)
  if valid_612249 != nil:
    section.add "X-Amz-Security-Token", valid_612249
  var valid_612250 = header.getOrDefault("X-Amz-Algorithm")
  valid_612250 = validateParameter(valid_612250, JString, required = false,
                                 default = nil)
  if valid_612250 != nil:
    section.add "X-Amz-Algorithm", valid_612250
  var valid_612251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612251 = validateParameter(valid_612251, JString, required = false,
                                 default = nil)
  if valid_612251 != nil:
    section.add "X-Amz-SignedHeaders", valid_612251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612253: Call_RegisterAVSDevice_612241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers an Alexa-enabled device built by an Original Equipment Manufacturer (OEM) using Alexa Voice Service (AVS).
  ## 
  let valid = call_612253.validator(path, query, header, formData, body)
  let scheme = call_612253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612253.url(scheme.get, call_612253.host, call_612253.base,
                         call_612253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612253, url, valid)

proc call*(call_612254: Call_RegisterAVSDevice_612241; body: JsonNode): Recallable =
  ## registerAVSDevice
  ## Registers an Alexa-enabled device built by an Original Equipment Manufacturer (OEM) using Alexa Voice Service (AVS).
  ##   body: JObject (required)
  var body_612255 = newJObject()
  if body != nil:
    body_612255 = body
  result = call_612254.call(nil, nil, nil, nil, body_612255)

var registerAVSDevice* = Call_RegisterAVSDevice_612241(name: "registerAVSDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.RegisterAVSDevice",
    validator: validate_RegisterAVSDevice_612242, base: "/",
    url: url_RegisterAVSDevice_612243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectSkill_612256 = ref object of OpenApiRestCall_610658
proc url_RejectSkill_612258(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RejectSkill_612257(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612259 = header.getOrDefault("X-Amz-Target")
  valid_612259 = validateParameter(valid_612259, JString, required = true, default = newJString(
      "AlexaForBusiness.RejectSkill"))
  if valid_612259 != nil:
    section.add "X-Amz-Target", valid_612259
  var valid_612260 = header.getOrDefault("X-Amz-Signature")
  valid_612260 = validateParameter(valid_612260, JString, required = false,
                                 default = nil)
  if valid_612260 != nil:
    section.add "X-Amz-Signature", valid_612260
  var valid_612261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612261 = validateParameter(valid_612261, JString, required = false,
                                 default = nil)
  if valid_612261 != nil:
    section.add "X-Amz-Content-Sha256", valid_612261
  var valid_612262 = header.getOrDefault("X-Amz-Date")
  valid_612262 = validateParameter(valid_612262, JString, required = false,
                                 default = nil)
  if valid_612262 != nil:
    section.add "X-Amz-Date", valid_612262
  var valid_612263 = header.getOrDefault("X-Amz-Credential")
  valid_612263 = validateParameter(valid_612263, JString, required = false,
                                 default = nil)
  if valid_612263 != nil:
    section.add "X-Amz-Credential", valid_612263
  var valid_612264 = header.getOrDefault("X-Amz-Security-Token")
  valid_612264 = validateParameter(valid_612264, JString, required = false,
                                 default = nil)
  if valid_612264 != nil:
    section.add "X-Amz-Security-Token", valid_612264
  var valid_612265 = header.getOrDefault("X-Amz-Algorithm")
  valid_612265 = validateParameter(valid_612265, JString, required = false,
                                 default = nil)
  if valid_612265 != nil:
    section.add "X-Amz-Algorithm", valid_612265
  var valid_612266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612266 = validateParameter(valid_612266, JString, required = false,
                                 default = nil)
  if valid_612266 != nil:
    section.add "X-Amz-SignedHeaders", valid_612266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612268: Call_RejectSkill_612256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a skill from the organization under a user's AWS account. If the skill is a private skill, it moves to an AcceptStatus of PENDING. Any private or public skill that is rejected can be added later by calling the ApproveSkill API. 
  ## 
  let valid = call_612268.validator(path, query, header, formData, body)
  let scheme = call_612268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612268.url(scheme.get, call_612268.host, call_612268.base,
                         call_612268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612268, url, valid)

proc call*(call_612269: Call_RejectSkill_612256; body: JsonNode): Recallable =
  ## rejectSkill
  ## Disassociates a skill from the organization under a user's AWS account. If the skill is a private skill, it moves to an AcceptStatus of PENDING. Any private or public skill that is rejected can be added later by calling the ApproveSkill API. 
  ##   body: JObject (required)
  var body_612270 = newJObject()
  if body != nil:
    body_612270 = body
  result = call_612269.call(nil, nil, nil, nil, body_612270)

var rejectSkill* = Call_RejectSkill_612256(name: "rejectSkill",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.RejectSkill",
                                        validator: validate_RejectSkill_612257,
                                        base: "/", url: url_RejectSkill_612258,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResolveRoom_612271 = ref object of OpenApiRestCall_610658
proc url_ResolveRoom_612273(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResolveRoom_612272(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612274 = header.getOrDefault("X-Amz-Target")
  valid_612274 = validateParameter(valid_612274, JString, required = true, default = newJString(
      "AlexaForBusiness.ResolveRoom"))
  if valid_612274 != nil:
    section.add "X-Amz-Target", valid_612274
  var valid_612275 = header.getOrDefault("X-Amz-Signature")
  valid_612275 = validateParameter(valid_612275, JString, required = false,
                                 default = nil)
  if valid_612275 != nil:
    section.add "X-Amz-Signature", valid_612275
  var valid_612276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612276 = validateParameter(valid_612276, JString, required = false,
                                 default = nil)
  if valid_612276 != nil:
    section.add "X-Amz-Content-Sha256", valid_612276
  var valid_612277 = header.getOrDefault("X-Amz-Date")
  valid_612277 = validateParameter(valid_612277, JString, required = false,
                                 default = nil)
  if valid_612277 != nil:
    section.add "X-Amz-Date", valid_612277
  var valid_612278 = header.getOrDefault("X-Amz-Credential")
  valid_612278 = validateParameter(valid_612278, JString, required = false,
                                 default = nil)
  if valid_612278 != nil:
    section.add "X-Amz-Credential", valid_612278
  var valid_612279 = header.getOrDefault("X-Amz-Security-Token")
  valid_612279 = validateParameter(valid_612279, JString, required = false,
                                 default = nil)
  if valid_612279 != nil:
    section.add "X-Amz-Security-Token", valid_612279
  var valid_612280 = header.getOrDefault("X-Amz-Algorithm")
  valid_612280 = validateParameter(valid_612280, JString, required = false,
                                 default = nil)
  if valid_612280 != nil:
    section.add "X-Amz-Algorithm", valid_612280
  var valid_612281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612281 = validateParameter(valid_612281, JString, required = false,
                                 default = nil)
  if valid_612281 != nil:
    section.add "X-Amz-SignedHeaders", valid_612281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612283: Call_ResolveRoom_612271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Determines the details for the room from which a skill request was invoked. This operation is used by skill developers.
  ## 
  let valid = call_612283.validator(path, query, header, formData, body)
  let scheme = call_612283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612283.url(scheme.get, call_612283.host, call_612283.base,
                         call_612283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612283, url, valid)

proc call*(call_612284: Call_ResolveRoom_612271; body: JsonNode): Recallable =
  ## resolveRoom
  ## Determines the details for the room from which a skill request was invoked. This operation is used by skill developers.
  ##   body: JObject (required)
  var body_612285 = newJObject()
  if body != nil:
    body_612285 = body
  result = call_612284.call(nil, nil, nil, nil, body_612285)

var resolveRoom* = Call_ResolveRoom_612271(name: "resolveRoom",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ResolveRoom",
                                        validator: validate_ResolveRoom_612272,
                                        base: "/", url: url_ResolveRoom_612273,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeInvitation_612286 = ref object of OpenApiRestCall_610658
proc url_RevokeInvitation_612288(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RevokeInvitation_612287(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612289 = header.getOrDefault("X-Amz-Target")
  valid_612289 = validateParameter(valid_612289, JString, required = true, default = newJString(
      "AlexaForBusiness.RevokeInvitation"))
  if valid_612289 != nil:
    section.add "X-Amz-Target", valid_612289
  var valid_612290 = header.getOrDefault("X-Amz-Signature")
  valid_612290 = validateParameter(valid_612290, JString, required = false,
                                 default = nil)
  if valid_612290 != nil:
    section.add "X-Amz-Signature", valid_612290
  var valid_612291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612291 = validateParameter(valid_612291, JString, required = false,
                                 default = nil)
  if valid_612291 != nil:
    section.add "X-Amz-Content-Sha256", valid_612291
  var valid_612292 = header.getOrDefault("X-Amz-Date")
  valid_612292 = validateParameter(valid_612292, JString, required = false,
                                 default = nil)
  if valid_612292 != nil:
    section.add "X-Amz-Date", valid_612292
  var valid_612293 = header.getOrDefault("X-Amz-Credential")
  valid_612293 = validateParameter(valid_612293, JString, required = false,
                                 default = nil)
  if valid_612293 != nil:
    section.add "X-Amz-Credential", valid_612293
  var valid_612294 = header.getOrDefault("X-Amz-Security-Token")
  valid_612294 = validateParameter(valid_612294, JString, required = false,
                                 default = nil)
  if valid_612294 != nil:
    section.add "X-Amz-Security-Token", valid_612294
  var valid_612295 = header.getOrDefault("X-Amz-Algorithm")
  valid_612295 = validateParameter(valid_612295, JString, required = false,
                                 default = nil)
  if valid_612295 != nil:
    section.add "X-Amz-Algorithm", valid_612295
  var valid_612296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612296 = validateParameter(valid_612296, JString, required = false,
                                 default = nil)
  if valid_612296 != nil:
    section.add "X-Amz-SignedHeaders", valid_612296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612298: Call_RevokeInvitation_612286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes an invitation and invalidates the enrollment URL.
  ## 
  let valid = call_612298.validator(path, query, header, formData, body)
  let scheme = call_612298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612298.url(scheme.get, call_612298.host, call_612298.base,
                         call_612298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612298, url, valid)

proc call*(call_612299: Call_RevokeInvitation_612286; body: JsonNode): Recallable =
  ## revokeInvitation
  ## Revokes an invitation and invalidates the enrollment URL.
  ##   body: JObject (required)
  var body_612300 = newJObject()
  if body != nil:
    body_612300 = body
  result = call_612299.call(nil, nil, nil, nil, body_612300)

var revokeInvitation* = Call_RevokeInvitation_612286(name: "revokeInvitation",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.RevokeInvitation",
    validator: validate_RevokeInvitation_612287, base: "/",
    url: url_RevokeInvitation_612288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAddressBooks_612301 = ref object of OpenApiRestCall_610658
proc url_SearchAddressBooks_612303(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchAddressBooks_612302(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
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
  var valid_612304 = query.getOrDefault("MaxResults")
  valid_612304 = validateParameter(valid_612304, JString, required = false,
                                 default = nil)
  if valid_612304 != nil:
    section.add "MaxResults", valid_612304
  var valid_612305 = query.getOrDefault("NextToken")
  valid_612305 = validateParameter(valid_612305, JString, required = false,
                                 default = nil)
  if valid_612305 != nil:
    section.add "NextToken", valid_612305
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
  var valid_612306 = header.getOrDefault("X-Amz-Target")
  valid_612306 = validateParameter(valid_612306, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchAddressBooks"))
  if valid_612306 != nil:
    section.add "X-Amz-Target", valid_612306
  var valid_612307 = header.getOrDefault("X-Amz-Signature")
  valid_612307 = validateParameter(valid_612307, JString, required = false,
                                 default = nil)
  if valid_612307 != nil:
    section.add "X-Amz-Signature", valid_612307
  var valid_612308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612308 = validateParameter(valid_612308, JString, required = false,
                                 default = nil)
  if valid_612308 != nil:
    section.add "X-Amz-Content-Sha256", valid_612308
  var valid_612309 = header.getOrDefault("X-Amz-Date")
  valid_612309 = validateParameter(valid_612309, JString, required = false,
                                 default = nil)
  if valid_612309 != nil:
    section.add "X-Amz-Date", valid_612309
  var valid_612310 = header.getOrDefault("X-Amz-Credential")
  valid_612310 = validateParameter(valid_612310, JString, required = false,
                                 default = nil)
  if valid_612310 != nil:
    section.add "X-Amz-Credential", valid_612310
  var valid_612311 = header.getOrDefault("X-Amz-Security-Token")
  valid_612311 = validateParameter(valid_612311, JString, required = false,
                                 default = nil)
  if valid_612311 != nil:
    section.add "X-Amz-Security-Token", valid_612311
  var valid_612312 = header.getOrDefault("X-Amz-Algorithm")
  valid_612312 = validateParameter(valid_612312, JString, required = false,
                                 default = nil)
  if valid_612312 != nil:
    section.add "X-Amz-Algorithm", valid_612312
  var valid_612313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612313 = validateParameter(valid_612313, JString, required = false,
                                 default = nil)
  if valid_612313 != nil:
    section.add "X-Amz-SignedHeaders", valid_612313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612315: Call_SearchAddressBooks_612301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_612315.validator(path, query, header, formData, body)
  let scheme = call_612315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612315.url(scheme.get, call_612315.host, call_612315.base,
                         call_612315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612315, url, valid)

proc call*(call_612316: Call_SearchAddressBooks_612301; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchAddressBooks
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612317 = newJObject()
  var body_612318 = newJObject()
  add(query_612317, "MaxResults", newJString(MaxResults))
  add(query_612317, "NextToken", newJString(NextToken))
  if body != nil:
    body_612318 = body
  result = call_612316.call(nil, query_612317, nil, nil, body_612318)

var searchAddressBooks* = Call_SearchAddressBooks_612301(
    name: "searchAddressBooks", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchAddressBooks",
    validator: validate_SearchAddressBooks_612302, base: "/",
    url: url_SearchAddressBooks_612303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchContacts_612319 = ref object of OpenApiRestCall_610658
proc url_SearchContacts_612321(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchContacts_612320(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
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
  var valid_612322 = query.getOrDefault("MaxResults")
  valid_612322 = validateParameter(valid_612322, JString, required = false,
                                 default = nil)
  if valid_612322 != nil:
    section.add "MaxResults", valid_612322
  var valid_612323 = query.getOrDefault("NextToken")
  valid_612323 = validateParameter(valid_612323, JString, required = false,
                                 default = nil)
  if valid_612323 != nil:
    section.add "NextToken", valid_612323
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
  var valid_612324 = header.getOrDefault("X-Amz-Target")
  valid_612324 = validateParameter(valid_612324, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchContacts"))
  if valid_612324 != nil:
    section.add "X-Amz-Target", valid_612324
  var valid_612325 = header.getOrDefault("X-Amz-Signature")
  valid_612325 = validateParameter(valid_612325, JString, required = false,
                                 default = nil)
  if valid_612325 != nil:
    section.add "X-Amz-Signature", valid_612325
  var valid_612326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612326 = validateParameter(valid_612326, JString, required = false,
                                 default = nil)
  if valid_612326 != nil:
    section.add "X-Amz-Content-Sha256", valid_612326
  var valid_612327 = header.getOrDefault("X-Amz-Date")
  valid_612327 = validateParameter(valid_612327, JString, required = false,
                                 default = nil)
  if valid_612327 != nil:
    section.add "X-Amz-Date", valid_612327
  var valid_612328 = header.getOrDefault("X-Amz-Credential")
  valid_612328 = validateParameter(valid_612328, JString, required = false,
                                 default = nil)
  if valid_612328 != nil:
    section.add "X-Amz-Credential", valid_612328
  var valid_612329 = header.getOrDefault("X-Amz-Security-Token")
  valid_612329 = validateParameter(valid_612329, JString, required = false,
                                 default = nil)
  if valid_612329 != nil:
    section.add "X-Amz-Security-Token", valid_612329
  var valid_612330 = header.getOrDefault("X-Amz-Algorithm")
  valid_612330 = validateParameter(valid_612330, JString, required = false,
                                 default = nil)
  if valid_612330 != nil:
    section.add "X-Amz-Algorithm", valid_612330
  var valid_612331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612331 = validateParameter(valid_612331, JString, required = false,
                                 default = nil)
  if valid_612331 != nil:
    section.add "X-Amz-SignedHeaders", valid_612331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612333: Call_SearchContacts_612319; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_612333.validator(path, query, header, formData, body)
  let scheme = call_612333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612333.url(scheme.get, call_612333.host, call_612333.base,
                         call_612333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612333, url, valid)

proc call*(call_612334: Call_SearchContacts_612319; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchContacts
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612335 = newJObject()
  var body_612336 = newJObject()
  add(query_612335, "MaxResults", newJString(MaxResults))
  add(query_612335, "NextToken", newJString(NextToken))
  if body != nil:
    body_612336 = body
  result = call_612334.call(nil, query_612335, nil, nil, body_612336)

var searchContacts* = Call_SearchContacts_612319(name: "searchContacts",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchContacts",
    validator: validate_SearchContacts_612320, base: "/", url: url_SearchContacts_612321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchDevices_612337 = ref object of OpenApiRestCall_610658
proc url_SearchDevices_612339(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchDevices_612338(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches devices and lists the ones that meet a set of filter criteria.
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
  var valid_612340 = query.getOrDefault("MaxResults")
  valid_612340 = validateParameter(valid_612340, JString, required = false,
                                 default = nil)
  if valid_612340 != nil:
    section.add "MaxResults", valid_612340
  var valid_612341 = query.getOrDefault("NextToken")
  valid_612341 = validateParameter(valid_612341, JString, required = false,
                                 default = nil)
  if valid_612341 != nil:
    section.add "NextToken", valid_612341
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
  var valid_612342 = header.getOrDefault("X-Amz-Target")
  valid_612342 = validateParameter(valid_612342, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchDevices"))
  if valid_612342 != nil:
    section.add "X-Amz-Target", valid_612342
  var valid_612343 = header.getOrDefault("X-Amz-Signature")
  valid_612343 = validateParameter(valid_612343, JString, required = false,
                                 default = nil)
  if valid_612343 != nil:
    section.add "X-Amz-Signature", valid_612343
  var valid_612344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612344 = validateParameter(valid_612344, JString, required = false,
                                 default = nil)
  if valid_612344 != nil:
    section.add "X-Amz-Content-Sha256", valid_612344
  var valid_612345 = header.getOrDefault("X-Amz-Date")
  valid_612345 = validateParameter(valid_612345, JString, required = false,
                                 default = nil)
  if valid_612345 != nil:
    section.add "X-Amz-Date", valid_612345
  var valid_612346 = header.getOrDefault("X-Amz-Credential")
  valid_612346 = validateParameter(valid_612346, JString, required = false,
                                 default = nil)
  if valid_612346 != nil:
    section.add "X-Amz-Credential", valid_612346
  var valid_612347 = header.getOrDefault("X-Amz-Security-Token")
  valid_612347 = validateParameter(valid_612347, JString, required = false,
                                 default = nil)
  if valid_612347 != nil:
    section.add "X-Amz-Security-Token", valid_612347
  var valid_612348 = header.getOrDefault("X-Amz-Algorithm")
  valid_612348 = validateParameter(valid_612348, JString, required = false,
                                 default = nil)
  if valid_612348 != nil:
    section.add "X-Amz-Algorithm", valid_612348
  var valid_612349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612349 = validateParameter(valid_612349, JString, required = false,
                                 default = nil)
  if valid_612349 != nil:
    section.add "X-Amz-SignedHeaders", valid_612349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612351: Call_SearchDevices_612337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches devices and lists the ones that meet a set of filter criteria.
  ## 
  let valid = call_612351.validator(path, query, header, formData, body)
  let scheme = call_612351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612351.url(scheme.get, call_612351.host, call_612351.base,
                         call_612351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612351, url, valid)

proc call*(call_612352: Call_SearchDevices_612337; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchDevices
  ## Searches devices and lists the ones that meet a set of filter criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612353 = newJObject()
  var body_612354 = newJObject()
  add(query_612353, "MaxResults", newJString(MaxResults))
  add(query_612353, "NextToken", newJString(NextToken))
  if body != nil:
    body_612354 = body
  result = call_612352.call(nil, query_612353, nil, nil, body_612354)

var searchDevices* = Call_SearchDevices_612337(name: "searchDevices",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchDevices",
    validator: validate_SearchDevices_612338, base: "/", url: url_SearchDevices_612339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchNetworkProfiles_612355 = ref object of OpenApiRestCall_610658
proc url_SearchNetworkProfiles_612357(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchNetworkProfiles_612356(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
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
  var valid_612358 = query.getOrDefault("MaxResults")
  valid_612358 = validateParameter(valid_612358, JString, required = false,
                                 default = nil)
  if valid_612358 != nil:
    section.add "MaxResults", valid_612358
  var valid_612359 = query.getOrDefault("NextToken")
  valid_612359 = validateParameter(valid_612359, JString, required = false,
                                 default = nil)
  if valid_612359 != nil:
    section.add "NextToken", valid_612359
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
  var valid_612360 = header.getOrDefault("X-Amz-Target")
  valid_612360 = validateParameter(valid_612360, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchNetworkProfiles"))
  if valid_612360 != nil:
    section.add "X-Amz-Target", valid_612360
  var valid_612361 = header.getOrDefault("X-Amz-Signature")
  valid_612361 = validateParameter(valid_612361, JString, required = false,
                                 default = nil)
  if valid_612361 != nil:
    section.add "X-Amz-Signature", valid_612361
  var valid_612362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612362 = validateParameter(valid_612362, JString, required = false,
                                 default = nil)
  if valid_612362 != nil:
    section.add "X-Amz-Content-Sha256", valid_612362
  var valid_612363 = header.getOrDefault("X-Amz-Date")
  valid_612363 = validateParameter(valid_612363, JString, required = false,
                                 default = nil)
  if valid_612363 != nil:
    section.add "X-Amz-Date", valid_612363
  var valid_612364 = header.getOrDefault("X-Amz-Credential")
  valid_612364 = validateParameter(valid_612364, JString, required = false,
                                 default = nil)
  if valid_612364 != nil:
    section.add "X-Amz-Credential", valid_612364
  var valid_612365 = header.getOrDefault("X-Amz-Security-Token")
  valid_612365 = validateParameter(valid_612365, JString, required = false,
                                 default = nil)
  if valid_612365 != nil:
    section.add "X-Amz-Security-Token", valid_612365
  var valid_612366 = header.getOrDefault("X-Amz-Algorithm")
  valid_612366 = validateParameter(valid_612366, JString, required = false,
                                 default = nil)
  if valid_612366 != nil:
    section.add "X-Amz-Algorithm", valid_612366
  var valid_612367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612367 = validateParameter(valid_612367, JString, required = false,
                                 default = nil)
  if valid_612367 != nil:
    section.add "X-Amz-SignedHeaders", valid_612367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612369: Call_SearchNetworkProfiles_612355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_612369.validator(path, query, header, formData, body)
  let scheme = call_612369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612369.url(scheme.get, call_612369.host, call_612369.base,
                         call_612369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612369, url, valid)

proc call*(call_612370: Call_SearchNetworkProfiles_612355; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchNetworkProfiles
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612371 = newJObject()
  var body_612372 = newJObject()
  add(query_612371, "MaxResults", newJString(MaxResults))
  add(query_612371, "NextToken", newJString(NextToken))
  if body != nil:
    body_612372 = body
  result = call_612370.call(nil, query_612371, nil, nil, body_612372)

var searchNetworkProfiles* = Call_SearchNetworkProfiles_612355(
    name: "searchNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchNetworkProfiles",
    validator: validate_SearchNetworkProfiles_612356, base: "/",
    url: url_SearchNetworkProfiles_612357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProfiles_612373 = ref object of OpenApiRestCall_610658
proc url_SearchProfiles_612375(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchProfiles_612374(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
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
  var valid_612376 = query.getOrDefault("MaxResults")
  valid_612376 = validateParameter(valid_612376, JString, required = false,
                                 default = nil)
  if valid_612376 != nil:
    section.add "MaxResults", valid_612376
  var valid_612377 = query.getOrDefault("NextToken")
  valid_612377 = validateParameter(valid_612377, JString, required = false,
                                 default = nil)
  if valid_612377 != nil:
    section.add "NextToken", valid_612377
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
  var valid_612378 = header.getOrDefault("X-Amz-Target")
  valid_612378 = validateParameter(valid_612378, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchProfiles"))
  if valid_612378 != nil:
    section.add "X-Amz-Target", valid_612378
  var valid_612379 = header.getOrDefault("X-Amz-Signature")
  valid_612379 = validateParameter(valid_612379, JString, required = false,
                                 default = nil)
  if valid_612379 != nil:
    section.add "X-Amz-Signature", valid_612379
  var valid_612380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612380 = validateParameter(valid_612380, JString, required = false,
                                 default = nil)
  if valid_612380 != nil:
    section.add "X-Amz-Content-Sha256", valid_612380
  var valid_612381 = header.getOrDefault("X-Amz-Date")
  valid_612381 = validateParameter(valid_612381, JString, required = false,
                                 default = nil)
  if valid_612381 != nil:
    section.add "X-Amz-Date", valid_612381
  var valid_612382 = header.getOrDefault("X-Amz-Credential")
  valid_612382 = validateParameter(valid_612382, JString, required = false,
                                 default = nil)
  if valid_612382 != nil:
    section.add "X-Amz-Credential", valid_612382
  var valid_612383 = header.getOrDefault("X-Amz-Security-Token")
  valid_612383 = validateParameter(valid_612383, JString, required = false,
                                 default = nil)
  if valid_612383 != nil:
    section.add "X-Amz-Security-Token", valid_612383
  var valid_612384 = header.getOrDefault("X-Amz-Algorithm")
  valid_612384 = validateParameter(valid_612384, JString, required = false,
                                 default = nil)
  if valid_612384 != nil:
    section.add "X-Amz-Algorithm", valid_612384
  var valid_612385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612385 = validateParameter(valid_612385, JString, required = false,
                                 default = nil)
  if valid_612385 != nil:
    section.add "X-Amz-SignedHeaders", valid_612385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612387: Call_SearchProfiles_612373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
  ## 
  let valid = call_612387.validator(path, query, header, formData, body)
  let scheme = call_612387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612387.url(scheme.get, call_612387.host, call_612387.base,
                         call_612387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612387, url, valid)

proc call*(call_612388: Call_SearchProfiles_612373; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchProfiles
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612389 = newJObject()
  var body_612390 = newJObject()
  add(query_612389, "MaxResults", newJString(MaxResults))
  add(query_612389, "NextToken", newJString(NextToken))
  if body != nil:
    body_612390 = body
  result = call_612388.call(nil, query_612389, nil, nil, body_612390)

var searchProfiles* = Call_SearchProfiles_612373(name: "searchProfiles",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchProfiles",
    validator: validate_SearchProfiles_612374, base: "/", url: url_SearchProfiles_612375,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchRooms_612391 = ref object of OpenApiRestCall_610658
proc url_SearchRooms_612393(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchRooms_612392(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
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
  var valid_612394 = query.getOrDefault("MaxResults")
  valid_612394 = validateParameter(valid_612394, JString, required = false,
                                 default = nil)
  if valid_612394 != nil:
    section.add "MaxResults", valid_612394
  var valid_612395 = query.getOrDefault("NextToken")
  valid_612395 = validateParameter(valid_612395, JString, required = false,
                                 default = nil)
  if valid_612395 != nil:
    section.add "NextToken", valid_612395
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
  var valid_612396 = header.getOrDefault("X-Amz-Target")
  valid_612396 = validateParameter(valid_612396, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchRooms"))
  if valid_612396 != nil:
    section.add "X-Amz-Target", valid_612396
  var valid_612397 = header.getOrDefault("X-Amz-Signature")
  valid_612397 = validateParameter(valid_612397, JString, required = false,
                                 default = nil)
  if valid_612397 != nil:
    section.add "X-Amz-Signature", valid_612397
  var valid_612398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612398 = validateParameter(valid_612398, JString, required = false,
                                 default = nil)
  if valid_612398 != nil:
    section.add "X-Amz-Content-Sha256", valid_612398
  var valid_612399 = header.getOrDefault("X-Amz-Date")
  valid_612399 = validateParameter(valid_612399, JString, required = false,
                                 default = nil)
  if valid_612399 != nil:
    section.add "X-Amz-Date", valid_612399
  var valid_612400 = header.getOrDefault("X-Amz-Credential")
  valid_612400 = validateParameter(valid_612400, JString, required = false,
                                 default = nil)
  if valid_612400 != nil:
    section.add "X-Amz-Credential", valid_612400
  var valid_612401 = header.getOrDefault("X-Amz-Security-Token")
  valid_612401 = validateParameter(valid_612401, JString, required = false,
                                 default = nil)
  if valid_612401 != nil:
    section.add "X-Amz-Security-Token", valid_612401
  var valid_612402 = header.getOrDefault("X-Amz-Algorithm")
  valid_612402 = validateParameter(valid_612402, JString, required = false,
                                 default = nil)
  if valid_612402 != nil:
    section.add "X-Amz-Algorithm", valid_612402
  var valid_612403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612403 = validateParameter(valid_612403, JString, required = false,
                                 default = nil)
  if valid_612403 != nil:
    section.add "X-Amz-SignedHeaders", valid_612403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612405: Call_SearchRooms_612391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_612405.validator(path, query, header, formData, body)
  let scheme = call_612405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612405.url(scheme.get, call_612405.host, call_612405.base,
                         call_612405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612405, url, valid)

proc call*(call_612406: Call_SearchRooms_612391; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchRooms
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612407 = newJObject()
  var body_612408 = newJObject()
  add(query_612407, "MaxResults", newJString(MaxResults))
  add(query_612407, "NextToken", newJString(NextToken))
  if body != nil:
    body_612408 = body
  result = call_612406.call(nil, query_612407, nil, nil, body_612408)

var searchRooms* = Call_SearchRooms_612391(name: "searchRooms",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.SearchRooms",
                                        validator: validate_SearchRooms_612392,
                                        base: "/", url: url_SearchRooms_612393,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSkillGroups_612409 = ref object of OpenApiRestCall_610658
proc url_SearchSkillGroups_612411(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchSkillGroups_612410(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
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
  var valid_612412 = query.getOrDefault("MaxResults")
  valid_612412 = validateParameter(valid_612412, JString, required = false,
                                 default = nil)
  if valid_612412 != nil:
    section.add "MaxResults", valid_612412
  var valid_612413 = query.getOrDefault("NextToken")
  valid_612413 = validateParameter(valid_612413, JString, required = false,
                                 default = nil)
  if valid_612413 != nil:
    section.add "NextToken", valid_612413
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
  var valid_612414 = header.getOrDefault("X-Amz-Target")
  valid_612414 = validateParameter(valid_612414, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchSkillGroups"))
  if valid_612414 != nil:
    section.add "X-Amz-Target", valid_612414
  var valid_612415 = header.getOrDefault("X-Amz-Signature")
  valid_612415 = validateParameter(valid_612415, JString, required = false,
                                 default = nil)
  if valid_612415 != nil:
    section.add "X-Amz-Signature", valid_612415
  var valid_612416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612416 = validateParameter(valid_612416, JString, required = false,
                                 default = nil)
  if valid_612416 != nil:
    section.add "X-Amz-Content-Sha256", valid_612416
  var valid_612417 = header.getOrDefault("X-Amz-Date")
  valid_612417 = validateParameter(valid_612417, JString, required = false,
                                 default = nil)
  if valid_612417 != nil:
    section.add "X-Amz-Date", valid_612417
  var valid_612418 = header.getOrDefault("X-Amz-Credential")
  valid_612418 = validateParameter(valid_612418, JString, required = false,
                                 default = nil)
  if valid_612418 != nil:
    section.add "X-Amz-Credential", valid_612418
  var valid_612419 = header.getOrDefault("X-Amz-Security-Token")
  valid_612419 = validateParameter(valid_612419, JString, required = false,
                                 default = nil)
  if valid_612419 != nil:
    section.add "X-Amz-Security-Token", valid_612419
  var valid_612420 = header.getOrDefault("X-Amz-Algorithm")
  valid_612420 = validateParameter(valid_612420, JString, required = false,
                                 default = nil)
  if valid_612420 != nil:
    section.add "X-Amz-Algorithm", valid_612420
  var valid_612421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612421 = validateParameter(valid_612421, JString, required = false,
                                 default = nil)
  if valid_612421 != nil:
    section.add "X-Amz-SignedHeaders", valid_612421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612423: Call_SearchSkillGroups_612409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_612423.validator(path, query, header, formData, body)
  let scheme = call_612423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612423.url(scheme.get, call_612423.host, call_612423.base,
                         call_612423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612423, url, valid)

proc call*(call_612424: Call_SearchSkillGroups_612409; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchSkillGroups
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612425 = newJObject()
  var body_612426 = newJObject()
  add(query_612425, "MaxResults", newJString(MaxResults))
  add(query_612425, "NextToken", newJString(NextToken))
  if body != nil:
    body_612426 = body
  result = call_612424.call(nil, query_612425, nil, nil, body_612426)

var searchSkillGroups* = Call_SearchSkillGroups_612409(name: "searchSkillGroups",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchSkillGroups",
    validator: validate_SearchSkillGroups_612410, base: "/",
    url: url_SearchSkillGroups_612411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchUsers_612427 = ref object of OpenApiRestCall_610658
proc url_SearchUsers_612429(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchUsers_612428(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
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
  var valid_612430 = query.getOrDefault("MaxResults")
  valid_612430 = validateParameter(valid_612430, JString, required = false,
                                 default = nil)
  if valid_612430 != nil:
    section.add "MaxResults", valid_612430
  var valid_612431 = query.getOrDefault("NextToken")
  valid_612431 = validateParameter(valid_612431, JString, required = false,
                                 default = nil)
  if valid_612431 != nil:
    section.add "NextToken", valid_612431
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
  var valid_612432 = header.getOrDefault("X-Amz-Target")
  valid_612432 = validateParameter(valid_612432, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchUsers"))
  if valid_612432 != nil:
    section.add "X-Amz-Target", valid_612432
  var valid_612433 = header.getOrDefault("X-Amz-Signature")
  valid_612433 = validateParameter(valid_612433, JString, required = false,
                                 default = nil)
  if valid_612433 != nil:
    section.add "X-Amz-Signature", valid_612433
  var valid_612434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612434 = validateParameter(valid_612434, JString, required = false,
                                 default = nil)
  if valid_612434 != nil:
    section.add "X-Amz-Content-Sha256", valid_612434
  var valid_612435 = header.getOrDefault("X-Amz-Date")
  valid_612435 = validateParameter(valid_612435, JString, required = false,
                                 default = nil)
  if valid_612435 != nil:
    section.add "X-Amz-Date", valid_612435
  var valid_612436 = header.getOrDefault("X-Amz-Credential")
  valid_612436 = validateParameter(valid_612436, JString, required = false,
                                 default = nil)
  if valid_612436 != nil:
    section.add "X-Amz-Credential", valid_612436
  var valid_612437 = header.getOrDefault("X-Amz-Security-Token")
  valid_612437 = validateParameter(valid_612437, JString, required = false,
                                 default = nil)
  if valid_612437 != nil:
    section.add "X-Amz-Security-Token", valid_612437
  var valid_612438 = header.getOrDefault("X-Amz-Algorithm")
  valid_612438 = validateParameter(valid_612438, JString, required = false,
                                 default = nil)
  if valid_612438 != nil:
    section.add "X-Amz-Algorithm", valid_612438
  var valid_612439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612439 = validateParameter(valid_612439, JString, required = false,
                                 default = nil)
  if valid_612439 != nil:
    section.add "X-Amz-SignedHeaders", valid_612439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612441: Call_SearchUsers_612427; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_612441.validator(path, query, header, formData, body)
  let scheme = call_612441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612441.url(scheme.get, call_612441.host, call_612441.base,
                         call_612441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612441, url, valid)

proc call*(call_612442: Call_SearchUsers_612427; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchUsers
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612443 = newJObject()
  var body_612444 = newJObject()
  add(query_612443, "MaxResults", newJString(MaxResults))
  add(query_612443, "NextToken", newJString(NextToken))
  if body != nil:
    body_612444 = body
  result = call_612442.call(nil, query_612443, nil, nil, body_612444)

var searchUsers* = Call_SearchUsers_612427(name: "searchUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.SearchUsers",
                                        validator: validate_SearchUsers_612428,
                                        base: "/", url: url_SearchUsers_612429,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAnnouncement_612445 = ref object of OpenApiRestCall_610658
proc url_SendAnnouncement_612447(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendAnnouncement_612446(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612448 = header.getOrDefault("X-Amz-Target")
  valid_612448 = validateParameter(valid_612448, JString, required = true, default = newJString(
      "AlexaForBusiness.SendAnnouncement"))
  if valid_612448 != nil:
    section.add "X-Amz-Target", valid_612448
  var valid_612449 = header.getOrDefault("X-Amz-Signature")
  valid_612449 = validateParameter(valid_612449, JString, required = false,
                                 default = nil)
  if valid_612449 != nil:
    section.add "X-Amz-Signature", valid_612449
  var valid_612450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612450 = validateParameter(valid_612450, JString, required = false,
                                 default = nil)
  if valid_612450 != nil:
    section.add "X-Amz-Content-Sha256", valid_612450
  var valid_612451 = header.getOrDefault("X-Amz-Date")
  valid_612451 = validateParameter(valid_612451, JString, required = false,
                                 default = nil)
  if valid_612451 != nil:
    section.add "X-Amz-Date", valid_612451
  var valid_612452 = header.getOrDefault("X-Amz-Credential")
  valid_612452 = validateParameter(valid_612452, JString, required = false,
                                 default = nil)
  if valid_612452 != nil:
    section.add "X-Amz-Credential", valid_612452
  var valid_612453 = header.getOrDefault("X-Amz-Security-Token")
  valid_612453 = validateParameter(valid_612453, JString, required = false,
                                 default = nil)
  if valid_612453 != nil:
    section.add "X-Amz-Security-Token", valid_612453
  var valid_612454 = header.getOrDefault("X-Amz-Algorithm")
  valid_612454 = validateParameter(valid_612454, JString, required = false,
                                 default = nil)
  if valid_612454 != nil:
    section.add "X-Amz-Algorithm", valid_612454
  var valid_612455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612455 = validateParameter(valid_612455, JString, required = false,
                                 default = nil)
  if valid_612455 != nil:
    section.add "X-Amz-SignedHeaders", valid_612455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612457: Call_SendAnnouncement_612445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Triggers an asynchronous flow to send text, SSML, or audio announcements to rooms that are identified by a search or filter. 
  ## 
  let valid = call_612457.validator(path, query, header, formData, body)
  let scheme = call_612457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612457.url(scheme.get, call_612457.host, call_612457.base,
                         call_612457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612457, url, valid)

proc call*(call_612458: Call_SendAnnouncement_612445; body: JsonNode): Recallable =
  ## sendAnnouncement
  ## Triggers an asynchronous flow to send text, SSML, or audio announcements to rooms that are identified by a search or filter. 
  ##   body: JObject (required)
  var body_612459 = newJObject()
  if body != nil:
    body_612459 = body
  result = call_612458.call(nil, nil, nil, nil, body_612459)

var sendAnnouncement* = Call_SendAnnouncement_612445(name: "sendAnnouncement",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SendAnnouncement",
    validator: validate_SendAnnouncement_612446, base: "/",
    url: url_SendAnnouncement_612447, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendInvitation_612460 = ref object of OpenApiRestCall_610658
proc url_SendInvitation_612462(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendInvitation_612461(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612463 = header.getOrDefault("X-Amz-Target")
  valid_612463 = validateParameter(valid_612463, JString, required = true, default = newJString(
      "AlexaForBusiness.SendInvitation"))
  if valid_612463 != nil:
    section.add "X-Amz-Target", valid_612463
  var valid_612464 = header.getOrDefault("X-Amz-Signature")
  valid_612464 = validateParameter(valid_612464, JString, required = false,
                                 default = nil)
  if valid_612464 != nil:
    section.add "X-Amz-Signature", valid_612464
  var valid_612465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612465 = validateParameter(valid_612465, JString, required = false,
                                 default = nil)
  if valid_612465 != nil:
    section.add "X-Amz-Content-Sha256", valid_612465
  var valid_612466 = header.getOrDefault("X-Amz-Date")
  valid_612466 = validateParameter(valid_612466, JString, required = false,
                                 default = nil)
  if valid_612466 != nil:
    section.add "X-Amz-Date", valid_612466
  var valid_612467 = header.getOrDefault("X-Amz-Credential")
  valid_612467 = validateParameter(valid_612467, JString, required = false,
                                 default = nil)
  if valid_612467 != nil:
    section.add "X-Amz-Credential", valid_612467
  var valid_612468 = header.getOrDefault("X-Amz-Security-Token")
  valid_612468 = validateParameter(valid_612468, JString, required = false,
                                 default = nil)
  if valid_612468 != nil:
    section.add "X-Amz-Security-Token", valid_612468
  var valid_612469 = header.getOrDefault("X-Amz-Algorithm")
  valid_612469 = validateParameter(valid_612469, JString, required = false,
                                 default = nil)
  if valid_612469 != nil:
    section.add "X-Amz-Algorithm", valid_612469
  var valid_612470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612470 = validateParameter(valid_612470, JString, required = false,
                                 default = nil)
  if valid_612470 != nil:
    section.add "X-Amz-SignedHeaders", valid_612470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612472: Call_SendInvitation_612460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends an enrollment invitation email with a URL to a user. The URL is valid for 30 days or until you call this operation again, whichever comes first. 
  ## 
  let valid = call_612472.validator(path, query, header, formData, body)
  let scheme = call_612472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612472.url(scheme.get, call_612472.host, call_612472.base,
                         call_612472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612472, url, valid)

proc call*(call_612473: Call_SendInvitation_612460; body: JsonNode): Recallable =
  ## sendInvitation
  ## Sends an enrollment invitation email with a URL to a user. The URL is valid for 30 days or until you call this operation again, whichever comes first. 
  ##   body: JObject (required)
  var body_612474 = newJObject()
  if body != nil:
    body_612474 = body
  result = call_612473.call(nil, nil, nil, nil, body_612474)

var sendInvitation* = Call_SendInvitation_612460(name: "sendInvitation",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SendInvitation",
    validator: validate_SendInvitation_612461, base: "/", url: url_SendInvitation_612462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeviceSync_612475 = ref object of OpenApiRestCall_610658
proc url_StartDeviceSync_612477(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartDeviceSync_612476(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612478 = header.getOrDefault("X-Amz-Target")
  valid_612478 = validateParameter(valid_612478, JString, required = true, default = newJString(
      "AlexaForBusiness.StartDeviceSync"))
  if valid_612478 != nil:
    section.add "X-Amz-Target", valid_612478
  var valid_612479 = header.getOrDefault("X-Amz-Signature")
  valid_612479 = validateParameter(valid_612479, JString, required = false,
                                 default = nil)
  if valid_612479 != nil:
    section.add "X-Amz-Signature", valid_612479
  var valid_612480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612480 = validateParameter(valid_612480, JString, required = false,
                                 default = nil)
  if valid_612480 != nil:
    section.add "X-Amz-Content-Sha256", valid_612480
  var valid_612481 = header.getOrDefault("X-Amz-Date")
  valid_612481 = validateParameter(valid_612481, JString, required = false,
                                 default = nil)
  if valid_612481 != nil:
    section.add "X-Amz-Date", valid_612481
  var valid_612482 = header.getOrDefault("X-Amz-Credential")
  valid_612482 = validateParameter(valid_612482, JString, required = false,
                                 default = nil)
  if valid_612482 != nil:
    section.add "X-Amz-Credential", valid_612482
  var valid_612483 = header.getOrDefault("X-Amz-Security-Token")
  valid_612483 = validateParameter(valid_612483, JString, required = false,
                                 default = nil)
  if valid_612483 != nil:
    section.add "X-Amz-Security-Token", valid_612483
  var valid_612484 = header.getOrDefault("X-Amz-Algorithm")
  valid_612484 = validateParameter(valid_612484, JString, required = false,
                                 default = nil)
  if valid_612484 != nil:
    section.add "X-Amz-Algorithm", valid_612484
  var valid_612485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612485 = validateParameter(valid_612485, JString, required = false,
                                 default = nil)
  if valid_612485 != nil:
    section.add "X-Amz-SignedHeaders", valid_612485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612487: Call_StartDeviceSync_612475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets a device and its account to the known default settings. This clears all information and settings set by previous users in the following ways:</p> <ul> <li> <p>Bluetooth - This unpairs all bluetooth devices paired with your echo device.</p> </li> <li> <p>Volume - This resets the echo device's volume to the default value.</p> </li> <li> <p>Notifications - This clears all notifications from your echo device.</p> </li> <li> <p>Lists - This clears all to-do items from your echo device.</p> </li> <li> <p>Settings - This internally syncs the room's profile (if the device is assigned to a room), contacts, address books, delegation access for account linking, and communications (if enabled on the room profile).</p> </li> </ul>
  ## 
  let valid = call_612487.validator(path, query, header, formData, body)
  let scheme = call_612487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612487.url(scheme.get, call_612487.host, call_612487.base,
                         call_612487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612487, url, valid)

proc call*(call_612488: Call_StartDeviceSync_612475; body: JsonNode): Recallable =
  ## startDeviceSync
  ## <p>Resets a device and its account to the known default settings. This clears all information and settings set by previous users in the following ways:</p> <ul> <li> <p>Bluetooth - This unpairs all bluetooth devices paired with your echo device.</p> </li> <li> <p>Volume - This resets the echo device's volume to the default value.</p> </li> <li> <p>Notifications - This clears all notifications from your echo device.</p> </li> <li> <p>Lists - This clears all to-do items from your echo device.</p> </li> <li> <p>Settings - This internally syncs the room's profile (if the device is assigned to a room), contacts, address books, delegation access for account linking, and communications (if enabled on the room profile).</p> </li> </ul>
  ##   body: JObject (required)
  var body_612489 = newJObject()
  if body != nil:
    body_612489 = body
  result = call_612488.call(nil, nil, nil, nil, body_612489)

var startDeviceSync* = Call_StartDeviceSync_612475(name: "startDeviceSync",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.StartDeviceSync",
    validator: validate_StartDeviceSync_612476, base: "/", url: url_StartDeviceSync_612477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSmartHomeApplianceDiscovery_612490 = ref object of OpenApiRestCall_610658
proc url_StartSmartHomeApplianceDiscovery_612492(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartSmartHomeApplianceDiscovery_612491(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612493 = header.getOrDefault("X-Amz-Target")
  valid_612493 = validateParameter(valid_612493, JString, required = true, default = newJString(
      "AlexaForBusiness.StartSmartHomeApplianceDiscovery"))
  if valid_612493 != nil:
    section.add "X-Amz-Target", valid_612493
  var valid_612494 = header.getOrDefault("X-Amz-Signature")
  valid_612494 = validateParameter(valid_612494, JString, required = false,
                                 default = nil)
  if valid_612494 != nil:
    section.add "X-Amz-Signature", valid_612494
  var valid_612495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612495 = validateParameter(valid_612495, JString, required = false,
                                 default = nil)
  if valid_612495 != nil:
    section.add "X-Amz-Content-Sha256", valid_612495
  var valid_612496 = header.getOrDefault("X-Amz-Date")
  valid_612496 = validateParameter(valid_612496, JString, required = false,
                                 default = nil)
  if valid_612496 != nil:
    section.add "X-Amz-Date", valid_612496
  var valid_612497 = header.getOrDefault("X-Amz-Credential")
  valid_612497 = validateParameter(valid_612497, JString, required = false,
                                 default = nil)
  if valid_612497 != nil:
    section.add "X-Amz-Credential", valid_612497
  var valid_612498 = header.getOrDefault("X-Amz-Security-Token")
  valid_612498 = validateParameter(valid_612498, JString, required = false,
                                 default = nil)
  if valid_612498 != nil:
    section.add "X-Amz-Security-Token", valid_612498
  var valid_612499 = header.getOrDefault("X-Amz-Algorithm")
  valid_612499 = validateParameter(valid_612499, JString, required = false,
                                 default = nil)
  if valid_612499 != nil:
    section.add "X-Amz-Algorithm", valid_612499
  var valid_612500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612500 = validateParameter(valid_612500, JString, required = false,
                                 default = nil)
  if valid_612500 != nil:
    section.add "X-Amz-SignedHeaders", valid_612500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612502: Call_StartSmartHomeApplianceDiscovery_612490;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Initiates the discovery of any smart home appliances associated with the room.
  ## 
  let valid = call_612502.validator(path, query, header, formData, body)
  let scheme = call_612502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612502.url(scheme.get, call_612502.host, call_612502.base,
                         call_612502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612502, url, valid)

proc call*(call_612503: Call_StartSmartHomeApplianceDiscovery_612490;
          body: JsonNode): Recallable =
  ## startSmartHomeApplianceDiscovery
  ## Initiates the discovery of any smart home appliances associated with the room.
  ##   body: JObject (required)
  var body_612504 = newJObject()
  if body != nil:
    body_612504 = body
  result = call_612503.call(nil, nil, nil, nil, body_612504)

var startSmartHomeApplianceDiscovery* = Call_StartSmartHomeApplianceDiscovery_612490(
    name: "startSmartHomeApplianceDiscovery", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.StartSmartHomeApplianceDiscovery",
    validator: validate_StartSmartHomeApplianceDiscovery_612491, base: "/",
    url: url_StartSmartHomeApplianceDiscovery_612492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_612505 = ref object of OpenApiRestCall_610658
proc url_TagResource_612507(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_612506(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612508 = header.getOrDefault("X-Amz-Target")
  valid_612508 = validateParameter(valid_612508, JString, required = true, default = newJString(
      "AlexaForBusiness.TagResource"))
  if valid_612508 != nil:
    section.add "X-Amz-Target", valid_612508
  var valid_612509 = header.getOrDefault("X-Amz-Signature")
  valid_612509 = validateParameter(valid_612509, JString, required = false,
                                 default = nil)
  if valid_612509 != nil:
    section.add "X-Amz-Signature", valid_612509
  var valid_612510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612510 = validateParameter(valid_612510, JString, required = false,
                                 default = nil)
  if valid_612510 != nil:
    section.add "X-Amz-Content-Sha256", valid_612510
  var valid_612511 = header.getOrDefault("X-Amz-Date")
  valid_612511 = validateParameter(valid_612511, JString, required = false,
                                 default = nil)
  if valid_612511 != nil:
    section.add "X-Amz-Date", valid_612511
  var valid_612512 = header.getOrDefault("X-Amz-Credential")
  valid_612512 = validateParameter(valid_612512, JString, required = false,
                                 default = nil)
  if valid_612512 != nil:
    section.add "X-Amz-Credential", valid_612512
  var valid_612513 = header.getOrDefault("X-Amz-Security-Token")
  valid_612513 = validateParameter(valid_612513, JString, required = false,
                                 default = nil)
  if valid_612513 != nil:
    section.add "X-Amz-Security-Token", valid_612513
  var valid_612514 = header.getOrDefault("X-Amz-Algorithm")
  valid_612514 = validateParameter(valid_612514, JString, required = false,
                                 default = nil)
  if valid_612514 != nil:
    section.add "X-Amz-Algorithm", valid_612514
  var valid_612515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612515 = validateParameter(valid_612515, JString, required = false,
                                 default = nil)
  if valid_612515 != nil:
    section.add "X-Amz-SignedHeaders", valid_612515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612517: Call_TagResource_612505; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to a specified resource.
  ## 
  let valid = call_612517.validator(path, query, header, formData, body)
  let scheme = call_612517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612517.url(scheme.get, call_612517.host, call_612517.base,
                         call_612517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612517, url, valid)

proc call*(call_612518: Call_TagResource_612505; body: JsonNode): Recallable =
  ## tagResource
  ## Adds metadata tags to a specified resource.
  ##   body: JObject (required)
  var body_612519 = newJObject()
  if body != nil:
    body_612519 = body
  result = call_612518.call(nil, nil, nil, nil, body_612519)

var tagResource* = Call_TagResource_612505(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.TagResource",
                                        validator: validate_TagResource_612506,
                                        base: "/", url: url_TagResource_612507,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_612520 = ref object of OpenApiRestCall_610658
proc url_UntagResource_612522(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_612521(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612523 = header.getOrDefault("X-Amz-Target")
  valid_612523 = validateParameter(valid_612523, JString, required = true, default = newJString(
      "AlexaForBusiness.UntagResource"))
  if valid_612523 != nil:
    section.add "X-Amz-Target", valid_612523
  var valid_612524 = header.getOrDefault("X-Amz-Signature")
  valid_612524 = validateParameter(valid_612524, JString, required = false,
                                 default = nil)
  if valid_612524 != nil:
    section.add "X-Amz-Signature", valid_612524
  var valid_612525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612525 = validateParameter(valid_612525, JString, required = false,
                                 default = nil)
  if valid_612525 != nil:
    section.add "X-Amz-Content-Sha256", valid_612525
  var valid_612526 = header.getOrDefault("X-Amz-Date")
  valid_612526 = validateParameter(valid_612526, JString, required = false,
                                 default = nil)
  if valid_612526 != nil:
    section.add "X-Amz-Date", valid_612526
  var valid_612527 = header.getOrDefault("X-Amz-Credential")
  valid_612527 = validateParameter(valid_612527, JString, required = false,
                                 default = nil)
  if valid_612527 != nil:
    section.add "X-Amz-Credential", valid_612527
  var valid_612528 = header.getOrDefault("X-Amz-Security-Token")
  valid_612528 = validateParameter(valid_612528, JString, required = false,
                                 default = nil)
  if valid_612528 != nil:
    section.add "X-Amz-Security-Token", valid_612528
  var valid_612529 = header.getOrDefault("X-Amz-Algorithm")
  valid_612529 = validateParameter(valid_612529, JString, required = false,
                                 default = nil)
  if valid_612529 != nil:
    section.add "X-Amz-Algorithm", valid_612529
  var valid_612530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612530 = validateParameter(valid_612530, JString, required = false,
                                 default = nil)
  if valid_612530 != nil:
    section.add "X-Amz-SignedHeaders", valid_612530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612532: Call_UntagResource_612520; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from a specified resource.
  ## 
  let valid = call_612532.validator(path, query, header, formData, body)
  let scheme = call_612532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612532.url(scheme.get, call_612532.host, call_612532.base,
                         call_612532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612532, url, valid)

proc call*(call_612533: Call_UntagResource_612520; body: JsonNode): Recallable =
  ## untagResource
  ## Removes metadata tags from a specified resource.
  ##   body: JObject (required)
  var body_612534 = newJObject()
  if body != nil:
    body_612534 = body
  result = call_612533.call(nil, nil, nil, nil, body_612534)

var untagResource* = Call_UntagResource_612520(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UntagResource",
    validator: validate_UntagResource_612521, base: "/", url: url_UntagResource_612522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAddressBook_612535 = ref object of OpenApiRestCall_610658
proc url_UpdateAddressBook_612537(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAddressBook_612536(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612538 = header.getOrDefault("X-Amz-Target")
  valid_612538 = validateParameter(valid_612538, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateAddressBook"))
  if valid_612538 != nil:
    section.add "X-Amz-Target", valid_612538
  var valid_612539 = header.getOrDefault("X-Amz-Signature")
  valid_612539 = validateParameter(valid_612539, JString, required = false,
                                 default = nil)
  if valid_612539 != nil:
    section.add "X-Amz-Signature", valid_612539
  var valid_612540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612540 = validateParameter(valid_612540, JString, required = false,
                                 default = nil)
  if valid_612540 != nil:
    section.add "X-Amz-Content-Sha256", valid_612540
  var valid_612541 = header.getOrDefault("X-Amz-Date")
  valid_612541 = validateParameter(valid_612541, JString, required = false,
                                 default = nil)
  if valid_612541 != nil:
    section.add "X-Amz-Date", valid_612541
  var valid_612542 = header.getOrDefault("X-Amz-Credential")
  valid_612542 = validateParameter(valid_612542, JString, required = false,
                                 default = nil)
  if valid_612542 != nil:
    section.add "X-Amz-Credential", valid_612542
  var valid_612543 = header.getOrDefault("X-Amz-Security-Token")
  valid_612543 = validateParameter(valid_612543, JString, required = false,
                                 default = nil)
  if valid_612543 != nil:
    section.add "X-Amz-Security-Token", valid_612543
  var valid_612544 = header.getOrDefault("X-Amz-Algorithm")
  valid_612544 = validateParameter(valid_612544, JString, required = false,
                                 default = nil)
  if valid_612544 != nil:
    section.add "X-Amz-Algorithm", valid_612544
  var valid_612545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612545 = validateParameter(valid_612545, JString, required = false,
                                 default = nil)
  if valid_612545 != nil:
    section.add "X-Amz-SignedHeaders", valid_612545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612547: Call_UpdateAddressBook_612535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates address book details by the address book ARN.
  ## 
  let valid = call_612547.validator(path, query, header, formData, body)
  let scheme = call_612547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612547.url(scheme.get, call_612547.host, call_612547.base,
                         call_612547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612547, url, valid)

proc call*(call_612548: Call_UpdateAddressBook_612535; body: JsonNode): Recallable =
  ## updateAddressBook
  ## Updates address book details by the address book ARN.
  ##   body: JObject (required)
  var body_612549 = newJObject()
  if body != nil:
    body_612549 = body
  result = call_612548.call(nil, nil, nil, nil, body_612549)

var updateAddressBook* = Call_UpdateAddressBook_612535(name: "updateAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateAddressBook",
    validator: validate_UpdateAddressBook_612536, base: "/",
    url: url_UpdateAddressBook_612537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBusinessReportSchedule_612550 = ref object of OpenApiRestCall_610658
proc url_UpdateBusinessReportSchedule_612552(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateBusinessReportSchedule_612551(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612553 = header.getOrDefault("X-Amz-Target")
  valid_612553 = validateParameter(valid_612553, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateBusinessReportSchedule"))
  if valid_612553 != nil:
    section.add "X-Amz-Target", valid_612553
  var valid_612554 = header.getOrDefault("X-Amz-Signature")
  valid_612554 = validateParameter(valid_612554, JString, required = false,
                                 default = nil)
  if valid_612554 != nil:
    section.add "X-Amz-Signature", valid_612554
  var valid_612555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612555 = validateParameter(valid_612555, JString, required = false,
                                 default = nil)
  if valid_612555 != nil:
    section.add "X-Amz-Content-Sha256", valid_612555
  var valid_612556 = header.getOrDefault("X-Amz-Date")
  valid_612556 = validateParameter(valid_612556, JString, required = false,
                                 default = nil)
  if valid_612556 != nil:
    section.add "X-Amz-Date", valid_612556
  var valid_612557 = header.getOrDefault("X-Amz-Credential")
  valid_612557 = validateParameter(valid_612557, JString, required = false,
                                 default = nil)
  if valid_612557 != nil:
    section.add "X-Amz-Credential", valid_612557
  var valid_612558 = header.getOrDefault("X-Amz-Security-Token")
  valid_612558 = validateParameter(valid_612558, JString, required = false,
                                 default = nil)
  if valid_612558 != nil:
    section.add "X-Amz-Security-Token", valid_612558
  var valid_612559 = header.getOrDefault("X-Amz-Algorithm")
  valid_612559 = validateParameter(valid_612559, JString, required = false,
                                 default = nil)
  if valid_612559 != nil:
    section.add "X-Amz-Algorithm", valid_612559
  var valid_612560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612560 = validateParameter(valid_612560, JString, required = false,
                                 default = nil)
  if valid_612560 != nil:
    section.add "X-Amz-SignedHeaders", valid_612560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612562: Call_UpdateBusinessReportSchedule_612550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration of the report delivery schedule with the specified schedule ARN.
  ## 
  let valid = call_612562.validator(path, query, header, formData, body)
  let scheme = call_612562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612562.url(scheme.get, call_612562.host, call_612562.base,
                         call_612562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612562, url, valid)

proc call*(call_612563: Call_UpdateBusinessReportSchedule_612550; body: JsonNode): Recallable =
  ## updateBusinessReportSchedule
  ## Updates the configuration of the report delivery schedule with the specified schedule ARN.
  ##   body: JObject (required)
  var body_612564 = newJObject()
  if body != nil:
    body_612564 = body
  result = call_612563.call(nil, nil, nil, nil, body_612564)

var updateBusinessReportSchedule* = Call_UpdateBusinessReportSchedule_612550(
    name: "updateBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateBusinessReportSchedule",
    validator: validate_UpdateBusinessReportSchedule_612551, base: "/",
    url: url_UpdateBusinessReportSchedule_612552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConferenceProvider_612565 = ref object of OpenApiRestCall_610658
proc url_UpdateConferenceProvider_612567(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateConferenceProvider_612566(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612568 = header.getOrDefault("X-Amz-Target")
  valid_612568 = validateParameter(valid_612568, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateConferenceProvider"))
  if valid_612568 != nil:
    section.add "X-Amz-Target", valid_612568
  var valid_612569 = header.getOrDefault("X-Amz-Signature")
  valid_612569 = validateParameter(valid_612569, JString, required = false,
                                 default = nil)
  if valid_612569 != nil:
    section.add "X-Amz-Signature", valid_612569
  var valid_612570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612570 = validateParameter(valid_612570, JString, required = false,
                                 default = nil)
  if valid_612570 != nil:
    section.add "X-Amz-Content-Sha256", valid_612570
  var valid_612571 = header.getOrDefault("X-Amz-Date")
  valid_612571 = validateParameter(valid_612571, JString, required = false,
                                 default = nil)
  if valid_612571 != nil:
    section.add "X-Amz-Date", valid_612571
  var valid_612572 = header.getOrDefault("X-Amz-Credential")
  valid_612572 = validateParameter(valid_612572, JString, required = false,
                                 default = nil)
  if valid_612572 != nil:
    section.add "X-Amz-Credential", valid_612572
  var valid_612573 = header.getOrDefault("X-Amz-Security-Token")
  valid_612573 = validateParameter(valid_612573, JString, required = false,
                                 default = nil)
  if valid_612573 != nil:
    section.add "X-Amz-Security-Token", valid_612573
  var valid_612574 = header.getOrDefault("X-Amz-Algorithm")
  valid_612574 = validateParameter(valid_612574, JString, required = false,
                                 default = nil)
  if valid_612574 != nil:
    section.add "X-Amz-Algorithm", valid_612574
  var valid_612575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612575 = validateParameter(valid_612575, JString, required = false,
                                 default = nil)
  if valid_612575 != nil:
    section.add "X-Amz-SignedHeaders", valid_612575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612577: Call_UpdateConferenceProvider_612565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing conference provider's settings.
  ## 
  let valid = call_612577.validator(path, query, header, formData, body)
  let scheme = call_612577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612577.url(scheme.get, call_612577.host, call_612577.base,
                         call_612577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612577, url, valid)

proc call*(call_612578: Call_UpdateConferenceProvider_612565; body: JsonNode): Recallable =
  ## updateConferenceProvider
  ## Updates an existing conference provider's settings.
  ##   body: JObject (required)
  var body_612579 = newJObject()
  if body != nil:
    body_612579 = body
  result = call_612578.call(nil, nil, nil, nil, body_612579)

var updateConferenceProvider* = Call_UpdateConferenceProvider_612565(
    name: "updateConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateConferenceProvider",
    validator: validate_UpdateConferenceProvider_612566, base: "/",
    url: url_UpdateConferenceProvider_612567, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContact_612580 = ref object of OpenApiRestCall_610658
proc url_UpdateContact_612582(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateContact_612581(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612583 = header.getOrDefault("X-Amz-Target")
  valid_612583 = validateParameter(valid_612583, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateContact"))
  if valid_612583 != nil:
    section.add "X-Amz-Target", valid_612583
  var valid_612584 = header.getOrDefault("X-Amz-Signature")
  valid_612584 = validateParameter(valid_612584, JString, required = false,
                                 default = nil)
  if valid_612584 != nil:
    section.add "X-Amz-Signature", valid_612584
  var valid_612585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612585 = validateParameter(valid_612585, JString, required = false,
                                 default = nil)
  if valid_612585 != nil:
    section.add "X-Amz-Content-Sha256", valid_612585
  var valid_612586 = header.getOrDefault("X-Amz-Date")
  valid_612586 = validateParameter(valid_612586, JString, required = false,
                                 default = nil)
  if valid_612586 != nil:
    section.add "X-Amz-Date", valid_612586
  var valid_612587 = header.getOrDefault("X-Amz-Credential")
  valid_612587 = validateParameter(valid_612587, JString, required = false,
                                 default = nil)
  if valid_612587 != nil:
    section.add "X-Amz-Credential", valid_612587
  var valid_612588 = header.getOrDefault("X-Amz-Security-Token")
  valid_612588 = validateParameter(valid_612588, JString, required = false,
                                 default = nil)
  if valid_612588 != nil:
    section.add "X-Amz-Security-Token", valid_612588
  var valid_612589 = header.getOrDefault("X-Amz-Algorithm")
  valid_612589 = validateParameter(valid_612589, JString, required = false,
                                 default = nil)
  if valid_612589 != nil:
    section.add "X-Amz-Algorithm", valid_612589
  var valid_612590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612590 = validateParameter(valid_612590, JString, required = false,
                                 default = nil)
  if valid_612590 != nil:
    section.add "X-Amz-SignedHeaders", valid_612590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612592: Call_UpdateContact_612580; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the contact details by the contact ARN.
  ## 
  let valid = call_612592.validator(path, query, header, formData, body)
  let scheme = call_612592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612592.url(scheme.get, call_612592.host, call_612592.base,
                         call_612592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612592, url, valid)

proc call*(call_612593: Call_UpdateContact_612580; body: JsonNode): Recallable =
  ## updateContact
  ## Updates the contact details by the contact ARN.
  ##   body: JObject (required)
  var body_612594 = newJObject()
  if body != nil:
    body_612594 = body
  result = call_612593.call(nil, nil, nil, nil, body_612594)

var updateContact* = Call_UpdateContact_612580(name: "updateContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateContact",
    validator: validate_UpdateContact_612581, base: "/", url: url_UpdateContact_612582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevice_612595 = ref object of OpenApiRestCall_610658
proc url_UpdateDevice_612597(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDevice_612596(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612598 = header.getOrDefault("X-Amz-Target")
  valid_612598 = validateParameter(valid_612598, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateDevice"))
  if valid_612598 != nil:
    section.add "X-Amz-Target", valid_612598
  var valid_612599 = header.getOrDefault("X-Amz-Signature")
  valid_612599 = validateParameter(valid_612599, JString, required = false,
                                 default = nil)
  if valid_612599 != nil:
    section.add "X-Amz-Signature", valid_612599
  var valid_612600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612600 = validateParameter(valid_612600, JString, required = false,
                                 default = nil)
  if valid_612600 != nil:
    section.add "X-Amz-Content-Sha256", valid_612600
  var valid_612601 = header.getOrDefault("X-Amz-Date")
  valid_612601 = validateParameter(valid_612601, JString, required = false,
                                 default = nil)
  if valid_612601 != nil:
    section.add "X-Amz-Date", valid_612601
  var valid_612602 = header.getOrDefault("X-Amz-Credential")
  valid_612602 = validateParameter(valid_612602, JString, required = false,
                                 default = nil)
  if valid_612602 != nil:
    section.add "X-Amz-Credential", valid_612602
  var valid_612603 = header.getOrDefault("X-Amz-Security-Token")
  valid_612603 = validateParameter(valid_612603, JString, required = false,
                                 default = nil)
  if valid_612603 != nil:
    section.add "X-Amz-Security-Token", valid_612603
  var valid_612604 = header.getOrDefault("X-Amz-Algorithm")
  valid_612604 = validateParameter(valid_612604, JString, required = false,
                                 default = nil)
  if valid_612604 != nil:
    section.add "X-Amz-Algorithm", valid_612604
  var valid_612605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612605 = validateParameter(valid_612605, JString, required = false,
                                 default = nil)
  if valid_612605 != nil:
    section.add "X-Amz-SignedHeaders", valid_612605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612607: Call_UpdateDevice_612595; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the device name by device ARN.
  ## 
  let valid = call_612607.validator(path, query, header, formData, body)
  let scheme = call_612607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612607.url(scheme.get, call_612607.host, call_612607.base,
                         call_612607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612607, url, valid)

proc call*(call_612608: Call_UpdateDevice_612595; body: JsonNode): Recallable =
  ## updateDevice
  ## Updates the device name by device ARN.
  ##   body: JObject (required)
  var body_612609 = newJObject()
  if body != nil:
    body_612609 = body
  result = call_612608.call(nil, nil, nil, nil, body_612609)

var updateDevice* = Call_UpdateDevice_612595(name: "updateDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateDevice",
    validator: validate_UpdateDevice_612596, base: "/", url: url_UpdateDevice_612597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGateway_612610 = ref object of OpenApiRestCall_610658
proc url_UpdateGateway_612612(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGateway_612611(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612613 = header.getOrDefault("X-Amz-Target")
  valid_612613 = validateParameter(valid_612613, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateGateway"))
  if valid_612613 != nil:
    section.add "X-Amz-Target", valid_612613
  var valid_612614 = header.getOrDefault("X-Amz-Signature")
  valid_612614 = validateParameter(valid_612614, JString, required = false,
                                 default = nil)
  if valid_612614 != nil:
    section.add "X-Amz-Signature", valid_612614
  var valid_612615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612615 = validateParameter(valid_612615, JString, required = false,
                                 default = nil)
  if valid_612615 != nil:
    section.add "X-Amz-Content-Sha256", valid_612615
  var valid_612616 = header.getOrDefault("X-Amz-Date")
  valid_612616 = validateParameter(valid_612616, JString, required = false,
                                 default = nil)
  if valid_612616 != nil:
    section.add "X-Amz-Date", valid_612616
  var valid_612617 = header.getOrDefault("X-Amz-Credential")
  valid_612617 = validateParameter(valid_612617, JString, required = false,
                                 default = nil)
  if valid_612617 != nil:
    section.add "X-Amz-Credential", valid_612617
  var valid_612618 = header.getOrDefault("X-Amz-Security-Token")
  valid_612618 = validateParameter(valid_612618, JString, required = false,
                                 default = nil)
  if valid_612618 != nil:
    section.add "X-Amz-Security-Token", valid_612618
  var valid_612619 = header.getOrDefault("X-Amz-Algorithm")
  valid_612619 = validateParameter(valid_612619, JString, required = false,
                                 default = nil)
  if valid_612619 != nil:
    section.add "X-Amz-Algorithm", valid_612619
  var valid_612620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612620 = validateParameter(valid_612620, JString, required = false,
                                 default = nil)
  if valid_612620 != nil:
    section.add "X-Amz-SignedHeaders", valid_612620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612622: Call_UpdateGateway_612610; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details of a gateway. If any optional field is not provided, the existing corresponding value is left unmodified.
  ## 
  let valid = call_612622.validator(path, query, header, formData, body)
  let scheme = call_612622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612622.url(scheme.get, call_612622.host, call_612622.base,
                         call_612622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612622, url, valid)

proc call*(call_612623: Call_UpdateGateway_612610; body: JsonNode): Recallable =
  ## updateGateway
  ## Updates the details of a gateway. If any optional field is not provided, the existing corresponding value is left unmodified.
  ##   body: JObject (required)
  var body_612624 = newJObject()
  if body != nil:
    body_612624 = body
  result = call_612623.call(nil, nil, nil, nil, body_612624)

var updateGateway* = Call_UpdateGateway_612610(name: "updateGateway",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateGateway",
    validator: validate_UpdateGateway_612611, base: "/", url: url_UpdateGateway_612612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayGroup_612625 = ref object of OpenApiRestCall_610658
proc url_UpdateGatewayGroup_612627(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGatewayGroup_612626(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612628 = header.getOrDefault("X-Amz-Target")
  valid_612628 = validateParameter(valid_612628, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateGatewayGroup"))
  if valid_612628 != nil:
    section.add "X-Amz-Target", valid_612628
  var valid_612629 = header.getOrDefault("X-Amz-Signature")
  valid_612629 = validateParameter(valid_612629, JString, required = false,
                                 default = nil)
  if valid_612629 != nil:
    section.add "X-Amz-Signature", valid_612629
  var valid_612630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612630 = validateParameter(valid_612630, JString, required = false,
                                 default = nil)
  if valid_612630 != nil:
    section.add "X-Amz-Content-Sha256", valid_612630
  var valid_612631 = header.getOrDefault("X-Amz-Date")
  valid_612631 = validateParameter(valid_612631, JString, required = false,
                                 default = nil)
  if valid_612631 != nil:
    section.add "X-Amz-Date", valid_612631
  var valid_612632 = header.getOrDefault("X-Amz-Credential")
  valid_612632 = validateParameter(valid_612632, JString, required = false,
                                 default = nil)
  if valid_612632 != nil:
    section.add "X-Amz-Credential", valid_612632
  var valid_612633 = header.getOrDefault("X-Amz-Security-Token")
  valid_612633 = validateParameter(valid_612633, JString, required = false,
                                 default = nil)
  if valid_612633 != nil:
    section.add "X-Amz-Security-Token", valid_612633
  var valid_612634 = header.getOrDefault("X-Amz-Algorithm")
  valid_612634 = validateParameter(valid_612634, JString, required = false,
                                 default = nil)
  if valid_612634 != nil:
    section.add "X-Amz-Algorithm", valid_612634
  var valid_612635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612635 = validateParameter(valid_612635, JString, required = false,
                                 default = nil)
  if valid_612635 != nil:
    section.add "X-Amz-SignedHeaders", valid_612635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612637: Call_UpdateGatewayGroup_612625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details of a gateway group. If any optional field is not provided, the existing corresponding value is left unmodified.
  ## 
  let valid = call_612637.validator(path, query, header, formData, body)
  let scheme = call_612637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612637.url(scheme.get, call_612637.host, call_612637.base,
                         call_612637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612637, url, valid)

proc call*(call_612638: Call_UpdateGatewayGroup_612625; body: JsonNode): Recallable =
  ## updateGatewayGroup
  ## Updates the details of a gateway group. If any optional field is not provided, the existing corresponding value is left unmodified.
  ##   body: JObject (required)
  var body_612639 = newJObject()
  if body != nil:
    body_612639 = body
  result = call_612638.call(nil, nil, nil, nil, body_612639)

var updateGatewayGroup* = Call_UpdateGatewayGroup_612625(
    name: "updateGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateGatewayGroup",
    validator: validate_UpdateGatewayGroup_612626, base: "/",
    url: url_UpdateGatewayGroup_612627, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_612640 = ref object of OpenApiRestCall_610658
proc url_UpdateNetworkProfile_612642(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNetworkProfile_612641(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612643 = header.getOrDefault("X-Amz-Target")
  valid_612643 = validateParameter(valid_612643, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateNetworkProfile"))
  if valid_612643 != nil:
    section.add "X-Amz-Target", valid_612643
  var valid_612644 = header.getOrDefault("X-Amz-Signature")
  valid_612644 = validateParameter(valid_612644, JString, required = false,
                                 default = nil)
  if valid_612644 != nil:
    section.add "X-Amz-Signature", valid_612644
  var valid_612645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612645 = validateParameter(valid_612645, JString, required = false,
                                 default = nil)
  if valid_612645 != nil:
    section.add "X-Amz-Content-Sha256", valid_612645
  var valid_612646 = header.getOrDefault("X-Amz-Date")
  valid_612646 = validateParameter(valid_612646, JString, required = false,
                                 default = nil)
  if valid_612646 != nil:
    section.add "X-Amz-Date", valid_612646
  var valid_612647 = header.getOrDefault("X-Amz-Credential")
  valid_612647 = validateParameter(valid_612647, JString, required = false,
                                 default = nil)
  if valid_612647 != nil:
    section.add "X-Amz-Credential", valid_612647
  var valid_612648 = header.getOrDefault("X-Amz-Security-Token")
  valid_612648 = validateParameter(valid_612648, JString, required = false,
                                 default = nil)
  if valid_612648 != nil:
    section.add "X-Amz-Security-Token", valid_612648
  var valid_612649 = header.getOrDefault("X-Amz-Algorithm")
  valid_612649 = validateParameter(valid_612649, JString, required = false,
                                 default = nil)
  if valid_612649 != nil:
    section.add "X-Amz-Algorithm", valid_612649
  var valid_612650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612650 = validateParameter(valid_612650, JString, required = false,
                                 default = nil)
  if valid_612650 != nil:
    section.add "X-Amz-SignedHeaders", valid_612650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612652: Call_UpdateNetworkProfile_612640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a network profile by the network profile ARN.
  ## 
  let valid = call_612652.validator(path, query, header, formData, body)
  let scheme = call_612652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612652.url(scheme.get, call_612652.host, call_612652.base,
                         call_612652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612652, url, valid)

proc call*(call_612653: Call_UpdateNetworkProfile_612640; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates a network profile by the network profile ARN.
  ##   body: JObject (required)
  var body_612654 = newJObject()
  if body != nil:
    body_612654 = body
  result = call_612653.call(nil, nil, nil, nil, body_612654)

var updateNetworkProfile* = Call_UpdateNetworkProfile_612640(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_612641, base: "/",
    url: url_UpdateNetworkProfile_612642, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProfile_612655 = ref object of OpenApiRestCall_610658
proc url_UpdateProfile_612657(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProfile_612656(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612658 = header.getOrDefault("X-Amz-Target")
  valid_612658 = validateParameter(valid_612658, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateProfile"))
  if valid_612658 != nil:
    section.add "X-Amz-Target", valid_612658
  var valid_612659 = header.getOrDefault("X-Amz-Signature")
  valid_612659 = validateParameter(valid_612659, JString, required = false,
                                 default = nil)
  if valid_612659 != nil:
    section.add "X-Amz-Signature", valid_612659
  var valid_612660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612660 = validateParameter(valid_612660, JString, required = false,
                                 default = nil)
  if valid_612660 != nil:
    section.add "X-Amz-Content-Sha256", valid_612660
  var valid_612661 = header.getOrDefault("X-Amz-Date")
  valid_612661 = validateParameter(valid_612661, JString, required = false,
                                 default = nil)
  if valid_612661 != nil:
    section.add "X-Amz-Date", valid_612661
  var valid_612662 = header.getOrDefault("X-Amz-Credential")
  valid_612662 = validateParameter(valid_612662, JString, required = false,
                                 default = nil)
  if valid_612662 != nil:
    section.add "X-Amz-Credential", valid_612662
  var valid_612663 = header.getOrDefault("X-Amz-Security-Token")
  valid_612663 = validateParameter(valid_612663, JString, required = false,
                                 default = nil)
  if valid_612663 != nil:
    section.add "X-Amz-Security-Token", valid_612663
  var valid_612664 = header.getOrDefault("X-Amz-Algorithm")
  valid_612664 = validateParameter(valid_612664, JString, required = false,
                                 default = nil)
  if valid_612664 != nil:
    section.add "X-Amz-Algorithm", valid_612664
  var valid_612665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612665 = validateParameter(valid_612665, JString, required = false,
                                 default = nil)
  if valid_612665 != nil:
    section.add "X-Amz-SignedHeaders", valid_612665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612667: Call_UpdateProfile_612655; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing room profile by room profile ARN.
  ## 
  let valid = call_612667.validator(path, query, header, formData, body)
  let scheme = call_612667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612667.url(scheme.get, call_612667.host, call_612667.base,
                         call_612667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612667, url, valid)

proc call*(call_612668: Call_UpdateProfile_612655; body: JsonNode): Recallable =
  ## updateProfile
  ## Updates an existing room profile by room profile ARN.
  ##   body: JObject (required)
  var body_612669 = newJObject()
  if body != nil:
    body_612669 = body
  result = call_612668.call(nil, nil, nil, nil, body_612669)

var updateProfile* = Call_UpdateProfile_612655(name: "updateProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateProfile",
    validator: validate_UpdateProfile_612656, base: "/", url: url_UpdateProfile_612657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoom_612670 = ref object of OpenApiRestCall_610658
proc url_UpdateRoom_612672(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRoom_612671(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612673 = header.getOrDefault("X-Amz-Target")
  valid_612673 = validateParameter(valid_612673, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateRoom"))
  if valid_612673 != nil:
    section.add "X-Amz-Target", valid_612673
  var valid_612674 = header.getOrDefault("X-Amz-Signature")
  valid_612674 = validateParameter(valid_612674, JString, required = false,
                                 default = nil)
  if valid_612674 != nil:
    section.add "X-Amz-Signature", valid_612674
  var valid_612675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612675 = validateParameter(valid_612675, JString, required = false,
                                 default = nil)
  if valid_612675 != nil:
    section.add "X-Amz-Content-Sha256", valid_612675
  var valid_612676 = header.getOrDefault("X-Amz-Date")
  valid_612676 = validateParameter(valid_612676, JString, required = false,
                                 default = nil)
  if valid_612676 != nil:
    section.add "X-Amz-Date", valid_612676
  var valid_612677 = header.getOrDefault("X-Amz-Credential")
  valid_612677 = validateParameter(valid_612677, JString, required = false,
                                 default = nil)
  if valid_612677 != nil:
    section.add "X-Amz-Credential", valid_612677
  var valid_612678 = header.getOrDefault("X-Amz-Security-Token")
  valid_612678 = validateParameter(valid_612678, JString, required = false,
                                 default = nil)
  if valid_612678 != nil:
    section.add "X-Amz-Security-Token", valid_612678
  var valid_612679 = header.getOrDefault("X-Amz-Algorithm")
  valid_612679 = validateParameter(valid_612679, JString, required = false,
                                 default = nil)
  if valid_612679 != nil:
    section.add "X-Amz-Algorithm", valid_612679
  var valid_612680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612680 = validateParameter(valid_612680, JString, required = false,
                                 default = nil)
  if valid_612680 != nil:
    section.add "X-Amz-SignedHeaders", valid_612680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612682: Call_UpdateRoom_612670; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room details by room ARN.
  ## 
  let valid = call_612682.validator(path, query, header, formData, body)
  let scheme = call_612682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612682.url(scheme.get, call_612682.host, call_612682.base,
                         call_612682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612682, url, valid)

proc call*(call_612683: Call_UpdateRoom_612670; body: JsonNode): Recallable =
  ## updateRoom
  ## Updates room details by room ARN.
  ##   body: JObject (required)
  var body_612684 = newJObject()
  if body != nil:
    body_612684 = body
  result = call_612683.call(nil, nil, nil, nil, body_612684)

var updateRoom* = Call_UpdateRoom_612670(name: "updateRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.UpdateRoom",
                                      validator: validate_UpdateRoom_612671,
                                      base: "/", url: url_UpdateRoom_612672,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSkillGroup_612685 = ref object of OpenApiRestCall_610658
proc url_UpdateSkillGroup_612687(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSkillGroup_612686(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612688 = header.getOrDefault("X-Amz-Target")
  valid_612688 = validateParameter(valid_612688, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateSkillGroup"))
  if valid_612688 != nil:
    section.add "X-Amz-Target", valid_612688
  var valid_612689 = header.getOrDefault("X-Amz-Signature")
  valid_612689 = validateParameter(valid_612689, JString, required = false,
                                 default = nil)
  if valid_612689 != nil:
    section.add "X-Amz-Signature", valid_612689
  var valid_612690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612690 = validateParameter(valid_612690, JString, required = false,
                                 default = nil)
  if valid_612690 != nil:
    section.add "X-Amz-Content-Sha256", valid_612690
  var valid_612691 = header.getOrDefault("X-Amz-Date")
  valid_612691 = validateParameter(valid_612691, JString, required = false,
                                 default = nil)
  if valid_612691 != nil:
    section.add "X-Amz-Date", valid_612691
  var valid_612692 = header.getOrDefault("X-Amz-Credential")
  valid_612692 = validateParameter(valid_612692, JString, required = false,
                                 default = nil)
  if valid_612692 != nil:
    section.add "X-Amz-Credential", valid_612692
  var valid_612693 = header.getOrDefault("X-Amz-Security-Token")
  valid_612693 = validateParameter(valid_612693, JString, required = false,
                                 default = nil)
  if valid_612693 != nil:
    section.add "X-Amz-Security-Token", valid_612693
  var valid_612694 = header.getOrDefault("X-Amz-Algorithm")
  valid_612694 = validateParameter(valid_612694, JString, required = false,
                                 default = nil)
  if valid_612694 != nil:
    section.add "X-Amz-Algorithm", valid_612694
  var valid_612695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612695 = validateParameter(valid_612695, JString, required = false,
                                 default = nil)
  if valid_612695 != nil:
    section.add "X-Amz-SignedHeaders", valid_612695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612697: Call_UpdateSkillGroup_612685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates skill group details by skill group ARN.
  ## 
  let valid = call_612697.validator(path, query, header, formData, body)
  let scheme = call_612697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612697.url(scheme.get, call_612697.host, call_612697.base,
                         call_612697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612697, url, valid)

proc call*(call_612698: Call_UpdateSkillGroup_612685; body: JsonNode): Recallable =
  ## updateSkillGroup
  ## Updates skill group details by skill group ARN.
  ##   body: JObject (required)
  var body_612699 = newJObject()
  if body != nil:
    body_612699 = body
  result = call_612698.call(nil, nil, nil, nil, body_612699)

var updateSkillGroup* = Call_UpdateSkillGroup_612685(name: "updateSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateSkillGroup",
    validator: validate_UpdateSkillGroup_612686, base: "/",
    url: url_UpdateSkillGroup_612687, schemes: {Scheme.Https, Scheme.Http})
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
