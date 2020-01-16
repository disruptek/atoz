
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  Call_ApproveSkill_605927 = ref object of OpenApiRestCall_605589
proc url_ApproveSkill_605929(protocol: Scheme; host: string; base: string;
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

proc validate_ApproveSkill_605928(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "AlexaForBusiness.ApproveSkill"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_ApproveSkill_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill with the organization under the customer's AWS account. If a skill is private, the user implicitly accepts access to this skill during enablement.
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_ApproveSkill_605927; body: JsonNode): Recallable =
  ## approveSkill
  ## Associates a skill with the organization under the customer's AWS account. If a skill is private, the user implicitly accepts access to this skill during enablement.
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var approveSkill* = Call_ApproveSkill_605927(name: "approveSkill",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ApproveSkill",
    validator: validate_ApproveSkill_605928, base: "/", url: url_ApproveSkill_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateContactWithAddressBook_606196 = ref object of OpenApiRestCall_605589
proc url_AssociateContactWithAddressBook_606198(protocol: Scheme; host: string;
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

proc validate_AssociateContactWithAddressBook_606197(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateContactWithAddressBook"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_AssociateContactWithAddressBook_606196;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a contact with a given address book.
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_AssociateContactWithAddressBook_606196; body: JsonNode): Recallable =
  ## associateContactWithAddressBook
  ## Associates a contact with a given address book.
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var associateContactWithAddressBook* = Call_AssociateContactWithAddressBook_606196(
    name: "associateContactWithAddressBook", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateContactWithAddressBook",
    validator: validate_AssociateContactWithAddressBook_606197, base: "/",
    url: url_AssociateContactWithAddressBook_606198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateDeviceWithNetworkProfile_606211 = ref object of OpenApiRestCall_605589
proc url_AssociateDeviceWithNetworkProfile_606213(protocol: Scheme; host: string;
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

proc validate_AssociateDeviceWithNetworkProfile_606212(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateDeviceWithNetworkProfile"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_AssociateDeviceWithNetworkProfile_606211;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a device with the specified network profile.
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_AssociateDeviceWithNetworkProfile_606211;
          body: JsonNode): Recallable =
  ## associateDeviceWithNetworkProfile
  ## Associates a device with the specified network profile.
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var associateDeviceWithNetworkProfile* = Call_AssociateDeviceWithNetworkProfile_606211(
    name: "associateDeviceWithNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateDeviceWithNetworkProfile",
    validator: validate_AssociateDeviceWithNetworkProfile_606212, base: "/",
    url: url_AssociateDeviceWithNetworkProfile_606213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateDeviceWithRoom_606226 = ref object of OpenApiRestCall_605589
proc url_AssociateDeviceWithRoom_606228(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateDeviceWithRoom_606227(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateDeviceWithRoom"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_AssociateDeviceWithRoom_606226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a device with a given room. This applies all the settings from the room profile to the device, and all the skills in any skill groups added to that room. This operation requires the device to be online, or else a manual sync is required. 
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_AssociateDeviceWithRoom_606226; body: JsonNode): Recallable =
  ## associateDeviceWithRoom
  ## Associates a device with a given room. This applies all the settings from the room profile to the device, and all the skills in any skill groups added to that room. This operation requires the device to be online, or else a manual sync is required. 
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var associateDeviceWithRoom* = Call_AssociateDeviceWithRoom_606226(
    name: "associateDeviceWithRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateDeviceWithRoom",
    validator: validate_AssociateDeviceWithRoom_606227, base: "/",
    url: url_AssociateDeviceWithRoom_606228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillGroupWithRoom_606241 = ref object of OpenApiRestCall_605589
proc url_AssociateSkillGroupWithRoom_606243(protocol: Scheme; host: string;
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

proc validate_AssociateSkillGroupWithRoom_606242(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillGroupWithRoom"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_AssociateSkillGroupWithRoom_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill group with a given room. This enables all skills in the associated skill group on all devices in the room.
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_AssociateSkillGroupWithRoom_606241; body: JsonNode): Recallable =
  ## associateSkillGroupWithRoom
  ## Associates a skill group with a given room. This enables all skills in the associated skill group on all devices in the room.
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var associateSkillGroupWithRoom* = Call_AssociateSkillGroupWithRoom_606241(
    name: "associateSkillGroupWithRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillGroupWithRoom",
    validator: validate_AssociateSkillGroupWithRoom_606242, base: "/",
    url: url_AssociateSkillGroupWithRoom_606243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillWithSkillGroup_606256 = ref object of OpenApiRestCall_605589
proc url_AssociateSkillWithSkillGroup_606258(protocol: Scheme; host: string;
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

proc validate_AssociateSkillWithSkillGroup_606257(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillWithSkillGroup"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_AssociateSkillWithSkillGroup_606256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill with a skill group.
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_AssociateSkillWithSkillGroup_606256; body: JsonNode): Recallable =
  ## associateSkillWithSkillGroup
  ## Associates a skill with a skill group.
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var associateSkillWithSkillGroup* = Call_AssociateSkillWithSkillGroup_606256(
    name: "associateSkillWithSkillGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillWithSkillGroup",
    validator: validate_AssociateSkillWithSkillGroup_606257, base: "/",
    url: url_AssociateSkillWithSkillGroup_606258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillWithUsers_606271 = ref object of OpenApiRestCall_605589
proc url_AssociateSkillWithUsers_606273(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateSkillWithUsers_606272(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillWithUsers"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_AssociateSkillWithUsers_606271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Makes a private skill available for enrolled users to enable on their devices.
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_AssociateSkillWithUsers_606271; body: JsonNode): Recallable =
  ## associateSkillWithUsers
  ## Makes a private skill available for enrolled users to enable on their devices.
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var associateSkillWithUsers* = Call_AssociateSkillWithUsers_606271(
    name: "associateSkillWithUsers", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillWithUsers",
    validator: validate_AssociateSkillWithUsers_606272, base: "/",
    url: url_AssociateSkillWithUsers_606273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAddressBook_606286 = ref object of OpenApiRestCall_605589
proc url_CreateAddressBook_606288(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAddressBook_606287(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateAddressBook"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_CreateAddressBook_606286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an address book with the specified details.
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_CreateAddressBook_606286; body: JsonNode): Recallable =
  ## createAddressBook
  ## Creates an address book with the specified details.
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var createAddressBook* = Call_CreateAddressBook_606286(name: "createAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateAddressBook",
    validator: validate_CreateAddressBook_606287, base: "/",
    url: url_CreateAddressBook_606288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBusinessReportSchedule_606301 = ref object of OpenApiRestCall_605589
proc url_CreateBusinessReportSchedule_606303(protocol: Scheme; host: string;
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

proc validate_CreateBusinessReportSchedule_606302(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606304 = header.getOrDefault("X-Amz-Target")
  valid_606304 = validateParameter(valid_606304, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateBusinessReportSchedule"))
  if valid_606304 != nil:
    section.add "X-Amz-Target", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Signature")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Signature", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Content-Sha256", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Date")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Date", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Credential")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Credential", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Security-Token")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Security-Token", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Algorithm")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Algorithm", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-SignedHeaders", valid_606311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606313: Call_CreateBusinessReportSchedule_606301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a recurring schedule for usage reports to deliver to the specified S3 location with a specified daily or weekly interval.
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_CreateBusinessReportSchedule_606301; body: JsonNode): Recallable =
  ## createBusinessReportSchedule
  ## Creates a recurring schedule for usage reports to deliver to the specified S3 location with a specified daily or weekly interval.
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var createBusinessReportSchedule* = Call_CreateBusinessReportSchedule_606301(
    name: "createBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateBusinessReportSchedule",
    validator: validate_CreateBusinessReportSchedule_606302, base: "/",
    url: url_CreateBusinessReportSchedule_606303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConferenceProvider_606316 = ref object of OpenApiRestCall_605589
proc url_CreateConferenceProvider_606318(protocol: Scheme; host: string;
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

proc validate_CreateConferenceProvider_606317(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606319 = header.getOrDefault("X-Amz-Target")
  valid_606319 = validateParameter(valid_606319, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateConferenceProvider"))
  if valid_606319 != nil:
    section.add "X-Amz-Target", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Signature")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Signature", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Content-Sha256", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Date")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Date", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Credential")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Credential", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Security-Token")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Security-Token", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Algorithm")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Algorithm", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-SignedHeaders", valid_606326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606328: Call_CreateConferenceProvider_606316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new conference provider under the user's AWS account.
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_CreateConferenceProvider_606316; body: JsonNode): Recallable =
  ## createConferenceProvider
  ## Adds a new conference provider under the user's AWS account.
  ##   body: JObject (required)
  var body_606330 = newJObject()
  if body != nil:
    body_606330 = body
  result = call_606329.call(nil, nil, nil, nil, body_606330)

var createConferenceProvider* = Call_CreateConferenceProvider_606316(
    name: "createConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateConferenceProvider",
    validator: validate_CreateConferenceProvider_606317, base: "/",
    url: url_CreateConferenceProvider_606318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateContact_606331 = ref object of OpenApiRestCall_605589
proc url_CreateContact_606333(protocol: Scheme; host: string; base: string;
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

proc validate_CreateContact_606332(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606334 = header.getOrDefault("X-Amz-Target")
  valid_606334 = validateParameter(valid_606334, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateContact"))
  if valid_606334 != nil:
    section.add "X-Amz-Target", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_CreateContact_606331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a contact with the specified details.
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_CreateContact_606331; body: JsonNode): Recallable =
  ## createContact
  ## Creates a contact with the specified details.
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var createContact* = Call_CreateContact_606331(name: "createContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateContact",
    validator: validate_CreateContact_606332, base: "/", url: url_CreateContact_606333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGatewayGroup_606346 = ref object of OpenApiRestCall_605589
proc url_CreateGatewayGroup_606348(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGatewayGroup_606347(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606349 = header.getOrDefault("X-Amz-Target")
  valid_606349 = validateParameter(valid_606349, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateGatewayGroup"))
  if valid_606349 != nil:
    section.add "X-Amz-Target", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606358: Call_CreateGatewayGroup_606346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a gateway group with the specified details.
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_CreateGatewayGroup_606346; body: JsonNode): Recallable =
  ## createGatewayGroup
  ## Creates a gateway group with the specified details.
  ##   body: JObject (required)
  var body_606360 = newJObject()
  if body != nil:
    body_606360 = body
  result = call_606359.call(nil, nil, nil, nil, body_606360)

var createGatewayGroup* = Call_CreateGatewayGroup_606346(
    name: "createGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateGatewayGroup",
    validator: validate_CreateGatewayGroup_606347, base: "/",
    url: url_CreateGatewayGroup_606348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_606361 = ref object of OpenApiRestCall_605589
proc url_CreateNetworkProfile_606363(protocol: Scheme; host: string; base: string;
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

proc validate_CreateNetworkProfile_606362(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606364 = header.getOrDefault("X-Amz-Target")
  valid_606364 = validateParameter(valid_606364, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateNetworkProfile"))
  if valid_606364 != nil:
    section.add "X-Amz-Target", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Signature")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Signature", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Content-Sha256", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Date")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Date", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Credential")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Credential", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Security-Token")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Security-Token", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Algorithm")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Algorithm", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-SignedHeaders", valid_606371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606373: Call_CreateNetworkProfile_606361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a network profile with the specified details.
  ## 
  let valid = call_606373.validator(path, query, header, formData, body)
  let scheme = call_606373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606373.url(scheme.get, call_606373.host, call_606373.base,
                         call_606373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606373, url, valid)

proc call*(call_606374: Call_CreateNetworkProfile_606361; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile with the specified details.
  ##   body: JObject (required)
  var body_606375 = newJObject()
  if body != nil:
    body_606375 = body
  result = call_606374.call(nil, nil, nil, nil, body_606375)

var createNetworkProfile* = Call_CreateNetworkProfile_606361(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_606362, base: "/",
    url: url_CreateNetworkProfile_606363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProfile_606376 = ref object of OpenApiRestCall_605589
proc url_CreateProfile_606378(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProfile_606377(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606379 = header.getOrDefault("X-Amz-Target")
  valid_606379 = validateParameter(valid_606379, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateProfile"))
  if valid_606379 != nil:
    section.add "X-Amz-Target", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Signature")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Signature", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Content-Sha256", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Date")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Date", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Credential")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Credential", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Security-Token")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Security-Token", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Algorithm")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Algorithm", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-SignedHeaders", valid_606386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_CreateProfile_606376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new room profile with the specified details.
  ## 
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_CreateProfile_606376; body: JsonNode): Recallable =
  ## createProfile
  ## Creates a new room profile with the specified details.
  ##   body: JObject (required)
  var body_606390 = newJObject()
  if body != nil:
    body_606390 = body
  result = call_606389.call(nil, nil, nil, nil, body_606390)

var createProfile* = Call_CreateProfile_606376(name: "createProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateProfile",
    validator: validate_CreateProfile_606377, base: "/", url: url_CreateProfile_606378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoom_606391 = ref object of OpenApiRestCall_605589
proc url_CreateRoom_606393(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateRoom_606392(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606394 = header.getOrDefault("X-Amz-Target")
  valid_606394 = validateParameter(valid_606394, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateRoom"))
  if valid_606394 != nil:
    section.add "X-Amz-Target", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Signature")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Signature", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Content-Sha256", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Date")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Date", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Credential")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Credential", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Security-Token")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Security-Token", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Algorithm")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Algorithm", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-SignedHeaders", valid_606401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606403: Call_CreateRoom_606391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a room with the specified details.
  ## 
  let valid = call_606403.validator(path, query, header, formData, body)
  let scheme = call_606403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606403.url(scheme.get, call_606403.host, call_606403.base,
                         call_606403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606403, url, valid)

proc call*(call_606404: Call_CreateRoom_606391; body: JsonNode): Recallable =
  ## createRoom
  ## Creates a room with the specified details.
  ##   body: JObject (required)
  var body_606405 = newJObject()
  if body != nil:
    body_606405 = body
  result = call_606404.call(nil, nil, nil, nil, body_606405)

var createRoom* = Call_CreateRoom_606391(name: "createRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.CreateRoom",
                                      validator: validate_CreateRoom_606392,
                                      base: "/", url: url_CreateRoom_606393,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSkillGroup_606406 = ref object of OpenApiRestCall_605589
proc url_CreateSkillGroup_606408(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSkillGroup_606407(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606409 = header.getOrDefault("X-Amz-Target")
  valid_606409 = validateParameter(valid_606409, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateSkillGroup"))
  if valid_606409 != nil:
    section.add "X-Amz-Target", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Signature")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Signature", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Content-Sha256", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Date")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Date", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Credential")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Credential", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Security-Token")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Security-Token", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Algorithm")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Algorithm", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-SignedHeaders", valid_606416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606418: Call_CreateSkillGroup_606406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a skill group with a specified name and description.
  ## 
  let valid = call_606418.validator(path, query, header, formData, body)
  let scheme = call_606418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606418.url(scheme.get, call_606418.host, call_606418.base,
                         call_606418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606418, url, valid)

proc call*(call_606419: Call_CreateSkillGroup_606406; body: JsonNode): Recallable =
  ## createSkillGroup
  ## Creates a skill group with a specified name and description.
  ##   body: JObject (required)
  var body_606420 = newJObject()
  if body != nil:
    body_606420 = body
  result = call_606419.call(nil, nil, nil, nil, body_606420)

var createSkillGroup* = Call_CreateSkillGroup_606406(name: "createSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateSkillGroup",
    validator: validate_CreateSkillGroup_606407, base: "/",
    url: url_CreateSkillGroup_606408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_606421 = ref object of OpenApiRestCall_605589
proc url_CreateUser_606423(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateUser_606422(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606424 = header.getOrDefault("X-Amz-Target")
  valid_606424 = validateParameter(valid_606424, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateUser"))
  if valid_606424 != nil:
    section.add "X-Amz-Target", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Signature")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Signature", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Content-Sha256", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Date")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Date", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Credential")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Credential", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Security-Token")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Security-Token", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Algorithm")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Algorithm", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-SignedHeaders", valid_606431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606433: Call_CreateUser_606421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user.
  ## 
  let valid = call_606433.validator(path, query, header, formData, body)
  let scheme = call_606433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606433.url(scheme.get, call_606433.host, call_606433.base,
                         call_606433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606433, url, valid)

proc call*(call_606434: Call_CreateUser_606421; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user.
  ##   body: JObject (required)
  var body_606435 = newJObject()
  if body != nil:
    body_606435 = body
  result = call_606434.call(nil, nil, nil, nil, body_606435)

var createUser* = Call_CreateUser_606421(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.CreateUser",
                                      validator: validate_CreateUser_606422,
                                      base: "/", url: url_CreateUser_606423,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAddressBook_606436 = ref object of OpenApiRestCall_605589
proc url_DeleteAddressBook_606438(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAddressBook_606437(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606439 = header.getOrDefault("X-Amz-Target")
  valid_606439 = validateParameter(valid_606439, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteAddressBook"))
  if valid_606439 != nil:
    section.add "X-Amz-Target", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Signature")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Signature", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Content-Sha256", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Date")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Date", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Credential")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Credential", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Security-Token")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Security-Token", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Algorithm")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Algorithm", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-SignedHeaders", valid_606446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606448: Call_DeleteAddressBook_606436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an address book by the address book ARN.
  ## 
  let valid = call_606448.validator(path, query, header, formData, body)
  let scheme = call_606448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606448.url(scheme.get, call_606448.host, call_606448.base,
                         call_606448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606448, url, valid)

proc call*(call_606449: Call_DeleteAddressBook_606436; body: JsonNode): Recallable =
  ## deleteAddressBook
  ## Deletes an address book by the address book ARN.
  ##   body: JObject (required)
  var body_606450 = newJObject()
  if body != nil:
    body_606450 = body
  result = call_606449.call(nil, nil, nil, nil, body_606450)

var deleteAddressBook* = Call_DeleteAddressBook_606436(name: "deleteAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteAddressBook",
    validator: validate_DeleteAddressBook_606437, base: "/",
    url: url_DeleteAddressBook_606438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBusinessReportSchedule_606451 = ref object of OpenApiRestCall_605589
proc url_DeleteBusinessReportSchedule_606453(protocol: Scheme; host: string;
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

proc validate_DeleteBusinessReportSchedule_606452(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606454 = header.getOrDefault("X-Amz-Target")
  valid_606454 = validateParameter(valid_606454, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteBusinessReportSchedule"))
  if valid_606454 != nil:
    section.add "X-Amz-Target", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Signature")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Signature", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Content-Sha256", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Date")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Date", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Credential")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Credential", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Security-Token")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Security-Token", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Algorithm")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Algorithm", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-SignedHeaders", valid_606461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606463: Call_DeleteBusinessReportSchedule_606451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the recurring report delivery schedule with the specified schedule ARN.
  ## 
  let valid = call_606463.validator(path, query, header, formData, body)
  let scheme = call_606463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606463.url(scheme.get, call_606463.host, call_606463.base,
                         call_606463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606463, url, valid)

proc call*(call_606464: Call_DeleteBusinessReportSchedule_606451; body: JsonNode): Recallable =
  ## deleteBusinessReportSchedule
  ## Deletes the recurring report delivery schedule with the specified schedule ARN.
  ##   body: JObject (required)
  var body_606465 = newJObject()
  if body != nil:
    body_606465 = body
  result = call_606464.call(nil, nil, nil, nil, body_606465)

var deleteBusinessReportSchedule* = Call_DeleteBusinessReportSchedule_606451(
    name: "deleteBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteBusinessReportSchedule",
    validator: validate_DeleteBusinessReportSchedule_606452, base: "/",
    url: url_DeleteBusinessReportSchedule_606453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConferenceProvider_606466 = ref object of OpenApiRestCall_605589
proc url_DeleteConferenceProvider_606468(protocol: Scheme; host: string;
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

proc validate_DeleteConferenceProvider_606467(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606469 = header.getOrDefault("X-Amz-Target")
  valid_606469 = validateParameter(valid_606469, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteConferenceProvider"))
  if valid_606469 != nil:
    section.add "X-Amz-Target", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Signature")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Signature", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Content-Sha256", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Date")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Date", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Credential")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Credential", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Security-Token")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Security-Token", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Algorithm")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Algorithm", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-SignedHeaders", valid_606476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606478: Call_DeleteConferenceProvider_606466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a conference provider.
  ## 
  let valid = call_606478.validator(path, query, header, formData, body)
  let scheme = call_606478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606478.url(scheme.get, call_606478.host, call_606478.base,
                         call_606478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606478, url, valid)

proc call*(call_606479: Call_DeleteConferenceProvider_606466; body: JsonNode): Recallable =
  ## deleteConferenceProvider
  ## Deletes a conference provider.
  ##   body: JObject (required)
  var body_606480 = newJObject()
  if body != nil:
    body_606480 = body
  result = call_606479.call(nil, nil, nil, nil, body_606480)

var deleteConferenceProvider* = Call_DeleteConferenceProvider_606466(
    name: "deleteConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteConferenceProvider",
    validator: validate_DeleteConferenceProvider_606467, base: "/",
    url: url_DeleteConferenceProvider_606468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteContact_606481 = ref object of OpenApiRestCall_605589
proc url_DeleteContact_606483(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteContact_606482(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606484 = header.getOrDefault("X-Amz-Target")
  valid_606484 = validateParameter(valid_606484, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteContact"))
  if valid_606484 != nil:
    section.add "X-Amz-Target", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Signature")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Signature", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Content-Sha256", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Date")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Date", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Credential")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Credential", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Security-Token")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Security-Token", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Algorithm")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Algorithm", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-SignedHeaders", valid_606491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606493: Call_DeleteContact_606481; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a contact by the contact ARN.
  ## 
  let valid = call_606493.validator(path, query, header, formData, body)
  let scheme = call_606493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606493.url(scheme.get, call_606493.host, call_606493.base,
                         call_606493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606493, url, valid)

proc call*(call_606494: Call_DeleteContact_606481; body: JsonNode): Recallable =
  ## deleteContact
  ## Deletes a contact by the contact ARN.
  ##   body: JObject (required)
  var body_606495 = newJObject()
  if body != nil:
    body_606495 = body
  result = call_606494.call(nil, nil, nil, nil, body_606495)

var deleteContact* = Call_DeleteContact_606481(name: "deleteContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteContact",
    validator: validate_DeleteContact_606482, base: "/", url: url_DeleteContact_606483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevice_606496 = ref object of OpenApiRestCall_605589
proc url_DeleteDevice_606498(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDevice_606497(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606499 = header.getOrDefault("X-Amz-Target")
  valid_606499 = validateParameter(valid_606499, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteDevice"))
  if valid_606499 != nil:
    section.add "X-Amz-Target", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Signature")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Signature", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Content-Sha256", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Date")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Date", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Credential")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Credential", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Security-Token")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Security-Token", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Algorithm")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Algorithm", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-SignedHeaders", valid_606506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606508: Call_DeleteDevice_606496; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a device from Alexa For Business.
  ## 
  let valid = call_606508.validator(path, query, header, formData, body)
  let scheme = call_606508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606508.url(scheme.get, call_606508.host, call_606508.base,
                         call_606508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606508, url, valid)

proc call*(call_606509: Call_DeleteDevice_606496; body: JsonNode): Recallable =
  ## deleteDevice
  ## Removes a device from Alexa For Business.
  ##   body: JObject (required)
  var body_606510 = newJObject()
  if body != nil:
    body_606510 = body
  result = call_606509.call(nil, nil, nil, nil, body_606510)

var deleteDevice* = Call_DeleteDevice_606496(name: "deleteDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteDevice",
    validator: validate_DeleteDevice_606497, base: "/", url: url_DeleteDevice_606498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceUsageData_606511 = ref object of OpenApiRestCall_605589
proc url_DeleteDeviceUsageData_606513(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeviceUsageData_606512(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606514 = header.getOrDefault("X-Amz-Target")
  valid_606514 = validateParameter(valid_606514, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteDeviceUsageData"))
  if valid_606514 != nil:
    section.add "X-Amz-Target", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Signature")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Signature", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Content-Sha256", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Date")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Date", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Credential")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Credential", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Security-Token")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Security-Token", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Algorithm")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Algorithm", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-SignedHeaders", valid_606521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606523: Call_DeleteDeviceUsageData_606511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## When this action is called for a specified shared device, it allows authorized users to delete the device's entire previous history of voice input data and associated response data. This action can be called once every 24 hours for a specific shared device.
  ## 
  let valid = call_606523.validator(path, query, header, formData, body)
  let scheme = call_606523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606523.url(scheme.get, call_606523.host, call_606523.base,
                         call_606523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606523, url, valid)

proc call*(call_606524: Call_DeleteDeviceUsageData_606511; body: JsonNode): Recallable =
  ## deleteDeviceUsageData
  ## When this action is called for a specified shared device, it allows authorized users to delete the device's entire previous history of voice input data and associated response data. This action can be called once every 24 hours for a specific shared device.
  ##   body: JObject (required)
  var body_606525 = newJObject()
  if body != nil:
    body_606525 = body
  result = call_606524.call(nil, nil, nil, nil, body_606525)

var deleteDeviceUsageData* = Call_DeleteDeviceUsageData_606511(
    name: "deleteDeviceUsageData", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteDeviceUsageData",
    validator: validate_DeleteDeviceUsageData_606512, base: "/",
    url: url_DeleteDeviceUsageData_606513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayGroup_606526 = ref object of OpenApiRestCall_605589
proc url_DeleteGatewayGroup_606528(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGatewayGroup_606527(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606529 = header.getOrDefault("X-Amz-Target")
  valid_606529 = validateParameter(valid_606529, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteGatewayGroup"))
  if valid_606529 != nil:
    section.add "X-Amz-Target", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Signature")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Signature", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Content-Sha256", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Date")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Date", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Credential")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Credential", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Security-Token")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Security-Token", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Algorithm")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Algorithm", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-SignedHeaders", valid_606536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606538: Call_DeleteGatewayGroup_606526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a gateway group.
  ## 
  let valid = call_606538.validator(path, query, header, formData, body)
  let scheme = call_606538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606538.url(scheme.get, call_606538.host, call_606538.base,
                         call_606538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606538, url, valid)

proc call*(call_606539: Call_DeleteGatewayGroup_606526; body: JsonNode): Recallable =
  ## deleteGatewayGroup
  ## Deletes a gateway group.
  ##   body: JObject (required)
  var body_606540 = newJObject()
  if body != nil:
    body_606540 = body
  result = call_606539.call(nil, nil, nil, nil, body_606540)

var deleteGatewayGroup* = Call_DeleteGatewayGroup_606526(
    name: "deleteGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteGatewayGroup",
    validator: validate_DeleteGatewayGroup_606527, base: "/",
    url: url_DeleteGatewayGroup_606528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_606541 = ref object of OpenApiRestCall_605589
proc url_DeleteNetworkProfile_606543(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteNetworkProfile_606542(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606544 = header.getOrDefault("X-Amz-Target")
  valid_606544 = validateParameter(valid_606544, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteNetworkProfile"))
  if valid_606544 != nil:
    section.add "X-Amz-Target", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Signature")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Signature", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Content-Sha256", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Date")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Date", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Credential")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Credential", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Security-Token")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Security-Token", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Algorithm")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Algorithm", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-SignedHeaders", valid_606551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606553: Call_DeleteNetworkProfile_606541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a network profile by the network profile ARN.
  ## 
  let valid = call_606553.validator(path, query, header, formData, body)
  let scheme = call_606553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606553.url(scheme.get, call_606553.host, call_606553.base,
                         call_606553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606553, url, valid)

proc call*(call_606554: Call_DeleteNetworkProfile_606541; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile by the network profile ARN.
  ##   body: JObject (required)
  var body_606555 = newJObject()
  if body != nil:
    body_606555 = body
  result = call_606554.call(nil, nil, nil, nil, body_606555)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_606541(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_606542, base: "/",
    url: url_DeleteNetworkProfile_606543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProfile_606556 = ref object of OpenApiRestCall_605589
proc url_DeleteProfile_606558(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteProfile_606557(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606559 = header.getOrDefault("X-Amz-Target")
  valid_606559 = validateParameter(valid_606559, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteProfile"))
  if valid_606559 != nil:
    section.add "X-Amz-Target", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Signature")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Signature", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Content-Sha256", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Date")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Date", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Credential")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Credential", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Security-Token")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Security-Token", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Algorithm")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Algorithm", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-SignedHeaders", valid_606566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606568: Call_DeleteProfile_606556; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a room profile by the profile ARN.
  ## 
  let valid = call_606568.validator(path, query, header, formData, body)
  let scheme = call_606568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606568.url(scheme.get, call_606568.host, call_606568.base,
                         call_606568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606568, url, valid)

proc call*(call_606569: Call_DeleteProfile_606556; body: JsonNode): Recallable =
  ## deleteProfile
  ## Deletes a room profile by the profile ARN.
  ##   body: JObject (required)
  var body_606570 = newJObject()
  if body != nil:
    body_606570 = body
  result = call_606569.call(nil, nil, nil, nil, body_606570)

var deleteProfile* = Call_DeleteProfile_606556(name: "deleteProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteProfile",
    validator: validate_DeleteProfile_606557, base: "/", url: url_DeleteProfile_606558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoom_606571 = ref object of OpenApiRestCall_605589
proc url_DeleteRoom_606573(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteRoom_606572(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606574 = header.getOrDefault("X-Amz-Target")
  valid_606574 = validateParameter(valid_606574, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteRoom"))
  if valid_606574 != nil:
    section.add "X-Amz-Target", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Signature")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Signature", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Content-Sha256", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Date")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Date", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Credential")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Credential", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Security-Token")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Security-Token", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Algorithm")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Algorithm", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-SignedHeaders", valid_606581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606583: Call_DeleteRoom_606571; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a room by the room ARN.
  ## 
  let valid = call_606583.validator(path, query, header, formData, body)
  let scheme = call_606583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606583.url(scheme.get, call_606583.host, call_606583.base,
                         call_606583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606583, url, valid)

proc call*(call_606584: Call_DeleteRoom_606571; body: JsonNode): Recallable =
  ## deleteRoom
  ## Deletes a room by the room ARN.
  ##   body: JObject (required)
  var body_606585 = newJObject()
  if body != nil:
    body_606585 = body
  result = call_606584.call(nil, nil, nil, nil, body_606585)

var deleteRoom* = Call_DeleteRoom_606571(name: "deleteRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DeleteRoom",
                                      validator: validate_DeleteRoom_606572,
                                      base: "/", url: url_DeleteRoom_606573,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoomSkillParameter_606586 = ref object of OpenApiRestCall_605589
proc url_DeleteRoomSkillParameter_606588(protocol: Scheme; host: string;
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

proc validate_DeleteRoomSkillParameter_606587(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606589 = header.getOrDefault("X-Amz-Target")
  valid_606589 = validateParameter(valid_606589, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteRoomSkillParameter"))
  if valid_606589 != nil:
    section.add "X-Amz-Target", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Signature")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Signature", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Content-Sha256", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Date")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Date", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Credential")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Credential", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Security-Token")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Security-Token", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Algorithm")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Algorithm", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-SignedHeaders", valid_606596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606598: Call_DeleteRoomSkillParameter_606586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes room skill parameter details by room, skill, and parameter key ID.
  ## 
  let valid = call_606598.validator(path, query, header, formData, body)
  let scheme = call_606598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606598.url(scheme.get, call_606598.host, call_606598.base,
                         call_606598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606598, url, valid)

proc call*(call_606599: Call_DeleteRoomSkillParameter_606586; body: JsonNode): Recallable =
  ## deleteRoomSkillParameter
  ## Deletes room skill parameter details by room, skill, and parameter key ID.
  ##   body: JObject (required)
  var body_606600 = newJObject()
  if body != nil:
    body_606600 = body
  result = call_606599.call(nil, nil, nil, nil, body_606600)

var deleteRoomSkillParameter* = Call_DeleteRoomSkillParameter_606586(
    name: "deleteRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteRoomSkillParameter",
    validator: validate_DeleteRoomSkillParameter_606587, base: "/",
    url: url_DeleteRoomSkillParameter_606588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSkillAuthorization_606601 = ref object of OpenApiRestCall_605589
proc url_DeleteSkillAuthorization_606603(protocol: Scheme; host: string;
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

proc validate_DeleteSkillAuthorization_606602(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606604 = header.getOrDefault("X-Amz-Target")
  valid_606604 = validateParameter(valid_606604, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteSkillAuthorization"))
  if valid_606604 != nil:
    section.add "X-Amz-Target", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-Signature")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Signature", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Content-Sha256", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-Date")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Date", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-Credential")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Credential", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Security-Token")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Security-Token", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Algorithm")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Algorithm", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-SignedHeaders", valid_606611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606613: Call_DeleteSkillAuthorization_606601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Unlinks a third-party account from a skill.
  ## 
  let valid = call_606613.validator(path, query, header, formData, body)
  let scheme = call_606613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606613.url(scheme.get, call_606613.host, call_606613.base,
                         call_606613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606613, url, valid)

proc call*(call_606614: Call_DeleteSkillAuthorization_606601; body: JsonNode): Recallable =
  ## deleteSkillAuthorization
  ## Unlinks a third-party account from a skill.
  ##   body: JObject (required)
  var body_606615 = newJObject()
  if body != nil:
    body_606615 = body
  result = call_606614.call(nil, nil, nil, nil, body_606615)

var deleteSkillAuthorization* = Call_DeleteSkillAuthorization_606601(
    name: "deleteSkillAuthorization", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteSkillAuthorization",
    validator: validate_DeleteSkillAuthorization_606602, base: "/",
    url: url_DeleteSkillAuthorization_606603, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSkillGroup_606616 = ref object of OpenApiRestCall_605589
proc url_DeleteSkillGroup_606618(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSkillGroup_606617(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606619 = header.getOrDefault("X-Amz-Target")
  valid_606619 = validateParameter(valid_606619, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteSkillGroup"))
  if valid_606619 != nil:
    section.add "X-Amz-Target", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-Signature")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Signature", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Content-Sha256", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Date")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Date", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-Credential")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Credential", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Security-Token")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Security-Token", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Algorithm")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Algorithm", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-SignedHeaders", valid_606626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606628: Call_DeleteSkillGroup_606616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a skill group by skill group ARN.
  ## 
  let valid = call_606628.validator(path, query, header, formData, body)
  let scheme = call_606628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606628.url(scheme.get, call_606628.host, call_606628.base,
                         call_606628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606628, url, valid)

proc call*(call_606629: Call_DeleteSkillGroup_606616; body: JsonNode): Recallable =
  ## deleteSkillGroup
  ## Deletes a skill group by skill group ARN.
  ##   body: JObject (required)
  var body_606630 = newJObject()
  if body != nil:
    body_606630 = body
  result = call_606629.call(nil, nil, nil, nil, body_606630)

var deleteSkillGroup* = Call_DeleteSkillGroup_606616(name: "deleteSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteSkillGroup",
    validator: validate_DeleteSkillGroup_606617, base: "/",
    url: url_DeleteSkillGroup_606618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_606631 = ref object of OpenApiRestCall_605589
proc url_DeleteUser_606633(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_606632(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606634 = header.getOrDefault("X-Amz-Target")
  valid_606634 = validateParameter(valid_606634, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteUser"))
  if valid_606634 != nil:
    section.add "X-Amz-Target", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Signature")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Signature", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Content-Sha256", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Date")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Date", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Credential")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Credential", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Security-Token")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Security-Token", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Algorithm")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Algorithm", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-SignedHeaders", valid_606641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606643: Call_DeleteUser_606631; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified user by user ARN and enrollment ARN.
  ## 
  let valid = call_606643.validator(path, query, header, formData, body)
  let scheme = call_606643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606643.url(scheme.get, call_606643.host, call_606643.base,
                         call_606643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606643, url, valid)

proc call*(call_606644: Call_DeleteUser_606631; body: JsonNode): Recallable =
  ## deleteUser
  ## Deletes a specified user by user ARN and enrollment ARN.
  ##   body: JObject (required)
  var body_606645 = newJObject()
  if body != nil:
    body_606645 = body
  result = call_606644.call(nil, nil, nil, nil, body_606645)

var deleteUser* = Call_DeleteUser_606631(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DeleteUser",
                                      validator: validate_DeleteUser_606632,
                                      base: "/", url: url_DeleteUser_606633,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateContactFromAddressBook_606646 = ref object of OpenApiRestCall_605589
proc url_DisassociateContactFromAddressBook_606648(protocol: Scheme; host: string;
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

proc validate_DisassociateContactFromAddressBook_606647(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606649 = header.getOrDefault("X-Amz-Target")
  valid_606649 = validateParameter(valid_606649, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateContactFromAddressBook"))
  if valid_606649 != nil:
    section.add "X-Amz-Target", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-Signature")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Signature", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Content-Sha256", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Date")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Date", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-Credential")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Credential", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-Security-Token")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Security-Token", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Algorithm")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Algorithm", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-SignedHeaders", valid_606656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606658: Call_DisassociateContactFromAddressBook_606646;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a contact from a given address book.
  ## 
  let valid = call_606658.validator(path, query, header, formData, body)
  let scheme = call_606658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606658.url(scheme.get, call_606658.host, call_606658.base,
                         call_606658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606658, url, valid)

proc call*(call_606659: Call_DisassociateContactFromAddressBook_606646;
          body: JsonNode): Recallable =
  ## disassociateContactFromAddressBook
  ## Disassociates a contact from a given address book.
  ##   body: JObject (required)
  var body_606660 = newJObject()
  if body != nil:
    body_606660 = body
  result = call_606659.call(nil, nil, nil, nil, body_606660)

var disassociateContactFromAddressBook* = Call_DisassociateContactFromAddressBook_606646(
    name: "disassociateContactFromAddressBook", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DisassociateContactFromAddressBook",
    validator: validate_DisassociateContactFromAddressBook_606647, base: "/",
    url: url_DisassociateContactFromAddressBook_606648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDeviceFromRoom_606661 = ref object of OpenApiRestCall_605589
proc url_DisassociateDeviceFromRoom_606663(protocol: Scheme; host: string;
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

proc validate_DisassociateDeviceFromRoom_606662(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606664 = header.getOrDefault("X-Amz-Target")
  valid_606664 = validateParameter(valid_606664, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateDeviceFromRoom"))
  if valid_606664 != nil:
    section.add "X-Amz-Target", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Signature")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Signature", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Content-Sha256", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Date")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Date", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-Credential")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Credential", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Security-Token")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Security-Token", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Algorithm")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Algorithm", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-SignedHeaders", valid_606671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606673: Call_DisassociateDeviceFromRoom_606661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a device from its current room. The device continues to be connected to the Wi-Fi network and is still registered to the account. The device settings and skills are removed from the room.
  ## 
  let valid = call_606673.validator(path, query, header, formData, body)
  let scheme = call_606673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606673.url(scheme.get, call_606673.host, call_606673.base,
                         call_606673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606673, url, valid)

proc call*(call_606674: Call_DisassociateDeviceFromRoom_606661; body: JsonNode): Recallable =
  ## disassociateDeviceFromRoom
  ## Disassociates a device from its current room. The device continues to be connected to the Wi-Fi network and is still registered to the account. The device settings and skills are removed from the room.
  ##   body: JObject (required)
  var body_606675 = newJObject()
  if body != nil:
    body_606675 = body
  result = call_606674.call(nil, nil, nil, nil, body_606675)

var disassociateDeviceFromRoom* = Call_DisassociateDeviceFromRoom_606661(
    name: "disassociateDeviceFromRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateDeviceFromRoom",
    validator: validate_DisassociateDeviceFromRoom_606662, base: "/",
    url: url_DisassociateDeviceFromRoom_606663,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillFromSkillGroup_606676 = ref object of OpenApiRestCall_605589
proc url_DisassociateSkillFromSkillGroup_606678(protocol: Scheme; host: string;
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

proc validate_DisassociateSkillFromSkillGroup_606677(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606679 = header.getOrDefault("X-Amz-Target")
  valid_606679 = validateParameter(valid_606679, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillFromSkillGroup"))
  if valid_606679 != nil:
    section.add "X-Amz-Target", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-Signature")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-Signature", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Content-Sha256", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Date")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Date", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-Credential")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Credential", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Security-Token")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Security-Token", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Algorithm")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Algorithm", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-SignedHeaders", valid_606686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606688: Call_DisassociateSkillFromSkillGroup_606676;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a skill from a skill group.
  ## 
  let valid = call_606688.validator(path, query, header, formData, body)
  let scheme = call_606688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606688.url(scheme.get, call_606688.host, call_606688.base,
                         call_606688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606688, url, valid)

proc call*(call_606689: Call_DisassociateSkillFromSkillGroup_606676; body: JsonNode): Recallable =
  ## disassociateSkillFromSkillGroup
  ## Disassociates a skill from a skill group.
  ##   body: JObject (required)
  var body_606690 = newJObject()
  if body != nil:
    body_606690 = body
  result = call_606689.call(nil, nil, nil, nil, body_606690)

var disassociateSkillFromSkillGroup* = Call_DisassociateSkillFromSkillGroup_606676(
    name: "disassociateSkillFromSkillGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillFromSkillGroup",
    validator: validate_DisassociateSkillFromSkillGroup_606677, base: "/",
    url: url_DisassociateSkillFromSkillGroup_606678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillFromUsers_606691 = ref object of OpenApiRestCall_605589
proc url_DisassociateSkillFromUsers_606693(protocol: Scheme; host: string;
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

proc validate_DisassociateSkillFromUsers_606692(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606694 = header.getOrDefault("X-Amz-Target")
  valid_606694 = validateParameter(valid_606694, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillFromUsers"))
  if valid_606694 != nil:
    section.add "X-Amz-Target", valid_606694
  var valid_606695 = header.getOrDefault("X-Amz-Signature")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-Signature", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Content-Sha256", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-Date")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-Date", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Credential")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Credential", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-Security-Token")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-Security-Token", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-Algorithm")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Algorithm", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-SignedHeaders", valid_606701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606703: Call_DisassociateSkillFromUsers_606691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Makes a private skill unavailable for enrolled users and prevents them from enabling it on their devices.
  ## 
  let valid = call_606703.validator(path, query, header, formData, body)
  let scheme = call_606703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606703.url(scheme.get, call_606703.host, call_606703.base,
                         call_606703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606703, url, valid)

proc call*(call_606704: Call_DisassociateSkillFromUsers_606691; body: JsonNode): Recallable =
  ## disassociateSkillFromUsers
  ## Makes a private skill unavailable for enrolled users and prevents them from enabling it on their devices.
  ##   body: JObject (required)
  var body_606705 = newJObject()
  if body != nil:
    body_606705 = body
  result = call_606704.call(nil, nil, nil, nil, body_606705)

var disassociateSkillFromUsers* = Call_DisassociateSkillFromUsers_606691(
    name: "disassociateSkillFromUsers", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillFromUsers",
    validator: validate_DisassociateSkillFromUsers_606692, base: "/",
    url: url_DisassociateSkillFromUsers_606693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillGroupFromRoom_606706 = ref object of OpenApiRestCall_605589
proc url_DisassociateSkillGroupFromRoom_606708(protocol: Scheme; host: string;
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

proc validate_DisassociateSkillGroupFromRoom_606707(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606709 = header.getOrDefault("X-Amz-Target")
  valid_606709 = validateParameter(valid_606709, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillGroupFromRoom"))
  if valid_606709 != nil:
    section.add "X-Amz-Target", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Signature")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Signature", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Content-Sha256", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Date")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Date", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-Credential")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Credential", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-Security-Token")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Security-Token", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-Algorithm")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-Algorithm", valid_606715
  var valid_606716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606716 = validateParameter(valid_606716, JString, required = false,
                                 default = nil)
  if valid_606716 != nil:
    section.add "X-Amz-SignedHeaders", valid_606716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606718: Call_DisassociateSkillGroupFromRoom_606706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a skill group from a specified room. This disables all skills in the skill group on all devices in the room.
  ## 
  let valid = call_606718.validator(path, query, header, formData, body)
  let scheme = call_606718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606718.url(scheme.get, call_606718.host, call_606718.base,
                         call_606718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606718, url, valid)

proc call*(call_606719: Call_DisassociateSkillGroupFromRoom_606706; body: JsonNode): Recallable =
  ## disassociateSkillGroupFromRoom
  ## Disassociates a skill group from a specified room. This disables all skills in the skill group on all devices in the room.
  ##   body: JObject (required)
  var body_606720 = newJObject()
  if body != nil:
    body_606720 = body
  result = call_606719.call(nil, nil, nil, nil, body_606720)

var disassociateSkillGroupFromRoom* = Call_DisassociateSkillGroupFromRoom_606706(
    name: "disassociateSkillGroupFromRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillGroupFromRoom",
    validator: validate_DisassociateSkillGroupFromRoom_606707, base: "/",
    url: url_DisassociateSkillGroupFromRoom_606708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgetSmartHomeAppliances_606721 = ref object of OpenApiRestCall_605589
proc url_ForgetSmartHomeAppliances_606723(protocol: Scheme; host: string;
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

proc validate_ForgetSmartHomeAppliances_606722(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606724 = header.getOrDefault("X-Amz-Target")
  valid_606724 = validateParameter(valid_606724, JString, required = true, default = newJString(
      "AlexaForBusiness.ForgetSmartHomeAppliances"))
  if valid_606724 != nil:
    section.add "X-Amz-Target", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Signature")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Signature", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Content-Sha256", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-Date")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Date", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-Credential")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-Credential", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-Security-Token")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-Security-Token", valid_606729
  var valid_606730 = header.getOrDefault("X-Amz-Algorithm")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-Algorithm", valid_606730
  var valid_606731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "X-Amz-SignedHeaders", valid_606731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606733: Call_ForgetSmartHomeAppliances_606721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Forgets smart home appliances associated to a room.
  ## 
  let valid = call_606733.validator(path, query, header, formData, body)
  let scheme = call_606733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606733.url(scheme.get, call_606733.host, call_606733.base,
                         call_606733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606733, url, valid)

proc call*(call_606734: Call_ForgetSmartHomeAppliances_606721; body: JsonNode): Recallable =
  ## forgetSmartHomeAppliances
  ## Forgets smart home appliances associated to a room.
  ##   body: JObject (required)
  var body_606735 = newJObject()
  if body != nil:
    body_606735 = body
  result = call_606734.call(nil, nil, nil, nil, body_606735)

var forgetSmartHomeAppliances* = Call_ForgetSmartHomeAppliances_606721(
    name: "forgetSmartHomeAppliances", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ForgetSmartHomeAppliances",
    validator: validate_ForgetSmartHomeAppliances_606722, base: "/",
    url: url_ForgetSmartHomeAppliances_606723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddressBook_606736 = ref object of OpenApiRestCall_605589
proc url_GetAddressBook_606738(protocol: Scheme; host: string; base: string;
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

proc validate_GetAddressBook_606737(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606739 = header.getOrDefault("X-Amz-Target")
  valid_606739 = validateParameter(valid_606739, JString, required = true, default = newJString(
      "AlexaForBusiness.GetAddressBook"))
  if valid_606739 != nil:
    section.add "X-Amz-Target", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-Signature")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-Signature", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-Content-Sha256", valid_606741
  var valid_606742 = header.getOrDefault("X-Amz-Date")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Date", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-Credential")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Credential", valid_606743
  var valid_606744 = header.getOrDefault("X-Amz-Security-Token")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Security-Token", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Algorithm")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Algorithm", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-SignedHeaders", valid_606746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606748: Call_GetAddressBook_606736; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets address the book details by the address book ARN.
  ## 
  let valid = call_606748.validator(path, query, header, formData, body)
  let scheme = call_606748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606748.url(scheme.get, call_606748.host, call_606748.base,
                         call_606748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606748, url, valid)

proc call*(call_606749: Call_GetAddressBook_606736; body: JsonNode): Recallable =
  ## getAddressBook
  ## Gets address the book details by the address book ARN.
  ##   body: JObject (required)
  var body_606750 = newJObject()
  if body != nil:
    body_606750 = body
  result = call_606749.call(nil, nil, nil, nil, body_606750)

var getAddressBook* = Call_GetAddressBook_606736(name: "getAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetAddressBook",
    validator: validate_GetAddressBook_606737, base: "/", url: url_GetAddressBook_606738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConferencePreference_606751 = ref object of OpenApiRestCall_605589
proc url_GetConferencePreference_606753(protocol: Scheme; host: string; base: string;
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

proc validate_GetConferencePreference_606752(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606754 = header.getOrDefault("X-Amz-Target")
  valid_606754 = validateParameter(valid_606754, JString, required = true, default = newJString(
      "AlexaForBusiness.GetConferencePreference"))
  if valid_606754 != nil:
    section.add "X-Amz-Target", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-Signature")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-Signature", valid_606755
  var valid_606756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Content-Sha256", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-Date")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Date", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-Credential")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-Credential", valid_606758
  var valid_606759 = header.getOrDefault("X-Amz-Security-Token")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-Security-Token", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-Algorithm")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Algorithm", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-SignedHeaders", valid_606761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606763: Call_GetConferencePreference_606751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the existing conference preferences.
  ## 
  let valid = call_606763.validator(path, query, header, formData, body)
  let scheme = call_606763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606763.url(scheme.get, call_606763.host, call_606763.base,
                         call_606763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606763, url, valid)

proc call*(call_606764: Call_GetConferencePreference_606751; body: JsonNode): Recallable =
  ## getConferencePreference
  ## Retrieves the existing conference preferences.
  ##   body: JObject (required)
  var body_606765 = newJObject()
  if body != nil:
    body_606765 = body
  result = call_606764.call(nil, nil, nil, nil, body_606765)

var getConferencePreference* = Call_GetConferencePreference_606751(
    name: "getConferencePreference", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetConferencePreference",
    validator: validate_GetConferencePreference_606752, base: "/",
    url: url_GetConferencePreference_606753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConferenceProvider_606766 = ref object of OpenApiRestCall_605589
proc url_GetConferenceProvider_606768(protocol: Scheme; host: string; base: string;
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

proc validate_GetConferenceProvider_606767(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606769 = header.getOrDefault("X-Amz-Target")
  valid_606769 = validateParameter(valid_606769, JString, required = true, default = newJString(
      "AlexaForBusiness.GetConferenceProvider"))
  if valid_606769 != nil:
    section.add "X-Amz-Target", valid_606769
  var valid_606770 = header.getOrDefault("X-Amz-Signature")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "X-Amz-Signature", valid_606770
  var valid_606771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = nil)
  if valid_606771 != nil:
    section.add "X-Amz-Content-Sha256", valid_606771
  var valid_606772 = header.getOrDefault("X-Amz-Date")
  valid_606772 = validateParameter(valid_606772, JString, required = false,
                                 default = nil)
  if valid_606772 != nil:
    section.add "X-Amz-Date", valid_606772
  var valid_606773 = header.getOrDefault("X-Amz-Credential")
  valid_606773 = validateParameter(valid_606773, JString, required = false,
                                 default = nil)
  if valid_606773 != nil:
    section.add "X-Amz-Credential", valid_606773
  var valid_606774 = header.getOrDefault("X-Amz-Security-Token")
  valid_606774 = validateParameter(valid_606774, JString, required = false,
                                 default = nil)
  if valid_606774 != nil:
    section.add "X-Amz-Security-Token", valid_606774
  var valid_606775 = header.getOrDefault("X-Amz-Algorithm")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "X-Amz-Algorithm", valid_606775
  var valid_606776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606776 = validateParameter(valid_606776, JString, required = false,
                                 default = nil)
  if valid_606776 != nil:
    section.add "X-Amz-SignedHeaders", valid_606776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606778: Call_GetConferenceProvider_606766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a specific conference provider.
  ## 
  let valid = call_606778.validator(path, query, header, formData, body)
  let scheme = call_606778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606778.url(scheme.get, call_606778.host, call_606778.base,
                         call_606778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606778, url, valid)

proc call*(call_606779: Call_GetConferenceProvider_606766; body: JsonNode): Recallable =
  ## getConferenceProvider
  ## Gets details about a specific conference provider.
  ##   body: JObject (required)
  var body_606780 = newJObject()
  if body != nil:
    body_606780 = body
  result = call_606779.call(nil, nil, nil, nil, body_606780)

var getConferenceProvider* = Call_GetConferenceProvider_606766(
    name: "getConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetConferenceProvider",
    validator: validate_GetConferenceProvider_606767, base: "/",
    url: url_GetConferenceProvider_606768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContact_606781 = ref object of OpenApiRestCall_605589
proc url_GetContact_606783(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetContact_606782(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606784 = header.getOrDefault("X-Amz-Target")
  valid_606784 = validateParameter(valid_606784, JString, required = true, default = newJString(
      "AlexaForBusiness.GetContact"))
  if valid_606784 != nil:
    section.add "X-Amz-Target", valid_606784
  var valid_606785 = header.getOrDefault("X-Amz-Signature")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "X-Amz-Signature", valid_606785
  var valid_606786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-Content-Sha256", valid_606786
  var valid_606787 = header.getOrDefault("X-Amz-Date")
  valid_606787 = validateParameter(valid_606787, JString, required = false,
                                 default = nil)
  if valid_606787 != nil:
    section.add "X-Amz-Date", valid_606787
  var valid_606788 = header.getOrDefault("X-Amz-Credential")
  valid_606788 = validateParameter(valid_606788, JString, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "X-Amz-Credential", valid_606788
  var valid_606789 = header.getOrDefault("X-Amz-Security-Token")
  valid_606789 = validateParameter(valid_606789, JString, required = false,
                                 default = nil)
  if valid_606789 != nil:
    section.add "X-Amz-Security-Token", valid_606789
  var valid_606790 = header.getOrDefault("X-Amz-Algorithm")
  valid_606790 = validateParameter(valid_606790, JString, required = false,
                                 default = nil)
  if valid_606790 != nil:
    section.add "X-Amz-Algorithm", valid_606790
  var valid_606791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-SignedHeaders", valid_606791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606793: Call_GetContact_606781; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contact details by the contact ARN.
  ## 
  let valid = call_606793.validator(path, query, header, formData, body)
  let scheme = call_606793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606793.url(scheme.get, call_606793.host, call_606793.base,
                         call_606793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606793, url, valid)

proc call*(call_606794: Call_GetContact_606781; body: JsonNode): Recallable =
  ## getContact
  ## Gets the contact details by the contact ARN.
  ##   body: JObject (required)
  var body_606795 = newJObject()
  if body != nil:
    body_606795 = body
  result = call_606794.call(nil, nil, nil, nil, body_606795)

var getContact* = Call_GetContact_606781(name: "getContact",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetContact",
                                      validator: validate_GetContact_606782,
                                      base: "/", url: url_GetContact_606783,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_606796 = ref object of OpenApiRestCall_605589
proc url_GetDevice_606798(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDevice_606797(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606799 = header.getOrDefault("X-Amz-Target")
  valid_606799 = validateParameter(valid_606799, JString, required = true, default = newJString(
      "AlexaForBusiness.GetDevice"))
  if valid_606799 != nil:
    section.add "X-Amz-Target", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Signature")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Signature", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-Content-Sha256", valid_606801
  var valid_606802 = header.getOrDefault("X-Amz-Date")
  valid_606802 = validateParameter(valid_606802, JString, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "X-Amz-Date", valid_606802
  var valid_606803 = header.getOrDefault("X-Amz-Credential")
  valid_606803 = validateParameter(valid_606803, JString, required = false,
                                 default = nil)
  if valid_606803 != nil:
    section.add "X-Amz-Credential", valid_606803
  var valid_606804 = header.getOrDefault("X-Amz-Security-Token")
  valid_606804 = validateParameter(valid_606804, JString, required = false,
                                 default = nil)
  if valid_606804 != nil:
    section.add "X-Amz-Security-Token", valid_606804
  var valid_606805 = header.getOrDefault("X-Amz-Algorithm")
  valid_606805 = validateParameter(valid_606805, JString, required = false,
                                 default = nil)
  if valid_606805 != nil:
    section.add "X-Amz-Algorithm", valid_606805
  var valid_606806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606806 = validateParameter(valid_606806, JString, required = false,
                                 default = nil)
  if valid_606806 != nil:
    section.add "X-Amz-SignedHeaders", valid_606806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606808: Call_GetDevice_606796; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details of a device by device ARN.
  ## 
  let valid = call_606808.validator(path, query, header, formData, body)
  let scheme = call_606808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606808.url(scheme.get, call_606808.host, call_606808.base,
                         call_606808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606808, url, valid)

proc call*(call_606809: Call_GetDevice_606796; body: JsonNode): Recallable =
  ## getDevice
  ## Gets the details of a device by device ARN.
  ##   body: JObject (required)
  var body_606810 = newJObject()
  if body != nil:
    body_606810 = body
  result = call_606809.call(nil, nil, nil, nil, body_606810)

var getDevice* = Call_GetDevice_606796(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetDevice",
                                    validator: validate_GetDevice_606797,
                                    base: "/", url: url_GetDevice_606798,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGateway_606811 = ref object of OpenApiRestCall_605589
proc url_GetGateway_606813(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetGateway_606812(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606814 = header.getOrDefault("X-Amz-Target")
  valid_606814 = validateParameter(valid_606814, JString, required = true, default = newJString(
      "AlexaForBusiness.GetGateway"))
  if valid_606814 != nil:
    section.add "X-Amz-Target", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Signature")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Signature", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-Content-Sha256", valid_606816
  var valid_606817 = header.getOrDefault("X-Amz-Date")
  valid_606817 = validateParameter(valid_606817, JString, required = false,
                                 default = nil)
  if valid_606817 != nil:
    section.add "X-Amz-Date", valid_606817
  var valid_606818 = header.getOrDefault("X-Amz-Credential")
  valid_606818 = validateParameter(valid_606818, JString, required = false,
                                 default = nil)
  if valid_606818 != nil:
    section.add "X-Amz-Credential", valid_606818
  var valid_606819 = header.getOrDefault("X-Amz-Security-Token")
  valid_606819 = validateParameter(valid_606819, JString, required = false,
                                 default = nil)
  if valid_606819 != nil:
    section.add "X-Amz-Security-Token", valid_606819
  var valid_606820 = header.getOrDefault("X-Amz-Algorithm")
  valid_606820 = validateParameter(valid_606820, JString, required = false,
                                 default = nil)
  if valid_606820 != nil:
    section.add "X-Amz-Algorithm", valid_606820
  var valid_606821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606821 = validateParameter(valid_606821, JString, required = false,
                                 default = nil)
  if valid_606821 != nil:
    section.add "X-Amz-SignedHeaders", valid_606821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606823: Call_GetGateway_606811; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details of a gateway.
  ## 
  let valid = call_606823.validator(path, query, header, formData, body)
  let scheme = call_606823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606823.url(scheme.get, call_606823.host, call_606823.base,
                         call_606823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606823, url, valid)

proc call*(call_606824: Call_GetGateway_606811; body: JsonNode): Recallable =
  ## getGateway
  ## Retrieves the details of a gateway.
  ##   body: JObject (required)
  var body_606825 = newJObject()
  if body != nil:
    body_606825 = body
  result = call_606824.call(nil, nil, nil, nil, body_606825)

var getGateway* = Call_GetGateway_606811(name: "getGateway",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetGateway",
                                      validator: validate_GetGateway_606812,
                                      base: "/", url: url_GetGateway_606813,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayGroup_606826 = ref object of OpenApiRestCall_605589
proc url_GetGatewayGroup_606828(protocol: Scheme; host: string; base: string;
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

proc validate_GetGatewayGroup_606827(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606829 = header.getOrDefault("X-Amz-Target")
  valid_606829 = validateParameter(valid_606829, JString, required = true, default = newJString(
      "AlexaForBusiness.GetGatewayGroup"))
  if valid_606829 != nil:
    section.add "X-Amz-Target", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-Signature")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Signature", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Content-Sha256", valid_606831
  var valid_606832 = header.getOrDefault("X-Amz-Date")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-Date", valid_606832
  var valid_606833 = header.getOrDefault("X-Amz-Credential")
  valid_606833 = validateParameter(valid_606833, JString, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "X-Amz-Credential", valid_606833
  var valid_606834 = header.getOrDefault("X-Amz-Security-Token")
  valid_606834 = validateParameter(valid_606834, JString, required = false,
                                 default = nil)
  if valid_606834 != nil:
    section.add "X-Amz-Security-Token", valid_606834
  var valid_606835 = header.getOrDefault("X-Amz-Algorithm")
  valid_606835 = validateParameter(valid_606835, JString, required = false,
                                 default = nil)
  if valid_606835 != nil:
    section.add "X-Amz-Algorithm", valid_606835
  var valid_606836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606836 = validateParameter(valid_606836, JString, required = false,
                                 default = nil)
  if valid_606836 != nil:
    section.add "X-Amz-SignedHeaders", valid_606836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606838: Call_GetGatewayGroup_606826; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details of a gateway group.
  ## 
  let valid = call_606838.validator(path, query, header, formData, body)
  let scheme = call_606838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606838.url(scheme.get, call_606838.host, call_606838.base,
                         call_606838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606838, url, valid)

proc call*(call_606839: Call_GetGatewayGroup_606826; body: JsonNode): Recallable =
  ## getGatewayGroup
  ## Retrieves the details of a gateway group.
  ##   body: JObject (required)
  var body_606840 = newJObject()
  if body != nil:
    body_606840 = body
  result = call_606839.call(nil, nil, nil, nil, body_606840)

var getGatewayGroup* = Call_GetGatewayGroup_606826(name: "getGatewayGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetGatewayGroup",
    validator: validate_GetGatewayGroup_606827, base: "/", url: url_GetGatewayGroup_606828,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationConfiguration_606841 = ref object of OpenApiRestCall_605589
proc url_GetInvitationConfiguration_606843(protocol: Scheme; host: string;
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

proc validate_GetInvitationConfiguration_606842(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606844 = header.getOrDefault("X-Amz-Target")
  valid_606844 = validateParameter(valid_606844, JString, required = true, default = newJString(
      "AlexaForBusiness.GetInvitationConfiguration"))
  if valid_606844 != nil:
    section.add "X-Amz-Target", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-Signature")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Signature", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Content-Sha256", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-Date")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-Date", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-Credential")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Credential", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-Security-Token")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-Security-Token", valid_606849
  var valid_606850 = header.getOrDefault("X-Amz-Algorithm")
  valid_606850 = validateParameter(valid_606850, JString, required = false,
                                 default = nil)
  if valid_606850 != nil:
    section.add "X-Amz-Algorithm", valid_606850
  var valid_606851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606851 = validateParameter(valid_606851, JString, required = false,
                                 default = nil)
  if valid_606851 != nil:
    section.add "X-Amz-SignedHeaders", valid_606851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606853: Call_GetInvitationConfiguration_606841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the configured values for the user enrollment invitation email template.
  ## 
  let valid = call_606853.validator(path, query, header, formData, body)
  let scheme = call_606853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606853.url(scheme.get, call_606853.host, call_606853.base,
                         call_606853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606853, url, valid)

proc call*(call_606854: Call_GetInvitationConfiguration_606841; body: JsonNode): Recallable =
  ## getInvitationConfiguration
  ## Retrieves the configured values for the user enrollment invitation email template.
  ##   body: JObject (required)
  var body_606855 = newJObject()
  if body != nil:
    body_606855 = body
  result = call_606854.call(nil, nil, nil, nil, body_606855)

var getInvitationConfiguration* = Call_GetInvitationConfiguration_606841(
    name: "getInvitationConfiguration", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetInvitationConfiguration",
    validator: validate_GetInvitationConfiguration_606842, base: "/",
    url: url_GetInvitationConfiguration_606843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_606856 = ref object of OpenApiRestCall_605589
proc url_GetNetworkProfile_606858(protocol: Scheme; host: string; base: string;
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

proc validate_GetNetworkProfile_606857(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606859 = header.getOrDefault("X-Amz-Target")
  valid_606859 = validateParameter(valid_606859, JString, required = true, default = newJString(
      "AlexaForBusiness.GetNetworkProfile"))
  if valid_606859 != nil:
    section.add "X-Amz-Target", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-Signature")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Signature", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-Content-Sha256", valid_606861
  var valid_606862 = header.getOrDefault("X-Amz-Date")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-Date", valid_606862
  var valid_606863 = header.getOrDefault("X-Amz-Credential")
  valid_606863 = validateParameter(valid_606863, JString, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "X-Amz-Credential", valid_606863
  var valid_606864 = header.getOrDefault("X-Amz-Security-Token")
  valid_606864 = validateParameter(valid_606864, JString, required = false,
                                 default = nil)
  if valid_606864 != nil:
    section.add "X-Amz-Security-Token", valid_606864
  var valid_606865 = header.getOrDefault("X-Amz-Algorithm")
  valid_606865 = validateParameter(valid_606865, JString, required = false,
                                 default = nil)
  if valid_606865 != nil:
    section.add "X-Amz-Algorithm", valid_606865
  var valid_606866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606866 = validateParameter(valid_606866, JString, required = false,
                                 default = nil)
  if valid_606866 != nil:
    section.add "X-Amz-SignedHeaders", valid_606866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606868: Call_GetNetworkProfile_606856; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the network profile details by the network profile ARN.
  ## 
  let valid = call_606868.validator(path, query, header, formData, body)
  let scheme = call_606868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606868.url(scheme.get, call_606868.host, call_606868.base,
                         call_606868.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606868, url, valid)

proc call*(call_606869: Call_GetNetworkProfile_606856; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Gets the network profile details by the network profile ARN.
  ##   body: JObject (required)
  var body_606870 = newJObject()
  if body != nil:
    body_606870 = body
  result = call_606869.call(nil, nil, nil, nil, body_606870)

var getNetworkProfile* = Call_GetNetworkProfile_606856(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetNetworkProfile",
    validator: validate_GetNetworkProfile_606857, base: "/",
    url: url_GetNetworkProfile_606858, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProfile_606871 = ref object of OpenApiRestCall_605589
proc url_GetProfile_606873(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetProfile_606872(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606874 = header.getOrDefault("X-Amz-Target")
  valid_606874 = validateParameter(valid_606874, JString, required = true, default = newJString(
      "AlexaForBusiness.GetProfile"))
  if valid_606874 != nil:
    section.add "X-Amz-Target", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Signature")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Signature", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Content-Sha256", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-Date")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-Date", valid_606877
  var valid_606878 = header.getOrDefault("X-Amz-Credential")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "X-Amz-Credential", valid_606878
  var valid_606879 = header.getOrDefault("X-Amz-Security-Token")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "X-Amz-Security-Token", valid_606879
  var valid_606880 = header.getOrDefault("X-Amz-Algorithm")
  valid_606880 = validateParameter(valid_606880, JString, required = false,
                                 default = nil)
  if valid_606880 != nil:
    section.add "X-Amz-Algorithm", valid_606880
  var valid_606881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606881 = validateParameter(valid_606881, JString, required = false,
                                 default = nil)
  if valid_606881 != nil:
    section.add "X-Amz-SignedHeaders", valid_606881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606883: Call_GetProfile_606871; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details of a room profile by profile ARN.
  ## 
  let valid = call_606883.validator(path, query, header, formData, body)
  let scheme = call_606883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606883.url(scheme.get, call_606883.host, call_606883.base,
                         call_606883.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606883, url, valid)

proc call*(call_606884: Call_GetProfile_606871; body: JsonNode): Recallable =
  ## getProfile
  ## Gets the details of a room profile by profile ARN.
  ##   body: JObject (required)
  var body_606885 = newJObject()
  if body != nil:
    body_606885 = body
  result = call_606884.call(nil, nil, nil, nil, body_606885)

var getProfile* = Call_GetProfile_606871(name: "getProfile",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetProfile",
                                      validator: validate_GetProfile_606872,
                                      base: "/", url: url_GetProfile_606873,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoom_606886 = ref object of OpenApiRestCall_605589
proc url_GetRoom_606888(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRoom_606887(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606889 = header.getOrDefault("X-Amz-Target")
  valid_606889 = validateParameter(valid_606889, JString, required = true, default = newJString(
      "AlexaForBusiness.GetRoom"))
  if valid_606889 != nil:
    section.add "X-Amz-Target", valid_606889
  var valid_606890 = header.getOrDefault("X-Amz-Signature")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Signature", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-Content-Sha256", valid_606891
  var valid_606892 = header.getOrDefault("X-Amz-Date")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "X-Amz-Date", valid_606892
  var valid_606893 = header.getOrDefault("X-Amz-Credential")
  valid_606893 = validateParameter(valid_606893, JString, required = false,
                                 default = nil)
  if valid_606893 != nil:
    section.add "X-Amz-Credential", valid_606893
  var valid_606894 = header.getOrDefault("X-Amz-Security-Token")
  valid_606894 = validateParameter(valid_606894, JString, required = false,
                                 default = nil)
  if valid_606894 != nil:
    section.add "X-Amz-Security-Token", valid_606894
  var valid_606895 = header.getOrDefault("X-Amz-Algorithm")
  valid_606895 = validateParameter(valid_606895, JString, required = false,
                                 default = nil)
  if valid_606895 != nil:
    section.add "X-Amz-Algorithm", valid_606895
  var valid_606896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606896 = validateParameter(valid_606896, JString, required = false,
                                 default = nil)
  if valid_606896 != nil:
    section.add "X-Amz-SignedHeaders", valid_606896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606898: Call_GetRoom_606886; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets room details by room ARN.
  ## 
  let valid = call_606898.validator(path, query, header, formData, body)
  let scheme = call_606898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606898.url(scheme.get, call_606898.host, call_606898.base,
                         call_606898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606898, url, valid)

proc call*(call_606899: Call_GetRoom_606886; body: JsonNode): Recallable =
  ## getRoom
  ## Gets room details by room ARN.
  ##   body: JObject (required)
  var body_606900 = newJObject()
  if body != nil:
    body_606900 = body
  result = call_606899.call(nil, nil, nil, nil, body_606900)

var getRoom* = Call_GetRoom_606886(name: "getRoom", meth: HttpMethod.HttpPost,
                                host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetRoom",
                                validator: validate_GetRoom_606887, base: "/",
                                url: url_GetRoom_606888,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoomSkillParameter_606901 = ref object of OpenApiRestCall_605589
proc url_GetRoomSkillParameter_606903(protocol: Scheme; host: string; base: string;
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

proc validate_GetRoomSkillParameter_606902(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606904 = header.getOrDefault("X-Amz-Target")
  valid_606904 = validateParameter(valid_606904, JString, required = true, default = newJString(
      "AlexaForBusiness.GetRoomSkillParameter"))
  if valid_606904 != nil:
    section.add "X-Amz-Target", valid_606904
  var valid_606905 = header.getOrDefault("X-Amz-Signature")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "X-Amz-Signature", valid_606905
  var valid_606906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606906 = validateParameter(valid_606906, JString, required = false,
                                 default = nil)
  if valid_606906 != nil:
    section.add "X-Amz-Content-Sha256", valid_606906
  var valid_606907 = header.getOrDefault("X-Amz-Date")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "X-Amz-Date", valid_606907
  var valid_606908 = header.getOrDefault("X-Amz-Credential")
  valid_606908 = validateParameter(valid_606908, JString, required = false,
                                 default = nil)
  if valid_606908 != nil:
    section.add "X-Amz-Credential", valid_606908
  var valid_606909 = header.getOrDefault("X-Amz-Security-Token")
  valid_606909 = validateParameter(valid_606909, JString, required = false,
                                 default = nil)
  if valid_606909 != nil:
    section.add "X-Amz-Security-Token", valid_606909
  var valid_606910 = header.getOrDefault("X-Amz-Algorithm")
  valid_606910 = validateParameter(valid_606910, JString, required = false,
                                 default = nil)
  if valid_606910 != nil:
    section.add "X-Amz-Algorithm", valid_606910
  var valid_606911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606911 = validateParameter(valid_606911, JString, required = false,
                                 default = nil)
  if valid_606911 != nil:
    section.add "X-Amz-SignedHeaders", valid_606911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606913: Call_GetRoomSkillParameter_606901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets room skill parameter details by room, skill, and parameter key ARN.
  ## 
  let valid = call_606913.validator(path, query, header, formData, body)
  let scheme = call_606913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606913.url(scheme.get, call_606913.host, call_606913.base,
                         call_606913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606913, url, valid)

proc call*(call_606914: Call_GetRoomSkillParameter_606901; body: JsonNode): Recallable =
  ## getRoomSkillParameter
  ## Gets room skill parameter details by room, skill, and parameter key ARN.
  ##   body: JObject (required)
  var body_606915 = newJObject()
  if body != nil:
    body_606915 = body
  result = call_606914.call(nil, nil, nil, nil, body_606915)

var getRoomSkillParameter* = Call_GetRoomSkillParameter_606901(
    name: "getRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetRoomSkillParameter",
    validator: validate_GetRoomSkillParameter_606902, base: "/",
    url: url_GetRoomSkillParameter_606903, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSkillGroup_606916 = ref object of OpenApiRestCall_605589
proc url_GetSkillGroup_606918(protocol: Scheme; host: string; base: string;
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

proc validate_GetSkillGroup_606917(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606919 = header.getOrDefault("X-Amz-Target")
  valid_606919 = validateParameter(valid_606919, JString, required = true, default = newJString(
      "AlexaForBusiness.GetSkillGroup"))
  if valid_606919 != nil:
    section.add "X-Amz-Target", valid_606919
  var valid_606920 = header.getOrDefault("X-Amz-Signature")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "X-Amz-Signature", valid_606920
  var valid_606921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-Content-Sha256", valid_606921
  var valid_606922 = header.getOrDefault("X-Amz-Date")
  valid_606922 = validateParameter(valid_606922, JString, required = false,
                                 default = nil)
  if valid_606922 != nil:
    section.add "X-Amz-Date", valid_606922
  var valid_606923 = header.getOrDefault("X-Amz-Credential")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "X-Amz-Credential", valid_606923
  var valid_606924 = header.getOrDefault("X-Amz-Security-Token")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "X-Amz-Security-Token", valid_606924
  var valid_606925 = header.getOrDefault("X-Amz-Algorithm")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "X-Amz-Algorithm", valid_606925
  var valid_606926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "X-Amz-SignedHeaders", valid_606926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606928: Call_GetSkillGroup_606916; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets skill group details by skill group ARN.
  ## 
  let valid = call_606928.validator(path, query, header, formData, body)
  let scheme = call_606928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606928.url(scheme.get, call_606928.host, call_606928.base,
                         call_606928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606928, url, valid)

proc call*(call_606929: Call_GetSkillGroup_606916; body: JsonNode): Recallable =
  ## getSkillGroup
  ## Gets skill group details by skill group ARN.
  ##   body: JObject (required)
  var body_606930 = newJObject()
  if body != nil:
    body_606930 = body
  result = call_606929.call(nil, nil, nil, nil, body_606930)

var getSkillGroup* = Call_GetSkillGroup_606916(name: "getSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetSkillGroup",
    validator: validate_GetSkillGroup_606917, base: "/", url: url_GetSkillGroup_606918,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBusinessReportSchedules_606931 = ref object of OpenApiRestCall_605589
proc url_ListBusinessReportSchedules_606933(protocol: Scheme; host: string;
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

proc validate_ListBusinessReportSchedules_606932(path: JsonNode; query: JsonNode;
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
  var valid_606934 = query.getOrDefault("MaxResults")
  valid_606934 = validateParameter(valid_606934, JString, required = false,
                                 default = nil)
  if valid_606934 != nil:
    section.add "MaxResults", valid_606934
  var valid_606935 = query.getOrDefault("NextToken")
  valid_606935 = validateParameter(valid_606935, JString, required = false,
                                 default = nil)
  if valid_606935 != nil:
    section.add "NextToken", valid_606935
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606936 = header.getOrDefault("X-Amz-Target")
  valid_606936 = validateParameter(valid_606936, JString, required = true, default = newJString(
      "AlexaForBusiness.ListBusinessReportSchedules"))
  if valid_606936 != nil:
    section.add "X-Amz-Target", valid_606936
  var valid_606937 = header.getOrDefault("X-Amz-Signature")
  valid_606937 = validateParameter(valid_606937, JString, required = false,
                                 default = nil)
  if valid_606937 != nil:
    section.add "X-Amz-Signature", valid_606937
  var valid_606938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606938 = validateParameter(valid_606938, JString, required = false,
                                 default = nil)
  if valid_606938 != nil:
    section.add "X-Amz-Content-Sha256", valid_606938
  var valid_606939 = header.getOrDefault("X-Amz-Date")
  valid_606939 = validateParameter(valid_606939, JString, required = false,
                                 default = nil)
  if valid_606939 != nil:
    section.add "X-Amz-Date", valid_606939
  var valid_606940 = header.getOrDefault("X-Amz-Credential")
  valid_606940 = validateParameter(valid_606940, JString, required = false,
                                 default = nil)
  if valid_606940 != nil:
    section.add "X-Amz-Credential", valid_606940
  var valid_606941 = header.getOrDefault("X-Amz-Security-Token")
  valid_606941 = validateParameter(valid_606941, JString, required = false,
                                 default = nil)
  if valid_606941 != nil:
    section.add "X-Amz-Security-Token", valid_606941
  var valid_606942 = header.getOrDefault("X-Amz-Algorithm")
  valid_606942 = validateParameter(valid_606942, JString, required = false,
                                 default = nil)
  if valid_606942 != nil:
    section.add "X-Amz-Algorithm", valid_606942
  var valid_606943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606943 = validateParameter(valid_606943, JString, required = false,
                                 default = nil)
  if valid_606943 != nil:
    section.add "X-Amz-SignedHeaders", valid_606943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606945: Call_ListBusinessReportSchedules_606931; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the details of the schedules that a user configured. A download URL of the report associated with each schedule is returned every time this action is called. A new download URL is returned each time, and is valid for 24 hours.
  ## 
  let valid = call_606945.validator(path, query, header, formData, body)
  let scheme = call_606945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606945.url(scheme.get, call_606945.host, call_606945.base,
                         call_606945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606945, url, valid)

proc call*(call_606946: Call_ListBusinessReportSchedules_606931; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listBusinessReportSchedules
  ## Lists the details of the schedules that a user configured. A download URL of the report associated with each schedule is returned every time this action is called. A new download URL is returned each time, and is valid for 24 hours.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606947 = newJObject()
  var body_606948 = newJObject()
  add(query_606947, "MaxResults", newJString(MaxResults))
  add(query_606947, "NextToken", newJString(NextToken))
  if body != nil:
    body_606948 = body
  result = call_606946.call(nil, query_606947, nil, nil, body_606948)

var listBusinessReportSchedules* = Call_ListBusinessReportSchedules_606931(
    name: "listBusinessReportSchedules", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListBusinessReportSchedules",
    validator: validate_ListBusinessReportSchedules_606932, base: "/",
    url: url_ListBusinessReportSchedules_606933,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConferenceProviders_606950 = ref object of OpenApiRestCall_605589
proc url_ListConferenceProviders_606952(protocol: Scheme; host: string; base: string;
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

proc validate_ListConferenceProviders_606951(path: JsonNode; query: JsonNode;
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
  var valid_606953 = query.getOrDefault("MaxResults")
  valid_606953 = validateParameter(valid_606953, JString, required = false,
                                 default = nil)
  if valid_606953 != nil:
    section.add "MaxResults", valid_606953
  var valid_606954 = query.getOrDefault("NextToken")
  valid_606954 = validateParameter(valid_606954, JString, required = false,
                                 default = nil)
  if valid_606954 != nil:
    section.add "NextToken", valid_606954
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606955 = header.getOrDefault("X-Amz-Target")
  valid_606955 = validateParameter(valid_606955, JString, required = true, default = newJString(
      "AlexaForBusiness.ListConferenceProviders"))
  if valid_606955 != nil:
    section.add "X-Amz-Target", valid_606955
  var valid_606956 = header.getOrDefault("X-Amz-Signature")
  valid_606956 = validateParameter(valid_606956, JString, required = false,
                                 default = nil)
  if valid_606956 != nil:
    section.add "X-Amz-Signature", valid_606956
  var valid_606957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606957 = validateParameter(valid_606957, JString, required = false,
                                 default = nil)
  if valid_606957 != nil:
    section.add "X-Amz-Content-Sha256", valid_606957
  var valid_606958 = header.getOrDefault("X-Amz-Date")
  valid_606958 = validateParameter(valid_606958, JString, required = false,
                                 default = nil)
  if valid_606958 != nil:
    section.add "X-Amz-Date", valid_606958
  var valid_606959 = header.getOrDefault("X-Amz-Credential")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "X-Amz-Credential", valid_606959
  var valid_606960 = header.getOrDefault("X-Amz-Security-Token")
  valid_606960 = validateParameter(valid_606960, JString, required = false,
                                 default = nil)
  if valid_606960 != nil:
    section.add "X-Amz-Security-Token", valid_606960
  var valid_606961 = header.getOrDefault("X-Amz-Algorithm")
  valid_606961 = validateParameter(valid_606961, JString, required = false,
                                 default = nil)
  if valid_606961 != nil:
    section.add "X-Amz-Algorithm", valid_606961
  var valid_606962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606962 = validateParameter(valid_606962, JString, required = false,
                                 default = nil)
  if valid_606962 != nil:
    section.add "X-Amz-SignedHeaders", valid_606962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606964: Call_ListConferenceProviders_606950; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists conference providers under a specific AWS account.
  ## 
  let valid = call_606964.validator(path, query, header, formData, body)
  let scheme = call_606964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606964.url(scheme.get, call_606964.host, call_606964.base,
                         call_606964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606964, url, valid)

proc call*(call_606965: Call_ListConferenceProviders_606950; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listConferenceProviders
  ## Lists conference providers under a specific AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606966 = newJObject()
  var body_606967 = newJObject()
  add(query_606966, "MaxResults", newJString(MaxResults))
  add(query_606966, "NextToken", newJString(NextToken))
  if body != nil:
    body_606967 = body
  result = call_606965.call(nil, query_606966, nil, nil, body_606967)

var listConferenceProviders* = Call_ListConferenceProviders_606950(
    name: "listConferenceProviders", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListConferenceProviders",
    validator: validate_ListConferenceProviders_606951, base: "/",
    url: url_ListConferenceProviders_606952, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceEvents_606968 = ref object of OpenApiRestCall_605589
proc url_ListDeviceEvents_606970(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeviceEvents_606969(path: JsonNode; query: JsonNode;
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
  var valid_606971 = query.getOrDefault("MaxResults")
  valid_606971 = validateParameter(valid_606971, JString, required = false,
                                 default = nil)
  if valid_606971 != nil:
    section.add "MaxResults", valid_606971
  var valid_606972 = query.getOrDefault("NextToken")
  valid_606972 = validateParameter(valid_606972, JString, required = false,
                                 default = nil)
  if valid_606972 != nil:
    section.add "NextToken", valid_606972
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606973 = header.getOrDefault("X-Amz-Target")
  valid_606973 = validateParameter(valid_606973, JString, required = true, default = newJString(
      "AlexaForBusiness.ListDeviceEvents"))
  if valid_606973 != nil:
    section.add "X-Amz-Target", valid_606973
  var valid_606974 = header.getOrDefault("X-Amz-Signature")
  valid_606974 = validateParameter(valid_606974, JString, required = false,
                                 default = nil)
  if valid_606974 != nil:
    section.add "X-Amz-Signature", valid_606974
  var valid_606975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606975 = validateParameter(valid_606975, JString, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "X-Amz-Content-Sha256", valid_606975
  var valid_606976 = header.getOrDefault("X-Amz-Date")
  valid_606976 = validateParameter(valid_606976, JString, required = false,
                                 default = nil)
  if valid_606976 != nil:
    section.add "X-Amz-Date", valid_606976
  var valid_606977 = header.getOrDefault("X-Amz-Credential")
  valid_606977 = validateParameter(valid_606977, JString, required = false,
                                 default = nil)
  if valid_606977 != nil:
    section.add "X-Amz-Credential", valid_606977
  var valid_606978 = header.getOrDefault("X-Amz-Security-Token")
  valid_606978 = validateParameter(valid_606978, JString, required = false,
                                 default = nil)
  if valid_606978 != nil:
    section.add "X-Amz-Security-Token", valid_606978
  var valid_606979 = header.getOrDefault("X-Amz-Algorithm")
  valid_606979 = validateParameter(valid_606979, JString, required = false,
                                 default = nil)
  if valid_606979 != nil:
    section.add "X-Amz-Algorithm", valid_606979
  var valid_606980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606980 = validateParameter(valid_606980, JString, required = false,
                                 default = nil)
  if valid_606980 != nil:
    section.add "X-Amz-SignedHeaders", valid_606980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606982: Call_ListDeviceEvents_606968; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the device event history, including device connection status, for up to 30 days.
  ## 
  let valid = call_606982.validator(path, query, header, formData, body)
  let scheme = call_606982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606982.url(scheme.get, call_606982.host, call_606982.base,
                         call_606982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606982, url, valid)

proc call*(call_606983: Call_ListDeviceEvents_606968; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDeviceEvents
  ## Lists the device event history, including device connection status, for up to 30 days.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606984 = newJObject()
  var body_606985 = newJObject()
  add(query_606984, "MaxResults", newJString(MaxResults))
  add(query_606984, "NextToken", newJString(NextToken))
  if body != nil:
    body_606985 = body
  result = call_606983.call(nil, query_606984, nil, nil, body_606985)

var listDeviceEvents* = Call_ListDeviceEvents_606968(name: "listDeviceEvents",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListDeviceEvents",
    validator: validate_ListDeviceEvents_606969, base: "/",
    url: url_ListDeviceEvents_606970, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGatewayGroups_606986 = ref object of OpenApiRestCall_605589
proc url_ListGatewayGroups_606988(protocol: Scheme; host: string; base: string;
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

proc validate_ListGatewayGroups_606987(path: JsonNode; query: JsonNode;
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
  var valid_606989 = query.getOrDefault("MaxResults")
  valid_606989 = validateParameter(valid_606989, JString, required = false,
                                 default = nil)
  if valid_606989 != nil:
    section.add "MaxResults", valid_606989
  var valid_606990 = query.getOrDefault("NextToken")
  valid_606990 = validateParameter(valid_606990, JString, required = false,
                                 default = nil)
  if valid_606990 != nil:
    section.add "NextToken", valid_606990
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606991 = header.getOrDefault("X-Amz-Target")
  valid_606991 = validateParameter(valid_606991, JString, required = true, default = newJString(
      "AlexaForBusiness.ListGatewayGroups"))
  if valid_606991 != nil:
    section.add "X-Amz-Target", valid_606991
  var valid_606992 = header.getOrDefault("X-Amz-Signature")
  valid_606992 = validateParameter(valid_606992, JString, required = false,
                                 default = nil)
  if valid_606992 != nil:
    section.add "X-Amz-Signature", valid_606992
  var valid_606993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606993 = validateParameter(valid_606993, JString, required = false,
                                 default = nil)
  if valid_606993 != nil:
    section.add "X-Amz-Content-Sha256", valid_606993
  var valid_606994 = header.getOrDefault("X-Amz-Date")
  valid_606994 = validateParameter(valid_606994, JString, required = false,
                                 default = nil)
  if valid_606994 != nil:
    section.add "X-Amz-Date", valid_606994
  var valid_606995 = header.getOrDefault("X-Amz-Credential")
  valid_606995 = validateParameter(valid_606995, JString, required = false,
                                 default = nil)
  if valid_606995 != nil:
    section.add "X-Amz-Credential", valid_606995
  var valid_606996 = header.getOrDefault("X-Amz-Security-Token")
  valid_606996 = validateParameter(valid_606996, JString, required = false,
                                 default = nil)
  if valid_606996 != nil:
    section.add "X-Amz-Security-Token", valid_606996
  var valid_606997 = header.getOrDefault("X-Amz-Algorithm")
  valid_606997 = validateParameter(valid_606997, JString, required = false,
                                 default = nil)
  if valid_606997 != nil:
    section.add "X-Amz-Algorithm", valid_606997
  var valid_606998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606998 = validateParameter(valid_606998, JString, required = false,
                                 default = nil)
  if valid_606998 != nil:
    section.add "X-Amz-SignedHeaders", valid_606998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607000: Call_ListGatewayGroups_606986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
  ## 
  let valid = call_607000.validator(path, query, header, formData, body)
  let scheme = call_607000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607000.url(scheme.get, call_607000.host, call_607000.base,
                         call_607000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607000, url, valid)

proc call*(call_607001: Call_ListGatewayGroups_606986; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGatewayGroups
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607002 = newJObject()
  var body_607003 = newJObject()
  add(query_607002, "MaxResults", newJString(MaxResults))
  add(query_607002, "NextToken", newJString(NextToken))
  if body != nil:
    body_607003 = body
  result = call_607001.call(nil, query_607002, nil, nil, body_607003)

var listGatewayGroups* = Call_ListGatewayGroups_606986(name: "listGatewayGroups",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListGatewayGroups",
    validator: validate_ListGatewayGroups_606987, base: "/",
    url: url_ListGatewayGroups_606988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGateways_607004 = ref object of OpenApiRestCall_605589
proc url_ListGateways_607006(protocol: Scheme; host: string; base: string;
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

proc validate_ListGateways_607005(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607007 = query.getOrDefault("MaxResults")
  valid_607007 = validateParameter(valid_607007, JString, required = false,
                                 default = nil)
  if valid_607007 != nil:
    section.add "MaxResults", valid_607007
  var valid_607008 = query.getOrDefault("NextToken")
  valid_607008 = validateParameter(valid_607008, JString, required = false,
                                 default = nil)
  if valid_607008 != nil:
    section.add "NextToken", valid_607008
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607009 = header.getOrDefault("X-Amz-Target")
  valid_607009 = validateParameter(valid_607009, JString, required = true, default = newJString(
      "AlexaForBusiness.ListGateways"))
  if valid_607009 != nil:
    section.add "X-Amz-Target", valid_607009
  var valid_607010 = header.getOrDefault("X-Amz-Signature")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "X-Amz-Signature", valid_607010
  var valid_607011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607011 = validateParameter(valid_607011, JString, required = false,
                                 default = nil)
  if valid_607011 != nil:
    section.add "X-Amz-Content-Sha256", valid_607011
  var valid_607012 = header.getOrDefault("X-Amz-Date")
  valid_607012 = validateParameter(valid_607012, JString, required = false,
                                 default = nil)
  if valid_607012 != nil:
    section.add "X-Amz-Date", valid_607012
  var valid_607013 = header.getOrDefault("X-Amz-Credential")
  valid_607013 = validateParameter(valid_607013, JString, required = false,
                                 default = nil)
  if valid_607013 != nil:
    section.add "X-Amz-Credential", valid_607013
  var valid_607014 = header.getOrDefault("X-Amz-Security-Token")
  valid_607014 = validateParameter(valid_607014, JString, required = false,
                                 default = nil)
  if valid_607014 != nil:
    section.add "X-Amz-Security-Token", valid_607014
  var valid_607015 = header.getOrDefault("X-Amz-Algorithm")
  valid_607015 = validateParameter(valid_607015, JString, required = false,
                                 default = nil)
  if valid_607015 != nil:
    section.add "X-Amz-Algorithm", valid_607015
  var valid_607016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607016 = validateParameter(valid_607016, JString, required = false,
                                 default = nil)
  if valid_607016 != nil:
    section.add "X-Amz-SignedHeaders", valid_607016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607018: Call_ListGateways_607004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
  ## 
  let valid = call_607018.validator(path, query, header, formData, body)
  let scheme = call_607018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607018.url(scheme.get, call_607018.host, call_607018.base,
                         call_607018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607018, url, valid)

proc call*(call_607019: Call_ListGateways_607004; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGateways
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607020 = newJObject()
  var body_607021 = newJObject()
  add(query_607020, "MaxResults", newJString(MaxResults))
  add(query_607020, "NextToken", newJString(NextToken))
  if body != nil:
    body_607021 = body
  result = call_607019.call(nil, query_607020, nil, nil, body_607021)

var listGateways* = Call_ListGateways_607004(name: "listGateways",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListGateways",
    validator: validate_ListGateways_607005, base: "/", url: url_ListGateways_607006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkills_607022 = ref object of OpenApiRestCall_605589
proc url_ListSkills_607024(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListSkills_607023(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607025 = query.getOrDefault("MaxResults")
  valid_607025 = validateParameter(valid_607025, JString, required = false,
                                 default = nil)
  if valid_607025 != nil:
    section.add "MaxResults", valid_607025
  var valid_607026 = query.getOrDefault("NextToken")
  valid_607026 = validateParameter(valid_607026, JString, required = false,
                                 default = nil)
  if valid_607026 != nil:
    section.add "NextToken", valid_607026
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607027 = header.getOrDefault("X-Amz-Target")
  valid_607027 = validateParameter(valid_607027, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkills"))
  if valid_607027 != nil:
    section.add "X-Amz-Target", valid_607027
  var valid_607028 = header.getOrDefault("X-Amz-Signature")
  valid_607028 = validateParameter(valid_607028, JString, required = false,
                                 default = nil)
  if valid_607028 != nil:
    section.add "X-Amz-Signature", valid_607028
  var valid_607029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607029 = validateParameter(valid_607029, JString, required = false,
                                 default = nil)
  if valid_607029 != nil:
    section.add "X-Amz-Content-Sha256", valid_607029
  var valid_607030 = header.getOrDefault("X-Amz-Date")
  valid_607030 = validateParameter(valid_607030, JString, required = false,
                                 default = nil)
  if valid_607030 != nil:
    section.add "X-Amz-Date", valid_607030
  var valid_607031 = header.getOrDefault("X-Amz-Credential")
  valid_607031 = validateParameter(valid_607031, JString, required = false,
                                 default = nil)
  if valid_607031 != nil:
    section.add "X-Amz-Credential", valid_607031
  var valid_607032 = header.getOrDefault("X-Amz-Security-Token")
  valid_607032 = validateParameter(valid_607032, JString, required = false,
                                 default = nil)
  if valid_607032 != nil:
    section.add "X-Amz-Security-Token", valid_607032
  var valid_607033 = header.getOrDefault("X-Amz-Algorithm")
  valid_607033 = validateParameter(valid_607033, JString, required = false,
                                 default = nil)
  if valid_607033 != nil:
    section.add "X-Amz-Algorithm", valid_607033
  var valid_607034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-SignedHeaders", valid_607034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607036: Call_ListSkills_607022; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all enabled skills in a specific skill group.
  ## 
  let valid = call_607036.validator(path, query, header, formData, body)
  let scheme = call_607036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607036.url(scheme.get, call_607036.host, call_607036.base,
                         call_607036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607036, url, valid)

proc call*(call_607037: Call_ListSkills_607022; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSkills
  ## Lists all enabled skills in a specific skill group.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607038 = newJObject()
  var body_607039 = newJObject()
  add(query_607038, "MaxResults", newJString(MaxResults))
  add(query_607038, "NextToken", newJString(NextToken))
  if body != nil:
    body_607039 = body
  result = call_607037.call(nil, query_607038, nil, nil, body_607039)

var listSkills* = Call_ListSkills_607022(name: "listSkills",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ListSkills",
                                      validator: validate_ListSkills_607023,
                                      base: "/", url: url_ListSkills_607024,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkillsStoreCategories_607040 = ref object of OpenApiRestCall_605589
proc url_ListSkillsStoreCategories_607042(protocol: Scheme; host: string;
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

proc validate_ListSkillsStoreCategories_607041(path: JsonNode; query: JsonNode;
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
  var valid_607043 = query.getOrDefault("MaxResults")
  valid_607043 = validateParameter(valid_607043, JString, required = false,
                                 default = nil)
  if valid_607043 != nil:
    section.add "MaxResults", valid_607043
  var valid_607044 = query.getOrDefault("NextToken")
  valid_607044 = validateParameter(valid_607044, JString, required = false,
                                 default = nil)
  if valid_607044 != nil:
    section.add "NextToken", valid_607044
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607045 = header.getOrDefault("X-Amz-Target")
  valid_607045 = validateParameter(valid_607045, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkillsStoreCategories"))
  if valid_607045 != nil:
    section.add "X-Amz-Target", valid_607045
  var valid_607046 = header.getOrDefault("X-Amz-Signature")
  valid_607046 = validateParameter(valid_607046, JString, required = false,
                                 default = nil)
  if valid_607046 != nil:
    section.add "X-Amz-Signature", valid_607046
  var valid_607047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607047 = validateParameter(valid_607047, JString, required = false,
                                 default = nil)
  if valid_607047 != nil:
    section.add "X-Amz-Content-Sha256", valid_607047
  var valid_607048 = header.getOrDefault("X-Amz-Date")
  valid_607048 = validateParameter(valid_607048, JString, required = false,
                                 default = nil)
  if valid_607048 != nil:
    section.add "X-Amz-Date", valid_607048
  var valid_607049 = header.getOrDefault("X-Amz-Credential")
  valid_607049 = validateParameter(valid_607049, JString, required = false,
                                 default = nil)
  if valid_607049 != nil:
    section.add "X-Amz-Credential", valid_607049
  var valid_607050 = header.getOrDefault("X-Amz-Security-Token")
  valid_607050 = validateParameter(valid_607050, JString, required = false,
                                 default = nil)
  if valid_607050 != nil:
    section.add "X-Amz-Security-Token", valid_607050
  var valid_607051 = header.getOrDefault("X-Amz-Algorithm")
  valid_607051 = validateParameter(valid_607051, JString, required = false,
                                 default = nil)
  if valid_607051 != nil:
    section.add "X-Amz-Algorithm", valid_607051
  var valid_607052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607052 = validateParameter(valid_607052, JString, required = false,
                                 default = nil)
  if valid_607052 != nil:
    section.add "X-Amz-SignedHeaders", valid_607052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607054: Call_ListSkillsStoreCategories_607040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all categories in the Alexa skill store.
  ## 
  let valid = call_607054.validator(path, query, header, formData, body)
  let scheme = call_607054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607054.url(scheme.get, call_607054.host, call_607054.base,
                         call_607054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607054, url, valid)

proc call*(call_607055: Call_ListSkillsStoreCategories_607040; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSkillsStoreCategories
  ## Lists all categories in the Alexa skill store.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607056 = newJObject()
  var body_607057 = newJObject()
  add(query_607056, "MaxResults", newJString(MaxResults))
  add(query_607056, "NextToken", newJString(NextToken))
  if body != nil:
    body_607057 = body
  result = call_607055.call(nil, query_607056, nil, nil, body_607057)

var listSkillsStoreCategories* = Call_ListSkillsStoreCategories_607040(
    name: "listSkillsStoreCategories", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSkillsStoreCategories",
    validator: validate_ListSkillsStoreCategories_607041, base: "/",
    url: url_ListSkillsStoreCategories_607042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkillsStoreSkillsByCategory_607058 = ref object of OpenApiRestCall_605589
proc url_ListSkillsStoreSkillsByCategory_607060(protocol: Scheme; host: string;
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

proc validate_ListSkillsStoreSkillsByCategory_607059(path: JsonNode;
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
  var valid_607061 = query.getOrDefault("MaxResults")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "MaxResults", valid_607061
  var valid_607062 = query.getOrDefault("NextToken")
  valid_607062 = validateParameter(valid_607062, JString, required = false,
                                 default = nil)
  if valid_607062 != nil:
    section.add "NextToken", valid_607062
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607063 = header.getOrDefault("X-Amz-Target")
  valid_607063 = validateParameter(valid_607063, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkillsStoreSkillsByCategory"))
  if valid_607063 != nil:
    section.add "X-Amz-Target", valid_607063
  var valid_607064 = header.getOrDefault("X-Amz-Signature")
  valid_607064 = validateParameter(valid_607064, JString, required = false,
                                 default = nil)
  if valid_607064 != nil:
    section.add "X-Amz-Signature", valid_607064
  var valid_607065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607065 = validateParameter(valid_607065, JString, required = false,
                                 default = nil)
  if valid_607065 != nil:
    section.add "X-Amz-Content-Sha256", valid_607065
  var valid_607066 = header.getOrDefault("X-Amz-Date")
  valid_607066 = validateParameter(valid_607066, JString, required = false,
                                 default = nil)
  if valid_607066 != nil:
    section.add "X-Amz-Date", valid_607066
  var valid_607067 = header.getOrDefault("X-Amz-Credential")
  valid_607067 = validateParameter(valid_607067, JString, required = false,
                                 default = nil)
  if valid_607067 != nil:
    section.add "X-Amz-Credential", valid_607067
  var valid_607068 = header.getOrDefault("X-Amz-Security-Token")
  valid_607068 = validateParameter(valid_607068, JString, required = false,
                                 default = nil)
  if valid_607068 != nil:
    section.add "X-Amz-Security-Token", valid_607068
  var valid_607069 = header.getOrDefault("X-Amz-Algorithm")
  valid_607069 = validateParameter(valid_607069, JString, required = false,
                                 default = nil)
  if valid_607069 != nil:
    section.add "X-Amz-Algorithm", valid_607069
  var valid_607070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607070 = validateParameter(valid_607070, JString, required = false,
                                 default = nil)
  if valid_607070 != nil:
    section.add "X-Amz-SignedHeaders", valid_607070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607072: Call_ListSkillsStoreSkillsByCategory_607058;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all skills in the Alexa skill store by category.
  ## 
  let valid = call_607072.validator(path, query, header, formData, body)
  let scheme = call_607072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607072.url(scheme.get, call_607072.host, call_607072.base,
                         call_607072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607072, url, valid)

proc call*(call_607073: Call_ListSkillsStoreSkillsByCategory_607058;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSkillsStoreSkillsByCategory
  ## Lists all skills in the Alexa skill store by category.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607074 = newJObject()
  var body_607075 = newJObject()
  add(query_607074, "MaxResults", newJString(MaxResults))
  add(query_607074, "NextToken", newJString(NextToken))
  if body != nil:
    body_607075 = body
  result = call_607073.call(nil, query_607074, nil, nil, body_607075)

var listSkillsStoreSkillsByCategory* = Call_ListSkillsStoreSkillsByCategory_607058(
    name: "listSkillsStoreSkillsByCategory", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSkillsStoreSkillsByCategory",
    validator: validate_ListSkillsStoreSkillsByCategory_607059, base: "/",
    url: url_ListSkillsStoreSkillsByCategory_607060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSmartHomeAppliances_607076 = ref object of OpenApiRestCall_605589
proc url_ListSmartHomeAppliances_607078(protocol: Scheme; host: string; base: string;
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

proc validate_ListSmartHomeAppliances_607077(path: JsonNode; query: JsonNode;
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
  var valid_607079 = query.getOrDefault("MaxResults")
  valid_607079 = validateParameter(valid_607079, JString, required = false,
                                 default = nil)
  if valid_607079 != nil:
    section.add "MaxResults", valid_607079
  var valid_607080 = query.getOrDefault("NextToken")
  valid_607080 = validateParameter(valid_607080, JString, required = false,
                                 default = nil)
  if valid_607080 != nil:
    section.add "NextToken", valid_607080
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607081 = header.getOrDefault("X-Amz-Target")
  valid_607081 = validateParameter(valid_607081, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSmartHomeAppliances"))
  if valid_607081 != nil:
    section.add "X-Amz-Target", valid_607081
  var valid_607082 = header.getOrDefault("X-Amz-Signature")
  valid_607082 = validateParameter(valid_607082, JString, required = false,
                                 default = nil)
  if valid_607082 != nil:
    section.add "X-Amz-Signature", valid_607082
  var valid_607083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607083 = validateParameter(valid_607083, JString, required = false,
                                 default = nil)
  if valid_607083 != nil:
    section.add "X-Amz-Content-Sha256", valid_607083
  var valid_607084 = header.getOrDefault("X-Amz-Date")
  valid_607084 = validateParameter(valid_607084, JString, required = false,
                                 default = nil)
  if valid_607084 != nil:
    section.add "X-Amz-Date", valid_607084
  var valid_607085 = header.getOrDefault("X-Amz-Credential")
  valid_607085 = validateParameter(valid_607085, JString, required = false,
                                 default = nil)
  if valid_607085 != nil:
    section.add "X-Amz-Credential", valid_607085
  var valid_607086 = header.getOrDefault("X-Amz-Security-Token")
  valid_607086 = validateParameter(valid_607086, JString, required = false,
                                 default = nil)
  if valid_607086 != nil:
    section.add "X-Amz-Security-Token", valid_607086
  var valid_607087 = header.getOrDefault("X-Amz-Algorithm")
  valid_607087 = validateParameter(valid_607087, JString, required = false,
                                 default = nil)
  if valid_607087 != nil:
    section.add "X-Amz-Algorithm", valid_607087
  var valid_607088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607088 = validateParameter(valid_607088, JString, required = false,
                                 default = nil)
  if valid_607088 != nil:
    section.add "X-Amz-SignedHeaders", valid_607088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607090: Call_ListSmartHomeAppliances_607076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all of the smart home appliances associated with a room.
  ## 
  let valid = call_607090.validator(path, query, header, formData, body)
  let scheme = call_607090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607090.url(scheme.get, call_607090.host, call_607090.base,
                         call_607090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607090, url, valid)

proc call*(call_607091: Call_ListSmartHomeAppliances_607076; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSmartHomeAppliances
  ## Lists all of the smart home appliances associated with a room.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607092 = newJObject()
  var body_607093 = newJObject()
  add(query_607092, "MaxResults", newJString(MaxResults))
  add(query_607092, "NextToken", newJString(NextToken))
  if body != nil:
    body_607093 = body
  result = call_607091.call(nil, query_607092, nil, nil, body_607093)

var listSmartHomeAppliances* = Call_ListSmartHomeAppliances_607076(
    name: "listSmartHomeAppliances", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSmartHomeAppliances",
    validator: validate_ListSmartHomeAppliances_607077, base: "/",
    url: url_ListSmartHomeAppliances_607078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_607094 = ref object of OpenApiRestCall_605589
proc url_ListTags_607096(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTags_607095(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607097 = query.getOrDefault("MaxResults")
  valid_607097 = validateParameter(valid_607097, JString, required = false,
                                 default = nil)
  if valid_607097 != nil:
    section.add "MaxResults", valid_607097
  var valid_607098 = query.getOrDefault("NextToken")
  valid_607098 = validateParameter(valid_607098, JString, required = false,
                                 default = nil)
  if valid_607098 != nil:
    section.add "NextToken", valid_607098
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607099 = header.getOrDefault("X-Amz-Target")
  valid_607099 = validateParameter(valid_607099, JString, required = true, default = newJString(
      "AlexaForBusiness.ListTags"))
  if valid_607099 != nil:
    section.add "X-Amz-Target", valid_607099
  var valid_607100 = header.getOrDefault("X-Amz-Signature")
  valid_607100 = validateParameter(valid_607100, JString, required = false,
                                 default = nil)
  if valid_607100 != nil:
    section.add "X-Amz-Signature", valid_607100
  var valid_607101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607101 = validateParameter(valid_607101, JString, required = false,
                                 default = nil)
  if valid_607101 != nil:
    section.add "X-Amz-Content-Sha256", valid_607101
  var valid_607102 = header.getOrDefault("X-Amz-Date")
  valid_607102 = validateParameter(valid_607102, JString, required = false,
                                 default = nil)
  if valid_607102 != nil:
    section.add "X-Amz-Date", valid_607102
  var valid_607103 = header.getOrDefault("X-Amz-Credential")
  valid_607103 = validateParameter(valid_607103, JString, required = false,
                                 default = nil)
  if valid_607103 != nil:
    section.add "X-Amz-Credential", valid_607103
  var valid_607104 = header.getOrDefault("X-Amz-Security-Token")
  valid_607104 = validateParameter(valid_607104, JString, required = false,
                                 default = nil)
  if valid_607104 != nil:
    section.add "X-Amz-Security-Token", valid_607104
  var valid_607105 = header.getOrDefault("X-Amz-Algorithm")
  valid_607105 = validateParameter(valid_607105, JString, required = false,
                                 default = nil)
  if valid_607105 != nil:
    section.add "X-Amz-Algorithm", valid_607105
  var valid_607106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607106 = validateParameter(valid_607106, JString, required = false,
                                 default = nil)
  if valid_607106 != nil:
    section.add "X-Amz-SignedHeaders", valid_607106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607108: Call_ListTags_607094; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags for the specified resource.
  ## 
  let valid = call_607108.validator(path, query, header, formData, body)
  let scheme = call_607108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607108.url(scheme.get, call_607108.host, call_607108.base,
                         call_607108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607108, url, valid)

proc call*(call_607109: Call_ListTags_607094; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTags
  ## Lists all tags for the specified resource.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607110 = newJObject()
  var body_607111 = newJObject()
  add(query_607110, "MaxResults", newJString(MaxResults))
  add(query_607110, "NextToken", newJString(NextToken))
  if body != nil:
    body_607111 = body
  result = call_607109.call(nil, query_607110, nil, nil, body_607111)

var listTags* = Call_ListTags_607094(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ListTags",
                                  validator: validate_ListTags_607095, base: "/",
                                  url: url_ListTags_607096,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConferencePreference_607112 = ref object of OpenApiRestCall_605589
proc url_PutConferencePreference_607114(protocol: Scheme; host: string; base: string;
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

proc validate_PutConferencePreference_607113(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607115 = header.getOrDefault("X-Amz-Target")
  valid_607115 = validateParameter(valid_607115, JString, required = true, default = newJString(
      "AlexaForBusiness.PutConferencePreference"))
  if valid_607115 != nil:
    section.add "X-Amz-Target", valid_607115
  var valid_607116 = header.getOrDefault("X-Amz-Signature")
  valid_607116 = validateParameter(valid_607116, JString, required = false,
                                 default = nil)
  if valid_607116 != nil:
    section.add "X-Amz-Signature", valid_607116
  var valid_607117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607117 = validateParameter(valid_607117, JString, required = false,
                                 default = nil)
  if valid_607117 != nil:
    section.add "X-Amz-Content-Sha256", valid_607117
  var valid_607118 = header.getOrDefault("X-Amz-Date")
  valid_607118 = validateParameter(valid_607118, JString, required = false,
                                 default = nil)
  if valid_607118 != nil:
    section.add "X-Amz-Date", valid_607118
  var valid_607119 = header.getOrDefault("X-Amz-Credential")
  valid_607119 = validateParameter(valid_607119, JString, required = false,
                                 default = nil)
  if valid_607119 != nil:
    section.add "X-Amz-Credential", valid_607119
  var valid_607120 = header.getOrDefault("X-Amz-Security-Token")
  valid_607120 = validateParameter(valid_607120, JString, required = false,
                                 default = nil)
  if valid_607120 != nil:
    section.add "X-Amz-Security-Token", valid_607120
  var valid_607121 = header.getOrDefault("X-Amz-Algorithm")
  valid_607121 = validateParameter(valid_607121, JString, required = false,
                                 default = nil)
  if valid_607121 != nil:
    section.add "X-Amz-Algorithm", valid_607121
  var valid_607122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607122 = validateParameter(valid_607122, JString, required = false,
                                 default = nil)
  if valid_607122 != nil:
    section.add "X-Amz-SignedHeaders", valid_607122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607124: Call_PutConferencePreference_607112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the conference preferences on a specific conference provider at the account level.
  ## 
  let valid = call_607124.validator(path, query, header, formData, body)
  let scheme = call_607124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607124.url(scheme.get, call_607124.host, call_607124.base,
                         call_607124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607124, url, valid)

proc call*(call_607125: Call_PutConferencePreference_607112; body: JsonNode): Recallable =
  ## putConferencePreference
  ## Sets the conference preferences on a specific conference provider at the account level.
  ##   body: JObject (required)
  var body_607126 = newJObject()
  if body != nil:
    body_607126 = body
  result = call_607125.call(nil, nil, nil, nil, body_607126)

var putConferencePreference* = Call_PutConferencePreference_607112(
    name: "putConferencePreference", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutConferencePreference",
    validator: validate_PutConferencePreference_607113, base: "/",
    url: url_PutConferencePreference_607114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInvitationConfiguration_607127 = ref object of OpenApiRestCall_605589
proc url_PutInvitationConfiguration_607129(protocol: Scheme; host: string;
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

proc validate_PutInvitationConfiguration_607128(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607130 = header.getOrDefault("X-Amz-Target")
  valid_607130 = validateParameter(valid_607130, JString, required = true, default = newJString(
      "AlexaForBusiness.PutInvitationConfiguration"))
  if valid_607130 != nil:
    section.add "X-Amz-Target", valid_607130
  var valid_607131 = header.getOrDefault("X-Amz-Signature")
  valid_607131 = validateParameter(valid_607131, JString, required = false,
                                 default = nil)
  if valid_607131 != nil:
    section.add "X-Amz-Signature", valid_607131
  var valid_607132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607132 = validateParameter(valid_607132, JString, required = false,
                                 default = nil)
  if valid_607132 != nil:
    section.add "X-Amz-Content-Sha256", valid_607132
  var valid_607133 = header.getOrDefault("X-Amz-Date")
  valid_607133 = validateParameter(valid_607133, JString, required = false,
                                 default = nil)
  if valid_607133 != nil:
    section.add "X-Amz-Date", valid_607133
  var valid_607134 = header.getOrDefault("X-Amz-Credential")
  valid_607134 = validateParameter(valid_607134, JString, required = false,
                                 default = nil)
  if valid_607134 != nil:
    section.add "X-Amz-Credential", valid_607134
  var valid_607135 = header.getOrDefault("X-Amz-Security-Token")
  valid_607135 = validateParameter(valid_607135, JString, required = false,
                                 default = nil)
  if valid_607135 != nil:
    section.add "X-Amz-Security-Token", valid_607135
  var valid_607136 = header.getOrDefault("X-Amz-Algorithm")
  valid_607136 = validateParameter(valid_607136, JString, required = false,
                                 default = nil)
  if valid_607136 != nil:
    section.add "X-Amz-Algorithm", valid_607136
  var valid_607137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607137 = validateParameter(valid_607137, JString, required = false,
                                 default = nil)
  if valid_607137 != nil:
    section.add "X-Amz-SignedHeaders", valid_607137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607139: Call_PutInvitationConfiguration_607127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the email template for the user enrollment invitation with the specified attributes.
  ## 
  let valid = call_607139.validator(path, query, header, formData, body)
  let scheme = call_607139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607139.url(scheme.get, call_607139.host, call_607139.base,
                         call_607139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607139, url, valid)

proc call*(call_607140: Call_PutInvitationConfiguration_607127; body: JsonNode): Recallable =
  ## putInvitationConfiguration
  ## Configures the email template for the user enrollment invitation with the specified attributes.
  ##   body: JObject (required)
  var body_607141 = newJObject()
  if body != nil:
    body_607141 = body
  result = call_607140.call(nil, nil, nil, nil, body_607141)

var putInvitationConfiguration* = Call_PutInvitationConfiguration_607127(
    name: "putInvitationConfiguration", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutInvitationConfiguration",
    validator: validate_PutInvitationConfiguration_607128, base: "/",
    url: url_PutInvitationConfiguration_607129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRoomSkillParameter_607142 = ref object of OpenApiRestCall_605589
proc url_PutRoomSkillParameter_607144(protocol: Scheme; host: string; base: string;
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

proc validate_PutRoomSkillParameter_607143(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607145 = header.getOrDefault("X-Amz-Target")
  valid_607145 = validateParameter(valid_607145, JString, required = true, default = newJString(
      "AlexaForBusiness.PutRoomSkillParameter"))
  if valid_607145 != nil:
    section.add "X-Amz-Target", valid_607145
  var valid_607146 = header.getOrDefault("X-Amz-Signature")
  valid_607146 = validateParameter(valid_607146, JString, required = false,
                                 default = nil)
  if valid_607146 != nil:
    section.add "X-Amz-Signature", valid_607146
  var valid_607147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607147 = validateParameter(valid_607147, JString, required = false,
                                 default = nil)
  if valid_607147 != nil:
    section.add "X-Amz-Content-Sha256", valid_607147
  var valid_607148 = header.getOrDefault("X-Amz-Date")
  valid_607148 = validateParameter(valid_607148, JString, required = false,
                                 default = nil)
  if valid_607148 != nil:
    section.add "X-Amz-Date", valid_607148
  var valid_607149 = header.getOrDefault("X-Amz-Credential")
  valid_607149 = validateParameter(valid_607149, JString, required = false,
                                 default = nil)
  if valid_607149 != nil:
    section.add "X-Amz-Credential", valid_607149
  var valid_607150 = header.getOrDefault("X-Amz-Security-Token")
  valid_607150 = validateParameter(valid_607150, JString, required = false,
                                 default = nil)
  if valid_607150 != nil:
    section.add "X-Amz-Security-Token", valid_607150
  var valid_607151 = header.getOrDefault("X-Amz-Algorithm")
  valid_607151 = validateParameter(valid_607151, JString, required = false,
                                 default = nil)
  if valid_607151 != nil:
    section.add "X-Amz-Algorithm", valid_607151
  var valid_607152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607152 = validateParameter(valid_607152, JString, required = false,
                                 default = nil)
  if valid_607152 != nil:
    section.add "X-Amz-SignedHeaders", valid_607152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607154: Call_PutRoomSkillParameter_607142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room skill parameter details by room, skill, and parameter key ID. Not all skills have a room skill parameter.
  ## 
  let valid = call_607154.validator(path, query, header, formData, body)
  let scheme = call_607154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607154.url(scheme.get, call_607154.host, call_607154.base,
                         call_607154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607154, url, valid)

proc call*(call_607155: Call_PutRoomSkillParameter_607142; body: JsonNode): Recallable =
  ## putRoomSkillParameter
  ## Updates room skill parameter details by room, skill, and parameter key ID. Not all skills have a room skill parameter.
  ##   body: JObject (required)
  var body_607156 = newJObject()
  if body != nil:
    body_607156 = body
  result = call_607155.call(nil, nil, nil, nil, body_607156)

var putRoomSkillParameter* = Call_PutRoomSkillParameter_607142(
    name: "putRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutRoomSkillParameter",
    validator: validate_PutRoomSkillParameter_607143, base: "/",
    url: url_PutRoomSkillParameter_607144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSkillAuthorization_607157 = ref object of OpenApiRestCall_605589
proc url_PutSkillAuthorization_607159(protocol: Scheme; host: string; base: string;
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

proc validate_PutSkillAuthorization_607158(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607160 = header.getOrDefault("X-Amz-Target")
  valid_607160 = validateParameter(valid_607160, JString, required = true, default = newJString(
      "AlexaForBusiness.PutSkillAuthorization"))
  if valid_607160 != nil:
    section.add "X-Amz-Target", valid_607160
  var valid_607161 = header.getOrDefault("X-Amz-Signature")
  valid_607161 = validateParameter(valid_607161, JString, required = false,
                                 default = nil)
  if valid_607161 != nil:
    section.add "X-Amz-Signature", valid_607161
  var valid_607162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607162 = validateParameter(valid_607162, JString, required = false,
                                 default = nil)
  if valid_607162 != nil:
    section.add "X-Amz-Content-Sha256", valid_607162
  var valid_607163 = header.getOrDefault("X-Amz-Date")
  valid_607163 = validateParameter(valid_607163, JString, required = false,
                                 default = nil)
  if valid_607163 != nil:
    section.add "X-Amz-Date", valid_607163
  var valid_607164 = header.getOrDefault("X-Amz-Credential")
  valid_607164 = validateParameter(valid_607164, JString, required = false,
                                 default = nil)
  if valid_607164 != nil:
    section.add "X-Amz-Credential", valid_607164
  var valid_607165 = header.getOrDefault("X-Amz-Security-Token")
  valid_607165 = validateParameter(valid_607165, JString, required = false,
                                 default = nil)
  if valid_607165 != nil:
    section.add "X-Amz-Security-Token", valid_607165
  var valid_607166 = header.getOrDefault("X-Amz-Algorithm")
  valid_607166 = validateParameter(valid_607166, JString, required = false,
                                 default = nil)
  if valid_607166 != nil:
    section.add "X-Amz-Algorithm", valid_607166
  var valid_607167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607167 = validateParameter(valid_607167, JString, required = false,
                                 default = nil)
  if valid_607167 != nil:
    section.add "X-Amz-SignedHeaders", valid_607167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607169: Call_PutSkillAuthorization_607157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Links a user's account to a third-party skill provider. If this API operation is called by an assumed IAM role, the skill being linked must be a private skill. Also, the skill must be owned by the AWS account that assumed the IAM role.
  ## 
  let valid = call_607169.validator(path, query, header, formData, body)
  let scheme = call_607169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607169.url(scheme.get, call_607169.host, call_607169.base,
                         call_607169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607169, url, valid)

proc call*(call_607170: Call_PutSkillAuthorization_607157; body: JsonNode): Recallable =
  ## putSkillAuthorization
  ## Links a user's account to a third-party skill provider. If this API operation is called by an assumed IAM role, the skill being linked must be a private skill. Also, the skill must be owned by the AWS account that assumed the IAM role.
  ##   body: JObject (required)
  var body_607171 = newJObject()
  if body != nil:
    body_607171 = body
  result = call_607170.call(nil, nil, nil, nil, body_607171)

var putSkillAuthorization* = Call_PutSkillAuthorization_607157(
    name: "putSkillAuthorization", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutSkillAuthorization",
    validator: validate_PutSkillAuthorization_607158, base: "/",
    url: url_PutSkillAuthorization_607159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterAVSDevice_607172 = ref object of OpenApiRestCall_605589
proc url_RegisterAVSDevice_607174(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterAVSDevice_607173(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607175 = header.getOrDefault("X-Amz-Target")
  valid_607175 = validateParameter(valid_607175, JString, required = true, default = newJString(
      "AlexaForBusiness.RegisterAVSDevice"))
  if valid_607175 != nil:
    section.add "X-Amz-Target", valid_607175
  var valid_607176 = header.getOrDefault("X-Amz-Signature")
  valid_607176 = validateParameter(valid_607176, JString, required = false,
                                 default = nil)
  if valid_607176 != nil:
    section.add "X-Amz-Signature", valid_607176
  var valid_607177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607177 = validateParameter(valid_607177, JString, required = false,
                                 default = nil)
  if valid_607177 != nil:
    section.add "X-Amz-Content-Sha256", valid_607177
  var valid_607178 = header.getOrDefault("X-Amz-Date")
  valid_607178 = validateParameter(valid_607178, JString, required = false,
                                 default = nil)
  if valid_607178 != nil:
    section.add "X-Amz-Date", valid_607178
  var valid_607179 = header.getOrDefault("X-Amz-Credential")
  valid_607179 = validateParameter(valid_607179, JString, required = false,
                                 default = nil)
  if valid_607179 != nil:
    section.add "X-Amz-Credential", valid_607179
  var valid_607180 = header.getOrDefault("X-Amz-Security-Token")
  valid_607180 = validateParameter(valid_607180, JString, required = false,
                                 default = nil)
  if valid_607180 != nil:
    section.add "X-Amz-Security-Token", valid_607180
  var valid_607181 = header.getOrDefault("X-Amz-Algorithm")
  valid_607181 = validateParameter(valid_607181, JString, required = false,
                                 default = nil)
  if valid_607181 != nil:
    section.add "X-Amz-Algorithm", valid_607181
  var valid_607182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607182 = validateParameter(valid_607182, JString, required = false,
                                 default = nil)
  if valid_607182 != nil:
    section.add "X-Amz-SignedHeaders", valid_607182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607184: Call_RegisterAVSDevice_607172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers an Alexa-enabled device built by an Original Equipment Manufacturer (OEM) using Alexa Voice Service (AVS).
  ## 
  let valid = call_607184.validator(path, query, header, formData, body)
  let scheme = call_607184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607184.url(scheme.get, call_607184.host, call_607184.base,
                         call_607184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607184, url, valid)

proc call*(call_607185: Call_RegisterAVSDevice_607172; body: JsonNode): Recallable =
  ## registerAVSDevice
  ## Registers an Alexa-enabled device built by an Original Equipment Manufacturer (OEM) using Alexa Voice Service (AVS).
  ##   body: JObject (required)
  var body_607186 = newJObject()
  if body != nil:
    body_607186 = body
  result = call_607185.call(nil, nil, nil, nil, body_607186)

var registerAVSDevice* = Call_RegisterAVSDevice_607172(name: "registerAVSDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.RegisterAVSDevice",
    validator: validate_RegisterAVSDevice_607173, base: "/",
    url: url_RegisterAVSDevice_607174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectSkill_607187 = ref object of OpenApiRestCall_605589
proc url_RejectSkill_607189(protocol: Scheme; host: string; base: string;
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

proc validate_RejectSkill_607188(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607190 = header.getOrDefault("X-Amz-Target")
  valid_607190 = validateParameter(valid_607190, JString, required = true, default = newJString(
      "AlexaForBusiness.RejectSkill"))
  if valid_607190 != nil:
    section.add "X-Amz-Target", valid_607190
  var valid_607191 = header.getOrDefault("X-Amz-Signature")
  valid_607191 = validateParameter(valid_607191, JString, required = false,
                                 default = nil)
  if valid_607191 != nil:
    section.add "X-Amz-Signature", valid_607191
  var valid_607192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607192 = validateParameter(valid_607192, JString, required = false,
                                 default = nil)
  if valid_607192 != nil:
    section.add "X-Amz-Content-Sha256", valid_607192
  var valid_607193 = header.getOrDefault("X-Amz-Date")
  valid_607193 = validateParameter(valid_607193, JString, required = false,
                                 default = nil)
  if valid_607193 != nil:
    section.add "X-Amz-Date", valid_607193
  var valid_607194 = header.getOrDefault("X-Amz-Credential")
  valid_607194 = validateParameter(valid_607194, JString, required = false,
                                 default = nil)
  if valid_607194 != nil:
    section.add "X-Amz-Credential", valid_607194
  var valid_607195 = header.getOrDefault("X-Amz-Security-Token")
  valid_607195 = validateParameter(valid_607195, JString, required = false,
                                 default = nil)
  if valid_607195 != nil:
    section.add "X-Amz-Security-Token", valid_607195
  var valid_607196 = header.getOrDefault("X-Amz-Algorithm")
  valid_607196 = validateParameter(valid_607196, JString, required = false,
                                 default = nil)
  if valid_607196 != nil:
    section.add "X-Amz-Algorithm", valid_607196
  var valid_607197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607197 = validateParameter(valid_607197, JString, required = false,
                                 default = nil)
  if valid_607197 != nil:
    section.add "X-Amz-SignedHeaders", valid_607197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607199: Call_RejectSkill_607187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a skill from the organization under a user's AWS account. If the skill is a private skill, it moves to an AcceptStatus of PENDING. Any private or public skill that is rejected can be added later by calling the ApproveSkill API. 
  ## 
  let valid = call_607199.validator(path, query, header, formData, body)
  let scheme = call_607199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607199.url(scheme.get, call_607199.host, call_607199.base,
                         call_607199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607199, url, valid)

proc call*(call_607200: Call_RejectSkill_607187; body: JsonNode): Recallable =
  ## rejectSkill
  ## Disassociates a skill from the organization under a user's AWS account. If the skill is a private skill, it moves to an AcceptStatus of PENDING. Any private or public skill that is rejected can be added later by calling the ApproveSkill API. 
  ##   body: JObject (required)
  var body_607201 = newJObject()
  if body != nil:
    body_607201 = body
  result = call_607200.call(nil, nil, nil, nil, body_607201)

var rejectSkill* = Call_RejectSkill_607187(name: "rejectSkill",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.RejectSkill",
                                        validator: validate_RejectSkill_607188,
                                        base: "/", url: url_RejectSkill_607189,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResolveRoom_607202 = ref object of OpenApiRestCall_605589
proc url_ResolveRoom_607204(protocol: Scheme; host: string; base: string;
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

proc validate_ResolveRoom_607203(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607205 = header.getOrDefault("X-Amz-Target")
  valid_607205 = validateParameter(valid_607205, JString, required = true, default = newJString(
      "AlexaForBusiness.ResolveRoom"))
  if valid_607205 != nil:
    section.add "X-Amz-Target", valid_607205
  var valid_607206 = header.getOrDefault("X-Amz-Signature")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "X-Amz-Signature", valid_607206
  var valid_607207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607207 = validateParameter(valid_607207, JString, required = false,
                                 default = nil)
  if valid_607207 != nil:
    section.add "X-Amz-Content-Sha256", valid_607207
  var valid_607208 = header.getOrDefault("X-Amz-Date")
  valid_607208 = validateParameter(valid_607208, JString, required = false,
                                 default = nil)
  if valid_607208 != nil:
    section.add "X-Amz-Date", valid_607208
  var valid_607209 = header.getOrDefault("X-Amz-Credential")
  valid_607209 = validateParameter(valid_607209, JString, required = false,
                                 default = nil)
  if valid_607209 != nil:
    section.add "X-Amz-Credential", valid_607209
  var valid_607210 = header.getOrDefault("X-Amz-Security-Token")
  valid_607210 = validateParameter(valid_607210, JString, required = false,
                                 default = nil)
  if valid_607210 != nil:
    section.add "X-Amz-Security-Token", valid_607210
  var valid_607211 = header.getOrDefault("X-Amz-Algorithm")
  valid_607211 = validateParameter(valid_607211, JString, required = false,
                                 default = nil)
  if valid_607211 != nil:
    section.add "X-Amz-Algorithm", valid_607211
  var valid_607212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607212 = validateParameter(valid_607212, JString, required = false,
                                 default = nil)
  if valid_607212 != nil:
    section.add "X-Amz-SignedHeaders", valid_607212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607214: Call_ResolveRoom_607202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Determines the details for the room from which a skill request was invoked. This operation is used by skill developers.
  ## 
  let valid = call_607214.validator(path, query, header, formData, body)
  let scheme = call_607214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607214.url(scheme.get, call_607214.host, call_607214.base,
                         call_607214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607214, url, valid)

proc call*(call_607215: Call_ResolveRoom_607202; body: JsonNode): Recallable =
  ## resolveRoom
  ## Determines the details for the room from which a skill request was invoked. This operation is used by skill developers.
  ##   body: JObject (required)
  var body_607216 = newJObject()
  if body != nil:
    body_607216 = body
  result = call_607215.call(nil, nil, nil, nil, body_607216)

var resolveRoom* = Call_ResolveRoom_607202(name: "resolveRoom",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ResolveRoom",
                                        validator: validate_ResolveRoom_607203,
                                        base: "/", url: url_ResolveRoom_607204,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeInvitation_607217 = ref object of OpenApiRestCall_605589
proc url_RevokeInvitation_607219(protocol: Scheme; host: string; base: string;
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

proc validate_RevokeInvitation_607218(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607220 = header.getOrDefault("X-Amz-Target")
  valid_607220 = validateParameter(valid_607220, JString, required = true, default = newJString(
      "AlexaForBusiness.RevokeInvitation"))
  if valid_607220 != nil:
    section.add "X-Amz-Target", valid_607220
  var valid_607221 = header.getOrDefault("X-Amz-Signature")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "X-Amz-Signature", valid_607221
  var valid_607222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607222 = validateParameter(valid_607222, JString, required = false,
                                 default = nil)
  if valid_607222 != nil:
    section.add "X-Amz-Content-Sha256", valid_607222
  var valid_607223 = header.getOrDefault("X-Amz-Date")
  valid_607223 = validateParameter(valid_607223, JString, required = false,
                                 default = nil)
  if valid_607223 != nil:
    section.add "X-Amz-Date", valid_607223
  var valid_607224 = header.getOrDefault("X-Amz-Credential")
  valid_607224 = validateParameter(valid_607224, JString, required = false,
                                 default = nil)
  if valid_607224 != nil:
    section.add "X-Amz-Credential", valid_607224
  var valid_607225 = header.getOrDefault("X-Amz-Security-Token")
  valid_607225 = validateParameter(valid_607225, JString, required = false,
                                 default = nil)
  if valid_607225 != nil:
    section.add "X-Amz-Security-Token", valid_607225
  var valid_607226 = header.getOrDefault("X-Amz-Algorithm")
  valid_607226 = validateParameter(valid_607226, JString, required = false,
                                 default = nil)
  if valid_607226 != nil:
    section.add "X-Amz-Algorithm", valid_607226
  var valid_607227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607227 = validateParameter(valid_607227, JString, required = false,
                                 default = nil)
  if valid_607227 != nil:
    section.add "X-Amz-SignedHeaders", valid_607227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607229: Call_RevokeInvitation_607217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes an invitation and invalidates the enrollment URL.
  ## 
  let valid = call_607229.validator(path, query, header, formData, body)
  let scheme = call_607229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607229.url(scheme.get, call_607229.host, call_607229.base,
                         call_607229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607229, url, valid)

proc call*(call_607230: Call_RevokeInvitation_607217; body: JsonNode): Recallable =
  ## revokeInvitation
  ## Revokes an invitation and invalidates the enrollment URL.
  ##   body: JObject (required)
  var body_607231 = newJObject()
  if body != nil:
    body_607231 = body
  result = call_607230.call(nil, nil, nil, nil, body_607231)

var revokeInvitation* = Call_RevokeInvitation_607217(name: "revokeInvitation",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.RevokeInvitation",
    validator: validate_RevokeInvitation_607218, base: "/",
    url: url_RevokeInvitation_607219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAddressBooks_607232 = ref object of OpenApiRestCall_605589
proc url_SearchAddressBooks_607234(protocol: Scheme; host: string; base: string;
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

proc validate_SearchAddressBooks_607233(path: JsonNode; query: JsonNode;
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
  var valid_607235 = query.getOrDefault("MaxResults")
  valid_607235 = validateParameter(valid_607235, JString, required = false,
                                 default = nil)
  if valid_607235 != nil:
    section.add "MaxResults", valid_607235
  var valid_607236 = query.getOrDefault("NextToken")
  valid_607236 = validateParameter(valid_607236, JString, required = false,
                                 default = nil)
  if valid_607236 != nil:
    section.add "NextToken", valid_607236
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607237 = header.getOrDefault("X-Amz-Target")
  valid_607237 = validateParameter(valid_607237, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchAddressBooks"))
  if valid_607237 != nil:
    section.add "X-Amz-Target", valid_607237
  var valid_607238 = header.getOrDefault("X-Amz-Signature")
  valid_607238 = validateParameter(valid_607238, JString, required = false,
                                 default = nil)
  if valid_607238 != nil:
    section.add "X-Amz-Signature", valid_607238
  var valid_607239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607239 = validateParameter(valid_607239, JString, required = false,
                                 default = nil)
  if valid_607239 != nil:
    section.add "X-Amz-Content-Sha256", valid_607239
  var valid_607240 = header.getOrDefault("X-Amz-Date")
  valid_607240 = validateParameter(valid_607240, JString, required = false,
                                 default = nil)
  if valid_607240 != nil:
    section.add "X-Amz-Date", valid_607240
  var valid_607241 = header.getOrDefault("X-Amz-Credential")
  valid_607241 = validateParameter(valid_607241, JString, required = false,
                                 default = nil)
  if valid_607241 != nil:
    section.add "X-Amz-Credential", valid_607241
  var valid_607242 = header.getOrDefault("X-Amz-Security-Token")
  valid_607242 = validateParameter(valid_607242, JString, required = false,
                                 default = nil)
  if valid_607242 != nil:
    section.add "X-Amz-Security-Token", valid_607242
  var valid_607243 = header.getOrDefault("X-Amz-Algorithm")
  valid_607243 = validateParameter(valid_607243, JString, required = false,
                                 default = nil)
  if valid_607243 != nil:
    section.add "X-Amz-Algorithm", valid_607243
  var valid_607244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607244 = validateParameter(valid_607244, JString, required = false,
                                 default = nil)
  if valid_607244 != nil:
    section.add "X-Amz-SignedHeaders", valid_607244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607246: Call_SearchAddressBooks_607232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_607246.validator(path, query, header, formData, body)
  let scheme = call_607246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607246.url(scheme.get, call_607246.host, call_607246.base,
                         call_607246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607246, url, valid)

proc call*(call_607247: Call_SearchAddressBooks_607232; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchAddressBooks
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607248 = newJObject()
  var body_607249 = newJObject()
  add(query_607248, "MaxResults", newJString(MaxResults))
  add(query_607248, "NextToken", newJString(NextToken))
  if body != nil:
    body_607249 = body
  result = call_607247.call(nil, query_607248, nil, nil, body_607249)

var searchAddressBooks* = Call_SearchAddressBooks_607232(
    name: "searchAddressBooks", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchAddressBooks",
    validator: validate_SearchAddressBooks_607233, base: "/",
    url: url_SearchAddressBooks_607234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchContacts_607250 = ref object of OpenApiRestCall_605589
proc url_SearchContacts_607252(protocol: Scheme; host: string; base: string;
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

proc validate_SearchContacts_607251(path: JsonNode; query: JsonNode;
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
  var valid_607253 = query.getOrDefault("MaxResults")
  valid_607253 = validateParameter(valid_607253, JString, required = false,
                                 default = nil)
  if valid_607253 != nil:
    section.add "MaxResults", valid_607253
  var valid_607254 = query.getOrDefault("NextToken")
  valid_607254 = validateParameter(valid_607254, JString, required = false,
                                 default = nil)
  if valid_607254 != nil:
    section.add "NextToken", valid_607254
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607255 = header.getOrDefault("X-Amz-Target")
  valid_607255 = validateParameter(valid_607255, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchContacts"))
  if valid_607255 != nil:
    section.add "X-Amz-Target", valid_607255
  var valid_607256 = header.getOrDefault("X-Amz-Signature")
  valid_607256 = validateParameter(valid_607256, JString, required = false,
                                 default = nil)
  if valid_607256 != nil:
    section.add "X-Amz-Signature", valid_607256
  var valid_607257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607257 = validateParameter(valid_607257, JString, required = false,
                                 default = nil)
  if valid_607257 != nil:
    section.add "X-Amz-Content-Sha256", valid_607257
  var valid_607258 = header.getOrDefault("X-Amz-Date")
  valid_607258 = validateParameter(valid_607258, JString, required = false,
                                 default = nil)
  if valid_607258 != nil:
    section.add "X-Amz-Date", valid_607258
  var valid_607259 = header.getOrDefault("X-Amz-Credential")
  valid_607259 = validateParameter(valid_607259, JString, required = false,
                                 default = nil)
  if valid_607259 != nil:
    section.add "X-Amz-Credential", valid_607259
  var valid_607260 = header.getOrDefault("X-Amz-Security-Token")
  valid_607260 = validateParameter(valid_607260, JString, required = false,
                                 default = nil)
  if valid_607260 != nil:
    section.add "X-Amz-Security-Token", valid_607260
  var valid_607261 = header.getOrDefault("X-Amz-Algorithm")
  valid_607261 = validateParameter(valid_607261, JString, required = false,
                                 default = nil)
  if valid_607261 != nil:
    section.add "X-Amz-Algorithm", valid_607261
  var valid_607262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607262 = validateParameter(valid_607262, JString, required = false,
                                 default = nil)
  if valid_607262 != nil:
    section.add "X-Amz-SignedHeaders", valid_607262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607264: Call_SearchContacts_607250; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_607264.validator(path, query, header, formData, body)
  let scheme = call_607264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607264.url(scheme.get, call_607264.host, call_607264.base,
                         call_607264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607264, url, valid)

proc call*(call_607265: Call_SearchContacts_607250; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchContacts
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607266 = newJObject()
  var body_607267 = newJObject()
  add(query_607266, "MaxResults", newJString(MaxResults))
  add(query_607266, "NextToken", newJString(NextToken))
  if body != nil:
    body_607267 = body
  result = call_607265.call(nil, query_607266, nil, nil, body_607267)

var searchContacts* = Call_SearchContacts_607250(name: "searchContacts",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchContacts",
    validator: validate_SearchContacts_607251, base: "/", url: url_SearchContacts_607252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchDevices_607268 = ref object of OpenApiRestCall_605589
proc url_SearchDevices_607270(protocol: Scheme; host: string; base: string;
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

proc validate_SearchDevices_607269(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607271 = query.getOrDefault("MaxResults")
  valid_607271 = validateParameter(valid_607271, JString, required = false,
                                 default = nil)
  if valid_607271 != nil:
    section.add "MaxResults", valid_607271
  var valid_607272 = query.getOrDefault("NextToken")
  valid_607272 = validateParameter(valid_607272, JString, required = false,
                                 default = nil)
  if valid_607272 != nil:
    section.add "NextToken", valid_607272
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607273 = header.getOrDefault("X-Amz-Target")
  valid_607273 = validateParameter(valid_607273, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchDevices"))
  if valid_607273 != nil:
    section.add "X-Amz-Target", valid_607273
  var valid_607274 = header.getOrDefault("X-Amz-Signature")
  valid_607274 = validateParameter(valid_607274, JString, required = false,
                                 default = nil)
  if valid_607274 != nil:
    section.add "X-Amz-Signature", valid_607274
  var valid_607275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607275 = validateParameter(valid_607275, JString, required = false,
                                 default = nil)
  if valid_607275 != nil:
    section.add "X-Amz-Content-Sha256", valid_607275
  var valid_607276 = header.getOrDefault("X-Amz-Date")
  valid_607276 = validateParameter(valid_607276, JString, required = false,
                                 default = nil)
  if valid_607276 != nil:
    section.add "X-Amz-Date", valid_607276
  var valid_607277 = header.getOrDefault("X-Amz-Credential")
  valid_607277 = validateParameter(valid_607277, JString, required = false,
                                 default = nil)
  if valid_607277 != nil:
    section.add "X-Amz-Credential", valid_607277
  var valid_607278 = header.getOrDefault("X-Amz-Security-Token")
  valid_607278 = validateParameter(valid_607278, JString, required = false,
                                 default = nil)
  if valid_607278 != nil:
    section.add "X-Amz-Security-Token", valid_607278
  var valid_607279 = header.getOrDefault("X-Amz-Algorithm")
  valid_607279 = validateParameter(valid_607279, JString, required = false,
                                 default = nil)
  if valid_607279 != nil:
    section.add "X-Amz-Algorithm", valid_607279
  var valid_607280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-SignedHeaders", valid_607280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607282: Call_SearchDevices_607268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches devices and lists the ones that meet a set of filter criteria.
  ## 
  let valid = call_607282.validator(path, query, header, formData, body)
  let scheme = call_607282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607282.url(scheme.get, call_607282.host, call_607282.base,
                         call_607282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607282, url, valid)

proc call*(call_607283: Call_SearchDevices_607268; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchDevices
  ## Searches devices and lists the ones that meet a set of filter criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607284 = newJObject()
  var body_607285 = newJObject()
  add(query_607284, "MaxResults", newJString(MaxResults))
  add(query_607284, "NextToken", newJString(NextToken))
  if body != nil:
    body_607285 = body
  result = call_607283.call(nil, query_607284, nil, nil, body_607285)

var searchDevices* = Call_SearchDevices_607268(name: "searchDevices",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchDevices",
    validator: validate_SearchDevices_607269, base: "/", url: url_SearchDevices_607270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchNetworkProfiles_607286 = ref object of OpenApiRestCall_605589
proc url_SearchNetworkProfiles_607288(protocol: Scheme; host: string; base: string;
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

proc validate_SearchNetworkProfiles_607287(path: JsonNode; query: JsonNode;
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
  var valid_607289 = query.getOrDefault("MaxResults")
  valid_607289 = validateParameter(valid_607289, JString, required = false,
                                 default = nil)
  if valid_607289 != nil:
    section.add "MaxResults", valid_607289
  var valid_607290 = query.getOrDefault("NextToken")
  valid_607290 = validateParameter(valid_607290, JString, required = false,
                                 default = nil)
  if valid_607290 != nil:
    section.add "NextToken", valid_607290
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607291 = header.getOrDefault("X-Amz-Target")
  valid_607291 = validateParameter(valid_607291, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchNetworkProfiles"))
  if valid_607291 != nil:
    section.add "X-Amz-Target", valid_607291
  var valid_607292 = header.getOrDefault("X-Amz-Signature")
  valid_607292 = validateParameter(valid_607292, JString, required = false,
                                 default = nil)
  if valid_607292 != nil:
    section.add "X-Amz-Signature", valid_607292
  var valid_607293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607293 = validateParameter(valid_607293, JString, required = false,
                                 default = nil)
  if valid_607293 != nil:
    section.add "X-Amz-Content-Sha256", valid_607293
  var valid_607294 = header.getOrDefault("X-Amz-Date")
  valid_607294 = validateParameter(valid_607294, JString, required = false,
                                 default = nil)
  if valid_607294 != nil:
    section.add "X-Amz-Date", valid_607294
  var valid_607295 = header.getOrDefault("X-Amz-Credential")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "X-Amz-Credential", valid_607295
  var valid_607296 = header.getOrDefault("X-Amz-Security-Token")
  valid_607296 = validateParameter(valid_607296, JString, required = false,
                                 default = nil)
  if valid_607296 != nil:
    section.add "X-Amz-Security-Token", valid_607296
  var valid_607297 = header.getOrDefault("X-Amz-Algorithm")
  valid_607297 = validateParameter(valid_607297, JString, required = false,
                                 default = nil)
  if valid_607297 != nil:
    section.add "X-Amz-Algorithm", valid_607297
  var valid_607298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607298 = validateParameter(valid_607298, JString, required = false,
                                 default = nil)
  if valid_607298 != nil:
    section.add "X-Amz-SignedHeaders", valid_607298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607300: Call_SearchNetworkProfiles_607286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_607300.validator(path, query, header, formData, body)
  let scheme = call_607300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607300.url(scheme.get, call_607300.host, call_607300.base,
                         call_607300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607300, url, valid)

proc call*(call_607301: Call_SearchNetworkProfiles_607286; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchNetworkProfiles
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607302 = newJObject()
  var body_607303 = newJObject()
  add(query_607302, "MaxResults", newJString(MaxResults))
  add(query_607302, "NextToken", newJString(NextToken))
  if body != nil:
    body_607303 = body
  result = call_607301.call(nil, query_607302, nil, nil, body_607303)

var searchNetworkProfiles* = Call_SearchNetworkProfiles_607286(
    name: "searchNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchNetworkProfiles",
    validator: validate_SearchNetworkProfiles_607287, base: "/",
    url: url_SearchNetworkProfiles_607288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProfiles_607304 = ref object of OpenApiRestCall_605589
proc url_SearchProfiles_607306(protocol: Scheme; host: string; base: string;
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

proc validate_SearchProfiles_607305(path: JsonNode; query: JsonNode;
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
  var valid_607307 = query.getOrDefault("MaxResults")
  valid_607307 = validateParameter(valid_607307, JString, required = false,
                                 default = nil)
  if valid_607307 != nil:
    section.add "MaxResults", valid_607307
  var valid_607308 = query.getOrDefault("NextToken")
  valid_607308 = validateParameter(valid_607308, JString, required = false,
                                 default = nil)
  if valid_607308 != nil:
    section.add "NextToken", valid_607308
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607309 = header.getOrDefault("X-Amz-Target")
  valid_607309 = validateParameter(valid_607309, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchProfiles"))
  if valid_607309 != nil:
    section.add "X-Amz-Target", valid_607309
  var valid_607310 = header.getOrDefault("X-Amz-Signature")
  valid_607310 = validateParameter(valid_607310, JString, required = false,
                                 default = nil)
  if valid_607310 != nil:
    section.add "X-Amz-Signature", valid_607310
  var valid_607311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607311 = validateParameter(valid_607311, JString, required = false,
                                 default = nil)
  if valid_607311 != nil:
    section.add "X-Amz-Content-Sha256", valid_607311
  var valid_607312 = header.getOrDefault("X-Amz-Date")
  valid_607312 = validateParameter(valid_607312, JString, required = false,
                                 default = nil)
  if valid_607312 != nil:
    section.add "X-Amz-Date", valid_607312
  var valid_607313 = header.getOrDefault("X-Amz-Credential")
  valid_607313 = validateParameter(valid_607313, JString, required = false,
                                 default = nil)
  if valid_607313 != nil:
    section.add "X-Amz-Credential", valid_607313
  var valid_607314 = header.getOrDefault("X-Amz-Security-Token")
  valid_607314 = validateParameter(valid_607314, JString, required = false,
                                 default = nil)
  if valid_607314 != nil:
    section.add "X-Amz-Security-Token", valid_607314
  var valid_607315 = header.getOrDefault("X-Amz-Algorithm")
  valid_607315 = validateParameter(valid_607315, JString, required = false,
                                 default = nil)
  if valid_607315 != nil:
    section.add "X-Amz-Algorithm", valid_607315
  var valid_607316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607316 = validateParameter(valid_607316, JString, required = false,
                                 default = nil)
  if valid_607316 != nil:
    section.add "X-Amz-SignedHeaders", valid_607316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607318: Call_SearchProfiles_607304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
  ## 
  let valid = call_607318.validator(path, query, header, formData, body)
  let scheme = call_607318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607318.url(scheme.get, call_607318.host, call_607318.base,
                         call_607318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607318, url, valid)

proc call*(call_607319: Call_SearchProfiles_607304; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchProfiles
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607320 = newJObject()
  var body_607321 = newJObject()
  add(query_607320, "MaxResults", newJString(MaxResults))
  add(query_607320, "NextToken", newJString(NextToken))
  if body != nil:
    body_607321 = body
  result = call_607319.call(nil, query_607320, nil, nil, body_607321)

var searchProfiles* = Call_SearchProfiles_607304(name: "searchProfiles",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchProfiles",
    validator: validate_SearchProfiles_607305, base: "/", url: url_SearchProfiles_607306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchRooms_607322 = ref object of OpenApiRestCall_605589
proc url_SearchRooms_607324(protocol: Scheme; host: string; base: string;
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

proc validate_SearchRooms_607323(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607325 = query.getOrDefault("MaxResults")
  valid_607325 = validateParameter(valid_607325, JString, required = false,
                                 default = nil)
  if valid_607325 != nil:
    section.add "MaxResults", valid_607325
  var valid_607326 = query.getOrDefault("NextToken")
  valid_607326 = validateParameter(valid_607326, JString, required = false,
                                 default = nil)
  if valid_607326 != nil:
    section.add "NextToken", valid_607326
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607327 = header.getOrDefault("X-Amz-Target")
  valid_607327 = validateParameter(valid_607327, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchRooms"))
  if valid_607327 != nil:
    section.add "X-Amz-Target", valid_607327
  var valid_607328 = header.getOrDefault("X-Amz-Signature")
  valid_607328 = validateParameter(valid_607328, JString, required = false,
                                 default = nil)
  if valid_607328 != nil:
    section.add "X-Amz-Signature", valid_607328
  var valid_607329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607329 = validateParameter(valid_607329, JString, required = false,
                                 default = nil)
  if valid_607329 != nil:
    section.add "X-Amz-Content-Sha256", valid_607329
  var valid_607330 = header.getOrDefault("X-Amz-Date")
  valid_607330 = validateParameter(valid_607330, JString, required = false,
                                 default = nil)
  if valid_607330 != nil:
    section.add "X-Amz-Date", valid_607330
  var valid_607331 = header.getOrDefault("X-Amz-Credential")
  valid_607331 = validateParameter(valid_607331, JString, required = false,
                                 default = nil)
  if valid_607331 != nil:
    section.add "X-Amz-Credential", valid_607331
  var valid_607332 = header.getOrDefault("X-Amz-Security-Token")
  valid_607332 = validateParameter(valid_607332, JString, required = false,
                                 default = nil)
  if valid_607332 != nil:
    section.add "X-Amz-Security-Token", valid_607332
  var valid_607333 = header.getOrDefault("X-Amz-Algorithm")
  valid_607333 = validateParameter(valid_607333, JString, required = false,
                                 default = nil)
  if valid_607333 != nil:
    section.add "X-Amz-Algorithm", valid_607333
  var valid_607334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607334 = validateParameter(valid_607334, JString, required = false,
                                 default = nil)
  if valid_607334 != nil:
    section.add "X-Amz-SignedHeaders", valid_607334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607336: Call_SearchRooms_607322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_607336.validator(path, query, header, formData, body)
  let scheme = call_607336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607336.url(scheme.get, call_607336.host, call_607336.base,
                         call_607336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607336, url, valid)

proc call*(call_607337: Call_SearchRooms_607322; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchRooms
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607338 = newJObject()
  var body_607339 = newJObject()
  add(query_607338, "MaxResults", newJString(MaxResults))
  add(query_607338, "NextToken", newJString(NextToken))
  if body != nil:
    body_607339 = body
  result = call_607337.call(nil, query_607338, nil, nil, body_607339)

var searchRooms* = Call_SearchRooms_607322(name: "searchRooms",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.SearchRooms",
                                        validator: validate_SearchRooms_607323,
                                        base: "/", url: url_SearchRooms_607324,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSkillGroups_607340 = ref object of OpenApiRestCall_605589
proc url_SearchSkillGroups_607342(protocol: Scheme; host: string; base: string;
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

proc validate_SearchSkillGroups_607341(path: JsonNode; query: JsonNode;
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
  var valid_607343 = query.getOrDefault("MaxResults")
  valid_607343 = validateParameter(valid_607343, JString, required = false,
                                 default = nil)
  if valid_607343 != nil:
    section.add "MaxResults", valid_607343
  var valid_607344 = query.getOrDefault("NextToken")
  valid_607344 = validateParameter(valid_607344, JString, required = false,
                                 default = nil)
  if valid_607344 != nil:
    section.add "NextToken", valid_607344
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607345 = header.getOrDefault("X-Amz-Target")
  valid_607345 = validateParameter(valid_607345, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchSkillGroups"))
  if valid_607345 != nil:
    section.add "X-Amz-Target", valid_607345
  var valid_607346 = header.getOrDefault("X-Amz-Signature")
  valid_607346 = validateParameter(valid_607346, JString, required = false,
                                 default = nil)
  if valid_607346 != nil:
    section.add "X-Amz-Signature", valid_607346
  var valid_607347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607347 = validateParameter(valid_607347, JString, required = false,
                                 default = nil)
  if valid_607347 != nil:
    section.add "X-Amz-Content-Sha256", valid_607347
  var valid_607348 = header.getOrDefault("X-Amz-Date")
  valid_607348 = validateParameter(valid_607348, JString, required = false,
                                 default = nil)
  if valid_607348 != nil:
    section.add "X-Amz-Date", valid_607348
  var valid_607349 = header.getOrDefault("X-Amz-Credential")
  valid_607349 = validateParameter(valid_607349, JString, required = false,
                                 default = nil)
  if valid_607349 != nil:
    section.add "X-Amz-Credential", valid_607349
  var valid_607350 = header.getOrDefault("X-Amz-Security-Token")
  valid_607350 = validateParameter(valid_607350, JString, required = false,
                                 default = nil)
  if valid_607350 != nil:
    section.add "X-Amz-Security-Token", valid_607350
  var valid_607351 = header.getOrDefault("X-Amz-Algorithm")
  valid_607351 = validateParameter(valid_607351, JString, required = false,
                                 default = nil)
  if valid_607351 != nil:
    section.add "X-Amz-Algorithm", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-SignedHeaders", valid_607352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607354: Call_SearchSkillGroups_607340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_607354.validator(path, query, header, formData, body)
  let scheme = call_607354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607354.url(scheme.get, call_607354.host, call_607354.base,
                         call_607354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607354, url, valid)

proc call*(call_607355: Call_SearchSkillGroups_607340; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchSkillGroups
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607356 = newJObject()
  var body_607357 = newJObject()
  add(query_607356, "MaxResults", newJString(MaxResults))
  add(query_607356, "NextToken", newJString(NextToken))
  if body != nil:
    body_607357 = body
  result = call_607355.call(nil, query_607356, nil, nil, body_607357)

var searchSkillGroups* = Call_SearchSkillGroups_607340(name: "searchSkillGroups",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchSkillGroups",
    validator: validate_SearchSkillGroups_607341, base: "/",
    url: url_SearchSkillGroups_607342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchUsers_607358 = ref object of OpenApiRestCall_605589
proc url_SearchUsers_607360(protocol: Scheme; host: string; base: string;
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

proc validate_SearchUsers_607359(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607361 = query.getOrDefault("MaxResults")
  valid_607361 = validateParameter(valid_607361, JString, required = false,
                                 default = nil)
  if valid_607361 != nil:
    section.add "MaxResults", valid_607361
  var valid_607362 = query.getOrDefault("NextToken")
  valid_607362 = validateParameter(valid_607362, JString, required = false,
                                 default = nil)
  if valid_607362 != nil:
    section.add "NextToken", valid_607362
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607363 = header.getOrDefault("X-Amz-Target")
  valid_607363 = validateParameter(valid_607363, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchUsers"))
  if valid_607363 != nil:
    section.add "X-Amz-Target", valid_607363
  var valid_607364 = header.getOrDefault("X-Amz-Signature")
  valid_607364 = validateParameter(valid_607364, JString, required = false,
                                 default = nil)
  if valid_607364 != nil:
    section.add "X-Amz-Signature", valid_607364
  var valid_607365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607365 = validateParameter(valid_607365, JString, required = false,
                                 default = nil)
  if valid_607365 != nil:
    section.add "X-Amz-Content-Sha256", valid_607365
  var valid_607366 = header.getOrDefault("X-Amz-Date")
  valid_607366 = validateParameter(valid_607366, JString, required = false,
                                 default = nil)
  if valid_607366 != nil:
    section.add "X-Amz-Date", valid_607366
  var valid_607367 = header.getOrDefault("X-Amz-Credential")
  valid_607367 = validateParameter(valid_607367, JString, required = false,
                                 default = nil)
  if valid_607367 != nil:
    section.add "X-Amz-Credential", valid_607367
  var valid_607368 = header.getOrDefault("X-Amz-Security-Token")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-Security-Token", valid_607368
  var valid_607369 = header.getOrDefault("X-Amz-Algorithm")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "X-Amz-Algorithm", valid_607369
  var valid_607370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "X-Amz-SignedHeaders", valid_607370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607372: Call_SearchUsers_607358; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_607372.validator(path, query, header, formData, body)
  let scheme = call_607372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607372.url(scheme.get, call_607372.host, call_607372.base,
                         call_607372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607372, url, valid)

proc call*(call_607373: Call_SearchUsers_607358; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchUsers
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607374 = newJObject()
  var body_607375 = newJObject()
  add(query_607374, "MaxResults", newJString(MaxResults))
  add(query_607374, "NextToken", newJString(NextToken))
  if body != nil:
    body_607375 = body
  result = call_607373.call(nil, query_607374, nil, nil, body_607375)

var searchUsers* = Call_SearchUsers_607358(name: "searchUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.SearchUsers",
                                        validator: validate_SearchUsers_607359,
                                        base: "/", url: url_SearchUsers_607360,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAnnouncement_607376 = ref object of OpenApiRestCall_605589
proc url_SendAnnouncement_607378(protocol: Scheme; host: string; base: string;
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

proc validate_SendAnnouncement_607377(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607379 = header.getOrDefault("X-Amz-Target")
  valid_607379 = validateParameter(valid_607379, JString, required = true, default = newJString(
      "AlexaForBusiness.SendAnnouncement"))
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

proc call*(call_607388: Call_SendAnnouncement_607376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Triggers an asynchronous flow to send text, SSML, or audio announcements to rooms that are identified by a search or filter. 
  ## 
  let valid = call_607388.validator(path, query, header, formData, body)
  let scheme = call_607388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607388.url(scheme.get, call_607388.host, call_607388.base,
                         call_607388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607388, url, valid)

proc call*(call_607389: Call_SendAnnouncement_607376; body: JsonNode): Recallable =
  ## sendAnnouncement
  ## Triggers an asynchronous flow to send text, SSML, or audio announcements to rooms that are identified by a search or filter. 
  ##   body: JObject (required)
  var body_607390 = newJObject()
  if body != nil:
    body_607390 = body
  result = call_607389.call(nil, nil, nil, nil, body_607390)

var sendAnnouncement* = Call_SendAnnouncement_607376(name: "sendAnnouncement",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SendAnnouncement",
    validator: validate_SendAnnouncement_607377, base: "/",
    url: url_SendAnnouncement_607378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendInvitation_607391 = ref object of OpenApiRestCall_605589
proc url_SendInvitation_607393(protocol: Scheme; host: string; base: string;
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

proc validate_SendInvitation_607392(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607394 = header.getOrDefault("X-Amz-Target")
  valid_607394 = validateParameter(valid_607394, JString, required = true, default = newJString(
      "AlexaForBusiness.SendInvitation"))
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

proc call*(call_607403: Call_SendInvitation_607391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends an enrollment invitation email with a URL to a user. The URL is valid for 30 days or until you call this operation again, whichever comes first. 
  ## 
  let valid = call_607403.validator(path, query, header, formData, body)
  let scheme = call_607403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607403.url(scheme.get, call_607403.host, call_607403.base,
                         call_607403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607403, url, valid)

proc call*(call_607404: Call_SendInvitation_607391; body: JsonNode): Recallable =
  ## sendInvitation
  ## Sends an enrollment invitation email with a URL to a user. The URL is valid for 30 days or until you call this operation again, whichever comes first. 
  ##   body: JObject (required)
  var body_607405 = newJObject()
  if body != nil:
    body_607405 = body
  result = call_607404.call(nil, nil, nil, nil, body_607405)

var sendInvitation* = Call_SendInvitation_607391(name: "sendInvitation",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SendInvitation",
    validator: validate_SendInvitation_607392, base: "/", url: url_SendInvitation_607393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeviceSync_607406 = ref object of OpenApiRestCall_605589
proc url_StartDeviceSync_607408(protocol: Scheme; host: string; base: string;
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

proc validate_StartDeviceSync_607407(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607409 = header.getOrDefault("X-Amz-Target")
  valid_607409 = validateParameter(valid_607409, JString, required = true, default = newJString(
      "AlexaForBusiness.StartDeviceSync"))
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

proc call*(call_607418: Call_StartDeviceSync_607406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets a device and its account to the known default settings. This clears all information and settings set by previous users in the following ways:</p> <ul> <li> <p>Bluetooth - This unpairs all bluetooth devices paired with your echo device.</p> </li> <li> <p>Volume - This resets the echo device's volume to the default value.</p> </li> <li> <p>Notifications - This clears all notifications from your echo device.</p> </li> <li> <p>Lists - This clears all to-do items from your echo device.</p> </li> <li> <p>Settings - This internally syncs the room's profile (if the device is assigned to a room), contacts, address books, delegation access for account linking, and communications (if enabled on the room profile).</p> </li> </ul>
  ## 
  let valid = call_607418.validator(path, query, header, formData, body)
  let scheme = call_607418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607418.url(scheme.get, call_607418.host, call_607418.base,
                         call_607418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607418, url, valid)

proc call*(call_607419: Call_StartDeviceSync_607406; body: JsonNode): Recallable =
  ## startDeviceSync
  ## <p>Resets a device and its account to the known default settings. This clears all information and settings set by previous users in the following ways:</p> <ul> <li> <p>Bluetooth - This unpairs all bluetooth devices paired with your echo device.</p> </li> <li> <p>Volume - This resets the echo device's volume to the default value.</p> </li> <li> <p>Notifications - This clears all notifications from your echo device.</p> </li> <li> <p>Lists - This clears all to-do items from your echo device.</p> </li> <li> <p>Settings - This internally syncs the room's profile (if the device is assigned to a room), contacts, address books, delegation access for account linking, and communications (if enabled on the room profile).</p> </li> </ul>
  ##   body: JObject (required)
  var body_607420 = newJObject()
  if body != nil:
    body_607420 = body
  result = call_607419.call(nil, nil, nil, nil, body_607420)

var startDeviceSync* = Call_StartDeviceSync_607406(name: "startDeviceSync",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.StartDeviceSync",
    validator: validate_StartDeviceSync_607407, base: "/", url: url_StartDeviceSync_607408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSmartHomeApplianceDiscovery_607421 = ref object of OpenApiRestCall_605589
proc url_StartSmartHomeApplianceDiscovery_607423(protocol: Scheme; host: string;
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

proc validate_StartSmartHomeApplianceDiscovery_607422(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607424 = header.getOrDefault("X-Amz-Target")
  valid_607424 = validateParameter(valid_607424, JString, required = true, default = newJString(
      "AlexaForBusiness.StartSmartHomeApplianceDiscovery"))
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

proc call*(call_607433: Call_StartSmartHomeApplianceDiscovery_607421;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Initiates the discovery of any smart home appliances associated with the room.
  ## 
  let valid = call_607433.validator(path, query, header, formData, body)
  let scheme = call_607433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607433.url(scheme.get, call_607433.host, call_607433.base,
                         call_607433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607433, url, valid)

proc call*(call_607434: Call_StartSmartHomeApplianceDiscovery_607421;
          body: JsonNode): Recallable =
  ## startSmartHomeApplianceDiscovery
  ## Initiates the discovery of any smart home appliances associated with the room.
  ##   body: JObject (required)
  var body_607435 = newJObject()
  if body != nil:
    body_607435 = body
  result = call_607434.call(nil, nil, nil, nil, body_607435)

var startSmartHomeApplianceDiscovery* = Call_StartSmartHomeApplianceDiscovery_607421(
    name: "startSmartHomeApplianceDiscovery", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.StartSmartHomeApplianceDiscovery",
    validator: validate_StartSmartHomeApplianceDiscovery_607422, base: "/",
    url: url_StartSmartHomeApplianceDiscovery_607423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_607436 = ref object of OpenApiRestCall_605589
proc url_TagResource_607438(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_607437(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607439 = header.getOrDefault("X-Amz-Target")
  valid_607439 = validateParameter(valid_607439, JString, required = true, default = newJString(
      "AlexaForBusiness.TagResource"))
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

proc call*(call_607448: Call_TagResource_607436; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to a specified resource.
  ## 
  let valid = call_607448.validator(path, query, header, formData, body)
  let scheme = call_607448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607448.url(scheme.get, call_607448.host, call_607448.base,
                         call_607448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607448, url, valid)

proc call*(call_607449: Call_TagResource_607436; body: JsonNode): Recallable =
  ## tagResource
  ## Adds metadata tags to a specified resource.
  ##   body: JObject (required)
  var body_607450 = newJObject()
  if body != nil:
    body_607450 = body
  result = call_607449.call(nil, nil, nil, nil, body_607450)

var tagResource* = Call_TagResource_607436(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.TagResource",
                                        validator: validate_TagResource_607437,
                                        base: "/", url: url_TagResource_607438,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_607451 = ref object of OpenApiRestCall_605589
proc url_UntagResource_607453(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_607452(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607454 = header.getOrDefault("X-Amz-Target")
  valid_607454 = validateParameter(valid_607454, JString, required = true, default = newJString(
      "AlexaForBusiness.UntagResource"))
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

proc call*(call_607463: Call_UntagResource_607451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from a specified resource.
  ## 
  let valid = call_607463.validator(path, query, header, formData, body)
  let scheme = call_607463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607463.url(scheme.get, call_607463.host, call_607463.base,
                         call_607463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607463, url, valid)

proc call*(call_607464: Call_UntagResource_607451; body: JsonNode): Recallable =
  ## untagResource
  ## Removes metadata tags from a specified resource.
  ##   body: JObject (required)
  var body_607465 = newJObject()
  if body != nil:
    body_607465 = body
  result = call_607464.call(nil, nil, nil, nil, body_607465)

var untagResource* = Call_UntagResource_607451(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UntagResource",
    validator: validate_UntagResource_607452, base: "/", url: url_UntagResource_607453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAddressBook_607466 = ref object of OpenApiRestCall_605589
proc url_UpdateAddressBook_607468(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAddressBook_607467(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607469 = header.getOrDefault("X-Amz-Target")
  valid_607469 = validateParameter(valid_607469, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateAddressBook"))
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

proc call*(call_607478: Call_UpdateAddressBook_607466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates address book details by the address book ARN.
  ## 
  let valid = call_607478.validator(path, query, header, formData, body)
  let scheme = call_607478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607478.url(scheme.get, call_607478.host, call_607478.base,
                         call_607478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607478, url, valid)

proc call*(call_607479: Call_UpdateAddressBook_607466; body: JsonNode): Recallable =
  ## updateAddressBook
  ## Updates address book details by the address book ARN.
  ##   body: JObject (required)
  var body_607480 = newJObject()
  if body != nil:
    body_607480 = body
  result = call_607479.call(nil, nil, nil, nil, body_607480)

var updateAddressBook* = Call_UpdateAddressBook_607466(name: "updateAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateAddressBook",
    validator: validate_UpdateAddressBook_607467, base: "/",
    url: url_UpdateAddressBook_607468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBusinessReportSchedule_607481 = ref object of OpenApiRestCall_605589
proc url_UpdateBusinessReportSchedule_607483(protocol: Scheme; host: string;
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

proc validate_UpdateBusinessReportSchedule_607482(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607484 = header.getOrDefault("X-Amz-Target")
  valid_607484 = validateParameter(valid_607484, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateBusinessReportSchedule"))
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

proc call*(call_607493: Call_UpdateBusinessReportSchedule_607481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration of the report delivery schedule with the specified schedule ARN.
  ## 
  let valid = call_607493.validator(path, query, header, formData, body)
  let scheme = call_607493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607493.url(scheme.get, call_607493.host, call_607493.base,
                         call_607493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607493, url, valid)

proc call*(call_607494: Call_UpdateBusinessReportSchedule_607481; body: JsonNode): Recallable =
  ## updateBusinessReportSchedule
  ## Updates the configuration of the report delivery schedule with the specified schedule ARN.
  ##   body: JObject (required)
  var body_607495 = newJObject()
  if body != nil:
    body_607495 = body
  result = call_607494.call(nil, nil, nil, nil, body_607495)

var updateBusinessReportSchedule* = Call_UpdateBusinessReportSchedule_607481(
    name: "updateBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateBusinessReportSchedule",
    validator: validate_UpdateBusinessReportSchedule_607482, base: "/",
    url: url_UpdateBusinessReportSchedule_607483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConferenceProvider_607496 = ref object of OpenApiRestCall_605589
proc url_UpdateConferenceProvider_607498(protocol: Scheme; host: string;
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

proc validate_UpdateConferenceProvider_607497(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607499 = header.getOrDefault("X-Amz-Target")
  valid_607499 = validateParameter(valid_607499, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateConferenceProvider"))
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

proc call*(call_607508: Call_UpdateConferenceProvider_607496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing conference provider's settings.
  ## 
  let valid = call_607508.validator(path, query, header, formData, body)
  let scheme = call_607508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607508.url(scheme.get, call_607508.host, call_607508.base,
                         call_607508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607508, url, valid)

proc call*(call_607509: Call_UpdateConferenceProvider_607496; body: JsonNode): Recallable =
  ## updateConferenceProvider
  ## Updates an existing conference provider's settings.
  ##   body: JObject (required)
  var body_607510 = newJObject()
  if body != nil:
    body_607510 = body
  result = call_607509.call(nil, nil, nil, nil, body_607510)

var updateConferenceProvider* = Call_UpdateConferenceProvider_607496(
    name: "updateConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateConferenceProvider",
    validator: validate_UpdateConferenceProvider_607497, base: "/",
    url: url_UpdateConferenceProvider_607498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContact_607511 = ref object of OpenApiRestCall_605589
proc url_UpdateContact_607513(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateContact_607512(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607514 = header.getOrDefault("X-Amz-Target")
  valid_607514 = validateParameter(valid_607514, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateContact"))
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

proc call*(call_607523: Call_UpdateContact_607511; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the contact details by the contact ARN.
  ## 
  let valid = call_607523.validator(path, query, header, formData, body)
  let scheme = call_607523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607523.url(scheme.get, call_607523.host, call_607523.base,
                         call_607523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607523, url, valid)

proc call*(call_607524: Call_UpdateContact_607511; body: JsonNode): Recallable =
  ## updateContact
  ## Updates the contact details by the contact ARN.
  ##   body: JObject (required)
  var body_607525 = newJObject()
  if body != nil:
    body_607525 = body
  result = call_607524.call(nil, nil, nil, nil, body_607525)

var updateContact* = Call_UpdateContact_607511(name: "updateContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateContact",
    validator: validate_UpdateContact_607512, base: "/", url: url_UpdateContact_607513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevice_607526 = ref object of OpenApiRestCall_605589
proc url_UpdateDevice_607528(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDevice_607527(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607529 = header.getOrDefault("X-Amz-Target")
  valid_607529 = validateParameter(valid_607529, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateDevice"))
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

proc call*(call_607538: Call_UpdateDevice_607526; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the device name by device ARN.
  ## 
  let valid = call_607538.validator(path, query, header, formData, body)
  let scheme = call_607538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607538.url(scheme.get, call_607538.host, call_607538.base,
                         call_607538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607538, url, valid)

proc call*(call_607539: Call_UpdateDevice_607526; body: JsonNode): Recallable =
  ## updateDevice
  ## Updates the device name by device ARN.
  ##   body: JObject (required)
  var body_607540 = newJObject()
  if body != nil:
    body_607540 = body
  result = call_607539.call(nil, nil, nil, nil, body_607540)

var updateDevice* = Call_UpdateDevice_607526(name: "updateDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateDevice",
    validator: validate_UpdateDevice_607527, base: "/", url: url_UpdateDevice_607528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGateway_607541 = ref object of OpenApiRestCall_605589
proc url_UpdateGateway_607543(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGateway_607542(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607544 = header.getOrDefault("X-Amz-Target")
  valid_607544 = validateParameter(valid_607544, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateGateway"))
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

proc call*(call_607553: Call_UpdateGateway_607541; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details of a gateway. If any optional field is not provided, the existing corresponding value is left unmodified.
  ## 
  let valid = call_607553.validator(path, query, header, formData, body)
  let scheme = call_607553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607553.url(scheme.get, call_607553.host, call_607553.base,
                         call_607553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607553, url, valid)

proc call*(call_607554: Call_UpdateGateway_607541; body: JsonNode): Recallable =
  ## updateGateway
  ## Updates the details of a gateway. If any optional field is not provided, the existing corresponding value is left unmodified.
  ##   body: JObject (required)
  var body_607555 = newJObject()
  if body != nil:
    body_607555 = body
  result = call_607554.call(nil, nil, nil, nil, body_607555)

var updateGateway* = Call_UpdateGateway_607541(name: "updateGateway",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateGateway",
    validator: validate_UpdateGateway_607542, base: "/", url: url_UpdateGateway_607543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayGroup_607556 = ref object of OpenApiRestCall_605589
proc url_UpdateGatewayGroup_607558(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGatewayGroup_607557(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607559 = header.getOrDefault("X-Amz-Target")
  valid_607559 = validateParameter(valid_607559, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateGatewayGroup"))
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

proc call*(call_607568: Call_UpdateGatewayGroup_607556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details of a gateway group. If any optional field is not provided, the existing corresponding value is left unmodified.
  ## 
  let valid = call_607568.validator(path, query, header, formData, body)
  let scheme = call_607568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607568.url(scheme.get, call_607568.host, call_607568.base,
                         call_607568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607568, url, valid)

proc call*(call_607569: Call_UpdateGatewayGroup_607556; body: JsonNode): Recallable =
  ## updateGatewayGroup
  ## Updates the details of a gateway group. If any optional field is not provided, the existing corresponding value is left unmodified.
  ##   body: JObject (required)
  var body_607570 = newJObject()
  if body != nil:
    body_607570 = body
  result = call_607569.call(nil, nil, nil, nil, body_607570)

var updateGatewayGroup* = Call_UpdateGatewayGroup_607556(
    name: "updateGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateGatewayGroup",
    validator: validate_UpdateGatewayGroup_607557, base: "/",
    url: url_UpdateGatewayGroup_607558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_607571 = ref object of OpenApiRestCall_605589
proc url_UpdateNetworkProfile_607573(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateNetworkProfile_607572(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607574 = header.getOrDefault("X-Amz-Target")
  valid_607574 = validateParameter(valid_607574, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateNetworkProfile"))
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

proc call*(call_607583: Call_UpdateNetworkProfile_607571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a network profile by the network profile ARN.
  ## 
  let valid = call_607583.validator(path, query, header, formData, body)
  let scheme = call_607583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607583.url(scheme.get, call_607583.host, call_607583.base,
                         call_607583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607583, url, valid)

proc call*(call_607584: Call_UpdateNetworkProfile_607571; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates a network profile by the network profile ARN.
  ##   body: JObject (required)
  var body_607585 = newJObject()
  if body != nil:
    body_607585 = body
  result = call_607584.call(nil, nil, nil, nil, body_607585)

var updateNetworkProfile* = Call_UpdateNetworkProfile_607571(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_607572, base: "/",
    url: url_UpdateNetworkProfile_607573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProfile_607586 = ref object of OpenApiRestCall_605589
proc url_UpdateProfile_607588(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateProfile_607587(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607589 = header.getOrDefault("X-Amz-Target")
  valid_607589 = validateParameter(valid_607589, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateProfile"))
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

proc call*(call_607598: Call_UpdateProfile_607586; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing room profile by room profile ARN.
  ## 
  let valid = call_607598.validator(path, query, header, formData, body)
  let scheme = call_607598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607598.url(scheme.get, call_607598.host, call_607598.base,
                         call_607598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607598, url, valid)

proc call*(call_607599: Call_UpdateProfile_607586; body: JsonNode): Recallable =
  ## updateProfile
  ## Updates an existing room profile by room profile ARN.
  ##   body: JObject (required)
  var body_607600 = newJObject()
  if body != nil:
    body_607600 = body
  result = call_607599.call(nil, nil, nil, nil, body_607600)

var updateProfile* = Call_UpdateProfile_607586(name: "updateProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateProfile",
    validator: validate_UpdateProfile_607587, base: "/", url: url_UpdateProfile_607588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoom_607601 = ref object of OpenApiRestCall_605589
proc url_UpdateRoom_607603(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateRoom_607602(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607604 = header.getOrDefault("X-Amz-Target")
  valid_607604 = validateParameter(valid_607604, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateRoom"))
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

proc call*(call_607613: Call_UpdateRoom_607601; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room details by room ARN.
  ## 
  let valid = call_607613.validator(path, query, header, formData, body)
  let scheme = call_607613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607613.url(scheme.get, call_607613.host, call_607613.base,
                         call_607613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607613, url, valid)

proc call*(call_607614: Call_UpdateRoom_607601; body: JsonNode): Recallable =
  ## updateRoom
  ## Updates room details by room ARN.
  ##   body: JObject (required)
  var body_607615 = newJObject()
  if body != nil:
    body_607615 = body
  result = call_607614.call(nil, nil, nil, nil, body_607615)

var updateRoom* = Call_UpdateRoom_607601(name: "updateRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.UpdateRoom",
                                      validator: validate_UpdateRoom_607602,
                                      base: "/", url: url_UpdateRoom_607603,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSkillGroup_607616 = ref object of OpenApiRestCall_605589
proc url_UpdateSkillGroup_607618(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSkillGroup_607617(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_607619 = header.getOrDefault("X-Amz-Target")
  valid_607619 = validateParameter(valid_607619, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateSkillGroup"))
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

proc call*(call_607628: Call_UpdateSkillGroup_607616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates skill group details by skill group ARN.
  ## 
  let valid = call_607628.validator(path, query, header, formData, body)
  let scheme = call_607628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607628.url(scheme.get, call_607628.host, call_607628.base,
                         call_607628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607628, url, valid)

proc call*(call_607629: Call_UpdateSkillGroup_607616; body: JsonNode): Recallable =
  ## updateSkillGroup
  ## Updates skill group details by skill group ARN.
  ##   body: JObject (required)
  var body_607630 = newJObject()
  if body != nil:
    body_607630 = body
  result = call_607629.call(nil, nil, nil, nil, body_607630)

var updateSkillGroup* = Call_UpdateSkillGroup_607616(name: "updateSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateSkillGroup",
    validator: validate_UpdateSkillGroup_607617, base: "/",
    url: url_UpdateSkillGroup_607618, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
