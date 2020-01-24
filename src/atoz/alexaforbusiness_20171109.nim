
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

  OpenApiRestCall_606589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_606589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_606589): Option[Scheme] {.used.} =
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
  Call_ApproveSkill_606927 = ref object of OpenApiRestCall_606589
proc url_ApproveSkill_606929(protocol: Scheme; host: string; base: string;
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

proc validate_ApproveSkill_606928(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607054 = header.getOrDefault("X-Amz-Target")
  valid_607054 = validateParameter(valid_607054, JString, required = true, default = newJString(
      "AlexaForBusiness.ApproveSkill"))
  if valid_607054 != nil:
    section.add "X-Amz-Target", valid_607054
  var valid_607055 = header.getOrDefault("X-Amz-Signature")
  valid_607055 = validateParameter(valid_607055, JString, required = false,
                                 default = nil)
  if valid_607055 != nil:
    section.add "X-Amz-Signature", valid_607055
  var valid_607056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607056 = validateParameter(valid_607056, JString, required = false,
                                 default = nil)
  if valid_607056 != nil:
    section.add "X-Amz-Content-Sha256", valid_607056
  var valid_607057 = header.getOrDefault("X-Amz-Date")
  valid_607057 = validateParameter(valid_607057, JString, required = false,
                                 default = nil)
  if valid_607057 != nil:
    section.add "X-Amz-Date", valid_607057
  var valid_607058 = header.getOrDefault("X-Amz-Credential")
  valid_607058 = validateParameter(valid_607058, JString, required = false,
                                 default = nil)
  if valid_607058 != nil:
    section.add "X-Amz-Credential", valid_607058
  var valid_607059 = header.getOrDefault("X-Amz-Security-Token")
  valid_607059 = validateParameter(valid_607059, JString, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "X-Amz-Security-Token", valid_607059
  var valid_607060 = header.getOrDefault("X-Amz-Algorithm")
  valid_607060 = validateParameter(valid_607060, JString, required = false,
                                 default = nil)
  if valid_607060 != nil:
    section.add "X-Amz-Algorithm", valid_607060
  var valid_607061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-SignedHeaders", valid_607061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607085: Call_ApproveSkill_606927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill with the organization under the customer's AWS account. If a skill is private, the user implicitly accepts access to this skill during enablement.
  ## 
  let valid = call_607085.validator(path, query, header, formData, body)
  let scheme = call_607085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607085.url(scheme.get, call_607085.host, call_607085.base,
                         call_607085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607085, url, valid)

proc call*(call_607156: Call_ApproveSkill_606927; body: JsonNode): Recallable =
  ## approveSkill
  ## Associates a skill with the organization under the customer's AWS account. If a skill is private, the user implicitly accepts access to this skill during enablement.
  ##   body: JObject (required)
  var body_607157 = newJObject()
  if body != nil:
    body_607157 = body
  result = call_607156.call(nil, nil, nil, nil, body_607157)

var approveSkill* = Call_ApproveSkill_606927(name: "approveSkill",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ApproveSkill",
    validator: validate_ApproveSkill_606928, base: "/", url: url_ApproveSkill_606929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateContactWithAddressBook_607196 = ref object of OpenApiRestCall_606589
proc url_AssociateContactWithAddressBook_607198(protocol: Scheme; host: string;
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

proc validate_AssociateContactWithAddressBook_607197(path: JsonNode;
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
  var valid_607199 = header.getOrDefault("X-Amz-Target")
  valid_607199 = validateParameter(valid_607199, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateContactWithAddressBook"))
  if valid_607199 != nil:
    section.add "X-Amz-Target", valid_607199
  var valid_607200 = header.getOrDefault("X-Amz-Signature")
  valid_607200 = validateParameter(valid_607200, JString, required = false,
                                 default = nil)
  if valid_607200 != nil:
    section.add "X-Amz-Signature", valid_607200
  var valid_607201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607201 = validateParameter(valid_607201, JString, required = false,
                                 default = nil)
  if valid_607201 != nil:
    section.add "X-Amz-Content-Sha256", valid_607201
  var valid_607202 = header.getOrDefault("X-Amz-Date")
  valid_607202 = validateParameter(valid_607202, JString, required = false,
                                 default = nil)
  if valid_607202 != nil:
    section.add "X-Amz-Date", valid_607202
  var valid_607203 = header.getOrDefault("X-Amz-Credential")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-Credential", valid_607203
  var valid_607204 = header.getOrDefault("X-Amz-Security-Token")
  valid_607204 = validateParameter(valid_607204, JString, required = false,
                                 default = nil)
  if valid_607204 != nil:
    section.add "X-Amz-Security-Token", valid_607204
  var valid_607205 = header.getOrDefault("X-Amz-Algorithm")
  valid_607205 = validateParameter(valid_607205, JString, required = false,
                                 default = nil)
  if valid_607205 != nil:
    section.add "X-Amz-Algorithm", valid_607205
  var valid_607206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "X-Amz-SignedHeaders", valid_607206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607208: Call_AssociateContactWithAddressBook_607196;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a contact with a given address book.
  ## 
  let valid = call_607208.validator(path, query, header, formData, body)
  let scheme = call_607208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607208.url(scheme.get, call_607208.host, call_607208.base,
                         call_607208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607208, url, valid)

proc call*(call_607209: Call_AssociateContactWithAddressBook_607196; body: JsonNode): Recallable =
  ## associateContactWithAddressBook
  ## Associates a contact with a given address book.
  ##   body: JObject (required)
  var body_607210 = newJObject()
  if body != nil:
    body_607210 = body
  result = call_607209.call(nil, nil, nil, nil, body_607210)

var associateContactWithAddressBook* = Call_AssociateContactWithAddressBook_607196(
    name: "associateContactWithAddressBook", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateContactWithAddressBook",
    validator: validate_AssociateContactWithAddressBook_607197, base: "/",
    url: url_AssociateContactWithAddressBook_607198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateDeviceWithNetworkProfile_607211 = ref object of OpenApiRestCall_606589
proc url_AssociateDeviceWithNetworkProfile_607213(protocol: Scheme; host: string;
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

proc validate_AssociateDeviceWithNetworkProfile_607212(path: JsonNode;
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
  var valid_607214 = header.getOrDefault("X-Amz-Target")
  valid_607214 = validateParameter(valid_607214, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateDeviceWithNetworkProfile"))
  if valid_607214 != nil:
    section.add "X-Amz-Target", valid_607214
  var valid_607215 = header.getOrDefault("X-Amz-Signature")
  valid_607215 = validateParameter(valid_607215, JString, required = false,
                                 default = nil)
  if valid_607215 != nil:
    section.add "X-Amz-Signature", valid_607215
  var valid_607216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607216 = validateParameter(valid_607216, JString, required = false,
                                 default = nil)
  if valid_607216 != nil:
    section.add "X-Amz-Content-Sha256", valid_607216
  var valid_607217 = header.getOrDefault("X-Amz-Date")
  valid_607217 = validateParameter(valid_607217, JString, required = false,
                                 default = nil)
  if valid_607217 != nil:
    section.add "X-Amz-Date", valid_607217
  var valid_607218 = header.getOrDefault("X-Amz-Credential")
  valid_607218 = validateParameter(valid_607218, JString, required = false,
                                 default = nil)
  if valid_607218 != nil:
    section.add "X-Amz-Credential", valid_607218
  var valid_607219 = header.getOrDefault("X-Amz-Security-Token")
  valid_607219 = validateParameter(valid_607219, JString, required = false,
                                 default = nil)
  if valid_607219 != nil:
    section.add "X-Amz-Security-Token", valid_607219
  var valid_607220 = header.getOrDefault("X-Amz-Algorithm")
  valid_607220 = validateParameter(valid_607220, JString, required = false,
                                 default = nil)
  if valid_607220 != nil:
    section.add "X-Amz-Algorithm", valid_607220
  var valid_607221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "X-Amz-SignedHeaders", valid_607221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607223: Call_AssociateDeviceWithNetworkProfile_607211;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a device with the specified network profile.
  ## 
  let valid = call_607223.validator(path, query, header, formData, body)
  let scheme = call_607223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607223.url(scheme.get, call_607223.host, call_607223.base,
                         call_607223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607223, url, valid)

proc call*(call_607224: Call_AssociateDeviceWithNetworkProfile_607211;
          body: JsonNode): Recallable =
  ## associateDeviceWithNetworkProfile
  ## Associates a device with the specified network profile.
  ##   body: JObject (required)
  var body_607225 = newJObject()
  if body != nil:
    body_607225 = body
  result = call_607224.call(nil, nil, nil, nil, body_607225)

var associateDeviceWithNetworkProfile* = Call_AssociateDeviceWithNetworkProfile_607211(
    name: "associateDeviceWithNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateDeviceWithNetworkProfile",
    validator: validate_AssociateDeviceWithNetworkProfile_607212, base: "/",
    url: url_AssociateDeviceWithNetworkProfile_607213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateDeviceWithRoom_607226 = ref object of OpenApiRestCall_606589
proc url_AssociateDeviceWithRoom_607228(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateDeviceWithRoom_607227(path: JsonNode; query: JsonNode;
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
  var valid_607229 = header.getOrDefault("X-Amz-Target")
  valid_607229 = validateParameter(valid_607229, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateDeviceWithRoom"))
  if valid_607229 != nil:
    section.add "X-Amz-Target", valid_607229
  var valid_607230 = header.getOrDefault("X-Amz-Signature")
  valid_607230 = validateParameter(valid_607230, JString, required = false,
                                 default = nil)
  if valid_607230 != nil:
    section.add "X-Amz-Signature", valid_607230
  var valid_607231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607231 = validateParameter(valid_607231, JString, required = false,
                                 default = nil)
  if valid_607231 != nil:
    section.add "X-Amz-Content-Sha256", valid_607231
  var valid_607232 = header.getOrDefault("X-Amz-Date")
  valid_607232 = validateParameter(valid_607232, JString, required = false,
                                 default = nil)
  if valid_607232 != nil:
    section.add "X-Amz-Date", valid_607232
  var valid_607233 = header.getOrDefault("X-Amz-Credential")
  valid_607233 = validateParameter(valid_607233, JString, required = false,
                                 default = nil)
  if valid_607233 != nil:
    section.add "X-Amz-Credential", valid_607233
  var valid_607234 = header.getOrDefault("X-Amz-Security-Token")
  valid_607234 = validateParameter(valid_607234, JString, required = false,
                                 default = nil)
  if valid_607234 != nil:
    section.add "X-Amz-Security-Token", valid_607234
  var valid_607235 = header.getOrDefault("X-Amz-Algorithm")
  valid_607235 = validateParameter(valid_607235, JString, required = false,
                                 default = nil)
  if valid_607235 != nil:
    section.add "X-Amz-Algorithm", valid_607235
  var valid_607236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607236 = validateParameter(valid_607236, JString, required = false,
                                 default = nil)
  if valid_607236 != nil:
    section.add "X-Amz-SignedHeaders", valid_607236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607238: Call_AssociateDeviceWithRoom_607226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a device with a given room. This applies all the settings from the room profile to the device, and all the skills in any skill groups added to that room. This operation requires the device to be online, or else a manual sync is required. 
  ## 
  let valid = call_607238.validator(path, query, header, formData, body)
  let scheme = call_607238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607238.url(scheme.get, call_607238.host, call_607238.base,
                         call_607238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607238, url, valid)

proc call*(call_607239: Call_AssociateDeviceWithRoom_607226; body: JsonNode): Recallable =
  ## associateDeviceWithRoom
  ## Associates a device with a given room. This applies all the settings from the room profile to the device, and all the skills in any skill groups added to that room. This operation requires the device to be online, or else a manual sync is required. 
  ##   body: JObject (required)
  var body_607240 = newJObject()
  if body != nil:
    body_607240 = body
  result = call_607239.call(nil, nil, nil, nil, body_607240)

var associateDeviceWithRoom* = Call_AssociateDeviceWithRoom_607226(
    name: "associateDeviceWithRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateDeviceWithRoom",
    validator: validate_AssociateDeviceWithRoom_607227, base: "/",
    url: url_AssociateDeviceWithRoom_607228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillGroupWithRoom_607241 = ref object of OpenApiRestCall_606589
proc url_AssociateSkillGroupWithRoom_607243(protocol: Scheme; host: string;
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

proc validate_AssociateSkillGroupWithRoom_607242(path: JsonNode; query: JsonNode;
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
  var valid_607244 = header.getOrDefault("X-Amz-Target")
  valid_607244 = validateParameter(valid_607244, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillGroupWithRoom"))
  if valid_607244 != nil:
    section.add "X-Amz-Target", valid_607244
  var valid_607245 = header.getOrDefault("X-Amz-Signature")
  valid_607245 = validateParameter(valid_607245, JString, required = false,
                                 default = nil)
  if valid_607245 != nil:
    section.add "X-Amz-Signature", valid_607245
  var valid_607246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607246 = validateParameter(valid_607246, JString, required = false,
                                 default = nil)
  if valid_607246 != nil:
    section.add "X-Amz-Content-Sha256", valid_607246
  var valid_607247 = header.getOrDefault("X-Amz-Date")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "X-Amz-Date", valid_607247
  var valid_607248 = header.getOrDefault("X-Amz-Credential")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "X-Amz-Credential", valid_607248
  var valid_607249 = header.getOrDefault("X-Amz-Security-Token")
  valid_607249 = validateParameter(valid_607249, JString, required = false,
                                 default = nil)
  if valid_607249 != nil:
    section.add "X-Amz-Security-Token", valid_607249
  var valid_607250 = header.getOrDefault("X-Amz-Algorithm")
  valid_607250 = validateParameter(valid_607250, JString, required = false,
                                 default = nil)
  if valid_607250 != nil:
    section.add "X-Amz-Algorithm", valid_607250
  var valid_607251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "X-Amz-SignedHeaders", valid_607251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607253: Call_AssociateSkillGroupWithRoom_607241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill group with a given room. This enables all skills in the associated skill group on all devices in the room.
  ## 
  let valid = call_607253.validator(path, query, header, formData, body)
  let scheme = call_607253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607253.url(scheme.get, call_607253.host, call_607253.base,
                         call_607253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607253, url, valid)

proc call*(call_607254: Call_AssociateSkillGroupWithRoom_607241; body: JsonNode): Recallable =
  ## associateSkillGroupWithRoom
  ## Associates a skill group with a given room. This enables all skills in the associated skill group on all devices in the room.
  ##   body: JObject (required)
  var body_607255 = newJObject()
  if body != nil:
    body_607255 = body
  result = call_607254.call(nil, nil, nil, nil, body_607255)

var associateSkillGroupWithRoom* = Call_AssociateSkillGroupWithRoom_607241(
    name: "associateSkillGroupWithRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillGroupWithRoom",
    validator: validate_AssociateSkillGroupWithRoom_607242, base: "/",
    url: url_AssociateSkillGroupWithRoom_607243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillWithSkillGroup_607256 = ref object of OpenApiRestCall_606589
proc url_AssociateSkillWithSkillGroup_607258(protocol: Scheme; host: string;
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

proc validate_AssociateSkillWithSkillGroup_607257(path: JsonNode; query: JsonNode;
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
  var valid_607259 = header.getOrDefault("X-Amz-Target")
  valid_607259 = validateParameter(valid_607259, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillWithSkillGroup"))
  if valid_607259 != nil:
    section.add "X-Amz-Target", valid_607259
  var valid_607260 = header.getOrDefault("X-Amz-Signature")
  valid_607260 = validateParameter(valid_607260, JString, required = false,
                                 default = nil)
  if valid_607260 != nil:
    section.add "X-Amz-Signature", valid_607260
  var valid_607261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607261 = validateParameter(valid_607261, JString, required = false,
                                 default = nil)
  if valid_607261 != nil:
    section.add "X-Amz-Content-Sha256", valid_607261
  var valid_607262 = header.getOrDefault("X-Amz-Date")
  valid_607262 = validateParameter(valid_607262, JString, required = false,
                                 default = nil)
  if valid_607262 != nil:
    section.add "X-Amz-Date", valid_607262
  var valid_607263 = header.getOrDefault("X-Amz-Credential")
  valid_607263 = validateParameter(valid_607263, JString, required = false,
                                 default = nil)
  if valid_607263 != nil:
    section.add "X-Amz-Credential", valid_607263
  var valid_607264 = header.getOrDefault("X-Amz-Security-Token")
  valid_607264 = validateParameter(valid_607264, JString, required = false,
                                 default = nil)
  if valid_607264 != nil:
    section.add "X-Amz-Security-Token", valid_607264
  var valid_607265 = header.getOrDefault("X-Amz-Algorithm")
  valid_607265 = validateParameter(valid_607265, JString, required = false,
                                 default = nil)
  if valid_607265 != nil:
    section.add "X-Amz-Algorithm", valid_607265
  var valid_607266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-SignedHeaders", valid_607266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607268: Call_AssociateSkillWithSkillGroup_607256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill with a skill group.
  ## 
  let valid = call_607268.validator(path, query, header, formData, body)
  let scheme = call_607268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607268.url(scheme.get, call_607268.host, call_607268.base,
                         call_607268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607268, url, valid)

proc call*(call_607269: Call_AssociateSkillWithSkillGroup_607256; body: JsonNode): Recallable =
  ## associateSkillWithSkillGroup
  ## Associates a skill with a skill group.
  ##   body: JObject (required)
  var body_607270 = newJObject()
  if body != nil:
    body_607270 = body
  result = call_607269.call(nil, nil, nil, nil, body_607270)

var associateSkillWithSkillGroup* = Call_AssociateSkillWithSkillGroup_607256(
    name: "associateSkillWithSkillGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillWithSkillGroup",
    validator: validate_AssociateSkillWithSkillGroup_607257, base: "/",
    url: url_AssociateSkillWithSkillGroup_607258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillWithUsers_607271 = ref object of OpenApiRestCall_606589
proc url_AssociateSkillWithUsers_607273(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateSkillWithUsers_607272(path: JsonNode; query: JsonNode;
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
  var valid_607274 = header.getOrDefault("X-Amz-Target")
  valid_607274 = validateParameter(valid_607274, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillWithUsers"))
  if valid_607274 != nil:
    section.add "X-Amz-Target", valid_607274
  var valid_607275 = header.getOrDefault("X-Amz-Signature")
  valid_607275 = validateParameter(valid_607275, JString, required = false,
                                 default = nil)
  if valid_607275 != nil:
    section.add "X-Amz-Signature", valid_607275
  var valid_607276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607276 = validateParameter(valid_607276, JString, required = false,
                                 default = nil)
  if valid_607276 != nil:
    section.add "X-Amz-Content-Sha256", valid_607276
  var valid_607277 = header.getOrDefault("X-Amz-Date")
  valid_607277 = validateParameter(valid_607277, JString, required = false,
                                 default = nil)
  if valid_607277 != nil:
    section.add "X-Amz-Date", valid_607277
  var valid_607278 = header.getOrDefault("X-Amz-Credential")
  valid_607278 = validateParameter(valid_607278, JString, required = false,
                                 default = nil)
  if valid_607278 != nil:
    section.add "X-Amz-Credential", valid_607278
  var valid_607279 = header.getOrDefault("X-Amz-Security-Token")
  valid_607279 = validateParameter(valid_607279, JString, required = false,
                                 default = nil)
  if valid_607279 != nil:
    section.add "X-Amz-Security-Token", valid_607279
  var valid_607280 = header.getOrDefault("X-Amz-Algorithm")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Algorithm", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-SignedHeaders", valid_607281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607283: Call_AssociateSkillWithUsers_607271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Makes a private skill available for enrolled users to enable on their devices.
  ## 
  let valid = call_607283.validator(path, query, header, formData, body)
  let scheme = call_607283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607283.url(scheme.get, call_607283.host, call_607283.base,
                         call_607283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607283, url, valid)

proc call*(call_607284: Call_AssociateSkillWithUsers_607271; body: JsonNode): Recallable =
  ## associateSkillWithUsers
  ## Makes a private skill available for enrolled users to enable on their devices.
  ##   body: JObject (required)
  var body_607285 = newJObject()
  if body != nil:
    body_607285 = body
  result = call_607284.call(nil, nil, nil, nil, body_607285)

var associateSkillWithUsers* = Call_AssociateSkillWithUsers_607271(
    name: "associateSkillWithUsers", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillWithUsers",
    validator: validate_AssociateSkillWithUsers_607272, base: "/",
    url: url_AssociateSkillWithUsers_607273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAddressBook_607286 = ref object of OpenApiRestCall_606589
proc url_CreateAddressBook_607288(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAddressBook_607287(path: JsonNode; query: JsonNode;
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
  var valid_607289 = header.getOrDefault("X-Amz-Target")
  valid_607289 = validateParameter(valid_607289, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateAddressBook"))
  if valid_607289 != nil:
    section.add "X-Amz-Target", valid_607289
  var valid_607290 = header.getOrDefault("X-Amz-Signature")
  valid_607290 = validateParameter(valid_607290, JString, required = false,
                                 default = nil)
  if valid_607290 != nil:
    section.add "X-Amz-Signature", valid_607290
  var valid_607291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607291 = validateParameter(valid_607291, JString, required = false,
                                 default = nil)
  if valid_607291 != nil:
    section.add "X-Amz-Content-Sha256", valid_607291
  var valid_607292 = header.getOrDefault("X-Amz-Date")
  valid_607292 = validateParameter(valid_607292, JString, required = false,
                                 default = nil)
  if valid_607292 != nil:
    section.add "X-Amz-Date", valid_607292
  var valid_607293 = header.getOrDefault("X-Amz-Credential")
  valid_607293 = validateParameter(valid_607293, JString, required = false,
                                 default = nil)
  if valid_607293 != nil:
    section.add "X-Amz-Credential", valid_607293
  var valid_607294 = header.getOrDefault("X-Amz-Security-Token")
  valid_607294 = validateParameter(valid_607294, JString, required = false,
                                 default = nil)
  if valid_607294 != nil:
    section.add "X-Amz-Security-Token", valid_607294
  var valid_607295 = header.getOrDefault("X-Amz-Algorithm")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "X-Amz-Algorithm", valid_607295
  var valid_607296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607296 = validateParameter(valid_607296, JString, required = false,
                                 default = nil)
  if valid_607296 != nil:
    section.add "X-Amz-SignedHeaders", valid_607296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607298: Call_CreateAddressBook_607286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an address book with the specified details.
  ## 
  let valid = call_607298.validator(path, query, header, formData, body)
  let scheme = call_607298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607298.url(scheme.get, call_607298.host, call_607298.base,
                         call_607298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607298, url, valid)

proc call*(call_607299: Call_CreateAddressBook_607286; body: JsonNode): Recallable =
  ## createAddressBook
  ## Creates an address book with the specified details.
  ##   body: JObject (required)
  var body_607300 = newJObject()
  if body != nil:
    body_607300 = body
  result = call_607299.call(nil, nil, nil, nil, body_607300)

var createAddressBook* = Call_CreateAddressBook_607286(name: "createAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateAddressBook",
    validator: validate_CreateAddressBook_607287, base: "/",
    url: url_CreateAddressBook_607288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBusinessReportSchedule_607301 = ref object of OpenApiRestCall_606589
proc url_CreateBusinessReportSchedule_607303(protocol: Scheme; host: string;
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

proc validate_CreateBusinessReportSchedule_607302(path: JsonNode; query: JsonNode;
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
  var valid_607304 = header.getOrDefault("X-Amz-Target")
  valid_607304 = validateParameter(valid_607304, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateBusinessReportSchedule"))
  if valid_607304 != nil:
    section.add "X-Amz-Target", valid_607304
  var valid_607305 = header.getOrDefault("X-Amz-Signature")
  valid_607305 = validateParameter(valid_607305, JString, required = false,
                                 default = nil)
  if valid_607305 != nil:
    section.add "X-Amz-Signature", valid_607305
  var valid_607306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607306 = validateParameter(valid_607306, JString, required = false,
                                 default = nil)
  if valid_607306 != nil:
    section.add "X-Amz-Content-Sha256", valid_607306
  var valid_607307 = header.getOrDefault("X-Amz-Date")
  valid_607307 = validateParameter(valid_607307, JString, required = false,
                                 default = nil)
  if valid_607307 != nil:
    section.add "X-Amz-Date", valid_607307
  var valid_607308 = header.getOrDefault("X-Amz-Credential")
  valid_607308 = validateParameter(valid_607308, JString, required = false,
                                 default = nil)
  if valid_607308 != nil:
    section.add "X-Amz-Credential", valid_607308
  var valid_607309 = header.getOrDefault("X-Amz-Security-Token")
  valid_607309 = validateParameter(valid_607309, JString, required = false,
                                 default = nil)
  if valid_607309 != nil:
    section.add "X-Amz-Security-Token", valid_607309
  var valid_607310 = header.getOrDefault("X-Amz-Algorithm")
  valid_607310 = validateParameter(valid_607310, JString, required = false,
                                 default = nil)
  if valid_607310 != nil:
    section.add "X-Amz-Algorithm", valid_607310
  var valid_607311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607311 = validateParameter(valid_607311, JString, required = false,
                                 default = nil)
  if valid_607311 != nil:
    section.add "X-Amz-SignedHeaders", valid_607311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607313: Call_CreateBusinessReportSchedule_607301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a recurring schedule for usage reports to deliver to the specified S3 location with a specified daily or weekly interval.
  ## 
  let valid = call_607313.validator(path, query, header, formData, body)
  let scheme = call_607313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607313.url(scheme.get, call_607313.host, call_607313.base,
                         call_607313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607313, url, valid)

proc call*(call_607314: Call_CreateBusinessReportSchedule_607301; body: JsonNode): Recallable =
  ## createBusinessReportSchedule
  ## Creates a recurring schedule for usage reports to deliver to the specified S3 location with a specified daily or weekly interval.
  ##   body: JObject (required)
  var body_607315 = newJObject()
  if body != nil:
    body_607315 = body
  result = call_607314.call(nil, nil, nil, nil, body_607315)

var createBusinessReportSchedule* = Call_CreateBusinessReportSchedule_607301(
    name: "createBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateBusinessReportSchedule",
    validator: validate_CreateBusinessReportSchedule_607302, base: "/",
    url: url_CreateBusinessReportSchedule_607303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConferenceProvider_607316 = ref object of OpenApiRestCall_606589
proc url_CreateConferenceProvider_607318(protocol: Scheme; host: string;
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

proc validate_CreateConferenceProvider_607317(path: JsonNode; query: JsonNode;
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
  var valid_607319 = header.getOrDefault("X-Amz-Target")
  valid_607319 = validateParameter(valid_607319, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateConferenceProvider"))
  if valid_607319 != nil:
    section.add "X-Amz-Target", valid_607319
  var valid_607320 = header.getOrDefault("X-Amz-Signature")
  valid_607320 = validateParameter(valid_607320, JString, required = false,
                                 default = nil)
  if valid_607320 != nil:
    section.add "X-Amz-Signature", valid_607320
  var valid_607321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "X-Amz-Content-Sha256", valid_607321
  var valid_607322 = header.getOrDefault("X-Amz-Date")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "X-Amz-Date", valid_607322
  var valid_607323 = header.getOrDefault("X-Amz-Credential")
  valid_607323 = validateParameter(valid_607323, JString, required = false,
                                 default = nil)
  if valid_607323 != nil:
    section.add "X-Amz-Credential", valid_607323
  var valid_607324 = header.getOrDefault("X-Amz-Security-Token")
  valid_607324 = validateParameter(valid_607324, JString, required = false,
                                 default = nil)
  if valid_607324 != nil:
    section.add "X-Amz-Security-Token", valid_607324
  var valid_607325 = header.getOrDefault("X-Amz-Algorithm")
  valid_607325 = validateParameter(valid_607325, JString, required = false,
                                 default = nil)
  if valid_607325 != nil:
    section.add "X-Amz-Algorithm", valid_607325
  var valid_607326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607326 = validateParameter(valid_607326, JString, required = false,
                                 default = nil)
  if valid_607326 != nil:
    section.add "X-Amz-SignedHeaders", valid_607326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607328: Call_CreateConferenceProvider_607316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new conference provider under the user's AWS account.
  ## 
  let valid = call_607328.validator(path, query, header, formData, body)
  let scheme = call_607328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607328.url(scheme.get, call_607328.host, call_607328.base,
                         call_607328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607328, url, valid)

proc call*(call_607329: Call_CreateConferenceProvider_607316; body: JsonNode): Recallable =
  ## createConferenceProvider
  ## Adds a new conference provider under the user's AWS account.
  ##   body: JObject (required)
  var body_607330 = newJObject()
  if body != nil:
    body_607330 = body
  result = call_607329.call(nil, nil, nil, nil, body_607330)

var createConferenceProvider* = Call_CreateConferenceProvider_607316(
    name: "createConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateConferenceProvider",
    validator: validate_CreateConferenceProvider_607317, base: "/",
    url: url_CreateConferenceProvider_607318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateContact_607331 = ref object of OpenApiRestCall_606589
proc url_CreateContact_607333(protocol: Scheme; host: string; base: string;
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

proc validate_CreateContact_607332(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607334 = header.getOrDefault("X-Amz-Target")
  valid_607334 = validateParameter(valid_607334, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateContact"))
  if valid_607334 != nil:
    section.add "X-Amz-Target", valid_607334
  var valid_607335 = header.getOrDefault("X-Amz-Signature")
  valid_607335 = validateParameter(valid_607335, JString, required = false,
                                 default = nil)
  if valid_607335 != nil:
    section.add "X-Amz-Signature", valid_607335
  var valid_607336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Content-Sha256", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-Date")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Date", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-Credential")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-Credential", valid_607338
  var valid_607339 = header.getOrDefault("X-Amz-Security-Token")
  valid_607339 = validateParameter(valid_607339, JString, required = false,
                                 default = nil)
  if valid_607339 != nil:
    section.add "X-Amz-Security-Token", valid_607339
  var valid_607340 = header.getOrDefault("X-Amz-Algorithm")
  valid_607340 = validateParameter(valid_607340, JString, required = false,
                                 default = nil)
  if valid_607340 != nil:
    section.add "X-Amz-Algorithm", valid_607340
  var valid_607341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607341 = validateParameter(valid_607341, JString, required = false,
                                 default = nil)
  if valid_607341 != nil:
    section.add "X-Amz-SignedHeaders", valid_607341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607343: Call_CreateContact_607331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a contact with the specified details.
  ## 
  let valid = call_607343.validator(path, query, header, formData, body)
  let scheme = call_607343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607343.url(scheme.get, call_607343.host, call_607343.base,
                         call_607343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607343, url, valid)

proc call*(call_607344: Call_CreateContact_607331; body: JsonNode): Recallable =
  ## createContact
  ## Creates a contact with the specified details.
  ##   body: JObject (required)
  var body_607345 = newJObject()
  if body != nil:
    body_607345 = body
  result = call_607344.call(nil, nil, nil, nil, body_607345)

var createContact* = Call_CreateContact_607331(name: "createContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateContact",
    validator: validate_CreateContact_607332, base: "/", url: url_CreateContact_607333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGatewayGroup_607346 = ref object of OpenApiRestCall_606589
proc url_CreateGatewayGroup_607348(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGatewayGroup_607347(path: JsonNode; query: JsonNode;
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
  var valid_607349 = header.getOrDefault("X-Amz-Target")
  valid_607349 = validateParameter(valid_607349, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateGatewayGroup"))
  if valid_607349 != nil:
    section.add "X-Amz-Target", valid_607349
  var valid_607350 = header.getOrDefault("X-Amz-Signature")
  valid_607350 = validateParameter(valid_607350, JString, required = false,
                                 default = nil)
  if valid_607350 != nil:
    section.add "X-Amz-Signature", valid_607350
  var valid_607351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607351 = validateParameter(valid_607351, JString, required = false,
                                 default = nil)
  if valid_607351 != nil:
    section.add "X-Amz-Content-Sha256", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-Date")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Date", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-Credential")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-Credential", valid_607353
  var valid_607354 = header.getOrDefault("X-Amz-Security-Token")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = nil)
  if valid_607354 != nil:
    section.add "X-Amz-Security-Token", valid_607354
  var valid_607355 = header.getOrDefault("X-Amz-Algorithm")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "X-Amz-Algorithm", valid_607355
  var valid_607356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607356 = validateParameter(valid_607356, JString, required = false,
                                 default = nil)
  if valid_607356 != nil:
    section.add "X-Amz-SignedHeaders", valid_607356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607358: Call_CreateGatewayGroup_607346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a gateway group with the specified details.
  ## 
  let valid = call_607358.validator(path, query, header, formData, body)
  let scheme = call_607358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607358.url(scheme.get, call_607358.host, call_607358.base,
                         call_607358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607358, url, valid)

proc call*(call_607359: Call_CreateGatewayGroup_607346; body: JsonNode): Recallable =
  ## createGatewayGroup
  ## Creates a gateway group with the specified details.
  ##   body: JObject (required)
  var body_607360 = newJObject()
  if body != nil:
    body_607360 = body
  result = call_607359.call(nil, nil, nil, nil, body_607360)

var createGatewayGroup* = Call_CreateGatewayGroup_607346(
    name: "createGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateGatewayGroup",
    validator: validate_CreateGatewayGroup_607347, base: "/",
    url: url_CreateGatewayGroup_607348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_607361 = ref object of OpenApiRestCall_606589
proc url_CreateNetworkProfile_607363(protocol: Scheme; host: string; base: string;
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

proc validate_CreateNetworkProfile_607362(path: JsonNode; query: JsonNode;
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
  var valid_607364 = header.getOrDefault("X-Amz-Target")
  valid_607364 = validateParameter(valid_607364, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateNetworkProfile"))
  if valid_607364 != nil:
    section.add "X-Amz-Target", valid_607364
  var valid_607365 = header.getOrDefault("X-Amz-Signature")
  valid_607365 = validateParameter(valid_607365, JString, required = false,
                                 default = nil)
  if valid_607365 != nil:
    section.add "X-Amz-Signature", valid_607365
  var valid_607366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607366 = validateParameter(valid_607366, JString, required = false,
                                 default = nil)
  if valid_607366 != nil:
    section.add "X-Amz-Content-Sha256", valid_607366
  var valid_607367 = header.getOrDefault("X-Amz-Date")
  valid_607367 = validateParameter(valid_607367, JString, required = false,
                                 default = nil)
  if valid_607367 != nil:
    section.add "X-Amz-Date", valid_607367
  var valid_607368 = header.getOrDefault("X-Amz-Credential")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-Credential", valid_607368
  var valid_607369 = header.getOrDefault("X-Amz-Security-Token")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "X-Amz-Security-Token", valid_607369
  var valid_607370 = header.getOrDefault("X-Amz-Algorithm")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "X-Amz-Algorithm", valid_607370
  var valid_607371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "X-Amz-SignedHeaders", valid_607371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607373: Call_CreateNetworkProfile_607361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a network profile with the specified details.
  ## 
  let valid = call_607373.validator(path, query, header, formData, body)
  let scheme = call_607373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607373.url(scheme.get, call_607373.host, call_607373.base,
                         call_607373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607373, url, valid)

proc call*(call_607374: Call_CreateNetworkProfile_607361; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile with the specified details.
  ##   body: JObject (required)
  var body_607375 = newJObject()
  if body != nil:
    body_607375 = body
  result = call_607374.call(nil, nil, nil, nil, body_607375)

var createNetworkProfile* = Call_CreateNetworkProfile_607361(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_607362, base: "/",
    url: url_CreateNetworkProfile_607363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProfile_607376 = ref object of OpenApiRestCall_606589
proc url_CreateProfile_607378(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProfile_607377(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607379 = header.getOrDefault("X-Amz-Target")
  valid_607379 = validateParameter(valid_607379, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateProfile"))
  if valid_607379 != nil:
    section.add "X-Amz-Target", valid_607379
  var valid_607380 = header.getOrDefault("X-Amz-Signature")
  valid_607380 = validateParameter(valid_607380, JString, required = false,
                                 default = nil)
  if valid_607380 != nil:
    section.add "X-Amz-Signature", valid_607380
  var valid_607381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607381 = validateParameter(valid_607381, JString, required = false,
                                 default = nil)
  if valid_607381 != nil:
    section.add "X-Amz-Content-Sha256", valid_607381
  var valid_607382 = header.getOrDefault("X-Amz-Date")
  valid_607382 = validateParameter(valid_607382, JString, required = false,
                                 default = nil)
  if valid_607382 != nil:
    section.add "X-Amz-Date", valid_607382
  var valid_607383 = header.getOrDefault("X-Amz-Credential")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "X-Amz-Credential", valid_607383
  var valid_607384 = header.getOrDefault("X-Amz-Security-Token")
  valid_607384 = validateParameter(valid_607384, JString, required = false,
                                 default = nil)
  if valid_607384 != nil:
    section.add "X-Amz-Security-Token", valid_607384
  var valid_607385 = header.getOrDefault("X-Amz-Algorithm")
  valid_607385 = validateParameter(valid_607385, JString, required = false,
                                 default = nil)
  if valid_607385 != nil:
    section.add "X-Amz-Algorithm", valid_607385
  var valid_607386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607386 = validateParameter(valid_607386, JString, required = false,
                                 default = nil)
  if valid_607386 != nil:
    section.add "X-Amz-SignedHeaders", valid_607386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607388: Call_CreateProfile_607376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new room profile with the specified details.
  ## 
  let valid = call_607388.validator(path, query, header, formData, body)
  let scheme = call_607388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607388.url(scheme.get, call_607388.host, call_607388.base,
                         call_607388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607388, url, valid)

proc call*(call_607389: Call_CreateProfile_607376; body: JsonNode): Recallable =
  ## createProfile
  ## Creates a new room profile with the specified details.
  ##   body: JObject (required)
  var body_607390 = newJObject()
  if body != nil:
    body_607390 = body
  result = call_607389.call(nil, nil, nil, nil, body_607390)

var createProfile* = Call_CreateProfile_607376(name: "createProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateProfile",
    validator: validate_CreateProfile_607377, base: "/", url: url_CreateProfile_607378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoom_607391 = ref object of OpenApiRestCall_606589
proc url_CreateRoom_607393(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateRoom_607392(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607394 = header.getOrDefault("X-Amz-Target")
  valid_607394 = validateParameter(valid_607394, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateRoom"))
  if valid_607394 != nil:
    section.add "X-Amz-Target", valid_607394
  var valid_607395 = header.getOrDefault("X-Amz-Signature")
  valid_607395 = validateParameter(valid_607395, JString, required = false,
                                 default = nil)
  if valid_607395 != nil:
    section.add "X-Amz-Signature", valid_607395
  var valid_607396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607396 = validateParameter(valid_607396, JString, required = false,
                                 default = nil)
  if valid_607396 != nil:
    section.add "X-Amz-Content-Sha256", valid_607396
  var valid_607397 = header.getOrDefault("X-Amz-Date")
  valid_607397 = validateParameter(valid_607397, JString, required = false,
                                 default = nil)
  if valid_607397 != nil:
    section.add "X-Amz-Date", valid_607397
  var valid_607398 = header.getOrDefault("X-Amz-Credential")
  valid_607398 = validateParameter(valid_607398, JString, required = false,
                                 default = nil)
  if valid_607398 != nil:
    section.add "X-Amz-Credential", valid_607398
  var valid_607399 = header.getOrDefault("X-Amz-Security-Token")
  valid_607399 = validateParameter(valid_607399, JString, required = false,
                                 default = nil)
  if valid_607399 != nil:
    section.add "X-Amz-Security-Token", valid_607399
  var valid_607400 = header.getOrDefault("X-Amz-Algorithm")
  valid_607400 = validateParameter(valid_607400, JString, required = false,
                                 default = nil)
  if valid_607400 != nil:
    section.add "X-Amz-Algorithm", valid_607400
  var valid_607401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607401 = validateParameter(valid_607401, JString, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "X-Amz-SignedHeaders", valid_607401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607403: Call_CreateRoom_607391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a room with the specified details.
  ## 
  let valid = call_607403.validator(path, query, header, formData, body)
  let scheme = call_607403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607403.url(scheme.get, call_607403.host, call_607403.base,
                         call_607403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607403, url, valid)

proc call*(call_607404: Call_CreateRoom_607391; body: JsonNode): Recallable =
  ## createRoom
  ## Creates a room with the specified details.
  ##   body: JObject (required)
  var body_607405 = newJObject()
  if body != nil:
    body_607405 = body
  result = call_607404.call(nil, nil, nil, nil, body_607405)

var createRoom* = Call_CreateRoom_607391(name: "createRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.CreateRoom",
                                      validator: validate_CreateRoom_607392,
                                      base: "/", url: url_CreateRoom_607393,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSkillGroup_607406 = ref object of OpenApiRestCall_606589
proc url_CreateSkillGroup_607408(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSkillGroup_607407(path: JsonNode; query: JsonNode;
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
  var valid_607409 = header.getOrDefault("X-Amz-Target")
  valid_607409 = validateParameter(valid_607409, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateSkillGroup"))
  if valid_607409 != nil:
    section.add "X-Amz-Target", valid_607409
  var valid_607410 = header.getOrDefault("X-Amz-Signature")
  valid_607410 = validateParameter(valid_607410, JString, required = false,
                                 default = nil)
  if valid_607410 != nil:
    section.add "X-Amz-Signature", valid_607410
  var valid_607411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607411 = validateParameter(valid_607411, JString, required = false,
                                 default = nil)
  if valid_607411 != nil:
    section.add "X-Amz-Content-Sha256", valid_607411
  var valid_607412 = header.getOrDefault("X-Amz-Date")
  valid_607412 = validateParameter(valid_607412, JString, required = false,
                                 default = nil)
  if valid_607412 != nil:
    section.add "X-Amz-Date", valid_607412
  var valid_607413 = header.getOrDefault("X-Amz-Credential")
  valid_607413 = validateParameter(valid_607413, JString, required = false,
                                 default = nil)
  if valid_607413 != nil:
    section.add "X-Amz-Credential", valid_607413
  var valid_607414 = header.getOrDefault("X-Amz-Security-Token")
  valid_607414 = validateParameter(valid_607414, JString, required = false,
                                 default = nil)
  if valid_607414 != nil:
    section.add "X-Amz-Security-Token", valid_607414
  var valid_607415 = header.getOrDefault("X-Amz-Algorithm")
  valid_607415 = validateParameter(valid_607415, JString, required = false,
                                 default = nil)
  if valid_607415 != nil:
    section.add "X-Amz-Algorithm", valid_607415
  var valid_607416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607416 = validateParameter(valid_607416, JString, required = false,
                                 default = nil)
  if valid_607416 != nil:
    section.add "X-Amz-SignedHeaders", valid_607416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607418: Call_CreateSkillGroup_607406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a skill group with a specified name and description.
  ## 
  let valid = call_607418.validator(path, query, header, formData, body)
  let scheme = call_607418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607418.url(scheme.get, call_607418.host, call_607418.base,
                         call_607418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607418, url, valid)

proc call*(call_607419: Call_CreateSkillGroup_607406; body: JsonNode): Recallable =
  ## createSkillGroup
  ## Creates a skill group with a specified name and description.
  ##   body: JObject (required)
  var body_607420 = newJObject()
  if body != nil:
    body_607420 = body
  result = call_607419.call(nil, nil, nil, nil, body_607420)

var createSkillGroup* = Call_CreateSkillGroup_607406(name: "createSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateSkillGroup",
    validator: validate_CreateSkillGroup_607407, base: "/",
    url: url_CreateSkillGroup_607408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_607421 = ref object of OpenApiRestCall_606589
proc url_CreateUser_607423(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateUser_607422(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607424 = header.getOrDefault("X-Amz-Target")
  valid_607424 = validateParameter(valid_607424, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateUser"))
  if valid_607424 != nil:
    section.add "X-Amz-Target", valid_607424
  var valid_607425 = header.getOrDefault("X-Amz-Signature")
  valid_607425 = validateParameter(valid_607425, JString, required = false,
                                 default = nil)
  if valid_607425 != nil:
    section.add "X-Amz-Signature", valid_607425
  var valid_607426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607426 = validateParameter(valid_607426, JString, required = false,
                                 default = nil)
  if valid_607426 != nil:
    section.add "X-Amz-Content-Sha256", valid_607426
  var valid_607427 = header.getOrDefault("X-Amz-Date")
  valid_607427 = validateParameter(valid_607427, JString, required = false,
                                 default = nil)
  if valid_607427 != nil:
    section.add "X-Amz-Date", valid_607427
  var valid_607428 = header.getOrDefault("X-Amz-Credential")
  valid_607428 = validateParameter(valid_607428, JString, required = false,
                                 default = nil)
  if valid_607428 != nil:
    section.add "X-Amz-Credential", valid_607428
  var valid_607429 = header.getOrDefault("X-Amz-Security-Token")
  valid_607429 = validateParameter(valid_607429, JString, required = false,
                                 default = nil)
  if valid_607429 != nil:
    section.add "X-Amz-Security-Token", valid_607429
  var valid_607430 = header.getOrDefault("X-Amz-Algorithm")
  valid_607430 = validateParameter(valid_607430, JString, required = false,
                                 default = nil)
  if valid_607430 != nil:
    section.add "X-Amz-Algorithm", valid_607430
  var valid_607431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607431 = validateParameter(valid_607431, JString, required = false,
                                 default = nil)
  if valid_607431 != nil:
    section.add "X-Amz-SignedHeaders", valid_607431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607433: Call_CreateUser_607421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user.
  ## 
  let valid = call_607433.validator(path, query, header, formData, body)
  let scheme = call_607433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607433.url(scheme.get, call_607433.host, call_607433.base,
                         call_607433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607433, url, valid)

proc call*(call_607434: Call_CreateUser_607421; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user.
  ##   body: JObject (required)
  var body_607435 = newJObject()
  if body != nil:
    body_607435 = body
  result = call_607434.call(nil, nil, nil, nil, body_607435)

var createUser* = Call_CreateUser_607421(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.CreateUser",
                                      validator: validate_CreateUser_607422,
                                      base: "/", url: url_CreateUser_607423,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAddressBook_607436 = ref object of OpenApiRestCall_606589
proc url_DeleteAddressBook_607438(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAddressBook_607437(path: JsonNode; query: JsonNode;
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
  var valid_607439 = header.getOrDefault("X-Amz-Target")
  valid_607439 = validateParameter(valid_607439, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteAddressBook"))
  if valid_607439 != nil:
    section.add "X-Amz-Target", valid_607439
  var valid_607440 = header.getOrDefault("X-Amz-Signature")
  valid_607440 = validateParameter(valid_607440, JString, required = false,
                                 default = nil)
  if valid_607440 != nil:
    section.add "X-Amz-Signature", valid_607440
  var valid_607441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607441 = validateParameter(valid_607441, JString, required = false,
                                 default = nil)
  if valid_607441 != nil:
    section.add "X-Amz-Content-Sha256", valid_607441
  var valid_607442 = header.getOrDefault("X-Amz-Date")
  valid_607442 = validateParameter(valid_607442, JString, required = false,
                                 default = nil)
  if valid_607442 != nil:
    section.add "X-Amz-Date", valid_607442
  var valid_607443 = header.getOrDefault("X-Amz-Credential")
  valid_607443 = validateParameter(valid_607443, JString, required = false,
                                 default = nil)
  if valid_607443 != nil:
    section.add "X-Amz-Credential", valid_607443
  var valid_607444 = header.getOrDefault("X-Amz-Security-Token")
  valid_607444 = validateParameter(valid_607444, JString, required = false,
                                 default = nil)
  if valid_607444 != nil:
    section.add "X-Amz-Security-Token", valid_607444
  var valid_607445 = header.getOrDefault("X-Amz-Algorithm")
  valid_607445 = validateParameter(valid_607445, JString, required = false,
                                 default = nil)
  if valid_607445 != nil:
    section.add "X-Amz-Algorithm", valid_607445
  var valid_607446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607446 = validateParameter(valid_607446, JString, required = false,
                                 default = nil)
  if valid_607446 != nil:
    section.add "X-Amz-SignedHeaders", valid_607446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607448: Call_DeleteAddressBook_607436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an address book by the address book ARN.
  ## 
  let valid = call_607448.validator(path, query, header, formData, body)
  let scheme = call_607448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607448.url(scheme.get, call_607448.host, call_607448.base,
                         call_607448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607448, url, valid)

proc call*(call_607449: Call_DeleteAddressBook_607436; body: JsonNode): Recallable =
  ## deleteAddressBook
  ## Deletes an address book by the address book ARN.
  ##   body: JObject (required)
  var body_607450 = newJObject()
  if body != nil:
    body_607450 = body
  result = call_607449.call(nil, nil, nil, nil, body_607450)

var deleteAddressBook* = Call_DeleteAddressBook_607436(name: "deleteAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteAddressBook",
    validator: validate_DeleteAddressBook_607437, base: "/",
    url: url_DeleteAddressBook_607438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBusinessReportSchedule_607451 = ref object of OpenApiRestCall_606589
proc url_DeleteBusinessReportSchedule_607453(protocol: Scheme; host: string;
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

proc validate_DeleteBusinessReportSchedule_607452(path: JsonNode; query: JsonNode;
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
  var valid_607454 = header.getOrDefault("X-Amz-Target")
  valid_607454 = validateParameter(valid_607454, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteBusinessReportSchedule"))
  if valid_607454 != nil:
    section.add "X-Amz-Target", valid_607454
  var valid_607455 = header.getOrDefault("X-Amz-Signature")
  valid_607455 = validateParameter(valid_607455, JString, required = false,
                                 default = nil)
  if valid_607455 != nil:
    section.add "X-Amz-Signature", valid_607455
  var valid_607456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607456 = validateParameter(valid_607456, JString, required = false,
                                 default = nil)
  if valid_607456 != nil:
    section.add "X-Amz-Content-Sha256", valid_607456
  var valid_607457 = header.getOrDefault("X-Amz-Date")
  valid_607457 = validateParameter(valid_607457, JString, required = false,
                                 default = nil)
  if valid_607457 != nil:
    section.add "X-Amz-Date", valid_607457
  var valid_607458 = header.getOrDefault("X-Amz-Credential")
  valid_607458 = validateParameter(valid_607458, JString, required = false,
                                 default = nil)
  if valid_607458 != nil:
    section.add "X-Amz-Credential", valid_607458
  var valid_607459 = header.getOrDefault("X-Amz-Security-Token")
  valid_607459 = validateParameter(valid_607459, JString, required = false,
                                 default = nil)
  if valid_607459 != nil:
    section.add "X-Amz-Security-Token", valid_607459
  var valid_607460 = header.getOrDefault("X-Amz-Algorithm")
  valid_607460 = validateParameter(valid_607460, JString, required = false,
                                 default = nil)
  if valid_607460 != nil:
    section.add "X-Amz-Algorithm", valid_607460
  var valid_607461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607461 = validateParameter(valid_607461, JString, required = false,
                                 default = nil)
  if valid_607461 != nil:
    section.add "X-Amz-SignedHeaders", valid_607461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607463: Call_DeleteBusinessReportSchedule_607451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the recurring report delivery schedule with the specified schedule ARN.
  ## 
  let valid = call_607463.validator(path, query, header, formData, body)
  let scheme = call_607463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607463.url(scheme.get, call_607463.host, call_607463.base,
                         call_607463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607463, url, valid)

proc call*(call_607464: Call_DeleteBusinessReportSchedule_607451; body: JsonNode): Recallable =
  ## deleteBusinessReportSchedule
  ## Deletes the recurring report delivery schedule with the specified schedule ARN.
  ##   body: JObject (required)
  var body_607465 = newJObject()
  if body != nil:
    body_607465 = body
  result = call_607464.call(nil, nil, nil, nil, body_607465)

var deleteBusinessReportSchedule* = Call_DeleteBusinessReportSchedule_607451(
    name: "deleteBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteBusinessReportSchedule",
    validator: validate_DeleteBusinessReportSchedule_607452, base: "/",
    url: url_DeleteBusinessReportSchedule_607453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConferenceProvider_607466 = ref object of OpenApiRestCall_606589
proc url_DeleteConferenceProvider_607468(protocol: Scheme; host: string;
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

proc validate_DeleteConferenceProvider_607467(path: JsonNode; query: JsonNode;
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
  var valid_607469 = header.getOrDefault("X-Amz-Target")
  valid_607469 = validateParameter(valid_607469, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteConferenceProvider"))
  if valid_607469 != nil:
    section.add "X-Amz-Target", valid_607469
  var valid_607470 = header.getOrDefault("X-Amz-Signature")
  valid_607470 = validateParameter(valid_607470, JString, required = false,
                                 default = nil)
  if valid_607470 != nil:
    section.add "X-Amz-Signature", valid_607470
  var valid_607471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607471 = validateParameter(valid_607471, JString, required = false,
                                 default = nil)
  if valid_607471 != nil:
    section.add "X-Amz-Content-Sha256", valid_607471
  var valid_607472 = header.getOrDefault("X-Amz-Date")
  valid_607472 = validateParameter(valid_607472, JString, required = false,
                                 default = nil)
  if valid_607472 != nil:
    section.add "X-Amz-Date", valid_607472
  var valid_607473 = header.getOrDefault("X-Amz-Credential")
  valid_607473 = validateParameter(valid_607473, JString, required = false,
                                 default = nil)
  if valid_607473 != nil:
    section.add "X-Amz-Credential", valid_607473
  var valid_607474 = header.getOrDefault("X-Amz-Security-Token")
  valid_607474 = validateParameter(valid_607474, JString, required = false,
                                 default = nil)
  if valid_607474 != nil:
    section.add "X-Amz-Security-Token", valid_607474
  var valid_607475 = header.getOrDefault("X-Amz-Algorithm")
  valid_607475 = validateParameter(valid_607475, JString, required = false,
                                 default = nil)
  if valid_607475 != nil:
    section.add "X-Amz-Algorithm", valid_607475
  var valid_607476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607476 = validateParameter(valid_607476, JString, required = false,
                                 default = nil)
  if valid_607476 != nil:
    section.add "X-Amz-SignedHeaders", valid_607476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607478: Call_DeleteConferenceProvider_607466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a conference provider.
  ## 
  let valid = call_607478.validator(path, query, header, formData, body)
  let scheme = call_607478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607478.url(scheme.get, call_607478.host, call_607478.base,
                         call_607478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607478, url, valid)

proc call*(call_607479: Call_DeleteConferenceProvider_607466; body: JsonNode): Recallable =
  ## deleteConferenceProvider
  ## Deletes a conference provider.
  ##   body: JObject (required)
  var body_607480 = newJObject()
  if body != nil:
    body_607480 = body
  result = call_607479.call(nil, nil, nil, nil, body_607480)

var deleteConferenceProvider* = Call_DeleteConferenceProvider_607466(
    name: "deleteConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteConferenceProvider",
    validator: validate_DeleteConferenceProvider_607467, base: "/",
    url: url_DeleteConferenceProvider_607468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteContact_607481 = ref object of OpenApiRestCall_606589
proc url_DeleteContact_607483(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteContact_607482(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607484 = header.getOrDefault("X-Amz-Target")
  valid_607484 = validateParameter(valid_607484, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteContact"))
  if valid_607484 != nil:
    section.add "X-Amz-Target", valid_607484
  var valid_607485 = header.getOrDefault("X-Amz-Signature")
  valid_607485 = validateParameter(valid_607485, JString, required = false,
                                 default = nil)
  if valid_607485 != nil:
    section.add "X-Amz-Signature", valid_607485
  var valid_607486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607486 = validateParameter(valid_607486, JString, required = false,
                                 default = nil)
  if valid_607486 != nil:
    section.add "X-Amz-Content-Sha256", valid_607486
  var valid_607487 = header.getOrDefault("X-Amz-Date")
  valid_607487 = validateParameter(valid_607487, JString, required = false,
                                 default = nil)
  if valid_607487 != nil:
    section.add "X-Amz-Date", valid_607487
  var valid_607488 = header.getOrDefault("X-Amz-Credential")
  valid_607488 = validateParameter(valid_607488, JString, required = false,
                                 default = nil)
  if valid_607488 != nil:
    section.add "X-Amz-Credential", valid_607488
  var valid_607489 = header.getOrDefault("X-Amz-Security-Token")
  valid_607489 = validateParameter(valid_607489, JString, required = false,
                                 default = nil)
  if valid_607489 != nil:
    section.add "X-Amz-Security-Token", valid_607489
  var valid_607490 = header.getOrDefault("X-Amz-Algorithm")
  valid_607490 = validateParameter(valid_607490, JString, required = false,
                                 default = nil)
  if valid_607490 != nil:
    section.add "X-Amz-Algorithm", valid_607490
  var valid_607491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607491 = validateParameter(valid_607491, JString, required = false,
                                 default = nil)
  if valid_607491 != nil:
    section.add "X-Amz-SignedHeaders", valid_607491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607493: Call_DeleteContact_607481; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a contact by the contact ARN.
  ## 
  let valid = call_607493.validator(path, query, header, formData, body)
  let scheme = call_607493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607493.url(scheme.get, call_607493.host, call_607493.base,
                         call_607493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607493, url, valid)

proc call*(call_607494: Call_DeleteContact_607481; body: JsonNode): Recallable =
  ## deleteContact
  ## Deletes a contact by the contact ARN.
  ##   body: JObject (required)
  var body_607495 = newJObject()
  if body != nil:
    body_607495 = body
  result = call_607494.call(nil, nil, nil, nil, body_607495)

var deleteContact* = Call_DeleteContact_607481(name: "deleteContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteContact",
    validator: validate_DeleteContact_607482, base: "/", url: url_DeleteContact_607483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevice_607496 = ref object of OpenApiRestCall_606589
proc url_DeleteDevice_607498(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDevice_607497(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607499 = header.getOrDefault("X-Amz-Target")
  valid_607499 = validateParameter(valid_607499, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteDevice"))
  if valid_607499 != nil:
    section.add "X-Amz-Target", valid_607499
  var valid_607500 = header.getOrDefault("X-Amz-Signature")
  valid_607500 = validateParameter(valid_607500, JString, required = false,
                                 default = nil)
  if valid_607500 != nil:
    section.add "X-Amz-Signature", valid_607500
  var valid_607501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607501 = validateParameter(valid_607501, JString, required = false,
                                 default = nil)
  if valid_607501 != nil:
    section.add "X-Amz-Content-Sha256", valid_607501
  var valid_607502 = header.getOrDefault("X-Amz-Date")
  valid_607502 = validateParameter(valid_607502, JString, required = false,
                                 default = nil)
  if valid_607502 != nil:
    section.add "X-Amz-Date", valid_607502
  var valid_607503 = header.getOrDefault("X-Amz-Credential")
  valid_607503 = validateParameter(valid_607503, JString, required = false,
                                 default = nil)
  if valid_607503 != nil:
    section.add "X-Amz-Credential", valid_607503
  var valid_607504 = header.getOrDefault("X-Amz-Security-Token")
  valid_607504 = validateParameter(valid_607504, JString, required = false,
                                 default = nil)
  if valid_607504 != nil:
    section.add "X-Amz-Security-Token", valid_607504
  var valid_607505 = header.getOrDefault("X-Amz-Algorithm")
  valid_607505 = validateParameter(valid_607505, JString, required = false,
                                 default = nil)
  if valid_607505 != nil:
    section.add "X-Amz-Algorithm", valid_607505
  var valid_607506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607506 = validateParameter(valid_607506, JString, required = false,
                                 default = nil)
  if valid_607506 != nil:
    section.add "X-Amz-SignedHeaders", valid_607506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607508: Call_DeleteDevice_607496; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a device from Alexa For Business.
  ## 
  let valid = call_607508.validator(path, query, header, formData, body)
  let scheme = call_607508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607508.url(scheme.get, call_607508.host, call_607508.base,
                         call_607508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607508, url, valid)

proc call*(call_607509: Call_DeleteDevice_607496; body: JsonNode): Recallable =
  ## deleteDevice
  ## Removes a device from Alexa For Business.
  ##   body: JObject (required)
  var body_607510 = newJObject()
  if body != nil:
    body_607510 = body
  result = call_607509.call(nil, nil, nil, nil, body_607510)

var deleteDevice* = Call_DeleteDevice_607496(name: "deleteDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteDevice",
    validator: validate_DeleteDevice_607497, base: "/", url: url_DeleteDevice_607498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceUsageData_607511 = ref object of OpenApiRestCall_606589
proc url_DeleteDeviceUsageData_607513(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeviceUsageData_607512(path: JsonNode; query: JsonNode;
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
  var valid_607514 = header.getOrDefault("X-Amz-Target")
  valid_607514 = validateParameter(valid_607514, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteDeviceUsageData"))
  if valid_607514 != nil:
    section.add "X-Amz-Target", valid_607514
  var valid_607515 = header.getOrDefault("X-Amz-Signature")
  valid_607515 = validateParameter(valid_607515, JString, required = false,
                                 default = nil)
  if valid_607515 != nil:
    section.add "X-Amz-Signature", valid_607515
  var valid_607516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607516 = validateParameter(valid_607516, JString, required = false,
                                 default = nil)
  if valid_607516 != nil:
    section.add "X-Amz-Content-Sha256", valid_607516
  var valid_607517 = header.getOrDefault("X-Amz-Date")
  valid_607517 = validateParameter(valid_607517, JString, required = false,
                                 default = nil)
  if valid_607517 != nil:
    section.add "X-Amz-Date", valid_607517
  var valid_607518 = header.getOrDefault("X-Amz-Credential")
  valid_607518 = validateParameter(valid_607518, JString, required = false,
                                 default = nil)
  if valid_607518 != nil:
    section.add "X-Amz-Credential", valid_607518
  var valid_607519 = header.getOrDefault("X-Amz-Security-Token")
  valid_607519 = validateParameter(valid_607519, JString, required = false,
                                 default = nil)
  if valid_607519 != nil:
    section.add "X-Amz-Security-Token", valid_607519
  var valid_607520 = header.getOrDefault("X-Amz-Algorithm")
  valid_607520 = validateParameter(valid_607520, JString, required = false,
                                 default = nil)
  if valid_607520 != nil:
    section.add "X-Amz-Algorithm", valid_607520
  var valid_607521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607521 = validateParameter(valid_607521, JString, required = false,
                                 default = nil)
  if valid_607521 != nil:
    section.add "X-Amz-SignedHeaders", valid_607521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607523: Call_DeleteDeviceUsageData_607511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## When this action is called for a specified shared device, it allows authorized users to delete the device's entire previous history of voice input data and associated response data. This action can be called once every 24 hours for a specific shared device.
  ## 
  let valid = call_607523.validator(path, query, header, formData, body)
  let scheme = call_607523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607523.url(scheme.get, call_607523.host, call_607523.base,
                         call_607523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607523, url, valid)

proc call*(call_607524: Call_DeleteDeviceUsageData_607511; body: JsonNode): Recallable =
  ## deleteDeviceUsageData
  ## When this action is called for a specified shared device, it allows authorized users to delete the device's entire previous history of voice input data and associated response data. This action can be called once every 24 hours for a specific shared device.
  ##   body: JObject (required)
  var body_607525 = newJObject()
  if body != nil:
    body_607525 = body
  result = call_607524.call(nil, nil, nil, nil, body_607525)

var deleteDeviceUsageData* = Call_DeleteDeviceUsageData_607511(
    name: "deleteDeviceUsageData", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteDeviceUsageData",
    validator: validate_DeleteDeviceUsageData_607512, base: "/",
    url: url_DeleteDeviceUsageData_607513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayGroup_607526 = ref object of OpenApiRestCall_606589
proc url_DeleteGatewayGroup_607528(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGatewayGroup_607527(path: JsonNode; query: JsonNode;
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
  var valid_607529 = header.getOrDefault("X-Amz-Target")
  valid_607529 = validateParameter(valid_607529, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteGatewayGroup"))
  if valid_607529 != nil:
    section.add "X-Amz-Target", valid_607529
  var valid_607530 = header.getOrDefault("X-Amz-Signature")
  valid_607530 = validateParameter(valid_607530, JString, required = false,
                                 default = nil)
  if valid_607530 != nil:
    section.add "X-Amz-Signature", valid_607530
  var valid_607531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607531 = validateParameter(valid_607531, JString, required = false,
                                 default = nil)
  if valid_607531 != nil:
    section.add "X-Amz-Content-Sha256", valid_607531
  var valid_607532 = header.getOrDefault("X-Amz-Date")
  valid_607532 = validateParameter(valid_607532, JString, required = false,
                                 default = nil)
  if valid_607532 != nil:
    section.add "X-Amz-Date", valid_607532
  var valid_607533 = header.getOrDefault("X-Amz-Credential")
  valid_607533 = validateParameter(valid_607533, JString, required = false,
                                 default = nil)
  if valid_607533 != nil:
    section.add "X-Amz-Credential", valid_607533
  var valid_607534 = header.getOrDefault("X-Amz-Security-Token")
  valid_607534 = validateParameter(valid_607534, JString, required = false,
                                 default = nil)
  if valid_607534 != nil:
    section.add "X-Amz-Security-Token", valid_607534
  var valid_607535 = header.getOrDefault("X-Amz-Algorithm")
  valid_607535 = validateParameter(valid_607535, JString, required = false,
                                 default = nil)
  if valid_607535 != nil:
    section.add "X-Amz-Algorithm", valid_607535
  var valid_607536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607536 = validateParameter(valid_607536, JString, required = false,
                                 default = nil)
  if valid_607536 != nil:
    section.add "X-Amz-SignedHeaders", valid_607536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607538: Call_DeleteGatewayGroup_607526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a gateway group.
  ## 
  let valid = call_607538.validator(path, query, header, formData, body)
  let scheme = call_607538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607538.url(scheme.get, call_607538.host, call_607538.base,
                         call_607538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607538, url, valid)

proc call*(call_607539: Call_DeleteGatewayGroup_607526; body: JsonNode): Recallable =
  ## deleteGatewayGroup
  ## Deletes a gateway group.
  ##   body: JObject (required)
  var body_607540 = newJObject()
  if body != nil:
    body_607540 = body
  result = call_607539.call(nil, nil, nil, nil, body_607540)

var deleteGatewayGroup* = Call_DeleteGatewayGroup_607526(
    name: "deleteGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteGatewayGroup",
    validator: validate_DeleteGatewayGroup_607527, base: "/",
    url: url_DeleteGatewayGroup_607528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_607541 = ref object of OpenApiRestCall_606589
proc url_DeleteNetworkProfile_607543(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteNetworkProfile_607542(path: JsonNode; query: JsonNode;
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
  var valid_607544 = header.getOrDefault("X-Amz-Target")
  valid_607544 = validateParameter(valid_607544, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteNetworkProfile"))
  if valid_607544 != nil:
    section.add "X-Amz-Target", valid_607544
  var valid_607545 = header.getOrDefault("X-Amz-Signature")
  valid_607545 = validateParameter(valid_607545, JString, required = false,
                                 default = nil)
  if valid_607545 != nil:
    section.add "X-Amz-Signature", valid_607545
  var valid_607546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607546 = validateParameter(valid_607546, JString, required = false,
                                 default = nil)
  if valid_607546 != nil:
    section.add "X-Amz-Content-Sha256", valid_607546
  var valid_607547 = header.getOrDefault("X-Amz-Date")
  valid_607547 = validateParameter(valid_607547, JString, required = false,
                                 default = nil)
  if valid_607547 != nil:
    section.add "X-Amz-Date", valid_607547
  var valid_607548 = header.getOrDefault("X-Amz-Credential")
  valid_607548 = validateParameter(valid_607548, JString, required = false,
                                 default = nil)
  if valid_607548 != nil:
    section.add "X-Amz-Credential", valid_607548
  var valid_607549 = header.getOrDefault("X-Amz-Security-Token")
  valid_607549 = validateParameter(valid_607549, JString, required = false,
                                 default = nil)
  if valid_607549 != nil:
    section.add "X-Amz-Security-Token", valid_607549
  var valid_607550 = header.getOrDefault("X-Amz-Algorithm")
  valid_607550 = validateParameter(valid_607550, JString, required = false,
                                 default = nil)
  if valid_607550 != nil:
    section.add "X-Amz-Algorithm", valid_607550
  var valid_607551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607551 = validateParameter(valid_607551, JString, required = false,
                                 default = nil)
  if valid_607551 != nil:
    section.add "X-Amz-SignedHeaders", valid_607551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607553: Call_DeleteNetworkProfile_607541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a network profile by the network profile ARN.
  ## 
  let valid = call_607553.validator(path, query, header, formData, body)
  let scheme = call_607553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607553.url(scheme.get, call_607553.host, call_607553.base,
                         call_607553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607553, url, valid)

proc call*(call_607554: Call_DeleteNetworkProfile_607541; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile by the network profile ARN.
  ##   body: JObject (required)
  var body_607555 = newJObject()
  if body != nil:
    body_607555 = body
  result = call_607554.call(nil, nil, nil, nil, body_607555)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_607541(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_607542, base: "/",
    url: url_DeleteNetworkProfile_607543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProfile_607556 = ref object of OpenApiRestCall_606589
proc url_DeleteProfile_607558(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProfile_607557(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607559 = header.getOrDefault("X-Amz-Target")
  valid_607559 = validateParameter(valid_607559, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteProfile"))
  if valid_607559 != nil:
    section.add "X-Amz-Target", valid_607559
  var valid_607560 = header.getOrDefault("X-Amz-Signature")
  valid_607560 = validateParameter(valid_607560, JString, required = false,
                                 default = nil)
  if valid_607560 != nil:
    section.add "X-Amz-Signature", valid_607560
  var valid_607561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607561 = validateParameter(valid_607561, JString, required = false,
                                 default = nil)
  if valid_607561 != nil:
    section.add "X-Amz-Content-Sha256", valid_607561
  var valid_607562 = header.getOrDefault("X-Amz-Date")
  valid_607562 = validateParameter(valid_607562, JString, required = false,
                                 default = nil)
  if valid_607562 != nil:
    section.add "X-Amz-Date", valid_607562
  var valid_607563 = header.getOrDefault("X-Amz-Credential")
  valid_607563 = validateParameter(valid_607563, JString, required = false,
                                 default = nil)
  if valid_607563 != nil:
    section.add "X-Amz-Credential", valid_607563
  var valid_607564 = header.getOrDefault("X-Amz-Security-Token")
  valid_607564 = validateParameter(valid_607564, JString, required = false,
                                 default = nil)
  if valid_607564 != nil:
    section.add "X-Amz-Security-Token", valid_607564
  var valid_607565 = header.getOrDefault("X-Amz-Algorithm")
  valid_607565 = validateParameter(valid_607565, JString, required = false,
                                 default = nil)
  if valid_607565 != nil:
    section.add "X-Amz-Algorithm", valid_607565
  var valid_607566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607566 = validateParameter(valid_607566, JString, required = false,
                                 default = nil)
  if valid_607566 != nil:
    section.add "X-Amz-SignedHeaders", valid_607566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607568: Call_DeleteProfile_607556; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a room profile by the profile ARN.
  ## 
  let valid = call_607568.validator(path, query, header, formData, body)
  let scheme = call_607568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607568.url(scheme.get, call_607568.host, call_607568.base,
                         call_607568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607568, url, valid)

proc call*(call_607569: Call_DeleteProfile_607556; body: JsonNode): Recallable =
  ## deleteProfile
  ## Deletes a room profile by the profile ARN.
  ##   body: JObject (required)
  var body_607570 = newJObject()
  if body != nil:
    body_607570 = body
  result = call_607569.call(nil, nil, nil, nil, body_607570)

var deleteProfile* = Call_DeleteProfile_607556(name: "deleteProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteProfile",
    validator: validate_DeleteProfile_607557, base: "/", url: url_DeleteProfile_607558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoom_607571 = ref object of OpenApiRestCall_606589
proc url_DeleteRoom_607573(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteRoom_607572(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607574 = header.getOrDefault("X-Amz-Target")
  valid_607574 = validateParameter(valid_607574, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteRoom"))
  if valid_607574 != nil:
    section.add "X-Amz-Target", valid_607574
  var valid_607575 = header.getOrDefault("X-Amz-Signature")
  valid_607575 = validateParameter(valid_607575, JString, required = false,
                                 default = nil)
  if valid_607575 != nil:
    section.add "X-Amz-Signature", valid_607575
  var valid_607576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607576 = validateParameter(valid_607576, JString, required = false,
                                 default = nil)
  if valid_607576 != nil:
    section.add "X-Amz-Content-Sha256", valid_607576
  var valid_607577 = header.getOrDefault("X-Amz-Date")
  valid_607577 = validateParameter(valid_607577, JString, required = false,
                                 default = nil)
  if valid_607577 != nil:
    section.add "X-Amz-Date", valid_607577
  var valid_607578 = header.getOrDefault("X-Amz-Credential")
  valid_607578 = validateParameter(valid_607578, JString, required = false,
                                 default = nil)
  if valid_607578 != nil:
    section.add "X-Amz-Credential", valid_607578
  var valid_607579 = header.getOrDefault("X-Amz-Security-Token")
  valid_607579 = validateParameter(valid_607579, JString, required = false,
                                 default = nil)
  if valid_607579 != nil:
    section.add "X-Amz-Security-Token", valid_607579
  var valid_607580 = header.getOrDefault("X-Amz-Algorithm")
  valid_607580 = validateParameter(valid_607580, JString, required = false,
                                 default = nil)
  if valid_607580 != nil:
    section.add "X-Amz-Algorithm", valid_607580
  var valid_607581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607581 = validateParameter(valid_607581, JString, required = false,
                                 default = nil)
  if valid_607581 != nil:
    section.add "X-Amz-SignedHeaders", valid_607581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607583: Call_DeleteRoom_607571; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a room by the room ARN.
  ## 
  let valid = call_607583.validator(path, query, header, formData, body)
  let scheme = call_607583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607583.url(scheme.get, call_607583.host, call_607583.base,
                         call_607583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607583, url, valid)

proc call*(call_607584: Call_DeleteRoom_607571; body: JsonNode): Recallable =
  ## deleteRoom
  ## Deletes a room by the room ARN.
  ##   body: JObject (required)
  var body_607585 = newJObject()
  if body != nil:
    body_607585 = body
  result = call_607584.call(nil, nil, nil, nil, body_607585)

var deleteRoom* = Call_DeleteRoom_607571(name: "deleteRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DeleteRoom",
                                      validator: validate_DeleteRoom_607572,
                                      base: "/", url: url_DeleteRoom_607573,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoomSkillParameter_607586 = ref object of OpenApiRestCall_606589
proc url_DeleteRoomSkillParameter_607588(protocol: Scheme; host: string;
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

proc validate_DeleteRoomSkillParameter_607587(path: JsonNode; query: JsonNode;
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
  var valid_607589 = header.getOrDefault("X-Amz-Target")
  valid_607589 = validateParameter(valid_607589, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteRoomSkillParameter"))
  if valid_607589 != nil:
    section.add "X-Amz-Target", valid_607589
  var valid_607590 = header.getOrDefault("X-Amz-Signature")
  valid_607590 = validateParameter(valid_607590, JString, required = false,
                                 default = nil)
  if valid_607590 != nil:
    section.add "X-Amz-Signature", valid_607590
  var valid_607591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607591 = validateParameter(valid_607591, JString, required = false,
                                 default = nil)
  if valid_607591 != nil:
    section.add "X-Amz-Content-Sha256", valid_607591
  var valid_607592 = header.getOrDefault("X-Amz-Date")
  valid_607592 = validateParameter(valid_607592, JString, required = false,
                                 default = nil)
  if valid_607592 != nil:
    section.add "X-Amz-Date", valid_607592
  var valid_607593 = header.getOrDefault("X-Amz-Credential")
  valid_607593 = validateParameter(valid_607593, JString, required = false,
                                 default = nil)
  if valid_607593 != nil:
    section.add "X-Amz-Credential", valid_607593
  var valid_607594 = header.getOrDefault("X-Amz-Security-Token")
  valid_607594 = validateParameter(valid_607594, JString, required = false,
                                 default = nil)
  if valid_607594 != nil:
    section.add "X-Amz-Security-Token", valid_607594
  var valid_607595 = header.getOrDefault("X-Amz-Algorithm")
  valid_607595 = validateParameter(valid_607595, JString, required = false,
                                 default = nil)
  if valid_607595 != nil:
    section.add "X-Amz-Algorithm", valid_607595
  var valid_607596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607596 = validateParameter(valid_607596, JString, required = false,
                                 default = nil)
  if valid_607596 != nil:
    section.add "X-Amz-SignedHeaders", valid_607596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607598: Call_DeleteRoomSkillParameter_607586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes room skill parameter details by room, skill, and parameter key ID.
  ## 
  let valid = call_607598.validator(path, query, header, formData, body)
  let scheme = call_607598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607598.url(scheme.get, call_607598.host, call_607598.base,
                         call_607598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607598, url, valid)

proc call*(call_607599: Call_DeleteRoomSkillParameter_607586; body: JsonNode): Recallable =
  ## deleteRoomSkillParameter
  ## Deletes room skill parameter details by room, skill, and parameter key ID.
  ##   body: JObject (required)
  var body_607600 = newJObject()
  if body != nil:
    body_607600 = body
  result = call_607599.call(nil, nil, nil, nil, body_607600)

var deleteRoomSkillParameter* = Call_DeleteRoomSkillParameter_607586(
    name: "deleteRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteRoomSkillParameter",
    validator: validate_DeleteRoomSkillParameter_607587, base: "/",
    url: url_DeleteRoomSkillParameter_607588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSkillAuthorization_607601 = ref object of OpenApiRestCall_606589
proc url_DeleteSkillAuthorization_607603(protocol: Scheme; host: string;
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

proc validate_DeleteSkillAuthorization_607602(path: JsonNode; query: JsonNode;
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
  var valid_607604 = header.getOrDefault("X-Amz-Target")
  valid_607604 = validateParameter(valid_607604, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteSkillAuthorization"))
  if valid_607604 != nil:
    section.add "X-Amz-Target", valid_607604
  var valid_607605 = header.getOrDefault("X-Amz-Signature")
  valid_607605 = validateParameter(valid_607605, JString, required = false,
                                 default = nil)
  if valid_607605 != nil:
    section.add "X-Amz-Signature", valid_607605
  var valid_607606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607606 = validateParameter(valid_607606, JString, required = false,
                                 default = nil)
  if valid_607606 != nil:
    section.add "X-Amz-Content-Sha256", valid_607606
  var valid_607607 = header.getOrDefault("X-Amz-Date")
  valid_607607 = validateParameter(valid_607607, JString, required = false,
                                 default = nil)
  if valid_607607 != nil:
    section.add "X-Amz-Date", valid_607607
  var valid_607608 = header.getOrDefault("X-Amz-Credential")
  valid_607608 = validateParameter(valid_607608, JString, required = false,
                                 default = nil)
  if valid_607608 != nil:
    section.add "X-Amz-Credential", valid_607608
  var valid_607609 = header.getOrDefault("X-Amz-Security-Token")
  valid_607609 = validateParameter(valid_607609, JString, required = false,
                                 default = nil)
  if valid_607609 != nil:
    section.add "X-Amz-Security-Token", valid_607609
  var valid_607610 = header.getOrDefault("X-Amz-Algorithm")
  valid_607610 = validateParameter(valid_607610, JString, required = false,
                                 default = nil)
  if valid_607610 != nil:
    section.add "X-Amz-Algorithm", valid_607610
  var valid_607611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607611 = validateParameter(valid_607611, JString, required = false,
                                 default = nil)
  if valid_607611 != nil:
    section.add "X-Amz-SignedHeaders", valid_607611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607613: Call_DeleteSkillAuthorization_607601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Unlinks a third-party account from a skill.
  ## 
  let valid = call_607613.validator(path, query, header, formData, body)
  let scheme = call_607613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607613.url(scheme.get, call_607613.host, call_607613.base,
                         call_607613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607613, url, valid)

proc call*(call_607614: Call_DeleteSkillAuthorization_607601; body: JsonNode): Recallable =
  ## deleteSkillAuthorization
  ## Unlinks a third-party account from a skill.
  ##   body: JObject (required)
  var body_607615 = newJObject()
  if body != nil:
    body_607615 = body
  result = call_607614.call(nil, nil, nil, nil, body_607615)

var deleteSkillAuthorization* = Call_DeleteSkillAuthorization_607601(
    name: "deleteSkillAuthorization", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteSkillAuthorization",
    validator: validate_DeleteSkillAuthorization_607602, base: "/",
    url: url_DeleteSkillAuthorization_607603, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSkillGroup_607616 = ref object of OpenApiRestCall_606589
proc url_DeleteSkillGroup_607618(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSkillGroup_607617(path: JsonNode; query: JsonNode;
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
  var valid_607619 = header.getOrDefault("X-Amz-Target")
  valid_607619 = validateParameter(valid_607619, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteSkillGroup"))
  if valid_607619 != nil:
    section.add "X-Amz-Target", valid_607619
  var valid_607620 = header.getOrDefault("X-Amz-Signature")
  valid_607620 = validateParameter(valid_607620, JString, required = false,
                                 default = nil)
  if valid_607620 != nil:
    section.add "X-Amz-Signature", valid_607620
  var valid_607621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607621 = validateParameter(valid_607621, JString, required = false,
                                 default = nil)
  if valid_607621 != nil:
    section.add "X-Amz-Content-Sha256", valid_607621
  var valid_607622 = header.getOrDefault("X-Amz-Date")
  valid_607622 = validateParameter(valid_607622, JString, required = false,
                                 default = nil)
  if valid_607622 != nil:
    section.add "X-Amz-Date", valid_607622
  var valid_607623 = header.getOrDefault("X-Amz-Credential")
  valid_607623 = validateParameter(valid_607623, JString, required = false,
                                 default = nil)
  if valid_607623 != nil:
    section.add "X-Amz-Credential", valid_607623
  var valid_607624 = header.getOrDefault("X-Amz-Security-Token")
  valid_607624 = validateParameter(valid_607624, JString, required = false,
                                 default = nil)
  if valid_607624 != nil:
    section.add "X-Amz-Security-Token", valid_607624
  var valid_607625 = header.getOrDefault("X-Amz-Algorithm")
  valid_607625 = validateParameter(valid_607625, JString, required = false,
                                 default = nil)
  if valid_607625 != nil:
    section.add "X-Amz-Algorithm", valid_607625
  var valid_607626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607626 = validateParameter(valid_607626, JString, required = false,
                                 default = nil)
  if valid_607626 != nil:
    section.add "X-Amz-SignedHeaders", valid_607626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607628: Call_DeleteSkillGroup_607616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a skill group by skill group ARN.
  ## 
  let valid = call_607628.validator(path, query, header, formData, body)
  let scheme = call_607628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607628.url(scheme.get, call_607628.host, call_607628.base,
                         call_607628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607628, url, valid)

proc call*(call_607629: Call_DeleteSkillGroup_607616; body: JsonNode): Recallable =
  ## deleteSkillGroup
  ## Deletes a skill group by skill group ARN.
  ##   body: JObject (required)
  var body_607630 = newJObject()
  if body != nil:
    body_607630 = body
  result = call_607629.call(nil, nil, nil, nil, body_607630)

var deleteSkillGroup* = Call_DeleteSkillGroup_607616(name: "deleteSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteSkillGroup",
    validator: validate_DeleteSkillGroup_607617, base: "/",
    url: url_DeleteSkillGroup_607618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_607631 = ref object of OpenApiRestCall_606589
proc url_DeleteUser_607633(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_607632(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607634 = header.getOrDefault("X-Amz-Target")
  valid_607634 = validateParameter(valid_607634, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteUser"))
  if valid_607634 != nil:
    section.add "X-Amz-Target", valid_607634
  var valid_607635 = header.getOrDefault("X-Amz-Signature")
  valid_607635 = validateParameter(valid_607635, JString, required = false,
                                 default = nil)
  if valid_607635 != nil:
    section.add "X-Amz-Signature", valid_607635
  var valid_607636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607636 = validateParameter(valid_607636, JString, required = false,
                                 default = nil)
  if valid_607636 != nil:
    section.add "X-Amz-Content-Sha256", valid_607636
  var valid_607637 = header.getOrDefault("X-Amz-Date")
  valid_607637 = validateParameter(valid_607637, JString, required = false,
                                 default = nil)
  if valid_607637 != nil:
    section.add "X-Amz-Date", valid_607637
  var valid_607638 = header.getOrDefault("X-Amz-Credential")
  valid_607638 = validateParameter(valid_607638, JString, required = false,
                                 default = nil)
  if valid_607638 != nil:
    section.add "X-Amz-Credential", valid_607638
  var valid_607639 = header.getOrDefault("X-Amz-Security-Token")
  valid_607639 = validateParameter(valid_607639, JString, required = false,
                                 default = nil)
  if valid_607639 != nil:
    section.add "X-Amz-Security-Token", valid_607639
  var valid_607640 = header.getOrDefault("X-Amz-Algorithm")
  valid_607640 = validateParameter(valid_607640, JString, required = false,
                                 default = nil)
  if valid_607640 != nil:
    section.add "X-Amz-Algorithm", valid_607640
  var valid_607641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607641 = validateParameter(valid_607641, JString, required = false,
                                 default = nil)
  if valid_607641 != nil:
    section.add "X-Amz-SignedHeaders", valid_607641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607643: Call_DeleteUser_607631; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified user by user ARN and enrollment ARN.
  ## 
  let valid = call_607643.validator(path, query, header, formData, body)
  let scheme = call_607643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607643.url(scheme.get, call_607643.host, call_607643.base,
                         call_607643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607643, url, valid)

proc call*(call_607644: Call_DeleteUser_607631; body: JsonNode): Recallable =
  ## deleteUser
  ## Deletes a specified user by user ARN and enrollment ARN.
  ##   body: JObject (required)
  var body_607645 = newJObject()
  if body != nil:
    body_607645 = body
  result = call_607644.call(nil, nil, nil, nil, body_607645)

var deleteUser* = Call_DeleteUser_607631(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DeleteUser",
                                      validator: validate_DeleteUser_607632,
                                      base: "/", url: url_DeleteUser_607633,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateContactFromAddressBook_607646 = ref object of OpenApiRestCall_606589
proc url_DisassociateContactFromAddressBook_607648(protocol: Scheme; host: string;
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

proc validate_DisassociateContactFromAddressBook_607647(path: JsonNode;
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
  var valid_607649 = header.getOrDefault("X-Amz-Target")
  valid_607649 = validateParameter(valid_607649, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateContactFromAddressBook"))
  if valid_607649 != nil:
    section.add "X-Amz-Target", valid_607649
  var valid_607650 = header.getOrDefault("X-Amz-Signature")
  valid_607650 = validateParameter(valid_607650, JString, required = false,
                                 default = nil)
  if valid_607650 != nil:
    section.add "X-Amz-Signature", valid_607650
  var valid_607651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607651 = validateParameter(valid_607651, JString, required = false,
                                 default = nil)
  if valid_607651 != nil:
    section.add "X-Amz-Content-Sha256", valid_607651
  var valid_607652 = header.getOrDefault("X-Amz-Date")
  valid_607652 = validateParameter(valid_607652, JString, required = false,
                                 default = nil)
  if valid_607652 != nil:
    section.add "X-Amz-Date", valid_607652
  var valid_607653 = header.getOrDefault("X-Amz-Credential")
  valid_607653 = validateParameter(valid_607653, JString, required = false,
                                 default = nil)
  if valid_607653 != nil:
    section.add "X-Amz-Credential", valid_607653
  var valid_607654 = header.getOrDefault("X-Amz-Security-Token")
  valid_607654 = validateParameter(valid_607654, JString, required = false,
                                 default = nil)
  if valid_607654 != nil:
    section.add "X-Amz-Security-Token", valid_607654
  var valid_607655 = header.getOrDefault("X-Amz-Algorithm")
  valid_607655 = validateParameter(valid_607655, JString, required = false,
                                 default = nil)
  if valid_607655 != nil:
    section.add "X-Amz-Algorithm", valid_607655
  var valid_607656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607656 = validateParameter(valid_607656, JString, required = false,
                                 default = nil)
  if valid_607656 != nil:
    section.add "X-Amz-SignedHeaders", valid_607656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607658: Call_DisassociateContactFromAddressBook_607646;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a contact from a given address book.
  ## 
  let valid = call_607658.validator(path, query, header, formData, body)
  let scheme = call_607658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607658.url(scheme.get, call_607658.host, call_607658.base,
                         call_607658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607658, url, valid)

proc call*(call_607659: Call_DisassociateContactFromAddressBook_607646;
          body: JsonNode): Recallable =
  ## disassociateContactFromAddressBook
  ## Disassociates a contact from a given address book.
  ##   body: JObject (required)
  var body_607660 = newJObject()
  if body != nil:
    body_607660 = body
  result = call_607659.call(nil, nil, nil, nil, body_607660)

var disassociateContactFromAddressBook* = Call_DisassociateContactFromAddressBook_607646(
    name: "disassociateContactFromAddressBook", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DisassociateContactFromAddressBook",
    validator: validate_DisassociateContactFromAddressBook_607647, base: "/",
    url: url_DisassociateContactFromAddressBook_607648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDeviceFromRoom_607661 = ref object of OpenApiRestCall_606589
proc url_DisassociateDeviceFromRoom_607663(protocol: Scheme; host: string;
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

proc validate_DisassociateDeviceFromRoom_607662(path: JsonNode; query: JsonNode;
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
  var valid_607664 = header.getOrDefault("X-Amz-Target")
  valid_607664 = validateParameter(valid_607664, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateDeviceFromRoom"))
  if valid_607664 != nil:
    section.add "X-Amz-Target", valid_607664
  var valid_607665 = header.getOrDefault("X-Amz-Signature")
  valid_607665 = validateParameter(valid_607665, JString, required = false,
                                 default = nil)
  if valid_607665 != nil:
    section.add "X-Amz-Signature", valid_607665
  var valid_607666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607666 = validateParameter(valid_607666, JString, required = false,
                                 default = nil)
  if valid_607666 != nil:
    section.add "X-Amz-Content-Sha256", valid_607666
  var valid_607667 = header.getOrDefault("X-Amz-Date")
  valid_607667 = validateParameter(valid_607667, JString, required = false,
                                 default = nil)
  if valid_607667 != nil:
    section.add "X-Amz-Date", valid_607667
  var valid_607668 = header.getOrDefault("X-Amz-Credential")
  valid_607668 = validateParameter(valid_607668, JString, required = false,
                                 default = nil)
  if valid_607668 != nil:
    section.add "X-Amz-Credential", valid_607668
  var valid_607669 = header.getOrDefault("X-Amz-Security-Token")
  valid_607669 = validateParameter(valid_607669, JString, required = false,
                                 default = nil)
  if valid_607669 != nil:
    section.add "X-Amz-Security-Token", valid_607669
  var valid_607670 = header.getOrDefault("X-Amz-Algorithm")
  valid_607670 = validateParameter(valid_607670, JString, required = false,
                                 default = nil)
  if valid_607670 != nil:
    section.add "X-Amz-Algorithm", valid_607670
  var valid_607671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607671 = validateParameter(valid_607671, JString, required = false,
                                 default = nil)
  if valid_607671 != nil:
    section.add "X-Amz-SignedHeaders", valid_607671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607673: Call_DisassociateDeviceFromRoom_607661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a device from its current room. The device continues to be connected to the Wi-Fi network and is still registered to the account. The device settings and skills are removed from the room.
  ## 
  let valid = call_607673.validator(path, query, header, formData, body)
  let scheme = call_607673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607673.url(scheme.get, call_607673.host, call_607673.base,
                         call_607673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607673, url, valid)

proc call*(call_607674: Call_DisassociateDeviceFromRoom_607661; body: JsonNode): Recallable =
  ## disassociateDeviceFromRoom
  ## Disassociates a device from its current room. The device continues to be connected to the Wi-Fi network and is still registered to the account. The device settings and skills are removed from the room.
  ##   body: JObject (required)
  var body_607675 = newJObject()
  if body != nil:
    body_607675 = body
  result = call_607674.call(nil, nil, nil, nil, body_607675)

var disassociateDeviceFromRoom* = Call_DisassociateDeviceFromRoom_607661(
    name: "disassociateDeviceFromRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateDeviceFromRoom",
    validator: validate_DisassociateDeviceFromRoom_607662, base: "/",
    url: url_DisassociateDeviceFromRoom_607663,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillFromSkillGroup_607676 = ref object of OpenApiRestCall_606589
proc url_DisassociateSkillFromSkillGroup_607678(protocol: Scheme; host: string;
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

proc validate_DisassociateSkillFromSkillGroup_607677(path: JsonNode;
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
  var valid_607679 = header.getOrDefault("X-Amz-Target")
  valid_607679 = validateParameter(valid_607679, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillFromSkillGroup"))
  if valid_607679 != nil:
    section.add "X-Amz-Target", valid_607679
  var valid_607680 = header.getOrDefault("X-Amz-Signature")
  valid_607680 = validateParameter(valid_607680, JString, required = false,
                                 default = nil)
  if valid_607680 != nil:
    section.add "X-Amz-Signature", valid_607680
  var valid_607681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607681 = validateParameter(valid_607681, JString, required = false,
                                 default = nil)
  if valid_607681 != nil:
    section.add "X-Amz-Content-Sha256", valid_607681
  var valid_607682 = header.getOrDefault("X-Amz-Date")
  valid_607682 = validateParameter(valid_607682, JString, required = false,
                                 default = nil)
  if valid_607682 != nil:
    section.add "X-Amz-Date", valid_607682
  var valid_607683 = header.getOrDefault("X-Amz-Credential")
  valid_607683 = validateParameter(valid_607683, JString, required = false,
                                 default = nil)
  if valid_607683 != nil:
    section.add "X-Amz-Credential", valid_607683
  var valid_607684 = header.getOrDefault("X-Amz-Security-Token")
  valid_607684 = validateParameter(valid_607684, JString, required = false,
                                 default = nil)
  if valid_607684 != nil:
    section.add "X-Amz-Security-Token", valid_607684
  var valid_607685 = header.getOrDefault("X-Amz-Algorithm")
  valid_607685 = validateParameter(valid_607685, JString, required = false,
                                 default = nil)
  if valid_607685 != nil:
    section.add "X-Amz-Algorithm", valid_607685
  var valid_607686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607686 = validateParameter(valid_607686, JString, required = false,
                                 default = nil)
  if valid_607686 != nil:
    section.add "X-Amz-SignedHeaders", valid_607686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607688: Call_DisassociateSkillFromSkillGroup_607676;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a skill from a skill group.
  ## 
  let valid = call_607688.validator(path, query, header, formData, body)
  let scheme = call_607688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607688.url(scheme.get, call_607688.host, call_607688.base,
                         call_607688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607688, url, valid)

proc call*(call_607689: Call_DisassociateSkillFromSkillGroup_607676; body: JsonNode): Recallable =
  ## disassociateSkillFromSkillGroup
  ## Disassociates a skill from a skill group.
  ##   body: JObject (required)
  var body_607690 = newJObject()
  if body != nil:
    body_607690 = body
  result = call_607689.call(nil, nil, nil, nil, body_607690)

var disassociateSkillFromSkillGroup* = Call_DisassociateSkillFromSkillGroup_607676(
    name: "disassociateSkillFromSkillGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillFromSkillGroup",
    validator: validate_DisassociateSkillFromSkillGroup_607677, base: "/",
    url: url_DisassociateSkillFromSkillGroup_607678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillFromUsers_607691 = ref object of OpenApiRestCall_606589
proc url_DisassociateSkillFromUsers_607693(protocol: Scheme; host: string;
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

proc validate_DisassociateSkillFromUsers_607692(path: JsonNode; query: JsonNode;
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
  var valid_607694 = header.getOrDefault("X-Amz-Target")
  valid_607694 = validateParameter(valid_607694, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillFromUsers"))
  if valid_607694 != nil:
    section.add "X-Amz-Target", valid_607694
  var valid_607695 = header.getOrDefault("X-Amz-Signature")
  valid_607695 = validateParameter(valid_607695, JString, required = false,
                                 default = nil)
  if valid_607695 != nil:
    section.add "X-Amz-Signature", valid_607695
  var valid_607696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607696 = validateParameter(valid_607696, JString, required = false,
                                 default = nil)
  if valid_607696 != nil:
    section.add "X-Amz-Content-Sha256", valid_607696
  var valid_607697 = header.getOrDefault("X-Amz-Date")
  valid_607697 = validateParameter(valid_607697, JString, required = false,
                                 default = nil)
  if valid_607697 != nil:
    section.add "X-Amz-Date", valid_607697
  var valid_607698 = header.getOrDefault("X-Amz-Credential")
  valid_607698 = validateParameter(valid_607698, JString, required = false,
                                 default = nil)
  if valid_607698 != nil:
    section.add "X-Amz-Credential", valid_607698
  var valid_607699 = header.getOrDefault("X-Amz-Security-Token")
  valid_607699 = validateParameter(valid_607699, JString, required = false,
                                 default = nil)
  if valid_607699 != nil:
    section.add "X-Amz-Security-Token", valid_607699
  var valid_607700 = header.getOrDefault("X-Amz-Algorithm")
  valid_607700 = validateParameter(valid_607700, JString, required = false,
                                 default = nil)
  if valid_607700 != nil:
    section.add "X-Amz-Algorithm", valid_607700
  var valid_607701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607701 = validateParameter(valid_607701, JString, required = false,
                                 default = nil)
  if valid_607701 != nil:
    section.add "X-Amz-SignedHeaders", valid_607701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607703: Call_DisassociateSkillFromUsers_607691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Makes a private skill unavailable for enrolled users and prevents them from enabling it on their devices.
  ## 
  let valid = call_607703.validator(path, query, header, formData, body)
  let scheme = call_607703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607703.url(scheme.get, call_607703.host, call_607703.base,
                         call_607703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607703, url, valid)

proc call*(call_607704: Call_DisassociateSkillFromUsers_607691; body: JsonNode): Recallable =
  ## disassociateSkillFromUsers
  ## Makes a private skill unavailable for enrolled users and prevents them from enabling it on their devices.
  ##   body: JObject (required)
  var body_607705 = newJObject()
  if body != nil:
    body_607705 = body
  result = call_607704.call(nil, nil, nil, nil, body_607705)

var disassociateSkillFromUsers* = Call_DisassociateSkillFromUsers_607691(
    name: "disassociateSkillFromUsers", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillFromUsers",
    validator: validate_DisassociateSkillFromUsers_607692, base: "/",
    url: url_DisassociateSkillFromUsers_607693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillGroupFromRoom_607706 = ref object of OpenApiRestCall_606589
proc url_DisassociateSkillGroupFromRoom_607708(protocol: Scheme; host: string;
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

proc validate_DisassociateSkillGroupFromRoom_607707(path: JsonNode;
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
  var valid_607709 = header.getOrDefault("X-Amz-Target")
  valid_607709 = validateParameter(valid_607709, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillGroupFromRoom"))
  if valid_607709 != nil:
    section.add "X-Amz-Target", valid_607709
  var valid_607710 = header.getOrDefault("X-Amz-Signature")
  valid_607710 = validateParameter(valid_607710, JString, required = false,
                                 default = nil)
  if valid_607710 != nil:
    section.add "X-Amz-Signature", valid_607710
  var valid_607711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607711 = validateParameter(valid_607711, JString, required = false,
                                 default = nil)
  if valid_607711 != nil:
    section.add "X-Amz-Content-Sha256", valid_607711
  var valid_607712 = header.getOrDefault("X-Amz-Date")
  valid_607712 = validateParameter(valid_607712, JString, required = false,
                                 default = nil)
  if valid_607712 != nil:
    section.add "X-Amz-Date", valid_607712
  var valid_607713 = header.getOrDefault("X-Amz-Credential")
  valid_607713 = validateParameter(valid_607713, JString, required = false,
                                 default = nil)
  if valid_607713 != nil:
    section.add "X-Amz-Credential", valid_607713
  var valid_607714 = header.getOrDefault("X-Amz-Security-Token")
  valid_607714 = validateParameter(valid_607714, JString, required = false,
                                 default = nil)
  if valid_607714 != nil:
    section.add "X-Amz-Security-Token", valid_607714
  var valid_607715 = header.getOrDefault("X-Amz-Algorithm")
  valid_607715 = validateParameter(valid_607715, JString, required = false,
                                 default = nil)
  if valid_607715 != nil:
    section.add "X-Amz-Algorithm", valid_607715
  var valid_607716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607716 = validateParameter(valid_607716, JString, required = false,
                                 default = nil)
  if valid_607716 != nil:
    section.add "X-Amz-SignedHeaders", valid_607716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607718: Call_DisassociateSkillGroupFromRoom_607706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a skill group from a specified room. This disables all skills in the skill group on all devices in the room.
  ## 
  let valid = call_607718.validator(path, query, header, formData, body)
  let scheme = call_607718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607718.url(scheme.get, call_607718.host, call_607718.base,
                         call_607718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607718, url, valid)

proc call*(call_607719: Call_DisassociateSkillGroupFromRoom_607706; body: JsonNode): Recallable =
  ## disassociateSkillGroupFromRoom
  ## Disassociates a skill group from a specified room. This disables all skills in the skill group on all devices in the room.
  ##   body: JObject (required)
  var body_607720 = newJObject()
  if body != nil:
    body_607720 = body
  result = call_607719.call(nil, nil, nil, nil, body_607720)

var disassociateSkillGroupFromRoom* = Call_DisassociateSkillGroupFromRoom_607706(
    name: "disassociateSkillGroupFromRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillGroupFromRoom",
    validator: validate_DisassociateSkillGroupFromRoom_607707, base: "/",
    url: url_DisassociateSkillGroupFromRoom_607708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgetSmartHomeAppliances_607721 = ref object of OpenApiRestCall_606589
proc url_ForgetSmartHomeAppliances_607723(protocol: Scheme; host: string;
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

proc validate_ForgetSmartHomeAppliances_607722(path: JsonNode; query: JsonNode;
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
  var valid_607724 = header.getOrDefault("X-Amz-Target")
  valid_607724 = validateParameter(valid_607724, JString, required = true, default = newJString(
      "AlexaForBusiness.ForgetSmartHomeAppliances"))
  if valid_607724 != nil:
    section.add "X-Amz-Target", valid_607724
  var valid_607725 = header.getOrDefault("X-Amz-Signature")
  valid_607725 = validateParameter(valid_607725, JString, required = false,
                                 default = nil)
  if valid_607725 != nil:
    section.add "X-Amz-Signature", valid_607725
  var valid_607726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607726 = validateParameter(valid_607726, JString, required = false,
                                 default = nil)
  if valid_607726 != nil:
    section.add "X-Amz-Content-Sha256", valid_607726
  var valid_607727 = header.getOrDefault("X-Amz-Date")
  valid_607727 = validateParameter(valid_607727, JString, required = false,
                                 default = nil)
  if valid_607727 != nil:
    section.add "X-Amz-Date", valid_607727
  var valid_607728 = header.getOrDefault("X-Amz-Credential")
  valid_607728 = validateParameter(valid_607728, JString, required = false,
                                 default = nil)
  if valid_607728 != nil:
    section.add "X-Amz-Credential", valid_607728
  var valid_607729 = header.getOrDefault("X-Amz-Security-Token")
  valid_607729 = validateParameter(valid_607729, JString, required = false,
                                 default = nil)
  if valid_607729 != nil:
    section.add "X-Amz-Security-Token", valid_607729
  var valid_607730 = header.getOrDefault("X-Amz-Algorithm")
  valid_607730 = validateParameter(valid_607730, JString, required = false,
                                 default = nil)
  if valid_607730 != nil:
    section.add "X-Amz-Algorithm", valid_607730
  var valid_607731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607731 = validateParameter(valid_607731, JString, required = false,
                                 default = nil)
  if valid_607731 != nil:
    section.add "X-Amz-SignedHeaders", valid_607731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607733: Call_ForgetSmartHomeAppliances_607721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Forgets smart home appliances associated to a room.
  ## 
  let valid = call_607733.validator(path, query, header, formData, body)
  let scheme = call_607733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607733.url(scheme.get, call_607733.host, call_607733.base,
                         call_607733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607733, url, valid)

proc call*(call_607734: Call_ForgetSmartHomeAppliances_607721; body: JsonNode): Recallable =
  ## forgetSmartHomeAppliances
  ## Forgets smart home appliances associated to a room.
  ##   body: JObject (required)
  var body_607735 = newJObject()
  if body != nil:
    body_607735 = body
  result = call_607734.call(nil, nil, nil, nil, body_607735)

var forgetSmartHomeAppliances* = Call_ForgetSmartHomeAppliances_607721(
    name: "forgetSmartHomeAppliances", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ForgetSmartHomeAppliances",
    validator: validate_ForgetSmartHomeAppliances_607722, base: "/",
    url: url_ForgetSmartHomeAppliances_607723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddressBook_607736 = ref object of OpenApiRestCall_606589
proc url_GetAddressBook_607738(protocol: Scheme; host: string; base: string;
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

proc validate_GetAddressBook_607737(path: JsonNode; query: JsonNode;
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
  var valid_607739 = header.getOrDefault("X-Amz-Target")
  valid_607739 = validateParameter(valid_607739, JString, required = true, default = newJString(
      "AlexaForBusiness.GetAddressBook"))
  if valid_607739 != nil:
    section.add "X-Amz-Target", valid_607739
  var valid_607740 = header.getOrDefault("X-Amz-Signature")
  valid_607740 = validateParameter(valid_607740, JString, required = false,
                                 default = nil)
  if valid_607740 != nil:
    section.add "X-Amz-Signature", valid_607740
  var valid_607741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607741 = validateParameter(valid_607741, JString, required = false,
                                 default = nil)
  if valid_607741 != nil:
    section.add "X-Amz-Content-Sha256", valid_607741
  var valid_607742 = header.getOrDefault("X-Amz-Date")
  valid_607742 = validateParameter(valid_607742, JString, required = false,
                                 default = nil)
  if valid_607742 != nil:
    section.add "X-Amz-Date", valid_607742
  var valid_607743 = header.getOrDefault("X-Amz-Credential")
  valid_607743 = validateParameter(valid_607743, JString, required = false,
                                 default = nil)
  if valid_607743 != nil:
    section.add "X-Amz-Credential", valid_607743
  var valid_607744 = header.getOrDefault("X-Amz-Security-Token")
  valid_607744 = validateParameter(valid_607744, JString, required = false,
                                 default = nil)
  if valid_607744 != nil:
    section.add "X-Amz-Security-Token", valid_607744
  var valid_607745 = header.getOrDefault("X-Amz-Algorithm")
  valid_607745 = validateParameter(valid_607745, JString, required = false,
                                 default = nil)
  if valid_607745 != nil:
    section.add "X-Amz-Algorithm", valid_607745
  var valid_607746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607746 = validateParameter(valid_607746, JString, required = false,
                                 default = nil)
  if valid_607746 != nil:
    section.add "X-Amz-SignedHeaders", valid_607746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607748: Call_GetAddressBook_607736; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets address the book details by the address book ARN.
  ## 
  let valid = call_607748.validator(path, query, header, formData, body)
  let scheme = call_607748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607748.url(scheme.get, call_607748.host, call_607748.base,
                         call_607748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607748, url, valid)

proc call*(call_607749: Call_GetAddressBook_607736; body: JsonNode): Recallable =
  ## getAddressBook
  ## Gets address the book details by the address book ARN.
  ##   body: JObject (required)
  var body_607750 = newJObject()
  if body != nil:
    body_607750 = body
  result = call_607749.call(nil, nil, nil, nil, body_607750)

var getAddressBook* = Call_GetAddressBook_607736(name: "getAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetAddressBook",
    validator: validate_GetAddressBook_607737, base: "/", url: url_GetAddressBook_607738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConferencePreference_607751 = ref object of OpenApiRestCall_606589
proc url_GetConferencePreference_607753(protocol: Scheme; host: string; base: string;
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

proc validate_GetConferencePreference_607752(path: JsonNode; query: JsonNode;
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
  var valid_607754 = header.getOrDefault("X-Amz-Target")
  valid_607754 = validateParameter(valid_607754, JString, required = true, default = newJString(
      "AlexaForBusiness.GetConferencePreference"))
  if valid_607754 != nil:
    section.add "X-Amz-Target", valid_607754
  var valid_607755 = header.getOrDefault("X-Amz-Signature")
  valid_607755 = validateParameter(valid_607755, JString, required = false,
                                 default = nil)
  if valid_607755 != nil:
    section.add "X-Amz-Signature", valid_607755
  var valid_607756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607756 = validateParameter(valid_607756, JString, required = false,
                                 default = nil)
  if valid_607756 != nil:
    section.add "X-Amz-Content-Sha256", valid_607756
  var valid_607757 = header.getOrDefault("X-Amz-Date")
  valid_607757 = validateParameter(valid_607757, JString, required = false,
                                 default = nil)
  if valid_607757 != nil:
    section.add "X-Amz-Date", valid_607757
  var valid_607758 = header.getOrDefault("X-Amz-Credential")
  valid_607758 = validateParameter(valid_607758, JString, required = false,
                                 default = nil)
  if valid_607758 != nil:
    section.add "X-Amz-Credential", valid_607758
  var valid_607759 = header.getOrDefault("X-Amz-Security-Token")
  valid_607759 = validateParameter(valid_607759, JString, required = false,
                                 default = nil)
  if valid_607759 != nil:
    section.add "X-Amz-Security-Token", valid_607759
  var valid_607760 = header.getOrDefault("X-Amz-Algorithm")
  valid_607760 = validateParameter(valid_607760, JString, required = false,
                                 default = nil)
  if valid_607760 != nil:
    section.add "X-Amz-Algorithm", valid_607760
  var valid_607761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607761 = validateParameter(valid_607761, JString, required = false,
                                 default = nil)
  if valid_607761 != nil:
    section.add "X-Amz-SignedHeaders", valid_607761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607763: Call_GetConferencePreference_607751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the existing conference preferences.
  ## 
  let valid = call_607763.validator(path, query, header, formData, body)
  let scheme = call_607763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607763.url(scheme.get, call_607763.host, call_607763.base,
                         call_607763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607763, url, valid)

proc call*(call_607764: Call_GetConferencePreference_607751; body: JsonNode): Recallable =
  ## getConferencePreference
  ## Retrieves the existing conference preferences.
  ##   body: JObject (required)
  var body_607765 = newJObject()
  if body != nil:
    body_607765 = body
  result = call_607764.call(nil, nil, nil, nil, body_607765)

var getConferencePreference* = Call_GetConferencePreference_607751(
    name: "getConferencePreference", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetConferencePreference",
    validator: validate_GetConferencePreference_607752, base: "/",
    url: url_GetConferencePreference_607753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConferenceProvider_607766 = ref object of OpenApiRestCall_606589
proc url_GetConferenceProvider_607768(protocol: Scheme; host: string; base: string;
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

proc validate_GetConferenceProvider_607767(path: JsonNode; query: JsonNode;
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
  var valid_607769 = header.getOrDefault("X-Amz-Target")
  valid_607769 = validateParameter(valid_607769, JString, required = true, default = newJString(
      "AlexaForBusiness.GetConferenceProvider"))
  if valid_607769 != nil:
    section.add "X-Amz-Target", valid_607769
  var valid_607770 = header.getOrDefault("X-Amz-Signature")
  valid_607770 = validateParameter(valid_607770, JString, required = false,
                                 default = nil)
  if valid_607770 != nil:
    section.add "X-Amz-Signature", valid_607770
  var valid_607771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607771 = validateParameter(valid_607771, JString, required = false,
                                 default = nil)
  if valid_607771 != nil:
    section.add "X-Amz-Content-Sha256", valid_607771
  var valid_607772 = header.getOrDefault("X-Amz-Date")
  valid_607772 = validateParameter(valid_607772, JString, required = false,
                                 default = nil)
  if valid_607772 != nil:
    section.add "X-Amz-Date", valid_607772
  var valid_607773 = header.getOrDefault("X-Amz-Credential")
  valid_607773 = validateParameter(valid_607773, JString, required = false,
                                 default = nil)
  if valid_607773 != nil:
    section.add "X-Amz-Credential", valid_607773
  var valid_607774 = header.getOrDefault("X-Amz-Security-Token")
  valid_607774 = validateParameter(valid_607774, JString, required = false,
                                 default = nil)
  if valid_607774 != nil:
    section.add "X-Amz-Security-Token", valid_607774
  var valid_607775 = header.getOrDefault("X-Amz-Algorithm")
  valid_607775 = validateParameter(valid_607775, JString, required = false,
                                 default = nil)
  if valid_607775 != nil:
    section.add "X-Amz-Algorithm", valid_607775
  var valid_607776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607776 = validateParameter(valid_607776, JString, required = false,
                                 default = nil)
  if valid_607776 != nil:
    section.add "X-Amz-SignedHeaders", valid_607776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607778: Call_GetConferenceProvider_607766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a specific conference provider.
  ## 
  let valid = call_607778.validator(path, query, header, formData, body)
  let scheme = call_607778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607778.url(scheme.get, call_607778.host, call_607778.base,
                         call_607778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607778, url, valid)

proc call*(call_607779: Call_GetConferenceProvider_607766; body: JsonNode): Recallable =
  ## getConferenceProvider
  ## Gets details about a specific conference provider.
  ##   body: JObject (required)
  var body_607780 = newJObject()
  if body != nil:
    body_607780 = body
  result = call_607779.call(nil, nil, nil, nil, body_607780)

var getConferenceProvider* = Call_GetConferenceProvider_607766(
    name: "getConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetConferenceProvider",
    validator: validate_GetConferenceProvider_607767, base: "/",
    url: url_GetConferenceProvider_607768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContact_607781 = ref object of OpenApiRestCall_606589
proc url_GetContact_607783(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetContact_607782(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607784 = header.getOrDefault("X-Amz-Target")
  valid_607784 = validateParameter(valid_607784, JString, required = true, default = newJString(
      "AlexaForBusiness.GetContact"))
  if valid_607784 != nil:
    section.add "X-Amz-Target", valid_607784
  var valid_607785 = header.getOrDefault("X-Amz-Signature")
  valid_607785 = validateParameter(valid_607785, JString, required = false,
                                 default = nil)
  if valid_607785 != nil:
    section.add "X-Amz-Signature", valid_607785
  var valid_607786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607786 = validateParameter(valid_607786, JString, required = false,
                                 default = nil)
  if valid_607786 != nil:
    section.add "X-Amz-Content-Sha256", valid_607786
  var valid_607787 = header.getOrDefault("X-Amz-Date")
  valid_607787 = validateParameter(valid_607787, JString, required = false,
                                 default = nil)
  if valid_607787 != nil:
    section.add "X-Amz-Date", valid_607787
  var valid_607788 = header.getOrDefault("X-Amz-Credential")
  valid_607788 = validateParameter(valid_607788, JString, required = false,
                                 default = nil)
  if valid_607788 != nil:
    section.add "X-Amz-Credential", valid_607788
  var valid_607789 = header.getOrDefault("X-Amz-Security-Token")
  valid_607789 = validateParameter(valid_607789, JString, required = false,
                                 default = nil)
  if valid_607789 != nil:
    section.add "X-Amz-Security-Token", valid_607789
  var valid_607790 = header.getOrDefault("X-Amz-Algorithm")
  valid_607790 = validateParameter(valid_607790, JString, required = false,
                                 default = nil)
  if valid_607790 != nil:
    section.add "X-Amz-Algorithm", valid_607790
  var valid_607791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607791 = validateParameter(valid_607791, JString, required = false,
                                 default = nil)
  if valid_607791 != nil:
    section.add "X-Amz-SignedHeaders", valid_607791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607793: Call_GetContact_607781; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contact details by the contact ARN.
  ## 
  let valid = call_607793.validator(path, query, header, formData, body)
  let scheme = call_607793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607793.url(scheme.get, call_607793.host, call_607793.base,
                         call_607793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607793, url, valid)

proc call*(call_607794: Call_GetContact_607781; body: JsonNode): Recallable =
  ## getContact
  ## Gets the contact details by the contact ARN.
  ##   body: JObject (required)
  var body_607795 = newJObject()
  if body != nil:
    body_607795 = body
  result = call_607794.call(nil, nil, nil, nil, body_607795)

var getContact* = Call_GetContact_607781(name: "getContact",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetContact",
                                      validator: validate_GetContact_607782,
                                      base: "/", url: url_GetContact_607783,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_607796 = ref object of OpenApiRestCall_606589
proc url_GetDevice_607798(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDevice_607797(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607799 = header.getOrDefault("X-Amz-Target")
  valid_607799 = validateParameter(valid_607799, JString, required = true, default = newJString(
      "AlexaForBusiness.GetDevice"))
  if valid_607799 != nil:
    section.add "X-Amz-Target", valid_607799
  var valid_607800 = header.getOrDefault("X-Amz-Signature")
  valid_607800 = validateParameter(valid_607800, JString, required = false,
                                 default = nil)
  if valid_607800 != nil:
    section.add "X-Amz-Signature", valid_607800
  var valid_607801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607801 = validateParameter(valid_607801, JString, required = false,
                                 default = nil)
  if valid_607801 != nil:
    section.add "X-Amz-Content-Sha256", valid_607801
  var valid_607802 = header.getOrDefault("X-Amz-Date")
  valid_607802 = validateParameter(valid_607802, JString, required = false,
                                 default = nil)
  if valid_607802 != nil:
    section.add "X-Amz-Date", valid_607802
  var valid_607803 = header.getOrDefault("X-Amz-Credential")
  valid_607803 = validateParameter(valid_607803, JString, required = false,
                                 default = nil)
  if valid_607803 != nil:
    section.add "X-Amz-Credential", valid_607803
  var valid_607804 = header.getOrDefault("X-Amz-Security-Token")
  valid_607804 = validateParameter(valid_607804, JString, required = false,
                                 default = nil)
  if valid_607804 != nil:
    section.add "X-Amz-Security-Token", valid_607804
  var valid_607805 = header.getOrDefault("X-Amz-Algorithm")
  valid_607805 = validateParameter(valid_607805, JString, required = false,
                                 default = nil)
  if valid_607805 != nil:
    section.add "X-Amz-Algorithm", valid_607805
  var valid_607806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607806 = validateParameter(valid_607806, JString, required = false,
                                 default = nil)
  if valid_607806 != nil:
    section.add "X-Amz-SignedHeaders", valid_607806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607808: Call_GetDevice_607796; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details of a device by device ARN.
  ## 
  let valid = call_607808.validator(path, query, header, formData, body)
  let scheme = call_607808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607808.url(scheme.get, call_607808.host, call_607808.base,
                         call_607808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607808, url, valid)

proc call*(call_607809: Call_GetDevice_607796; body: JsonNode): Recallable =
  ## getDevice
  ## Gets the details of a device by device ARN.
  ##   body: JObject (required)
  var body_607810 = newJObject()
  if body != nil:
    body_607810 = body
  result = call_607809.call(nil, nil, nil, nil, body_607810)

var getDevice* = Call_GetDevice_607796(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetDevice",
                                    validator: validate_GetDevice_607797,
                                    base: "/", url: url_GetDevice_607798,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGateway_607811 = ref object of OpenApiRestCall_606589
proc url_GetGateway_607813(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetGateway_607812(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607814 = header.getOrDefault("X-Amz-Target")
  valid_607814 = validateParameter(valid_607814, JString, required = true, default = newJString(
      "AlexaForBusiness.GetGateway"))
  if valid_607814 != nil:
    section.add "X-Amz-Target", valid_607814
  var valid_607815 = header.getOrDefault("X-Amz-Signature")
  valid_607815 = validateParameter(valid_607815, JString, required = false,
                                 default = nil)
  if valid_607815 != nil:
    section.add "X-Amz-Signature", valid_607815
  var valid_607816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607816 = validateParameter(valid_607816, JString, required = false,
                                 default = nil)
  if valid_607816 != nil:
    section.add "X-Amz-Content-Sha256", valid_607816
  var valid_607817 = header.getOrDefault("X-Amz-Date")
  valid_607817 = validateParameter(valid_607817, JString, required = false,
                                 default = nil)
  if valid_607817 != nil:
    section.add "X-Amz-Date", valid_607817
  var valid_607818 = header.getOrDefault("X-Amz-Credential")
  valid_607818 = validateParameter(valid_607818, JString, required = false,
                                 default = nil)
  if valid_607818 != nil:
    section.add "X-Amz-Credential", valid_607818
  var valid_607819 = header.getOrDefault("X-Amz-Security-Token")
  valid_607819 = validateParameter(valid_607819, JString, required = false,
                                 default = nil)
  if valid_607819 != nil:
    section.add "X-Amz-Security-Token", valid_607819
  var valid_607820 = header.getOrDefault("X-Amz-Algorithm")
  valid_607820 = validateParameter(valid_607820, JString, required = false,
                                 default = nil)
  if valid_607820 != nil:
    section.add "X-Amz-Algorithm", valid_607820
  var valid_607821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607821 = validateParameter(valid_607821, JString, required = false,
                                 default = nil)
  if valid_607821 != nil:
    section.add "X-Amz-SignedHeaders", valid_607821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607823: Call_GetGateway_607811; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details of a gateway.
  ## 
  let valid = call_607823.validator(path, query, header, formData, body)
  let scheme = call_607823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607823.url(scheme.get, call_607823.host, call_607823.base,
                         call_607823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607823, url, valid)

proc call*(call_607824: Call_GetGateway_607811; body: JsonNode): Recallable =
  ## getGateway
  ## Retrieves the details of a gateway.
  ##   body: JObject (required)
  var body_607825 = newJObject()
  if body != nil:
    body_607825 = body
  result = call_607824.call(nil, nil, nil, nil, body_607825)

var getGateway* = Call_GetGateway_607811(name: "getGateway",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetGateway",
                                      validator: validate_GetGateway_607812,
                                      base: "/", url: url_GetGateway_607813,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayGroup_607826 = ref object of OpenApiRestCall_606589
proc url_GetGatewayGroup_607828(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayGroup_607827(path: JsonNode; query: JsonNode;
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
  var valid_607829 = header.getOrDefault("X-Amz-Target")
  valid_607829 = validateParameter(valid_607829, JString, required = true, default = newJString(
      "AlexaForBusiness.GetGatewayGroup"))
  if valid_607829 != nil:
    section.add "X-Amz-Target", valid_607829
  var valid_607830 = header.getOrDefault("X-Amz-Signature")
  valid_607830 = validateParameter(valid_607830, JString, required = false,
                                 default = nil)
  if valid_607830 != nil:
    section.add "X-Amz-Signature", valid_607830
  var valid_607831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607831 = validateParameter(valid_607831, JString, required = false,
                                 default = nil)
  if valid_607831 != nil:
    section.add "X-Amz-Content-Sha256", valid_607831
  var valid_607832 = header.getOrDefault("X-Amz-Date")
  valid_607832 = validateParameter(valid_607832, JString, required = false,
                                 default = nil)
  if valid_607832 != nil:
    section.add "X-Amz-Date", valid_607832
  var valid_607833 = header.getOrDefault("X-Amz-Credential")
  valid_607833 = validateParameter(valid_607833, JString, required = false,
                                 default = nil)
  if valid_607833 != nil:
    section.add "X-Amz-Credential", valid_607833
  var valid_607834 = header.getOrDefault("X-Amz-Security-Token")
  valid_607834 = validateParameter(valid_607834, JString, required = false,
                                 default = nil)
  if valid_607834 != nil:
    section.add "X-Amz-Security-Token", valid_607834
  var valid_607835 = header.getOrDefault("X-Amz-Algorithm")
  valid_607835 = validateParameter(valid_607835, JString, required = false,
                                 default = nil)
  if valid_607835 != nil:
    section.add "X-Amz-Algorithm", valid_607835
  var valid_607836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607836 = validateParameter(valid_607836, JString, required = false,
                                 default = nil)
  if valid_607836 != nil:
    section.add "X-Amz-SignedHeaders", valid_607836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607838: Call_GetGatewayGroup_607826; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details of a gateway group.
  ## 
  let valid = call_607838.validator(path, query, header, formData, body)
  let scheme = call_607838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607838.url(scheme.get, call_607838.host, call_607838.base,
                         call_607838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607838, url, valid)

proc call*(call_607839: Call_GetGatewayGroup_607826; body: JsonNode): Recallable =
  ## getGatewayGroup
  ## Retrieves the details of a gateway group.
  ##   body: JObject (required)
  var body_607840 = newJObject()
  if body != nil:
    body_607840 = body
  result = call_607839.call(nil, nil, nil, nil, body_607840)

var getGatewayGroup* = Call_GetGatewayGroup_607826(name: "getGatewayGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetGatewayGroup",
    validator: validate_GetGatewayGroup_607827, base: "/", url: url_GetGatewayGroup_607828,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationConfiguration_607841 = ref object of OpenApiRestCall_606589
proc url_GetInvitationConfiguration_607843(protocol: Scheme; host: string;
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

proc validate_GetInvitationConfiguration_607842(path: JsonNode; query: JsonNode;
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
  var valid_607844 = header.getOrDefault("X-Amz-Target")
  valid_607844 = validateParameter(valid_607844, JString, required = true, default = newJString(
      "AlexaForBusiness.GetInvitationConfiguration"))
  if valid_607844 != nil:
    section.add "X-Amz-Target", valid_607844
  var valid_607845 = header.getOrDefault("X-Amz-Signature")
  valid_607845 = validateParameter(valid_607845, JString, required = false,
                                 default = nil)
  if valid_607845 != nil:
    section.add "X-Amz-Signature", valid_607845
  var valid_607846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607846 = validateParameter(valid_607846, JString, required = false,
                                 default = nil)
  if valid_607846 != nil:
    section.add "X-Amz-Content-Sha256", valid_607846
  var valid_607847 = header.getOrDefault("X-Amz-Date")
  valid_607847 = validateParameter(valid_607847, JString, required = false,
                                 default = nil)
  if valid_607847 != nil:
    section.add "X-Amz-Date", valid_607847
  var valid_607848 = header.getOrDefault("X-Amz-Credential")
  valid_607848 = validateParameter(valid_607848, JString, required = false,
                                 default = nil)
  if valid_607848 != nil:
    section.add "X-Amz-Credential", valid_607848
  var valid_607849 = header.getOrDefault("X-Amz-Security-Token")
  valid_607849 = validateParameter(valid_607849, JString, required = false,
                                 default = nil)
  if valid_607849 != nil:
    section.add "X-Amz-Security-Token", valid_607849
  var valid_607850 = header.getOrDefault("X-Amz-Algorithm")
  valid_607850 = validateParameter(valid_607850, JString, required = false,
                                 default = nil)
  if valid_607850 != nil:
    section.add "X-Amz-Algorithm", valid_607850
  var valid_607851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607851 = validateParameter(valid_607851, JString, required = false,
                                 default = nil)
  if valid_607851 != nil:
    section.add "X-Amz-SignedHeaders", valid_607851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607853: Call_GetInvitationConfiguration_607841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the configured values for the user enrollment invitation email template.
  ## 
  let valid = call_607853.validator(path, query, header, formData, body)
  let scheme = call_607853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607853.url(scheme.get, call_607853.host, call_607853.base,
                         call_607853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607853, url, valid)

proc call*(call_607854: Call_GetInvitationConfiguration_607841; body: JsonNode): Recallable =
  ## getInvitationConfiguration
  ## Retrieves the configured values for the user enrollment invitation email template.
  ##   body: JObject (required)
  var body_607855 = newJObject()
  if body != nil:
    body_607855 = body
  result = call_607854.call(nil, nil, nil, nil, body_607855)

var getInvitationConfiguration* = Call_GetInvitationConfiguration_607841(
    name: "getInvitationConfiguration", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetInvitationConfiguration",
    validator: validate_GetInvitationConfiguration_607842, base: "/",
    url: url_GetInvitationConfiguration_607843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_607856 = ref object of OpenApiRestCall_606589
proc url_GetNetworkProfile_607858(protocol: Scheme; host: string; base: string;
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

proc validate_GetNetworkProfile_607857(path: JsonNode; query: JsonNode;
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
  var valid_607859 = header.getOrDefault("X-Amz-Target")
  valid_607859 = validateParameter(valid_607859, JString, required = true, default = newJString(
      "AlexaForBusiness.GetNetworkProfile"))
  if valid_607859 != nil:
    section.add "X-Amz-Target", valid_607859
  var valid_607860 = header.getOrDefault("X-Amz-Signature")
  valid_607860 = validateParameter(valid_607860, JString, required = false,
                                 default = nil)
  if valid_607860 != nil:
    section.add "X-Amz-Signature", valid_607860
  var valid_607861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607861 = validateParameter(valid_607861, JString, required = false,
                                 default = nil)
  if valid_607861 != nil:
    section.add "X-Amz-Content-Sha256", valid_607861
  var valid_607862 = header.getOrDefault("X-Amz-Date")
  valid_607862 = validateParameter(valid_607862, JString, required = false,
                                 default = nil)
  if valid_607862 != nil:
    section.add "X-Amz-Date", valid_607862
  var valid_607863 = header.getOrDefault("X-Amz-Credential")
  valid_607863 = validateParameter(valid_607863, JString, required = false,
                                 default = nil)
  if valid_607863 != nil:
    section.add "X-Amz-Credential", valid_607863
  var valid_607864 = header.getOrDefault("X-Amz-Security-Token")
  valid_607864 = validateParameter(valid_607864, JString, required = false,
                                 default = nil)
  if valid_607864 != nil:
    section.add "X-Amz-Security-Token", valid_607864
  var valid_607865 = header.getOrDefault("X-Amz-Algorithm")
  valid_607865 = validateParameter(valid_607865, JString, required = false,
                                 default = nil)
  if valid_607865 != nil:
    section.add "X-Amz-Algorithm", valid_607865
  var valid_607866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607866 = validateParameter(valid_607866, JString, required = false,
                                 default = nil)
  if valid_607866 != nil:
    section.add "X-Amz-SignedHeaders", valid_607866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607868: Call_GetNetworkProfile_607856; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the network profile details by the network profile ARN.
  ## 
  let valid = call_607868.validator(path, query, header, formData, body)
  let scheme = call_607868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607868.url(scheme.get, call_607868.host, call_607868.base,
                         call_607868.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607868, url, valid)

proc call*(call_607869: Call_GetNetworkProfile_607856; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Gets the network profile details by the network profile ARN.
  ##   body: JObject (required)
  var body_607870 = newJObject()
  if body != nil:
    body_607870 = body
  result = call_607869.call(nil, nil, nil, nil, body_607870)

var getNetworkProfile* = Call_GetNetworkProfile_607856(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetNetworkProfile",
    validator: validate_GetNetworkProfile_607857, base: "/",
    url: url_GetNetworkProfile_607858, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProfile_607871 = ref object of OpenApiRestCall_606589
proc url_GetProfile_607873(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetProfile_607872(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607874 = header.getOrDefault("X-Amz-Target")
  valid_607874 = validateParameter(valid_607874, JString, required = true, default = newJString(
      "AlexaForBusiness.GetProfile"))
  if valid_607874 != nil:
    section.add "X-Amz-Target", valid_607874
  var valid_607875 = header.getOrDefault("X-Amz-Signature")
  valid_607875 = validateParameter(valid_607875, JString, required = false,
                                 default = nil)
  if valid_607875 != nil:
    section.add "X-Amz-Signature", valid_607875
  var valid_607876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607876 = validateParameter(valid_607876, JString, required = false,
                                 default = nil)
  if valid_607876 != nil:
    section.add "X-Amz-Content-Sha256", valid_607876
  var valid_607877 = header.getOrDefault("X-Amz-Date")
  valid_607877 = validateParameter(valid_607877, JString, required = false,
                                 default = nil)
  if valid_607877 != nil:
    section.add "X-Amz-Date", valid_607877
  var valid_607878 = header.getOrDefault("X-Amz-Credential")
  valid_607878 = validateParameter(valid_607878, JString, required = false,
                                 default = nil)
  if valid_607878 != nil:
    section.add "X-Amz-Credential", valid_607878
  var valid_607879 = header.getOrDefault("X-Amz-Security-Token")
  valid_607879 = validateParameter(valid_607879, JString, required = false,
                                 default = nil)
  if valid_607879 != nil:
    section.add "X-Amz-Security-Token", valid_607879
  var valid_607880 = header.getOrDefault("X-Amz-Algorithm")
  valid_607880 = validateParameter(valid_607880, JString, required = false,
                                 default = nil)
  if valid_607880 != nil:
    section.add "X-Amz-Algorithm", valid_607880
  var valid_607881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607881 = validateParameter(valid_607881, JString, required = false,
                                 default = nil)
  if valid_607881 != nil:
    section.add "X-Amz-SignedHeaders", valid_607881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607883: Call_GetProfile_607871; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details of a room profile by profile ARN.
  ## 
  let valid = call_607883.validator(path, query, header, formData, body)
  let scheme = call_607883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607883.url(scheme.get, call_607883.host, call_607883.base,
                         call_607883.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607883, url, valid)

proc call*(call_607884: Call_GetProfile_607871; body: JsonNode): Recallable =
  ## getProfile
  ## Gets the details of a room profile by profile ARN.
  ##   body: JObject (required)
  var body_607885 = newJObject()
  if body != nil:
    body_607885 = body
  result = call_607884.call(nil, nil, nil, nil, body_607885)

var getProfile* = Call_GetProfile_607871(name: "getProfile",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetProfile",
                                      validator: validate_GetProfile_607872,
                                      base: "/", url: url_GetProfile_607873,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoom_607886 = ref object of OpenApiRestCall_606589
proc url_GetRoom_607888(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRoom_607887(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607889 = header.getOrDefault("X-Amz-Target")
  valid_607889 = validateParameter(valid_607889, JString, required = true, default = newJString(
      "AlexaForBusiness.GetRoom"))
  if valid_607889 != nil:
    section.add "X-Amz-Target", valid_607889
  var valid_607890 = header.getOrDefault("X-Amz-Signature")
  valid_607890 = validateParameter(valid_607890, JString, required = false,
                                 default = nil)
  if valid_607890 != nil:
    section.add "X-Amz-Signature", valid_607890
  var valid_607891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607891 = validateParameter(valid_607891, JString, required = false,
                                 default = nil)
  if valid_607891 != nil:
    section.add "X-Amz-Content-Sha256", valid_607891
  var valid_607892 = header.getOrDefault("X-Amz-Date")
  valid_607892 = validateParameter(valid_607892, JString, required = false,
                                 default = nil)
  if valid_607892 != nil:
    section.add "X-Amz-Date", valid_607892
  var valid_607893 = header.getOrDefault("X-Amz-Credential")
  valid_607893 = validateParameter(valid_607893, JString, required = false,
                                 default = nil)
  if valid_607893 != nil:
    section.add "X-Amz-Credential", valid_607893
  var valid_607894 = header.getOrDefault("X-Amz-Security-Token")
  valid_607894 = validateParameter(valid_607894, JString, required = false,
                                 default = nil)
  if valid_607894 != nil:
    section.add "X-Amz-Security-Token", valid_607894
  var valid_607895 = header.getOrDefault("X-Amz-Algorithm")
  valid_607895 = validateParameter(valid_607895, JString, required = false,
                                 default = nil)
  if valid_607895 != nil:
    section.add "X-Amz-Algorithm", valid_607895
  var valid_607896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607896 = validateParameter(valid_607896, JString, required = false,
                                 default = nil)
  if valid_607896 != nil:
    section.add "X-Amz-SignedHeaders", valid_607896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607898: Call_GetRoom_607886; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets room details by room ARN.
  ## 
  let valid = call_607898.validator(path, query, header, formData, body)
  let scheme = call_607898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607898.url(scheme.get, call_607898.host, call_607898.base,
                         call_607898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607898, url, valid)

proc call*(call_607899: Call_GetRoom_607886; body: JsonNode): Recallable =
  ## getRoom
  ## Gets room details by room ARN.
  ##   body: JObject (required)
  var body_607900 = newJObject()
  if body != nil:
    body_607900 = body
  result = call_607899.call(nil, nil, nil, nil, body_607900)

var getRoom* = Call_GetRoom_607886(name: "getRoom", meth: HttpMethod.HttpPost,
                                host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetRoom",
                                validator: validate_GetRoom_607887, base: "/",
                                url: url_GetRoom_607888,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoomSkillParameter_607901 = ref object of OpenApiRestCall_606589
proc url_GetRoomSkillParameter_607903(protocol: Scheme; host: string; base: string;
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

proc validate_GetRoomSkillParameter_607902(path: JsonNode; query: JsonNode;
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
  var valid_607904 = header.getOrDefault("X-Amz-Target")
  valid_607904 = validateParameter(valid_607904, JString, required = true, default = newJString(
      "AlexaForBusiness.GetRoomSkillParameter"))
  if valid_607904 != nil:
    section.add "X-Amz-Target", valid_607904
  var valid_607905 = header.getOrDefault("X-Amz-Signature")
  valid_607905 = validateParameter(valid_607905, JString, required = false,
                                 default = nil)
  if valid_607905 != nil:
    section.add "X-Amz-Signature", valid_607905
  var valid_607906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607906 = validateParameter(valid_607906, JString, required = false,
                                 default = nil)
  if valid_607906 != nil:
    section.add "X-Amz-Content-Sha256", valid_607906
  var valid_607907 = header.getOrDefault("X-Amz-Date")
  valid_607907 = validateParameter(valid_607907, JString, required = false,
                                 default = nil)
  if valid_607907 != nil:
    section.add "X-Amz-Date", valid_607907
  var valid_607908 = header.getOrDefault("X-Amz-Credential")
  valid_607908 = validateParameter(valid_607908, JString, required = false,
                                 default = nil)
  if valid_607908 != nil:
    section.add "X-Amz-Credential", valid_607908
  var valid_607909 = header.getOrDefault("X-Amz-Security-Token")
  valid_607909 = validateParameter(valid_607909, JString, required = false,
                                 default = nil)
  if valid_607909 != nil:
    section.add "X-Amz-Security-Token", valid_607909
  var valid_607910 = header.getOrDefault("X-Amz-Algorithm")
  valid_607910 = validateParameter(valid_607910, JString, required = false,
                                 default = nil)
  if valid_607910 != nil:
    section.add "X-Amz-Algorithm", valid_607910
  var valid_607911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607911 = validateParameter(valid_607911, JString, required = false,
                                 default = nil)
  if valid_607911 != nil:
    section.add "X-Amz-SignedHeaders", valid_607911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607913: Call_GetRoomSkillParameter_607901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets room skill parameter details by room, skill, and parameter key ARN.
  ## 
  let valid = call_607913.validator(path, query, header, formData, body)
  let scheme = call_607913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607913.url(scheme.get, call_607913.host, call_607913.base,
                         call_607913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607913, url, valid)

proc call*(call_607914: Call_GetRoomSkillParameter_607901; body: JsonNode): Recallable =
  ## getRoomSkillParameter
  ## Gets room skill parameter details by room, skill, and parameter key ARN.
  ##   body: JObject (required)
  var body_607915 = newJObject()
  if body != nil:
    body_607915 = body
  result = call_607914.call(nil, nil, nil, nil, body_607915)

var getRoomSkillParameter* = Call_GetRoomSkillParameter_607901(
    name: "getRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetRoomSkillParameter",
    validator: validate_GetRoomSkillParameter_607902, base: "/",
    url: url_GetRoomSkillParameter_607903, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSkillGroup_607916 = ref object of OpenApiRestCall_606589
proc url_GetSkillGroup_607918(protocol: Scheme; host: string; base: string;
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

proc validate_GetSkillGroup_607917(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607919 = header.getOrDefault("X-Amz-Target")
  valid_607919 = validateParameter(valid_607919, JString, required = true, default = newJString(
      "AlexaForBusiness.GetSkillGroup"))
  if valid_607919 != nil:
    section.add "X-Amz-Target", valid_607919
  var valid_607920 = header.getOrDefault("X-Amz-Signature")
  valid_607920 = validateParameter(valid_607920, JString, required = false,
                                 default = nil)
  if valid_607920 != nil:
    section.add "X-Amz-Signature", valid_607920
  var valid_607921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607921 = validateParameter(valid_607921, JString, required = false,
                                 default = nil)
  if valid_607921 != nil:
    section.add "X-Amz-Content-Sha256", valid_607921
  var valid_607922 = header.getOrDefault("X-Amz-Date")
  valid_607922 = validateParameter(valid_607922, JString, required = false,
                                 default = nil)
  if valid_607922 != nil:
    section.add "X-Amz-Date", valid_607922
  var valid_607923 = header.getOrDefault("X-Amz-Credential")
  valid_607923 = validateParameter(valid_607923, JString, required = false,
                                 default = nil)
  if valid_607923 != nil:
    section.add "X-Amz-Credential", valid_607923
  var valid_607924 = header.getOrDefault("X-Amz-Security-Token")
  valid_607924 = validateParameter(valid_607924, JString, required = false,
                                 default = nil)
  if valid_607924 != nil:
    section.add "X-Amz-Security-Token", valid_607924
  var valid_607925 = header.getOrDefault("X-Amz-Algorithm")
  valid_607925 = validateParameter(valid_607925, JString, required = false,
                                 default = nil)
  if valid_607925 != nil:
    section.add "X-Amz-Algorithm", valid_607925
  var valid_607926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607926 = validateParameter(valid_607926, JString, required = false,
                                 default = nil)
  if valid_607926 != nil:
    section.add "X-Amz-SignedHeaders", valid_607926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607928: Call_GetSkillGroup_607916; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets skill group details by skill group ARN.
  ## 
  let valid = call_607928.validator(path, query, header, formData, body)
  let scheme = call_607928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607928.url(scheme.get, call_607928.host, call_607928.base,
                         call_607928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607928, url, valid)

proc call*(call_607929: Call_GetSkillGroup_607916; body: JsonNode): Recallable =
  ## getSkillGroup
  ## Gets skill group details by skill group ARN.
  ##   body: JObject (required)
  var body_607930 = newJObject()
  if body != nil:
    body_607930 = body
  result = call_607929.call(nil, nil, nil, nil, body_607930)

var getSkillGroup* = Call_GetSkillGroup_607916(name: "getSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetSkillGroup",
    validator: validate_GetSkillGroup_607917, base: "/", url: url_GetSkillGroup_607918,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBusinessReportSchedules_607931 = ref object of OpenApiRestCall_606589
proc url_ListBusinessReportSchedules_607933(protocol: Scheme; host: string;
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

proc validate_ListBusinessReportSchedules_607932(path: JsonNode; query: JsonNode;
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
  var valid_607934 = query.getOrDefault("MaxResults")
  valid_607934 = validateParameter(valid_607934, JString, required = false,
                                 default = nil)
  if valid_607934 != nil:
    section.add "MaxResults", valid_607934
  var valid_607935 = query.getOrDefault("NextToken")
  valid_607935 = validateParameter(valid_607935, JString, required = false,
                                 default = nil)
  if valid_607935 != nil:
    section.add "NextToken", valid_607935
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
  var valid_607936 = header.getOrDefault("X-Amz-Target")
  valid_607936 = validateParameter(valid_607936, JString, required = true, default = newJString(
      "AlexaForBusiness.ListBusinessReportSchedules"))
  if valid_607936 != nil:
    section.add "X-Amz-Target", valid_607936
  var valid_607937 = header.getOrDefault("X-Amz-Signature")
  valid_607937 = validateParameter(valid_607937, JString, required = false,
                                 default = nil)
  if valid_607937 != nil:
    section.add "X-Amz-Signature", valid_607937
  var valid_607938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607938 = validateParameter(valid_607938, JString, required = false,
                                 default = nil)
  if valid_607938 != nil:
    section.add "X-Amz-Content-Sha256", valid_607938
  var valid_607939 = header.getOrDefault("X-Amz-Date")
  valid_607939 = validateParameter(valid_607939, JString, required = false,
                                 default = nil)
  if valid_607939 != nil:
    section.add "X-Amz-Date", valid_607939
  var valid_607940 = header.getOrDefault("X-Amz-Credential")
  valid_607940 = validateParameter(valid_607940, JString, required = false,
                                 default = nil)
  if valid_607940 != nil:
    section.add "X-Amz-Credential", valid_607940
  var valid_607941 = header.getOrDefault("X-Amz-Security-Token")
  valid_607941 = validateParameter(valid_607941, JString, required = false,
                                 default = nil)
  if valid_607941 != nil:
    section.add "X-Amz-Security-Token", valid_607941
  var valid_607942 = header.getOrDefault("X-Amz-Algorithm")
  valid_607942 = validateParameter(valid_607942, JString, required = false,
                                 default = nil)
  if valid_607942 != nil:
    section.add "X-Amz-Algorithm", valid_607942
  var valid_607943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607943 = validateParameter(valid_607943, JString, required = false,
                                 default = nil)
  if valid_607943 != nil:
    section.add "X-Amz-SignedHeaders", valid_607943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607945: Call_ListBusinessReportSchedules_607931; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the details of the schedules that a user configured. A download URL of the report associated with each schedule is returned every time this action is called. A new download URL is returned each time, and is valid for 24 hours.
  ## 
  let valid = call_607945.validator(path, query, header, formData, body)
  let scheme = call_607945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607945.url(scheme.get, call_607945.host, call_607945.base,
                         call_607945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607945, url, valid)

proc call*(call_607946: Call_ListBusinessReportSchedules_607931; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listBusinessReportSchedules
  ## Lists the details of the schedules that a user configured. A download URL of the report associated with each schedule is returned every time this action is called. A new download URL is returned each time, and is valid for 24 hours.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607947 = newJObject()
  var body_607948 = newJObject()
  add(query_607947, "MaxResults", newJString(MaxResults))
  add(query_607947, "NextToken", newJString(NextToken))
  if body != nil:
    body_607948 = body
  result = call_607946.call(nil, query_607947, nil, nil, body_607948)

var listBusinessReportSchedules* = Call_ListBusinessReportSchedules_607931(
    name: "listBusinessReportSchedules", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListBusinessReportSchedules",
    validator: validate_ListBusinessReportSchedules_607932, base: "/",
    url: url_ListBusinessReportSchedules_607933,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConferenceProviders_607950 = ref object of OpenApiRestCall_606589
proc url_ListConferenceProviders_607952(protocol: Scheme; host: string; base: string;
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

proc validate_ListConferenceProviders_607951(path: JsonNode; query: JsonNode;
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
  var valid_607953 = query.getOrDefault("MaxResults")
  valid_607953 = validateParameter(valid_607953, JString, required = false,
                                 default = nil)
  if valid_607953 != nil:
    section.add "MaxResults", valid_607953
  var valid_607954 = query.getOrDefault("NextToken")
  valid_607954 = validateParameter(valid_607954, JString, required = false,
                                 default = nil)
  if valid_607954 != nil:
    section.add "NextToken", valid_607954
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
  var valid_607955 = header.getOrDefault("X-Amz-Target")
  valid_607955 = validateParameter(valid_607955, JString, required = true, default = newJString(
      "AlexaForBusiness.ListConferenceProviders"))
  if valid_607955 != nil:
    section.add "X-Amz-Target", valid_607955
  var valid_607956 = header.getOrDefault("X-Amz-Signature")
  valid_607956 = validateParameter(valid_607956, JString, required = false,
                                 default = nil)
  if valid_607956 != nil:
    section.add "X-Amz-Signature", valid_607956
  var valid_607957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607957 = validateParameter(valid_607957, JString, required = false,
                                 default = nil)
  if valid_607957 != nil:
    section.add "X-Amz-Content-Sha256", valid_607957
  var valid_607958 = header.getOrDefault("X-Amz-Date")
  valid_607958 = validateParameter(valid_607958, JString, required = false,
                                 default = nil)
  if valid_607958 != nil:
    section.add "X-Amz-Date", valid_607958
  var valid_607959 = header.getOrDefault("X-Amz-Credential")
  valid_607959 = validateParameter(valid_607959, JString, required = false,
                                 default = nil)
  if valid_607959 != nil:
    section.add "X-Amz-Credential", valid_607959
  var valid_607960 = header.getOrDefault("X-Amz-Security-Token")
  valid_607960 = validateParameter(valid_607960, JString, required = false,
                                 default = nil)
  if valid_607960 != nil:
    section.add "X-Amz-Security-Token", valid_607960
  var valid_607961 = header.getOrDefault("X-Amz-Algorithm")
  valid_607961 = validateParameter(valid_607961, JString, required = false,
                                 default = nil)
  if valid_607961 != nil:
    section.add "X-Amz-Algorithm", valid_607961
  var valid_607962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607962 = validateParameter(valid_607962, JString, required = false,
                                 default = nil)
  if valid_607962 != nil:
    section.add "X-Amz-SignedHeaders", valid_607962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607964: Call_ListConferenceProviders_607950; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists conference providers under a specific AWS account.
  ## 
  let valid = call_607964.validator(path, query, header, formData, body)
  let scheme = call_607964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607964.url(scheme.get, call_607964.host, call_607964.base,
                         call_607964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607964, url, valid)

proc call*(call_607965: Call_ListConferenceProviders_607950; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listConferenceProviders
  ## Lists conference providers under a specific AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607966 = newJObject()
  var body_607967 = newJObject()
  add(query_607966, "MaxResults", newJString(MaxResults))
  add(query_607966, "NextToken", newJString(NextToken))
  if body != nil:
    body_607967 = body
  result = call_607965.call(nil, query_607966, nil, nil, body_607967)

var listConferenceProviders* = Call_ListConferenceProviders_607950(
    name: "listConferenceProviders", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListConferenceProviders",
    validator: validate_ListConferenceProviders_607951, base: "/",
    url: url_ListConferenceProviders_607952, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceEvents_607968 = ref object of OpenApiRestCall_606589
proc url_ListDeviceEvents_607970(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeviceEvents_607969(path: JsonNode; query: JsonNode;
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
  var valid_607971 = query.getOrDefault("MaxResults")
  valid_607971 = validateParameter(valid_607971, JString, required = false,
                                 default = nil)
  if valid_607971 != nil:
    section.add "MaxResults", valid_607971
  var valid_607972 = query.getOrDefault("NextToken")
  valid_607972 = validateParameter(valid_607972, JString, required = false,
                                 default = nil)
  if valid_607972 != nil:
    section.add "NextToken", valid_607972
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
  var valid_607973 = header.getOrDefault("X-Amz-Target")
  valid_607973 = validateParameter(valid_607973, JString, required = true, default = newJString(
      "AlexaForBusiness.ListDeviceEvents"))
  if valid_607973 != nil:
    section.add "X-Amz-Target", valid_607973
  var valid_607974 = header.getOrDefault("X-Amz-Signature")
  valid_607974 = validateParameter(valid_607974, JString, required = false,
                                 default = nil)
  if valid_607974 != nil:
    section.add "X-Amz-Signature", valid_607974
  var valid_607975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607975 = validateParameter(valid_607975, JString, required = false,
                                 default = nil)
  if valid_607975 != nil:
    section.add "X-Amz-Content-Sha256", valid_607975
  var valid_607976 = header.getOrDefault("X-Amz-Date")
  valid_607976 = validateParameter(valid_607976, JString, required = false,
                                 default = nil)
  if valid_607976 != nil:
    section.add "X-Amz-Date", valid_607976
  var valid_607977 = header.getOrDefault("X-Amz-Credential")
  valid_607977 = validateParameter(valid_607977, JString, required = false,
                                 default = nil)
  if valid_607977 != nil:
    section.add "X-Amz-Credential", valid_607977
  var valid_607978 = header.getOrDefault("X-Amz-Security-Token")
  valid_607978 = validateParameter(valid_607978, JString, required = false,
                                 default = nil)
  if valid_607978 != nil:
    section.add "X-Amz-Security-Token", valid_607978
  var valid_607979 = header.getOrDefault("X-Amz-Algorithm")
  valid_607979 = validateParameter(valid_607979, JString, required = false,
                                 default = nil)
  if valid_607979 != nil:
    section.add "X-Amz-Algorithm", valid_607979
  var valid_607980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607980 = validateParameter(valid_607980, JString, required = false,
                                 default = nil)
  if valid_607980 != nil:
    section.add "X-Amz-SignedHeaders", valid_607980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607982: Call_ListDeviceEvents_607968; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the device event history, including device connection status, for up to 30 days.
  ## 
  let valid = call_607982.validator(path, query, header, formData, body)
  let scheme = call_607982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607982.url(scheme.get, call_607982.host, call_607982.base,
                         call_607982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607982, url, valid)

proc call*(call_607983: Call_ListDeviceEvents_607968; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDeviceEvents
  ## Lists the device event history, including device connection status, for up to 30 days.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607984 = newJObject()
  var body_607985 = newJObject()
  add(query_607984, "MaxResults", newJString(MaxResults))
  add(query_607984, "NextToken", newJString(NextToken))
  if body != nil:
    body_607985 = body
  result = call_607983.call(nil, query_607984, nil, nil, body_607985)

var listDeviceEvents* = Call_ListDeviceEvents_607968(name: "listDeviceEvents",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListDeviceEvents",
    validator: validate_ListDeviceEvents_607969, base: "/",
    url: url_ListDeviceEvents_607970, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGatewayGroups_607986 = ref object of OpenApiRestCall_606589
proc url_ListGatewayGroups_607988(protocol: Scheme; host: string; base: string;
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

proc validate_ListGatewayGroups_607987(path: JsonNode; query: JsonNode;
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
  var valid_607989 = query.getOrDefault("MaxResults")
  valid_607989 = validateParameter(valid_607989, JString, required = false,
                                 default = nil)
  if valid_607989 != nil:
    section.add "MaxResults", valid_607989
  var valid_607990 = query.getOrDefault("NextToken")
  valid_607990 = validateParameter(valid_607990, JString, required = false,
                                 default = nil)
  if valid_607990 != nil:
    section.add "NextToken", valid_607990
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
  var valid_607991 = header.getOrDefault("X-Amz-Target")
  valid_607991 = validateParameter(valid_607991, JString, required = true, default = newJString(
      "AlexaForBusiness.ListGatewayGroups"))
  if valid_607991 != nil:
    section.add "X-Amz-Target", valid_607991
  var valid_607992 = header.getOrDefault("X-Amz-Signature")
  valid_607992 = validateParameter(valid_607992, JString, required = false,
                                 default = nil)
  if valid_607992 != nil:
    section.add "X-Amz-Signature", valid_607992
  var valid_607993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607993 = validateParameter(valid_607993, JString, required = false,
                                 default = nil)
  if valid_607993 != nil:
    section.add "X-Amz-Content-Sha256", valid_607993
  var valid_607994 = header.getOrDefault("X-Amz-Date")
  valid_607994 = validateParameter(valid_607994, JString, required = false,
                                 default = nil)
  if valid_607994 != nil:
    section.add "X-Amz-Date", valid_607994
  var valid_607995 = header.getOrDefault("X-Amz-Credential")
  valid_607995 = validateParameter(valid_607995, JString, required = false,
                                 default = nil)
  if valid_607995 != nil:
    section.add "X-Amz-Credential", valid_607995
  var valid_607996 = header.getOrDefault("X-Amz-Security-Token")
  valid_607996 = validateParameter(valid_607996, JString, required = false,
                                 default = nil)
  if valid_607996 != nil:
    section.add "X-Amz-Security-Token", valid_607996
  var valid_607997 = header.getOrDefault("X-Amz-Algorithm")
  valid_607997 = validateParameter(valid_607997, JString, required = false,
                                 default = nil)
  if valid_607997 != nil:
    section.add "X-Amz-Algorithm", valid_607997
  var valid_607998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607998 = validateParameter(valid_607998, JString, required = false,
                                 default = nil)
  if valid_607998 != nil:
    section.add "X-Amz-SignedHeaders", valid_607998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608000: Call_ListGatewayGroups_607986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
  ## 
  let valid = call_608000.validator(path, query, header, formData, body)
  let scheme = call_608000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608000.url(scheme.get, call_608000.host, call_608000.base,
                         call_608000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608000, url, valid)

proc call*(call_608001: Call_ListGatewayGroups_607986; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGatewayGroups
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_608002 = newJObject()
  var body_608003 = newJObject()
  add(query_608002, "MaxResults", newJString(MaxResults))
  add(query_608002, "NextToken", newJString(NextToken))
  if body != nil:
    body_608003 = body
  result = call_608001.call(nil, query_608002, nil, nil, body_608003)

var listGatewayGroups* = Call_ListGatewayGroups_607986(name: "listGatewayGroups",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListGatewayGroups",
    validator: validate_ListGatewayGroups_607987, base: "/",
    url: url_ListGatewayGroups_607988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGateways_608004 = ref object of OpenApiRestCall_606589
proc url_ListGateways_608006(protocol: Scheme; host: string; base: string;
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

proc validate_ListGateways_608005(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608007 = query.getOrDefault("MaxResults")
  valid_608007 = validateParameter(valid_608007, JString, required = false,
                                 default = nil)
  if valid_608007 != nil:
    section.add "MaxResults", valid_608007
  var valid_608008 = query.getOrDefault("NextToken")
  valid_608008 = validateParameter(valid_608008, JString, required = false,
                                 default = nil)
  if valid_608008 != nil:
    section.add "NextToken", valid_608008
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
  var valid_608009 = header.getOrDefault("X-Amz-Target")
  valid_608009 = validateParameter(valid_608009, JString, required = true, default = newJString(
      "AlexaForBusiness.ListGateways"))
  if valid_608009 != nil:
    section.add "X-Amz-Target", valid_608009
  var valid_608010 = header.getOrDefault("X-Amz-Signature")
  valid_608010 = validateParameter(valid_608010, JString, required = false,
                                 default = nil)
  if valid_608010 != nil:
    section.add "X-Amz-Signature", valid_608010
  var valid_608011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608011 = validateParameter(valid_608011, JString, required = false,
                                 default = nil)
  if valid_608011 != nil:
    section.add "X-Amz-Content-Sha256", valid_608011
  var valid_608012 = header.getOrDefault("X-Amz-Date")
  valid_608012 = validateParameter(valid_608012, JString, required = false,
                                 default = nil)
  if valid_608012 != nil:
    section.add "X-Amz-Date", valid_608012
  var valid_608013 = header.getOrDefault("X-Amz-Credential")
  valid_608013 = validateParameter(valid_608013, JString, required = false,
                                 default = nil)
  if valid_608013 != nil:
    section.add "X-Amz-Credential", valid_608013
  var valid_608014 = header.getOrDefault("X-Amz-Security-Token")
  valid_608014 = validateParameter(valid_608014, JString, required = false,
                                 default = nil)
  if valid_608014 != nil:
    section.add "X-Amz-Security-Token", valid_608014
  var valid_608015 = header.getOrDefault("X-Amz-Algorithm")
  valid_608015 = validateParameter(valid_608015, JString, required = false,
                                 default = nil)
  if valid_608015 != nil:
    section.add "X-Amz-Algorithm", valid_608015
  var valid_608016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608016 = validateParameter(valid_608016, JString, required = false,
                                 default = nil)
  if valid_608016 != nil:
    section.add "X-Amz-SignedHeaders", valid_608016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608018: Call_ListGateways_608004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
  ## 
  let valid = call_608018.validator(path, query, header, formData, body)
  let scheme = call_608018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608018.url(scheme.get, call_608018.host, call_608018.base,
                         call_608018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608018, url, valid)

proc call*(call_608019: Call_ListGateways_608004; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGateways
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_608020 = newJObject()
  var body_608021 = newJObject()
  add(query_608020, "MaxResults", newJString(MaxResults))
  add(query_608020, "NextToken", newJString(NextToken))
  if body != nil:
    body_608021 = body
  result = call_608019.call(nil, query_608020, nil, nil, body_608021)

var listGateways* = Call_ListGateways_608004(name: "listGateways",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListGateways",
    validator: validate_ListGateways_608005, base: "/", url: url_ListGateways_608006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkills_608022 = ref object of OpenApiRestCall_606589
proc url_ListSkills_608024(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListSkills_608023(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608025 = query.getOrDefault("MaxResults")
  valid_608025 = validateParameter(valid_608025, JString, required = false,
                                 default = nil)
  if valid_608025 != nil:
    section.add "MaxResults", valid_608025
  var valid_608026 = query.getOrDefault("NextToken")
  valid_608026 = validateParameter(valid_608026, JString, required = false,
                                 default = nil)
  if valid_608026 != nil:
    section.add "NextToken", valid_608026
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
  var valid_608027 = header.getOrDefault("X-Amz-Target")
  valid_608027 = validateParameter(valid_608027, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkills"))
  if valid_608027 != nil:
    section.add "X-Amz-Target", valid_608027
  var valid_608028 = header.getOrDefault("X-Amz-Signature")
  valid_608028 = validateParameter(valid_608028, JString, required = false,
                                 default = nil)
  if valid_608028 != nil:
    section.add "X-Amz-Signature", valid_608028
  var valid_608029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608029 = validateParameter(valid_608029, JString, required = false,
                                 default = nil)
  if valid_608029 != nil:
    section.add "X-Amz-Content-Sha256", valid_608029
  var valid_608030 = header.getOrDefault("X-Amz-Date")
  valid_608030 = validateParameter(valid_608030, JString, required = false,
                                 default = nil)
  if valid_608030 != nil:
    section.add "X-Amz-Date", valid_608030
  var valid_608031 = header.getOrDefault("X-Amz-Credential")
  valid_608031 = validateParameter(valid_608031, JString, required = false,
                                 default = nil)
  if valid_608031 != nil:
    section.add "X-Amz-Credential", valid_608031
  var valid_608032 = header.getOrDefault("X-Amz-Security-Token")
  valid_608032 = validateParameter(valid_608032, JString, required = false,
                                 default = nil)
  if valid_608032 != nil:
    section.add "X-Amz-Security-Token", valid_608032
  var valid_608033 = header.getOrDefault("X-Amz-Algorithm")
  valid_608033 = validateParameter(valid_608033, JString, required = false,
                                 default = nil)
  if valid_608033 != nil:
    section.add "X-Amz-Algorithm", valid_608033
  var valid_608034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608034 = validateParameter(valid_608034, JString, required = false,
                                 default = nil)
  if valid_608034 != nil:
    section.add "X-Amz-SignedHeaders", valid_608034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608036: Call_ListSkills_608022; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all enabled skills in a specific skill group.
  ## 
  let valid = call_608036.validator(path, query, header, formData, body)
  let scheme = call_608036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608036.url(scheme.get, call_608036.host, call_608036.base,
                         call_608036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608036, url, valid)

proc call*(call_608037: Call_ListSkills_608022; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSkills
  ## Lists all enabled skills in a specific skill group.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_608038 = newJObject()
  var body_608039 = newJObject()
  add(query_608038, "MaxResults", newJString(MaxResults))
  add(query_608038, "NextToken", newJString(NextToken))
  if body != nil:
    body_608039 = body
  result = call_608037.call(nil, query_608038, nil, nil, body_608039)

var listSkills* = Call_ListSkills_608022(name: "listSkills",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ListSkills",
                                      validator: validate_ListSkills_608023,
                                      base: "/", url: url_ListSkills_608024,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkillsStoreCategories_608040 = ref object of OpenApiRestCall_606589
proc url_ListSkillsStoreCategories_608042(protocol: Scheme; host: string;
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

proc validate_ListSkillsStoreCategories_608041(path: JsonNode; query: JsonNode;
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
  var valid_608043 = query.getOrDefault("MaxResults")
  valid_608043 = validateParameter(valid_608043, JString, required = false,
                                 default = nil)
  if valid_608043 != nil:
    section.add "MaxResults", valid_608043
  var valid_608044 = query.getOrDefault("NextToken")
  valid_608044 = validateParameter(valid_608044, JString, required = false,
                                 default = nil)
  if valid_608044 != nil:
    section.add "NextToken", valid_608044
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
  var valid_608045 = header.getOrDefault("X-Amz-Target")
  valid_608045 = validateParameter(valid_608045, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkillsStoreCategories"))
  if valid_608045 != nil:
    section.add "X-Amz-Target", valid_608045
  var valid_608046 = header.getOrDefault("X-Amz-Signature")
  valid_608046 = validateParameter(valid_608046, JString, required = false,
                                 default = nil)
  if valid_608046 != nil:
    section.add "X-Amz-Signature", valid_608046
  var valid_608047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608047 = validateParameter(valid_608047, JString, required = false,
                                 default = nil)
  if valid_608047 != nil:
    section.add "X-Amz-Content-Sha256", valid_608047
  var valid_608048 = header.getOrDefault("X-Amz-Date")
  valid_608048 = validateParameter(valid_608048, JString, required = false,
                                 default = nil)
  if valid_608048 != nil:
    section.add "X-Amz-Date", valid_608048
  var valid_608049 = header.getOrDefault("X-Amz-Credential")
  valid_608049 = validateParameter(valid_608049, JString, required = false,
                                 default = nil)
  if valid_608049 != nil:
    section.add "X-Amz-Credential", valid_608049
  var valid_608050 = header.getOrDefault("X-Amz-Security-Token")
  valid_608050 = validateParameter(valid_608050, JString, required = false,
                                 default = nil)
  if valid_608050 != nil:
    section.add "X-Amz-Security-Token", valid_608050
  var valid_608051 = header.getOrDefault("X-Amz-Algorithm")
  valid_608051 = validateParameter(valid_608051, JString, required = false,
                                 default = nil)
  if valid_608051 != nil:
    section.add "X-Amz-Algorithm", valid_608051
  var valid_608052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608052 = validateParameter(valid_608052, JString, required = false,
                                 default = nil)
  if valid_608052 != nil:
    section.add "X-Amz-SignedHeaders", valid_608052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608054: Call_ListSkillsStoreCategories_608040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all categories in the Alexa skill store.
  ## 
  let valid = call_608054.validator(path, query, header, formData, body)
  let scheme = call_608054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608054.url(scheme.get, call_608054.host, call_608054.base,
                         call_608054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608054, url, valid)

proc call*(call_608055: Call_ListSkillsStoreCategories_608040; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSkillsStoreCategories
  ## Lists all categories in the Alexa skill store.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_608056 = newJObject()
  var body_608057 = newJObject()
  add(query_608056, "MaxResults", newJString(MaxResults))
  add(query_608056, "NextToken", newJString(NextToken))
  if body != nil:
    body_608057 = body
  result = call_608055.call(nil, query_608056, nil, nil, body_608057)

var listSkillsStoreCategories* = Call_ListSkillsStoreCategories_608040(
    name: "listSkillsStoreCategories", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSkillsStoreCategories",
    validator: validate_ListSkillsStoreCategories_608041, base: "/",
    url: url_ListSkillsStoreCategories_608042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkillsStoreSkillsByCategory_608058 = ref object of OpenApiRestCall_606589
proc url_ListSkillsStoreSkillsByCategory_608060(protocol: Scheme; host: string;
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

proc validate_ListSkillsStoreSkillsByCategory_608059(path: JsonNode;
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
  var valid_608061 = query.getOrDefault("MaxResults")
  valid_608061 = validateParameter(valid_608061, JString, required = false,
                                 default = nil)
  if valid_608061 != nil:
    section.add "MaxResults", valid_608061
  var valid_608062 = query.getOrDefault("NextToken")
  valid_608062 = validateParameter(valid_608062, JString, required = false,
                                 default = nil)
  if valid_608062 != nil:
    section.add "NextToken", valid_608062
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
  var valid_608063 = header.getOrDefault("X-Amz-Target")
  valid_608063 = validateParameter(valid_608063, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkillsStoreSkillsByCategory"))
  if valid_608063 != nil:
    section.add "X-Amz-Target", valid_608063
  var valid_608064 = header.getOrDefault("X-Amz-Signature")
  valid_608064 = validateParameter(valid_608064, JString, required = false,
                                 default = nil)
  if valid_608064 != nil:
    section.add "X-Amz-Signature", valid_608064
  var valid_608065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608065 = validateParameter(valid_608065, JString, required = false,
                                 default = nil)
  if valid_608065 != nil:
    section.add "X-Amz-Content-Sha256", valid_608065
  var valid_608066 = header.getOrDefault("X-Amz-Date")
  valid_608066 = validateParameter(valid_608066, JString, required = false,
                                 default = nil)
  if valid_608066 != nil:
    section.add "X-Amz-Date", valid_608066
  var valid_608067 = header.getOrDefault("X-Amz-Credential")
  valid_608067 = validateParameter(valid_608067, JString, required = false,
                                 default = nil)
  if valid_608067 != nil:
    section.add "X-Amz-Credential", valid_608067
  var valid_608068 = header.getOrDefault("X-Amz-Security-Token")
  valid_608068 = validateParameter(valid_608068, JString, required = false,
                                 default = nil)
  if valid_608068 != nil:
    section.add "X-Amz-Security-Token", valid_608068
  var valid_608069 = header.getOrDefault("X-Amz-Algorithm")
  valid_608069 = validateParameter(valid_608069, JString, required = false,
                                 default = nil)
  if valid_608069 != nil:
    section.add "X-Amz-Algorithm", valid_608069
  var valid_608070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608070 = validateParameter(valid_608070, JString, required = false,
                                 default = nil)
  if valid_608070 != nil:
    section.add "X-Amz-SignedHeaders", valid_608070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608072: Call_ListSkillsStoreSkillsByCategory_608058;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all skills in the Alexa skill store by category.
  ## 
  let valid = call_608072.validator(path, query, header, formData, body)
  let scheme = call_608072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608072.url(scheme.get, call_608072.host, call_608072.base,
                         call_608072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608072, url, valid)

proc call*(call_608073: Call_ListSkillsStoreSkillsByCategory_608058;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSkillsStoreSkillsByCategory
  ## Lists all skills in the Alexa skill store by category.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_608074 = newJObject()
  var body_608075 = newJObject()
  add(query_608074, "MaxResults", newJString(MaxResults))
  add(query_608074, "NextToken", newJString(NextToken))
  if body != nil:
    body_608075 = body
  result = call_608073.call(nil, query_608074, nil, nil, body_608075)

var listSkillsStoreSkillsByCategory* = Call_ListSkillsStoreSkillsByCategory_608058(
    name: "listSkillsStoreSkillsByCategory", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSkillsStoreSkillsByCategory",
    validator: validate_ListSkillsStoreSkillsByCategory_608059, base: "/",
    url: url_ListSkillsStoreSkillsByCategory_608060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSmartHomeAppliances_608076 = ref object of OpenApiRestCall_606589
proc url_ListSmartHomeAppliances_608078(protocol: Scheme; host: string; base: string;
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

proc validate_ListSmartHomeAppliances_608077(path: JsonNode; query: JsonNode;
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
  var valid_608079 = query.getOrDefault("MaxResults")
  valid_608079 = validateParameter(valid_608079, JString, required = false,
                                 default = nil)
  if valid_608079 != nil:
    section.add "MaxResults", valid_608079
  var valid_608080 = query.getOrDefault("NextToken")
  valid_608080 = validateParameter(valid_608080, JString, required = false,
                                 default = nil)
  if valid_608080 != nil:
    section.add "NextToken", valid_608080
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
  var valid_608081 = header.getOrDefault("X-Amz-Target")
  valid_608081 = validateParameter(valid_608081, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSmartHomeAppliances"))
  if valid_608081 != nil:
    section.add "X-Amz-Target", valid_608081
  var valid_608082 = header.getOrDefault("X-Amz-Signature")
  valid_608082 = validateParameter(valid_608082, JString, required = false,
                                 default = nil)
  if valid_608082 != nil:
    section.add "X-Amz-Signature", valid_608082
  var valid_608083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608083 = validateParameter(valid_608083, JString, required = false,
                                 default = nil)
  if valid_608083 != nil:
    section.add "X-Amz-Content-Sha256", valid_608083
  var valid_608084 = header.getOrDefault("X-Amz-Date")
  valid_608084 = validateParameter(valid_608084, JString, required = false,
                                 default = nil)
  if valid_608084 != nil:
    section.add "X-Amz-Date", valid_608084
  var valid_608085 = header.getOrDefault("X-Amz-Credential")
  valid_608085 = validateParameter(valid_608085, JString, required = false,
                                 default = nil)
  if valid_608085 != nil:
    section.add "X-Amz-Credential", valid_608085
  var valid_608086 = header.getOrDefault("X-Amz-Security-Token")
  valid_608086 = validateParameter(valid_608086, JString, required = false,
                                 default = nil)
  if valid_608086 != nil:
    section.add "X-Amz-Security-Token", valid_608086
  var valid_608087 = header.getOrDefault("X-Amz-Algorithm")
  valid_608087 = validateParameter(valid_608087, JString, required = false,
                                 default = nil)
  if valid_608087 != nil:
    section.add "X-Amz-Algorithm", valid_608087
  var valid_608088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608088 = validateParameter(valid_608088, JString, required = false,
                                 default = nil)
  if valid_608088 != nil:
    section.add "X-Amz-SignedHeaders", valid_608088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608090: Call_ListSmartHomeAppliances_608076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all of the smart home appliances associated with a room.
  ## 
  let valid = call_608090.validator(path, query, header, formData, body)
  let scheme = call_608090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608090.url(scheme.get, call_608090.host, call_608090.base,
                         call_608090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608090, url, valid)

proc call*(call_608091: Call_ListSmartHomeAppliances_608076; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSmartHomeAppliances
  ## Lists all of the smart home appliances associated with a room.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_608092 = newJObject()
  var body_608093 = newJObject()
  add(query_608092, "MaxResults", newJString(MaxResults))
  add(query_608092, "NextToken", newJString(NextToken))
  if body != nil:
    body_608093 = body
  result = call_608091.call(nil, query_608092, nil, nil, body_608093)

var listSmartHomeAppliances* = Call_ListSmartHomeAppliances_608076(
    name: "listSmartHomeAppliances", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSmartHomeAppliances",
    validator: validate_ListSmartHomeAppliances_608077, base: "/",
    url: url_ListSmartHomeAppliances_608078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_608094 = ref object of OpenApiRestCall_606589
proc url_ListTags_608096(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTags_608095(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608097 = query.getOrDefault("MaxResults")
  valid_608097 = validateParameter(valid_608097, JString, required = false,
                                 default = nil)
  if valid_608097 != nil:
    section.add "MaxResults", valid_608097
  var valid_608098 = query.getOrDefault("NextToken")
  valid_608098 = validateParameter(valid_608098, JString, required = false,
                                 default = nil)
  if valid_608098 != nil:
    section.add "NextToken", valid_608098
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
  var valid_608099 = header.getOrDefault("X-Amz-Target")
  valid_608099 = validateParameter(valid_608099, JString, required = true, default = newJString(
      "AlexaForBusiness.ListTags"))
  if valid_608099 != nil:
    section.add "X-Amz-Target", valid_608099
  var valid_608100 = header.getOrDefault("X-Amz-Signature")
  valid_608100 = validateParameter(valid_608100, JString, required = false,
                                 default = nil)
  if valid_608100 != nil:
    section.add "X-Amz-Signature", valid_608100
  var valid_608101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608101 = validateParameter(valid_608101, JString, required = false,
                                 default = nil)
  if valid_608101 != nil:
    section.add "X-Amz-Content-Sha256", valid_608101
  var valid_608102 = header.getOrDefault("X-Amz-Date")
  valid_608102 = validateParameter(valid_608102, JString, required = false,
                                 default = nil)
  if valid_608102 != nil:
    section.add "X-Amz-Date", valid_608102
  var valid_608103 = header.getOrDefault("X-Amz-Credential")
  valid_608103 = validateParameter(valid_608103, JString, required = false,
                                 default = nil)
  if valid_608103 != nil:
    section.add "X-Amz-Credential", valid_608103
  var valid_608104 = header.getOrDefault("X-Amz-Security-Token")
  valid_608104 = validateParameter(valid_608104, JString, required = false,
                                 default = nil)
  if valid_608104 != nil:
    section.add "X-Amz-Security-Token", valid_608104
  var valid_608105 = header.getOrDefault("X-Amz-Algorithm")
  valid_608105 = validateParameter(valid_608105, JString, required = false,
                                 default = nil)
  if valid_608105 != nil:
    section.add "X-Amz-Algorithm", valid_608105
  var valid_608106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608106 = validateParameter(valid_608106, JString, required = false,
                                 default = nil)
  if valid_608106 != nil:
    section.add "X-Amz-SignedHeaders", valid_608106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608108: Call_ListTags_608094; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags for the specified resource.
  ## 
  let valid = call_608108.validator(path, query, header, formData, body)
  let scheme = call_608108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608108.url(scheme.get, call_608108.host, call_608108.base,
                         call_608108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608108, url, valid)

proc call*(call_608109: Call_ListTags_608094; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTags
  ## Lists all tags for the specified resource.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_608110 = newJObject()
  var body_608111 = newJObject()
  add(query_608110, "MaxResults", newJString(MaxResults))
  add(query_608110, "NextToken", newJString(NextToken))
  if body != nil:
    body_608111 = body
  result = call_608109.call(nil, query_608110, nil, nil, body_608111)

var listTags* = Call_ListTags_608094(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ListTags",
                                  validator: validate_ListTags_608095, base: "/",
                                  url: url_ListTags_608096,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConferencePreference_608112 = ref object of OpenApiRestCall_606589
proc url_PutConferencePreference_608114(protocol: Scheme; host: string; base: string;
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

proc validate_PutConferencePreference_608113(path: JsonNode; query: JsonNode;
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
  var valid_608115 = header.getOrDefault("X-Amz-Target")
  valid_608115 = validateParameter(valid_608115, JString, required = true, default = newJString(
      "AlexaForBusiness.PutConferencePreference"))
  if valid_608115 != nil:
    section.add "X-Amz-Target", valid_608115
  var valid_608116 = header.getOrDefault("X-Amz-Signature")
  valid_608116 = validateParameter(valid_608116, JString, required = false,
                                 default = nil)
  if valid_608116 != nil:
    section.add "X-Amz-Signature", valid_608116
  var valid_608117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608117 = validateParameter(valid_608117, JString, required = false,
                                 default = nil)
  if valid_608117 != nil:
    section.add "X-Amz-Content-Sha256", valid_608117
  var valid_608118 = header.getOrDefault("X-Amz-Date")
  valid_608118 = validateParameter(valid_608118, JString, required = false,
                                 default = nil)
  if valid_608118 != nil:
    section.add "X-Amz-Date", valid_608118
  var valid_608119 = header.getOrDefault("X-Amz-Credential")
  valid_608119 = validateParameter(valid_608119, JString, required = false,
                                 default = nil)
  if valid_608119 != nil:
    section.add "X-Amz-Credential", valid_608119
  var valid_608120 = header.getOrDefault("X-Amz-Security-Token")
  valid_608120 = validateParameter(valid_608120, JString, required = false,
                                 default = nil)
  if valid_608120 != nil:
    section.add "X-Amz-Security-Token", valid_608120
  var valid_608121 = header.getOrDefault("X-Amz-Algorithm")
  valid_608121 = validateParameter(valid_608121, JString, required = false,
                                 default = nil)
  if valid_608121 != nil:
    section.add "X-Amz-Algorithm", valid_608121
  var valid_608122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608122 = validateParameter(valid_608122, JString, required = false,
                                 default = nil)
  if valid_608122 != nil:
    section.add "X-Amz-SignedHeaders", valid_608122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608124: Call_PutConferencePreference_608112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the conference preferences on a specific conference provider at the account level.
  ## 
  let valid = call_608124.validator(path, query, header, formData, body)
  let scheme = call_608124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608124.url(scheme.get, call_608124.host, call_608124.base,
                         call_608124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608124, url, valid)

proc call*(call_608125: Call_PutConferencePreference_608112; body: JsonNode): Recallable =
  ## putConferencePreference
  ## Sets the conference preferences on a specific conference provider at the account level.
  ##   body: JObject (required)
  var body_608126 = newJObject()
  if body != nil:
    body_608126 = body
  result = call_608125.call(nil, nil, nil, nil, body_608126)

var putConferencePreference* = Call_PutConferencePreference_608112(
    name: "putConferencePreference", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutConferencePreference",
    validator: validate_PutConferencePreference_608113, base: "/",
    url: url_PutConferencePreference_608114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInvitationConfiguration_608127 = ref object of OpenApiRestCall_606589
proc url_PutInvitationConfiguration_608129(protocol: Scheme; host: string;
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

proc validate_PutInvitationConfiguration_608128(path: JsonNode; query: JsonNode;
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
  var valid_608130 = header.getOrDefault("X-Amz-Target")
  valid_608130 = validateParameter(valid_608130, JString, required = true, default = newJString(
      "AlexaForBusiness.PutInvitationConfiguration"))
  if valid_608130 != nil:
    section.add "X-Amz-Target", valid_608130
  var valid_608131 = header.getOrDefault("X-Amz-Signature")
  valid_608131 = validateParameter(valid_608131, JString, required = false,
                                 default = nil)
  if valid_608131 != nil:
    section.add "X-Amz-Signature", valid_608131
  var valid_608132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608132 = validateParameter(valid_608132, JString, required = false,
                                 default = nil)
  if valid_608132 != nil:
    section.add "X-Amz-Content-Sha256", valid_608132
  var valid_608133 = header.getOrDefault("X-Amz-Date")
  valid_608133 = validateParameter(valid_608133, JString, required = false,
                                 default = nil)
  if valid_608133 != nil:
    section.add "X-Amz-Date", valid_608133
  var valid_608134 = header.getOrDefault("X-Amz-Credential")
  valid_608134 = validateParameter(valid_608134, JString, required = false,
                                 default = nil)
  if valid_608134 != nil:
    section.add "X-Amz-Credential", valid_608134
  var valid_608135 = header.getOrDefault("X-Amz-Security-Token")
  valid_608135 = validateParameter(valid_608135, JString, required = false,
                                 default = nil)
  if valid_608135 != nil:
    section.add "X-Amz-Security-Token", valid_608135
  var valid_608136 = header.getOrDefault("X-Amz-Algorithm")
  valid_608136 = validateParameter(valid_608136, JString, required = false,
                                 default = nil)
  if valid_608136 != nil:
    section.add "X-Amz-Algorithm", valid_608136
  var valid_608137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608137 = validateParameter(valid_608137, JString, required = false,
                                 default = nil)
  if valid_608137 != nil:
    section.add "X-Amz-SignedHeaders", valid_608137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608139: Call_PutInvitationConfiguration_608127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the email template for the user enrollment invitation with the specified attributes.
  ## 
  let valid = call_608139.validator(path, query, header, formData, body)
  let scheme = call_608139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608139.url(scheme.get, call_608139.host, call_608139.base,
                         call_608139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608139, url, valid)

proc call*(call_608140: Call_PutInvitationConfiguration_608127; body: JsonNode): Recallable =
  ## putInvitationConfiguration
  ## Configures the email template for the user enrollment invitation with the specified attributes.
  ##   body: JObject (required)
  var body_608141 = newJObject()
  if body != nil:
    body_608141 = body
  result = call_608140.call(nil, nil, nil, nil, body_608141)

var putInvitationConfiguration* = Call_PutInvitationConfiguration_608127(
    name: "putInvitationConfiguration", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutInvitationConfiguration",
    validator: validate_PutInvitationConfiguration_608128, base: "/",
    url: url_PutInvitationConfiguration_608129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRoomSkillParameter_608142 = ref object of OpenApiRestCall_606589
proc url_PutRoomSkillParameter_608144(protocol: Scheme; host: string; base: string;
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

proc validate_PutRoomSkillParameter_608143(path: JsonNode; query: JsonNode;
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
  var valid_608145 = header.getOrDefault("X-Amz-Target")
  valid_608145 = validateParameter(valid_608145, JString, required = true, default = newJString(
      "AlexaForBusiness.PutRoomSkillParameter"))
  if valid_608145 != nil:
    section.add "X-Amz-Target", valid_608145
  var valid_608146 = header.getOrDefault("X-Amz-Signature")
  valid_608146 = validateParameter(valid_608146, JString, required = false,
                                 default = nil)
  if valid_608146 != nil:
    section.add "X-Amz-Signature", valid_608146
  var valid_608147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608147 = validateParameter(valid_608147, JString, required = false,
                                 default = nil)
  if valid_608147 != nil:
    section.add "X-Amz-Content-Sha256", valid_608147
  var valid_608148 = header.getOrDefault("X-Amz-Date")
  valid_608148 = validateParameter(valid_608148, JString, required = false,
                                 default = nil)
  if valid_608148 != nil:
    section.add "X-Amz-Date", valid_608148
  var valid_608149 = header.getOrDefault("X-Amz-Credential")
  valid_608149 = validateParameter(valid_608149, JString, required = false,
                                 default = nil)
  if valid_608149 != nil:
    section.add "X-Amz-Credential", valid_608149
  var valid_608150 = header.getOrDefault("X-Amz-Security-Token")
  valid_608150 = validateParameter(valid_608150, JString, required = false,
                                 default = nil)
  if valid_608150 != nil:
    section.add "X-Amz-Security-Token", valid_608150
  var valid_608151 = header.getOrDefault("X-Amz-Algorithm")
  valid_608151 = validateParameter(valid_608151, JString, required = false,
                                 default = nil)
  if valid_608151 != nil:
    section.add "X-Amz-Algorithm", valid_608151
  var valid_608152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608152 = validateParameter(valid_608152, JString, required = false,
                                 default = nil)
  if valid_608152 != nil:
    section.add "X-Amz-SignedHeaders", valid_608152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608154: Call_PutRoomSkillParameter_608142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room skill parameter details by room, skill, and parameter key ID. Not all skills have a room skill parameter.
  ## 
  let valid = call_608154.validator(path, query, header, formData, body)
  let scheme = call_608154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608154.url(scheme.get, call_608154.host, call_608154.base,
                         call_608154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608154, url, valid)

proc call*(call_608155: Call_PutRoomSkillParameter_608142; body: JsonNode): Recallable =
  ## putRoomSkillParameter
  ## Updates room skill parameter details by room, skill, and parameter key ID. Not all skills have a room skill parameter.
  ##   body: JObject (required)
  var body_608156 = newJObject()
  if body != nil:
    body_608156 = body
  result = call_608155.call(nil, nil, nil, nil, body_608156)

var putRoomSkillParameter* = Call_PutRoomSkillParameter_608142(
    name: "putRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutRoomSkillParameter",
    validator: validate_PutRoomSkillParameter_608143, base: "/",
    url: url_PutRoomSkillParameter_608144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSkillAuthorization_608157 = ref object of OpenApiRestCall_606589
proc url_PutSkillAuthorization_608159(protocol: Scheme; host: string; base: string;
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

proc validate_PutSkillAuthorization_608158(path: JsonNode; query: JsonNode;
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
  var valid_608160 = header.getOrDefault("X-Amz-Target")
  valid_608160 = validateParameter(valid_608160, JString, required = true, default = newJString(
      "AlexaForBusiness.PutSkillAuthorization"))
  if valid_608160 != nil:
    section.add "X-Amz-Target", valid_608160
  var valid_608161 = header.getOrDefault("X-Amz-Signature")
  valid_608161 = validateParameter(valid_608161, JString, required = false,
                                 default = nil)
  if valid_608161 != nil:
    section.add "X-Amz-Signature", valid_608161
  var valid_608162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608162 = validateParameter(valid_608162, JString, required = false,
                                 default = nil)
  if valid_608162 != nil:
    section.add "X-Amz-Content-Sha256", valid_608162
  var valid_608163 = header.getOrDefault("X-Amz-Date")
  valid_608163 = validateParameter(valid_608163, JString, required = false,
                                 default = nil)
  if valid_608163 != nil:
    section.add "X-Amz-Date", valid_608163
  var valid_608164 = header.getOrDefault("X-Amz-Credential")
  valid_608164 = validateParameter(valid_608164, JString, required = false,
                                 default = nil)
  if valid_608164 != nil:
    section.add "X-Amz-Credential", valid_608164
  var valid_608165 = header.getOrDefault("X-Amz-Security-Token")
  valid_608165 = validateParameter(valid_608165, JString, required = false,
                                 default = nil)
  if valid_608165 != nil:
    section.add "X-Amz-Security-Token", valid_608165
  var valid_608166 = header.getOrDefault("X-Amz-Algorithm")
  valid_608166 = validateParameter(valid_608166, JString, required = false,
                                 default = nil)
  if valid_608166 != nil:
    section.add "X-Amz-Algorithm", valid_608166
  var valid_608167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608167 = validateParameter(valid_608167, JString, required = false,
                                 default = nil)
  if valid_608167 != nil:
    section.add "X-Amz-SignedHeaders", valid_608167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608169: Call_PutSkillAuthorization_608157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Links a user's account to a third-party skill provider. If this API operation is called by an assumed IAM role, the skill being linked must be a private skill. Also, the skill must be owned by the AWS account that assumed the IAM role.
  ## 
  let valid = call_608169.validator(path, query, header, formData, body)
  let scheme = call_608169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608169.url(scheme.get, call_608169.host, call_608169.base,
                         call_608169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608169, url, valid)

proc call*(call_608170: Call_PutSkillAuthorization_608157; body: JsonNode): Recallable =
  ## putSkillAuthorization
  ## Links a user's account to a third-party skill provider. If this API operation is called by an assumed IAM role, the skill being linked must be a private skill. Also, the skill must be owned by the AWS account that assumed the IAM role.
  ##   body: JObject (required)
  var body_608171 = newJObject()
  if body != nil:
    body_608171 = body
  result = call_608170.call(nil, nil, nil, nil, body_608171)

var putSkillAuthorization* = Call_PutSkillAuthorization_608157(
    name: "putSkillAuthorization", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutSkillAuthorization",
    validator: validate_PutSkillAuthorization_608158, base: "/",
    url: url_PutSkillAuthorization_608159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterAVSDevice_608172 = ref object of OpenApiRestCall_606589
proc url_RegisterAVSDevice_608174(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterAVSDevice_608173(path: JsonNode; query: JsonNode;
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
  var valid_608175 = header.getOrDefault("X-Amz-Target")
  valid_608175 = validateParameter(valid_608175, JString, required = true, default = newJString(
      "AlexaForBusiness.RegisterAVSDevice"))
  if valid_608175 != nil:
    section.add "X-Amz-Target", valid_608175
  var valid_608176 = header.getOrDefault("X-Amz-Signature")
  valid_608176 = validateParameter(valid_608176, JString, required = false,
                                 default = nil)
  if valid_608176 != nil:
    section.add "X-Amz-Signature", valid_608176
  var valid_608177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608177 = validateParameter(valid_608177, JString, required = false,
                                 default = nil)
  if valid_608177 != nil:
    section.add "X-Amz-Content-Sha256", valid_608177
  var valid_608178 = header.getOrDefault("X-Amz-Date")
  valid_608178 = validateParameter(valid_608178, JString, required = false,
                                 default = nil)
  if valid_608178 != nil:
    section.add "X-Amz-Date", valid_608178
  var valid_608179 = header.getOrDefault("X-Amz-Credential")
  valid_608179 = validateParameter(valid_608179, JString, required = false,
                                 default = nil)
  if valid_608179 != nil:
    section.add "X-Amz-Credential", valid_608179
  var valid_608180 = header.getOrDefault("X-Amz-Security-Token")
  valid_608180 = validateParameter(valid_608180, JString, required = false,
                                 default = nil)
  if valid_608180 != nil:
    section.add "X-Amz-Security-Token", valid_608180
  var valid_608181 = header.getOrDefault("X-Amz-Algorithm")
  valid_608181 = validateParameter(valid_608181, JString, required = false,
                                 default = nil)
  if valid_608181 != nil:
    section.add "X-Amz-Algorithm", valid_608181
  var valid_608182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608182 = validateParameter(valid_608182, JString, required = false,
                                 default = nil)
  if valid_608182 != nil:
    section.add "X-Amz-SignedHeaders", valid_608182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608184: Call_RegisterAVSDevice_608172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers an Alexa-enabled device built by an Original Equipment Manufacturer (OEM) using Alexa Voice Service (AVS).
  ## 
  let valid = call_608184.validator(path, query, header, formData, body)
  let scheme = call_608184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608184.url(scheme.get, call_608184.host, call_608184.base,
                         call_608184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608184, url, valid)

proc call*(call_608185: Call_RegisterAVSDevice_608172; body: JsonNode): Recallable =
  ## registerAVSDevice
  ## Registers an Alexa-enabled device built by an Original Equipment Manufacturer (OEM) using Alexa Voice Service (AVS).
  ##   body: JObject (required)
  var body_608186 = newJObject()
  if body != nil:
    body_608186 = body
  result = call_608185.call(nil, nil, nil, nil, body_608186)

var registerAVSDevice* = Call_RegisterAVSDevice_608172(name: "registerAVSDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.RegisterAVSDevice",
    validator: validate_RegisterAVSDevice_608173, base: "/",
    url: url_RegisterAVSDevice_608174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectSkill_608187 = ref object of OpenApiRestCall_606589
proc url_RejectSkill_608189(protocol: Scheme; host: string; base: string;
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

proc validate_RejectSkill_608188(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608190 = header.getOrDefault("X-Amz-Target")
  valid_608190 = validateParameter(valid_608190, JString, required = true, default = newJString(
      "AlexaForBusiness.RejectSkill"))
  if valid_608190 != nil:
    section.add "X-Amz-Target", valid_608190
  var valid_608191 = header.getOrDefault("X-Amz-Signature")
  valid_608191 = validateParameter(valid_608191, JString, required = false,
                                 default = nil)
  if valid_608191 != nil:
    section.add "X-Amz-Signature", valid_608191
  var valid_608192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608192 = validateParameter(valid_608192, JString, required = false,
                                 default = nil)
  if valid_608192 != nil:
    section.add "X-Amz-Content-Sha256", valid_608192
  var valid_608193 = header.getOrDefault("X-Amz-Date")
  valid_608193 = validateParameter(valid_608193, JString, required = false,
                                 default = nil)
  if valid_608193 != nil:
    section.add "X-Amz-Date", valid_608193
  var valid_608194 = header.getOrDefault("X-Amz-Credential")
  valid_608194 = validateParameter(valid_608194, JString, required = false,
                                 default = nil)
  if valid_608194 != nil:
    section.add "X-Amz-Credential", valid_608194
  var valid_608195 = header.getOrDefault("X-Amz-Security-Token")
  valid_608195 = validateParameter(valid_608195, JString, required = false,
                                 default = nil)
  if valid_608195 != nil:
    section.add "X-Amz-Security-Token", valid_608195
  var valid_608196 = header.getOrDefault("X-Amz-Algorithm")
  valid_608196 = validateParameter(valid_608196, JString, required = false,
                                 default = nil)
  if valid_608196 != nil:
    section.add "X-Amz-Algorithm", valid_608196
  var valid_608197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608197 = validateParameter(valid_608197, JString, required = false,
                                 default = nil)
  if valid_608197 != nil:
    section.add "X-Amz-SignedHeaders", valid_608197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608199: Call_RejectSkill_608187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a skill from the organization under a user's AWS account. If the skill is a private skill, it moves to an AcceptStatus of PENDING. Any private or public skill that is rejected can be added later by calling the ApproveSkill API. 
  ## 
  let valid = call_608199.validator(path, query, header, formData, body)
  let scheme = call_608199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608199.url(scheme.get, call_608199.host, call_608199.base,
                         call_608199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608199, url, valid)

proc call*(call_608200: Call_RejectSkill_608187; body: JsonNode): Recallable =
  ## rejectSkill
  ## Disassociates a skill from the organization under a user's AWS account. If the skill is a private skill, it moves to an AcceptStatus of PENDING. Any private or public skill that is rejected can be added later by calling the ApproveSkill API. 
  ##   body: JObject (required)
  var body_608201 = newJObject()
  if body != nil:
    body_608201 = body
  result = call_608200.call(nil, nil, nil, nil, body_608201)

var rejectSkill* = Call_RejectSkill_608187(name: "rejectSkill",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.RejectSkill",
                                        validator: validate_RejectSkill_608188,
                                        base: "/", url: url_RejectSkill_608189,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResolveRoom_608202 = ref object of OpenApiRestCall_606589
proc url_ResolveRoom_608204(protocol: Scheme; host: string; base: string;
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

proc validate_ResolveRoom_608203(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608205 = header.getOrDefault("X-Amz-Target")
  valid_608205 = validateParameter(valid_608205, JString, required = true, default = newJString(
      "AlexaForBusiness.ResolveRoom"))
  if valid_608205 != nil:
    section.add "X-Amz-Target", valid_608205
  var valid_608206 = header.getOrDefault("X-Amz-Signature")
  valid_608206 = validateParameter(valid_608206, JString, required = false,
                                 default = nil)
  if valid_608206 != nil:
    section.add "X-Amz-Signature", valid_608206
  var valid_608207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608207 = validateParameter(valid_608207, JString, required = false,
                                 default = nil)
  if valid_608207 != nil:
    section.add "X-Amz-Content-Sha256", valid_608207
  var valid_608208 = header.getOrDefault("X-Amz-Date")
  valid_608208 = validateParameter(valid_608208, JString, required = false,
                                 default = nil)
  if valid_608208 != nil:
    section.add "X-Amz-Date", valid_608208
  var valid_608209 = header.getOrDefault("X-Amz-Credential")
  valid_608209 = validateParameter(valid_608209, JString, required = false,
                                 default = nil)
  if valid_608209 != nil:
    section.add "X-Amz-Credential", valid_608209
  var valid_608210 = header.getOrDefault("X-Amz-Security-Token")
  valid_608210 = validateParameter(valid_608210, JString, required = false,
                                 default = nil)
  if valid_608210 != nil:
    section.add "X-Amz-Security-Token", valid_608210
  var valid_608211 = header.getOrDefault("X-Amz-Algorithm")
  valid_608211 = validateParameter(valid_608211, JString, required = false,
                                 default = nil)
  if valid_608211 != nil:
    section.add "X-Amz-Algorithm", valid_608211
  var valid_608212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608212 = validateParameter(valid_608212, JString, required = false,
                                 default = nil)
  if valid_608212 != nil:
    section.add "X-Amz-SignedHeaders", valid_608212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608214: Call_ResolveRoom_608202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Determines the details for the room from which a skill request was invoked. This operation is used by skill developers.
  ## 
  let valid = call_608214.validator(path, query, header, formData, body)
  let scheme = call_608214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608214.url(scheme.get, call_608214.host, call_608214.base,
                         call_608214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608214, url, valid)

proc call*(call_608215: Call_ResolveRoom_608202; body: JsonNode): Recallable =
  ## resolveRoom
  ## Determines the details for the room from which a skill request was invoked. This operation is used by skill developers.
  ##   body: JObject (required)
  var body_608216 = newJObject()
  if body != nil:
    body_608216 = body
  result = call_608215.call(nil, nil, nil, nil, body_608216)

var resolveRoom* = Call_ResolveRoom_608202(name: "resolveRoom",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ResolveRoom",
                                        validator: validate_ResolveRoom_608203,
                                        base: "/", url: url_ResolveRoom_608204,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeInvitation_608217 = ref object of OpenApiRestCall_606589
proc url_RevokeInvitation_608219(protocol: Scheme; host: string; base: string;
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

proc validate_RevokeInvitation_608218(path: JsonNode; query: JsonNode;
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
  var valid_608220 = header.getOrDefault("X-Amz-Target")
  valid_608220 = validateParameter(valid_608220, JString, required = true, default = newJString(
      "AlexaForBusiness.RevokeInvitation"))
  if valid_608220 != nil:
    section.add "X-Amz-Target", valid_608220
  var valid_608221 = header.getOrDefault("X-Amz-Signature")
  valid_608221 = validateParameter(valid_608221, JString, required = false,
                                 default = nil)
  if valid_608221 != nil:
    section.add "X-Amz-Signature", valid_608221
  var valid_608222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608222 = validateParameter(valid_608222, JString, required = false,
                                 default = nil)
  if valid_608222 != nil:
    section.add "X-Amz-Content-Sha256", valid_608222
  var valid_608223 = header.getOrDefault("X-Amz-Date")
  valid_608223 = validateParameter(valid_608223, JString, required = false,
                                 default = nil)
  if valid_608223 != nil:
    section.add "X-Amz-Date", valid_608223
  var valid_608224 = header.getOrDefault("X-Amz-Credential")
  valid_608224 = validateParameter(valid_608224, JString, required = false,
                                 default = nil)
  if valid_608224 != nil:
    section.add "X-Amz-Credential", valid_608224
  var valid_608225 = header.getOrDefault("X-Amz-Security-Token")
  valid_608225 = validateParameter(valid_608225, JString, required = false,
                                 default = nil)
  if valid_608225 != nil:
    section.add "X-Amz-Security-Token", valid_608225
  var valid_608226 = header.getOrDefault("X-Amz-Algorithm")
  valid_608226 = validateParameter(valid_608226, JString, required = false,
                                 default = nil)
  if valid_608226 != nil:
    section.add "X-Amz-Algorithm", valid_608226
  var valid_608227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608227 = validateParameter(valid_608227, JString, required = false,
                                 default = nil)
  if valid_608227 != nil:
    section.add "X-Amz-SignedHeaders", valid_608227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608229: Call_RevokeInvitation_608217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes an invitation and invalidates the enrollment URL.
  ## 
  let valid = call_608229.validator(path, query, header, formData, body)
  let scheme = call_608229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608229.url(scheme.get, call_608229.host, call_608229.base,
                         call_608229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608229, url, valid)

proc call*(call_608230: Call_RevokeInvitation_608217; body: JsonNode): Recallable =
  ## revokeInvitation
  ## Revokes an invitation and invalidates the enrollment URL.
  ##   body: JObject (required)
  var body_608231 = newJObject()
  if body != nil:
    body_608231 = body
  result = call_608230.call(nil, nil, nil, nil, body_608231)

var revokeInvitation* = Call_RevokeInvitation_608217(name: "revokeInvitation",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.RevokeInvitation",
    validator: validate_RevokeInvitation_608218, base: "/",
    url: url_RevokeInvitation_608219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAddressBooks_608232 = ref object of OpenApiRestCall_606589
proc url_SearchAddressBooks_608234(protocol: Scheme; host: string; base: string;
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

proc validate_SearchAddressBooks_608233(path: JsonNode; query: JsonNode;
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
  var valid_608235 = query.getOrDefault("MaxResults")
  valid_608235 = validateParameter(valid_608235, JString, required = false,
                                 default = nil)
  if valid_608235 != nil:
    section.add "MaxResults", valid_608235
  var valid_608236 = query.getOrDefault("NextToken")
  valid_608236 = validateParameter(valid_608236, JString, required = false,
                                 default = nil)
  if valid_608236 != nil:
    section.add "NextToken", valid_608236
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
  var valid_608237 = header.getOrDefault("X-Amz-Target")
  valid_608237 = validateParameter(valid_608237, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchAddressBooks"))
  if valid_608237 != nil:
    section.add "X-Amz-Target", valid_608237
  var valid_608238 = header.getOrDefault("X-Amz-Signature")
  valid_608238 = validateParameter(valid_608238, JString, required = false,
                                 default = nil)
  if valid_608238 != nil:
    section.add "X-Amz-Signature", valid_608238
  var valid_608239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608239 = validateParameter(valid_608239, JString, required = false,
                                 default = nil)
  if valid_608239 != nil:
    section.add "X-Amz-Content-Sha256", valid_608239
  var valid_608240 = header.getOrDefault("X-Amz-Date")
  valid_608240 = validateParameter(valid_608240, JString, required = false,
                                 default = nil)
  if valid_608240 != nil:
    section.add "X-Amz-Date", valid_608240
  var valid_608241 = header.getOrDefault("X-Amz-Credential")
  valid_608241 = validateParameter(valid_608241, JString, required = false,
                                 default = nil)
  if valid_608241 != nil:
    section.add "X-Amz-Credential", valid_608241
  var valid_608242 = header.getOrDefault("X-Amz-Security-Token")
  valid_608242 = validateParameter(valid_608242, JString, required = false,
                                 default = nil)
  if valid_608242 != nil:
    section.add "X-Amz-Security-Token", valid_608242
  var valid_608243 = header.getOrDefault("X-Amz-Algorithm")
  valid_608243 = validateParameter(valid_608243, JString, required = false,
                                 default = nil)
  if valid_608243 != nil:
    section.add "X-Amz-Algorithm", valid_608243
  var valid_608244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608244 = validateParameter(valid_608244, JString, required = false,
                                 default = nil)
  if valid_608244 != nil:
    section.add "X-Amz-SignedHeaders", valid_608244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608246: Call_SearchAddressBooks_608232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_608246.validator(path, query, header, formData, body)
  let scheme = call_608246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608246.url(scheme.get, call_608246.host, call_608246.base,
                         call_608246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608246, url, valid)

proc call*(call_608247: Call_SearchAddressBooks_608232; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchAddressBooks
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_608248 = newJObject()
  var body_608249 = newJObject()
  add(query_608248, "MaxResults", newJString(MaxResults))
  add(query_608248, "NextToken", newJString(NextToken))
  if body != nil:
    body_608249 = body
  result = call_608247.call(nil, query_608248, nil, nil, body_608249)

var searchAddressBooks* = Call_SearchAddressBooks_608232(
    name: "searchAddressBooks", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchAddressBooks",
    validator: validate_SearchAddressBooks_608233, base: "/",
    url: url_SearchAddressBooks_608234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchContacts_608250 = ref object of OpenApiRestCall_606589
proc url_SearchContacts_608252(protocol: Scheme; host: string; base: string;
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

proc validate_SearchContacts_608251(path: JsonNode; query: JsonNode;
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
  var valid_608253 = query.getOrDefault("MaxResults")
  valid_608253 = validateParameter(valid_608253, JString, required = false,
                                 default = nil)
  if valid_608253 != nil:
    section.add "MaxResults", valid_608253
  var valid_608254 = query.getOrDefault("NextToken")
  valid_608254 = validateParameter(valid_608254, JString, required = false,
                                 default = nil)
  if valid_608254 != nil:
    section.add "NextToken", valid_608254
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
  var valid_608255 = header.getOrDefault("X-Amz-Target")
  valid_608255 = validateParameter(valid_608255, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchContacts"))
  if valid_608255 != nil:
    section.add "X-Amz-Target", valid_608255
  var valid_608256 = header.getOrDefault("X-Amz-Signature")
  valid_608256 = validateParameter(valid_608256, JString, required = false,
                                 default = nil)
  if valid_608256 != nil:
    section.add "X-Amz-Signature", valid_608256
  var valid_608257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608257 = validateParameter(valid_608257, JString, required = false,
                                 default = nil)
  if valid_608257 != nil:
    section.add "X-Amz-Content-Sha256", valid_608257
  var valid_608258 = header.getOrDefault("X-Amz-Date")
  valid_608258 = validateParameter(valid_608258, JString, required = false,
                                 default = nil)
  if valid_608258 != nil:
    section.add "X-Amz-Date", valid_608258
  var valid_608259 = header.getOrDefault("X-Amz-Credential")
  valid_608259 = validateParameter(valid_608259, JString, required = false,
                                 default = nil)
  if valid_608259 != nil:
    section.add "X-Amz-Credential", valid_608259
  var valid_608260 = header.getOrDefault("X-Amz-Security-Token")
  valid_608260 = validateParameter(valid_608260, JString, required = false,
                                 default = nil)
  if valid_608260 != nil:
    section.add "X-Amz-Security-Token", valid_608260
  var valid_608261 = header.getOrDefault("X-Amz-Algorithm")
  valid_608261 = validateParameter(valid_608261, JString, required = false,
                                 default = nil)
  if valid_608261 != nil:
    section.add "X-Amz-Algorithm", valid_608261
  var valid_608262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608262 = validateParameter(valid_608262, JString, required = false,
                                 default = nil)
  if valid_608262 != nil:
    section.add "X-Amz-SignedHeaders", valid_608262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608264: Call_SearchContacts_608250; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_608264.validator(path, query, header, formData, body)
  let scheme = call_608264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608264.url(scheme.get, call_608264.host, call_608264.base,
                         call_608264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608264, url, valid)

proc call*(call_608265: Call_SearchContacts_608250; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchContacts
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_608266 = newJObject()
  var body_608267 = newJObject()
  add(query_608266, "MaxResults", newJString(MaxResults))
  add(query_608266, "NextToken", newJString(NextToken))
  if body != nil:
    body_608267 = body
  result = call_608265.call(nil, query_608266, nil, nil, body_608267)

var searchContacts* = Call_SearchContacts_608250(name: "searchContacts",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchContacts",
    validator: validate_SearchContacts_608251, base: "/", url: url_SearchContacts_608252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchDevices_608268 = ref object of OpenApiRestCall_606589
proc url_SearchDevices_608270(protocol: Scheme; host: string; base: string;
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

proc validate_SearchDevices_608269(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608271 = query.getOrDefault("MaxResults")
  valid_608271 = validateParameter(valid_608271, JString, required = false,
                                 default = nil)
  if valid_608271 != nil:
    section.add "MaxResults", valid_608271
  var valid_608272 = query.getOrDefault("NextToken")
  valid_608272 = validateParameter(valid_608272, JString, required = false,
                                 default = nil)
  if valid_608272 != nil:
    section.add "NextToken", valid_608272
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
  var valid_608273 = header.getOrDefault("X-Amz-Target")
  valid_608273 = validateParameter(valid_608273, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchDevices"))
  if valid_608273 != nil:
    section.add "X-Amz-Target", valid_608273
  var valid_608274 = header.getOrDefault("X-Amz-Signature")
  valid_608274 = validateParameter(valid_608274, JString, required = false,
                                 default = nil)
  if valid_608274 != nil:
    section.add "X-Amz-Signature", valid_608274
  var valid_608275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608275 = validateParameter(valid_608275, JString, required = false,
                                 default = nil)
  if valid_608275 != nil:
    section.add "X-Amz-Content-Sha256", valid_608275
  var valid_608276 = header.getOrDefault("X-Amz-Date")
  valid_608276 = validateParameter(valid_608276, JString, required = false,
                                 default = nil)
  if valid_608276 != nil:
    section.add "X-Amz-Date", valid_608276
  var valid_608277 = header.getOrDefault("X-Amz-Credential")
  valid_608277 = validateParameter(valid_608277, JString, required = false,
                                 default = nil)
  if valid_608277 != nil:
    section.add "X-Amz-Credential", valid_608277
  var valid_608278 = header.getOrDefault("X-Amz-Security-Token")
  valid_608278 = validateParameter(valid_608278, JString, required = false,
                                 default = nil)
  if valid_608278 != nil:
    section.add "X-Amz-Security-Token", valid_608278
  var valid_608279 = header.getOrDefault("X-Amz-Algorithm")
  valid_608279 = validateParameter(valid_608279, JString, required = false,
                                 default = nil)
  if valid_608279 != nil:
    section.add "X-Amz-Algorithm", valid_608279
  var valid_608280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608280 = validateParameter(valid_608280, JString, required = false,
                                 default = nil)
  if valid_608280 != nil:
    section.add "X-Amz-SignedHeaders", valid_608280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608282: Call_SearchDevices_608268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches devices and lists the ones that meet a set of filter criteria.
  ## 
  let valid = call_608282.validator(path, query, header, formData, body)
  let scheme = call_608282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608282.url(scheme.get, call_608282.host, call_608282.base,
                         call_608282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608282, url, valid)

proc call*(call_608283: Call_SearchDevices_608268; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchDevices
  ## Searches devices and lists the ones that meet a set of filter criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_608284 = newJObject()
  var body_608285 = newJObject()
  add(query_608284, "MaxResults", newJString(MaxResults))
  add(query_608284, "NextToken", newJString(NextToken))
  if body != nil:
    body_608285 = body
  result = call_608283.call(nil, query_608284, nil, nil, body_608285)

var searchDevices* = Call_SearchDevices_608268(name: "searchDevices",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchDevices",
    validator: validate_SearchDevices_608269, base: "/", url: url_SearchDevices_608270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchNetworkProfiles_608286 = ref object of OpenApiRestCall_606589
proc url_SearchNetworkProfiles_608288(protocol: Scheme; host: string; base: string;
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

proc validate_SearchNetworkProfiles_608287(path: JsonNode; query: JsonNode;
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
  var valid_608289 = query.getOrDefault("MaxResults")
  valid_608289 = validateParameter(valid_608289, JString, required = false,
                                 default = nil)
  if valid_608289 != nil:
    section.add "MaxResults", valid_608289
  var valid_608290 = query.getOrDefault("NextToken")
  valid_608290 = validateParameter(valid_608290, JString, required = false,
                                 default = nil)
  if valid_608290 != nil:
    section.add "NextToken", valid_608290
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
  var valid_608291 = header.getOrDefault("X-Amz-Target")
  valid_608291 = validateParameter(valid_608291, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchNetworkProfiles"))
  if valid_608291 != nil:
    section.add "X-Amz-Target", valid_608291
  var valid_608292 = header.getOrDefault("X-Amz-Signature")
  valid_608292 = validateParameter(valid_608292, JString, required = false,
                                 default = nil)
  if valid_608292 != nil:
    section.add "X-Amz-Signature", valid_608292
  var valid_608293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608293 = validateParameter(valid_608293, JString, required = false,
                                 default = nil)
  if valid_608293 != nil:
    section.add "X-Amz-Content-Sha256", valid_608293
  var valid_608294 = header.getOrDefault("X-Amz-Date")
  valid_608294 = validateParameter(valid_608294, JString, required = false,
                                 default = nil)
  if valid_608294 != nil:
    section.add "X-Amz-Date", valid_608294
  var valid_608295 = header.getOrDefault("X-Amz-Credential")
  valid_608295 = validateParameter(valid_608295, JString, required = false,
                                 default = nil)
  if valid_608295 != nil:
    section.add "X-Amz-Credential", valid_608295
  var valid_608296 = header.getOrDefault("X-Amz-Security-Token")
  valid_608296 = validateParameter(valid_608296, JString, required = false,
                                 default = nil)
  if valid_608296 != nil:
    section.add "X-Amz-Security-Token", valid_608296
  var valid_608297 = header.getOrDefault("X-Amz-Algorithm")
  valid_608297 = validateParameter(valid_608297, JString, required = false,
                                 default = nil)
  if valid_608297 != nil:
    section.add "X-Amz-Algorithm", valid_608297
  var valid_608298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608298 = validateParameter(valid_608298, JString, required = false,
                                 default = nil)
  if valid_608298 != nil:
    section.add "X-Amz-SignedHeaders", valid_608298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608300: Call_SearchNetworkProfiles_608286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_608300.validator(path, query, header, formData, body)
  let scheme = call_608300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608300.url(scheme.get, call_608300.host, call_608300.base,
                         call_608300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608300, url, valid)

proc call*(call_608301: Call_SearchNetworkProfiles_608286; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchNetworkProfiles
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_608302 = newJObject()
  var body_608303 = newJObject()
  add(query_608302, "MaxResults", newJString(MaxResults))
  add(query_608302, "NextToken", newJString(NextToken))
  if body != nil:
    body_608303 = body
  result = call_608301.call(nil, query_608302, nil, nil, body_608303)

var searchNetworkProfiles* = Call_SearchNetworkProfiles_608286(
    name: "searchNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchNetworkProfiles",
    validator: validate_SearchNetworkProfiles_608287, base: "/",
    url: url_SearchNetworkProfiles_608288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProfiles_608304 = ref object of OpenApiRestCall_606589
proc url_SearchProfiles_608306(protocol: Scheme; host: string; base: string;
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

proc validate_SearchProfiles_608305(path: JsonNode; query: JsonNode;
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
  var valid_608307 = query.getOrDefault("MaxResults")
  valid_608307 = validateParameter(valid_608307, JString, required = false,
                                 default = nil)
  if valid_608307 != nil:
    section.add "MaxResults", valid_608307
  var valid_608308 = query.getOrDefault("NextToken")
  valid_608308 = validateParameter(valid_608308, JString, required = false,
                                 default = nil)
  if valid_608308 != nil:
    section.add "NextToken", valid_608308
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
  var valid_608309 = header.getOrDefault("X-Amz-Target")
  valid_608309 = validateParameter(valid_608309, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchProfiles"))
  if valid_608309 != nil:
    section.add "X-Amz-Target", valid_608309
  var valid_608310 = header.getOrDefault("X-Amz-Signature")
  valid_608310 = validateParameter(valid_608310, JString, required = false,
                                 default = nil)
  if valid_608310 != nil:
    section.add "X-Amz-Signature", valid_608310
  var valid_608311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608311 = validateParameter(valid_608311, JString, required = false,
                                 default = nil)
  if valid_608311 != nil:
    section.add "X-Amz-Content-Sha256", valid_608311
  var valid_608312 = header.getOrDefault("X-Amz-Date")
  valid_608312 = validateParameter(valid_608312, JString, required = false,
                                 default = nil)
  if valid_608312 != nil:
    section.add "X-Amz-Date", valid_608312
  var valid_608313 = header.getOrDefault("X-Amz-Credential")
  valid_608313 = validateParameter(valid_608313, JString, required = false,
                                 default = nil)
  if valid_608313 != nil:
    section.add "X-Amz-Credential", valid_608313
  var valid_608314 = header.getOrDefault("X-Amz-Security-Token")
  valid_608314 = validateParameter(valid_608314, JString, required = false,
                                 default = nil)
  if valid_608314 != nil:
    section.add "X-Amz-Security-Token", valid_608314
  var valid_608315 = header.getOrDefault("X-Amz-Algorithm")
  valid_608315 = validateParameter(valid_608315, JString, required = false,
                                 default = nil)
  if valid_608315 != nil:
    section.add "X-Amz-Algorithm", valid_608315
  var valid_608316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608316 = validateParameter(valid_608316, JString, required = false,
                                 default = nil)
  if valid_608316 != nil:
    section.add "X-Amz-SignedHeaders", valid_608316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608318: Call_SearchProfiles_608304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
  ## 
  let valid = call_608318.validator(path, query, header, formData, body)
  let scheme = call_608318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608318.url(scheme.get, call_608318.host, call_608318.base,
                         call_608318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608318, url, valid)

proc call*(call_608319: Call_SearchProfiles_608304; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchProfiles
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_608320 = newJObject()
  var body_608321 = newJObject()
  add(query_608320, "MaxResults", newJString(MaxResults))
  add(query_608320, "NextToken", newJString(NextToken))
  if body != nil:
    body_608321 = body
  result = call_608319.call(nil, query_608320, nil, nil, body_608321)

var searchProfiles* = Call_SearchProfiles_608304(name: "searchProfiles",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchProfiles",
    validator: validate_SearchProfiles_608305, base: "/", url: url_SearchProfiles_608306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchRooms_608322 = ref object of OpenApiRestCall_606589
proc url_SearchRooms_608324(protocol: Scheme; host: string; base: string;
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

proc validate_SearchRooms_608323(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608325 = query.getOrDefault("MaxResults")
  valid_608325 = validateParameter(valid_608325, JString, required = false,
                                 default = nil)
  if valid_608325 != nil:
    section.add "MaxResults", valid_608325
  var valid_608326 = query.getOrDefault("NextToken")
  valid_608326 = validateParameter(valid_608326, JString, required = false,
                                 default = nil)
  if valid_608326 != nil:
    section.add "NextToken", valid_608326
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
  var valid_608327 = header.getOrDefault("X-Amz-Target")
  valid_608327 = validateParameter(valid_608327, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchRooms"))
  if valid_608327 != nil:
    section.add "X-Amz-Target", valid_608327
  var valid_608328 = header.getOrDefault("X-Amz-Signature")
  valid_608328 = validateParameter(valid_608328, JString, required = false,
                                 default = nil)
  if valid_608328 != nil:
    section.add "X-Amz-Signature", valid_608328
  var valid_608329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608329 = validateParameter(valid_608329, JString, required = false,
                                 default = nil)
  if valid_608329 != nil:
    section.add "X-Amz-Content-Sha256", valid_608329
  var valid_608330 = header.getOrDefault("X-Amz-Date")
  valid_608330 = validateParameter(valid_608330, JString, required = false,
                                 default = nil)
  if valid_608330 != nil:
    section.add "X-Amz-Date", valid_608330
  var valid_608331 = header.getOrDefault("X-Amz-Credential")
  valid_608331 = validateParameter(valid_608331, JString, required = false,
                                 default = nil)
  if valid_608331 != nil:
    section.add "X-Amz-Credential", valid_608331
  var valid_608332 = header.getOrDefault("X-Amz-Security-Token")
  valid_608332 = validateParameter(valid_608332, JString, required = false,
                                 default = nil)
  if valid_608332 != nil:
    section.add "X-Amz-Security-Token", valid_608332
  var valid_608333 = header.getOrDefault("X-Amz-Algorithm")
  valid_608333 = validateParameter(valid_608333, JString, required = false,
                                 default = nil)
  if valid_608333 != nil:
    section.add "X-Amz-Algorithm", valid_608333
  var valid_608334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608334 = validateParameter(valid_608334, JString, required = false,
                                 default = nil)
  if valid_608334 != nil:
    section.add "X-Amz-SignedHeaders", valid_608334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608336: Call_SearchRooms_608322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_608336.validator(path, query, header, formData, body)
  let scheme = call_608336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608336.url(scheme.get, call_608336.host, call_608336.base,
                         call_608336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608336, url, valid)

proc call*(call_608337: Call_SearchRooms_608322; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchRooms
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_608338 = newJObject()
  var body_608339 = newJObject()
  add(query_608338, "MaxResults", newJString(MaxResults))
  add(query_608338, "NextToken", newJString(NextToken))
  if body != nil:
    body_608339 = body
  result = call_608337.call(nil, query_608338, nil, nil, body_608339)

var searchRooms* = Call_SearchRooms_608322(name: "searchRooms",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.SearchRooms",
                                        validator: validate_SearchRooms_608323,
                                        base: "/", url: url_SearchRooms_608324,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSkillGroups_608340 = ref object of OpenApiRestCall_606589
proc url_SearchSkillGroups_608342(protocol: Scheme; host: string; base: string;
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

proc validate_SearchSkillGroups_608341(path: JsonNode; query: JsonNode;
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
  var valid_608343 = query.getOrDefault("MaxResults")
  valid_608343 = validateParameter(valid_608343, JString, required = false,
                                 default = nil)
  if valid_608343 != nil:
    section.add "MaxResults", valid_608343
  var valid_608344 = query.getOrDefault("NextToken")
  valid_608344 = validateParameter(valid_608344, JString, required = false,
                                 default = nil)
  if valid_608344 != nil:
    section.add "NextToken", valid_608344
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
  var valid_608345 = header.getOrDefault("X-Amz-Target")
  valid_608345 = validateParameter(valid_608345, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchSkillGroups"))
  if valid_608345 != nil:
    section.add "X-Amz-Target", valid_608345
  var valid_608346 = header.getOrDefault("X-Amz-Signature")
  valid_608346 = validateParameter(valid_608346, JString, required = false,
                                 default = nil)
  if valid_608346 != nil:
    section.add "X-Amz-Signature", valid_608346
  var valid_608347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608347 = validateParameter(valid_608347, JString, required = false,
                                 default = nil)
  if valid_608347 != nil:
    section.add "X-Amz-Content-Sha256", valid_608347
  var valid_608348 = header.getOrDefault("X-Amz-Date")
  valid_608348 = validateParameter(valid_608348, JString, required = false,
                                 default = nil)
  if valid_608348 != nil:
    section.add "X-Amz-Date", valid_608348
  var valid_608349 = header.getOrDefault("X-Amz-Credential")
  valid_608349 = validateParameter(valid_608349, JString, required = false,
                                 default = nil)
  if valid_608349 != nil:
    section.add "X-Amz-Credential", valid_608349
  var valid_608350 = header.getOrDefault("X-Amz-Security-Token")
  valid_608350 = validateParameter(valid_608350, JString, required = false,
                                 default = nil)
  if valid_608350 != nil:
    section.add "X-Amz-Security-Token", valid_608350
  var valid_608351 = header.getOrDefault("X-Amz-Algorithm")
  valid_608351 = validateParameter(valid_608351, JString, required = false,
                                 default = nil)
  if valid_608351 != nil:
    section.add "X-Amz-Algorithm", valid_608351
  var valid_608352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608352 = validateParameter(valid_608352, JString, required = false,
                                 default = nil)
  if valid_608352 != nil:
    section.add "X-Amz-SignedHeaders", valid_608352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608354: Call_SearchSkillGroups_608340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_608354.validator(path, query, header, formData, body)
  let scheme = call_608354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608354.url(scheme.get, call_608354.host, call_608354.base,
                         call_608354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608354, url, valid)

proc call*(call_608355: Call_SearchSkillGroups_608340; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchSkillGroups
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_608356 = newJObject()
  var body_608357 = newJObject()
  add(query_608356, "MaxResults", newJString(MaxResults))
  add(query_608356, "NextToken", newJString(NextToken))
  if body != nil:
    body_608357 = body
  result = call_608355.call(nil, query_608356, nil, nil, body_608357)

var searchSkillGroups* = Call_SearchSkillGroups_608340(name: "searchSkillGroups",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchSkillGroups",
    validator: validate_SearchSkillGroups_608341, base: "/",
    url: url_SearchSkillGroups_608342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchUsers_608358 = ref object of OpenApiRestCall_606589
proc url_SearchUsers_608360(protocol: Scheme; host: string; base: string;
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

proc validate_SearchUsers_608359(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608361 = query.getOrDefault("MaxResults")
  valid_608361 = validateParameter(valid_608361, JString, required = false,
                                 default = nil)
  if valid_608361 != nil:
    section.add "MaxResults", valid_608361
  var valid_608362 = query.getOrDefault("NextToken")
  valid_608362 = validateParameter(valid_608362, JString, required = false,
                                 default = nil)
  if valid_608362 != nil:
    section.add "NextToken", valid_608362
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
  var valid_608363 = header.getOrDefault("X-Amz-Target")
  valid_608363 = validateParameter(valid_608363, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchUsers"))
  if valid_608363 != nil:
    section.add "X-Amz-Target", valid_608363
  var valid_608364 = header.getOrDefault("X-Amz-Signature")
  valid_608364 = validateParameter(valid_608364, JString, required = false,
                                 default = nil)
  if valid_608364 != nil:
    section.add "X-Amz-Signature", valid_608364
  var valid_608365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608365 = validateParameter(valid_608365, JString, required = false,
                                 default = nil)
  if valid_608365 != nil:
    section.add "X-Amz-Content-Sha256", valid_608365
  var valid_608366 = header.getOrDefault("X-Amz-Date")
  valid_608366 = validateParameter(valid_608366, JString, required = false,
                                 default = nil)
  if valid_608366 != nil:
    section.add "X-Amz-Date", valid_608366
  var valid_608367 = header.getOrDefault("X-Amz-Credential")
  valid_608367 = validateParameter(valid_608367, JString, required = false,
                                 default = nil)
  if valid_608367 != nil:
    section.add "X-Amz-Credential", valid_608367
  var valid_608368 = header.getOrDefault("X-Amz-Security-Token")
  valid_608368 = validateParameter(valid_608368, JString, required = false,
                                 default = nil)
  if valid_608368 != nil:
    section.add "X-Amz-Security-Token", valid_608368
  var valid_608369 = header.getOrDefault("X-Amz-Algorithm")
  valid_608369 = validateParameter(valid_608369, JString, required = false,
                                 default = nil)
  if valid_608369 != nil:
    section.add "X-Amz-Algorithm", valid_608369
  var valid_608370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608370 = validateParameter(valid_608370, JString, required = false,
                                 default = nil)
  if valid_608370 != nil:
    section.add "X-Amz-SignedHeaders", valid_608370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608372: Call_SearchUsers_608358; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_608372.validator(path, query, header, formData, body)
  let scheme = call_608372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608372.url(scheme.get, call_608372.host, call_608372.base,
                         call_608372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608372, url, valid)

proc call*(call_608373: Call_SearchUsers_608358; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchUsers
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_608374 = newJObject()
  var body_608375 = newJObject()
  add(query_608374, "MaxResults", newJString(MaxResults))
  add(query_608374, "NextToken", newJString(NextToken))
  if body != nil:
    body_608375 = body
  result = call_608373.call(nil, query_608374, nil, nil, body_608375)

var searchUsers* = Call_SearchUsers_608358(name: "searchUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.SearchUsers",
                                        validator: validate_SearchUsers_608359,
                                        base: "/", url: url_SearchUsers_608360,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAnnouncement_608376 = ref object of OpenApiRestCall_606589
proc url_SendAnnouncement_608378(protocol: Scheme; host: string; base: string;
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

proc validate_SendAnnouncement_608377(path: JsonNode; query: JsonNode;
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
  var valid_608379 = header.getOrDefault("X-Amz-Target")
  valid_608379 = validateParameter(valid_608379, JString, required = true, default = newJString(
      "AlexaForBusiness.SendAnnouncement"))
  if valid_608379 != nil:
    section.add "X-Amz-Target", valid_608379
  var valid_608380 = header.getOrDefault("X-Amz-Signature")
  valid_608380 = validateParameter(valid_608380, JString, required = false,
                                 default = nil)
  if valid_608380 != nil:
    section.add "X-Amz-Signature", valid_608380
  var valid_608381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608381 = validateParameter(valid_608381, JString, required = false,
                                 default = nil)
  if valid_608381 != nil:
    section.add "X-Amz-Content-Sha256", valid_608381
  var valid_608382 = header.getOrDefault("X-Amz-Date")
  valid_608382 = validateParameter(valid_608382, JString, required = false,
                                 default = nil)
  if valid_608382 != nil:
    section.add "X-Amz-Date", valid_608382
  var valid_608383 = header.getOrDefault("X-Amz-Credential")
  valid_608383 = validateParameter(valid_608383, JString, required = false,
                                 default = nil)
  if valid_608383 != nil:
    section.add "X-Amz-Credential", valid_608383
  var valid_608384 = header.getOrDefault("X-Amz-Security-Token")
  valid_608384 = validateParameter(valid_608384, JString, required = false,
                                 default = nil)
  if valid_608384 != nil:
    section.add "X-Amz-Security-Token", valid_608384
  var valid_608385 = header.getOrDefault("X-Amz-Algorithm")
  valid_608385 = validateParameter(valid_608385, JString, required = false,
                                 default = nil)
  if valid_608385 != nil:
    section.add "X-Amz-Algorithm", valid_608385
  var valid_608386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608386 = validateParameter(valid_608386, JString, required = false,
                                 default = nil)
  if valid_608386 != nil:
    section.add "X-Amz-SignedHeaders", valid_608386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608388: Call_SendAnnouncement_608376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Triggers an asynchronous flow to send text, SSML, or audio announcements to rooms that are identified by a search or filter. 
  ## 
  let valid = call_608388.validator(path, query, header, formData, body)
  let scheme = call_608388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608388.url(scheme.get, call_608388.host, call_608388.base,
                         call_608388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608388, url, valid)

proc call*(call_608389: Call_SendAnnouncement_608376; body: JsonNode): Recallable =
  ## sendAnnouncement
  ## Triggers an asynchronous flow to send text, SSML, or audio announcements to rooms that are identified by a search or filter. 
  ##   body: JObject (required)
  var body_608390 = newJObject()
  if body != nil:
    body_608390 = body
  result = call_608389.call(nil, nil, nil, nil, body_608390)

var sendAnnouncement* = Call_SendAnnouncement_608376(name: "sendAnnouncement",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SendAnnouncement",
    validator: validate_SendAnnouncement_608377, base: "/",
    url: url_SendAnnouncement_608378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendInvitation_608391 = ref object of OpenApiRestCall_606589
proc url_SendInvitation_608393(protocol: Scheme; host: string; base: string;
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

proc validate_SendInvitation_608392(path: JsonNode; query: JsonNode;
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
  var valid_608394 = header.getOrDefault("X-Amz-Target")
  valid_608394 = validateParameter(valid_608394, JString, required = true, default = newJString(
      "AlexaForBusiness.SendInvitation"))
  if valid_608394 != nil:
    section.add "X-Amz-Target", valid_608394
  var valid_608395 = header.getOrDefault("X-Amz-Signature")
  valid_608395 = validateParameter(valid_608395, JString, required = false,
                                 default = nil)
  if valid_608395 != nil:
    section.add "X-Amz-Signature", valid_608395
  var valid_608396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608396 = validateParameter(valid_608396, JString, required = false,
                                 default = nil)
  if valid_608396 != nil:
    section.add "X-Amz-Content-Sha256", valid_608396
  var valid_608397 = header.getOrDefault("X-Amz-Date")
  valid_608397 = validateParameter(valid_608397, JString, required = false,
                                 default = nil)
  if valid_608397 != nil:
    section.add "X-Amz-Date", valid_608397
  var valid_608398 = header.getOrDefault("X-Amz-Credential")
  valid_608398 = validateParameter(valid_608398, JString, required = false,
                                 default = nil)
  if valid_608398 != nil:
    section.add "X-Amz-Credential", valid_608398
  var valid_608399 = header.getOrDefault("X-Amz-Security-Token")
  valid_608399 = validateParameter(valid_608399, JString, required = false,
                                 default = nil)
  if valid_608399 != nil:
    section.add "X-Amz-Security-Token", valid_608399
  var valid_608400 = header.getOrDefault("X-Amz-Algorithm")
  valid_608400 = validateParameter(valid_608400, JString, required = false,
                                 default = nil)
  if valid_608400 != nil:
    section.add "X-Amz-Algorithm", valid_608400
  var valid_608401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608401 = validateParameter(valid_608401, JString, required = false,
                                 default = nil)
  if valid_608401 != nil:
    section.add "X-Amz-SignedHeaders", valid_608401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608403: Call_SendInvitation_608391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends an enrollment invitation email with a URL to a user. The URL is valid for 30 days or until you call this operation again, whichever comes first. 
  ## 
  let valid = call_608403.validator(path, query, header, formData, body)
  let scheme = call_608403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608403.url(scheme.get, call_608403.host, call_608403.base,
                         call_608403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608403, url, valid)

proc call*(call_608404: Call_SendInvitation_608391; body: JsonNode): Recallable =
  ## sendInvitation
  ## Sends an enrollment invitation email with a URL to a user. The URL is valid for 30 days or until you call this operation again, whichever comes first. 
  ##   body: JObject (required)
  var body_608405 = newJObject()
  if body != nil:
    body_608405 = body
  result = call_608404.call(nil, nil, nil, nil, body_608405)

var sendInvitation* = Call_SendInvitation_608391(name: "sendInvitation",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SendInvitation",
    validator: validate_SendInvitation_608392, base: "/", url: url_SendInvitation_608393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeviceSync_608406 = ref object of OpenApiRestCall_606589
proc url_StartDeviceSync_608408(protocol: Scheme; host: string; base: string;
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

proc validate_StartDeviceSync_608407(path: JsonNode; query: JsonNode;
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
  var valid_608409 = header.getOrDefault("X-Amz-Target")
  valid_608409 = validateParameter(valid_608409, JString, required = true, default = newJString(
      "AlexaForBusiness.StartDeviceSync"))
  if valid_608409 != nil:
    section.add "X-Amz-Target", valid_608409
  var valid_608410 = header.getOrDefault("X-Amz-Signature")
  valid_608410 = validateParameter(valid_608410, JString, required = false,
                                 default = nil)
  if valid_608410 != nil:
    section.add "X-Amz-Signature", valid_608410
  var valid_608411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608411 = validateParameter(valid_608411, JString, required = false,
                                 default = nil)
  if valid_608411 != nil:
    section.add "X-Amz-Content-Sha256", valid_608411
  var valid_608412 = header.getOrDefault("X-Amz-Date")
  valid_608412 = validateParameter(valid_608412, JString, required = false,
                                 default = nil)
  if valid_608412 != nil:
    section.add "X-Amz-Date", valid_608412
  var valid_608413 = header.getOrDefault("X-Amz-Credential")
  valid_608413 = validateParameter(valid_608413, JString, required = false,
                                 default = nil)
  if valid_608413 != nil:
    section.add "X-Amz-Credential", valid_608413
  var valid_608414 = header.getOrDefault("X-Amz-Security-Token")
  valid_608414 = validateParameter(valid_608414, JString, required = false,
                                 default = nil)
  if valid_608414 != nil:
    section.add "X-Amz-Security-Token", valid_608414
  var valid_608415 = header.getOrDefault("X-Amz-Algorithm")
  valid_608415 = validateParameter(valid_608415, JString, required = false,
                                 default = nil)
  if valid_608415 != nil:
    section.add "X-Amz-Algorithm", valid_608415
  var valid_608416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608416 = validateParameter(valid_608416, JString, required = false,
                                 default = nil)
  if valid_608416 != nil:
    section.add "X-Amz-SignedHeaders", valid_608416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608418: Call_StartDeviceSync_608406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets a device and its account to the known default settings. This clears all information and settings set by previous users in the following ways:</p> <ul> <li> <p>Bluetooth - This unpairs all bluetooth devices paired with your echo device.</p> </li> <li> <p>Volume - This resets the echo device's volume to the default value.</p> </li> <li> <p>Notifications - This clears all notifications from your echo device.</p> </li> <li> <p>Lists - This clears all to-do items from your echo device.</p> </li> <li> <p>Settings - This internally syncs the room's profile (if the device is assigned to a room), contacts, address books, delegation access for account linking, and communications (if enabled on the room profile).</p> </li> </ul>
  ## 
  let valid = call_608418.validator(path, query, header, formData, body)
  let scheme = call_608418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608418.url(scheme.get, call_608418.host, call_608418.base,
                         call_608418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608418, url, valid)

proc call*(call_608419: Call_StartDeviceSync_608406; body: JsonNode): Recallable =
  ## startDeviceSync
  ## <p>Resets a device and its account to the known default settings. This clears all information and settings set by previous users in the following ways:</p> <ul> <li> <p>Bluetooth - This unpairs all bluetooth devices paired with your echo device.</p> </li> <li> <p>Volume - This resets the echo device's volume to the default value.</p> </li> <li> <p>Notifications - This clears all notifications from your echo device.</p> </li> <li> <p>Lists - This clears all to-do items from your echo device.</p> </li> <li> <p>Settings - This internally syncs the room's profile (if the device is assigned to a room), contacts, address books, delegation access for account linking, and communications (if enabled on the room profile).</p> </li> </ul>
  ##   body: JObject (required)
  var body_608420 = newJObject()
  if body != nil:
    body_608420 = body
  result = call_608419.call(nil, nil, nil, nil, body_608420)

var startDeviceSync* = Call_StartDeviceSync_608406(name: "startDeviceSync",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.StartDeviceSync",
    validator: validate_StartDeviceSync_608407, base: "/", url: url_StartDeviceSync_608408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSmartHomeApplianceDiscovery_608421 = ref object of OpenApiRestCall_606589
proc url_StartSmartHomeApplianceDiscovery_608423(protocol: Scheme; host: string;
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

proc validate_StartSmartHomeApplianceDiscovery_608422(path: JsonNode;
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
  var valid_608424 = header.getOrDefault("X-Amz-Target")
  valid_608424 = validateParameter(valid_608424, JString, required = true, default = newJString(
      "AlexaForBusiness.StartSmartHomeApplianceDiscovery"))
  if valid_608424 != nil:
    section.add "X-Amz-Target", valid_608424
  var valid_608425 = header.getOrDefault("X-Amz-Signature")
  valid_608425 = validateParameter(valid_608425, JString, required = false,
                                 default = nil)
  if valid_608425 != nil:
    section.add "X-Amz-Signature", valid_608425
  var valid_608426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608426 = validateParameter(valid_608426, JString, required = false,
                                 default = nil)
  if valid_608426 != nil:
    section.add "X-Amz-Content-Sha256", valid_608426
  var valid_608427 = header.getOrDefault("X-Amz-Date")
  valid_608427 = validateParameter(valid_608427, JString, required = false,
                                 default = nil)
  if valid_608427 != nil:
    section.add "X-Amz-Date", valid_608427
  var valid_608428 = header.getOrDefault("X-Amz-Credential")
  valid_608428 = validateParameter(valid_608428, JString, required = false,
                                 default = nil)
  if valid_608428 != nil:
    section.add "X-Amz-Credential", valid_608428
  var valid_608429 = header.getOrDefault("X-Amz-Security-Token")
  valid_608429 = validateParameter(valid_608429, JString, required = false,
                                 default = nil)
  if valid_608429 != nil:
    section.add "X-Amz-Security-Token", valid_608429
  var valid_608430 = header.getOrDefault("X-Amz-Algorithm")
  valid_608430 = validateParameter(valid_608430, JString, required = false,
                                 default = nil)
  if valid_608430 != nil:
    section.add "X-Amz-Algorithm", valid_608430
  var valid_608431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608431 = validateParameter(valid_608431, JString, required = false,
                                 default = nil)
  if valid_608431 != nil:
    section.add "X-Amz-SignedHeaders", valid_608431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608433: Call_StartSmartHomeApplianceDiscovery_608421;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Initiates the discovery of any smart home appliances associated with the room.
  ## 
  let valid = call_608433.validator(path, query, header, formData, body)
  let scheme = call_608433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608433.url(scheme.get, call_608433.host, call_608433.base,
                         call_608433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608433, url, valid)

proc call*(call_608434: Call_StartSmartHomeApplianceDiscovery_608421;
          body: JsonNode): Recallable =
  ## startSmartHomeApplianceDiscovery
  ## Initiates the discovery of any smart home appliances associated with the room.
  ##   body: JObject (required)
  var body_608435 = newJObject()
  if body != nil:
    body_608435 = body
  result = call_608434.call(nil, nil, nil, nil, body_608435)

var startSmartHomeApplianceDiscovery* = Call_StartSmartHomeApplianceDiscovery_608421(
    name: "startSmartHomeApplianceDiscovery", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.StartSmartHomeApplianceDiscovery",
    validator: validate_StartSmartHomeApplianceDiscovery_608422, base: "/",
    url: url_StartSmartHomeApplianceDiscovery_608423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_608436 = ref object of OpenApiRestCall_606589
proc url_TagResource_608438(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_608437(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608439 = header.getOrDefault("X-Amz-Target")
  valid_608439 = validateParameter(valid_608439, JString, required = true, default = newJString(
      "AlexaForBusiness.TagResource"))
  if valid_608439 != nil:
    section.add "X-Amz-Target", valid_608439
  var valid_608440 = header.getOrDefault("X-Amz-Signature")
  valid_608440 = validateParameter(valid_608440, JString, required = false,
                                 default = nil)
  if valid_608440 != nil:
    section.add "X-Amz-Signature", valid_608440
  var valid_608441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608441 = validateParameter(valid_608441, JString, required = false,
                                 default = nil)
  if valid_608441 != nil:
    section.add "X-Amz-Content-Sha256", valid_608441
  var valid_608442 = header.getOrDefault("X-Amz-Date")
  valid_608442 = validateParameter(valid_608442, JString, required = false,
                                 default = nil)
  if valid_608442 != nil:
    section.add "X-Amz-Date", valid_608442
  var valid_608443 = header.getOrDefault("X-Amz-Credential")
  valid_608443 = validateParameter(valid_608443, JString, required = false,
                                 default = nil)
  if valid_608443 != nil:
    section.add "X-Amz-Credential", valid_608443
  var valid_608444 = header.getOrDefault("X-Amz-Security-Token")
  valid_608444 = validateParameter(valid_608444, JString, required = false,
                                 default = nil)
  if valid_608444 != nil:
    section.add "X-Amz-Security-Token", valid_608444
  var valid_608445 = header.getOrDefault("X-Amz-Algorithm")
  valid_608445 = validateParameter(valid_608445, JString, required = false,
                                 default = nil)
  if valid_608445 != nil:
    section.add "X-Amz-Algorithm", valid_608445
  var valid_608446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608446 = validateParameter(valid_608446, JString, required = false,
                                 default = nil)
  if valid_608446 != nil:
    section.add "X-Amz-SignedHeaders", valid_608446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608448: Call_TagResource_608436; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to a specified resource.
  ## 
  let valid = call_608448.validator(path, query, header, formData, body)
  let scheme = call_608448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608448.url(scheme.get, call_608448.host, call_608448.base,
                         call_608448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608448, url, valid)

proc call*(call_608449: Call_TagResource_608436; body: JsonNode): Recallable =
  ## tagResource
  ## Adds metadata tags to a specified resource.
  ##   body: JObject (required)
  var body_608450 = newJObject()
  if body != nil:
    body_608450 = body
  result = call_608449.call(nil, nil, nil, nil, body_608450)

var tagResource* = Call_TagResource_608436(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.TagResource",
                                        validator: validate_TagResource_608437,
                                        base: "/", url: url_TagResource_608438,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_608451 = ref object of OpenApiRestCall_606589
proc url_UntagResource_608453(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_608452(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608454 = header.getOrDefault("X-Amz-Target")
  valid_608454 = validateParameter(valid_608454, JString, required = true, default = newJString(
      "AlexaForBusiness.UntagResource"))
  if valid_608454 != nil:
    section.add "X-Amz-Target", valid_608454
  var valid_608455 = header.getOrDefault("X-Amz-Signature")
  valid_608455 = validateParameter(valid_608455, JString, required = false,
                                 default = nil)
  if valid_608455 != nil:
    section.add "X-Amz-Signature", valid_608455
  var valid_608456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608456 = validateParameter(valid_608456, JString, required = false,
                                 default = nil)
  if valid_608456 != nil:
    section.add "X-Amz-Content-Sha256", valid_608456
  var valid_608457 = header.getOrDefault("X-Amz-Date")
  valid_608457 = validateParameter(valid_608457, JString, required = false,
                                 default = nil)
  if valid_608457 != nil:
    section.add "X-Amz-Date", valid_608457
  var valid_608458 = header.getOrDefault("X-Amz-Credential")
  valid_608458 = validateParameter(valid_608458, JString, required = false,
                                 default = nil)
  if valid_608458 != nil:
    section.add "X-Amz-Credential", valid_608458
  var valid_608459 = header.getOrDefault("X-Amz-Security-Token")
  valid_608459 = validateParameter(valid_608459, JString, required = false,
                                 default = nil)
  if valid_608459 != nil:
    section.add "X-Amz-Security-Token", valid_608459
  var valid_608460 = header.getOrDefault("X-Amz-Algorithm")
  valid_608460 = validateParameter(valid_608460, JString, required = false,
                                 default = nil)
  if valid_608460 != nil:
    section.add "X-Amz-Algorithm", valid_608460
  var valid_608461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608461 = validateParameter(valid_608461, JString, required = false,
                                 default = nil)
  if valid_608461 != nil:
    section.add "X-Amz-SignedHeaders", valid_608461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608463: Call_UntagResource_608451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from a specified resource.
  ## 
  let valid = call_608463.validator(path, query, header, formData, body)
  let scheme = call_608463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608463.url(scheme.get, call_608463.host, call_608463.base,
                         call_608463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608463, url, valid)

proc call*(call_608464: Call_UntagResource_608451; body: JsonNode): Recallable =
  ## untagResource
  ## Removes metadata tags from a specified resource.
  ##   body: JObject (required)
  var body_608465 = newJObject()
  if body != nil:
    body_608465 = body
  result = call_608464.call(nil, nil, nil, nil, body_608465)

var untagResource* = Call_UntagResource_608451(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UntagResource",
    validator: validate_UntagResource_608452, base: "/", url: url_UntagResource_608453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAddressBook_608466 = ref object of OpenApiRestCall_606589
proc url_UpdateAddressBook_608468(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAddressBook_608467(path: JsonNode; query: JsonNode;
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
  var valid_608469 = header.getOrDefault("X-Amz-Target")
  valid_608469 = validateParameter(valid_608469, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateAddressBook"))
  if valid_608469 != nil:
    section.add "X-Amz-Target", valid_608469
  var valid_608470 = header.getOrDefault("X-Amz-Signature")
  valid_608470 = validateParameter(valid_608470, JString, required = false,
                                 default = nil)
  if valid_608470 != nil:
    section.add "X-Amz-Signature", valid_608470
  var valid_608471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608471 = validateParameter(valid_608471, JString, required = false,
                                 default = nil)
  if valid_608471 != nil:
    section.add "X-Amz-Content-Sha256", valid_608471
  var valid_608472 = header.getOrDefault("X-Amz-Date")
  valid_608472 = validateParameter(valid_608472, JString, required = false,
                                 default = nil)
  if valid_608472 != nil:
    section.add "X-Amz-Date", valid_608472
  var valid_608473 = header.getOrDefault("X-Amz-Credential")
  valid_608473 = validateParameter(valid_608473, JString, required = false,
                                 default = nil)
  if valid_608473 != nil:
    section.add "X-Amz-Credential", valid_608473
  var valid_608474 = header.getOrDefault("X-Amz-Security-Token")
  valid_608474 = validateParameter(valid_608474, JString, required = false,
                                 default = nil)
  if valid_608474 != nil:
    section.add "X-Amz-Security-Token", valid_608474
  var valid_608475 = header.getOrDefault("X-Amz-Algorithm")
  valid_608475 = validateParameter(valid_608475, JString, required = false,
                                 default = nil)
  if valid_608475 != nil:
    section.add "X-Amz-Algorithm", valid_608475
  var valid_608476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608476 = validateParameter(valid_608476, JString, required = false,
                                 default = nil)
  if valid_608476 != nil:
    section.add "X-Amz-SignedHeaders", valid_608476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608478: Call_UpdateAddressBook_608466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates address book details by the address book ARN.
  ## 
  let valid = call_608478.validator(path, query, header, formData, body)
  let scheme = call_608478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608478.url(scheme.get, call_608478.host, call_608478.base,
                         call_608478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608478, url, valid)

proc call*(call_608479: Call_UpdateAddressBook_608466; body: JsonNode): Recallable =
  ## updateAddressBook
  ## Updates address book details by the address book ARN.
  ##   body: JObject (required)
  var body_608480 = newJObject()
  if body != nil:
    body_608480 = body
  result = call_608479.call(nil, nil, nil, nil, body_608480)

var updateAddressBook* = Call_UpdateAddressBook_608466(name: "updateAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateAddressBook",
    validator: validate_UpdateAddressBook_608467, base: "/",
    url: url_UpdateAddressBook_608468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBusinessReportSchedule_608481 = ref object of OpenApiRestCall_606589
proc url_UpdateBusinessReportSchedule_608483(protocol: Scheme; host: string;
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

proc validate_UpdateBusinessReportSchedule_608482(path: JsonNode; query: JsonNode;
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
  var valid_608484 = header.getOrDefault("X-Amz-Target")
  valid_608484 = validateParameter(valid_608484, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateBusinessReportSchedule"))
  if valid_608484 != nil:
    section.add "X-Amz-Target", valid_608484
  var valid_608485 = header.getOrDefault("X-Amz-Signature")
  valid_608485 = validateParameter(valid_608485, JString, required = false,
                                 default = nil)
  if valid_608485 != nil:
    section.add "X-Amz-Signature", valid_608485
  var valid_608486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608486 = validateParameter(valid_608486, JString, required = false,
                                 default = nil)
  if valid_608486 != nil:
    section.add "X-Amz-Content-Sha256", valid_608486
  var valid_608487 = header.getOrDefault("X-Amz-Date")
  valid_608487 = validateParameter(valid_608487, JString, required = false,
                                 default = nil)
  if valid_608487 != nil:
    section.add "X-Amz-Date", valid_608487
  var valid_608488 = header.getOrDefault("X-Amz-Credential")
  valid_608488 = validateParameter(valid_608488, JString, required = false,
                                 default = nil)
  if valid_608488 != nil:
    section.add "X-Amz-Credential", valid_608488
  var valid_608489 = header.getOrDefault("X-Amz-Security-Token")
  valid_608489 = validateParameter(valid_608489, JString, required = false,
                                 default = nil)
  if valid_608489 != nil:
    section.add "X-Amz-Security-Token", valid_608489
  var valid_608490 = header.getOrDefault("X-Amz-Algorithm")
  valid_608490 = validateParameter(valid_608490, JString, required = false,
                                 default = nil)
  if valid_608490 != nil:
    section.add "X-Amz-Algorithm", valid_608490
  var valid_608491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608491 = validateParameter(valid_608491, JString, required = false,
                                 default = nil)
  if valid_608491 != nil:
    section.add "X-Amz-SignedHeaders", valid_608491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608493: Call_UpdateBusinessReportSchedule_608481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration of the report delivery schedule with the specified schedule ARN.
  ## 
  let valid = call_608493.validator(path, query, header, formData, body)
  let scheme = call_608493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608493.url(scheme.get, call_608493.host, call_608493.base,
                         call_608493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608493, url, valid)

proc call*(call_608494: Call_UpdateBusinessReportSchedule_608481; body: JsonNode): Recallable =
  ## updateBusinessReportSchedule
  ## Updates the configuration of the report delivery schedule with the specified schedule ARN.
  ##   body: JObject (required)
  var body_608495 = newJObject()
  if body != nil:
    body_608495 = body
  result = call_608494.call(nil, nil, nil, nil, body_608495)

var updateBusinessReportSchedule* = Call_UpdateBusinessReportSchedule_608481(
    name: "updateBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateBusinessReportSchedule",
    validator: validate_UpdateBusinessReportSchedule_608482, base: "/",
    url: url_UpdateBusinessReportSchedule_608483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConferenceProvider_608496 = ref object of OpenApiRestCall_606589
proc url_UpdateConferenceProvider_608498(protocol: Scheme; host: string;
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

proc validate_UpdateConferenceProvider_608497(path: JsonNode; query: JsonNode;
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
  var valid_608499 = header.getOrDefault("X-Amz-Target")
  valid_608499 = validateParameter(valid_608499, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateConferenceProvider"))
  if valid_608499 != nil:
    section.add "X-Amz-Target", valid_608499
  var valid_608500 = header.getOrDefault("X-Amz-Signature")
  valid_608500 = validateParameter(valid_608500, JString, required = false,
                                 default = nil)
  if valid_608500 != nil:
    section.add "X-Amz-Signature", valid_608500
  var valid_608501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608501 = validateParameter(valid_608501, JString, required = false,
                                 default = nil)
  if valid_608501 != nil:
    section.add "X-Amz-Content-Sha256", valid_608501
  var valid_608502 = header.getOrDefault("X-Amz-Date")
  valid_608502 = validateParameter(valid_608502, JString, required = false,
                                 default = nil)
  if valid_608502 != nil:
    section.add "X-Amz-Date", valid_608502
  var valid_608503 = header.getOrDefault("X-Amz-Credential")
  valid_608503 = validateParameter(valid_608503, JString, required = false,
                                 default = nil)
  if valid_608503 != nil:
    section.add "X-Amz-Credential", valid_608503
  var valid_608504 = header.getOrDefault("X-Amz-Security-Token")
  valid_608504 = validateParameter(valid_608504, JString, required = false,
                                 default = nil)
  if valid_608504 != nil:
    section.add "X-Amz-Security-Token", valid_608504
  var valid_608505 = header.getOrDefault("X-Amz-Algorithm")
  valid_608505 = validateParameter(valid_608505, JString, required = false,
                                 default = nil)
  if valid_608505 != nil:
    section.add "X-Amz-Algorithm", valid_608505
  var valid_608506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608506 = validateParameter(valid_608506, JString, required = false,
                                 default = nil)
  if valid_608506 != nil:
    section.add "X-Amz-SignedHeaders", valid_608506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608508: Call_UpdateConferenceProvider_608496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing conference provider's settings.
  ## 
  let valid = call_608508.validator(path, query, header, formData, body)
  let scheme = call_608508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608508.url(scheme.get, call_608508.host, call_608508.base,
                         call_608508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608508, url, valid)

proc call*(call_608509: Call_UpdateConferenceProvider_608496; body: JsonNode): Recallable =
  ## updateConferenceProvider
  ## Updates an existing conference provider's settings.
  ##   body: JObject (required)
  var body_608510 = newJObject()
  if body != nil:
    body_608510 = body
  result = call_608509.call(nil, nil, nil, nil, body_608510)

var updateConferenceProvider* = Call_UpdateConferenceProvider_608496(
    name: "updateConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateConferenceProvider",
    validator: validate_UpdateConferenceProvider_608497, base: "/",
    url: url_UpdateConferenceProvider_608498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContact_608511 = ref object of OpenApiRestCall_606589
proc url_UpdateContact_608513(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateContact_608512(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608514 = header.getOrDefault("X-Amz-Target")
  valid_608514 = validateParameter(valid_608514, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateContact"))
  if valid_608514 != nil:
    section.add "X-Amz-Target", valid_608514
  var valid_608515 = header.getOrDefault("X-Amz-Signature")
  valid_608515 = validateParameter(valid_608515, JString, required = false,
                                 default = nil)
  if valid_608515 != nil:
    section.add "X-Amz-Signature", valid_608515
  var valid_608516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608516 = validateParameter(valid_608516, JString, required = false,
                                 default = nil)
  if valid_608516 != nil:
    section.add "X-Amz-Content-Sha256", valid_608516
  var valid_608517 = header.getOrDefault("X-Amz-Date")
  valid_608517 = validateParameter(valid_608517, JString, required = false,
                                 default = nil)
  if valid_608517 != nil:
    section.add "X-Amz-Date", valid_608517
  var valid_608518 = header.getOrDefault("X-Amz-Credential")
  valid_608518 = validateParameter(valid_608518, JString, required = false,
                                 default = nil)
  if valid_608518 != nil:
    section.add "X-Amz-Credential", valid_608518
  var valid_608519 = header.getOrDefault("X-Amz-Security-Token")
  valid_608519 = validateParameter(valid_608519, JString, required = false,
                                 default = nil)
  if valid_608519 != nil:
    section.add "X-Amz-Security-Token", valid_608519
  var valid_608520 = header.getOrDefault("X-Amz-Algorithm")
  valid_608520 = validateParameter(valid_608520, JString, required = false,
                                 default = nil)
  if valid_608520 != nil:
    section.add "X-Amz-Algorithm", valid_608520
  var valid_608521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608521 = validateParameter(valid_608521, JString, required = false,
                                 default = nil)
  if valid_608521 != nil:
    section.add "X-Amz-SignedHeaders", valid_608521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608523: Call_UpdateContact_608511; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the contact details by the contact ARN.
  ## 
  let valid = call_608523.validator(path, query, header, formData, body)
  let scheme = call_608523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608523.url(scheme.get, call_608523.host, call_608523.base,
                         call_608523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608523, url, valid)

proc call*(call_608524: Call_UpdateContact_608511; body: JsonNode): Recallable =
  ## updateContact
  ## Updates the contact details by the contact ARN.
  ##   body: JObject (required)
  var body_608525 = newJObject()
  if body != nil:
    body_608525 = body
  result = call_608524.call(nil, nil, nil, nil, body_608525)

var updateContact* = Call_UpdateContact_608511(name: "updateContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateContact",
    validator: validate_UpdateContact_608512, base: "/", url: url_UpdateContact_608513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevice_608526 = ref object of OpenApiRestCall_606589
proc url_UpdateDevice_608528(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDevice_608527(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608529 = header.getOrDefault("X-Amz-Target")
  valid_608529 = validateParameter(valid_608529, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateDevice"))
  if valid_608529 != nil:
    section.add "X-Amz-Target", valid_608529
  var valid_608530 = header.getOrDefault("X-Amz-Signature")
  valid_608530 = validateParameter(valid_608530, JString, required = false,
                                 default = nil)
  if valid_608530 != nil:
    section.add "X-Amz-Signature", valid_608530
  var valid_608531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608531 = validateParameter(valid_608531, JString, required = false,
                                 default = nil)
  if valid_608531 != nil:
    section.add "X-Amz-Content-Sha256", valid_608531
  var valid_608532 = header.getOrDefault("X-Amz-Date")
  valid_608532 = validateParameter(valid_608532, JString, required = false,
                                 default = nil)
  if valid_608532 != nil:
    section.add "X-Amz-Date", valid_608532
  var valid_608533 = header.getOrDefault("X-Amz-Credential")
  valid_608533 = validateParameter(valid_608533, JString, required = false,
                                 default = nil)
  if valid_608533 != nil:
    section.add "X-Amz-Credential", valid_608533
  var valid_608534 = header.getOrDefault("X-Amz-Security-Token")
  valid_608534 = validateParameter(valid_608534, JString, required = false,
                                 default = nil)
  if valid_608534 != nil:
    section.add "X-Amz-Security-Token", valid_608534
  var valid_608535 = header.getOrDefault("X-Amz-Algorithm")
  valid_608535 = validateParameter(valid_608535, JString, required = false,
                                 default = nil)
  if valid_608535 != nil:
    section.add "X-Amz-Algorithm", valid_608535
  var valid_608536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608536 = validateParameter(valid_608536, JString, required = false,
                                 default = nil)
  if valid_608536 != nil:
    section.add "X-Amz-SignedHeaders", valid_608536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608538: Call_UpdateDevice_608526; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the device name by device ARN.
  ## 
  let valid = call_608538.validator(path, query, header, formData, body)
  let scheme = call_608538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608538.url(scheme.get, call_608538.host, call_608538.base,
                         call_608538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608538, url, valid)

proc call*(call_608539: Call_UpdateDevice_608526; body: JsonNode): Recallable =
  ## updateDevice
  ## Updates the device name by device ARN.
  ##   body: JObject (required)
  var body_608540 = newJObject()
  if body != nil:
    body_608540 = body
  result = call_608539.call(nil, nil, nil, nil, body_608540)

var updateDevice* = Call_UpdateDevice_608526(name: "updateDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateDevice",
    validator: validate_UpdateDevice_608527, base: "/", url: url_UpdateDevice_608528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGateway_608541 = ref object of OpenApiRestCall_606589
proc url_UpdateGateway_608543(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGateway_608542(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608544 = header.getOrDefault("X-Amz-Target")
  valid_608544 = validateParameter(valid_608544, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateGateway"))
  if valid_608544 != nil:
    section.add "X-Amz-Target", valid_608544
  var valid_608545 = header.getOrDefault("X-Amz-Signature")
  valid_608545 = validateParameter(valid_608545, JString, required = false,
                                 default = nil)
  if valid_608545 != nil:
    section.add "X-Amz-Signature", valid_608545
  var valid_608546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608546 = validateParameter(valid_608546, JString, required = false,
                                 default = nil)
  if valid_608546 != nil:
    section.add "X-Amz-Content-Sha256", valid_608546
  var valid_608547 = header.getOrDefault("X-Amz-Date")
  valid_608547 = validateParameter(valid_608547, JString, required = false,
                                 default = nil)
  if valid_608547 != nil:
    section.add "X-Amz-Date", valid_608547
  var valid_608548 = header.getOrDefault("X-Amz-Credential")
  valid_608548 = validateParameter(valid_608548, JString, required = false,
                                 default = nil)
  if valid_608548 != nil:
    section.add "X-Amz-Credential", valid_608548
  var valid_608549 = header.getOrDefault("X-Amz-Security-Token")
  valid_608549 = validateParameter(valid_608549, JString, required = false,
                                 default = nil)
  if valid_608549 != nil:
    section.add "X-Amz-Security-Token", valid_608549
  var valid_608550 = header.getOrDefault("X-Amz-Algorithm")
  valid_608550 = validateParameter(valid_608550, JString, required = false,
                                 default = nil)
  if valid_608550 != nil:
    section.add "X-Amz-Algorithm", valid_608550
  var valid_608551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608551 = validateParameter(valid_608551, JString, required = false,
                                 default = nil)
  if valid_608551 != nil:
    section.add "X-Amz-SignedHeaders", valid_608551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608553: Call_UpdateGateway_608541; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details of a gateway. If any optional field is not provided, the existing corresponding value is left unmodified.
  ## 
  let valid = call_608553.validator(path, query, header, formData, body)
  let scheme = call_608553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608553.url(scheme.get, call_608553.host, call_608553.base,
                         call_608553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608553, url, valid)

proc call*(call_608554: Call_UpdateGateway_608541; body: JsonNode): Recallable =
  ## updateGateway
  ## Updates the details of a gateway. If any optional field is not provided, the existing corresponding value is left unmodified.
  ##   body: JObject (required)
  var body_608555 = newJObject()
  if body != nil:
    body_608555 = body
  result = call_608554.call(nil, nil, nil, nil, body_608555)

var updateGateway* = Call_UpdateGateway_608541(name: "updateGateway",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateGateway",
    validator: validate_UpdateGateway_608542, base: "/", url: url_UpdateGateway_608543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayGroup_608556 = ref object of OpenApiRestCall_606589
proc url_UpdateGatewayGroup_608558(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGatewayGroup_608557(path: JsonNode; query: JsonNode;
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
  var valid_608559 = header.getOrDefault("X-Amz-Target")
  valid_608559 = validateParameter(valid_608559, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateGatewayGroup"))
  if valid_608559 != nil:
    section.add "X-Amz-Target", valid_608559
  var valid_608560 = header.getOrDefault("X-Amz-Signature")
  valid_608560 = validateParameter(valid_608560, JString, required = false,
                                 default = nil)
  if valid_608560 != nil:
    section.add "X-Amz-Signature", valid_608560
  var valid_608561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608561 = validateParameter(valid_608561, JString, required = false,
                                 default = nil)
  if valid_608561 != nil:
    section.add "X-Amz-Content-Sha256", valid_608561
  var valid_608562 = header.getOrDefault("X-Amz-Date")
  valid_608562 = validateParameter(valid_608562, JString, required = false,
                                 default = nil)
  if valid_608562 != nil:
    section.add "X-Amz-Date", valid_608562
  var valid_608563 = header.getOrDefault("X-Amz-Credential")
  valid_608563 = validateParameter(valid_608563, JString, required = false,
                                 default = nil)
  if valid_608563 != nil:
    section.add "X-Amz-Credential", valid_608563
  var valid_608564 = header.getOrDefault("X-Amz-Security-Token")
  valid_608564 = validateParameter(valid_608564, JString, required = false,
                                 default = nil)
  if valid_608564 != nil:
    section.add "X-Amz-Security-Token", valid_608564
  var valid_608565 = header.getOrDefault("X-Amz-Algorithm")
  valid_608565 = validateParameter(valid_608565, JString, required = false,
                                 default = nil)
  if valid_608565 != nil:
    section.add "X-Amz-Algorithm", valid_608565
  var valid_608566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608566 = validateParameter(valid_608566, JString, required = false,
                                 default = nil)
  if valid_608566 != nil:
    section.add "X-Amz-SignedHeaders", valid_608566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608568: Call_UpdateGatewayGroup_608556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details of a gateway group. If any optional field is not provided, the existing corresponding value is left unmodified.
  ## 
  let valid = call_608568.validator(path, query, header, formData, body)
  let scheme = call_608568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608568.url(scheme.get, call_608568.host, call_608568.base,
                         call_608568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608568, url, valid)

proc call*(call_608569: Call_UpdateGatewayGroup_608556; body: JsonNode): Recallable =
  ## updateGatewayGroup
  ## Updates the details of a gateway group. If any optional field is not provided, the existing corresponding value is left unmodified.
  ##   body: JObject (required)
  var body_608570 = newJObject()
  if body != nil:
    body_608570 = body
  result = call_608569.call(nil, nil, nil, nil, body_608570)

var updateGatewayGroup* = Call_UpdateGatewayGroup_608556(
    name: "updateGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateGatewayGroup",
    validator: validate_UpdateGatewayGroup_608557, base: "/",
    url: url_UpdateGatewayGroup_608558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_608571 = ref object of OpenApiRestCall_606589
proc url_UpdateNetworkProfile_608573(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateNetworkProfile_608572(path: JsonNode; query: JsonNode;
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
  var valid_608574 = header.getOrDefault("X-Amz-Target")
  valid_608574 = validateParameter(valid_608574, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateNetworkProfile"))
  if valid_608574 != nil:
    section.add "X-Amz-Target", valid_608574
  var valid_608575 = header.getOrDefault("X-Amz-Signature")
  valid_608575 = validateParameter(valid_608575, JString, required = false,
                                 default = nil)
  if valid_608575 != nil:
    section.add "X-Amz-Signature", valid_608575
  var valid_608576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608576 = validateParameter(valid_608576, JString, required = false,
                                 default = nil)
  if valid_608576 != nil:
    section.add "X-Amz-Content-Sha256", valid_608576
  var valid_608577 = header.getOrDefault("X-Amz-Date")
  valid_608577 = validateParameter(valid_608577, JString, required = false,
                                 default = nil)
  if valid_608577 != nil:
    section.add "X-Amz-Date", valid_608577
  var valid_608578 = header.getOrDefault("X-Amz-Credential")
  valid_608578 = validateParameter(valid_608578, JString, required = false,
                                 default = nil)
  if valid_608578 != nil:
    section.add "X-Amz-Credential", valid_608578
  var valid_608579 = header.getOrDefault("X-Amz-Security-Token")
  valid_608579 = validateParameter(valid_608579, JString, required = false,
                                 default = nil)
  if valid_608579 != nil:
    section.add "X-Amz-Security-Token", valid_608579
  var valid_608580 = header.getOrDefault("X-Amz-Algorithm")
  valid_608580 = validateParameter(valid_608580, JString, required = false,
                                 default = nil)
  if valid_608580 != nil:
    section.add "X-Amz-Algorithm", valid_608580
  var valid_608581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608581 = validateParameter(valid_608581, JString, required = false,
                                 default = nil)
  if valid_608581 != nil:
    section.add "X-Amz-SignedHeaders", valid_608581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608583: Call_UpdateNetworkProfile_608571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a network profile by the network profile ARN.
  ## 
  let valid = call_608583.validator(path, query, header, formData, body)
  let scheme = call_608583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608583.url(scheme.get, call_608583.host, call_608583.base,
                         call_608583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608583, url, valid)

proc call*(call_608584: Call_UpdateNetworkProfile_608571; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates a network profile by the network profile ARN.
  ##   body: JObject (required)
  var body_608585 = newJObject()
  if body != nil:
    body_608585 = body
  result = call_608584.call(nil, nil, nil, nil, body_608585)

var updateNetworkProfile* = Call_UpdateNetworkProfile_608571(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_608572, base: "/",
    url: url_UpdateNetworkProfile_608573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProfile_608586 = ref object of OpenApiRestCall_606589
proc url_UpdateProfile_608588(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateProfile_608587(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608589 = header.getOrDefault("X-Amz-Target")
  valid_608589 = validateParameter(valid_608589, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateProfile"))
  if valid_608589 != nil:
    section.add "X-Amz-Target", valid_608589
  var valid_608590 = header.getOrDefault("X-Amz-Signature")
  valid_608590 = validateParameter(valid_608590, JString, required = false,
                                 default = nil)
  if valid_608590 != nil:
    section.add "X-Amz-Signature", valid_608590
  var valid_608591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608591 = validateParameter(valid_608591, JString, required = false,
                                 default = nil)
  if valid_608591 != nil:
    section.add "X-Amz-Content-Sha256", valid_608591
  var valid_608592 = header.getOrDefault("X-Amz-Date")
  valid_608592 = validateParameter(valid_608592, JString, required = false,
                                 default = nil)
  if valid_608592 != nil:
    section.add "X-Amz-Date", valid_608592
  var valid_608593 = header.getOrDefault("X-Amz-Credential")
  valid_608593 = validateParameter(valid_608593, JString, required = false,
                                 default = nil)
  if valid_608593 != nil:
    section.add "X-Amz-Credential", valid_608593
  var valid_608594 = header.getOrDefault("X-Amz-Security-Token")
  valid_608594 = validateParameter(valid_608594, JString, required = false,
                                 default = nil)
  if valid_608594 != nil:
    section.add "X-Amz-Security-Token", valid_608594
  var valid_608595 = header.getOrDefault("X-Amz-Algorithm")
  valid_608595 = validateParameter(valid_608595, JString, required = false,
                                 default = nil)
  if valid_608595 != nil:
    section.add "X-Amz-Algorithm", valid_608595
  var valid_608596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608596 = validateParameter(valid_608596, JString, required = false,
                                 default = nil)
  if valid_608596 != nil:
    section.add "X-Amz-SignedHeaders", valid_608596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608598: Call_UpdateProfile_608586; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing room profile by room profile ARN.
  ## 
  let valid = call_608598.validator(path, query, header, formData, body)
  let scheme = call_608598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608598.url(scheme.get, call_608598.host, call_608598.base,
                         call_608598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608598, url, valid)

proc call*(call_608599: Call_UpdateProfile_608586; body: JsonNode): Recallable =
  ## updateProfile
  ## Updates an existing room profile by room profile ARN.
  ##   body: JObject (required)
  var body_608600 = newJObject()
  if body != nil:
    body_608600 = body
  result = call_608599.call(nil, nil, nil, nil, body_608600)

var updateProfile* = Call_UpdateProfile_608586(name: "updateProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateProfile",
    validator: validate_UpdateProfile_608587, base: "/", url: url_UpdateProfile_608588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoom_608601 = ref object of OpenApiRestCall_606589
proc url_UpdateRoom_608603(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateRoom_608602(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608604 = header.getOrDefault("X-Amz-Target")
  valid_608604 = validateParameter(valid_608604, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateRoom"))
  if valid_608604 != nil:
    section.add "X-Amz-Target", valid_608604
  var valid_608605 = header.getOrDefault("X-Amz-Signature")
  valid_608605 = validateParameter(valid_608605, JString, required = false,
                                 default = nil)
  if valid_608605 != nil:
    section.add "X-Amz-Signature", valid_608605
  var valid_608606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608606 = validateParameter(valid_608606, JString, required = false,
                                 default = nil)
  if valid_608606 != nil:
    section.add "X-Amz-Content-Sha256", valid_608606
  var valid_608607 = header.getOrDefault("X-Amz-Date")
  valid_608607 = validateParameter(valid_608607, JString, required = false,
                                 default = nil)
  if valid_608607 != nil:
    section.add "X-Amz-Date", valid_608607
  var valid_608608 = header.getOrDefault("X-Amz-Credential")
  valid_608608 = validateParameter(valid_608608, JString, required = false,
                                 default = nil)
  if valid_608608 != nil:
    section.add "X-Amz-Credential", valid_608608
  var valid_608609 = header.getOrDefault("X-Amz-Security-Token")
  valid_608609 = validateParameter(valid_608609, JString, required = false,
                                 default = nil)
  if valid_608609 != nil:
    section.add "X-Amz-Security-Token", valid_608609
  var valid_608610 = header.getOrDefault("X-Amz-Algorithm")
  valid_608610 = validateParameter(valid_608610, JString, required = false,
                                 default = nil)
  if valid_608610 != nil:
    section.add "X-Amz-Algorithm", valid_608610
  var valid_608611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608611 = validateParameter(valid_608611, JString, required = false,
                                 default = nil)
  if valid_608611 != nil:
    section.add "X-Amz-SignedHeaders", valid_608611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608613: Call_UpdateRoom_608601; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room details by room ARN.
  ## 
  let valid = call_608613.validator(path, query, header, formData, body)
  let scheme = call_608613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608613.url(scheme.get, call_608613.host, call_608613.base,
                         call_608613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608613, url, valid)

proc call*(call_608614: Call_UpdateRoom_608601; body: JsonNode): Recallable =
  ## updateRoom
  ## Updates room details by room ARN.
  ##   body: JObject (required)
  var body_608615 = newJObject()
  if body != nil:
    body_608615 = body
  result = call_608614.call(nil, nil, nil, nil, body_608615)

var updateRoom* = Call_UpdateRoom_608601(name: "updateRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.UpdateRoom",
                                      validator: validate_UpdateRoom_608602,
                                      base: "/", url: url_UpdateRoom_608603,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSkillGroup_608616 = ref object of OpenApiRestCall_606589
proc url_UpdateSkillGroup_608618(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSkillGroup_608617(path: JsonNode; query: JsonNode;
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
  var valid_608619 = header.getOrDefault("X-Amz-Target")
  valid_608619 = validateParameter(valid_608619, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateSkillGroup"))
  if valid_608619 != nil:
    section.add "X-Amz-Target", valid_608619
  var valid_608620 = header.getOrDefault("X-Amz-Signature")
  valid_608620 = validateParameter(valid_608620, JString, required = false,
                                 default = nil)
  if valid_608620 != nil:
    section.add "X-Amz-Signature", valid_608620
  var valid_608621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608621 = validateParameter(valid_608621, JString, required = false,
                                 default = nil)
  if valid_608621 != nil:
    section.add "X-Amz-Content-Sha256", valid_608621
  var valid_608622 = header.getOrDefault("X-Amz-Date")
  valid_608622 = validateParameter(valid_608622, JString, required = false,
                                 default = nil)
  if valid_608622 != nil:
    section.add "X-Amz-Date", valid_608622
  var valid_608623 = header.getOrDefault("X-Amz-Credential")
  valid_608623 = validateParameter(valid_608623, JString, required = false,
                                 default = nil)
  if valid_608623 != nil:
    section.add "X-Amz-Credential", valid_608623
  var valid_608624 = header.getOrDefault("X-Amz-Security-Token")
  valid_608624 = validateParameter(valid_608624, JString, required = false,
                                 default = nil)
  if valid_608624 != nil:
    section.add "X-Amz-Security-Token", valid_608624
  var valid_608625 = header.getOrDefault("X-Amz-Algorithm")
  valid_608625 = validateParameter(valid_608625, JString, required = false,
                                 default = nil)
  if valid_608625 != nil:
    section.add "X-Amz-Algorithm", valid_608625
  var valid_608626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608626 = validateParameter(valid_608626, JString, required = false,
                                 default = nil)
  if valid_608626 != nil:
    section.add "X-Amz-SignedHeaders", valid_608626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608628: Call_UpdateSkillGroup_608616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates skill group details by skill group ARN.
  ## 
  let valid = call_608628.validator(path, query, header, formData, body)
  let scheme = call_608628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608628.url(scheme.get, call_608628.host, call_608628.base,
                         call_608628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608628, url, valid)

proc call*(call_608629: Call_UpdateSkillGroup_608616; body: JsonNode): Recallable =
  ## updateSkillGroup
  ## Updates skill group details by skill group ARN.
  ##   body: JObject (required)
  var body_608630 = newJObject()
  if body != nil:
    body_608630 = body
  result = call_608629.call(nil, nil, nil, nil, body_608630)

var updateSkillGroup* = Call_UpdateSkillGroup_608616(name: "updateSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateSkillGroup",
    validator: validate_UpdateSkillGroup_608617, base: "/",
    url: url_UpdateSkillGroup_608618, schemes: {Scheme.Https, Scheme.Http})
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
