
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_ApproveSkill_772933 = ref object of OpenApiRestCall_772597
proc url_ApproveSkill_772935(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ApproveSkill_772934(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773062 = header.getOrDefault("X-Amz-Target")
  valid_773062 = validateParameter(valid_773062, JString, required = true, default = newJString(
      "AlexaForBusiness.ApproveSkill"))
  if valid_773062 != nil:
    section.add "X-Amz-Target", valid_773062
  var valid_773063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "X-Amz-Content-Sha256", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Algorithm")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Algorithm", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Signature")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Signature", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-SignedHeaders", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Credential")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Credential", valid_773067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773091: Call_ApproveSkill_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill with the organization under the customer's AWS account. If a skill is private, the user implicitly accepts access to this skill during enablement.
  ## 
  let valid = call_773091.validator(path, query, header, formData, body)
  let scheme = call_773091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773091.url(scheme.get, call_773091.host, call_773091.base,
                         call_773091.route, valid.getOrDefault("path"))
  result = hook(call_773091, url, valid)

proc call*(call_773162: Call_ApproveSkill_772933; body: JsonNode): Recallable =
  ## approveSkill
  ## Associates a skill with the organization under the customer's AWS account. If a skill is private, the user implicitly accepts access to this skill during enablement.
  ##   body: JObject (required)
  var body_773163 = newJObject()
  if body != nil:
    body_773163 = body
  result = call_773162.call(nil, nil, nil, nil, body_773163)

var approveSkill* = Call_ApproveSkill_772933(name: "approveSkill",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ApproveSkill",
    validator: validate_ApproveSkill_772934, base: "/", url: url_ApproveSkill_772935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateContactWithAddressBook_773202 = ref object of OpenApiRestCall_772597
proc url_AssociateContactWithAddressBook_773204(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateContactWithAddressBook_773203(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773207 = header.getOrDefault("X-Amz-Target")
  valid_773207 = validateParameter(valid_773207, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateContactWithAddressBook"))
  if valid_773207 != nil:
    section.add "X-Amz-Target", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Content-Sha256", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Algorithm")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Algorithm", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Signature")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Signature", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-SignedHeaders", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Credential")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Credential", valid_773212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773214: Call_AssociateContactWithAddressBook_773202;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a contact with a given address book.
  ## 
  let valid = call_773214.validator(path, query, header, formData, body)
  let scheme = call_773214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773214.url(scheme.get, call_773214.host, call_773214.base,
                         call_773214.route, valid.getOrDefault("path"))
  result = hook(call_773214, url, valid)

proc call*(call_773215: Call_AssociateContactWithAddressBook_773202; body: JsonNode): Recallable =
  ## associateContactWithAddressBook
  ## Associates a contact with a given address book.
  ##   body: JObject (required)
  var body_773216 = newJObject()
  if body != nil:
    body_773216 = body
  result = call_773215.call(nil, nil, nil, nil, body_773216)

var associateContactWithAddressBook* = Call_AssociateContactWithAddressBook_773202(
    name: "associateContactWithAddressBook", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateContactWithAddressBook",
    validator: validate_AssociateContactWithAddressBook_773203, base: "/",
    url: url_AssociateContactWithAddressBook_773204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateDeviceWithNetworkProfile_773217 = ref object of OpenApiRestCall_772597
proc url_AssociateDeviceWithNetworkProfile_773219(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateDeviceWithNetworkProfile_773218(path: JsonNode;
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
  var valid_773220 = header.getOrDefault("X-Amz-Date")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Date", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Security-Token")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Security-Token", valid_773221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773222 = header.getOrDefault("X-Amz-Target")
  valid_773222 = validateParameter(valid_773222, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateDeviceWithNetworkProfile"))
  if valid_773222 != nil:
    section.add "X-Amz-Target", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Content-Sha256", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Algorithm")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Algorithm", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Signature")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Signature", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-SignedHeaders", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Credential")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Credential", valid_773227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773229: Call_AssociateDeviceWithNetworkProfile_773217;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a device with the specified network profile.
  ## 
  let valid = call_773229.validator(path, query, header, formData, body)
  let scheme = call_773229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773229.url(scheme.get, call_773229.host, call_773229.base,
                         call_773229.route, valid.getOrDefault("path"))
  result = hook(call_773229, url, valid)

proc call*(call_773230: Call_AssociateDeviceWithNetworkProfile_773217;
          body: JsonNode): Recallable =
  ## associateDeviceWithNetworkProfile
  ## Associates a device with the specified network profile.
  ##   body: JObject (required)
  var body_773231 = newJObject()
  if body != nil:
    body_773231 = body
  result = call_773230.call(nil, nil, nil, nil, body_773231)

var associateDeviceWithNetworkProfile* = Call_AssociateDeviceWithNetworkProfile_773217(
    name: "associateDeviceWithNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateDeviceWithNetworkProfile",
    validator: validate_AssociateDeviceWithNetworkProfile_773218, base: "/",
    url: url_AssociateDeviceWithNetworkProfile_773219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateDeviceWithRoom_773232 = ref object of OpenApiRestCall_772597
proc url_AssociateDeviceWithRoom_773234(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateDeviceWithRoom_773233(path: JsonNode; query: JsonNode;
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
  var valid_773235 = header.getOrDefault("X-Amz-Date")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Date", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Security-Token")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Security-Token", valid_773236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773237 = header.getOrDefault("X-Amz-Target")
  valid_773237 = validateParameter(valid_773237, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateDeviceWithRoom"))
  if valid_773237 != nil:
    section.add "X-Amz-Target", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Content-Sha256", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Algorithm")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Algorithm", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Signature")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Signature", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-SignedHeaders", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Credential")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Credential", valid_773242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773244: Call_AssociateDeviceWithRoom_773232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a device with a given room. This applies all the settings from the room profile to the device, and all the skills in any skill groups added to that room. This operation requires the device to be online, or else a manual sync is required. 
  ## 
  let valid = call_773244.validator(path, query, header, formData, body)
  let scheme = call_773244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773244.url(scheme.get, call_773244.host, call_773244.base,
                         call_773244.route, valid.getOrDefault("path"))
  result = hook(call_773244, url, valid)

proc call*(call_773245: Call_AssociateDeviceWithRoom_773232; body: JsonNode): Recallable =
  ## associateDeviceWithRoom
  ## Associates a device with a given room. This applies all the settings from the room profile to the device, and all the skills in any skill groups added to that room. This operation requires the device to be online, or else a manual sync is required. 
  ##   body: JObject (required)
  var body_773246 = newJObject()
  if body != nil:
    body_773246 = body
  result = call_773245.call(nil, nil, nil, nil, body_773246)

var associateDeviceWithRoom* = Call_AssociateDeviceWithRoom_773232(
    name: "associateDeviceWithRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateDeviceWithRoom",
    validator: validate_AssociateDeviceWithRoom_773233, base: "/",
    url: url_AssociateDeviceWithRoom_773234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillGroupWithRoom_773247 = ref object of OpenApiRestCall_772597
proc url_AssociateSkillGroupWithRoom_773249(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateSkillGroupWithRoom_773248(path: JsonNode; query: JsonNode;
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
  var valid_773250 = header.getOrDefault("X-Amz-Date")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Date", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Security-Token")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Security-Token", valid_773251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773252 = header.getOrDefault("X-Amz-Target")
  valid_773252 = validateParameter(valid_773252, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillGroupWithRoom"))
  if valid_773252 != nil:
    section.add "X-Amz-Target", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Content-Sha256", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Algorithm")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Algorithm", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Signature")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Signature", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-SignedHeaders", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Credential")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Credential", valid_773257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773259: Call_AssociateSkillGroupWithRoom_773247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill group with a given room. This enables all skills in the associated skill group on all devices in the room.
  ## 
  let valid = call_773259.validator(path, query, header, formData, body)
  let scheme = call_773259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773259.url(scheme.get, call_773259.host, call_773259.base,
                         call_773259.route, valid.getOrDefault("path"))
  result = hook(call_773259, url, valid)

proc call*(call_773260: Call_AssociateSkillGroupWithRoom_773247; body: JsonNode): Recallable =
  ## associateSkillGroupWithRoom
  ## Associates a skill group with a given room. This enables all skills in the associated skill group on all devices in the room.
  ##   body: JObject (required)
  var body_773261 = newJObject()
  if body != nil:
    body_773261 = body
  result = call_773260.call(nil, nil, nil, nil, body_773261)

var associateSkillGroupWithRoom* = Call_AssociateSkillGroupWithRoom_773247(
    name: "associateSkillGroupWithRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillGroupWithRoom",
    validator: validate_AssociateSkillGroupWithRoom_773248, base: "/",
    url: url_AssociateSkillGroupWithRoom_773249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillWithSkillGroup_773262 = ref object of OpenApiRestCall_772597
proc url_AssociateSkillWithSkillGroup_773264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateSkillWithSkillGroup_773263(path: JsonNode; query: JsonNode;
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
  var valid_773265 = header.getOrDefault("X-Amz-Date")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Date", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Security-Token")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Security-Token", valid_773266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773267 = header.getOrDefault("X-Amz-Target")
  valid_773267 = validateParameter(valid_773267, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillWithSkillGroup"))
  if valid_773267 != nil:
    section.add "X-Amz-Target", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Content-Sha256", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Algorithm")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Algorithm", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Signature")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Signature", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-SignedHeaders", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Credential")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Credential", valid_773272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773274: Call_AssociateSkillWithSkillGroup_773262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill with a skill group.
  ## 
  let valid = call_773274.validator(path, query, header, formData, body)
  let scheme = call_773274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773274.url(scheme.get, call_773274.host, call_773274.base,
                         call_773274.route, valid.getOrDefault("path"))
  result = hook(call_773274, url, valid)

proc call*(call_773275: Call_AssociateSkillWithSkillGroup_773262; body: JsonNode): Recallable =
  ## associateSkillWithSkillGroup
  ## Associates a skill with a skill group.
  ##   body: JObject (required)
  var body_773276 = newJObject()
  if body != nil:
    body_773276 = body
  result = call_773275.call(nil, nil, nil, nil, body_773276)

var associateSkillWithSkillGroup* = Call_AssociateSkillWithSkillGroup_773262(
    name: "associateSkillWithSkillGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillWithSkillGroup",
    validator: validate_AssociateSkillWithSkillGroup_773263, base: "/",
    url: url_AssociateSkillWithSkillGroup_773264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillWithUsers_773277 = ref object of OpenApiRestCall_772597
proc url_AssociateSkillWithUsers_773279(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateSkillWithUsers_773278(path: JsonNode; query: JsonNode;
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
  var valid_773280 = header.getOrDefault("X-Amz-Date")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Date", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Security-Token")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Security-Token", valid_773281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773282 = header.getOrDefault("X-Amz-Target")
  valid_773282 = validateParameter(valid_773282, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillWithUsers"))
  if valid_773282 != nil:
    section.add "X-Amz-Target", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Content-Sha256", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Algorithm")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Algorithm", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Signature")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Signature", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-SignedHeaders", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Credential")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Credential", valid_773287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773289: Call_AssociateSkillWithUsers_773277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Makes a private skill available for enrolled users to enable on their devices.
  ## 
  let valid = call_773289.validator(path, query, header, formData, body)
  let scheme = call_773289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773289.url(scheme.get, call_773289.host, call_773289.base,
                         call_773289.route, valid.getOrDefault("path"))
  result = hook(call_773289, url, valid)

proc call*(call_773290: Call_AssociateSkillWithUsers_773277; body: JsonNode): Recallable =
  ## associateSkillWithUsers
  ## Makes a private skill available for enrolled users to enable on their devices.
  ##   body: JObject (required)
  var body_773291 = newJObject()
  if body != nil:
    body_773291 = body
  result = call_773290.call(nil, nil, nil, nil, body_773291)

var associateSkillWithUsers* = Call_AssociateSkillWithUsers_773277(
    name: "associateSkillWithUsers", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillWithUsers",
    validator: validate_AssociateSkillWithUsers_773278, base: "/",
    url: url_AssociateSkillWithUsers_773279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAddressBook_773292 = ref object of OpenApiRestCall_772597
proc url_CreateAddressBook_773294(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAddressBook_773293(path: JsonNode; query: JsonNode;
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
  var valid_773295 = header.getOrDefault("X-Amz-Date")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Date", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Security-Token")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Security-Token", valid_773296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773297 = header.getOrDefault("X-Amz-Target")
  valid_773297 = validateParameter(valid_773297, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateAddressBook"))
  if valid_773297 != nil:
    section.add "X-Amz-Target", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Content-Sha256", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Algorithm")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Algorithm", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Signature")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Signature", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-SignedHeaders", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Credential")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Credential", valid_773302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773304: Call_CreateAddressBook_773292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an address book with the specified details.
  ## 
  let valid = call_773304.validator(path, query, header, formData, body)
  let scheme = call_773304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773304.url(scheme.get, call_773304.host, call_773304.base,
                         call_773304.route, valid.getOrDefault("path"))
  result = hook(call_773304, url, valid)

proc call*(call_773305: Call_CreateAddressBook_773292; body: JsonNode): Recallable =
  ## createAddressBook
  ## Creates an address book with the specified details.
  ##   body: JObject (required)
  var body_773306 = newJObject()
  if body != nil:
    body_773306 = body
  result = call_773305.call(nil, nil, nil, nil, body_773306)

var createAddressBook* = Call_CreateAddressBook_773292(name: "createAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateAddressBook",
    validator: validate_CreateAddressBook_773293, base: "/",
    url: url_CreateAddressBook_773294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBusinessReportSchedule_773307 = ref object of OpenApiRestCall_772597
proc url_CreateBusinessReportSchedule_773309(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateBusinessReportSchedule_773308(path: JsonNode; query: JsonNode;
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
  var valid_773310 = header.getOrDefault("X-Amz-Date")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Date", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Security-Token")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Security-Token", valid_773311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773312 = header.getOrDefault("X-Amz-Target")
  valid_773312 = validateParameter(valid_773312, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateBusinessReportSchedule"))
  if valid_773312 != nil:
    section.add "X-Amz-Target", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Content-Sha256", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Algorithm")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Algorithm", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Signature")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Signature", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-SignedHeaders", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Credential")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Credential", valid_773317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773319: Call_CreateBusinessReportSchedule_773307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a recurring schedule for usage reports to deliver to the specified S3 location with a specified daily or weekly interval.
  ## 
  let valid = call_773319.validator(path, query, header, formData, body)
  let scheme = call_773319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773319.url(scheme.get, call_773319.host, call_773319.base,
                         call_773319.route, valid.getOrDefault("path"))
  result = hook(call_773319, url, valid)

proc call*(call_773320: Call_CreateBusinessReportSchedule_773307; body: JsonNode): Recallable =
  ## createBusinessReportSchedule
  ## Creates a recurring schedule for usage reports to deliver to the specified S3 location with a specified daily or weekly interval.
  ##   body: JObject (required)
  var body_773321 = newJObject()
  if body != nil:
    body_773321 = body
  result = call_773320.call(nil, nil, nil, nil, body_773321)

var createBusinessReportSchedule* = Call_CreateBusinessReportSchedule_773307(
    name: "createBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateBusinessReportSchedule",
    validator: validate_CreateBusinessReportSchedule_773308, base: "/",
    url: url_CreateBusinessReportSchedule_773309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConferenceProvider_773322 = ref object of OpenApiRestCall_772597
proc url_CreateConferenceProvider_773324(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateConferenceProvider_773323(path: JsonNode; query: JsonNode;
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
  var valid_773325 = header.getOrDefault("X-Amz-Date")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Date", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Security-Token")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Security-Token", valid_773326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773327 = header.getOrDefault("X-Amz-Target")
  valid_773327 = validateParameter(valid_773327, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateConferenceProvider"))
  if valid_773327 != nil:
    section.add "X-Amz-Target", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Content-Sha256", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Algorithm")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Algorithm", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Signature")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Signature", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-SignedHeaders", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Credential")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Credential", valid_773332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773334: Call_CreateConferenceProvider_773322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new conference provider under the user's AWS account.
  ## 
  let valid = call_773334.validator(path, query, header, formData, body)
  let scheme = call_773334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773334.url(scheme.get, call_773334.host, call_773334.base,
                         call_773334.route, valid.getOrDefault("path"))
  result = hook(call_773334, url, valid)

proc call*(call_773335: Call_CreateConferenceProvider_773322; body: JsonNode): Recallable =
  ## createConferenceProvider
  ## Adds a new conference provider under the user's AWS account.
  ##   body: JObject (required)
  var body_773336 = newJObject()
  if body != nil:
    body_773336 = body
  result = call_773335.call(nil, nil, nil, nil, body_773336)

var createConferenceProvider* = Call_CreateConferenceProvider_773322(
    name: "createConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateConferenceProvider",
    validator: validate_CreateConferenceProvider_773323, base: "/",
    url: url_CreateConferenceProvider_773324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateContact_773337 = ref object of OpenApiRestCall_772597
proc url_CreateContact_773339(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateContact_773338(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773340 = header.getOrDefault("X-Amz-Date")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Date", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Security-Token")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Security-Token", valid_773341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773342 = header.getOrDefault("X-Amz-Target")
  valid_773342 = validateParameter(valid_773342, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateContact"))
  if valid_773342 != nil:
    section.add "X-Amz-Target", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Content-Sha256", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Algorithm")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Algorithm", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Signature")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Signature", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-SignedHeaders", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Credential")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Credential", valid_773347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773349: Call_CreateContact_773337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a contact with the specified details.
  ## 
  let valid = call_773349.validator(path, query, header, formData, body)
  let scheme = call_773349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773349.url(scheme.get, call_773349.host, call_773349.base,
                         call_773349.route, valid.getOrDefault("path"))
  result = hook(call_773349, url, valid)

proc call*(call_773350: Call_CreateContact_773337; body: JsonNode): Recallable =
  ## createContact
  ## Creates a contact with the specified details.
  ##   body: JObject (required)
  var body_773351 = newJObject()
  if body != nil:
    body_773351 = body
  result = call_773350.call(nil, nil, nil, nil, body_773351)

var createContact* = Call_CreateContact_773337(name: "createContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateContact",
    validator: validate_CreateContact_773338, base: "/", url: url_CreateContact_773339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGatewayGroup_773352 = ref object of OpenApiRestCall_772597
proc url_CreateGatewayGroup_773354(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateGatewayGroup_773353(path: JsonNode; query: JsonNode;
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
  var valid_773355 = header.getOrDefault("X-Amz-Date")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Date", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Security-Token")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Security-Token", valid_773356
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773357 = header.getOrDefault("X-Amz-Target")
  valid_773357 = validateParameter(valid_773357, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateGatewayGroup"))
  if valid_773357 != nil:
    section.add "X-Amz-Target", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Content-Sha256", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Algorithm")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Algorithm", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Signature")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Signature", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-SignedHeaders", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Credential")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Credential", valid_773362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773364: Call_CreateGatewayGroup_773352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a gateway group with the specified details.
  ## 
  let valid = call_773364.validator(path, query, header, formData, body)
  let scheme = call_773364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773364.url(scheme.get, call_773364.host, call_773364.base,
                         call_773364.route, valid.getOrDefault("path"))
  result = hook(call_773364, url, valid)

proc call*(call_773365: Call_CreateGatewayGroup_773352; body: JsonNode): Recallable =
  ## createGatewayGroup
  ## Creates a gateway group with the specified details.
  ##   body: JObject (required)
  var body_773366 = newJObject()
  if body != nil:
    body_773366 = body
  result = call_773365.call(nil, nil, nil, nil, body_773366)

var createGatewayGroup* = Call_CreateGatewayGroup_773352(
    name: "createGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateGatewayGroup",
    validator: validate_CreateGatewayGroup_773353, base: "/",
    url: url_CreateGatewayGroup_773354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_773367 = ref object of OpenApiRestCall_772597
proc url_CreateNetworkProfile_773369(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateNetworkProfile_773368(path: JsonNode; query: JsonNode;
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
  var valid_773370 = header.getOrDefault("X-Amz-Date")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Date", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Security-Token")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Security-Token", valid_773371
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773372 = header.getOrDefault("X-Amz-Target")
  valid_773372 = validateParameter(valid_773372, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateNetworkProfile"))
  if valid_773372 != nil:
    section.add "X-Amz-Target", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Content-Sha256", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Algorithm")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Algorithm", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Signature")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Signature", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-SignedHeaders", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Credential")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Credential", valid_773377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773379: Call_CreateNetworkProfile_773367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a network profile with the specified details.
  ## 
  let valid = call_773379.validator(path, query, header, formData, body)
  let scheme = call_773379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773379.url(scheme.get, call_773379.host, call_773379.base,
                         call_773379.route, valid.getOrDefault("path"))
  result = hook(call_773379, url, valid)

proc call*(call_773380: Call_CreateNetworkProfile_773367; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile with the specified details.
  ##   body: JObject (required)
  var body_773381 = newJObject()
  if body != nil:
    body_773381 = body
  result = call_773380.call(nil, nil, nil, nil, body_773381)

var createNetworkProfile* = Call_CreateNetworkProfile_773367(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_773368, base: "/",
    url: url_CreateNetworkProfile_773369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProfile_773382 = ref object of OpenApiRestCall_772597
proc url_CreateProfile_773384(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateProfile_773383(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773385 = header.getOrDefault("X-Amz-Date")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Date", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-Security-Token")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Security-Token", valid_773386
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773387 = header.getOrDefault("X-Amz-Target")
  valid_773387 = validateParameter(valid_773387, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateProfile"))
  if valid_773387 != nil:
    section.add "X-Amz-Target", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Content-Sha256", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Algorithm")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Algorithm", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Signature")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Signature", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-SignedHeaders", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Credential")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Credential", valid_773392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773394: Call_CreateProfile_773382; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new room profile with the specified details.
  ## 
  let valid = call_773394.validator(path, query, header, formData, body)
  let scheme = call_773394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773394.url(scheme.get, call_773394.host, call_773394.base,
                         call_773394.route, valid.getOrDefault("path"))
  result = hook(call_773394, url, valid)

proc call*(call_773395: Call_CreateProfile_773382; body: JsonNode): Recallable =
  ## createProfile
  ## Creates a new room profile with the specified details.
  ##   body: JObject (required)
  var body_773396 = newJObject()
  if body != nil:
    body_773396 = body
  result = call_773395.call(nil, nil, nil, nil, body_773396)

var createProfile* = Call_CreateProfile_773382(name: "createProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateProfile",
    validator: validate_CreateProfile_773383, base: "/", url: url_CreateProfile_773384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoom_773397 = ref object of OpenApiRestCall_772597
proc url_CreateRoom_773399(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateRoom_773398(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773400 = header.getOrDefault("X-Amz-Date")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Date", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-Security-Token")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Security-Token", valid_773401
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773402 = header.getOrDefault("X-Amz-Target")
  valid_773402 = validateParameter(valid_773402, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateRoom"))
  if valid_773402 != nil:
    section.add "X-Amz-Target", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Content-Sha256", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-Algorithm")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Algorithm", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Signature")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Signature", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-SignedHeaders", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Credential")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Credential", valid_773407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773409: Call_CreateRoom_773397; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a room with the specified details.
  ## 
  let valid = call_773409.validator(path, query, header, formData, body)
  let scheme = call_773409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773409.url(scheme.get, call_773409.host, call_773409.base,
                         call_773409.route, valid.getOrDefault("path"))
  result = hook(call_773409, url, valid)

proc call*(call_773410: Call_CreateRoom_773397; body: JsonNode): Recallable =
  ## createRoom
  ## Creates a room with the specified details.
  ##   body: JObject (required)
  var body_773411 = newJObject()
  if body != nil:
    body_773411 = body
  result = call_773410.call(nil, nil, nil, nil, body_773411)

var createRoom* = Call_CreateRoom_773397(name: "createRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.CreateRoom",
                                      validator: validate_CreateRoom_773398,
                                      base: "/", url: url_CreateRoom_773399,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSkillGroup_773412 = ref object of OpenApiRestCall_772597
proc url_CreateSkillGroup_773414(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateSkillGroup_773413(path: JsonNode; query: JsonNode;
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
  var valid_773415 = header.getOrDefault("X-Amz-Date")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Date", valid_773415
  var valid_773416 = header.getOrDefault("X-Amz-Security-Token")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-Security-Token", valid_773416
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773417 = header.getOrDefault("X-Amz-Target")
  valid_773417 = validateParameter(valid_773417, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateSkillGroup"))
  if valid_773417 != nil:
    section.add "X-Amz-Target", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Content-Sha256", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Algorithm")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Algorithm", valid_773419
  var valid_773420 = header.getOrDefault("X-Amz-Signature")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "X-Amz-Signature", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-SignedHeaders", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Credential")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Credential", valid_773422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773424: Call_CreateSkillGroup_773412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a skill group with a specified name and description.
  ## 
  let valid = call_773424.validator(path, query, header, formData, body)
  let scheme = call_773424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773424.url(scheme.get, call_773424.host, call_773424.base,
                         call_773424.route, valid.getOrDefault("path"))
  result = hook(call_773424, url, valid)

proc call*(call_773425: Call_CreateSkillGroup_773412; body: JsonNode): Recallable =
  ## createSkillGroup
  ## Creates a skill group with a specified name and description.
  ##   body: JObject (required)
  var body_773426 = newJObject()
  if body != nil:
    body_773426 = body
  result = call_773425.call(nil, nil, nil, nil, body_773426)

var createSkillGroup* = Call_CreateSkillGroup_773412(name: "createSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateSkillGroup",
    validator: validate_CreateSkillGroup_773413, base: "/",
    url: url_CreateSkillGroup_773414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_773427 = ref object of OpenApiRestCall_772597
proc url_CreateUser_773429(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUser_773428(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773430 = header.getOrDefault("X-Amz-Date")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Date", valid_773430
  var valid_773431 = header.getOrDefault("X-Amz-Security-Token")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-Security-Token", valid_773431
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773432 = header.getOrDefault("X-Amz-Target")
  valid_773432 = validateParameter(valid_773432, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateUser"))
  if valid_773432 != nil:
    section.add "X-Amz-Target", valid_773432
  var valid_773433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-Content-Sha256", valid_773433
  var valid_773434 = header.getOrDefault("X-Amz-Algorithm")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-Algorithm", valid_773434
  var valid_773435 = header.getOrDefault("X-Amz-Signature")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-Signature", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-SignedHeaders", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-Credential")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Credential", valid_773437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773439: Call_CreateUser_773427; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user.
  ## 
  let valid = call_773439.validator(path, query, header, formData, body)
  let scheme = call_773439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773439.url(scheme.get, call_773439.host, call_773439.base,
                         call_773439.route, valid.getOrDefault("path"))
  result = hook(call_773439, url, valid)

proc call*(call_773440: Call_CreateUser_773427; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user.
  ##   body: JObject (required)
  var body_773441 = newJObject()
  if body != nil:
    body_773441 = body
  result = call_773440.call(nil, nil, nil, nil, body_773441)

var createUser* = Call_CreateUser_773427(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.CreateUser",
                                      validator: validate_CreateUser_773428,
                                      base: "/", url: url_CreateUser_773429,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAddressBook_773442 = ref object of OpenApiRestCall_772597
proc url_DeleteAddressBook_773444(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAddressBook_773443(path: JsonNode; query: JsonNode;
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
  var valid_773445 = header.getOrDefault("X-Amz-Date")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-Date", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-Security-Token")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Security-Token", valid_773446
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773447 = header.getOrDefault("X-Amz-Target")
  valid_773447 = validateParameter(valid_773447, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteAddressBook"))
  if valid_773447 != nil:
    section.add "X-Amz-Target", valid_773447
  var valid_773448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "X-Amz-Content-Sha256", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Algorithm")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Algorithm", valid_773449
  var valid_773450 = header.getOrDefault("X-Amz-Signature")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-Signature", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-SignedHeaders", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-Credential")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Credential", valid_773452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773454: Call_DeleteAddressBook_773442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an address book by the address book ARN.
  ## 
  let valid = call_773454.validator(path, query, header, formData, body)
  let scheme = call_773454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773454.url(scheme.get, call_773454.host, call_773454.base,
                         call_773454.route, valid.getOrDefault("path"))
  result = hook(call_773454, url, valid)

proc call*(call_773455: Call_DeleteAddressBook_773442; body: JsonNode): Recallable =
  ## deleteAddressBook
  ## Deletes an address book by the address book ARN.
  ##   body: JObject (required)
  var body_773456 = newJObject()
  if body != nil:
    body_773456 = body
  result = call_773455.call(nil, nil, nil, nil, body_773456)

var deleteAddressBook* = Call_DeleteAddressBook_773442(name: "deleteAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteAddressBook",
    validator: validate_DeleteAddressBook_773443, base: "/",
    url: url_DeleteAddressBook_773444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBusinessReportSchedule_773457 = ref object of OpenApiRestCall_772597
proc url_DeleteBusinessReportSchedule_773459(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteBusinessReportSchedule_773458(path: JsonNode; query: JsonNode;
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
  var valid_773460 = header.getOrDefault("X-Amz-Date")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "X-Amz-Date", valid_773460
  var valid_773461 = header.getOrDefault("X-Amz-Security-Token")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-Security-Token", valid_773461
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773462 = header.getOrDefault("X-Amz-Target")
  valid_773462 = validateParameter(valid_773462, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteBusinessReportSchedule"))
  if valid_773462 != nil:
    section.add "X-Amz-Target", valid_773462
  var valid_773463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "X-Amz-Content-Sha256", valid_773463
  var valid_773464 = header.getOrDefault("X-Amz-Algorithm")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Algorithm", valid_773464
  var valid_773465 = header.getOrDefault("X-Amz-Signature")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Signature", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-SignedHeaders", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Credential")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Credential", valid_773467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773469: Call_DeleteBusinessReportSchedule_773457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the recurring report delivery schedule with the specified schedule ARN.
  ## 
  let valid = call_773469.validator(path, query, header, formData, body)
  let scheme = call_773469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773469.url(scheme.get, call_773469.host, call_773469.base,
                         call_773469.route, valid.getOrDefault("path"))
  result = hook(call_773469, url, valid)

proc call*(call_773470: Call_DeleteBusinessReportSchedule_773457; body: JsonNode): Recallable =
  ## deleteBusinessReportSchedule
  ## Deletes the recurring report delivery schedule with the specified schedule ARN.
  ##   body: JObject (required)
  var body_773471 = newJObject()
  if body != nil:
    body_773471 = body
  result = call_773470.call(nil, nil, nil, nil, body_773471)

var deleteBusinessReportSchedule* = Call_DeleteBusinessReportSchedule_773457(
    name: "deleteBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteBusinessReportSchedule",
    validator: validate_DeleteBusinessReportSchedule_773458, base: "/",
    url: url_DeleteBusinessReportSchedule_773459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConferenceProvider_773472 = ref object of OpenApiRestCall_772597
proc url_DeleteConferenceProvider_773474(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteConferenceProvider_773473(path: JsonNode; query: JsonNode;
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
  var valid_773475 = header.getOrDefault("X-Amz-Date")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "X-Amz-Date", valid_773475
  var valid_773476 = header.getOrDefault("X-Amz-Security-Token")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "X-Amz-Security-Token", valid_773476
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773477 = header.getOrDefault("X-Amz-Target")
  valid_773477 = validateParameter(valid_773477, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteConferenceProvider"))
  if valid_773477 != nil:
    section.add "X-Amz-Target", valid_773477
  var valid_773478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "X-Amz-Content-Sha256", valid_773478
  var valid_773479 = header.getOrDefault("X-Amz-Algorithm")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-Algorithm", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-Signature")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Signature", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-SignedHeaders", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-Credential")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Credential", valid_773482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773484: Call_DeleteConferenceProvider_773472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a conference provider.
  ## 
  let valid = call_773484.validator(path, query, header, formData, body)
  let scheme = call_773484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773484.url(scheme.get, call_773484.host, call_773484.base,
                         call_773484.route, valid.getOrDefault("path"))
  result = hook(call_773484, url, valid)

proc call*(call_773485: Call_DeleteConferenceProvider_773472; body: JsonNode): Recallable =
  ## deleteConferenceProvider
  ## Deletes a conference provider.
  ##   body: JObject (required)
  var body_773486 = newJObject()
  if body != nil:
    body_773486 = body
  result = call_773485.call(nil, nil, nil, nil, body_773486)

var deleteConferenceProvider* = Call_DeleteConferenceProvider_773472(
    name: "deleteConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteConferenceProvider",
    validator: validate_DeleteConferenceProvider_773473, base: "/",
    url: url_DeleteConferenceProvider_773474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteContact_773487 = ref object of OpenApiRestCall_772597
proc url_DeleteContact_773489(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteContact_773488(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773490 = header.getOrDefault("X-Amz-Date")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Date", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-Security-Token")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Security-Token", valid_773491
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773492 = header.getOrDefault("X-Amz-Target")
  valid_773492 = validateParameter(valid_773492, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteContact"))
  if valid_773492 != nil:
    section.add "X-Amz-Target", valid_773492
  var valid_773493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-Content-Sha256", valid_773493
  var valid_773494 = header.getOrDefault("X-Amz-Algorithm")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-Algorithm", valid_773494
  var valid_773495 = header.getOrDefault("X-Amz-Signature")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "X-Amz-Signature", valid_773495
  var valid_773496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-SignedHeaders", valid_773496
  var valid_773497 = header.getOrDefault("X-Amz-Credential")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-Credential", valid_773497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773499: Call_DeleteContact_773487; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a contact by the contact ARN.
  ## 
  let valid = call_773499.validator(path, query, header, formData, body)
  let scheme = call_773499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773499.url(scheme.get, call_773499.host, call_773499.base,
                         call_773499.route, valid.getOrDefault("path"))
  result = hook(call_773499, url, valid)

proc call*(call_773500: Call_DeleteContact_773487; body: JsonNode): Recallable =
  ## deleteContact
  ## Deletes a contact by the contact ARN.
  ##   body: JObject (required)
  var body_773501 = newJObject()
  if body != nil:
    body_773501 = body
  result = call_773500.call(nil, nil, nil, nil, body_773501)

var deleteContact* = Call_DeleteContact_773487(name: "deleteContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteContact",
    validator: validate_DeleteContact_773488, base: "/", url: url_DeleteContact_773489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevice_773502 = ref object of OpenApiRestCall_772597
proc url_DeleteDevice_773504(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteDevice_773503(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773505 = header.getOrDefault("X-Amz-Date")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Date", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-Security-Token")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Security-Token", valid_773506
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773507 = header.getOrDefault("X-Amz-Target")
  valid_773507 = validateParameter(valid_773507, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteDevice"))
  if valid_773507 != nil:
    section.add "X-Amz-Target", valid_773507
  var valid_773508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-Content-Sha256", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-Algorithm")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-Algorithm", valid_773509
  var valid_773510 = header.getOrDefault("X-Amz-Signature")
  valid_773510 = validateParameter(valid_773510, JString, required = false,
                                 default = nil)
  if valid_773510 != nil:
    section.add "X-Amz-Signature", valid_773510
  var valid_773511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773511 = validateParameter(valid_773511, JString, required = false,
                                 default = nil)
  if valid_773511 != nil:
    section.add "X-Amz-SignedHeaders", valid_773511
  var valid_773512 = header.getOrDefault("X-Amz-Credential")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Credential", valid_773512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773514: Call_DeleteDevice_773502; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a device from Alexa For Business.
  ## 
  let valid = call_773514.validator(path, query, header, formData, body)
  let scheme = call_773514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773514.url(scheme.get, call_773514.host, call_773514.base,
                         call_773514.route, valid.getOrDefault("path"))
  result = hook(call_773514, url, valid)

proc call*(call_773515: Call_DeleteDevice_773502; body: JsonNode): Recallable =
  ## deleteDevice
  ## Removes a device from Alexa For Business.
  ##   body: JObject (required)
  var body_773516 = newJObject()
  if body != nil:
    body_773516 = body
  result = call_773515.call(nil, nil, nil, nil, body_773516)

var deleteDevice* = Call_DeleteDevice_773502(name: "deleteDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteDevice",
    validator: validate_DeleteDevice_773503, base: "/", url: url_DeleteDevice_773504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceUsageData_773517 = ref object of OpenApiRestCall_772597
proc url_DeleteDeviceUsageData_773519(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteDeviceUsageData_773518(path: JsonNode; query: JsonNode;
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
  var valid_773520 = header.getOrDefault("X-Amz-Date")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Date", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-Security-Token")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Security-Token", valid_773521
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773522 = header.getOrDefault("X-Amz-Target")
  valid_773522 = validateParameter(valid_773522, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteDeviceUsageData"))
  if valid_773522 != nil:
    section.add "X-Amz-Target", valid_773522
  var valid_773523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-Content-Sha256", valid_773523
  var valid_773524 = header.getOrDefault("X-Amz-Algorithm")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "X-Amz-Algorithm", valid_773524
  var valid_773525 = header.getOrDefault("X-Amz-Signature")
  valid_773525 = validateParameter(valid_773525, JString, required = false,
                                 default = nil)
  if valid_773525 != nil:
    section.add "X-Amz-Signature", valid_773525
  var valid_773526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773526 = validateParameter(valid_773526, JString, required = false,
                                 default = nil)
  if valid_773526 != nil:
    section.add "X-Amz-SignedHeaders", valid_773526
  var valid_773527 = header.getOrDefault("X-Amz-Credential")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-Credential", valid_773527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773529: Call_DeleteDeviceUsageData_773517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## When this action is called for a specified shared device, it allows authorized users to delete the device's entire previous history of voice input data and associated response data. This action can be called once every 24 hours for a specific shared device.
  ## 
  let valid = call_773529.validator(path, query, header, formData, body)
  let scheme = call_773529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773529.url(scheme.get, call_773529.host, call_773529.base,
                         call_773529.route, valid.getOrDefault("path"))
  result = hook(call_773529, url, valid)

proc call*(call_773530: Call_DeleteDeviceUsageData_773517; body: JsonNode): Recallable =
  ## deleteDeviceUsageData
  ## When this action is called for a specified shared device, it allows authorized users to delete the device's entire previous history of voice input data and associated response data. This action can be called once every 24 hours for a specific shared device.
  ##   body: JObject (required)
  var body_773531 = newJObject()
  if body != nil:
    body_773531 = body
  result = call_773530.call(nil, nil, nil, nil, body_773531)

var deleteDeviceUsageData* = Call_DeleteDeviceUsageData_773517(
    name: "deleteDeviceUsageData", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteDeviceUsageData",
    validator: validate_DeleteDeviceUsageData_773518, base: "/",
    url: url_DeleteDeviceUsageData_773519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayGroup_773532 = ref object of OpenApiRestCall_772597
proc url_DeleteGatewayGroup_773534(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteGatewayGroup_773533(path: JsonNode; query: JsonNode;
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
  var valid_773535 = header.getOrDefault("X-Amz-Date")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "X-Amz-Date", valid_773535
  var valid_773536 = header.getOrDefault("X-Amz-Security-Token")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Security-Token", valid_773536
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773537 = header.getOrDefault("X-Amz-Target")
  valid_773537 = validateParameter(valid_773537, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteGatewayGroup"))
  if valid_773537 != nil:
    section.add "X-Amz-Target", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Content-Sha256", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-Algorithm")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-Algorithm", valid_773539
  var valid_773540 = header.getOrDefault("X-Amz-Signature")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-Signature", valid_773540
  var valid_773541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773541 = validateParameter(valid_773541, JString, required = false,
                                 default = nil)
  if valid_773541 != nil:
    section.add "X-Amz-SignedHeaders", valid_773541
  var valid_773542 = header.getOrDefault("X-Amz-Credential")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Credential", valid_773542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773544: Call_DeleteGatewayGroup_773532; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a gateway group.
  ## 
  let valid = call_773544.validator(path, query, header, formData, body)
  let scheme = call_773544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773544.url(scheme.get, call_773544.host, call_773544.base,
                         call_773544.route, valid.getOrDefault("path"))
  result = hook(call_773544, url, valid)

proc call*(call_773545: Call_DeleteGatewayGroup_773532; body: JsonNode): Recallable =
  ## deleteGatewayGroup
  ## Deletes a gateway group.
  ##   body: JObject (required)
  var body_773546 = newJObject()
  if body != nil:
    body_773546 = body
  result = call_773545.call(nil, nil, nil, nil, body_773546)

var deleteGatewayGroup* = Call_DeleteGatewayGroup_773532(
    name: "deleteGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteGatewayGroup",
    validator: validate_DeleteGatewayGroup_773533, base: "/",
    url: url_DeleteGatewayGroup_773534, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_773547 = ref object of OpenApiRestCall_772597
proc url_DeleteNetworkProfile_773549(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteNetworkProfile_773548(path: JsonNode; query: JsonNode;
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
  var valid_773550 = header.getOrDefault("X-Amz-Date")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-Date", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-Security-Token")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Security-Token", valid_773551
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773552 = header.getOrDefault("X-Amz-Target")
  valid_773552 = validateParameter(valid_773552, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteNetworkProfile"))
  if valid_773552 != nil:
    section.add "X-Amz-Target", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Content-Sha256", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-Algorithm")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Algorithm", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-Signature")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-Signature", valid_773555
  var valid_773556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773556 = validateParameter(valid_773556, JString, required = false,
                                 default = nil)
  if valid_773556 != nil:
    section.add "X-Amz-SignedHeaders", valid_773556
  var valid_773557 = header.getOrDefault("X-Amz-Credential")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-Credential", valid_773557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773559: Call_DeleteNetworkProfile_773547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a network profile by the network profile ARN.
  ## 
  let valid = call_773559.validator(path, query, header, formData, body)
  let scheme = call_773559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773559.url(scheme.get, call_773559.host, call_773559.base,
                         call_773559.route, valid.getOrDefault("path"))
  result = hook(call_773559, url, valid)

proc call*(call_773560: Call_DeleteNetworkProfile_773547; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile by the network profile ARN.
  ##   body: JObject (required)
  var body_773561 = newJObject()
  if body != nil:
    body_773561 = body
  result = call_773560.call(nil, nil, nil, nil, body_773561)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_773547(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_773548, base: "/",
    url: url_DeleteNetworkProfile_773549, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProfile_773562 = ref object of OpenApiRestCall_772597
proc url_DeleteProfile_773564(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteProfile_773563(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773565 = header.getOrDefault("X-Amz-Date")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-Date", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-Security-Token")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Security-Token", valid_773566
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773567 = header.getOrDefault("X-Amz-Target")
  valid_773567 = validateParameter(valid_773567, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteProfile"))
  if valid_773567 != nil:
    section.add "X-Amz-Target", valid_773567
  var valid_773568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773568 = validateParameter(valid_773568, JString, required = false,
                                 default = nil)
  if valid_773568 != nil:
    section.add "X-Amz-Content-Sha256", valid_773568
  var valid_773569 = header.getOrDefault("X-Amz-Algorithm")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-Algorithm", valid_773569
  var valid_773570 = header.getOrDefault("X-Amz-Signature")
  valid_773570 = validateParameter(valid_773570, JString, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "X-Amz-Signature", valid_773570
  var valid_773571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773571 = validateParameter(valid_773571, JString, required = false,
                                 default = nil)
  if valid_773571 != nil:
    section.add "X-Amz-SignedHeaders", valid_773571
  var valid_773572 = header.getOrDefault("X-Amz-Credential")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Credential", valid_773572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773574: Call_DeleteProfile_773562; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a room profile by the profile ARN.
  ## 
  let valid = call_773574.validator(path, query, header, formData, body)
  let scheme = call_773574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773574.url(scheme.get, call_773574.host, call_773574.base,
                         call_773574.route, valid.getOrDefault("path"))
  result = hook(call_773574, url, valid)

proc call*(call_773575: Call_DeleteProfile_773562; body: JsonNode): Recallable =
  ## deleteProfile
  ## Deletes a room profile by the profile ARN.
  ##   body: JObject (required)
  var body_773576 = newJObject()
  if body != nil:
    body_773576 = body
  result = call_773575.call(nil, nil, nil, nil, body_773576)

var deleteProfile* = Call_DeleteProfile_773562(name: "deleteProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteProfile",
    validator: validate_DeleteProfile_773563, base: "/", url: url_DeleteProfile_773564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoom_773577 = ref object of OpenApiRestCall_772597
proc url_DeleteRoom_773579(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteRoom_773578(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773580 = header.getOrDefault("X-Amz-Date")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-Date", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-Security-Token")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Security-Token", valid_773581
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773582 = header.getOrDefault("X-Amz-Target")
  valid_773582 = validateParameter(valid_773582, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteRoom"))
  if valid_773582 != nil:
    section.add "X-Amz-Target", valid_773582
  var valid_773583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "X-Amz-Content-Sha256", valid_773583
  var valid_773584 = header.getOrDefault("X-Amz-Algorithm")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-Algorithm", valid_773584
  var valid_773585 = header.getOrDefault("X-Amz-Signature")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-Signature", valid_773585
  var valid_773586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-SignedHeaders", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Credential")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Credential", valid_773587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773589: Call_DeleteRoom_773577; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a room by the room ARN.
  ## 
  let valid = call_773589.validator(path, query, header, formData, body)
  let scheme = call_773589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773589.url(scheme.get, call_773589.host, call_773589.base,
                         call_773589.route, valid.getOrDefault("path"))
  result = hook(call_773589, url, valid)

proc call*(call_773590: Call_DeleteRoom_773577; body: JsonNode): Recallable =
  ## deleteRoom
  ## Deletes a room by the room ARN.
  ##   body: JObject (required)
  var body_773591 = newJObject()
  if body != nil:
    body_773591 = body
  result = call_773590.call(nil, nil, nil, nil, body_773591)

var deleteRoom* = Call_DeleteRoom_773577(name: "deleteRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DeleteRoom",
                                      validator: validate_DeleteRoom_773578,
                                      base: "/", url: url_DeleteRoom_773579,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoomSkillParameter_773592 = ref object of OpenApiRestCall_772597
proc url_DeleteRoomSkillParameter_773594(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteRoomSkillParameter_773593(path: JsonNode; query: JsonNode;
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
  var valid_773595 = header.getOrDefault("X-Amz-Date")
  valid_773595 = validateParameter(valid_773595, JString, required = false,
                                 default = nil)
  if valid_773595 != nil:
    section.add "X-Amz-Date", valid_773595
  var valid_773596 = header.getOrDefault("X-Amz-Security-Token")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "X-Amz-Security-Token", valid_773596
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773597 = header.getOrDefault("X-Amz-Target")
  valid_773597 = validateParameter(valid_773597, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteRoomSkillParameter"))
  if valid_773597 != nil:
    section.add "X-Amz-Target", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-Content-Sha256", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-Algorithm")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Algorithm", valid_773599
  var valid_773600 = header.getOrDefault("X-Amz-Signature")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Signature", valid_773600
  var valid_773601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773601 = validateParameter(valid_773601, JString, required = false,
                                 default = nil)
  if valid_773601 != nil:
    section.add "X-Amz-SignedHeaders", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-Credential")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Credential", valid_773602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773604: Call_DeleteRoomSkillParameter_773592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes room skill parameter details by room, skill, and parameter key ID.
  ## 
  let valid = call_773604.validator(path, query, header, formData, body)
  let scheme = call_773604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773604.url(scheme.get, call_773604.host, call_773604.base,
                         call_773604.route, valid.getOrDefault("path"))
  result = hook(call_773604, url, valid)

proc call*(call_773605: Call_DeleteRoomSkillParameter_773592; body: JsonNode): Recallable =
  ## deleteRoomSkillParameter
  ## Deletes room skill parameter details by room, skill, and parameter key ID.
  ##   body: JObject (required)
  var body_773606 = newJObject()
  if body != nil:
    body_773606 = body
  result = call_773605.call(nil, nil, nil, nil, body_773606)

var deleteRoomSkillParameter* = Call_DeleteRoomSkillParameter_773592(
    name: "deleteRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteRoomSkillParameter",
    validator: validate_DeleteRoomSkillParameter_773593, base: "/",
    url: url_DeleteRoomSkillParameter_773594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSkillAuthorization_773607 = ref object of OpenApiRestCall_772597
proc url_DeleteSkillAuthorization_773609(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteSkillAuthorization_773608(path: JsonNode; query: JsonNode;
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
  var valid_773610 = header.getOrDefault("X-Amz-Date")
  valid_773610 = validateParameter(valid_773610, JString, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "X-Amz-Date", valid_773610
  var valid_773611 = header.getOrDefault("X-Amz-Security-Token")
  valid_773611 = validateParameter(valid_773611, JString, required = false,
                                 default = nil)
  if valid_773611 != nil:
    section.add "X-Amz-Security-Token", valid_773611
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773612 = header.getOrDefault("X-Amz-Target")
  valid_773612 = validateParameter(valid_773612, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteSkillAuthorization"))
  if valid_773612 != nil:
    section.add "X-Amz-Target", valid_773612
  var valid_773613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-Content-Sha256", valid_773613
  var valid_773614 = header.getOrDefault("X-Amz-Algorithm")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Algorithm", valid_773614
  var valid_773615 = header.getOrDefault("X-Amz-Signature")
  valid_773615 = validateParameter(valid_773615, JString, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "X-Amz-Signature", valid_773615
  var valid_773616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-SignedHeaders", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-Credential")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Credential", valid_773617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773619: Call_DeleteSkillAuthorization_773607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Unlinks a third-party account from a skill.
  ## 
  let valid = call_773619.validator(path, query, header, formData, body)
  let scheme = call_773619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773619.url(scheme.get, call_773619.host, call_773619.base,
                         call_773619.route, valid.getOrDefault("path"))
  result = hook(call_773619, url, valid)

proc call*(call_773620: Call_DeleteSkillAuthorization_773607; body: JsonNode): Recallable =
  ## deleteSkillAuthorization
  ## Unlinks a third-party account from a skill.
  ##   body: JObject (required)
  var body_773621 = newJObject()
  if body != nil:
    body_773621 = body
  result = call_773620.call(nil, nil, nil, nil, body_773621)

var deleteSkillAuthorization* = Call_DeleteSkillAuthorization_773607(
    name: "deleteSkillAuthorization", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteSkillAuthorization",
    validator: validate_DeleteSkillAuthorization_773608, base: "/",
    url: url_DeleteSkillAuthorization_773609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSkillGroup_773622 = ref object of OpenApiRestCall_772597
proc url_DeleteSkillGroup_773624(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteSkillGroup_773623(path: JsonNode; query: JsonNode;
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
  var valid_773625 = header.getOrDefault("X-Amz-Date")
  valid_773625 = validateParameter(valid_773625, JString, required = false,
                                 default = nil)
  if valid_773625 != nil:
    section.add "X-Amz-Date", valid_773625
  var valid_773626 = header.getOrDefault("X-Amz-Security-Token")
  valid_773626 = validateParameter(valid_773626, JString, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "X-Amz-Security-Token", valid_773626
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773627 = header.getOrDefault("X-Amz-Target")
  valid_773627 = validateParameter(valid_773627, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteSkillGroup"))
  if valid_773627 != nil:
    section.add "X-Amz-Target", valid_773627
  var valid_773628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "X-Amz-Content-Sha256", valid_773628
  var valid_773629 = header.getOrDefault("X-Amz-Algorithm")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amz-Algorithm", valid_773629
  var valid_773630 = header.getOrDefault("X-Amz-Signature")
  valid_773630 = validateParameter(valid_773630, JString, required = false,
                                 default = nil)
  if valid_773630 != nil:
    section.add "X-Amz-Signature", valid_773630
  var valid_773631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773631 = validateParameter(valid_773631, JString, required = false,
                                 default = nil)
  if valid_773631 != nil:
    section.add "X-Amz-SignedHeaders", valid_773631
  var valid_773632 = header.getOrDefault("X-Amz-Credential")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-Credential", valid_773632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773634: Call_DeleteSkillGroup_773622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a skill group by skill group ARN.
  ## 
  let valid = call_773634.validator(path, query, header, formData, body)
  let scheme = call_773634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773634.url(scheme.get, call_773634.host, call_773634.base,
                         call_773634.route, valid.getOrDefault("path"))
  result = hook(call_773634, url, valid)

proc call*(call_773635: Call_DeleteSkillGroup_773622; body: JsonNode): Recallable =
  ## deleteSkillGroup
  ## Deletes a skill group by skill group ARN.
  ##   body: JObject (required)
  var body_773636 = newJObject()
  if body != nil:
    body_773636 = body
  result = call_773635.call(nil, nil, nil, nil, body_773636)

var deleteSkillGroup* = Call_DeleteSkillGroup_773622(name: "deleteSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteSkillGroup",
    validator: validate_DeleteSkillGroup_773623, base: "/",
    url: url_DeleteSkillGroup_773624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_773637 = ref object of OpenApiRestCall_772597
proc url_DeleteUser_773639(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUser_773638(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773640 = header.getOrDefault("X-Amz-Date")
  valid_773640 = validateParameter(valid_773640, JString, required = false,
                                 default = nil)
  if valid_773640 != nil:
    section.add "X-Amz-Date", valid_773640
  var valid_773641 = header.getOrDefault("X-Amz-Security-Token")
  valid_773641 = validateParameter(valid_773641, JString, required = false,
                                 default = nil)
  if valid_773641 != nil:
    section.add "X-Amz-Security-Token", valid_773641
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773642 = header.getOrDefault("X-Amz-Target")
  valid_773642 = validateParameter(valid_773642, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteUser"))
  if valid_773642 != nil:
    section.add "X-Amz-Target", valid_773642
  var valid_773643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-Content-Sha256", valid_773643
  var valid_773644 = header.getOrDefault("X-Amz-Algorithm")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-Algorithm", valid_773644
  var valid_773645 = header.getOrDefault("X-Amz-Signature")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Signature", valid_773645
  var valid_773646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773646 = validateParameter(valid_773646, JString, required = false,
                                 default = nil)
  if valid_773646 != nil:
    section.add "X-Amz-SignedHeaders", valid_773646
  var valid_773647 = header.getOrDefault("X-Amz-Credential")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Credential", valid_773647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773649: Call_DeleteUser_773637; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified user by user ARN and enrollment ARN.
  ## 
  let valid = call_773649.validator(path, query, header, formData, body)
  let scheme = call_773649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773649.url(scheme.get, call_773649.host, call_773649.base,
                         call_773649.route, valid.getOrDefault("path"))
  result = hook(call_773649, url, valid)

proc call*(call_773650: Call_DeleteUser_773637; body: JsonNode): Recallable =
  ## deleteUser
  ## Deletes a specified user by user ARN and enrollment ARN.
  ##   body: JObject (required)
  var body_773651 = newJObject()
  if body != nil:
    body_773651 = body
  result = call_773650.call(nil, nil, nil, nil, body_773651)

var deleteUser* = Call_DeleteUser_773637(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DeleteUser",
                                      validator: validate_DeleteUser_773638,
                                      base: "/", url: url_DeleteUser_773639,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateContactFromAddressBook_773652 = ref object of OpenApiRestCall_772597
proc url_DisassociateContactFromAddressBook_773654(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateContactFromAddressBook_773653(path: JsonNode;
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
  var valid_773655 = header.getOrDefault("X-Amz-Date")
  valid_773655 = validateParameter(valid_773655, JString, required = false,
                                 default = nil)
  if valid_773655 != nil:
    section.add "X-Amz-Date", valid_773655
  var valid_773656 = header.getOrDefault("X-Amz-Security-Token")
  valid_773656 = validateParameter(valid_773656, JString, required = false,
                                 default = nil)
  if valid_773656 != nil:
    section.add "X-Amz-Security-Token", valid_773656
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773657 = header.getOrDefault("X-Amz-Target")
  valid_773657 = validateParameter(valid_773657, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateContactFromAddressBook"))
  if valid_773657 != nil:
    section.add "X-Amz-Target", valid_773657
  var valid_773658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773658 = validateParameter(valid_773658, JString, required = false,
                                 default = nil)
  if valid_773658 != nil:
    section.add "X-Amz-Content-Sha256", valid_773658
  var valid_773659 = header.getOrDefault("X-Amz-Algorithm")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-Algorithm", valid_773659
  var valid_773660 = header.getOrDefault("X-Amz-Signature")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amz-Signature", valid_773660
  var valid_773661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "X-Amz-SignedHeaders", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-Credential")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Credential", valid_773662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773664: Call_DisassociateContactFromAddressBook_773652;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a contact from a given address book.
  ## 
  let valid = call_773664.validator(path, query, header, formData, body)
  let scheme = call_773664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773664.url(scheme.get, call_773664.host, call_773664.base,
                         call_773664.route, valid.getOrDefault("path"))
  result = hook(call_773664, url, valid)

proc call*(call_773665: Call_DisassociateContactFromAddressBook_773652;
          body: JsonNode): Recallable =
  ## disassociateContactFromAddressBook
  ## Disassociates a contact from a given address book.
  ##   body: JObject (required)
  var body_773666 = newJObject()
  if body != nil:
    body_773666 = body
  result = call_773665.call(nil, nil, nil, nil, body_773666)

var disassociateContactFromAddressBook* = Call_DisassociateContactFromAddressBook_773652(
    name: "disassociateContactFromAddressBook", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DisassociateContactFromAddressBook",
    validator: validate_DisassociateContactFromAddressBook_773653, base: "/",
    url: url_DisassociateContactFromAddressBook_773654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDeviceFromRoom_773667 = ref object of OpenApiRestCall_772597
proc url_DisassociateDeviceFromRoom_773669(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateDeviceFromRoom_773668(path: JsonNode; query: JsonNode;
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
  var valid_773670 = header.getOrDefault("X-Amz-Date")
  valid_773670 = validateParameter(valid_773670, JString, required = false,
                                 default = nil)
  if valid_773670 != nil:
    section.add "X-Amz-Date", valid_773670
  var valid_773671 = header.getOrDefault("X-Amz-Security-Token")
  valid_773671 = validateParameter(valid_773671, JString, required = false,
                                 default = nil)
  if valid_773671 != nil:
    section.add "X-Amz-Security-Token", valid_773671
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773672 = header.getOrDefault("X-Amz-Target")
  valid_773672 = validateParameter(valid_773672, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateDeviceFromRoom"))
  if valid_773672 != nil:
    section.add "X-Amz-Target", valid_773672
  var valid_773673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773673 = validateParameter(valid_773673, JString, required = false,
                                 default = nil)
  if valid_773673 != nil:
    section.add "X-Amz-Content-Sha256", valid_773673
  var valid_773674 = header.getOrDefault("X-Amz-Algorithm")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "X-Amz-Algorithm", valid_773674
  var valid_773675 = header.getOrDefault("X-Amz-Signature")
  valid_773675 = validateParameter(valid_773675, JString, required = false,
                                 default = nil)
  if valid_773675 != nil:
    section.add "X-Amz-Signature", valid_773675
  var valid_773676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773676 = validateParameter(valid_773676, JString, required = false,
                                 default = nil)
  if valid_773676 != nil:
    section.add "X-Amz-SignedHeaders", valid_773676
  var valid_773677 = header.getOrDefault("X-Amz-Credential")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Credential", valid_773677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773679: Call_DisassociateDeviceFromRoom_773667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a device from its current room. The device continues to be connected to the Wi-Fi network and is still registered to the account. The device settings and skills are removed from the room.
  ## 
  let valid = call_773679.validator(path, query, header, formData, body)
  let scheme = call_773679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773679.url(scheme.get, call_773679.host, call_773679.base,
                         call_773679.route, valid.getOrDefault("path"))
  result = hook(call_773679, url, valid)

proc call*(call_773680: Call_DisassociateDeviceFromRoom_773667; body: JsonNode): Recallable =
  ## disassociateDeviceFromRoom
  ## Disassociates a device from its current room. The device continues to be connected to the Wi-Fi network and is still registered to the account. The device settings and skills are removed from the room.
  ##   body: JObject (required)
  var body_773681 = newJObject()
  if body != nil:
    body_773681 = body
  result = call_773680.call(nil, nil, nil, nil, body_773681)

var disassociateDeviceFromRoom* = Call_DisassociateDeviceFromRoom_773667(
    name: "disassociateDeviceFromRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateDeviceFromRoom",
    validator: validate_DisassociateDeviceFromRoom_773668, base: "/",
    url: url_DisassociateDeviceFromRoom_773669,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillFromSkillGroup_773682 = ref object of OpenApiRestCall_772597
proc url_DisassociateSkillFromSkillGroup_773684(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateSkillFromSkillGroup_773683(path: JsonNode;
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
  var valid_773685 = header.getOrDefault("X-Amz-Date")
  valid_773685 = validateParameter(valid_773685, JString, required = false,
                                 default = nil)
  if valid_773685 != nil:
    section.add "X-Amz-Date", valid_773685
  var valid_773686 = header.getOrDefault("X-Amz-Security-Token")
  valid_773686 = validateParameter(valid_773686, JString, required = false,
                                 default = nil)
  if valid_773686 != nil:
    section.add "X-Amz-Security-Token", valid_773686
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773687 = header.getOrDefault("X-Amz-Target")
  valid_773687 = validateParameter(valid_773687, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillFromSkillGroup"))
  if valid_773687 != nil:
    section.add "X-Amz-Target", valid_773687
  var valid_773688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773688 = validateParameter(valid_773688, JString, required = false,
                                 default = nil)
  if valid_773688 != nil:
    section.add "X-Amz-Content-Sha256", valid_773688
  var valid_773689 = header.getOrDefault("X-Amz-Algorithm")
  valid_773689 = validateParameter(valid_773689, JString, required = false,
                                 default = nil)
  if valid_773689 != nil:
    section.add "X-Amz-Algorithm", valid_773689
  var valid_773690 = header.getOrDefault("X-Amz-Signature")
  valid_773690 = validateParameter(valid_773690, JString, required = false,
                                 default = nil)
  if valid_773690 != nil:
    section.add "X-Amz-Signature", valid_773690
  var valid_773691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773691 = validateParameter(valid_773691, JString, required = false,
                                 default = nil)
  if valid_773691 != nil:
    section.add "X-Amz-SignedHeaders", valid_773691
  var valid_773692 = header.getOrDefault("X-Amz-Credential")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Credential", valid_773692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773694: Call_DisassociateSkillFromSkillGroup_773682;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a skill from a skill group.
  ## 
  let valid = call_773694.validator(path, query, header, formData, body)
  let scheme = call_773694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773694.url(scheme.get, call_773694.host, call_773694.base,
                         call_773694.route, valid.getOrDefault("path"))
  result = hook(call_773694, url, valid)

proc call*(call_773695: Call_DisassociateSkillFromSkillGroup_773682; body: JsonNode): Recallable =
  ## disassociateSkillFromSkillGroup
  ## Disassociates a skill from a skill group.
  ##   body: JObject (required)
  var body_773696 = newJObject()
  if body != nil:
    body_773696 = body
  result = call_773695.call(nil, nil, nil, nil, body_773696)

var disassociateSkillFromSkillGroup* = Call_DisassociateSkillFromSkillGroup_773682(
    name: "disassociateSkillFromSkillGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillFromSkillGroup",
    validator: validate_DisassociateSkillFromSkillGroup_773683, base: "/",
    url: url_DisassociateSkillFromSkillGroup_773684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillFromUsers_773697 = ref object of OpenApiRestCall_772597
proc url_DisassociateSkillFromUsers_773699(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateSkillFromUsers_773698(path: JsonNode; query: JsonNode;
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
  var valid_773700 = header.getOrDefault("X-Amz-Date")
  valid_773700 = validateParameter(valid_773700, JString, required = false,
                                 default = nil)
  if valid_773700 != nil:
    section.add "X-Amz-Date", valid_773700
  var valid_773701 = header.getOrDefault("X-Amz-Security-Token")
  valid_773701 = validateParameter(valid_773701, JString, required = false,
                                 default = nil)
  if valid_773701 != nil:
    section.add "X-Amz-Security-Token", valid_773701
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773702 = header.getOrDefault("X-Amz-Target")
  valid_773702 = validateParameter(valid_773702, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillFromUsers"))
  if valid_773702 != nil:
    section.add "X-Amz-Target", valid_773702
  var valid_773703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773703 = validateParameter(valid_773703, JString, required = false,
                                 default = nil)
  if valid_773703 != nil:
    section.add "X-Amz-Content-Sha256", valid_773703
  var valid_773704 = header.getOrDefault("X-Amz-Algorithm")
  valid_773704 = validateParameter(valid_773704, JString, required = false,
                                 default = nil)
  if valid_773704 != nil:
    section.add "X-Amz-Algorithm", valid_773704
  var valid_773705 = header.getOrDefault("X-Amz-Signature")
  valid_773705 = validateParameter(valid_773705, JString, required = false,
                                 default = nil)
  if valid_773705 != nil:
    section.add "X-Amz-Signature", valid_773705
  var valid_773706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773706 = validateParameter(valid_773706, JString, required = false,
                                 default = nil)
  if valid_773706 != nil:
    section.add "X-Amz-SignedHeaders", valid_773706
  var valid_773707 = header.getOrDefault("X-Amz-Credential")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Credential", valid_773707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773709: Call_DisassociateSkillFromUsers_773697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Makes a private skill unavailable for enrolled users and prevents them from enabling it on their devices.
  ## 
  let valid = call_773709.validator(path, query, header, formData, body)
  let scheme = call_773709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773709.url(scheme.get, call_773709.host, call_773709.base,
                         call_773709.route, valid.getOrDefault("path"))
  result = hook(call_773709, url, valid)

proc call*(call_773710: Call_DisassociateSkillFromUsers_773697; body: JsonNode): Recallable =
  ## disassociateSkillFromUsers
  ## Makes a private skill unavailable for enrolled users and prevents them from enabling it on their devices.
  ##   body: JObject (required)
  var body_773711 = newJObject()
  if body != nil:
    body_773711 = body
  result = call_773710.call(nil, nil, nil, nil, body_773711)

var disassociateSkillFromUsers* = Call_DisassociateSkillFromUsers_773697(
    name: "disassociateSkillFromUsers", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillFromUsers",
    validator: validate_DisassociateSkillFromUsers_773698, base: "/",
    url: url_DisassociateSkillFromUsers_773699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillGroupFromRoom_773712 = ref object of OpenApiRestCall_772597
proc url_DisassociateSkillGroupFromRoom_773714(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateSkillGroupFromRoom_773713(path: JsonNode;
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
  var valid_773715 = header.getOrDefault("X-Amz-Date")
  valid_773715 = validateParameter(valid_773715, JString, required = false,
                                 default = nil)
  if valid_773715 != nil:
    section.add "X-Amz-Date", valid_773715
  var valid_773716 = header.getOrDefault("X-Amz-Security-Token")
  valid_773716 = validateParameter(valid_773716, JString, required = false,
                                 default = nil)
  if valid_773716 != nil:
    section.add "X-Amz-Security-Token", valid_773716
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773717 = header.getOrDefault("X-Amz-Target")
  valid_773717 = validateParameter(valid_773717, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillGroupFromRoom"))
  if valid_773717 != nil:
    section.add "X-Amz-Target", valid_773717
  var valid_773718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773718 = validateParameter(valid_773718, JString, required = false,
                                 default = nil)
  if valid_773718 != nil:
    section.add "X-Amz-Content-Sha256", valid_773718
  var valid_773719 = header.getOrDefault("X-Amz-Algorithm")
  valid_773719 = validateParameter(valid_773719, JString, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "X-Amz-Algorithm", valid_773719
  var valid_773720 = header.getOrDefault("X-Amz-Signature")
  valid_773720 = validateParameter(valid_773720, JString, required = false,
                                 default = nil)
  if valid_773720 != nil:
    section.add "X-Amz-Signature", valid_773720
  var valid_773721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773721 = validateParameter(valid_773721, JString, required = false,
                                 default = nil)
  if valid_773721 != nil:
    section.add "X-Amz-SignedHeaders", valid_773721
  var valid_773722 = header.getOrDefault("X-Amz-Credential")
  valid_773722 = validateParameter(valid_773722, JString, required = false,
                                 default = nil)
  if valid_773722 != nil:
    section.add "X-Amz-Credential", valid_773722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773724: Call_DisassociateSkillGroupFromRoom_773712; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a skill group from a specified room. This disables all skills in the skill group on all devices in the room.
  ## 
  let valid = call_773724.validator(path, query, header, formData, body)
  let scheme = call_773724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773724.url(scheme.get, call_773724.host, call_773724.base,
                         call_773724.route, valid.getOrDefault("path"))
  result = hook(call_773724, url, valid)

proc call*(call_773725: Call_DisassociateSkillGroupFromRoom_773712; body: JsonNode): Recallable =
  ## disassociateSkillGroupFromRoom
  ## Disassociates a skill group from a specified room. This disables all skills in the skill group on all devices in the room.
  ##   body: JObject (required)
  var body_773726 = newJObject()
  if body != nil:
    body_773726 = body
  result = call_773725.call(nil, nil, nil, nil, body_773726)

var disassociateSkillGroupFromRoom* = Call_DisassociateSkillGroupFromRoom_773712(
    name: "disassociateSkillGroupFromRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillGroupFromRoom",
    validator: validate_DisassociateSkillGroupFromRoom_773713, base: "/",
    url: url_DisassociateSkillGroupFromRoom_773714,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgetSmartHomeAppliances_773727 = ref object of OpenApiRestCall_772597
proc url_ForgetSmartHomeAppliances_773729(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ForgetSmartHomeAppliances_773728(path: JsonNode; query: JsonNode;
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
  var valid_773730 = header.getOrDefault("X-Amz-Date")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "X-Amz-Date", valid_773730
  var valid_773731 = header.getOrDefault("X-Amz-Security-Token")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "X-Amz-Security-Token", valid_773731
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773732 = header.getOrDefault("X-Amz-Target")
  valid_773732 = validateParameter(valid_773732, JString, required = true, default = newJString(
      "AlexaForBusiness.ForgetSmartHomeAppliances"))
  if valid_773732 != nil:
    section.add "X-Amz-Target", valid_773732
  var valid_773733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773733 = validateParameter(valid_773733, JString, required = false,
                                 default = nil)
  if valid_773733 != nil:
    section.add "X-Amz-Content-Sha256", valid_773733
  var valid_773734 = header.getOrDefault("X-Amz-Algorithm")
  valid_773734 = validateParameter(valid_773734, JString, required = false,
                                 default = nil)
  if valid_773734 != nil:
    section.add "X-Amz-Algorithm", valid_773734
  var valid_773735 = header.getOrDefault("X-Amz-Signature")
  valid_773735 = validateParameter(valid_773735, JString, required = false,
                                 default = nil)
  if valid_773735 != nil:
    section.add "X-Amz-Signature", valid_773735
  var valid_773736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773736 = validateParameter(valid_773736, JString, required = false,
                                 default = nil)
  if valid_773736 != nil:
    section.add "X-Amz-SignedHeaders", valid_773736
  var valid_773737 = header.getOrDefault("X-Amz-Credential")
  valid_773737 = validateParameter(valid_773737, JString, required = false,
                                 default = nil)
  if valid_773737 != nil:
    section.add "X-Amz-Credential", valid_773737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773739: Call_ForgetSmartHomeAppliances_773727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Forgets smart home appliances associated to a room.
  ## 
  let valid = call_773739.validator(path, query, header, formData, body)
  let scheme = call_773739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773739.url(scheme.get, call_773739.host, call_773739.base,
                         call_773739.route, valid.getOrDefault("path"))
  result = hook(call_773739, url, valid)

proc call*(call_773740: Call_ForgetSmartHomeAppliances_773727; body: JsonNode): Recallable =
  ## forgetSmartHomeAppliances
  ## Forgets smart home appliances associated to a room.
  ##   body: JObject (required)
  var body_773741 = newJObject()
  if body != nil:
    body_773741 = body
  result = call_773740.call(nil, nil, nil, nil, body_773741)

var forgetSmartHomeAppliances* = Call_ForgetSmartHomeAppliances_773727(
    name: "forgetSmartHomeAppliances", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ForgetSmartHomeAppliances",
    validator: validate_ForgetSmartHomeAppliances_773728, base: "/",
    url: url_ForgetSmartHomeAppliances_773729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddressBook_773742 = ref object of OpenApiRestCall_772597
proc url_GetAddressBook_773744(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddressBook_773743(path: JsonNode; query: JsonNode;
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
  var valid_773745 = header.getOrDefault("X-Amz-Date")
  valid_773745 = validateParameter(valid_773745, JString, required = false,
                                 default = nil)
  if valid_773745 != nil:
    section.add "X-Amz-Date", valid_773745
  var valid_773746 = header.getOrDefault("X-Amz-Security-Token")
  valid_773746 = validateParameter(valid_773746, JString, required = false,
                                 default = nil)
  if valid_773746 != nil:
    section.add "X-Amz-Security-Token", valid_773746
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773747 = header.getOrDefault("X-Amz-Target")
  valid_773747 = validateParameter(valid_773747, JString, required = true, default = newJString(
      "AlexaForBusiness.GetAddressBook"))
  if valid_773747 != nil:
    section.add "X-Amz-Target", valid_773747
  var valid_773748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773748 = validateParameter(valid_773748, JString, required = false,
                                 default = nil)
  if valid_773748 != nil:
    section.add "X-Amz-Content-Sha256", valid_773748
  var valid_773749 = header.getOrDefault("X-Amz-Algorithm")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "X-Amz-Algorithm", valid_773749
  var valid_773750 = header.getOrDefault("X-Amz-Signature")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = nil)
  if valid_773750 != nil:
    section.add "X-Amz-Signature", valid_773750
  var valid_773751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-SignedHeaders", valid_773751
  var valid_773752 = header.getOrDefault("X-Amz-Credential")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "X-Amz-Credential", valid_773752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773754: Call_GetAddressBook_773742; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets address the book details by the address book ARN.
  ## 
  let valid = call_773754.validator(path, query, header, formData, body)
  let scheme = call_773754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773754.url(scheme.get, call_773754.host, call_773754.base,
                         call_773754.route, valid.getOrDefault("path"))
  result = hook(call_773754, url, valid)

proc call*(call_773755: Call_GetAddressBook_773742; body: JsonNode): Recallable =
  ## getAddressBook
  ## Gets address the book details by the address book ARN.
  ##   body: JObject (required)
  var body_773756 = newJObject()
  if body != nil:
    body_773756 = body
  result = call_773755.call(nil, nil, nil, nil, body_773756)

var getAddressBook* = Call_GetAddressBook_773742(name: "getAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetAddressBook",
    validator: validate_GetAddressBook_773743, base: "/", url: url_GetAddressBook_773744,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConferencePreference_773757 = ref object of OpenApiRestCall_772597
proc url_GetConferencePreference_773759(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetConferencePreference_773758(path: JsonNode; query: JsonNode;
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
  var valid_773760 = header.getOrDefault("X-Amz-Date")
  valid_773760 = validateParameter(valid_773760, JString, required = false,
                                 default = nil)
  if valid_773760 != nil:
    section.add "X-Amz-Date", valid_773760
  var valid_773761 = header.getOrDefault("X-Amz-Security-Token")
  valid_773761 = validateParameter(valid_773761, JString, required = false,
                                 default = nil)
  if valid_773761 != nil:
    section.add "X-Amz-Security-Token", valid_773761
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773762 = header.getOrDefault("X-Amz-Target")
  valid_773762 = validateParameter(valid_773762, JString, required = true, default = newJString(
      "AlexaForBusiness.GetConferencePreference"))
  if valid_773762 != nil:
    section.add "X-Amz-Target", valid_773762
  var valid_773763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773763 = validateParameter(valid_773763, JString, required = false,
                                 default = nil)
  if valid_773763 != nil:
    section.add "X-Amz-Content-Sha256", valid_773763
  var valid_773764 = header.getOrDefault("X-Amz-Algorithm")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "X-Amz-Algorithm", valid_773764
  var valid_773765 = header.getOrDefault("X-Amz-Signature")
  valid_773765 = validateParameter(valid_773765, JString, required = false,
                                 default = nil)
  if valid_773765 != nil:
    section.add "X-Amz-Signature", valid_773765
  var valid_773766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "X-Amz-SignedHeaders", valid_773766
  var valid_773767 = header.getOrDefault("X-Amz-Credential")
  valid_773767 = validateParameter(valid_773767, JString, required = false,
                                 default = nil)
  if valid_773767 != nil:
    section.add "X-Amz-Credential", valid_773767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773769: Call_GetConferencePreference_773757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the existing conference preferences.
  ## 
  let valid = call_773769.validator(path, query, header, formData, body)
  let scheme = call_773769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773769.url(scheme.get, call_773769.host, call_773769.base,
                         call_773769.route, valid.getOrDefault("path"))
  result = hook(call_773769, url, valid)

proc call*(call_773770: Call_GetConferencePreference_773757; body: JsonNode): Recallable =
  ## getConferencePreference
  ## Retrieves the existing conference preferences.
  ##   body: JObject (required)
  var body_773771 = newJObject()
  if body != nil:
    body_773771 = body
  result = call_773770.call(nil, nil, nil, nil, body_773771)

var getConferencePreference* = Call_GetConferencePreference_773757(
    name: "getConferencePreference", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetConferencePreference",
    validator: validate_GetConferencePreference_773758, base: "/",
    url: url_GetConferencePreference_773759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConferenceProvider_773772 = ref object of OpenApiRestCall_772597
proc url_GetConferenceProvider_773774(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetConferenceProvider_773773(path: JsonNode; query: JsonNode;
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
  var valid_773775 = header.getOrDefault("X-Amz-Date")
  valid_773775 = validateParameter(valid_773775, JString, required = false,
                                 default = nil)
  if valid_773775 != nil:
    section.add "X-Amz-Date", valid_773775
  var valid_773776 = header.getOrDefault("X-Amz-Security-Token")
  valid_773776 = validateParameter(valid_773776, JString, required = false,
                                 default = nil)
  if valid_773776 != nil:
    section.add "X-Amz-Security-Token", valid_773776
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773777 = header.getOrDefault("X-Amz-Target")
  valid_773777 = validateParameter(valid_773777, JString, required = true, default = newJString(
      "AlexaForBusiness.GetConferenceProvider"))
  if valid_773777 != nil:
    section.add "X-Amz-Target", valid_773777
  var valid_773778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773778 = validateParameter(valid_773778, JString, required = false,
                                 default = nil)
  if valid_773778 != nil:
    section.add "X-Amz-Content-Sha256", valid_773778
  var valid_773779 = header.getOrDefault("X-Amz-Algorithm")
  valid_773779 = validateParameter(valid_773779, JString, required = false,
                                 default = nil)
  if valid_773779 != nil:
    section.add "X-Amz-Algorithm", valid_773779
  var valid_773780 = header.getOrDefault("X-Amz-Signature")
  valid_773780 = validateParameter(valid_773780, JString, required = false,
                                 default = nil)
  if valid_773780 != nil:
    section.add "X-Amz-Signature", valid_773780
  var valid_773781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773781 = validateParameter(valid_773781, JString, required = false,
                                 default = nil)
  if valid_773781 != nil:
    section.add "X-Amz-SignedHeaders", valid_773781
  var valid_773782 = header.getOrDefault("X-Amz-Credential")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "X-Amz-Credential", valid_773782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773784: Call_GetConferenceProvider_773772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a specific conference provider.
  ## 
  let valid = call_773784.validator(path, query, header, formData, body)
  let scheme = call_773784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773784.url(scheme.get, call_773784.host, call_773784.base,
                         call_773784.route, valid.getOrDefault("path"))
  result = hook(call_773784, url, valid)

proc call*(call_773785: Call_GetConferenceProvider_773772; body: JsonNode): Recallable =
  ## getConferenceProvider
  ## Gets details about a specific conference provider.
  ##   body: JObject (required)
  var body_773786 = newJObject()
  if body != nil:
    body_773786 = body
  result = call_773785.call(nil, nil, nil, nil, body_773786)

var getConferenceProvider* = Call_GetConferenceProvider_773772(
    name: "getConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetConferenceProvider",
    validator: validate_GetConferenceProvider_773773, base: "/",
    url: url_GetConferenceProvider_773774, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContact_773787 = ref object of OpenApiRestCall_772597
proc url_GetContact_773789(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetContact_773788(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773790 = header.getOrDefault("X-Amz-Date")
  valid_773790 = validateParameter(valid_773790, JString, required = false,
                                 default = nil)
  if valid_773790 != nil:
    section.add "X-Amz-Date", valid_773790
  var valid_773791 = header.getOrDefault("X-Amz-Security-Token")
  valid_773791 = validateParameter(valid_773791, JString, required = false,
                                 default = nil)
  if valid_773791 != nil:
    section.add "X-Amz-Security-Token", valid_773791
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773792 = header.getOrDefault("X-Amz-Target")
  valid_773792 = validateParameter(valid_773792, JString, required = true, default = newJString(
      "AlexaForBusiness.GetContact"))
  if valid_773792 != nil:
    section.add "X-Amz-Target", valid_773792
  var valid_773793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773793 = validateParameter(valid_773793, JString, required = false,
                                 default = nil)
  if valid_773793 != nil:
    section.add "X-Amz-Content-Sha256", valid_773793
  var valid_773794 = header.getOrDefault("X-Amz-Algorithm")
  valid_773794 = validateParameter(valid_773794, JString, required = false,
                                 default = nil)
  if valid_773794 != nil:
    section.add "X-Amz-Algorithm", valid_773794
  var valid_773795 = header.getOrDefault("X-Amz-Signature")
  valid_773795 = validateParameter(valid_773795, JString, required = false,
                                 default = nil)
  if valid_773795 != nil:
    section.add "X-Amz-Signature", valid_773795
  var valid_773796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773796 = validateParameter(valid_773796, JString, required = false,
                                 default = nil)
  if valid_773796 != nil:
    section.add "X-Amz-SignedHeaders", valid_773796
  var valid_773797 = header.getOrDefault("X-Amz-Credential")
  valid_773797 = validateParameter(valid_773797, JString, required = false,
                                 default = nil)
  if valid_773797 != nil:
    section.add "X-Amz-Credential", valid_773797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773799: Call_GetContact_773787; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contact details by the contact ARN.
  ## 
  let valid = call_773799.validator(path, query, header, formData, body)
  let scheme = call_773799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773799.url(scheme.get, call_773799.host, call_773799.base,
                         call_773799.route, valid.getOrDefault("path"))
  result = hook(call_773799, url, valid)

proc call*(call_773800: Call_GetContact_773787; body: JsonNode): Recallable =
  ## getContact
  ## Gets the contact details by the contact ARN.
  ##   body: JObject (required)
  var body_773801 = newJObject()
  if body != nil:
    body_773801 = body
  result = call_773800.call(nil, nil, nil, nil, body_773801)

var getContact* = Call_GetContact_773787(name: "getContact",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetContact",
                                      validator: validate_GetContact_773788,
                                      base: "/", url: url_GetContact_773789,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_773802 = ref object of OpenApiRestCall_772597
proc url_GetDevice_773804(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDevice_773803(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773805 = header.getOrDefault("X-Amz-Date")
  valid_773805 = validateParameter(valid_773805, JString, required = false,
                                 default = nil)
  if valid_773805 != nil:
    section.add "X-Amz-Date", valid_773805
  var valid_773806 = header.getOrDefault("X-Amz-Security-Token")
  valid_773806 = validateParameter(valid_773806, JString, required = false,
                                 default = nil)
  if valid_773806 != nil:
    section.add "X-Amz-Security-Token", valid_773806
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773807 = header.getOrDefault("X-Amz-Target")
  valid_773807 = validateParameter(valid_773807, JString, required = true, default = newJString(
      "AlexaForBusiness.GetDevice"))
  if valid_773807 != nil:
    section.add "X-Amz-Target", valid_773807
  var valid_773808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773808 = validateParameter(valid_773808, JString, required = false,
                                 default = nil)
  if valid_773808 != nil:
    section.add "X-Amz-Content-Sha256", valid_773808
  var valid_773809 = header.getOrDefault("X-Amz-Algorithm")
  valid_773809 = validateParameter(valid_773809, JString, required = false,
                                 default = nil)
  if valid_773809 != nil:
    section.add "X-Amz-Algorithm", valid_773809
  var valid_773810 = header.getOrDefault("X-Amz-Signature")
  valid_773810 = validateParameter(valid_773810, JString, required = false,
                                 default = nil)
  if valid_773810 != nil:
    section.add "X-Amz-Signature", valid_773810
  var valid_773811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773811 = validateParameter(valid_773811, JString, required = false,
                                 default = nil)
  if valid_773811 != nil:
    section.add "X-Amz-SignedHeaders", valid_773811
  var valid_773812 = header.getOrDefault("X-Amz-Credential")
  valid_773812 = validateParameter(valid_773812, JString, required = false,
                                 default = nil)
  if valid_773812 != nil:
    section.add "X-Amz-Credential", valid_773812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773814: Call_GetDevice_773802; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details of a device by device ARN.
  ## 
  let valid = call_773814.validator(path, query, header, formData, body)
  let scheme = call_773814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773814.url(scheme.get, call_773814.host, call_773814.base,
                         call_773814.route, valid.getOrDefault("path"))
  result = hook(call_773814, url, valid)

proc call*(call_773815: Call_GetDevice_773802; body: JsonNode): Recallable =
  ## getDevice
  ## Gets the details of a device by device ARN.
  ##   body: JObject (required)
  var body_773816 = newJObject()
  if body != nil:
    body_773816 = body
  result = call_773815.call(nil, nil, nil, nil, body_773816)

var getDevice* = Call_GetDevice_773802(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetDevice",
                                    validator: validate_GetDevice_773803,
                                    base: "/", url: url_GetDevice_773804,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGateway_773817 = ref object of OpenApiRestCall_772597
proc url_GetGateway_773819(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGateway_773818(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773820 = header.getOrDefault("X-Amz-Date")
  valid_773820 = validateParameter(valid_773820, JString, required = false,
                                 default = nil)
  if valid_773820 != nil:
    section.add "X-Amz-Date", valid_773820
  var valid_773821 = header.getOrDefault("X-Amz-Security-Token")
  valid_773821 = validateParameter(valid_773821, JString, required = false,
                                 default = nil)
  if valid_773821 != nil:
    section.add "X-Amz-Security-Token", valid_773821
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773822 = header.getOrDefault("X-Amz-Target")
  valid_773822 = validateParameter(valid_773822, JString, required = true, default = newJString(
      "AlexaForBusiness.GetGateway"))
  if valid_773822 != nil:
    section.add "X-Amz-Target", valid_773822
  var valid_773823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773823 = validateParameter(valid_773823, JString, required = false,
                                 default = nil)
  if valid_773823 != nil:
    section.add "X-Amz-Content-Sha256", valid_773823
  var valid_773824 = header.getOrDefault("X-Amz-Algorithm")
  valid_773824 = validateParameter(valid_773824, JString, required = false,
                                 default = nil)
  if valid_773824 != nil:
    section.add "X-Amz-Algorithm", valid_773824
  var valid_773825 = header.getOrDefault("X-Amz-Signature")
  valid_773825 = validateParameter(valid_773825, JString, required = false,
                                 default = nil)
  if valid_773825 != nil:
    section.add "X-Amz-Signature", valid_773825
  var valid_773826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773826 = validateParameter(valid_773826, JString, required = false,
                                 default = nil)
  if valid_773826 != nil:
    section.add "X-Amz-SignedHeaders", valid_773826
  var valid_773827 = header.getOrDefault("X-Amz-Credential")
  valid_773827 = validateParameter(valid_773827, JString, required = false,
                                 default = nil)
  if valid_773827 != nil:
    section.add "X-Amz-Credential", valid_773827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773829: Call_GetGateway_773817; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details of a gateway.
  ## 
  let valid = call_773829.validator(path, query, header, formData, body)
  let scheme = call_773829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773829.url(scheme.get, call_773829.host, call_773829.base,
                         call_773829.route, valid.getOrDefault("path"))
  result = hook(call_773829, url, valid)

proc call*(call_773830: Call_GetGateway_773817; body: JsonNode): Recallable =
  ## getGateway
  ## Retrieves the details of a gateway.
  ##   body: JObject (required)
  var body_773831 = newJObject()
  if body != nil:
    body_773831 = body
  result = call_773830.call(nil, nil, nil, nil, body_773831)

var getGateway* = Call_GetGateway_773817(name: "getGateway",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetGateway",
                                      validator: validate_GetGateway_773818,
                                      base: "/", url: url_GetGateway_773819,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayGroup_773832 = ref object of OpenApiRestCall_772597
proc url_GetGatewayGroup_773834(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGatewayGroup_773833(path: JsonNode; query: JsonNode;
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
  var valid_773835 = header.getOrDefault("X-Amz-Date")
  valid_773835 = validateParameter(valid_773835, JString, required = false,
                                 default = nil)
  if valid_773835 != nil:
    section.add "X-Amz-Date", valid_773835
  var valid_773836 = header.getOrDefault("X-Amz-Security-Token")
  valid_773836 = validateParameter(valid_773836, JString, required = false,
                                 default = nil)
  if valid_773836 != nil:
    section.add "X-Amz-Security-Token", valid_773836
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773837 = header.getOrDefault("X-Amz-Target")
  valid_773837 = validateParameter(valid_773837, JString, required = true, default = newJString(
      "AlexaForBusiness.GetGatewayGroup"))
  if valid_773837 != nil:
    section.add "X-Amz-Target", valid_773837
  var valid_773838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773838 = validateParameter(valid_773838, JString, required = false,
                                 default = nil)
  if valid_773838 != nil:
    section.add "X-Amz-Content-Sha256", valid_773838
  var valid_773839 = header.getOrDefault("X-Amz-Algorithm")
  valid_773839 = validateParameter(valid_773839, JString, required = false,
                                 default = nil)
  if valid_773839 != nil:
    section.add "X-Amz-Algorithm", valid_773839
  var valid_773840 = header.getOrDefault("X-Amz-Signature")
  valid_773840 = validateParameter(valid_773840, JString, required = false,
                                 default = nil)
  if valid_773840 != nil:
    section.add "X-Amz-Signature", valid_773840
  var valid_773841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773841 = validateParameter(valid_773841, JString, required = false,
                                 default = nil)
  if valid_773841 != nil:
    section.add "X-Amz-SignedHeaders", valid_773841
  var valid_773842 = header.getOrDefault("X-Amz-Credential")
  valid_773842 = validateParameter(valid_773842, JString, required = false,
                                 default = nil)
  if valid_773842 != nil:
    section.add "X-Amz-Credential", valid_773842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773844: Call_GetGatewayGroup_773832; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details of a gateway group.
  ## 
  let valid = call_773844.validator(path, query, header, formData, body)
  let scheme = call_773844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773844.url(scheme.get, call_773844.host, call_773844.base,
                         call_773844.route, valid.getOrDefault("path"))
  result = hook(call_773844, url, valid)

proc call*(call_773845: Call_GetGatewayGroup_773832; body: JsonNode): Recallable =
  ## getGatewayGroup
  ## Retrieves the details of a gateway group.
  ##   body: JObject (required)
  var body_773846 = newJObject()
  if body != nil:
    body_773846 = body
  result = call_773845.call(nil, nil, nil, nil, body_773846)

var getGatewayGroup* = Call_GetGatewayGroup_773832(name: "getGatewayGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetGatewayGroup",
    validator: validate_GetGatewayGroup_773833, base: "/", url: url_GetGatewayGroup_773834,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationConfiguration_773847 = ref object of OpenApiRestCall_772597
proc url_GetInvitationConfiguration_773849(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetInvitationConfiguration_773848(path: JsonNode; query: JsonNode;
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
  var valid_773850 = header.getOrDefault("X-Amz-Date")
  valid_773850 = validateParameter(valid_773850, JString, required = false,
                                 default = nil)
  if valid_773850 != nil:
    section.add "X-Amz-Date", valid_773850
  var valid_773851 = header.getOrDefault("X-Amz-Security-Token")
  valid_773851 = validateParameter(valid_773851, JString, required = false,
                                 default = nil)
  if valid_773851 != nil:
    section.add "X-Amz-Security-Token", valid_773851
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773852 = header.getOrDefault("X-Amz-Target")
  valid_773852 = validateParameter(valid_773852, JString, required = true, default = newJString(
      "AlexaForBusiness.GetInvitationConfiguration"))
  if valid_773852 != nil:
    section.add "X-Amz-Target", valid_773852
  var valid_773853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773853 = validateParameter(valid_773853, JString, required = false,
                                 default = nil)
  if valid_773853 != nil:
    section.add "X-Amz-Content-Sha256", valid_773853
  var valid_773854 = header.getOrDefault("X-Amz-Algorithm")
  valid_773854 = validateParameter(valid_773854, JString, required = false,
                                 default = nil)
  if valid_773854 != nil:
    section.add "X-Amz-Algorithm", valid_773854
  var valid_773855 = header.getOrDefault("X-Amz-Signature")
  valid_773855 = validateParameter(valid_773855, JString, required = false,
                                 default = nil)
  if valid_773855 != nil:
    section.add "X-Amz-Signature", valid_773855
  var valid_773856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773856 = validateParameter(valid_773856, JString, required = false,
                                 default = nil)
  if valid_773856 != nil:
    section.add "X-Amz-SignedHeaders", valid_773856
  var valid_773857 = header.getOrDefault("X-Amz-Credential")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "X-Amz-Credential", valid_773857
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773859: Call_GetInvitationConfiguration_773847; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the configured values for the user enrollment invitation email template.
  ## 
  let valid = call_773859.validator(path, query, header, formData, body)
  let scheme = call_773859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773859.url(scheme.get, call_773859.host, call_773859.base,
                         call_773859.route, valid.getOrDefault("path"))
  result = hook(call_773859, url, valid)

proc call*(call_773860: Call_GetInvitationConfiguration_773847; body: JsonNode): Recallable =
  ## getInvitationConfiguration
  ## Retrieves the configured values for the user enrollment invitation email template.
  ##   body: JObject (required)
  var body_773861 = newJObject()
  if body != nil:
    body_773861 = body
  result = call_773860.call(nil, nil, nil, nil, body_773861)

var getInvitationConfiguration* = Call_GetInvitationConfiguration_773847(
    name: "getInvitationConfiguration", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetInvitationConfiguration",
    validator: validate_GetInvitationConfiguration_773848, base: "/",
    url: url_GetInvitationConfiguration_773849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_773862 = ref object of OpenApiRestCall_772597
proc url_GetNetworkProfile_773864(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetNetworkProfile_773863(path: JsonNode; query: JsonNode;
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
  var valid_773865 = header.getOrDefault("X-Amz-Date")
  valid_773865 = validateParameter(valid_773865, JString, required = false,
                                 default = nil)
  if valid_773865 != nil:
    section.add "X-Amz-Date", valid_773865
  var valid_773866 = header.getOrDefault("X-Amz-Security-Token")
  valid_773866 = validateParameter(valid_773866, JString, required = false,
                                 default = nil)
  if valid_773866 != nil:
    section.add "X-Amz-Security-Token", valid_773866
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773867 = header.getOrDefault("X-Amz-Target")
  valid_773867 = validateParameter(valid_773867, JString, required = true, default = newJString(
      "AlexaForBusiness.GetNetworkProfile"))
  if valid_773867 != nil:
    section.add "X-Amz-Target", valid_773867
  var valid_773868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773868 = validateParameter(valid_773868, JString, required = false,
                                 default = nil)
  if valid_773868 != nil:
    section.add "X-Amz-Content-Sha256", valid_773868
  var valid_773869 = header.getOrDefault("X-Amz-Algorithm")
  valid_773869 = validateParameter(valid_773869, JString, required = false,
                                 default = nil)
  if valid_773869 != nil:
    section.add "X-Amz-Algorithm", valid_773869
  var valid_773870 = header.getOrDefault("X-Amz-Signature")
  valid_773870 = validateParameter(valid_773870, JString, required = false,
                                 default = nil)
  if valid_773870 != nil:
    section.add "X-Amz-Signature", valid_773870
  var valid_773871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773871 = validateParameter(valid_773871, JString, required = false,
                                 default = nil)
  if valid_773871 != nil:
    section.add "X-Amz-SignedHeaders", valid_773871
  var valid_773872 = header.getOrDefault("X-Amz-Credential")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = nil)
  if valid_773872 != nil:
    section.add "X-Amz-Credential", valid_773872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773874: Call_GetNetworkProfile_773862; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the network profile details by the network profile ARN.
  ## 
  let valid = call_773874.validator(path, query, header, formData, body)
  let scheme = call_773874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773874.url(scheme.get, call_773874.host, call_773874.base,
                         call_773874.route, valid.getOrDefault("path"))
  result = hook(call_773874, url, valid)

proc call*(call_773875: Call_GetNetworkProfile_773862; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Gets the network profile details by the network profile ARN.
  ##   body: JObject (required)
  var body_773876 = newJObject()
  if body != nil:
    body_773876 = body
  result = call_773875.call(nil, nil, nil, nil, body_773876)

var getNetworkProfile* = Call_GetNetworkProfile_773862(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetNetworkProfile",
    validator: validate_GetNetworkProfile_773863, base: "/",
    url: url_GetNetworkProfile_773864, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProfile_773877 = ref object of OpenApiRestCall_772597
proc url_GetProfile_773879(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetProfile_773878(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773880 = header.getOrDefault("X-Amz-Date")
  valid_773880 = validateParameter(valid_773880, JString, required = false,
                                 default = nil)
  if valid_773880 != nil:
    section.add "X-Amz-Date", valid_773880
  var valid_773881 = header.getOrDefault("X-Amz-Security-Token")
  valid_773881 = validateParameter(valid_773881, JString, required = false,
                                 default = nil)
  if valid_773881 != nil:
    section.add "X-Amz-Security-Token", valid_773881
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773882 = header.getOrDefault("X-Amz-Target")
  valid_773882 = validateParameter(valid_773882, JString, required = true, default = newJString(
      "AlexaForBusiness.GetProfile"))
  if valid_773882 != nil:
    section.add "X-Amz-Target", valid_773882
  var valid_773883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773883 = validateParameter(valid_773883, JString, required = false,
                                 default = nil)
  if valid_773883 != nil:
    section.add "X-Amz-Content-Sha256", valid_773883
  var valid_773884 = header.getOrDefault("X-Amz-Algorithm")
  valid_773884 = validateParameter(valid_773884, JString, required = false,
                                 default = nil)
  if valid_773884 != nil:
    section.add "X-Amz-Algorithm", valid_773884
  var valid_773885 = header.getOrDefault("X-Amz-Signature")
  valid_773885 = validateParameter(valid_773885, JString, required = false,
                                 default = nil)
  if valid_773885 != nil:
    section.add "X-Amz-Signature", valid_773885
  var valid_773886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773886 = validateParameter(valid_773886, JString, required = false,
                                 default = nil)
  if valid_773886 != nil:
    section.add "X-Amz-SignedHeaders", valid_773886
  var valid_773887 = header.getOrDefault("X-Amz-Credential")
  valid_773887 = validateParameter(valid_773887, JString, required = false,
                                 default = nil)
  if valid_773887 != nil:
    section.add "X-Amz-Credential", valid_773887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773889: Call_GetProfile_773877; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details of a room profile by profile ARN.
  ## 
  let valid = call_773889.validator(path, query, header, formData, body)
  let scheme = call_773889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773889.url(scheme.get, call_773889.host, call_773889.base,
                         call_773889.route, valid.getOrDefault("path"))
  result = hook(call_773889, url, valid)

proc call*(call_773890: Call_GetProfile_773877; body: JsonNode): Recallable =
  ## getProfile
  ## Gets the details of a room profile by profile ARN.
  ##   body: JObject (required)
  var body_773891 = newJObject()
  if body != nil:
    body_773891 = body
  result = call_773890.call(nil, nil, nil, nil, body_773891)

var getProfile* = Call_GetProfile_773877(name: "getProfile",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetProfile",
                                      validator: validate_GetProfile_773878,
                                      base: "/", url: url_GetProfile_773879,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoom_773892 = ref object of OpenApiRestCall_772597
proc url_GetRoom_773894(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRoom_773893(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773895 = header.getOrDefault("X-Amz-Date")
  valid_773895 = validateParameter(valid_773895, JString, required = false,
                                 default = nil)
  if valid_773895 != nil:
    section.add "X-Amz-Date", valid_773895
  var valid_773896 = header.getOrDefault("X-Amz-Security-Token")
  valid_773896 = validateParameter(valid_773896, JString, required = false,
                                 default = nil)
  if valid_773896 != nil:
    section.add "X-Amz-Security-Token", valid_773896
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773897 = header.getOrDefault("X-Amz-Target")
  valid_773897 = validateParameter(valid_773897, JString, required = true, default = newJString(
      "AlexaForBusiness.GetRoom"))
  if valid_773897 != nil:
    section.add "X-Amz-Target", valid_773897
  var valid_773898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773898 = validateParameter(valid_773898, JString, required = false,
                                 default = nil)
  if valid_773898 != nil:
    section.add "X-Amz-Content-Sha256", valid_773898
  var valid_773899 = header.getOrDefault("X-Amz-Algorithm")
  valid_773899 = validateParameter(valid_773899, JString, required = false,
                                 default = nil)
  if valid_773899 != nil:
    section.add "X-Amz-Algorithm", valid_773899
  var valid_773900 = header.getOrDefault("X-Amz-Signature")
  valid_773900 = validateParameter(valid_773900, JString, required = false,
                                 default = nil)
  if valid_773900 != nil:
    section.add "X-Amz-Signature", valid_773900
  var valid_773901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773901 = validateParameter(valid_773901, JString, required = false,
                                 default = nil)
  if valid_773901 != nil:
    section.add "X-Amz-SignedHeaders", valid_773901
  var valid_773902 = header.getOrDefault("X-Amz-Credential")
  valid_773902 = validateParameter(valid_773902, JString, required = false,
                                 default = nil)
  if valid_773902 != nil:
    section.add "X-Amz-Credential", valid_773902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773904: Call_GetRoom_773892; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets room details by room ARN.
  ## 
  let valid = call_773904.validator(path, query, header, formData, body)
  let scheme = call_773904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773904.url(scheme.get, call_773904.host, call_773904.base,
                         call_773904.route, valid.getOrDefault("path"))
  result = hook(call_773904, url, valid)

proc call*(call_773905: Call_GetRoom_773892; body: JsonNode): Recallable =
  ## getRoom
  ## Gets room details by room ARN.
  ##   body: JObject (required)
  var body_773906 = newJObject()
  if body != nil:
    body_773906 = body
  result = call_773905.call(nil, nil, nil, nil, body_773906)

var getRoom* = Call_GetRoom_773892(name: "getRoom", meth: HttpMethod.HttpPost,
                                host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetRoom",
                                validator: validate_GetRoom_773893, base: "/",
                                url: url_GetRoom_773894,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoomSkillParameter_773907 = ref object of OpenApiRestCall_772597
proc url_GetRoomSkillParameter_773909(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRoomSkillParameter_773908(path: JsonNode; query: JsonNode;
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
  var valid_773910 = header.getOrDefault("X-Amz-Date")
  valid_773910 = validateParameter(valid_773910, JString, required = false,
                                 default = nil)
  if valid_773910 != nil:
    section.add "X-Amz-Date", valid_773910
  var valid_773911 = header.getOrDefault("X-Amz-Security-Token")
  valid_773911 = validateParameter(valid_773911, JString, required = false,
                                 default = nil)
  if valid_773911 != nil:
    section.add "X-Amz-Security-Token", valid_773911
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773912 = header.getOrDefault("X-Amz-Target")
  valid_773912 = validateParameter(valid_773912, JString, required = true, default = newJString(
      "AlexaForBusiness.GetRoomSkillParameter"))
  if valid_773912 != nil:
    section.add "X-Amz-Target", valid_773912
  var valid_773913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773913 = validateParameter(valid_773913, JString, required = false,
                                 default = nil)
  if valid_773913 != nil:
    section.add "X-Amz-Content-Sha256", valid_773913
  var valid_773914 = header.getOrDefault("X-Amz-Algorithm")
  valid_773914 = validateParameter(valid_773914, JString, required = false,
                                 default = nil)
  if valid_773914 != nil:
    section.add "X-Amz-Algorithm", valid_773914
  var valid_773915 = header.getOrDefault("X-Amz-Signature")
  valid_773915 = validateParameter(valid_773915, JString, required = false,
                                 default = nil)
  if valid_773915 != nil:
    section.add "X-Amz-Signature", valid_773915
  var valid_773916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773916 = validateParameter(valid_773916, JString, required = false,
                                 default = nil)
  if valid_773916 != nil:
    section.add "X-Amz-SignedHeaders", valid_773916
  var valid_773917 = header.getOrDefault("X-Amz-Credential")
  valid_773917 = validateParameter(valid_773917, JString, required = false,
                                 default = nil)
  if valid_773917 != nil:
    section.add "X-Amz-Credential", valid_773917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773919: Call_GetRoomSkillParameter_773907; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets room skill parameter details by room, skill, and parameter key ARN.
  ## 
  let valid = call_773919.validator(path, query, header, formData, body)
  let scheme = call_773919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773919.url(scheme.get, call_773919.host, call_773919.base,
                         call_773919.route, valid.getOrDefault("path"))
  result = hook(call_773919, url, valid)

proc call*(call_773920: Call_GetRoomSkillParameter_773907; body: JsonNode): Recallable =
  ## getRoomSkillParameter
  ## Gets room skill parameter details by room, skill, and parameter key ARN.
  ##   body: JObject (required)
  var body_773921 = newJObject()
  if body != nil:
    body_773921 = body
  result = call_773920.call(nil, nil, nil, nil, body_773921)

var getRoomSkillParameter* = Call_GetRoomSkillParameter_773907(
    name: "getRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetRoomSkillParameter",
    validator: validate_GetRoomSkillParameter_773908, base: "/",
    url: url_GetRoomSkillParameter_773909, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSkillGroup_773922 = ref object of OpenApiRestCall_772597
proc url_GetSkillGroup_773924(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSkillGroup_773923(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773925 = header.getOrDefault("X-Amz-Date")
  valid_773925 = validateParameter(valid_773925, JString, required = false,
                                 default = nil)
  if valid_773925 != nil:
    section.add "X-Amz-Date", valid_773925
  var valid_773926 = header.getOrDefault("X-Amz-Security-Token")
  valid_773926 = validateParameter(valid_773926, JString, required = false,
                                 default = nil)
  if valid_773926 != nil:
    section.add "X-Amz-Security-Token", valid_773926
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773927 = header.getOrDefault("X-Amz-Target")
  valid_773927 = validateParameter(valid_773927, JString, required = true, default = newJString(
      "AlexaForBusiness.GetSkillGroup"))
  if valid_773927 != nil:
    section.add "X-Amz-Target", valid_773927
  var valid_773928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773928 = validateParameter(valid_773928, JString, required = false,
                                 default = nil)
  if valid_773928 != nil:
    section.add "X-Amz-Content-Sha256", valid_773928
  var valid_773929 = header.getOrDefault("X-Amz-Algorithm")
  valid_773929 = validateParameter(valid_773929, JString, required = false,
                                 default = nil)
  if valid_773929 != nil:
    section.add "X-Amz-Algorithm", valid_773929
  var valid_773930 = header.getOrDefault("X-Amz-Signature")
  valid_773930 = validateParameter(valid_773930, JString, required = false,
                                 default = nil)
  if valid_773930 != nil:
    section.add "X-Amz-Signature", valid_773930
  var valid_773931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773931 = validateParameter(valid_773931, JString, required = false,
                                 default = nil)
  if valid_773931 != nil:
    section.add "X-Amz-SignedHeaders", valid_773931
  var valid_773932 = header.getOrDefault("X-Amz-Credential")
  valid_773932 = validateParameter(valid_773932, JString, required = false,
                                 default = nil)
  if valid_773932 != nil:
    section.add "X-Amz-Credential", valid_773932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773934: Call_GetSkillGroup_773922; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets skill group details by skill group ARN.
  ## 
  let valid = call_773934.validator(path, query, header, formData, body)
  let scheme = call_773934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773934.url(scheme.get, call_773934.host, call_773934.base,
                         call_773934.route, valid.getOrDefault("path"))
  result = hook(call_773934, url, valid)

proc call*(call_773935: Call_GetSkillGroup_773922; body: JsonNode): Recallable =
  ## getSkillGroup
  ## Gets skill group details by skill group ARN.
  ##   body: JObject (required)
  var body_773936 = newJObject()
  if body != nil:
    body_773936 = body
  result = call_773935.call(nil, nil, nil, nil, body_773936)

var getSkillGroup* = Call_GetSkillGroup_773922(name: "getSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetSkillGroup",
    validator: validate_GetSkillGroup_773923, base: "/", url: url_GetSkillGroup_773924,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBusinessReportSchedules_773937 = ref object of OpenApiRestCall_772597
proc url_ListBusinessReportSchedules_773939(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListBusinessReportSchedules_773938(path: JsonNode; query: JsonNode;
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
  var valid_773940 = query.getOrDefault("NextToken")
  valid_773940 = validateParameter(valid_773940, JString, required = false,
                                 default = nil)
  if valid_773940 != nil:
    section.add "NextToken", valid_773940
  var valid_773941 = query.getOrDefault("MaxResults")
  valid_773941 = validateParameter(valid_773941, JString, required = false,
                                 default = nil)
  if valid_773941 != nil:
    section.add "MaxResults", valid_773941
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
  var valid_773942 = header.getOrDefault("X-Amz-Date")
  valid_773942 = validateParameter(valid_773942, JString, required = false,
                                 default = nil)
  if valid_773942 != nil:
    section.add "X-Amz-Date", valid_773942
  var valid_773943 = header.getOrDefault("X-Amz-Security-Token")
  valid_773943 = validateParameter(valid_773943, JString, required = false,
                                 default = nil)
  if valid_773943 != nil:
    section.add "X-Amz-Security-Token", valid_773943
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773944 = header.getOrDefault("X-Amz-Target")
  valid_773944 = validateParameter(valid_773944, JString, required = true, default = newJString(
      "AlexaForBusiness.ListBusinessReportSchedules"))
  if valid_773944 != nil:
    section.add "X-Amz-Target", valid_773944
  var valid_773945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773945 = validateParameter(valid_773945, JString, required = false,
                                 default = nil)
  if valid_773945 != nil:
    section.add "X-Amz-Content-Sha256", valid_773945
  var valid_773946 = header.getOrDefault("X-Amz-Algorithm")
  valid_773946 = validateParameter(valid_773946, JString, required = false,
                                 default = nil)
  if valid_773946 != nil:
    section.add "X-Amz-Algorithm", valid_773946
  var valid_773947 = header.getOrDefault("X-Amz-Signature")
  valid_773947 = validateParameter(valid_773947, JString, required = false,
                                 default = nil)
  if valid_773947 != nil:
    section.add "X-Amz-Signature", valid_773947
  var valid_773948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773948 = validateParameter(valid_773948, JString, required = false,
                                 default = nil)
  if valid_773948 != nil:
    section.add "X-Amz-SignedHeaders", valid_773948
  var valid_773949 = header.getOrDefault("X-Amz-Credential")
  valid_773949 = validateParameter(valid_773949, JString, required = false,
                                 default = nil)
  if valid_773949 != nil:
    section.add "X-Amz-Credential", valid_773949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773951: Call_ListBusinessReportSchedules_773937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the details of the schedules that a user configured.
  ## 
  let valid = call_773951.validator(path, query, header, formData, body)
  let scheme = call_773951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773951.url(scheme.get, call_773951.host, call_773951.base,
                         call_773951.route, valid.getOrDefault("path"))
  result = hook(call_773951, url, valid)

proc call*(call_773952: Call_ListBusinessReportSchedules_773937; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listBusinessReportSchedules
  ## Lists the details of the schedules that a user configured.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773953 = newJObject()
  var body_773954 = newJObject()
  add(query_773953, "NextToken", newJString(NextToken))
  if body != nil:
    body_773954 = body
  add(query_773953, "MaxResults", newJString(MaxResults))
  result = call_773952.call(nil, query_773953, nil, nil, body_773954)

var listBusinessReportSchedules* = Call_ListBusinessReportSchedules_773937(
    name: "listBusinessReportSchedules", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListBusinessReportSchedules",
    validator: validate_ListBusinessReportSchedules_773938, base: "/",
    url: url_ListBusinessReportSchedules_773939,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConferenceProviders_773956 = ref object of OpenApiRestCall_772597
proc url_ListConferenceProviders_773958(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListConferenceProviders_773957(path: JsonNode; query: JsonNode;
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
  var valid_773959 = query.getOrDefault("NextToken")
  valid_773959 = validateParameter(valid_773959, JString, required = false,
                                 default = nil)
  if valid_773959 != nil:
    section.add "NextToken", valid_773959
  var valid_773960 = query.getOrDefault("MaxResults")
  valid_773960 = validateParameter(valid_773960, JString, required = false,
                                 default = nil)
  if valid_773960 != nil:
    section.add "MaxResults", valid_773960
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
  var valid_773961 = header.getOrDefault("X-Amz-Date")
  valid_773961 = validateParameter(valid_773961, JString, required = false,
                                 default = nil)
  if valid_773961 != nil:
    section.add "X-Amz-Date", valid_773961
  var valid_773962 = header.getOrDefault("X-Amz-Security-Token")
  valid_773962 = validateParameter(valid_773962, JString, required = false,
                                 default = nil)
  if valid_773962 != nil:
    section.add "X-Amz-Security-Token", valid_773962
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773963 = header.getOrDefault("X-Amz-Target")
  valid_773963 = validateParameter(valid_773963, JString, required = true, default = newJString(
      "AlexaForBusiness.ListConferenceProviders"))
  if valid_773963 != nil:
    section.add "X-Amz-Target", valid_773963
  var valid_773964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773964 = validateParameter(valid_773964, JString, required = false,
                                 default = nil)
  if valid_773964 != nil:
    section.add "X-Amz-Content-Sha256", valid_773964
  var valid_773965 = header.getOrDefault("X-Amz-Algorithm")
  valid_773965 = validateParameter(valid_773965, JString, required = false,
                                 default = nil)
  if valid_773965 != nil:
    section.add "X-Amz-Algorithm", valid_773965
  var valid_773966 = header.getOrDefault("X-Amz-Signature")
  valid_773966 = validateParameter(valid_773966, JString, required = false,
                                 default = nil)
  if valid_773966 != nil:
    section.add "X-Amz-Signature", valid_773966
  var valid_773967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773967 = validateParameter(valid_773967, JString, required = false,
                                 default = nil)
  if valid_773967 != nil:
    section.add "X-Amz-SignedHeaders", valid_773967
  var valid_773968 = header.getOrDefault("X-Amz-Credential")
  valid_773968 = validateParameter(valid_773968, JString, required = false,
                                 default = nil)
  if valid_773968 != nil:
    section.add "X-Amz-Credential", valid_773968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773970: Call_ListConferenceProviders_773956; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists conference providers under a specific AWS account.
  ## 
  let valid = call_773970.validator(path, query, header, formData, body)
  let scheme = call_773970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773970.url(scheme.get, call_773970.host, call_773970.base,
                         call_773970.route, valid.getOrDefault("path"))
  result = hook(call_773970, url, valid)

proc call*(call_773971: Call_ListConferenceProviders_773956; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listConferenceProviders
  ## Lists conference providers under a specific AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773972 = newJObject()
  var body_773973 = newJObject()
  add(query_773972, "NextToken", newJString(NextToken))
  if body != nil:
    body_773973 = body
  add(query_773972, "MaxResults", newJString(MaxResults))
  result = call_773971.call(nil, query_773972, nil, nil, body_773973)

var listConferenceProviders* = Call_ListConferenceProviders_773956(
    name: "listConferenceProviders", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListConferenceProviders",
    validator: validate_ListConferenceProviders_773957, base: "/",
    url: url_ListConferenceProviders_773958, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceEvents_773974 = ref object of OpenApiRestCall_772597
proc url_ListDeviceEvents_773976(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDeviceEvents_773975(path: JsonNode; query: JsonNode;
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
  var valid_773977 = query.getOrDefault("NextToken")
  valid_773977 = validateParameter(valid_773977, JString, required = false,
                                 default = nil)
  if valid_773977 != nil:
    section.add "NextToken", valid_773977
  var valid_773978 = query.getOrDefault("MaxResults")
  valid_773978 = validateParameter(valid_773978, JString, required = false,
                                 default = nil)
  if valid_773978 != nil:
    section.add "MaxResults", valid_773978
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
  var valid_773979 = header.getOrDefault("X-Amz-Date")
  valid_773979 = validateParameter(valid_773979, JString, required = false,
                                 default = nil)
  if valid_773979 != nil:
    section.add "X-Amz-Date", valid_773979
  var valid_773980 = header.getOrDefault("X-Amz-Security-Token")
  valid_773980 = validateParameter(valid_773980, JString, required = false,
                                 default = nil)
  if valid_773980 != nil:
    section.add "X-Amz-Security-Token", valid_773980
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773981 = header.getOrDefault("X-Amz-Target")
  valid_773981 = validateParameter(valid_773981, JString, required = true, default = newJString(
      "AlexaForBusiness.ListDeviceEvents"))
  if valid_773981 != nil:
    section.add "X-Amz-Target", valid_773981
  var valid_773982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773982 = validateParameter(valid_773982, JString, required = false,
                                 default = nil)
  if valid_773982 != nil:
    section.add "X-Amz-Content-Sha256", valid_773982
  var valid_773983 = header.getOrDefault("X-Amz-Algorithm")
  valid_773983 = validateParameter(valid_773983, JString, required = false,
                                 default = nil)
  if valid_773983 != nil:
    section.add "X-Amz-Algorithm", valid_773983
  var valid_773984 = header.getOrDefault("X-Amz-Signature")
  valid_773984 = validateParameter(valid_773984, JString, required = false,
                                 default = nil)
  if valid_773984 != nil:
    section.add "X-Amz-Signature", valid_773984
  var valid_773985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773985 = validateParameter(valid_773985, JString, required = false,
                                 default = nil)
  if valid_773985 != nil:
    section.add "X-Amz-SignedHeaders", valid_773985
  var valid_773986 = header.getOrDefault("X-Amz-Credential")
  valid_773986 = validateParameter(valid_773986, JString, required = false,
                                 default = nil)
  if valid_773986 != nil:
    section.add "X-Amz-Credential", valid_773986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773988: Call_ListDeviceEvents_773974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the device event history, including device connection status, for up to 30 days.
  ## 
  let valid = call_773988.validator(path, query, header, formData, body)
  let scheme = call_773988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773988.url(scheme.get, call_773988.host, call_773988.base,
                         call_773988.route, valid.getOrDefault("path"))
  result = hook(call_773988, url, valid)

proc call*(call_773989: Call_ListDeviceEvents_773974; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDeviceEvents
  ## Lists the device event history, including device connection status, for up to 30 days.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773990 = newJObject()
  var body_773991 = newJObject()
  add(query_773990, "NextToken", newJString(NextToken))
  if body != nil:
    body_773991 = body
  add(query_773990, "MaxResults", newJString(MaxResults))
  result = call_773989.call(nil, query_773990, nil, nil, body_773991)

var listDeviceEvents* = Call_ListDeviceEvents_773974(name: "listDeviceEvents",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListDeviceEvents",
    validator: validate_ListDeviceEvents_773975, base: "/",
    url: url_ListDeviceEvents_773976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGatewayGroups_773992 = ref object of OpenApiRestCall_772597
proc url_ListGatewayGroups_773994(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListGatewayGroups_773993(path: JsonNode; query: JsonNode;
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
  var valid_773995 = query.getOrDefault("NextToken")
  valid_773995 = validateParameter(valid_773995, JString, required = false,
                                 default = nil)
  if valid_773995 != nil:
    section.add "NextToken", valid_773995
  var valid_773996 = query.getOrDefault("MaxResults")
  valid_773996 = validateParameter(valid_773996, JString, required = false,
                                 default = nil)
  if valid_773996 != nil:
    section.add "MaxResults", valid_773996
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
  var valid_773997 = header.getOrDefault("X-Amz-Date")
  valid_773997 = validateParameter(valid_773997, JString, required = false,
                                 default = nil)
  if valid_773997 != nil:
    section.add "X-Amz-Date", valid_773997
  var valid_773998 = header.getOrDefault("X-Amz-Security-Token")
  valid_773998 = validateParameter(valid_773998, JString, required = false,
                                 default = nil)
  if valid_773998 != nil:
    section.add "X-Amz-Security-Token", valid_773998
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773999 = header.getOrDefault("X-Amz-Target")
  valid_773999 = validateParameter(valid_773999, JString, required = true, default = newJString(
      "AlexaForBusiness.ListGatewayGroups"))
  if valid_773999 != nil:
    section.add "X-Amz-Target", valid_773999
  var valid_774000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774000 = validateParameter(valid_774000, JString, required = false,
                                 default = nil)
  if valid_774000 != nil:
    section.add "X-Amz-Content-Sha256", valid_774000
  var valid_774001 = header.getOrDefault("X-Amz-Algorithm")
  valid_774001 = validateParameter(valid_774001, JString, required = false,
                                 default = nil)
  if valid_774001 != nil:
    section.add "X-Amz-Algorithm", valid_774001
  var valid_774002 = header.getOrDefault("X-Amz-Signature")
  valid_774002 = validateParameter(valid_774002, JString, required = false,
                                 default = nil)
  if valid_774002 != nil:
    section.add "X-Amz-Signature", valid_774002
  var valid_774003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774003 = validateParameter(valid_774003, JString, required = false,
                                 default = nil)
  if valid_774003 != nil:
    section.add "X-Amz-SignedHeaders", valid_774003
  var valid_774004 = header.getOrDefault("X-Amz-Credential")
  valid_774004 = validateParameter(valid_774004, JString, required = false,
                                 default = nil)
  if valid_774004 != nil:
    section.add "X-Amz-Credential", valid_774004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774006: Call_ListGatewayGroups_773992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
  ## 
  let valid = call_774006.validator(path, query, header, formData, body)
  let scheme = call_774006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774006.url(scheme.get, call_774006.host, call_774006.base,
                         call_774006.route, valid.getOrDefault("path"))
  result = hook(call_774006, url, valid)

proc call*(call_774007: Call_ListGatewayGroups_773992; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listGatewayGroups
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774008 = newJObject()
  var body_774009 = newJObject()
  add(query_774008, "NextToken", newJString(NextToken))
  if body != nil:
    body_774009 = body
  add(query_774008, "MaxResults", newJString(MaxResults))
  result = call_774007.call(nil, query_774008, nil, nil, body_774009)

var listGatewayGroups* = Call_ListGatewayGroups_773992(name: "listGatewayGroups",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListGatewayGroups",
    validator: validate_ListGatewayGroups_773993, base: "/",
    url: url_ListGatewayGroups_773994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGateways_774010 = ref object of OpenApiRestCall_772597
proc url_ListGateways_774012(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListGateways_774011(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774013 = query.getOrDefault("NextToken")
  valid_774013 = validateParameter(valid_774013, JString, required = false,
                                 default = nil)
  if valid_774013 != nil:
    section.add "NextToken", valid_774013
  var valid_774014 = query.getOrDefault("MaxResults")
  valid_774014 = validateParameter(valid_774014, JString, required = false,
                                 default = nil)
  if valid_774014 != nil:
    section.add "MaxResults", valid_774014
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
  var valid_774015 = header.getOrDefault("X-Amz-Date")
  valid_774015 = validateParameter(valid_774015, JString, required = false,
                                 default = nil)
  if valid_774015 != nil:
    section.add "X-Amz-Date", valid_774015
  var valid_774016 = header.getOrDefault("X-Amz-Security-Token")
  valid_774016 = validateParameter(valid_774016, JString, required = false,
                                 default = nil)
  if valid_774016 != nil:
    section.add "X-Amz-Security-Token", valid_774016
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774017 = header.getOrDefault("X-Amz-Target")
  valid_774017 = validateParameter(valid_774017, JString, required = true, default = newJString(
      "AlexaForBusiness.ListGateways"))
  if valid_774017 != nil:
    section.add "X-Amz-Target", valid_774017
  var valid_774018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774018 = validateParameter(valid_774018, JString, required = false,
                                 default = nil)
  if valid_774018 != nil:
    section.add "X-Amz-Content-Sha256", valid_774018
  var valid_774019 = header.getOrDefault("X-Amz-Algorithm")
  valid_774019 = validateParameter(valid_774019, JString, required = false,
                                 default = nil)
  if valid_774019 != nil:
    section.add "X-Amz-Algorithm", valid_774019
  var valid_774020 = header.getOrDefault("X-Amz-Signature")
  valid_774020 = validateParameter(valid_774020, JString, required = false,
                                 default = nil)
  if valid_774020 != nil:
    section.add "X-Amz-Signature", valid_774020
  var valid_774021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774021 = validateParameter(valid_774021, JString, required = false,
                                 default = nil)
  if valid_774021 != nil:
    section.add "X-Amz-SignedHeaders", valid_774021
  var valid_774022 = header.getOrDefault("X-Amz-Credential")
  valid_774022 = validateParameter(valid_774022, JString, required = false,
                                 default = nil)
  if valid_774022 != nil:
    section.add "X-Amz-Credential", valid_774022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774024: Call_ListGateways_774010; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
  ## 
  let valid = call_774024.validator(path, query, header, formData, body)
  let scheme = call_774024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774024.url(scheme.get, call_774024.host, call_774024.base,
                         call_774024.route, valid.getOrDefault("path"))
  result = hook(call_774024, url, valid)

proc call*(call_774025: Call_ListGateways_774010; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listGateways
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774026 = newJObject()
  var body_774027 = newJObject()
  add(query_774026, "NextToken", newJString(NextToken))
  if body != nil:
    body_774027 = body
  add(query_774026, "MaxResults", newJString(MaxResults))
  result = call_774025.call(nil, query_774026, nil, nil, body_774027)

var listGateways* = Call_ListGateways_774010(name: "listGateways",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListGateways",
    validator: validate_ListGateways_774011, base: "/", url: url_ListGateways_774012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkills_774028 = ref object of OpenApiRestCall_772597
proc url_ListSkills_774030(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSkills_774029(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774031 = query.getOrDefault("NextToken")
  valid_774031 = validateParameter(valid_774031, JString, required = false,
                                 default = nil)
  if valid_774031 != nil:
    section.add "NextToken", valid_774031
  var valid_774032 = query.getOrDefault("MaxResults")
  valid_774032 = validateParameter(valid_774032, JString, required = false,
                                 default = nil)
  if valid_774032 != nil:
    section.add "MaxResults", valid_774032
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
  var valid_774033 = header.getOrDefault("X-Amz-Date")
  valid_774033 = validateParameter(valid_774033, JString, required = false,
                                 default = nil)
  if valid_774033 != nil:
    section.add "X-Amz-Date", valid_774033
  var valid_774034 = header.getOrDefault("X-Amz-Security-Token")
  valid_774034 = validateParameter(valid_774034, JString, required = false,
                                 default = nil)
  if valid_774034 != nil:
    section.add "X-Amz-Security-Token", valid_774034
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774035 = header.getOrDefault("X-Amz-Target")
  valid_774035 = validateParameter(valid_774035, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkills"))
  if valid_774035 != nil:
    section.add "X-Amz-Target", valid_774035
  var valid_774036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774036 = validateParameter(valid_774036, JString, required = false,
                                 default = nil)
  if valid_774036 != nil:
    section.add "X-Amz-Content-Sha256", valid_774036
  var valid_774037 = header.getOrDefault("X-Amz-Algorithm")
  valid_774037 = validateParameter(valid_774037, JString, required = false,
                                 default = nil)
  if valid_774037 != nil:
    section.add "X-Amz-Algorithm", valid_774037
  var valid_774038 = header.getOrDefault("X-Amz-Signature")
  valid_774038 = validateParameter(valid_774038, JString, required = false,
                                 default = nil)
  if valid_774038 != nil:
    section.add "X-Amz-Signature", valid_774038
  var valid_774039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774039 = validateParameter(valid_774039, JString, required = false,
                                 default = nil)
  if valid_774039 != nil:
    section.add "X-Amz-SignedHeaders", valid_774039
  var valid_774040 = header.getOrDefault("X-Amz-Credential")
  valid_774040 = validateParameter(valid_774040, JString, required = false,
                                 default = nil)
  if valid_774040 != nil:
    section.add "X-Amz-Credential", valid_774040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774042: Call_ListSkills_774028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all enabled skills in a specific skill group.
  ## 
  let valid = call_774042.validator(path, query, header, formData, body)
  let scheme = call_774042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774042.url(scheme.get, call_774042.host, call_774042.base,
                         call_774042.route, valid.getOrDefault("path"))
  result = hook(call_774042, url, valid)

proc call*(call_774043: Call_ListSkills_774028; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSkills
  ## Lists all enabled skills in a specific skill group.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774044 = newJObject()
  var body_774045 = newJObject()
  add(query_774044, "NextToken", newJString(NextToken))
  if body != nil:
    body_774045 = body
  add(query_774044, "MaxResults", newJString(MaxResults))
  result = call_774043.call(nil, query_774044, nil, nil, body_774045)

var listSkills* = Call_ListSkills_774028(name: "listSkills",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ListSkills",
                                      validator: validate_ListSkills_774029,
                                      base: "/", url: url_ListSkills_774030,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkillsStoreCategories_774046 = ref object of OpenApiRestCall_772597
proc url_ListSkillsStoreCategories_774048(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSkillsStoreCategories_774047(path: JsonNode; query: JsonNode;
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
  var valid_774049 = query.getOrDefault("NextToken")
  valid_774049 = validateParameter(valid_774049, JString, required = false,
                                 default = nil)
  if valid_774049 != nil:
    section.add "NextToken", valid_774049
  var valid_774050 = query.getOrDefault("MaxResults")
  valid_774050 = validateParameter(valid_774050, JString, required = false,
                                 default = nil)
  if valid_774050 != nil:
    section.add "MaxResults", valid_774050
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
  var valid_774051 = header.getOrDefault("X-Amz-Date")
  valid_774051 = validateParameter(valid_774051, JString, required = false,
                                 default = nil)
  if valid_774051 != nil:
    section.add "X-Amz-Date", valid_774051
  var valid_774052 = header.getOrDefault("X-Amz-Security-Token")
  valid_774052 = validateParameter(valid_774052, JString, required = false,
                                 default = nil)
  if valid_774052 != nil:
    section.add "X-Amz-Security-Token", valid_774052
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774053 = header.getOrDefault("X-Amz-Target")
  valid_774053 = validateParameter(valid_774053, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkillsStoreCategories"))
  if valid_774053 != nil:
    section.add "X-Amz-Target", valid_774053
  var valid_774054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774054 = validateParameter(valid_774054, JString, required = false,
                                 default = nil)
  if valid_774054 != nil:
    section.add "X-Amz-Content-Sha256", valid_774054
  var valid_774055 = header.getOrDefault("X-Amz-Algorithm")
  valid_774055 = validateParameter(valid_774055, JString, required = false,
                                 default = nil)
  if valid_774055 != nil:
    section.add "X-Amz-Algorithm", valid_774055
  var valid_774056 = header.getOrDefault("X-Amz-Signature")
  valid_774056 = validateParameter(valid_774056, JString, required = false,
                                 default = nil)
  if valid_774056 != nil:
    section.add "X-Amz-Signature", valid_774056
  var valid_774057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774057 = validateParameter(valid_774057, JString, required = false,
                                 default = nil)
  if valid_774057 != nil:
    section.add "X-Amz-SignedHeaders", valid_774057
  var valid_774058 = header.getOrDefault("X-Amz-Credential")
  valid_774058 = validateParameter(valid_774058, JString, required = false,
                                 default = nil)
  if valid_774058 != nil:
    section.add "X-Amz-Credential", valid_774058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774060: Call_ListSkillsStoreCategories_774046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all categories in the Alexa skill store.
  ## 
  let valid = call_774060.validator(path, query, header, formData, body)
  let scheme = call_774060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774060.url(scheme.get, call_774060.host, call_774060.base,
                         call_774060.route, valid.getOrDefault("path"))
  result = hook(call_774060, url, valid)

proc call*(call_774061: Call_ListSkillsStoreCategories_774046; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSkillsStoreCategories
  ## Lists all categories in the Alexa skill store.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774062 = newJObject()
  var body_774063 = newJObject()
  add(query_774062, "NextToken", newJString(NextToken))
  if body != nil:
    body_774063 = body
  add(query_774062, "MaxResults", newJString(MaxResults))
  result = call_774061.call(nil, query_774062, nil, nil, body_774063)

var listSkillsStoreCategories* = Call_ListSkillsStoreCategories_774046(
    name: "listSkillsStoreCategories", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSkillsStoreCategories",
    validator: validate_ListSkillsStoreCategories_774047, base: "/",
    url: url_ListSkillsStoreCategories_774048,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkillsStoreSkillsByCategory_774064 = ref object of OpenApiRestCall_772597
proc url_ListSkillsStoreSkillsByCategory_774066(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSkillsStoreSkillsByCategory_774065(path: JsonNode;
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
  var valid_774067 = query.getOrDefault("NextToken")
  valid_774067 = validateParameter(valid_774067, JString, required = false,
                                 default = nil)
  if valid_774067 != nil:
    section.add "NextToken", valid_774067
  var valid_774068 = query.getOrDefault("MaxResults")
  valid_774068 = validateParameter(valid_774068, JString, required = false,
                                 default = nil)
  if valid_774068 != nil:
    section.add "MaxResults", valid_774068
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
  var valid_774069 = header.getOrDefault("X-Amz-Date")
  valid_774069 = validateParameter(valid_774069, JString, required = false,
                                 default = nil)
  if valid_774069 != nil:
    section.add "X-Amz-Date", valid_774069
  var valid_774070 = header.getOrDefault("X-Amz-Security-Token")
  valid_774070 = validateParameter(valid_774070, JString, required = false,
                                 default = nil)
  if valid_774070 != nil:
    section.add "X-Amz-Security-Token", valid_774070
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774071 = header.getOrDefault("X-Amz-Target")
  valid_774071 = validateParameter(valid_774071, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkillsStoreSkillsByCategory"))
  if valid_774071 != nil:
    section.add "X-Amz-Target", valid_774071
  var valid_774072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774072 = validateParameter(valid_774072, JString, required = false,
                                 default = nil)
  if valid_774072 != nil:
    section.add "X-Amz-Content-Sha256", valid_774072
  var valid_774073 = header.getOrDefault("X-Amz-Algorithm")
  valid_774073 = validateParameter(valid_774073, JString, required = false,
                                 default = nil)
  if valid_774073 != nil:
    section.add "X-Amz-Algorithm", valid_774073
  var valid_774074 = header.getOrDefault("X-Amz-Signature")
  valid_774074 = validateParameter(valid_774074, JString, required = false,
                                 default = nil)
  if valid_774074 != nil:
    section.add "X-Amz-Signature", valid_774074
  var valid_774075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774075 = validateParameter(valid_774075, JString, required = false,
                                 default = nil)
  if valid_774075 != nil:
    section.add "X-Amz-SignedHeaders", valid_774075
  var valid_774076 = header.getOrDefault("X-Amz-Credential")
  valid_774076 = validateParameter(valid_774076, JString, required = false,
                                 default = nil)
  if valid_774076 != nil:
    section.add "X-Amz-Credential", valid_774076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774078: Call_ListSkillsStoreSkillsByCategory_774064;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all skills in the Alexa skill store by category.
  ## 
  let valid = call_774078.validator(path, query, header, formData, body)
  let scheme = call_774078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774078.url(scheme.get, call_774078.host, call_774078.base,
                         call_774078.route, valid.getOrDefault("path"))
  result = hook(call_774078, url, valid)

proc call*(call_774079: Call_ListSkillsStoreSkillsByCategory_774064;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSkillsStoreSkillsByCategory
  ## Lists all skills in the Alexa skill store by category.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774080 = newJObject()
  var body_774081 = newJObject()
  add(query_774080, "NextToken", newJString(NextToken))
  if body != nil:
    body_774081 = body
  add(query_774080, "MaxResults", newJString(MaxResults))
  result = call_774079.call(nil, query_774080, nil, nil, body_774081)

var listSkillsStoreSkillsByCategory* = Call_ListSkillsStoreSkillsByCategory_774064(
    name: "listSkillsStoreSkillsByCategory", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSkillsStoreSkillsByCategory",
    validator: validate_ListSkillsStoreSkillsByCategory_774065, base: "/",
    url: url_ListSkillsStoreSkillsByCategory_774066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSmartHomeAppliances_774082 = ref object of OpenApiRestCall_772597
proc url_ListSmartHomeAppliances_774084(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSmartHomeAppliances_774083(path: JsonNode; query: JsonNode;
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
  var valid_774085 = query.getOrDefault("NextToken")
  valid_774085 = validateParameter(valid_774085, JString, required = false,
                                 default = nil)
  if valid_774085 != nil:
    section.add "NextToken", valid_774085
  var valid_774086 = query.getOrDefault("MaxResults")
  valid_774086 = validateParameter(valid_774086, JString, required = false,
                                 default = nil)
  if valid_774086 != nil:
    section.add "MaxResults", valid_774086
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
  var valid_774087 = header.getOrDefault("X-Amz-Date")
  valid_774087 = validateParameter(valid_774087, JString, required = false,
                                 default = nil)
  if valid_774087 != nil:
    section.add "X-Amz-Date", valid_774087
  var valid_774088 = header.getOrDefault("X-Amz-Security-Token")
  valid_774088 = validateParameter(valid_774088, JString, required = false,
                                 default = nil)
  if valid_774088 != nil:
    section.add "X-Amz-Security-Token", valid_774088
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774089 = header.getOrDefault("X-Amz-Target")
  valid_774089 = validateParameter(valid_774089, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSmartHomeAppliances"))
  if valid_774089 != nil:
    section.add "X-Amz-Target", valid_774089
  var valid_774090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774090 = validateParameter(valid_774090, JString, required = false,
                                 default = nil)
  if valid_774090 != nil:
    section.add "X-Amz-Content-Sha256", valid_774090
  var valid_774091 = header.getOrDefault("X-Amz-Algorithm")
  valid_774091 = validateParameter(valid_774091, JString, required = false,
                                 default = nil)
  if valid_774091 != nil:
    section.add "X-Amz-Algorithm", valid_774091
  var valid_774092 = header.getOrDefault("X-Amz-Signature")
  valid_774092 = validateParameter(valid_774092, JString, required = false,
                                 default = nil)
  if valid_774092 != nil:
    section.add "X-Amz-Signature", valid_774092
  var valid_774093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774093 = validateParameter(valid_774093, JString, required = false,
                                 default = nil)
  if valid_774093 != nil:
    section.add "X-Amz-SignedHeaders", valid_774093
  var valid_774094 = header.getOrDefault("X-Amz-Credential")
  valid_774094 = validateParameter(valid_774094, JString, required = false,
                                 default = nil)
  if valid_774094 != nil:
    section.add "X-Amz-Credential", valid_774094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774096: Call_ListSmartHomeAppliances_774082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all of the smart home appliances associated with a room.
  ## 
  let valid = call_774096.validator(path, query, header, formData, body)
  let scheme = call_774096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774096.url(scheme.get, call_774096.host, call_774096.base,
                         call_774096.route, valid.getOrDefault("path"))
  result = hook(call_774096, url, valid)

proc call*(call_774097: Call_ListSmartHomeAppliances_774082; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSmartHomeAppliances
  ## Lists all of the smart home appliances associated with a room.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774098 = newJObject()
  var body_774099 = newJObject()
  add(query_774098, "NextToken", newJString(NextToken))
  if body != nil:
    body_774099 = body
  add(query_774098, "MaxResults", newJString(MaxResults))
  result = call_774097.call(nil, query_774098, nil, nil, body_774099)

var listSmartHomeAppliances* = Call_ListSmartHomeAppliances_774082(
    name: "listSmartHomeAppliances", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSmartHomeAppliances",
    validator: validate_ListSmartHomeAppliances_774083, base: "/",
    url: url_ListSmartHomeAppliances_774084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_774100 = ref object of OpenApiRestCall_772597
proc url_ListTags_774102(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTags_774101(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774103 = query.getOrDefault("NextToken")
  valid_774103 = validateParameter(valid_774103, JString, required = false,
                                 default = nil)
  if valid_774103 != nil:
    section.add "NextToken", valid_774103
  var valid_774104 = query.getOrDefault("MaxResults")
  valid_774104 = validateParameter(valid_774104, JString, required = false,
                                 default = nil)
  if valid_774104 != nil:
    section.add "MaxResults", valid_774104
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
  var valid_774105 = header.getOrDefault("X-Amz-Date")
  valid_774105 = validateParameter(valid_774105, JString, required = false,
                                 default = nil)
  if valid_774105 != nil:
    section.add "X-Amz-Date", valid_774105
  var valid_774106 = header.getOrDefault("X-Amz-Security-Token")
  valid_774106 = validateParameter(valid_774106, JString, required = false,
                                 default = nil)
  if valid_774106 != nil:
    section.add "X-Amz-Security-Token", valid_774106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774107 = header.getOrDefault("X-Amz-Target")
  valid_774107 = validateParameter(valid_774107, JString, required = true, default = newJString(
      "AlexaForBusiness.ListTags"))
  if valid_774107 != nil:
    section.add "X-Amz-Target", valid_774107
  var valid_774108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774108 = validateParameter(valid_774108, JString, required = false,
                                 default = nil)
  if valid_774108 != nil:
    section.add "X-Amz-Content-Sha256", valid_774108
  var valid_774109 = header.getOrDefault("X-Amz-Algorithm")
  valid_774109 = validateParameter(valid_774109, JString, required = false,
                                 default = nil)
  if valid_774109 != nil:
    section.add "X-Amz-Algorithm", valid_774109
  var valid_774110 = header.getOrDefault("X-Amz-Signature")
  valid_774110 = validateParameter(valid_774110, JString, required = false,
                                 default = nil)
  if valid_774110 != nil:
    section.add "X-Amz-Signature", valid_774110
  var valid_774111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774111 = validateParameter(valid_774111, JString, required = false,
                                 default = nil)
  if valid_774111 != nil:
    section.add "X-Amz-SignedHeaders", valid_774111
  var valid_774112 = header.getOrDefault("X-Amz-Credential")
  valid_774112 = validateParameter(valid_774112, JString, required = false,
                                 default = nil)
  if valid_774112 != nil:
    section.add "X-Amz-Credential", valid_774112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774114: Call_ListTags_774100; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags for the specified resource.
  ## 
  let valid = call_774114.validator(path, query, header, formData, body)
  let scheme = call_774114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774114.url(scheme.get, call_774114.host, call_774114.base,
                         call_774114.route, valid.getOrDefault("path"))
  result = hook(call_774114, url, valid)

proc call*(call_774115: Call_ListTags_774100; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listTags
  ## Lists all tags for the specified resource.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774116 = newJObject()
  var body_774117 = newJObject()
  add(query_774116, "NextToken", newJString(NextToken))
  if body != nil:
    body_774117 = body
  add(query_774116, "MaxResults", newJString(MaxResults))
  result = call_774115.call(nil, query_774116, nil, nil, body_774117)

var listTags* = Call_ListTags_774100(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ListTags",
                                  validator: validate_ListTags_774101, base: "/",
                                  url: url_ListTags_774102,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConferencePreference_774118 = ref object of OpenApiRestCall_772597
proc url_PutConferencePreference_774120(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutConferencePreference_774119(path: JsonNode; query: JsonNode;
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
  var valid_774121 = header.getOrDefault("X-Amz-Date")
  valid_774121 = validateParameter(valid_774121, JString, required = false,
                                 default = nil)
  if valid_774121 != nil:
    section.add "X-Amz-Date", valid_774121
  var valid_774122 = header.getOrDefault("X-Amz-Security-Token")
  valid_774122 = validateParameter(valid_774122, JString, required = false,
                                 default = nil)
  if valid_774122 != nil:
    section.add "X-Amz-Security-Token", valid_774122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774123 = header.getOrDefault("X-Amz-Target")
  valid_774123 = validateParameter(valid_774123, JString, required = true, default = newJString(
      "AlexaForBusiness.PutConferencePreference"))
  if valid_774123 != nil:
    section.add "X-Amz-Target", valid_774123
  var valid_774124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774124 = validateParameter(valid_774124, JString, required = false,
                                 default = nil)
  if valid_774124 != nil:
    section.add "X-Amz-Content-Sha256", valid_774124
  var valid_774125 = header.getOrDefault("X-Amz-Algorithm")
  valid_774125 = validateParameter(valid_774125, JString, required = false,
                                 default = nil)
  if valid_774125 != nil:
    section.add "X-Amz-Algorithm", valid_774125
  var valid_774126 = header.getOrDefault("X-Amz-Signature")
  valid_774126 = validateParameter(valid_774126, JString, required = false,
                                 default = nil)
  if valid_774126 != nil:
    section.add "X-Amz-Signature", valid_774126
  var valid_774127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774127 = validateParameter(valid_774127, JString, required = false,
                                 default = nil)
  if valid_774127 != nil:
    section.add "X-Amz-SignedHeaders", valid_774127
  var valid_774128 = header.getOrDefault("X-Amz-Credential")
  valid_774128 = validateParameter(valid_774128, JString, required = false,
                                 default = nil)
  if valid_774128 != nil:
    section.add "X-Amz-Credential", valid_774128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774130: Call_PutConferencePreference_774118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the conference preferences on a specific conference provider at the account level.
  ## 
  let valid = call_774130.validator(path, query, header, formData, body)
  let scheme = call_774130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774130.url(scheme.get, call_774130.host, call_774130.base,
                         call_774130.route, valid.getOrDefault("path"))
  result = hook(call_774130, url, valid)

proc call*(call_774131: Call_PutConferencePreference_774118; body: JsonNode): Recallable =
  ## putConferencePreference
  ## Sets the conference preferences on a specific conference provider at the account level.
  ##   body: JObject (required)
  var body_774132 = newJObject()
  if body != nil:
    body_774132 = body
  result = call_774131.call(nil, nil, nil, nil, body_774132)

var putConferencePreference* = Call_PutConferencePreference_774118(
    name: "putConferencePreference", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutConferencePreference",
    validator: validate_PutConferencePreference_774119, base: "/",
    url: url_PutConferencePreference_774120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInvitationConfiguration_774133 = ref object of OpenApiRestCall_772597
proc url_PutInvitationConfiguration_774135(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutInvitationConfiguration_774134(path: JsonNode; query: JsonNode;
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
  var valid_774136 = header.getOrDefault("X-Amz-Date")
  valid_774136 = validateParameter(valid_774136, JString, required = false,
                                 default = nil)
  if valid_774136 != nil:
    section.add "X-Amz-Date", valid_774136
  var valid_774137 = header.getOrDefault("X-Amz-Security-Token")
  valid_774137 = validateParameter(valid_774137, JString, required = false,
                                 default = nil)
  if valid_774137 != nil:
    section.add "X-Amz-Security-Token", valid_774137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774138 = header.getOrDefault("X-Amz-Target")
  valid_774138 = validateParameter(valid_774138, JString, required = true, default = newJString(
      "AlexaForBusiness.PutInvitationConfiguration"))
  if valid_774138 != nil:
    section.add "X-Amz-Target", valid_774138
  var valid_774139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774139 = validateParameter(valid_774139, JString, required = false,
                                 default = nil)
  if valid_774139 != nil:
    section.add "X-Amz-Content-Sha256", valid_774139
  var valid_774140 = header.getOrDefault("X-Amz-Algorithm")
  valid_774140 = validateParameter(valid_774140, JString, required = false,
                                 default = nil)
  if valid_774140 != nil:
    section.add "X-Amz-Algorithm", valid_774140
  var valid_774141 = header.getOrDefault("X-Amz-Signature")
  valid_774141 = validateParameter(valid_774141, JString, required = false,
                                 default = nil)
  if valid_774141 != nil:
    section.add "X-Amz-Signature", valid_774141
  var valid_774142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774142 = validateParameter(valid_774142, JString, required = false,
                                 default = nil)
  if valid_774142 != nil:
    section.add "X-Amz-SignedHeaders", valid_774142
  var valid_774143 = header.getOrDefault("X-Amz-Credential")
  valid_774143 = validateParameter(valid_774143, JString, required = false,
                                 default = nil)
  if valid_774143 != nil:
    section.add "X-Amz-Credential", valid_774143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774145: Call_PutInvitationConfiguration_774133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the email template for the user enrollment invitation with the specified attributes.
  ## 
  let valid = call_774145.validator(path, query, header, formData, body)
  let scheme = call_774145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774145.url(scheme.get, call_774145.host, call_774145.base,
                         call_774145.route, valid.getOrDefault("path"))
  result = hook(call_774145, url, valid)

proc call*(call_774146: Call_PutInvitationConfiguration_774133; body: JsonNode): Recallable =
  ## putInvitationConfiguration
  ## Configures the email template for the user enrollment invitation with the specified attributes.
  ##   body: JObject (required)
  var body_774147 = newJObject()
  if body != nil:
    body_774147 = body
  result = call_774146.call(nil, nil, nil, nil, body_774147)

var putInvitationConfiguration* = Call_PutInvitationConfiguration_774133(
    name: "putInvitationConfiguration", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutInvitationConfiguration",
    validator: validate_PutInvitationConfiguration_774134, base: "/",
    url: url_PutInvitationConfiguration_774135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRoomSkillParameter_774148 = ref object of OpenApiRestCall_772597
proc url_PutRoomSkillParameter_774150(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutRoomSkillParameter_774149(path: JsonNode; query: JsonNode;
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
  var valid_774151 = header.getOrDefault("X-Amz-Date")
  valid_774151 = validateParameter(valid_774151, JString, required = false,
                                 default = nil)
  if valid_774151 != nil:
    section.add "X-Amz-Date", valid_774151
  var valid_774152 = header.getOrDefault("X-Amz-Security-Token")
  valid_774152 = validateParameter(valid_774152, JString, required = false,
                                 default = nil)
  if valid_774152 != nil:
    section.add "X-Amz-Security-Token", valid_774152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774153 = header.getOrDefault("X-Amz-Target")
  valid_774153 = validateParameter(valid_774153, JString, required = true, default = newJString(
      "AlexaForBusiness.PutRoomSkillParameter"))
  if valid_774153 != nil:
    section.add "X-Amz-Target", valid_774153
  var valid_774154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774154 = validateParameter(valid_774154, JString, required = false,
                                 default = nil)
  if valid_774154 != nil:
    section.add "X-Amz-Content-Sha256", valid_774154
  var valid_774155 = header.getOrDefault("X-Amz-Algorithm")
  valid_774155 = validateParameter(valid_774155, JString, required = false,
                                 default = nil)
  if valid_774155 != nil:
    section.add "X-Amz-Algorithm", valid_774155
  var valid_774156 = header.getOrDefault("X-Amz-Signature")
  valid_774156 = validateParameter(valid_774156, JString, required = false,
                                 default = nil)
  if valid_774156 != nil:
    section.add "X-Amz-Signature", valid_774156
  var valid_774157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774157 = validateParameter(valid_774157, JString, required = false,
                                 default = nil)
  if valid_774157 != nil:
    section.add "X-Amz-SignedHeaders", valid_774157
  var valid_774158 = header.getOrDefault("X-Amz-Credential")
  valid_774158 = validateParameter(valid_774158, JString, required = false,
                                 default = nil)
  if valid_774158 != nil:
    section.add "X-Amz-Credential", valid_774158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774160: Call_PutRoomSkillParameter_774148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room skill parameter details by room, skill, and parameter key ID. Not all skills have a room skill parameter.
  ## 
  let valid = call_774160.validator(path, query, header, formData, body)
  let scheme = call_774160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774160.url(scheme.get, call_774160.host, call_774160.base,
                         call_774160.route, valid.getOrDefault("path"))
  result = hook(call_774160, url, valid)

proc call*(call_774161: Call_PutRoomSkillParameter_774148; body: JsonNode): Recallable =
  ## putRoomSkillParameter
  ## Updates room skill parameter details by room, skill, and parameter key ID. Not all skills have a room skill parameter.
  ##   body: JObject (required)
  var body_774162 = newJObject()
  if body != nil:
    body_774162 = body
  result = call_774161.call(nil, nil, nil, nil, body_774162)

var putRoomSkillParameter* = Call_PutRoomSkillParameter_774148(
    name: "putRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutRoomSkillParameter",
    validator: validate_PutRoomSkillParameter_774149, base: "/",
    url: url_PutRoomSkillParameter_774150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSkillAuthorization_774163 = ref object of OpenApiRestCall_772597
proc url_PutSkillAuthorization_774165(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutSkillAuthorization_774164(path: JsonNode; query: JsonNode;
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
  var valid_774166 = header.getOrDefault("X-Amz-Date")
  valid_774166 = validateParameter(valid_774166, JString, required = false,
                                 default = nil)
  if valid_774166 != nil:
    section.add "X-Amz-Date", valid_774166
  var valid_774167 = header.getOrDefault("X-Amz-Security-Token")
  valid_774167 = validateParameter(valid_774167, JString, required = false,
                                 default = nil)
  if valid_774167 != nil:
    section.add "X-Amz-Security-Token", valid_774167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774168 = header.getOrDefault("X-Amz-Target")
  valid_774168 = validateParameter(valid_774168, JString, required = true, default = newJString(
      "AlexaForBusiness.PutSkillAuthorization"))
  if valid_774168 != nil:
    section.add "X-Amz-Target", valid_774168
  var valid_774169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774169 = validateParameter(valid_774169, JString, required = false,
                                 default = nil)
  if valid_774169 != nil:
    section.add "X-Amz-Content-Sha256", valid_774169
  var valid_774170 = header.getOrDefault("X-Amz-Algorithm")
  valid_774170 = validateParameter(valid_774170, JString, required = false,
                                 default = nil)
  if valid_774170 != nil:
    section.add "X-Amz-Algorithm", valid_774170
  var valid_774171 = header.getOrDefault("X-Amz-Signature")
  valid_774171 = validateParameter(valid_774171, JString, required = false,
                                 default = nil)
  if valid_774171 != nil:
    section.add "X-Amz-Signature", valid_774171
  var valid_774172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774172 = validateParameter(valid_774172, JString, required = false,
                                 default = nil)
  if valid_774172 != nil:
    section.add "X-Amz-SignedHeaders", valid_774172
  var valid_774173 = header.getOrDefault("X-Amz-Credential")
  valid_774173 = validateParameter(valid_774173, JString, required = false,
                                 default = nil)
  if valid_774173 != nil:
    section.add "X-Amz-Credential", valid_774173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774175: Call_PutSkillAuthorization_774163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Links a user's account to a third-party skill provider. If this API operation is called by an assumed IAM role, the skill being linked must be a private skill. Also, the skill must be owned by the AWS account that assumed the IAM role.
  ## 
  let valid = call_774175.validator(path, query, header, formData, body)
  let scheme = call_774175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774175.url(scheme.get, call_774175.host, call_774175.base,
                         call_774175.route, valid.getOrDefault("path"))
  result = hook(call_774175, url, valid)

proc call*(call_774176: Call_PutSkillAuthorization_774163; body: JsonNode): Recallable =
  ## putSkillAuthorization
  ## Links a user's account to a third-party skill provider. If this API operation is called by an assumed IAM role, the skill being linked must be a private skill. Also, the skill must be owned by the AWS account that assumed the IAM role.
  ##   body: JObject (required)
  var body_774177 = newJObject()
  if body != nil:
    body_774177 = body
  result = call_774176.call(nil, nil, nil, nil, body_774177)

var putSkillAuthorization* = Call_PutSkillAuthorization_774163(
    name: "putSkillAuthorization", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutSkillAuthorization",
    validator: validate_PutSkillAuthorization_774164, base: "/",
    url: url_PutSkillAuthorization_774165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterAVSDevice_774178 = ref object of OpenApiRestCall_772597
proc url_RegisterAVSDevice_774180(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterAVSDevice_774179(path: JsonNode; query: JsonNode;
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
  var valid_774181 = header.getOrDefault("X-Amz-Date")
  valid_774181 = validateParameter(valid_774181, JString, required = false,
                                 default = nil)
  if valid_774181 != nil:
    section.add "X-Amz-Date", valid_774181
  var valid_774182 = header.getOrDefault("X-Amz-Security-Token")
  valid_774182 = validateParameter(valid_774182, JString, required = false,
                                 default = nil)
  if valid_774182 != nil:
    section.add "X-Amz-Security-Token", valid_774182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774183 = header.getOrDefault("X-Amz-Target")
  valid_774183 = validateParameter(valid_774183, JString, required = true, default = newJString(
      "AlexaForBusiness.RegisterAVSDevice"))
  if valid_774183 != nil:
    section.add "X-Amz-Target", valid_774183
  var valid_774184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774184 = validateParameter(valid_774184, JString, required = false,
                                 default = nil)
  if valid_774184 != nil:
    section.add "X-Amz-Content-Sha256", valid_774184
  var valid_774185 = header.getOrDefault("X-Amz-Algorithm")
  valid_774185 = validateParameter(valid_774185, JString, required = false,
                                 default = nil)
  if valid_774185 != nil:
    section.add "X-Amz-Algorithm", valid_774185
  var valid_774186 = header.getOrDefault("X-Amz-Signature")
  valid_774186 = validateParameter(valid_774186, JString, required = false,
                                 default = nil)
  if valid_774186 != nil:
    section.add "X-Amz-Signature", valid_774186
  var valid_774187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774187 = validateParameter(valid_774187, JString, required = false,
                                 default = nil)
  if valid_774187 != nil:
    section.add "X-Amz-SignedHeaders", valid_774187
  var valid_774188 = header.getOrDefault("X-Amz-Credential")
  valid_774188 = validateParameter(valid_774188, JString, required = false,
                                 default = nil)
  if valid_774188 != nil:
    section.add "X-Amz-Credential", valid_774188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774190: Call_RegisterAVSDevice_774178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers an Alexa-enabled device built by an Original Equipment Manufacturer (OEM) using Alexa Voice Service (AVS).
  ## 
  let valid = call_774190.validator(path, query, header, formData, body)
  let scheme = call_774190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774190.url(scheme.get, call_774190.host, call_774190.base,
                         call_774190.route, valid.getOrDefault("path"))
  result = hook(call_774190, url, valid)

proc call*(call_774191: Call_RegisterAVSDevice_774178; body: JsonNode): Recallable =
  ## registerAVSDevice
  ## Registers an Alexa-enabled device built by an Original Equipment Manufacturer (OEM) using Alexa Voice Service (AVS).
  ##   body: JObject (required)
  var body_774192 = newJObject()
  if body != nil:
    body_774192 = body
  result = call_774191.call(nil, nil, nil, nil, body_774192)

var registerAVSDevice* = Call_RegisterAVSDevice_774178(name: "registerAVSDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.RegisterAVSDevice",
    validator: validate_RegisterAVSDevice_774179, base: "/",
    url: url_RegisterAVSDevice_774180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectSkill_774193 = ref object of OpenApiRestCall_772597
proc url_RejectSkill_774195(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RejectSkill_774194(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774196 = header.getOrDefault("X-Amz-Date")
  valid_774196 = validateParameter(valid_774196, JString, required = false,
                                 default = nil)
  if valid_774196 != nil:
    section.add "X-Amz-Date", valid_774196
  var valid_774197 = header.getOrDefault("X-Amz-Security-Token")
  valid_774197 = validateParameter(valid_774197, JString, required = false,
                                 default = nil)
  if valid_774197 != nil:
    section.add "X-Amz-Security-Token", valid_774197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774198 = header.getOrDefault("X-Amz-Target")
  valid_774198 = validateParameter(valid_774198, JString, required = true, default = newJString(
      "AlexaForBusiness.RejectSkill"))
  if valid_774198 != nil:
    section.add "X-Amz-Target", valid_774198
  var valid_774199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774199 = validateParameter(valid_774199, JString, required = false,
                                 default = nil)
  if valid_774199 != nil:
    section.add "X-Amz-Content-Sha256", valid_774199
  var valid_774200 = header.getOrDefault("X-Amz-Algorithm")
  valid_774200 = validateParameter(valid_774200, JString, required = false,
                                 default = nil)
  if valid_774200 != nil:
    section.add "X-Amz-Algorithm", valid_774200
  var valid_774201 = header.getOrDefault("X-Amz-Signature")
  valid_774201 = validateParameter(valid_774201, JString, required = false,
                                 default = nil)
  if valid_774201 != nil:
    section.add "X-Amz-Signature", valid_774201
  var valid_774202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774202 = validateParameter(valid_774202, JString, required = false,
                                 default = nil)
  if valid_774202 != nil:
    section.add "X-Amz-SignedHeaders", valid_774202
  var valid_774203 = header.getOrDefault("X-Amz-Credential")
  valid_774203 = validateParameter(valid_774203, JString, required = false,
                                 default = nil)
  if valid_774203 != nil:
    section.add "X-Amz-Credential", valid_774203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774205: Call_RejectSkill_774193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a skill from the organization under a user's AWS account. If the skill is a private skill, it moves to an AcceptStatus of PENDING. Any private or public skill that is rejected can be added later by calling the ApproveSkill API. 
  ## 
  let valid = call_774205.validator(path, query, header, formData, body)
  let scheme = call_774205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774205.url(scheme.get, call_774205.host, call_774205.base,
                         call_774205.route, valid.getOrDefault("path"))
  result = hook(call_774205, url, valid)

proc call*(call_774206: Call_RejectSkill_774193; body: JsonNode): Recallable =
  ## rejectSkill
  ## Disassociates a skill from the organization under a user's AWS account. If the skill is a private skill, it moves to an AcceptStatus of PENDING. Any private or public skill that is rejected can be added later by calling the ApproveSkill API. 
  ##   body: JObject (required)
  var body_774207 = newJObject()
  if body != nil:
    body_774207 = body
  result = call_774206.call(nil, nil, nil, nil, body_774207)

var rejectSkill* = Call_RejectSkill_774193(name: "rejectSkill",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.RejectSkill",
                                        validator: validate_RejectSkill_774194,
                                        base: "/", url: url_RejectSkill_774195,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResolveRoom_774208 = ref object of OpenApiRestCall_772597
proc url_ResolveRoom_774210(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ResolveRoom_774209(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774211 = header.getOrDefault("X-Amz-Date")
  valid_774211 = validateParameter(valid_774211, JString, required = false,
                                 default = nil)
  if valid_774211 != nil:
    section.add "X-Amz-Date", valid_774211
  var valid_774212 = header.getOrDefault("X-Amz-Security-Token")
  valid_774212 = validateParameter(valid_774212, JString, required = false,
                                 default = nil)
  if valid_774212 != nil:
    section.add "X-Amz-Security-Token", valid_774212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774213 = header.getOrDefault("X-Amz-Target")
  valid_774213 = validateParameter(valid_774213, JString, required = true, default = newJString(
      "AlexaForBusiness.ResolveRoom"))
  if valid_774213 != nil:
    section.add "X-Amz-Target", valid_774213
  var valid_774214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774214 = validateParameter(valid_774214, JString, required = false,
                                 default = nil)
  if valid_774214 != nil:
    section.add "X-Amz-Content-Sha256", valid_774214
  var valid_774215 = header.getOrDefault("X-Amz-Algorithm")
  valid_774215 = validateParameter(valid_774215, JString, required = false,
                                 default = nil)
  if valid_774215 != nil:
    section.add "X-Amz-Algorithm", valid_774215
  var valid_774216 = header.getOrDefault("X-Amz-Signature")
  valid_774216 = validateParameter(valid_774216, JString, required = false,
                                 default = nil)
  if valid_774216 != nil:
    section.add "X-Amz-Signature", valid_774216
  var valid_774217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774217 = validateParameter(valid_774217, JString, required = false,
                                 default = nil)
  if valid_774217 != nil:
    section.add "X-Amz-SignedHeaders", valid_774217
  var valid_774218 = header.getOrDefault("X-Amz-Credential")
  valid_774218 = validateParameter(valid_774218, JString, required = false,
                                 default = nil)
  if valid_774218 != nil:
    section.add "X-Amz-Credential", valid_774218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774220: Call_ResolveRoom_774208; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Determines the details for the room from which a skill request was invoked. This operation is used by skill developers.
  ## 
  let valid = call_774220.validator(path, query, header, formData, body)
  let scheme = call_774220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774220.url(scheme.get, call_774220.host, call_774220.base,
                         call_774220.route, valid.getOrDefault("path"))
  result = hook(call_774220, url, valid)

proc call*(call_774221: Call_ResolveRoom_774208; body: JsonNode): Recallable =
  ## resolveRoom
  ## Determines the details for the room from which a skill request was invoked. This operation is used by skill developers.
  ##   body: JObject (required)
  var body_774222 = newJObject()
  if body != nil:
    body_774222 = body
  result = call_774221.call(nil, nil, nil, nil, body_774222)

var resolveRoom* = Call_ResolveRoom_774208(name: "resolveRoom",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ResolveRoom",
                                        validator: validate_ResolveRoom_774209,
                                        base: "/", url: url_ResolveRoom_774210,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeInvitation_774223 = ref object of OpenApiRestCall_772597
proc url_RevokeInvitation_774225(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RevokeInvitation_774224(path: JsonNode; query: JsonNode;
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
  var valid_774226 = header.getOrDefault("X-Amz-Date")
  valid_774226 = validateParameter(valid_774226, JString, required = false,
                                 default = nil)
  if valid_774226 != nil:
    section.add "X-Amz-Date", valid_774226
  var valid_774227 = header.getOrDefault("X-Amz-Security-Token")
  valid_774227 = validateParameter(valid_774227, JString, required = false,
                                 default = nil)
  if valid_774227 != nil:
    section.add "X-Amz-Security-Token", valid_774227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774228 = header.getOrDefault("X-Amz-Target")
  valid_774228 = validateParameter(valid_774228, JString, required = true, default = newJString(
      "AlexaForBusiness.RevokeInvitation"))
  if valid_774228 != nil:
    section.add "X-Amz-Target", valid_774228
  var valid_774229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774229 = validateParameter(valid_774229, JString, required = false,
                                 default = nil)
  if valid_774229 != nil:
    section.add "X-Amz-Content-Sha256", valid_774229
  var valid_774230 = header.getOrDefault("X-Amz-Algorithm")
  valid_774230 = validateParameter(valid_774230, JString, required = false,
                                 default = nil)
  if valid_774230 != nil:
    section.add "X-Amz-Algorithm", valid_774230
  var valid_774231 = header.getOrDefault("X-Amz-Signature")
  valid_774231 = validateParameter(valid_774231, JString, required = false,
                                 default = nil)
  if valid_774231 != nil:
    section.add "X-Amz-Signature", valid_774231
  var valid_774232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774232 = validateParameter(valid_774232, JString, required = false,
                                 default = nil)
  if valid_774232 != nil:
    section.add "X-Amz-SignedHeaders", valid_774232
  var valid_774233 = header.getOrDefault("X-Amz-Credential")
  valid_774233 = validateParameter(valid_774233, JString, required = false,
                                 default = nil)
  if valid_774233 != nil:
    section.add "X-Amz-Credential", valid_774233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774235: Call_RevokeInvitation_774223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes an invitation and invalidates the enrollment URL.
  ## 
  let valid = call_774235.validator(path, query, header, formData, body)
  let scheme = call_774235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774235.url(scheme.get, call_774235.host, call_774235.base,
                         call_774235.route, valid.getOrDefault("path"))
  result = hook(call_774235, url, valid)

proc call*(call_774236: Call_RevokeInvitation_774223; body: JsonNode): Recallable =
  ## revokeInvitation
  ## Revokes an invitation and invalidates the enrollment URL.
  ##   body: JObject (required)
  var body_774237 = newJObject()
  if body != nil:
    body_774237 = body
  result = call_774236.call(nil, nil, nil, nil, body_774237)

var revokeInvitation* = Call_RevokeInvitation_774223(name: "revokeInvitation",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.RevokeInvitation",
    validator: validate_RevokeInvitation_774224, base: "/",
    url: url_RevokeInvitation_774225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAddressBooks_774238 = ref object of OpenApiRestCall_772597
proc url_SearchAddressBooks_774240(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchAddressBooks_774239(path: JsonNode; query: JsonNode;
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
  var valid_774241 = query.getOrDefault("NextToken")
  valid_774241 = validateParameter(valid_774241, JString, required = false,
                                 default = nil)
  if valid_774241 != nil:
    section.add "NextToken", valid_774241
  var valid_774242 = query.getOrDefault("MaxResults")
  valid_774242 = validateParameter(valid_774242, JString, required = false,
                                 default = nil)
  if valid_774242 != nil:
    section.add "MaxResults", valid_774242
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
  var valid_774243 = header.getOrDefault("X-Amz-Date")
  valid_774243 = validateParameter(valid_774243, JString, required = false,
                                 default = nil)
  if valid_774243 != nil:
    section.add "X-Amz-Date", valid_774243
  var valid_774244 = header.getOrDefault("X-Amz-Security-Token")
  valid_774244 = validateParameter(valid_774244, JString, required = false,
                                 default = nil)
  if valid_774244 != nil:
    section.add "X-Amz-Security-Token", valid_774244
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774245 = header.getOrDefault("X-Amz-Target")
  valid_774245 = validateParameter(valid_774245, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchAddressBooks"))
  if valid_774245 != nil:
    section.add "X-Amz-Target", valid_774245
  var valid_774246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774246 = validateParameter(valid_774246, JString, required = false,
                                 default = nil)
  if valid_774246 != nil:
    section.add "X-Amz-Content-Sha256", valid_774246
  var valid_774247 = header.getOrDefault("X-Amz-Algorithm")
  valid_774247 = validateParameter(valid_774247, JString, required = false,
                                 default = nil)
  if valid_774247 != nil:
    section.add "X-Amz-Algorithm", valid_774247
  var valid_774248 = header.getOrDefault("X-Amz-Signature")
  valid_774248 = validateParameter(valid_774248, JString, required = false,
                                 default = nil)
  if valid_774248 != nil:
    section.add "X-Amz-Signature", valid_774248
  var valid_774249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774249 = validateParameter(valid_774249, JString, required = false,
                                 default = nil)
  if valid_774249 != nil:
    section.add "X-Amz-SignedHeaders", valid_774249
  var valid_774250 = header.getOrDefault("X-Amz-Credential")
  valid_774250 = validateParameter(valid_774250, JString, required = false,
                                 default = nil)
  if valid_774250 != nil:
    section.add "X-Amz-Credential", valid_774250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774252: Call_SearchAddressBooks_774238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_774252.validator(path, query, header, formData, body)
  let scheme = call_774252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774252.url(scheme.get, call_774252.host, call_774252.base,
                         call_774252.route, valid.getOrDefault("path"))
  result = hook(call_774252, url, valid)

proc call*(call_774253: Call_SearchAddressBooks_774238; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchAddressBooks
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774254 = newJObject()
  var body_774255 = newJObject()
  add(query_774254, "NextToken", newJString(NextToken))
  if body != nil:
    body_774255 = body
  add(query_774254, "MaxResults", newJString(MaxResults))
  result = call_774253.call(nil, query_774254, nil, nil, body_774255)

var searchAddressBooks* = Call_SearchAddressBooks_774238(
    name: "searchAddressBooks", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchAddressBooks",
    validator: validate_SearchAddressBooks_774239, base: "/",
    url: url_SearchAddressBooks_774240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchContacts_774256 = ref object of OpenApiRestCall_772597
proc url_SearchContacts_774258(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchContacts_774257(path: JsonNode; query: JsonNode;
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
  var valid_774259 = query.getOrDefault("NextToken")
  valid_774259 = validateParameter(valid_774259, JString, required = false,
                                 default = nil)
  if valid_774259 != nil:
    section.add "NextToken", valid_774259
  var valid_774260 = query.getOrDefault("MaxResults")
  valid_774260 = validateParameter(valid_774260, JString, required = false,
                                 default = nil)
  if valid_774260 != nil:
    section.add "MaxResults", valid_774260
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
  var valid_774261 = header.getOrDefault("X-Amz-Date")
  valid_774261 = validateParameter(valid_774261, JString, required = false,
                                 default = nil)
  if valid_774261 != nil:
    section.add "X-Amz-Date", valid_774261
  var valid_774262 = header.getOrDefault("X-Amz-Security-Token")
  valid_774262 = validateParameter(valid_774262, JString, required = false,
                                 default = nil)
  if valid_774262 != nil:
    section.add "X-Amz-Security-Token", valid_774262
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774263 = header.getOrDefault("X-Amz-Target")
  valid_774263 = validateParameter(valid_774263, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchContacts"))
  if valid_774263 != nil:
    section.add "X-Amz-Target", valid_774263
  var valid_774264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774264 = validateParameter(valid_774264, JString, required = false,
                                 default = nil)
  if valid_774264 != nil:
    section.add "X-Amz-Content-Sha256", valid_774264
  var valid_774265 = header.getOrDefault("X-Amz-Algorithm")
  valid_774265 = validateParameter(valid_774265, JString, required = false,
                                 default = nil)
  if valid_774265 != nil:
    section.add "X-Amz-Algorithm", valid_774265
  var valid_774266 = header.getOrDefault("X-Amz-Signature")
  valid_774266 = validateParameter(valid_774266, JString, required = false,
                                 default = nil)
  if valid_774266 != nil:
    section.add "X-Amz-Signature", valid_774266
  var valid_774267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774267 = validateParameter(valid_774267, JString, required = false,
                                 default = nil)
  if valid_774267 != nil:
    section.add "X-Amz-SignedHeaders", valid_774267
  var valid_774268 = header.getOrDefault("X-Amz-Credential")
  valid_774268 = validateParameter(valid_774268, JString, required = false,
                                 default = nil)
  if valid_774268 != nil:
    section.add "X-Amz-Credential", valid_774268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774270: Call_SearchContacts_774256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_774270.validator(path, query, header, formData, body)
  let scheme = call_774270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774270.url(scheme.get, call_774270.host, call_774270.base,
                         call_774270.route, valid.getOrDefault("path"))
  result = hook(call_774270, url, valid)

proc call*(call_774271: Call_SearchContacts_774256; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchContacts
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774272 = newJObject()
  var body_774273 = newJObject()
  add(query_774272, "NextToken", newJString(NextToken))
  if body != nil:
    body_774273 = body
  add(query_774272, "MaxResults", newJString(MaxResults))
  result = call_774271.call(nil, query_774272, nil, nil, body_774273)

var searchContacts* = Call_SearchContacts_774256(name: "searchContacts",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchContacts",
    validator: validate_SearchContacts_774257, base: "/", url: url_SearchContacts_774258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchDevices_774274 = ref object of OpenApiRestCall_772597
proc url_SearchDevices_774276(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchDevices_774275(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774277 = query.getOrDefault("NextToken")
  valid_774277 = validateParameter(valid_774277, JString, required = false,
                                 default = nil)
  if valid_774277 != nil:
    section.add "NextToken", valid_774277
  var valid_774278 = query.getOrDefault("MaxResults")
  valid_774278 = validateParameter(valid_774278, JString, required = false,
                                 default = nil)
  if valid_774278 != nil:
    section.add "MaxResults", valid_774278
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
  var valid_774279 = header.getOrDefault("X-Amz-Date")
  valid_774279 = validateParameter(valid_774279, JString, required = false,
                                 default = nil)
  if valid_774279 != nil:
    section.add "X-Amz-Date", valid_774279
  var valid_774280 = header.getOrDefault("X-Amz-Security-Token")
  valid_774280 = validateParameter(valid_774280, JString, required = false,
                                 default = nil)
  if valid_774280 != nil:
    section.add "X-Amz-Security-Token", valid_774280
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774281 = header.getOrDefault("X-Amz-Target")
  valid_774281 = validateParameter(valid_774281, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchDevices"))
  if valid_774281 != nil:
    section.add "X-Amz-Target", valid_774281
  var valid_774282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774282 = validateParameter(valid_774282, JString, required = false,
                                 default = nil)
  if valid_774282 != nil:
    section.add "X-Amz-Content-Sha256", valid_774282
  var valid_774283 = header.getOrDefault("X-Amz-Algorithm")
  valid_774283 = validateParameter(valid_774283, JString, required = false,
                                 default = nil)
  if valid_774283 != nil:
    section.add "X-Amz-Algorithm", valid_774283
  var valid_774284 = header.getOrDefault("X-Amz-Signature")
  valid_774284 = validateParameter(valid_774284, JString, required = false,
                                 default = nil)
  if valid_774284 != nil:
    section.add "X-Amz-Signature", valid_774284
  var valid_774285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774285 = validateParameter(valid_774285, JString, required = false,
                                 default = nil)
  if valid_774285 != nil:
    section.add "X-Amz-SignedHeaders", valid_774285
  var valid_774286 = header.getOrDefault("X-Amz-Credential")
  valid_774286 = validateParameter(valid_774286, JString, required = false,
                                 default = nil)
  if valid_774286 != nil:
    section.add "X-Amz-Credential", valid_774286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774288: Call_SearchDevices_774274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches devices and lists the ones that meet a set of filter criteria.
  ## 
  let valid = call_774288.validator(path, query, header, formData, body)
  let scheme = call_774288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774288.url(scheme.get, call_774288.host, call_774288.base,
                         call_774288.route, valid.getOrDefault("path"))
  result = hook(call_774288, url, valid)

proc call*(call_774289: Call_SearchDevices_774274; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchDevices
  ## Searches devices and lists the ones that meet a set of filter criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774290 = newJObject()
  var body_774291 = newJObject()
  add(query_774290, "NextToken", newJString(NextToken))
  if body != nil:
    body_774291 = body
  add(query_774290, "MaxResults", newJString(MaxResults))
  result = call_774289.call(nil, query_774290, nil, nil, body_774291)

var searchDevices* = Call_SearchDevices_774274(name: "searchDevices",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchDevices",
    validator: validate_SearchDevices_774275, base: "/", url: url_SearchDevices_774276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchNetworkProfiles_774292 = ref object of OpenApiRestCall_772597
proc url_SearchNetworkProfiles_774294(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchNetworkProfiles_774293(path: JsonNode; query: JsonNode;
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
  var valid_774295 = query.getOrDefault("NextToken")
  valid_774295 = validateParameter(valid_774295, JString, required = false,
                                 default = nil)
  if valid_774295 != nil:
    section.add "NextToken", valid_774295
  var valid_774296 = query.getOrDefault("MaxResults")
  valid_774296 = validateParameter(valid_774296, JString, required = false,
                                 default = nil)
  if valid_774296 != nil:
    section.add "MaxResults", valid_774296
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
  var valid_774297 = header.getOrDefault("X-Amz-Date")
  valid_774297 = validateParameter(valid_774297, JString, required = false,
                                 default = nil)
  if valid_774297 != nil:
    section.add "X-Amz-Date", valid_774297
  var valid_774298 = header.getOrDefault("X-Amz-Security-Token")
  valid_774298 = validateParameter(valid_774298, JString, required = false,
                                 default = nil)
  if valid_774298 != nil:
    section.add "X-Amz-Security-Token", valid_774298
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774299 = header.getOrDefault("X-Amz-Target")
  valid_774299 = validateParameter(valid_774299, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchNetworkProfiles"))
  if valid_774299 != nil:
    section.add "X-Amz-Target", valid_774299
  var valid_774300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774300 = validateParameter(valid_774300, JString, required = false,
                                 default = nil)
  if valid_774300 != nil:
    section.add "X-Amz-Content-Sha256", valid_774300
  var valid_774301 = header.getOrDefault("X-Amz-Algorithm")
  valid_774301 = validateParameter(valid_774301, JString, required = false,
                                 default = nil)
  if valid_774301 != nil:
    section.add "X-Amz-Algorithm", valid_774301
  var valid_774302 = header.getOrDefault("X-Amz-Signature")
  valid_774302 = validateParameter(valid_774302, JString, required = false,
                                 default = nil)
  if valid_774302 != nil:
    section.add "X-Amz-Signature", valid_774302
  var valid_774303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774303 = validateParameter(valid_774303, JString, required = false,
                                 default = nil)
  if valid_774303 != nil:
    section.add "X-Amz-SignedHeaders", valid_774303
  var valid_774304 = header.getOrDefault("X-Amz-Credential")
  valid_774304 = validateParameter(valid_774304, JString, required = false,
                                 default = nil)
  if valid_774304 != nil:
    section.add "X-Amz-Credential", valid_774304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774306: Call_SearchNetworkProfiles_774292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_774306.validator(path, query, header, formData, body)
  let scheme = call_774306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774306.url(scheme.get, call_774306.host, call_774306.base,
                         call_774306.route, valid.getOrDefault("path"))
  result = hook(call_774306, url, valid)

proc call*(call_774307: Call_SearchNetworkProfiles_774292; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchNetworkProfiles
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774308 = newJObject()
  var body_774309 = newJObject()
  add(query_774308, "NextToken", newJString(NextToken))
  if body != nil:
    body_774309 = body
  add(query_774308, "MaxResults", newJString(MaxResults))
  result = call_774307.call(nil, query_774308, nil, nil, body_774309)

var searchNetworkProfiles* = Call_SearchNetworkProfiles_774292(
    name: "searchNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchNetworkProfiles",
    validator: validate_SearchNetworkProfiles_774293, base: "/",
    url: url_SearchNetworkProfiles_774294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProfiles_774310 = ref object of OpenApiRestCall_772597
proc url_SearchProfiles_774312(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchProfiles_774311(path: JsonNode; query: JsonNode;
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
  var valid_774313 = query.getOrDefault("NextToken")
  valid_774313 = validateParameter(valid_774313, JString, required = false,
                                 default = nil)
  if valid_774313 != nil:
    section.add "NextToken", valid_774313
  var valid_774314 = query.getOrDefault("MaxResults")
  valid_774314 = validateParameter(valid_774314, JString, required = false,
                                 default = nil)
  if valid_774314 != nil:
    section.add "MaxResults", valid_774314
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
  var valid_774315 = header.getOrDefault("X-Amz-Date")
  valid_774315 = validateParameter(valid_774315, JString, required = false,
                                 default = nil)
  if valid_774315 != nil:
    section.add "X-Amz-Date", valid_774315
  var valid_774316 = header.getOrDefault("X-Amz-Security-Token")
  valid_774316 = validateParameter(valid_774316, JString, required = false,
                                 default = nil)
  if valid_774316 != nil:
    section.add "X-Amz-Security-Token", valid_774316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774317 = header.getOrDefault("X-Amz-Target")
  valid_774317 = validateParameter(valid_774317, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchProfiles"))
  if valid_774317 != nil:
    section.add "X-Amz-Target", valid_774317
  var valid_774318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774318 = validateParameter(valid_774318, JString, required = false,
                                 default = nil)
  if valid_774318 != nil:
    section.add "X-Amz-Content-Sha256", valid_774318
  var valid_774319 = header.getOrDefault("X-Amz-Algorithm")
  valid_774319 = validateParameter(valid_774319, JString, required = false,
                                 default = nil)
  if valid_774319 != nil:
    section.add "X-Amz-Algorithm", valid_774319
  var valid_774320 = header.getOrDefault("X-Amz-Signature")
  valid_774320 = validateParameter(valid_774320, JString, required = false,
                                 default = nil)
  if valid_774320 != nil:
    section.add "X-Amz-Signature", valid_774320
  var valid_774321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774321 = validateParameter(valid_774321, JString, required = false,
                                 default = nil)
  if valid_774321 != nil:
    section.add "X-Amz-SignedHeaders", valid_774321
  var valid_774322 = header.getOrDefault("X-Amz-Credential")
  valid_774322 = validateParameter(valid_774322, JString, required = false,
                                 default = nil)
  if valid_774322 != nil:
    section.add "X-Amz-Credential", valid_774322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774324: Call_SearchProfiles_774310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
  ## 
  let valid = call_774324.validator(path, query, header, formData, body)
  let scheme = call_774324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774324.url(scheme.get, call_774324.host, call_774324.base,
                         call_774324.route, valid.getOrDefault("path"))
  result = hook(call_774324, url, valid)

proc call*(call_774325: Call_SearchProfiles_774310; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchProfiles
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774326 = newJObject()
  var body_774327 = newJObject()
  add(query_774326, "NextToken", newJString(NextToken))
  if body != nil:
    body_774327 = body
  add(query_774326, "MaxResults", newJString(MaxResults))
  result = call_774325.call(nil, query_774326, nil, nil, body_774327)

var searchProfiles* = Call_SearchProfiles_774310(name: "searchProfiles",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchProfiles",
    validator: validate_SearchProfiles_774311, base: "/", url: url_SearchProfiles_774312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchRooms_774328 = ref object of OpenApiRestCall_772597
proc url_SearchRooms_774330(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchRooms_774329(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774331 = query.getOrDefault("NextToken")
  valid_774331 = validateParameter(valid_774331, JString, required = false,
                                 default = nil)
  if valid_774331 != nil:
    section.add "NextToken", valid_774331
  var valid_774332 = query.getOrDefault("MaxResults")
  valid_774332 = validateParameter(valid_774332, JString, required = false,
                                 default = nil)
  if valid_774332 != nil:
    section.add "MaxResults", valid_774332
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
  var valid_774333 = header.getOrDefault("X-Amz-Date")
  valid_774333 = validateParameter(valid_774333, JString, required = false,
                                 default = nil)
  if valid_774333 != nil:
    section.add "X-Amz-Date", valid_774333
  var valid_774334 = header.getOrDefault("X-Amz-Security-Token")
  valid_774334 = validateParameter(valid_774334, JString, required = false,
                                 default = nil)
  if valid_774334 != nil:
    section.add "X-Amz-Security-Token", valid_774334
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774335 = header.getOrDefault("X-Amz-Target")
  valid_774335 = validateParameter(valid_774335, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchRooms"))
  if valid_774335 != nil:
    section.add "X-Amz-Target", valid_774335
  var valid_774336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774336 = validateParameter(valid_774336, JString, required = false,
                                 default = nil)
  if valid_774336 != nil:
    section.add "X-Amz-Content-Sha256", valid_774336
  var valid_774337 = header.getOrDefault("X-Amz-Algorithm")
  valid_774337 = validateParameter(valid_774337, JString, required = false,
                                 default = nil)
  if valid_774337 != nil:
    section.add "X-Amz-Algorithm", valid_774337
  var valid_774338 = header.getOrDefault("X-Amz-Signature")
  valid_774338 = validateParameter(valid_774338, JString, required = false,
                                 default = nil)
  if valid_774338 != nil:
    section.add "X-Amz-Signature", valid_774338
  var valid_774339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774339 = validateParameter(valid_774339, JString, required = false,
                                 default = nil)
  if valid_774339 != nil:
    section.add "X-Amz-SignedHeaders", valid_774339
  var valid_774340 = header.getOrDefault("X-Amz-Credential")
  valid_774340 = validateParameter(valid_774340, JString, required = false,
                                 default = nil)
  if valid_774340 != nil:
    section.add "X-Amz-Credential", valid_774340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774342: Call_SearchRooms_774328; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_774342.validator(path, query, header, formData, body)
  let scheme = call_774342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774342.url(scheme.get, call_774342.host, call_774342.base,
                         call_774342.route, valid.getOrDefault("path"))
  result = hook(call_774342, url, valid)

proc call*(call_774343: Call_SearchRooms_774328; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchRooms
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774344 = newJObject()
  var body_774345 = newJObject()
  add(query_774344, "NextToken", newJString(NextToken))
  if body != nil:
    body_774345 = body
  add(query_774344, "MaxResults", newJString(MaxResults))
  result = call_774343.call(nil, query_774344, nil, nil, body_774345)

var searchRooms* = Call_SearchRooms_774328(name: "searchRooms",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.SearchRooms",
                                        validator: validate_SearchRooms_774329,
                                        base: "/", url: url_SearchRooms_774330,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSkillGroups_774346 = ref object of OpenApiRestCall_772597
proc url_SearchSkillGroups_774348(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchSkillGroups_774347(path: JsonNode; query: JsonNode;
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
  var valid_774349 = query.getOrDefault("NextToken")
  valid_774349 = validateParameter(valid_774349, JString, required = false,
                                 default = nil)
  if valid_774349 != nil:
    section.add "NextToken", valid_774349
  var valid_774350 = query.getOrDefault("MaxResults")
  valid_774350 = validateParameter(valid_774350, JString, required = false,
                                 default = nil)
  if valid_774350 != nil:
    section.add "MaxResults", valid_774350
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
  var valid_774351 = header.getOrDefault("X-Amz-Date")
  valid_774351 = validateParameter(valid_774351, JString, required = false,
                                 default = nil)
  if valid_774351 != nil:
    section.add "X-Amz-Date", valid_774351
  var valid_774352 = header.getOrDefault("X-Amz-Security-Token")
  valid_774352 = validateParameter(valid_774352, JString, required = false,
                                 default = nil)
  if valid_774352 != nil:
    section.add "X-Amz-Security-Token", valid_774352
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774353 = header.getOrDefault("X-Amz-Target")
  valid_774353 = validateParameter(valid_774353, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchSkillGroups"))
  if valid_774353 != nil:
    section.add "X-Amz-Target", valid_774353
  var valid_774354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774354 = validateParameter(valid_774354, JString, required = false,
                                 default = nil)
  if valid_774354 != nil:
    section.add "X-Amz-Content-Sha256", valid_774354
  var valid_774355 = header.getOrDefault("X-Amz-Algorithm")
  valid_774355 = validateParameter(valid_774355, JString, required = false,
                                 default = nil)
  if valid_774355 != nil:
    section.add "X-Amz-Algorithm", valid_774355
  var valid_774356 = header.getOrDefault("X-Amz-Signature")
  valid_774356 = validateParameter(valid_774356, JString, required = false,
                                 default = nil)
  if valid_774356 != nil:
    section.add "X-Amz-Signature", valid_774356
  var valid_774357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774357 = validateParameter(valid_774357, JString, required = false,
                                 default = nil)
  if valid_774357 != nil:
    section.add "X-Amz-SignedHeaders", valid_774357
  var valid_774358 = header.getOrDefault("X-Amz-Credential")
  valid_774358 = validateParameter(valid_774358, JString, required = false,
                                 default = nil)
  if valid_774358 != nil:
    section.add "X-Amz-Credential", valid_774358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774360: Call_SearchSkillGroups_774346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_774360.validator(path, query, header, formData, body)
  let scheme = call_774360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774360.url(scheme.get, call_774360.host, call_774360.base,
                         call_774360.route, valid.getOrDefault("path"))
  result = hook(call_774360, url, valid)

proc call*(call_774361: Call_SearchSkillGroups_774346; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchSkillGroups
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774362 = newJObject()
  var body_774363 = newJObject()
  add(query_774362, "NextToken", newJString(NextToken))
  if body != nil:
    body_774363 = body
  add(query_774362, "MaxResults", newJString(MaxResults))
  result = call_774361.call(nil, query_774362, nil, nil, body_774363)

var searchSkillGroups* = Call_SearchSkillGroups_774346(name: "searchSkillGroups",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchSkillGroups",
    validator: validate_SearchSkillGroups_774347, base: "/",
    url: url_SearchSkillGroups_774348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchUsers_774364 = ref object of OpenApiRestCall_772597
proc url_SearchUsers_774366(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchUsers_774365(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774367 = query.getOrDefault("NextToken")
  valid_774367 = validateParameter(valid_774367, JString, required = false,
                                 default = nil)
  if valid_774367 != nil:
    section.add "NextToken", valid_774367
  var valid_774368 = query.getOrDefault("MaxResults")
  valid_774368 = validateParameter(valid_774368, JString, required = false,
                                 default = nil)
  if valid_774368 != nil:
    section.add "MaxResults", valid_774368
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
  var valid_774369 = header.getOrDefault("X-Amz-Date")
  valid_774369 = validateParameter(valid_774369, JString, required = false,
                                 default = nil)
  if valid_774369 != nil:
    section.add "X-Amz-Date", valid_774369
  var valid_774370 = header.getOrDefault("X-Amz-Security-Token")
  valid_774370 = validateParameter(valid_774370, JString, required = false,
                                 default = nil)
  if valid_774370 != nil:
    section.add "X-Amz-Security-Token", valid_774370
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774371 = header.getOrDefault("X-Amz-Target")
  valid_774371 = validateParameter(valid_774371, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchUsers"))
  if valid_774371 != nil:
    section.add "X-Amz-Target", valid_774371
  var valid_774372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774372 = validateParameter(valid_774372, JString, required = false,
                                 default = nil)
  if valid_774372 != nil:
    section.add "X-Amz-Content-Sha256", valid_774372
  var valid_774373 = header.getOrDefault("X-Amz-Algorithm")
  valid_774373 = validateParameter(valid_774373, JString, required = false,
                                 default = nil)
  if valid_774373 != nil:
    section.add "X-Amz-Algorithm", valid_774373
  var valid_774374 = header.getOrDefault("X-Amz-Signature")
  valid_774374 = validateParameter(valid_774374, JString, required = false,
                                 default = nil)
  if valid_774374 != nil:
    section.add "X-Amz-Signature", valid_774374
  var valid_774375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774375 = validateParameter(valid_774375, JString, required = false,
                                 default = nil)
  if valid_774375 != nil:
    section.add "X-Amz-SignedHeaders", valid_774375
  var valid_774376 = header.getOrDefault("X-Amz-Credential")
  valid_774376 = validateParameter(valid_774376, JString, required = false,
                                 default = nil)
  if valid_774376 != nil:
    section.add "X-Amz-Credential", valid_774376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774378: Call_SearchUsers_774364; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_774378.validator(path, query, header, formData, body)
  let scheme = call_774378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774378.url(scheme.get, call_774378.host, call_774378.base,
                         call_774378.route, valid.getOrDefault("path"))
  result = hook(call_774378, url, valid)

proc call*(call_774379: Call_SearchUsers_774364; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchUsers
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774380 = newJObject()
  var body_774381 = newJObject()
  add(query_774380, "NextToken", newJString(NextToken))
  if body != nil:
    body_774381 = body
  add(query_774380, "MaxResults", newJString(MaxResults))
  result = call_774379.call(nil, query_774380, nil, nil, body_774381)

var searchUsers* = Call_SearchUsers_774364(name: "searchUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.SearchUsers",
                                        validator: validate_SearchUsers_774365,
                                        base: "/", url: url_SearchUsers_774366,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAnnouncement_774382 = ref object of OpenApiRestCall_772597
proc url_SendAnnouncement_774384(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SendAnnouncement_774383(path: JsonNode; query: JsonNode;
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
  var valid_774385 = header.getOrDefault("X-Amz-Date")
  valid_774385 = validateParameter(valid_774385, JString, required = false,
                                 default = nil)
  if valid_774385 != nil:
    section.add "X-Amz-Date", valid_774385
  var valid_774386 = header.getOrDefault("X-Amz-Security-Token")
  valid_774386 = validateParameter(valid_774386, JString, required = false,
                                 default = nil)
  if valid_774386 != nil:
    section.add "X-Amz-Security-Token", valid_774386
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774387 = header.getOrDefault("X-Amz-Target")
  valid_774387 = validateParameter(valid_774387, JString, required = true, default = newJString(
      "AlexaForBusiness.SendAnnouncement"))
  if valid_774387 != nil:
    section.add "X-Amz-Target", valid_774387
  var valid_774388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774388 = validateParameter(valid_774388, JString, required = false,
                                 default = nil)
  if valid_774388 != nil:
    section.add "X-Amz-Content-Sha256", valid_774388
  var valid_774389 = header.getOrDefault("X-Amz-Algorithm")
  valid_774389 = validateParameter(valid_774389, JString, required = false,
                                 default = nil)
  if valid_774389 != nil:
    section.add "X-Amz-Algorithm", valid_774389
  var valid_774390 = header.getOrDefault("X-Amz-Signature")
  valid_774390 = validateParameter(valid_774390, JString, required = false,
                                 default = nil)
  if valid_774390 != nil:
    section.add "X-Amz-Signature", valid_774390
  var valid_774391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774391 = validateParameter(valid_774391, JString, required = false,
                                 default = nil)
  if valid_774391 != nil:
    section.add "X-Amz-SignedHeaders", valid_774391
  var valid_774392 = header.getOrDefault("X-Amz-Credential")
  valid_774392 = validateParameter(valid_774392, JString, required = false,
                                 default = nil)
  if valid_774392 != nil:
    section.add "X-Amz-Credential", valid_774392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774394: Call_SendAnnouncement_774382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Triggers an asynchronous flow to send text, SSML, or audio announcements to rooms that are identified by a search or filter. 
  ## 
  let valid = call_774394.validator(path, query, header, formData, body)
  let scheme = call_774394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774394.url(scheme.get, call_774394.host, call_774394.base,
                         call_774394.route, valid.getOrDefault("path"))
  result = hook(call_774394, url, valid)

proc call*(call_774395: Call_SendAnnouncement_774382; body: JsonNode): Recallable =
  ## sendAnnouncement
  ## Triggers an asynchronous flow to send text, SSML, or audio announcements to rooms that are identified by a search or filter. 
  ##   body: JObject (required)
  var body_774396 = newJObject()
  if body != nil:
    body_774396 = body
  result = call_774395.call(nil, nil, nil, nil, body_774396)

var sendAnnouncement* = Call_SendAnnouncement_774382(name: "sendAnnouncement",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SendAnnouncement",
    validator: validate_SendAnnouncement_774383, base: "/",
    url: url_SendAnnouncement_774384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendInvitation_774397 = ref object of OpenApiRestCall_772597
proc url_SendInvitation_774399(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SendInvitation_774398(path: JsonNode; query: JsonNode;
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
  var valid_774400 = header.getOrDefault("X-Amz-Date")
  valid_774400 = validateParameter(valid_774400, JString, required = false,
                                 default = nil)
  if valid_774400 != nil:
    section.add "X-Amz-Date", valid_774400
  var valid_774401 = header.getOrDefault("X-Amz-Security-Token")
  valid_774401 = validateParameter(valid_774401, JString, required = false,
                                 default = nil)
  if valid_774401 != nil:
    section.add "X-Amz-Security-Token", valid_774401
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774402 = header.getOrDefault("X-Amz-Target")
  valid_774402 = validateParameter(valid_774402, JString, required = true, default = newJString(
      "AlexaForBusiness.SendInvitation"))
  if valid_774402 != nil:
    section.add "X-Amz-Target", valid_774402
  var valid_774403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774403 = validateParameter(valid_774403, JString, required = false,
                                 default = nil)
  if valid_774403 != nil:
    section.add "X-Amz-Content-Sha256", valid_774403
  var valid_774404 = header.getOrDefault("X-Amz-Algorithm")
  valid_774404 = validateParameter(valid_774404, JString, required = false,
                                 default = nil)
  if valid_774404 != nil:
    section.add "X-Amz-Algorithm", valid_774404
  var valid_774405 = header.getOrDefault("X-Amz-Signature")
  valid_774405 = validateParameter(valid_774405, JString, required = false,
                                 default = nil)
  if valid_774405 != nil:
    section.add "X-Amz-Signature", valid_774405
  var valid_774406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774406 = validateParameter(valid_774406, JString, required = false,
                                 default = nil)
  if valid_774406 != nil:
    section.add "X-Amz-SignedHeaders", valid_774406
  var valid_774407 = header.getOrDefault("X-Amz-Credential")
  valid_774407 = validateParameter(valid_774407, JString, required = false,
                                 default = nil)
  if valid_774407 != nil:
    section.add "X-Amz-Credential", valid_774407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774409: Call_SendInvitation_774397; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends an enrollment invitation email with a URL to a user. The URL is valid for 30 days or until you call this operation again, whichever comes first. 
  ## 
  let valid = call_774409.validator(path, query, header, formData, body)
  let scheme = call_774409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774409.url(scheme.get, call_774409.host, call_774409.base,
                         call_774409.route, valid.getOrDefault("path"))
  result = hook(call_774409, url, valid)

proc call*(call_774410: Call_SendInvitation_774397; body: JsonNode): Recallable =
  ## sendInvitation
  ## Sends an enrollment invitation email with a URL to a user. The URL is valid for 30 days or until you call this operation again, whichever comes first. 
  ##   body: JObject (required)
  var body_774411 = newJObject()
  if body != nil:
    body_774411 = body
  result = call_774410.call(nil, nil, nil, nil, body_774411)

var sendInvitation* = Call_SendInvitation_774397(name: "sendInvitation",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SendInvitation",
    validator: validate_SendInvitation_774398, base: "/", url: url_SendInvitation_774399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeviceSync_774412 = ref object of OpenApiRestCall_772597
proc url_StartDeviceSync_774414(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartDeviceSync_774413(path: JsonNode; query: JsonNode;
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
  var valid_774415 = header.getOrDefault("X-Amz-Date")
  valid_774415 = validateParameter(valid_774415, JString, required = false,
                                 default = nil)
  if valid_774415 != nil:
    section.add "X-Amz-Date", valid_774415
  var valid_774416 = header.getOrDefault("X-Amz-Security-Token")
  valid_774416 = validateParameter(valid_774416, JString, required = false,
                                 default = nil)
  if valid_774416 != nil:
    section.add "X-Amz-Security-Token", valid_774416
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774417 = header.getOrDefault("X-Amz-Target")
  valid_774417 = validateParameter(valid_774417, JString, required = true, default = newJString(
      "AlexaForBusiness.StartDeviceSync"))
  if valid_774417 != nil:
    section.add "X-Amz-Target", valid_774417
  var valid_774418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774418 = validateParameter(valid_774418, JString, required = false,
                                 default = nil)
  if valid_774418 != nil:
    section.add "X-Amz-Content-Sha256", valid_774418
  var valid_774419 = header.getOrDefault("X-Amz-Algorithm")
  valid_774419 = validateParameter(valid_774419, JString, required = false,
                                 default = nil)
  if valid_774419 != nil:
    section.add "X-Amz-Algorithm", valid_774419
  var valid_774420 = header.getOrDefault("X-Amz-Signature")
  valid_774420 = validateParameter(valid_774420, JString, required = false,
                                 default = nil)
  if valid_774420 != nil:
    section.add "X-Amz-Signature", valid_774420
  var valid_774421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774421 = validateParameter(valid_774421, JString, required = false,
                                 default = nil)
  if valid_774421 != nil:
    section.add "X-Amz-SignedHeaders", valid_774421
  var valid_774422 = header.getOrDefault("X-Amz-Credential")
  valid_774422 = validateParameter(valid_774422, JString, required = false,
                                 default = nil)
  if valid_774422 != nil:
    section.add "X-Amz-Credential", valid_774422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774424: Call_StartDeviceSync_774412; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets a device and its account to the known default settings. This clears all information and settings set by previous users in the following ways:</p> <ul> <li> <p>Bluetooth - This unpairs all bluetooth devices paired with your echo device.</p> </li> <li> <p>Volume - This resets the echo device's volume to the default value.</p> </li> <li> <p>Notifications - This clears all notifications from your echo device.</p> </li> <li> <p>Lists - This clears all to-do items from your echo device.</p> </li> <li> <p>Settings - This internally syncs the room's profile (if the device is assigned to a room), contacts, address books, delegation access for account linking, and communications (if enabled on the room profile).</p> </li> </ul>
  ## 
  let valid = call_774424.validator(path, query, header, formData, body)
  let scheme = call_774424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774424.url(scheme.get, call_774424.host, call_774424.base,
                         call_774424.route, valid.getOrDefault("path"))
  result = hook(call_774424, url, valid)

proc call*(call_774425: Call_StartDeviceSync_774412; body: JsonNode): Recallable =
  ## startDeviceSync
  ## <p>Resets a device and its account to the known default settings. This clears all information and settings set by previous users in the following ways:</p> <ul> <li> <p>Bluetooth - This unpairs all bluetooth devices paired with your echo device.</p> </li> <li> <p>Volume - This resets the echo device's volume to the default value.</p> </li> <li> <p>Notifications - This clears all notifications from your echo device.</p> </li> <li> <p>Lists - This clears all to-do items from your echo device.</p> </li> <li> <p>Settings - This internally syncs the room's profile (if the device is assigned to a room), contacts, address books, delegation access for account linking, and communications (if enabled on the room profile).</p> </li> </ul>
  ##   body: JObject (required)
  var body_774426 = newJObject()
  if body != nil:
    body_774426 = body
  result = call_774425.call(nil, nil, nil, nil, body_774426)

var startDeviceSync* = Call_StartDeviceSync_774412(name: "startDeviceSync",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.StartDeviceSync",
    validator: validate_StartDeviceSync_774413, base: "/", url: url_StartDeviceSync_774414,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSmartHomeApplianceDiscovery_774427 = ref object of OpenApiRestCall_772597
proc url_StartSmartHomeApplianceDiscovery_774429(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartSmartHomeApplianceDiscovery_774428(path: JsonNode;
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
  var valid_774430 = header.getOrDefault("X-Amz-Date")
  valid_774430 = validateParameter(valid_774430, JString, required = false,
                                 default = nil)
  if valid_774430 != nil:
    section.add "X-Amz-Date", valid_774430
  var valid_774431 = header.getOrDefault("X-Amz-Security-Token")
  valid_774431 = validateParameter(valid_774431, JString, required = false,
                                 default = nil)
  if valid_774431 != nil:
    section.add "X-Amz-Security-Token", valid_774431
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774432 = header.getOrDefault("X-Amz-Target")
  valid_774432 = validateParameter(valid_774432, JString, required = true, default = newJString(
      "AlexaForBusiness.StartSmartHomeApplianceDiscovery"))
  if valid_774432 != nil:
    section.add "X-Amz-Target", valid_774432
  var valid_774433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774433 = validateParameter(valid_774433, JString, required = false,
                                 default = nil)
  if valid_774433 != nil:
    section.add "X-Amz-Content-Sha256", valid_774433
  var valid_774434 = header.getOrDefault("X-Amz-Algorithm")
  valid_774434 = validateParameter(valid_774434, JString, required = false,
                                 default = nil)
  if valid_774434 != nil:
    section.add "X-Amz-Algorithm", valid_774434
  var valid_774435 = header.getOrDefault("X-Amz-Signature")
  valid_774435 = validateParameter(valid_774435, JString, required = false,
                                 default = nil)
  if valid_774435 != nil:
    section.add "X-Amz-Signature", valid_774435
  var valid_774436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774436 = validateParameter(valid_774436, JString, required = false,
                                 default = nil)
  if valid_774436 != nil:
    section.add "X-Amz-SignedHeaders", valid_774436
  var valid_774437 = header.getOrDefault("X-Amz-Credential")
  valid_774437 = validateParameter(valid_774437, JString, required = false,
                                 default = nil)
  if valid_774437 != nil:
    section.add "X-Amz-Credential", valid_774437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774439: Call_StartSmartHomeApplianceDiscovery_774427;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Initiates the discovery of any smart home appliances associated with the room.
  ## 
  let valid = call_774439.validator(path, query, header, formData, body)
  let scheme = call_774439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774439.url(scheme.get, call_774439.host, call_774439.base,
                         call_774439.route, valid.getOrDefault("path"))
  result = hook(call_774439, url, valid)

proc call*(call_774440: Call_StartSmartHomeApplianceDiscovery_774427;
          body: JsonNode): Recallable =
  ## startSmartHomeApplianceDiscovery
  ## Initiates the discovery of any smart home appliances associated with the room.
  ##   body: JObject (required)
  var body_774441 = newJObject()
  if body != nil:
    body_774441 = body
  result = call_774440.call(nil, nil, nil, nil, body_774441)

var startSmartHomeApplianceDiscovery* = Call_StartSmartHomeApplianceDiscovery_774427(
    name: "startSmartHomeApplianceDiscovery", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.StartSmartHomeApplianceDiscovery",
    validator: validate_StartSmartHomeApplianceDiscovery_774428, base: "/",
    url: url_StartSmartHomeApplianceDiscovery_774429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_774442 = ref object of OpenApiRestCall_772597
proc url_TagResource_774444(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_774443(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774445 = header.getOrDefault("X-Amz-Date")
  valid_774445 = validateParameter(valid_774445, JString, required = false,
                                 default = nil)
  if valid_774445 != nil:
    section.add "X-Amz-Date", valid_774445
  var valid_774446 = header.getOrDefault("X-Amz-Security-Token")
  valid_774446 = validateParameter(valid_774446, JString, required = false,
                                 default = nil)
  if valid_774446 != nil:
    section.add "X-Amz-Security-Token", valid_774446
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774447 = header.getOrDefault("X-Amz-Target")
  valid_774447 = validateParameter(valid_774447, JString, required = true, default = newJString(
      "AlexaForBusiness.TagResource"))
  if valid_774447 != nil:
    section.add "X-Amz-Target", valid_774447
  var valid_774448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774448 = validateParameter(valid_774448, JString, required = false,
                                 default = nil)
  if valid_774448 != nil:
    section.add "X-Amz-Content-Sha256", valid_774448
  var valid_774449 = header.getOrDefault("X-Amz-Algorithm")
  valid_774449 = validateParameter(valid_774449, JString, required = false,
                                 default = nil)
  if valid_774449 != nil:
    section.add "X-Amz-Algorithm", valid_774449
  var valid_774450 = header.getOrDefault("X-Amz-Signature")
  valid_774450 = validateParameter(valid_774450, JString, required = false,
                                 default = nil)
  if valid_774450 != nil:
    section.add "X-Amz-Signature", valid_774450
  var valid_774451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774451 = validateParameter(valid_774451, JString, required = false,
                                 default = nil)
  if valid_774451 != nil:
    section.add "X-Amz-SignedHeaders", valid_774451
  var valid_774452 = header.getOrDefault("X-Amz-Credential")
  valid_774452 = validateParameter(valid_774452, JString, required = false,
                                 default = nil)
  if valid_774452 != nil:
    section.add "X-Amz-Credential", valid_774452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774454: Call_TagResource_774442; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to a specified resource.
  ## 
  let valid = call_774454.validator(path, query, header, formData, body)
  let scheme = call_774454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774454.url(scheme.get, call_774454.host, call_774454.base,
                         call_774454.route, valid.getOrDefault("path"))
  result = hook(call_774454, url, valid)

proc call*(call_774455: Call_TagResource_774442; body: JsonNode): Recallable =
  ## tagResource
  ## Adds metadata tags to a specified resource.
  ##   body: JObject (required)
  var body_774456 = newJObject()
  if body != nil:
    body_774456 = body
  result = call_774455.call(nil, nil, nil, nil, body_774456)

var tagResource* = Call_TagResource_774442(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.TagResource",
                                        validator: validate_TagResource_774443,
                                        base: "/", url: url_TagResource_774444,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_774457 = ref object of OpenApiRestCall_772597
proc url_UntagResource_774459(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_774458(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774460 = header.getOrDefault("X-Amz-Date")
  valid_774460 = validateParameter(valid_774460, JString, required = false,
                                 default = nil)
  if valid_774460 != nil:
    section.add "X-Amz-Date", valid_774460
  var valid_774461 = header.getOrDefault("X-Amz-Security-Token")
  valid_774461 = validateParameter(valid_774461, JString, required = false,
                                 default = nil)
  if valid_774461 != nil:
    section.add "X-Amz-Security-Token", valid_774461
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774462 = header.getOrDefault("X-Amz-Target")
  valid_774462 = validateParameter(valid_774462, JString, required = true, default = newJString(
      "AlexaForBusiness.UntagResource"))
  if valid_774462 != nil:
    section.add "X-Amz-Target", valid_774462
  var valid_774463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774463 = validateParameter(valid_774463, JString, required = false,
                                 default = nil)
  if valid_774463 != nil:
    section.add "X-Amz-Content-Sha256", valid_774463
  var valid_774464 = header.getOrDefault("X-Amz-Algorithm")
  valid_774464 = validateParameter(valid_774464, JString, required = false,
                                 default = nil)
  if valid_774464 != nil:
    section.add "X-Amz-Algorithm", valid_774464
  var valid_774465 = header.getOrDefault("X-Amz-Signature")
  valid_774465 = validateParameter(valid_774465, JString, required = false,
                                 default = nil)
  if valid_774465 != nil:
    section.add "X-Amz-Signature", valid_774465
  var valid_774466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774466 = validateParameter(valid_774466, JString, required = false,
                                 default = nil)
  if valid_774466 != nil:
    section.add "X-Amz-SignedHeaders", valid_774466
  var valid_774467 = header.getOrDefault("X-Amz-Credential")
  valid_774467 = validateParameter(valid_774467, JString, required = false,
                                 default = nil)
  if valid_774467 != nil:
    section.add "X-Amz-Credential", valid_774467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774469: Call_UntagResource_774457; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from a specified resource.
  ## 
  let valid = call_774469.validator(path, query, header, formData, body)
  let scheme = call_774469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774469.url(scheme.get, call_774469.host, call_774469.base,
                         call_774469.route, valid.getOrDefault("path"))
  result = hook(call_774469, url, valid)

proc call*(call_774470: Call_UntagResource_774457; body: JsonNode): Recallable =
  ## untagResource
  ## Removes metadata tags from a specified resource.
  ##   body: JObject (required)
  var body_774471 = newJObject()
  if body != nil:
    body_774471 = body
  result = call_774470.call(nil, nil, nil, nil, body_774471)

var untagResource* = Call_UntagResource_774457(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UntagResource",
    validator: validate_UntagResource_774458, base: "/", url: url_UntagResource_774459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAddressBook_774472 = ref object of OpenApiRestCall_772597
proc url_UpdateAddressBook_774474(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateAddressBook_774473(path: JsonNode; query: JsonNode;
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
  var valid_774475 = header.getOrDefault("X-Amz-Date")
  valid_774475 = validateParameter(valid_774475, JString, required = false,
                                 default = nil)
  if valid_774475 != nil:
    section.add "X-Amz-Date", valid_774475
  var valid_774476 = header.getOrDefault("X-Amz-Security-Token")
  valid_774476 = validateParameter(valid_774476, JString, required = false,
                                 default = nil)
  if valid_774476 != nil:
    section.add "X-Amz-Security-Token", valid_774476
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774477 = header.getOrDefault("X-Amz-Target")
  valid_774477 = validateParameter(valid_774477, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateAddressBook"))
  if valid_774477 != nil:
    section.add "X-Amz-Target", valid_774477
  var valid_774478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774478 = validateParameter(valid_774478, JString, required = false,
                                 default = nil)
  if valid_774478 != nil:
    section.add "X-Amz-Content-Sha256", valid_774478
  var valid_774479 = header.getOrDefault("X-Amz-Algorithm")
  valid_774479 = validateParameter(valid_774479, JString, required = false,
                                 default = nil)
  if valid_774479 != nil:
    section.add "X-Amz-Algorithm", valid_774479
  var valid_774480 = header.getOrDefault("X-Amz-Signature")
  valid_774480 = validateParameter(valid_774480, JString, required = false,
                                 default = nil)
  if valid_774480 != nil:
    section.add "X-Amz-Signature", valid_774480
  var valid_774481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774481 = validateParameter(valid_774481, JString, required = false,
                                 default = nil)
  if valid_774481 != nil:
    section.add "X-Amz-SignedHeaders", valid_774481
  var valid_774482 = header.getOrDefault("X-Amz-Credential")
  valid_774482 = validateParameter(valid_774482, JString, required = false,
                                 default = nil)
  if valid_774482 != nil:
    section.add "X-Amz-Credential", valid_774482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774484: Call_UpdateAddressBook_774472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates address book details by the address book ARN.
  ## 
  let valid = call_774484.validator(path, query, header, formData, body)
  let scheme = call_774484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774484.url(scheme.get, call_774484.host, call_774484.base,
                         call_774484.route, valid.getOrDefault("path"))
  result = hook(call_774484, url, valid)

proc call*(call_774485: Call_UpdateAddressBook_774472; body: JsonNode): Recallable =
  ## updateAddressBook
  ## Updates address book details by the address book ARN.
  ##   body: JObject (required)
  var body_774486 = newJObject()
  if body != nil:
    body_774486 = body
  result = call_774485.call(nil, nil, nil, nil, body_774486)

var updateAddressBook* = Call_UpdateAddressBook_774472(name: "updateAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateAddressBook",
    validator: validate_UpdateAddressBook_774473, base: "/",
    url: url_UpdateAddressBook_774474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBusinessReportSchedule_774487 = ref object of OpenApiRestCall_772597
proc url_UpdateBusinessReportSchedule_774489(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateBusinessReportSchedule_774488(path: JsonNode; query: JsonNode;
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
  var valid_774490 = header.getOrDefault("X-Amz-Date")
  valid_774490 = validateParameter(valid_774490, JString, required = false,
                                 default = nil)
  if valid_774490 != nil:
    section.add "X-Amz-Date", valid_774490
  var valid_774491 = header.getOrDefault("X-Amz-Security-Token")
  valid_774491 = validateParameter(valid_774491, JString, required = false,
                                 default = nil)
  if valid_774491 != nil:
    section.add "X-Amz-Security-Token", valid_774491
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774492 = header.getOrDefault("X-Amz-Target")
  valid_774492 = validateParameter(valid_774492, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateBusinessReportSchedule"))
  if valid_774492 != nil:
    section.add "X-Amz-Target", valid_774492
  var valid_774493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774493 = validateParameter(valid_774493, JString, required = false,
                                 default = nil)
  if valid_774493 != nil:
    section.add "X-Amz-Content-Sha256", valid_774493
  var valid_774494 = header.getOrDefault("X-Amz-Algorithm")
  valid_774494 = validateParameter(valid_774494, JString, required = false,
                                 default = nil)
  if valid_774494 != nil:
    section.add "X-Amz-Algorithm", valid_774494
  var valid_774495 = header.getOrDefault("X-Amz-Signature")
  valid_774495 = validateParameter(valid_774495, JString, required = false,
                                 default = nil)
  if valid_774495 != nil:
    section.add "X-Amz-Signature", valid_774495
  var valid_774496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774496 = validateParameter(valid_774496, JString, required = false,
                                 default = nil)
  if valid_774496 != nil:
    section.add "X-Amz-SignedHeaders", valid_774496
  var valid_774497 = header.getOrDefault("X-Amz-Credential")
  valid_774497 = validateParameter(valid_774497, JString, required = false,
                                 default = nil)
  if valid_774497 != nil:
    section.add "X-Amz-Credential", valid_774497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774499: Call_UpdateBusinessReportSchedule_774487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration of the report delivery schedule with the specified schedule ARN.
  ## 
  let valid = call_774499.validator(path, query, header, formData, body)
  let scheme = call_774499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774499.url(scheme.get, call_774499.host, call_774499.base,
                         call_774499.route, valid.getOrDefault("path"))
  result = hook(call_774499, url, valid)

proc call*(call_774500: Call_UpdateBusinessReportSchedule_774487; body: JsonNode): Recallable =
  ## updateBusinessReportSchedule
  ## Updates the configuration of the report delivery schedule with the specified schedule ARN.
  ##   body: JObject (required)
  var body_774501 = newJObject()
  if body != nil:
    body_774501 = body
  result = call_774500.call(nil, nil, nil, nil, body_774501)

var updateBusinessReportSchedule* = Call_UpdateBusinessReportSchedule_774487(
    name: "updateBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateBusinessReportSchedule",
    validator: validate_UpdateBusinessReportSchedule_774488, base: "/",
    url: url_UpdateBusinessReportSchedule_774489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConferenceProvider_774502 = ref object of OpenApiRestCall_772597
proc url_UpdateConferenceProvider_774504(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateConferenceProvider_774503(path: JsonNode; query: JsonNode;
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
  var valid_774505 = header.getOrDefault("X-Amz-Date")
  valid_774505 = validateParameter(valid_774505, JString, required = false,
                                 default = nil)
  if valid_774505 != nil:
    section.add "X-Amz-Date", valid_774505
  var valid_774506 = header.getOrDefault("X-Amz-Security-Token")
  valid_774506 = validateParameter(valid_774506, JString, required = false,
                                 default = nil)
  if valid_774506 != nil:
    section.add "X-Amz-Security-Token", valid_774506
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774507 = header.getOrDefault("X-Amz-Target")
  valid_774507 = validateParameter(valid_774507, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateConferenceProvider"))
  if valid_774507 != nil:
    section.add "X-Amz-Target", valid_774507
  var valid_774508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774508 = validateParameter(valid_774508, JString, required = false,
                                 default = nil)
  if valid_774508 != nil:
    section.add "X-Amz-Content-Sha256", valid_774508
  var valid_774509 = header.getOrDefault("X-Amz-Algorithm")
  valid_774509 = validateParameter(valid_774509, JString, required = false,
                                 default = nil)
  if valid_774509 != nil:
    section.add "X-Amz-Algorithm", valid_774509
  var valid_774510 = header.getOrDefault("X-Amz-Signature")
  valid_774510 = validateParameter(valid_774510, JString, required = false,
                                 default = nil)
  if valid_774510 != nil:
    section.add "X-Amz-Signature", valid_774510
  var valid_774511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774511 = validateParameter(valid_774511, JString, required = false,
                                 default = nil)
  if valid_774511 != nil:
    section.add "X-Amz-SignedHeaders", valid_774511
  var valid_774512 = header.getOrDefault("X-Amz-Credential")
  valid_774512 = validateParameter(valid_774512, JString, required = false,
                                 default = nil)
  if valid_774512 != nil:
    section.add "X-Amz-Credential", valid_774512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774514: Call_UpdateConferenceProvider_774502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing conference provider's settings.
  ## 
  let valid = call_774514.validator(path, query, header, formData, body)
  let scheme = call_774514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774514.url(scheme.get, call_774514.host, call_774514.base,
                         call_774514.route, valid.getOrDefault("path"))
  result = hook(call_774514, url, valid)

proc call*(call_774515: Call_UpdateConferenceProvider_774502; body: JsonNode): Recallable =
  ## updateConferenceProvider
  ## Updates an existing conference provider's settings.
  ##   body: JObject (required)
  var body_774516 = newJObject()
  if body != nil:
    body_774516 = body
  result = call_774515.call(nil, nil, nil, nil, body_774516)

var updateConferenceProvider* = Call_UpdateConferenceProvider_774502(
    name: "updateConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateConferenceProvider",
    validator: validate_UpdateConferenceProvider_774503, base: "/",
    url: url_UpdateConferenceProvider_774504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContact_774517 = ref object of OpenApiRestCall_772597
proc url_UpdateContact_774519(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateContact_774518(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774520 = header.getOrDefault("X-Amz-Date")
  valid_774520 = validateParameter(valid_774520, JString, required = false,
                                 default = nil)
  if valid_774520 != nil:
    section.add "X-Amz-Date", valid_774520
  var valid_774521 = header.getOrDefault("X-Amz-Security-Token")
  valid_774521 = validateParameter(valid_774521, JString, required = false,
                                 default = nil)
  if valid_774521 != nil:
    section.add "X-Amz-Security-Token", valid_774521
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774522 = header.getOrDefault("X-Amz-Target")
  valid_774522 = validateParameter(valid_774522, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateContact"))
  if valid_774522 != nil:
    section.add "X-Amz-Target", valid_774522
  var valid_774523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774523 = validateParameter(valid_774523, JString, required = false,
                                 default = nil)
  if valid_774523 != nil:
    section.add "X-Amz-Content-Sha256", valid_774523
  var valid_774524 = header.getOrDefault("X-Amz-Algorithm")
  valid_774524 = validateParameter(valid_774524, JString, required = false,
                                 default = nil)
  if valid_774524 != nil:
    section.add "X-Amz-Algorithm", valid_774524
  var valid_774525 = header.getOrDefault("X-Amz-Signature")
  valid_774525 = validateParameter(valid_774525, JString, required = false,
                                 default = nil)
  if valid_774525 != nil:
    section.add "X-Amz-Signature", valid_774525
  var valid_774526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774526 = validateParameter(valid_774526, JString, required = false,
                                 default = nil)
  if valid_774526 != nil:
    section.add "X-Amz-SignedHeaders", valid_774526
  var valid_774527 = header.getOrDefault("X-Amz-Credential")
  valid_774527 = validateParameter(valid_774527, JString, required = false,
                                 default = nil)
  if valid_774527 != nil:
    section.add "X-Amz-Credential", valid_774527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774529: Call_UpdateContact_774517; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the contact details by the contact ARN.
  ## 
  let valid = call_774529.validator(path, query, header, formData, body)
  let scheme = call_774529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774529.url(scheme.get, call_774529.host, call_774529.base,
                         call_774529.route, valid.getOrDefault("path"))
  result = hook(call_774529, url, valid)

proc call*(call_774530: Call_UpdateContact_774517; body: JsonNode): Recallable =
  ## updateContact
  ## Updates the contact details by the contact ARN.
  ##   body: JObject (required)
  var body_774531 = newJObject()
  if body != nil:
    body_774531 = body
  result = call_774530.call(nil, nil, nil, nil, body_774531)

var updateContact* = Call_UpdateContact_774517(name: "updateContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateContact",
    validator: validate_UpdateContact_774518, base: "/", url: url_UpdateContact_774519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevice_774532 = ref object of OpenApiRestCall_772597
proc url_UpdateDevice_774534(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDevice_774533(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774535 = header.getOrDefault("X-Amz-Date")
  valid_774535 = validateParameter(valid_774535, JString, required = false,
                                 default = nil)
  if valid_774535 != nil:
    section.add "X-Amz-Date", valid_774535
  var valid_774536 = header.getOrDefault("X-Amz-Security-Token")
  valid_774536 = validateParameter(valid_774536, JString, required = false,
                                 default = nil)
  if valid_774536 != nil:
    section.add "X-Amz-Security-Token", valid_774536
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774537 = header.getOrDefault("X-Amz-Target")
  valid_774537 = validateParameter(valid_774537, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateDevice"))
  if valid_774537 != nil:
    section.add "X-Amz-Target", valid_774537
  var valid_774538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774538 = validateParameter(valid_774538, JString, required = false,
                                 default = nil)
  if valid_774538 != nil:
    section.add "X-Amz-Content-Sha256", valid_774538
  var valid_774539 = header.getOrDefault("X-Amz-Algorithm")
  valid_774539 = validateParameter(valid_774539, JString, required = false,
                                 default = nil)
  if valid_774539 != nil:
    section.add "X-Amz-Algorithm", valid_774539
  var valid_774540 = header.getOrDefault("X-Amz-Signature")
  valid_774540 = validateParameter(valid_774540, JString, required = false,
                                 default = nil)
  if valid_774540 != nil:
    section.add "X-Amz-Signature", valid_774540
  var valid_774541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774541 = validateParameter(valid_774541, JString, required = false,
                                 default = nil)
  if valid_774541 != nil:
    section.add "X-Amz-SignedHeaders", valid_774541
  var valid_774542 = header.getOrDefault("X-Amz-Credential")
  valid_774542 = validateParameter(valid_774542, JString, required = false,
                                 default = nil)
  if valid_774542 != nil:
    section.add "X-Amz-Credential", valid_774542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774544: Call_UpdateDevice_774532; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the device name by device ARN.
  ## 
  let valid = call_774544.validator(path, query, header, formData, body)
  let scheme = call_774544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774544.url(scheme.get, call_774544.host, call_774544.base,
                         call_774544.route, valid.getOrDefault("path"))
  result = hook(call_774544, url, valid)

proc call*(call_774545: Call_UpdateDevice_774532; body: JsonNode): Recallable =
  ## updateDevice
  ## Updates the device name by device ARN.
  ##   body: JObject (required)
  var body_774546 = newJObject()
  if body != nil:
    body_774546 = body
  result = call_774545.call(nil, nil, nil, nil, body_774546)

var updateDevice* = Call_UpdateDevice_774532(name: "updateDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateDevice",
    validator: validate_UpdateDevice_774533, base: "/", url: url_UpdateDevice_774534,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGateway_774547 = ref object of OpenApiRestCall_772597
proc url_UpdateGateway_774549(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateGateway_774548(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774550 = header.getOrDefault("X-Amz-Date")
  valid_774550 = validateParameter(valid_774550, JString, required = false,
                                 default = nil)
  if valid_774550 != nil:
    section.add "X-Amz-Date", valid_774550
  var valid_774551 = header.getOrDefault("X-Amz-Security-Token")
  valid_774551 = validateParameter(valid_774551, JString, required = false,
                                 default = nil)
  if valid_774551 != nil:
    section.add "X-Amz-Security-Token", valid_774551
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774552 = header.getOrDefault("X-Amz-Target")
  valid_774552 = validateParameter(valid_774552, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateGateway"))
  if valid_774552 != nil:
    section.add "X-Amz-Target", valid_774552
  var valid_774553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774553 = validateParameter(valid_774553, JString, required = false,
                                 default = nil)
  if valid_774553 != nil:
    section.add "X-Amz-Content-Sha256", valid_774553
  var valid_774554 = header.getOrDefault("X-Amz-Algorithm")
  valid_774554 = validateParameter(valid_774554, JString, required = false,
                                 default = nil)
  if valid_774554 != nil:
    section.add "X-Amz-Algorithm", valid_774554
  var valid_774555 = header.getOrDefault("X-Amz-Signature")
  valid_774555 = validateParameter(valid_774555, JString, required = false,
                                 default = nil)
  if valid_774555 != nil:
    section.add "X-Amz-Signature", valid_774555
  var valid_774556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774556 = validateParameter(valid_774556, JString, required = false,
                                 default = nil)
  if valid_774556 != nil:
    section.add "X-Amz-SignedHeaders", valid_774556
  var valid_774557 = header.getOrDefault("X-Amz-Credential")
  valid_774557 = validateParameter(valid_774557, JString, required = false,
                                 default = nil)
  if valid_774557 != nil:
    section.add "X-Amz-Credential", valid_774557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774559: Call_UpdateGateway_774547; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details of a gateway. If any optional field is not provided, the existing corresponding value is left unmodified.
  ## 
  let valid = call_774559.validator(path, query, header, formData, body)
  let scheme = call_774559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774559.url(scheme.get, call_774559.host, call_774559.base,
                         call_774559.route, valid.getOrDefault("path"))
  result = hook(call_774559, url, valid)

proc call*(call_774560: Call_UpdateGateway_774547; body: JsonNode): Recallable =
  ## updateGateway
  ## Updates the details of a gateway. If any optional field is not provided, the existing corresponding value is left unmodified.
  ##   body: JObject (required)
  var body_774561 = newJObject()
  if body != nil:
    body_774561 = body
  result = call_774560.call(nil, nil, nil, nil, body_774561)

var updateGateway* = Call_UpdateGateway_774547(name: "updateGateway",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateGateway",
    validator: validate_UpdateGateway_774548, base: "/", url: url_UpdateGateway_774549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayGroup_774562 = ref object of OpenApiRestCall_772597
proc url_UpdateGatewayGroup_774564(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateGatewayGroup_774563(path: JsonNode; query: JsonNode;
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
  var valid_774565 = header.getOrDefault("X-Amz-Date")
  valid_774565 = validateParameter(valid_774565, JString, required = false,
                                 default = nil)
  if valid_774565 != nil:
    section.add "X-Amz-Date", valid_774565
  var valid_774566 = header.getOrDefault("X-Amz-Security-Token")
  valid_774566 = validateParameter(valid_774566, JString, required = false,
                                 default = nil)
  if valid_774566 != nil:
    section.add "X-Amz-Security-Token", valid_774566
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774567 = header.getOrDefault("X-Amz-Target")
  valid_774567 = validateParameter(valid_774567, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateGatewayGroup"))
  if valid_774567 != nil:
    section.add "X-Amz-Target", valid_774567
  var valid_774568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774568 = validateParameter(valid_774568, JString, required = false,
                                 default = nil)
  if valid_774568 != nil:
    section.add "X-Amz-Content-Sha256", valid_774568
  var valid_774569 = header.getOrDefault("X-Amz-Algorithm")
  valid_774569 = validateParameter(valid_774569, JString, required = false,
                                 default = nil)
  if valid_774569 != nil:
    section.add "X-Amz-Algorithm", valid_774569
  var valid_774570 = header.getOrDefault("X-Amz-Signature")
  valid_774570 = validateParameter(valid_774570, JString, required = false,
                                 default = nil)
  if valid_774570 != nil:
    section.add "X-Amz-Signature", valid_774570
  var valid_774571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774571 = validateParameter(valid_774571, JString, required = false,
                                 default = nil)
  if valid_774571 != nil:
    section.add "X-Amz-SignedHeaders", valid_774571
  var valid_774572 = header.getOrDefault("X-Amz-Credential")
  valid_774572 = validateParameter(valid_774572, JString, required = false,
                                 default = nil)
  if valid_774572 != nil:
    section.add "X-Amz-Credential", valid_774572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774574: Call_UpdateGatewayGroup_774562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details of a gateway group. If any optional field is not provided, the existing corresponding value is left unmodified.
  ## 
  let valid = call_774574.validator(path, query, header, formData, body)
  let scheme = call_774574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774574.url(scheme.get, call_774574.host, call_774574.base,
                         call_774574.route, valid.getOrDefault("path"))
  result = hook(call_774574, url, valid)

proc call*(call_774575: Call_UpdateGatewayGroup_774562; body: JsonNode): Recallable =
  ## updateGatewayGroup
  ## Updates the details of a gateway group. If any optional field is not provided, the existing corresponding value is left unmodified.
  ##   body: JObject (required)
  var body_774576 = newJObject()
  if body != nil:
    body_774576 = body
  result = call_774575.call(nil, nil, nil, nil, body_774576)

var updateGatewayGroup* = Call_UpdateGatewayGroup_774562(
    name: "updateGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateGatewayGroup",
    validator: validate_UpdateGatewayGroup_774563, base: "/",
    url: url_UpdateGatewayGroup_774564, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_774577 = ref object of OpenApiRestCall_772597
proc url_UpdateNetworkProfile_774579(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateNetworkProfile_774578(path: JsonNode; query: JsonNode;
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
  var valid_774580 = header.getOrDefault("X-Amz-Date")
  valid_774580 = validateParameter(valid_774580, JString, required = false,
                                 default = nil)
  if valid_774580 != nil:
    section.add "X-Amz-Date", valid_774580
  var valid_774581 = header.getOrDefault("X-Amz-Security-Token")
  valid_774581 = validateParameter(valid_774581, JString, required = false,
                                 default = nil)
  if valid_774581 != nil:
    section.add "X-Amz-Security-Token", valid_774581
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774582 = header.getOrDefault("X-Amz-Target")
  valid_774582 = validateParameter(valid_774582, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateNetworkProfile"))
  if valid_774582 != nil:
    section.add "X-Amz-Target", valid_774582
  var valid_774583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774583 = validateParameter(valid_774583, JString, required = false,
                                 default = nil)
  if valid_774583 != nil:
    section.add "X-Amz-Content-Sha256", valid_774583
  var valid_774584 = header.getOrDefault("X-Amz-Algorithm")
  valid_774584 = validateParameter(valid_774584, JString, required = false,
                                 default = nil)
  if valid_774584 != nil:
    section.add "X-Amz-Algorithm", valid_774584
  var valid_774585 = header.getOrDefault("X-Amz-Signature")
  valid_774585 = validateParameter(valid_774585, JString, required = false,
                                 default = nil)
  if valid_774585 != nil:
    section.add "X-Amz-Signature", valid_774585
  var valid_774586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774586 = validateParameter(valid_774586, JString, required = false,
                                 default = nil)
  if valid_774586 != nil:
    section.add "X-Amz-SignedHeaders", valid_774586
  var valid_774587 = header.getOrDefault("X-Amz-Credential")
  valid_774587 = validateParameter(valid_774587, JString, required = false,
                                 default = nil)
  if valid_774587 != nil:
    section.add "X-Amz-Credential", valid_774587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774589: Call_UpdateNetworkProfile_774577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a network profile by the network profile ARN.
  ## 
  let valid = call_774589.validator(path, query, header, formData, body)
  let scheme = call_774589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774589.url(scheme.get, call_774589.host, call_774589.base,
                         call_774589.route, valid.getOrDefault("path"))
  result = hook(call_774589, url, valid)

proc call*(call_774590: Call_UpdateNetworkProfile_774577; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates a network profile by the network profile ARN.
  ##   body: JObject (required)
  var body_774591 = newJObject()
  if body != nil:
    body_774591 = body
  result = call_774590.call(nil, nil, nil, nil, body_774591)

var updateNetworkProfile* = Call_UpdateNetworkProfile_774577(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_774578, base: "/",
    url: url_UpdateNetworkProfile_774579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProfile_774592 = ref object of OpenApiRestCall_772597
proc url_UpdateProfile_774594(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateProfile_774593(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774595 = header.getOrDefault("X-Amz-Date")
  valid_774595 = validateParameter(valid_774595, JString, required = false,
                                 default = nil)
  if valid_774595 != nil:
    section.add "X-Amz-Date", valid_774595
  var valid_774596 = header.getOrDefault("X-Amz-Security-Token")
  valid_774596 = validateParameter(valid_774596, JString, required = false,
                                 default = nil)
  if valid_774596 != nil:
    section.add "X-Amz-Security-Token", valid_774596
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774597 = header.getOrDefault("X-Amz-Target")
  valid_774597 = validateParameter(valid_774597, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateProfile"))
  if valid_774597 != nil:
    section.add "X-Amz-Target", valid_774597
  var valid_774598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774598 = validateParameter(valid_774598, JString, required = false,
                                 default = nil)
  if valid_774598 != nil:
    section.add "X-Amz-Content-Sha256", valid_774598
  var valid_774599 = header.getOrDefault("X-Amz-Algorithm")
  valid_774599 = validateParameter(valid_774599, JString, required = false,
                                 default = nil)
  if valid_774599 != nil:
    section.add "X-Amz-Algorithm", valid_774599
  var valid_774600 = header.getOrDefault("X-Amz-Signature")
  valid_774600 = validateParameter(valid_774600, JString, required = false,
                                 default = nil)
  if valid_774600 != nil:
    section.add "X-Amz-Signature", valid_774600
  var valid_774601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774601 = validateParameter(valid_774601, JString, required = false,
                                 default = nil)
  if valid_774601 != nil:
    section.add "X-Amz-SignedHeaders", valid_774601
  var valid_774602 = header.getOrDefault("X-Amz-Credential")
  valid_774602 = validateParameter(valid_774602, JString, required = false,
                                 default = nil)
  if valid_774602 != nil:
    section.add "X-Amz-Credential", valid_774602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774604: Call_UpdateProfile_774592; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing room profile by room profile ARN.
  ## 
  let valid = call_774604.validator(path, query, header, formData, body)
  let scheme = call_774604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774604.url(scheme.get, call_774604.host, call_774604.base,
                         call_774604.route, valid.getOrDefault("path"))
  result = hook(call_774604, url, valid)

proc call*(call_774605: Call_UpdateProfile_774592; body: JsonNode): Recallable =
  ## updateProfile
  ## Updates an existing room profile by room profile ARN.
  ##   body: JObject (required)
  var body_774606 = newJObject()
  if body != nil:
    body_774606 = body
  result = call_774605.call(nil, nil, nil, nil, body_774606)

var updateProfile* = Call_UpdateProfile_774592(name: "updateProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateProfile",
    validator: validate_UpdateProfile_774593, base: "/", url: url_UpdateProfile_774594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoom_774607 = ref object of OpenApiRestCall_772597
proc url_UpdateRoom_774609(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateRoom_774608(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774610 = header.getOrDefault("X-Amz-Date")
  valid_774610 = validateParameter(valid_774610, JString, required = false,
                                 default = nil)
  if valid_774610 != nil:
    section.add "X-Amz-Date", valid_774610
  var valid_774611 = header.getOrDefault("X-Amz-Security-Token")
  valid_774611 = validateParameter(valid_774611, JString, required = false,
                                 default = nil)
  if valid_774611 != nil:
    section.add "X-Amz-Security-Token", valid_774611
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774612 = header.getOrDefault("X-Amz-Target")
  valid_774612 = validateParameter(valid_774612, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateRoom"))
  if valid_774612 != nil:
    section.add "X-Amz-Target", valid_774612
  var valid_774613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774613 = validateParameter(valid_774613, JString, required = false,
                                 default = nil)
  if valid_774613 != nil:
    section.add "X-Amz-Content-Sha256", valid_774613
  var valid_774614 = header.getOrDefault("X-Amz-Algorithm")
  valid_774614 = validateParameter(valid_774614, JString, required = false,
                                 default = nil)
  if valid_774614 != nil:
    section.add "X-Amz-Algorithm", valid_774614
  var valid_774615 = header.getOrDefault("X-Amz-Signature")
  valid_774615 = validateParameter(valid_774615, JString, required = false,
                                 default = nil)
  if valid_774615 != nil:
    section.add "X-Amz-Signature", valid_774615
  var valid_774616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774616 = validateParameter(valid_774616, JString, required = false,
                                 default = nil)
  if valid_774616 != nil:
    section.add "X-Amz-SignedHeaders", valid_774616
  var valid_774617 = header.getOrDefault("X-Amz-Credential")
  valid_774617 = validateParameter(valid_774617, JString, required = false,
                                 default = nil)
  if valid_774617 != nil:
    section.add "X-Amz-Credential", valid_774617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774619: Call_UpdateRoom_774607; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room details by room ARN.
  ## 
  let valid = call_774619.validator(path, query, header, formData, body)
  let scheme = call_774619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774619.url(scheme.get, call_774619.host, call_774619.base,
                         call_774619.route, valid.getOrDefault("path"))
  result = hook(call_774619, url, valid)

proc call*(call_774620: Call_UpdateRoom_774607; body: JsonNode): Recallable =
  ## updateRoom
  ## Updates room details by room ARN.
  ##   body: JObject (required)
  var body_774621 = newJObject()
  if body != nil:
    body_774621 = body
  result = call_774620.call(nil, nil, nil, nil, body_774621)

var updateRoom* = Call_UpdateRoom_774607(name: "updateRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.UpdateRoom",
                                      validator: validate_UpdateRoom_774608,
                                      base: "/", url: url_UpdateRoom_774609,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSkillGroup_774622 = ref object of OpenApiRestCall_772597
proc url_UpdateSkillGroup_774624(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateSkillGroup_774623(path: JsonNode; query: JsonNode;
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
  var valid_774625 = header.getOrDefault("X-Amz-Date")
  valid_774625 = validateParameter(valid_774625, JString, required = false,
                                 default = nil)
  if valid_774625 != nil:
    section.add "X-Amz-Date", valid_774625
  var valid_774626 = header.getOrDefault("X-Amz-Security-Token")
  valid_774626 = validateParameter(valid_774626, JString, required = false,
                                 default = nil)
  if valid_774626 != nil:
    section.add "X-Amz-Security-Token", valid_774626
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774627 = header.getOrDefault("X-Amz-Target")
  valid_774627 = validateParameter(valid_774627, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateSkillGroup"))
  if valid_774627 != nil:
    section.add "X-Amz-Target", valid_774627
  var valid_774628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774628 = validateParameter(valid_774628, JString, required = false,
                                 default = nil)
  if valid_774628 != nil:
    section.add "X-Amz-Content-Sha256", valid_774628
  var valid_774629 = header.getOrDefault("X-Amz-Algorithm")
  valid_774629 = validateParameter(valid_774629, JString, required = false,
                                 default = nil)
  if valid_774629 != nil:
    section.add "X-Amz-Algorithm", valid_774629
  var valid_774630 = header.getOrDefault("X-Amz-Signature")
  valid_774630 = validateParameter(valid_774630, JString, required = false,
                                 default = nil)
  if valid_774630 != nil:
    section.add "X-Amz-Signature", valid_774630
  var valid_774631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774631 = validateParameter(valid_774631, JString, required = false,
                                 default = nil)
  if valid_774631 != nil:
    section.add "X-Amz-SignedHeaders", valid_774631
  var valid_774632 = header.getOrDefault("X-Amz-Credential")
  valid_774632 = validateParameter(valid_774632, JString, required = false,
                                 default = nil)
  if valid_774632 != nil:
    section.add "X-Amz-Credential", valid_774632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774634: Call_UpdateSkillGroup_774622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates skill group details by skill group ARN.
  ## 
  let valid = call_774634.validator(path, query, header, formData, body)
  let scheme = call_774634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774634.url(scheme.get, call_774634.host, call_774634.base,
                         call_774634.route, valid.getOrDefault("path"))
  result = hook(call_774634, url, valid)

proc call*(call_774635: Call_UpdateSkillGroup_774622; body: JsonNode): Recallable =
  ## updateSkillGroup
  ## Updates skill group details by skill group ARN.
  ##   body: JObject (required)
  var body_774636 = newJObject()
  if body != nil:
    body_774636 = body
  result = call_774635.call(nil, nil, nil, nil, body_774636)

var updateSkillGroup* = Call_UpdateSkillGroup_774622(name: "updateSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateSkillGroup",
    validator: validate_UpdateSkillGroup_774623, base: "/",
    url: url_UpdateSkillGroup_774624, schemes: {Scheme.Https, Scheme.Http})
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
