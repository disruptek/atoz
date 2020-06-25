
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
    if required:
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_ApproveSkill_21625779 = ref object of OpenApiRestCall_21625435
proc url_ApproveSkill_21625781(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ApproveSkill_21625780(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625898 = header.getOrDefault("X-Amz-Target")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true, default = newJString(
      "AlexaForBusiness.ApproveSkill"))
  if valid_21625898 != nil:
    section.add "X-Amz-Target", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625929: Call_ApproveSkill_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a skill with the organization under the customer's AWS account. If a skill is private, the user implicitly accepts access to this skill during enablement.
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_ApproveSkill_21625779; body: JsonNode): Recallable =
  ## approveSkill
  ## Associates a skill with the organization under the customer's AWS account. If a skill is private, the user implicitly accepts access to this skill during enablement.
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var approveSkill* = Call_ApproveSkill_21625779(name: "approveSkill",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ApproveSkill",
    validator: validate_ApproveSkill_21625780, base: "/", makeUrl: url_ApproveSkill_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateContactWithAddressBook_21626029 = ref object of OpenApiRestCall_21625435
proc url_AssociateContactWithAddressBook_21626031(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateContactWithAddressBook_21626030(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Target")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateContactWithAddressBook"))
  if valid_21626034 != nil:
    section.add "X-Amz-Target", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626041: Call_AssociateContactWithAddressBook_21626029;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a contact with a given address book.
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_AssociateContactWithAddressBook_21626029;
          body: JsonNode): Recallable =
  ## associateContactWithAddressBook
  ## Associates a contact with a given address book.
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var associateContactWithAddressBook* = Call_AssociateContactWithAddressBook_21626029(
    name: "associateContactWithAddressBook", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateContactWithAddressBook",
    validator: validate_AssociateContactWithAddressBook_21626030, base: "/",
    makeUrl: url_AssociateContactWithAddressBook_21626031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateDeviceWithNetworkProfile_21626044 = ref object of OpenApiRestCall_21625435
proc url_AssociateDeviceWithNetworkProfile_21626046(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateDeviceWithNetworkProfile_21626045(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Target")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateDeviceWithNetworkProfile"))
  if valid_21626049 != nil:
    section.add "X-Amz-Target", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626056: Call_AssociateDeviceWithNetworkProfile_21626044;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a device with the specified network profile.
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_AssociateDeviceWithNetworkProfile_21626044;
          body: JsonNode): Recallable =
  ## associateDeviceWithNetworkProfile
  ## Associates a device with the specified network profile.
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var associateDeviceWithNetworkProfile* = Call_AssociateDeviceWithNetworkProfile_21626044(
    name: "associateDeviceWithNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateDeviceWithNetworkProfile",
    validator: validate_AssociateDeviceWithNetworkProfile_21626045, base: "/",
    makeUrl: url_AssociateDeviceWithNetworkProfile_21626046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateDeviceWithRoom_21626059 = ref object of OpenApiRestCall_21625435
proc url_AssociateDeviceWithRoom_21626061(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateDeviceWithRoom_21626060(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626062 = header.getOrDefault("X-Amz-Date")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Date", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Security-Token", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Target")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateDeviceWithRoom"))
  if valid_21626064 != nil:
    section.add "X-Amz-Target", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626071: Call_AssociateDeviceWithRoom_21626059;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a device with a given room. This applies all the settings from the room profile to the device, and all the skills in any skill groups added to that room. This operation requires the device to be online, or else a manual sync is required. 
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_AssociateDeviceWithRoom_21626059; body: JsonNode): Recallable =
  ## associateDeviceWithRoom
  ## Associates a device with a given room. This applies all the settings from the room profile to the device, and all the skills in any skill groups added to that room. This operation requires the device to be online, or else a manual sync is required. 
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var associateDeviceWithRoom* = Call_AssociateDeviceWithRoom_21626059(
    name: "associateDeviceWithRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateDeviceWithRoom",
    validator: validate_AssociateDeviceWithRoom_21626060, base: "/",
    makeUrl: url_AssociateDeviceWithRoom_21626061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillGroupWithRoom_21626074 = ref object of OpenApiRestCall_21625435
proc url_AssociateSkillGroupWithRoom_21626076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateSkillGroupWithRoom_21626075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626077 = header.getOrDefault("X-Amz-Date")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Date", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Security-Token", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Target")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillGroupWithRoom"))
  if valid_21626079 != nil:
    section.add "X-Amz-Target", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626086: Call_AssociateSkillGroupWithRoom_21626074;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a skill group with a given room. This enables all skills in the associated skill group on all devices in the room.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_AssociateSkillGroupWithRoom_21626074; body: JsonNode): Recallable =
  ## associateSkillGroupWithRoom
  ## Associates a skill group with a given room. This enables all skills in the associated skill group on all devices in the room.
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var associateSkillGroupWithRoom* = Call_AssociateSkillGroupWithRoom_21626074(
    name: "associateSkillGroupWithRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillGroupWithRoom",
    validator: validate_AssociateSkillGroupWithRoom_21626075, base: "/",
    makeUrl: url_AssociateSkillGroupWithRoom_21626076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillWithSkillGroup_21626089 = ref object of OpenApiRestCall_21625435
proc url_AssociateSkillWithSkillGroup_21626091(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateSkillWithSkillGroup_21626090(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Target")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillWithSkillGroup"))
  if valid_21626094 != nil:
    section.add "X-Amz-Target", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Credential")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Credential", valid_21626099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626101: Call_AssociateSkillWithSkillGroup_21626089;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a skill with a skill group.
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_AssociateSkillWithSkillGroup_21626089;
          body: JsonNode): Recallable =
  ## associateSkillWithSkillGroup
  ## Associates a skill with a skill group.
  ##   body: JObject (required)
  var body_21626103 = newJObject()
  if body != nil:
    body_21626103 = body
  result = call_21626102.call(nil, nil, nil, nil, body_21626103)

var associateSkillWithSkillGroup* = Call_AssociateSkillWithSkillGroup_21626089(
    name: "associateSkillWithSkillGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillWithSkillGroup",
    validator: validate_AssociateSkillWithSkillGroup_21626090, base: "/",
    makeUrl: url_AssociateSkillWithSkillGroup_21626091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillWithUsers_21626104 = ref object of OpenApiRestCall_21625435
proc url_AssociateSkillWithUsers_21626106(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateSkillWithUsers_21626105(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626107 = header.getOrDefault("X-Amz-Date")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Date", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Security-Token", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Target")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillWithUsers"))
  if valid_21626109 != nil:
    section.add "X-Amz-Target", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626116: Call_AssociateSkillWithUsers_21626104;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Makes a private skill available for enrolled users to enable on their devices.
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_AssociateSkillWithUsers_21626104; body: JsonNode): Recallable =
  ## associateSkillWithUsers
  ## Makes a private skill available for enrolled users to enable on their devices.
  ##   body: JObject (required)
  var body_21626118 = newJObject()
  if body != nil:
    body_21626118 = body
  result = call_21626117.call(nil, nil, nil, nil, body_21626118)

var associateSkillWithUsers* = Call_AssociateSkillWithUsers_21626104(
    name: "associateSkillWithUsers", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillWithUsers",
    validator: validate_AssociateSkillWithUsers_21626105, base: "/",
    makeUrl: url_AssociateSkillWithUsers_21626106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAddressBook_21626119 = ref object of OpenApiRestCall_21625435
proc url_CreateAddressBook_21626121(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAddressBook_21626120(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626122 = header.getOrDefault("X-Amz-Date")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Date", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Security-Token", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Target")
  valid_21626124 = validateParameter(valid_21626124, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateAddressBook"))
  if valid_21626124 != nil:
    section.add "X-Amz-Target", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626131: Call_CreateAddressBook_21626119; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an address book with the specified details.
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_CreateAddressBook_21626119; body: JsonNode): Recallable =
  ## createAddressBook
  ## Creates an address book with the specified details.
  ##   body: JObject (required)
  var body_21626133 = newJObject()
  if body != nil:
    body_21626133 = body
  result = call_21626132.call(nil, nil, nil, nil, body_21626133)

var createAddressBook* = Call_CreateAddressBook_21626119(name: "createAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateAddressBook",
    validator: validate_CreateAddressBook_21626120, base: "/",
    makeUrl: url_CreateAddressBook_21626121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBusinessReportSchedule_21626134 = ref object of OpenApiRestCall_21625435
proc url_CreateBusinessReportSchedule_21626136(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBusinessReportSchedule_21626135(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626137 = header.getOrDefault("X-Amz-Date")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Date", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Security-Token", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Target")
  valid_21626139 = validateParameter(valid_21626139, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateBusinessReportSchedule"))
  if valid_21626139 != nil:
    section.add "X-Amz-Target", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Algorithm", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Signature")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Signature", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Credential")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Credential", valid_21626144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626146: Call_CreateBusinessReportSchedule_21626134;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a recurring schedule for usage reports to deliver to the specified S3 location with a specified daily or weekly interval.
  ## 
  let valid = call_21626146.validator(path, query, header, formData, body, _)
  let scheme = call_21626146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626146.makeUrl(scheme.get, call_21626146.host, call_21626146.base,
                               call_21626146.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626146, uri, valid, _)

proc call*(call_21626147: Call_CreateBusinessReportSchedule_21626134;
          body: JsonNode): Recallable =
  ## createBusinessReportSchedule
  ## Creates a recurring schedule for usage reports to deliver to the specified S3 location with a specified daily or weekly interval.
  ##   body: JObject (required)
  var body_21626148 = newJObject()
  if body != nil:
    body_21626148 = body
  result = call_21626147.call(nil, nil, nil, nil, body_21626148)

var createBusinessReportSchedule* = Call_CreateBusinessReportSchedule_21626134(
    name: "createBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateBusinessReportSchedule",
    validator: validate_CreateBusinessReportSchedule_21626135, base: "/",
    makeUrl: url_CreateBusinessReportSchedule_21626136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConferenceProvider_21626149 = ref object of OpenApiRestCall_21625435
proc url_CreateConferenceProvider_21626151(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConferenceProvider_21626150(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626152 = header.getOrDefault("X-Amz-Date")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Date", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Security-Token", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Target")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateConferenceProvider"))
  if valid_21626154 != nil:
    section.add "X-Amz-Target", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Algorithm", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Signature")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Signature", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Credential")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Credential", valid_21626159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626161: Call_CreateConferenceProvider_21626149;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a new conference provider under the user's AWS account.
  ## 
  let valid = call_21626161.validator(path, query, header, formData, body, _)
  let scheme = call_21626161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626161.makeUrl(scheme.get, call_21626161.host, call_21626161.base,
                               call_21626161.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626161, uri, valid, _)

proc call*(call_21626162: Call_CreateConferenceProvider_21626149; body: JsonNode): Recallable =
  ## createConferenceProvider
  ## Adds a new conference provider under the user's AWS account.
  ##   body: JObject (required)
  var body_21626163 = newJObject()
  if body != nil:
    body_21626163 = body
  result = call_21626162.call(nil, nil, nil, nil, body_21626163)

var createConferenceProvider* = Call_CreateConferenceProvider_21626149(
    name: "createConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateConferenceProvider",
    validator: validate_CreateConferenceProvider_21626150, base: "/",
    makeUrl: url_CreateConferenceProvider_21626151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateContact_21626164 = ref object of OpenApiRestCall_21625435
proc url_CreateContact_21626166(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateContact_21626165(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626167 = header.getOrDefault("X-Amz-Date")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Date", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Security-Token", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Target")
  valid_21626169 = validateParameter(valid_21626169, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateContact"))
  if valid_21626169 != nil:
    section.add "X-Amz-Target", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Algorithm", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Signature")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Signature", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Credential")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Credential", valid_21626174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626176: Call_CreateContact_21626164; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a contact with the specified details.
  ## 
  let valid = call_21626176.validator(path, query, header, formData, body, _)
  let scheme = call_21626176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626176.makeUrl(scheme.get, call_21626176.host, call_21626176.base,
                               call_21626176.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626176, uri, valid, _)

proc call*(call_21626177: Call_CreateContact_21626164; body: JsonNode): Recallable =
  ## createContact
  ## Creates a contact with the specified details.
  ##   body: JObject (required)
  var body_21626178 = newJObject()
  if body != nil:
    body_21626178 = body
  result = call_21626177.call(nil, nil, nil, nil, body_21626178)

var createContact* = Call_CreateContact_21626164(name: "createContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateContact",
    validator: validate_CreateContact_21626165, base: "/",
    makeUrl: url_CreateContact_21626166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGatewayGroup_21626179 = ref object of OpenApiRestCall_21625435
proc url_CreateGatewayGroup_21626181(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGatewayGroup_21626180(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626182 = header.getOrDefault("X-Amz-Date")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Date", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Security-Token", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Target")
  valid_21626184 = validateParameter(valid_21626184, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateGatewayGroup"))
  if valid_21626184 != nil:
    section.add "X-Amz-Target", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Algorithm", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Signature")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Signature", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Credential")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Credential", valid_21626189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626191: Call_CreateGatewayGroup_21626179; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a gateway group with the specified details.
  ## 
  let valid = call_21626191.validator(path, query, header, formData, body, _)
  let scheme = call_21626191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626191.makeUrl(scheme.get, call_21626191.host, call_21626191.base,
                               call_21626191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626191, uri, valid, _)

proc call*(call_21626192: Call_CreateGatewayGroup_21626179; body: JsonNode): Recallable =
  ## createGatewayGroup
  ## Creates a gateway group with the specified details.
  ##   body: JObject (required)
  var body_21626193 = newJObject()
  if body != nil:
    body_21626193 = body
  result = call_21626192.call(nil, nil, nil, nil, body_21626193)

var createGatewayGroup* = Call_CreateGatewayGroup_21626179(
    name: "createGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateGatewayGroup",
    validator: validate_CreateGatewayGroup_21626180, base: "/",
    makeUrl: url_CreateGatewayGroup_21626181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_21626194 = ref object of OpenApiRestCall_21625435
proc url_CreateNetworkProfile_21626196(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNetworkProfile_21626195(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Target")
  valid_21626199 = validateParameter(valid_21626199, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateNetworkProfile"))
  if valid_21626199 != nil:
    section.add "X-Amz-Target", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626206: Call_CreateNetworkProfile_21626194; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a network profile with the specified details.
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_CreateNetworkProfile_21626194; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile with the specified details.
  ##   body: JObject (required)
  var body_21626208 = newJObject()
  if body != nil:
    body_21626208 = body
  result = call_21626207.call(nil, nil, nil, nil, body_21626208)

var createNetworkProfile* = Call_CreateNetworkProfile_21626194(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_21626195, base: "/",
    makeUrl: url_CreateNetworkProfile_21626196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProfile_21626209 = ref object of OpenApiRestCall_21625435
proc url_CreateProfile_21626211(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProfile_21626210(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Target")
  valid_21626214 = validateParameter(valid_21626214, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateProfile"))
  if valid_21626214 != nil:
    section.add "X-Amz-Target", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626221: Call_CreateProfile_21626209; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new room profile with the specified details.
  ## 
  let valid = call_21626221.validator(path, query, header, formData, body, _)
  let scheme = call_21626221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626221.makeUrl(scheme.get, call_21626221.host, call_21626221.base,
                               call_21626221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626221, uri, valid, _)

proc call*(call_21626222: Call_CreateProfile_21626209; body: JsonNode): Recallable =
  ## createProfile
  ## Creates a new room profile with the specified details.
  ##   body: JObject (required)
  var body_21626223 = newJObject()
  if body != nil:
    body_21626223 = body
  result = call_21626222.call(nil, nil, nil, nil, body_21626223)

var createProfile* = Call_CreateProfile_21626209(name: "createProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateProfile",
    validator: validate_CreateProfile_21626210, base: "/",
    makeUrl: url_CreateProfile_21626211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoom_21626224 = ref object of OpenApiRestCall_21625435
proc url_CreateRoom_21626226(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRoom_21626225(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626227 = header.getOrDefault("X-Amz-Date")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Date", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Security-Token", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Target")
  valid_21626229 = validateParameter(valid_21626229, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateRoom"))
  if valid_21626229 != nil:
    section.add "X-Amz-Target", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626236: Call_CreateRoom_21626224; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a room with the specified details.
  ## 
  let valid = call_21626236.validator(path, query, header, formData, body, _)
  let scheme = call_21626236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626236.makeUrl(scheme.get, call_21626236.host, call_21626236.base,
                               call_21626236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626236, uri, valid, _)

proc call*(call_21626237: Call_CreateRoom_21626224; body: JsonNode): Recallable =
  ## createRoom
  ## Creates a room with the specified details.
  ##   body: JObject (required)
  var body_21626238 = newJObject()
  if body != nil:
    body_21626238 = body
  result = call_21626237.call(nil, nil, nil, nil, body_21626238)

var createRoom* = Call_CreateRoom_21626224(name: "createRoom",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.CreateRoom",
                                        validator: validate_CreateRoom_21626225,
                                        base: "/", makeUrl: url_CreateRoom_21626226,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSkillGroup_21626239 = ref object of OpenApiRestCall_21625435
proc url_CreateSkillGroup_21626241(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSkillGroup_21626240(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626242 = header.getOrDefault("X-Amz-Date")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Date", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Security-Token", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Target")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateSkillGroup"))
  if valid_21626244 != nil:
    section.add "X-Amz-Target", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Algorithm", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Signature")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Signature", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Credential")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Credential", valid_21626249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626251: Call_CreateSkillGroup_21626239; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a skill group with a specified name and description.
  ## 
  let valid = call_21626251.validator(path, query, header, formData, body, _)
  let scheme = call_21626251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626251.makeUrl(scheme.get, call_21626251.host, call_21626251.base,
                               call_21626251.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626251, uri, valid, _)

proc call*(call_21626252: Call_CreateSkillGroup_21626239; body: JsonNode): Recallable =
  ## createSkillGroup
  ## Creates a skill group with a specified name and description.
  ##   body: JObject (required)
  var body_21626253 = newJObject()
  if body != nil:
    body_21626253 = body
  result = call_21626252.call(nil, nil, nil, nil, body_21626253)

var createSkillGroup* = Call_CreateSkillGroup_21626239(name: "createSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateSkillGroup",
    validator: validate_CreateSkillGroup_21626240, base: "/",
    makeUrl: url_CreateSkillGroup_21626241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_21626254 = ref object of OpenApiRestCall_21625435
proc url_CreateUser_21626256(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUser_21626255(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626257 = header.getOrDefault("X-Amz-Date")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Date", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Security-Token", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Target")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateUser"))
  if valid_21626259 != nil:
    section.add "X-Amz-Target", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Algorithm", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Signature")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Signature", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Credential")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Credential", valid_21626264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626266: Call_CreateUser_21626254; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a user.
  ## 
  let valid = call_21626266.validator(path, query, header, formData, body, _)
  let scheme = call_21626266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626266.makeUrl(scheme.get, call_21626266.host, call_21626266.base,
                               call_21626266.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626266, uri, valid, _)

proc call*(call_21626267: Call_CreateUser_21626254; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user.
  ##   body: JObject (required)
  var body_21626268 = newJObject()
  if body != nil:
    body_21626268 = body
  result = call_21626267.call(nil, nil, nil, nil, body_21626268)

var createUser* = Call_CreateUser_21626254(name: "createUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.CreateUser",
                                        validator: validate_CreateUser_21626255,
                                        base: "/", makeUrl: url_CreateUser_21626256,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAddressBook_21626269 = ref object of OpenApiRestCall_21625435
proc url_DeleteAddressBook_21626271(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAddressBook_21626270(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626272 = header.getOrDefault("X-Amz-Date")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Date", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Security-Token", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Target")
  valid_21626274 = validateParameter(valid_21626274, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteAddressBook"))
  if valid_21626274 != nil:
    section.add "X-Amz-Target", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Algorithm", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Signature")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Signature", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Credential")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Credential", valid_21626279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626281: Call_DeleteAddressBook_21626269; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an address book by the address book ARN.
  ## 
  let valid = call_21626281.validator(path, query, header, formData, body, _)
  let scheme = call_21626281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626281.makeUrl(scheme.get, call_21626281.host, call_21626281.base,
                               call_21626281.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626281, uri, valid, _)

proc call*(call_21626282: Call_DeleteAddressBook_21626269; body: JsonNode): Recallable =
  ## deleteAddressBook
  ## Deletes an address book by the address book ARN.
  ##   body: JObject (required)
  var body_21626283 = newJObject()
  if body != nil:
    body_21626283 = body
  result = call_21626282.call(nil, nil, nil, nil, body_21626283)

var deleteAddressBook* = Call_DeleteAddressBook_21626269(name: "deleteAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteAddressBook",
    validator: validate_DeleteAddressBook_21626270, base: "/",
    makeUrl: url_DeleteAddressBook_21626271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBusinessReportSchedule_21626284 = ref object of OpenApiRestCall_21625435
proc url_DeleteBusinessReportSchedule_21626286(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBusinessReportSchedule_21626285(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626287 = header.getOrDefault("X-Amz-Date")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Date", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Security-Token", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Target")
  valid_21626289 = validateParameter(valid_21626289, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteBusinessReportSchedule"))
  if valid_21626289 != nil:
    section.add "X-Amz-Target", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Algorithm", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Signature")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Signature", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Credential")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Credential", valid_21626294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626296: Call_DeleteBusinessReportSchedule_21626284;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the recurring report delivery schedule with the specified schedule ARN.
  ## 
  let valid = call_21626296.validator(path, query, header, formData, body, _)
  let scheme = call_21626296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626296.makeUrl(scheme.get, call_21626296.host, call_21626296.base,
                               call_21626296.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626296, uri, valid, _)

proc call*(call_21626297: Call_DeleteBusinessReportSchedule_21626284;
          body: JsonNode): Recallable =
  ## deleteBusinessReportSchedule
  ## Deletes the recurring report delivery schedule with the specified schedule ARN.
  ##   body: JObject (required)
  var body_21626298 = newJObject()
  if body != nil:
    body_21626298 = body
  result = call_21626297.call(nil, nil, nil, nil, body_21626298)

var deleteBusinessReportSchedule* = Call_DeleteBusinessReportSchedule_21626284(
    name: "deleteBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteBusinessReportSchedule",
    validator: validate_DeleteBusinessReportSchedule_21626285, base: "/",
    makeUrl: url_DeleteBusinessReportSchedule_21626286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConferenceProvider_21626299 = ref object of OpenApiRestCall_21625435
proc url_DeleteConferenceProvider_21626301(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConferenceProvider_21626300(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626302 = header.getOrDefault("X-Amz-Date")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Date", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Security-Token", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Target")
  valid_21626304 = validateParameter(valid_21626304, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteConferenceProvider"))
  if valid_21626304 != nil:
    section.add "X-Amz-Target", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Algorithm", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Signature")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Signature", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Credential")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Credential", valid_21626309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626311: Call_DeleteConferenceProvider_21626299;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a conference provider.
  ## 
  let valid = call_21626311.validator(path, query, header, formData, body, _)
  let scheme = call_21626311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626311.makeUrl(scheme.get, call_21626311.host, call_21626311.base,
                               call_21626311.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626311, uri, valid, _)

proc call*(call_21626312: Call_DeleteConferenceProvider_21626299; body: JsonNode): Recallable =
  ## deleteConferenceProvider
  ## Deletes a conference provider.
  ##   body: JObject (required)
  var body_21626313 = newJObject()
  if body != nil:
    body_21626313 = body
  result = call_21626312.call(nil, nil, nil, nil, body_21626313)

var deleteConferenceProvider* = Call_DeleteConferenceProvider_21626299(
    name: "deleteConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteConferenceProvider",
    validator: validate_DeleteConferenceProvider_21626300, base: "/",
    makeUrl: url_DeleteConferenceProvider_21626301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteContact_21626314 = ref object of OpenApiRestCall_21625435
proc url_DeleteContact_21626316(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteContact_21626315(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626317 = header.getOrDefault("X-Amz-Date")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Date", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Security-Token", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Target")
  valid_21626319 = validateParameter(valid_21626319, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteContact"))
  if valid_21626319 != nil:
    section.add "X-Amz-Target", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Algorithm", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Signature")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Signature", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Credential")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Credential", valid_21626324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626326: Call_DeleteContact_21626314; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a contact by the contact ARN.
  ## 
  let valid = call_21626326.validator(path, query, header, formData, body, _)
  let scheme = call_21626326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626326.makeUrl(scheme.get, call_21626326.host, call_21626326.base,
                               call_21626326.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626326, uri, valid, _)

proc call*(call_21626327: Call_DeleteContact_21626314; body: JsonNode): Recallable =
  ## deleteContact
  ## Deletes a contact by the contact ARN.
  ##   body: JObject (required)
  var body_21626328 = newJObject()
  if body != nil:
    body_21626328 = body
  result = call_21626327.call(nil, nil, nil, nil, body_21626328)

var deleteContact* = Call_DeleteContact_21626314(name: "deleteContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteContact",
    validator: validate_DeleteContact_21626315, base: "/",
    makeUrl: url_DeleteContact_21626316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevice_21626329 = ref object of OpenApiRestCall_21625435
proc url_DeleteDevice_21626331(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDevice_21626330(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626332 = header.getOrDefault("X-Amz-Date")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Date", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Security-Token", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Target")
  valid_21626334 = validateParameter(valid_21626334, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteDevice"))
  if valid_21626334 != nil:
    section.add "X-Amz-Target", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Algorithm", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Signature")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Signature", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Credential")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Credential", valid_21626339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626341: Call_DeleteDevice_21626329; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a device from Alexa For Business.
  ## 
  let valid = call_21626341.validator(path, query, header, formData, body, _)
  let scheme = call_21626341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626341.makeUrl(scheme.get, call_21626341.host, call_21626341.base,
                               call_21626341.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626341, uri, valid, _)

proc call*(call_21626342: Call_DeleteDevice_21626329; body: JsonNode): Recallable =
  ## deleteDevice
  ## Removes a device from Alexa For Business.
  ##   body: JObject (required)
  var body_21626343 = newJObject()
  if body != nil:
    body_21626343 = body
  result = call_21626342.call(nil, nil, nil, nil, body_21626343)

var deleteDevice* = Call_DeleteDevice_21626329(name: "deleteDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteDevice",
    validator: validate_DeleteDevice_21626330, base: "/", makeUrl: url_DeleteDevice_21626331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceUsageData_21626344 = ref object of OpenApiRestCall_21625435
proc url_DeleteDeviceUsageData_21626346(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDeviceUsageData_21626345(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626347 = header.getOrDefault("X-Amz-Date")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Date", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Security-Token", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Target")
  valid_21626349 = validateParameter(valid_21626349, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteDeviceUsageData"))
  if valid_21626349 != nil:
    section.add "X-Amz-Target", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Algorithm", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Signature")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Signature", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Credential")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Credential", valid_21626354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626356: Call_DeleteDeviceUsageData_21626344;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## When this action is called for a specified shared device, it allows authorized users to delete the device's entire previous history of voice input data and associated response data. This action can be called once every 24 hours for a specific shared device.
  ## 
  let valid = call_21626356.validator(path, query, header, formData, body, _)
  let scheme = call_21626356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626356.makeUrl(scheme.get, call_21626356.host, call_21626356.base,
                               call_21626356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626356, uri, valid, _)

proc call*(call_21626357: Call_DeleteDeviceUsageData_21626344; body: JsonNode): Recallable =
  ## deleteDeviceUsageData
  ## When this action is called for a specified shared device, it allows authorized users to delete the device's entire previous history of voice input data and associated response data. This action can be called once every 24 hours for a specific shared device.
  ##   body: JObject (required)
  var body_21626358 = newJObject()
  if body != nil:
    body_21626358 = body
  result = call_21626357.call(nil, nil, nil, nil, body_21626358)

var deleteDeviceUsageData* = Call_DeleteDeviceUsageData_21626344(
    name: "deleteDeviceUsageData", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteDeviceUsageData",
    validator: validate_DeleteDeviceUsageData_21626345, base: "/",
    makeUrl: url_DeleteDeviceUsageData_21626346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayGroup_21626359 = ref object of OpenApiRestCall_21625435
proc url_DeleteGatewayGroup_21626361(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGatewayGroup_21626360(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626362 = header.getOrDefault("X-Amz-Date")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Date", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-Security-Token", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Target")
  valid_21626364 = validateParameter(valid_21626364, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteGatewayGroup"))
  if valid_21626364 != nil:
    section.add "X-Amz-Target", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Algorithm", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Signature")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Signature", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Credential")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Credential", valid_21626369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626371: Call_DeleteGatewayGroup_21626359; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a gateway group.
  ## 
  let valid = call_21626371.validator(path, query, header, formData, body, _)
  let scheme = call_21626371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626371.makeUrl(scheme.get, call_21626371.host, call_21626371.base,
                               call_21626371.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626371, uri, valid, _)

proc call*(call_21626372: Call_DeleteGatewayGroup_21626359; body: JsonNode): Recallable =
  ## deleteGatewayGroup
  ## Deletes a gateway group.
  ##   body: JObject (required)
  var body_21626373 = newJObject()
  if body != nil:
    body_21626373 = body
  result = call_21626372.call(nil, nil, nil, nil, body_21626373)

var deleteGatewayGroup* = Call_DeleteGatewayGroup_21626359(
    name: "deleteGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteGatewayGroup",
    validator: validate_DeleteGatewayGroup_21626360, base: "/",
    makeUrl: url_DeleteGatewayGroup_21626361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_21626374 = ref object of OpenApiRestCall_21625435
proc url_DeleteNetworkProfile_21626376(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNetworkProfile_21626375(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626377 = header.getOrDefault("X-Amz-Date")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Date", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Security-Token", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Target")
  valid_21626379 = validateParameter(valid_21626379, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteNetworkProfile"))
  if valid_21626379 != nil:
    section.add "X-Amz-Target", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Algorithm", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Signature")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Signature", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Credential")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Credential", valid_21626384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626386: Call_DeleteNetworkProfile_21626374; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a network profile by the network profile ARN.
  ## 
  let valid = call_21626386.validator(path, query, header, formData, body, _)
  let scheme = call_21626386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626386.makeUrl(scheme.get, call_21626386.host, call_21626386.base,
                               call_21626386.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626386, uri, valid, _)

proc call*(call_21626387: Call_DeleteNetworkProfile_21626374; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile by the network profile ARN.
  ##   body: JObject (required)
  var body_21626388 = newJObject()
  if body != nil:
    body_21626388 = body
  result = call_21626387.call(nil, nil, nil, nil, body_21626388)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_21626374(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_21626375, base: "/",
    makeUrl: url_DeleteNetworkProfile_21626376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProfile_21626389 = ref object of OpenApiRestCall_21625435
proc url_DeleteProfile_21626391(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProfile_21626390(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626392 = header.getOrDefault("X-Amz-Date")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Date", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Security-Token", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Target")
  valid_21626394 = validateParameter(valid_21626394, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteProfile"))
  if valid_21626394 != nil:
    section.add "X-Amz-Target", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Algorithm", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Signature")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Signature", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Credential")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Credential", valid_21626399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626401: Call_DeleteProfile_21626389; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a room profile by the profile ARN.
  ## 
  let valid = call_21626401.validator(path, query, header, formData, body, _)
  let scheme = call_21626401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626401.makeUrl(scheme.get, call_21626401.host, call_21626401.base,
                               call_21626401.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626401, uri, valid, _)

proc call*(call_21626402: Call_DeleteProfile_21626389; body: JsonNode): Recallable =
  ## deleteProfile
  ## Deletes a room profile by the profile ARN.
  ##   body: JObject (required)
  var body_21626403 = newJObject()
  if body != nil:
    body_21626403 = body
  result = call_21626402.call(nil, nil, nil, nil, body_21626403)

var deleteProfile* = Call_DeleteProfile_21626389(name: "deleteProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteProfile",
    validator: validate_DeleteProfile_21626390, base: "/",
    makeUrl: url_DeleteProfile_21626391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoom_21626404 = ref object of OpenApiRestCall_21625435
proc url_DeleteRoom_21626406(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRoom_21626405(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626407 = header.getOrDefault("X-Amz-Date")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Date", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Security-Token", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Target")
  valid_21626409 = validateParameter(valid_21626409, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteRoom"))
  if valid_21626409 != nil:
    section.add "X-Amz-Target", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Algorithm", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Signature")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Signature", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Credential")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Credential", valid_21626414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626416: Call_DeleteRoom_21626404; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a room by the room ARN.
  ## 
  let valid = call_21626416.validator(path, query, header, formData, body, _)
  let scheme = call_21626416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626416.makeUrl(scheme.get, call_21626416.host, call_21626416.base,
                               call_21626416.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626416, uri, valid, _)

proc call*(call_21626417: Call_DeleteRoom_21626404; body: JsonNode): Recallable =
  ## deleteRoom
  ## Deletes a room by the room ARN.
  ##   body: JObject (required)
  var body_21626418 = newJObject()
  if body != nil:
    body_21626418 = body
  result = call_21626417.call(nil, nil, nil, nil, body_21626418)

var deleteRoom* = Call_DeleteRoom_21626404(name: "deleteRoom",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DeleteRoom",
                                        validator: validate_DeleteRoom_21626405,
                                        base: "/", makeUrl: url_DeleteRoom_21626406,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoomSkillParameter_21626419 = ref object of OpenApiRestCall_21625435
proc url_DeleteRoomSkillParameter_21626421(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRoomSkillParameter_21626420(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626422 = header.getOrDefault("X-Amz-Date")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Date", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Security-Token", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Target")
  valid_21626424 = validateParameter(valid_21626424, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteRoomSkillParameter"))
  if valid_21626424 != nil:
    section.add "X-Amz-Target", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-Algorithm", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Signature")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Signature", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Credential")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Credential", valid_21626429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626431: Call_DeleteRoomSkillParameter_21626419;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes room skill parameter details by room, skill, and parameter key ID.
  ## 
  let valid = call_21626431.validator(path, query, header, formData, body, _)
  let scheme = call_21626431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626431.makeUrl(scheme.get, call_21626431.host, call_21626431.base,
                               call_21626431.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626431, uri, valid, _)

proc call*(call_21626432: Call_DeleteRoomSkillParameter_21626419; body: JsonNode): Recallable =
  ## deleteRoomSkillParameter
  ## Deletes room skill parameter details by room, skill, and parameter key ID.
  ##   body: JObject (required)
  var body_21626433 = newJObject()
  if body != nil:
    body_21626433 = body
  result = call_21626432.call(nil, nil, nil, nil, body_21626433)

var deleteRoomSkillParameter* = Call_DeleteRoomSkillParameter_21626419(
    name: "deleteRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteRoomSkillParameter",
    validator: validate_DeleteRoomSkillParameter_21626420, base: "/",
    makeUrl: url_DeleteRoomSkillParameter_21626421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSkillAuthorization_21626434 = ref object of OpenApiRestCall_21625435
proc url_DeleteSkillAuthorization_21626436(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSkillAuthorization_21626435(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626437 = header.getOrDefault("X-Amz-Date")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Date", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Security-Token", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Target")
  valid_21626439 = validateParameter(valid_21626439, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteSkillAuthorization"))
  if valid_21626439 != nil:
    section.add "X-Amz-Target", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Algorithm", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Signature")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Signature", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626443
  var valid_21626444 = header.getOrDefault("X-Amz-Credential")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Credential", valid_21626444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626446: Call_DeleteSkillAuthorization_21626434;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Unlinks a third-party account from a skill.
  ## 
  let valid = call_21626446.validator(path, query, header, formData, body, _)
  let scheme = call_21626446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626446.makeUrl(scheme.get, call_21626446.host, call_21626446.base,
                               call_21626446.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626446, uri, valid, _)

proc call*(call_21626447: Call_DeleteSkillAuthorization_21626434; body: JsonNode): Recallable =
  ## deleteSkillAuthorization
  ## Unlinks a third-party account from a skill.
  ##   body: JObject (required)
  var body_21626448 = newJObject()
  if body != nil:
    body_21626448 = body
  result = call_21626447.call(nil, nil, nil, nil, body_21626448)

var deleteSkillAuthorization* = Call_DeleteSkillAuthorization_21626434(
    name: "deleteSkillAuthorization", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteSkillAuthorization",
    validator: validate_DeleteSkillAuthorization_21626435, base: "/",
    makeUrl: url_DeleteSkillAuthorization_21626436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSkillGroup_21626449 = ref object of OpenApiRestCall_21625435
proc url_DeleteSkillGroup_21626451(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSkillGroup_21626450(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626452 = header.getOrDefault("X-Amz-Date")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Date", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Security-Token", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Target")
  valid_21626454 = validateParameter(valid_21626454, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteSkillGroup"))
  if valid_21626454 != nil:
    section.add "X-Amz-Target", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Algorithm", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Signature")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Signature", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Credential")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Credential", valid_21626459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626461: Call_DeleteSkillGroup_21626449; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a skill group by skill group ARN.
  ## 
  let valid = call_21626461.validator(path, query, header, formData, body, _)
  let scheme = call_21626461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626461.makeUrl(scheme.get, call_21626461.host, call_21626461.base,
                               call_21626461.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626461, uri, valid, _)

proc call*(call_21626462: Call_DeleteSkillGroup_21626449; body: JsonNode): Recallable =
  ## deleteSkillGroup
  ## Deletes a skill group by skill group ARN.
  ##   body: JObject (required)
  var body_21626463 = newJObject()
  if body != nil:
    body_21626463 = body
  result = call_21626462.call(nil, nil, nil, nil, body_21626463)

var deleteSkillGroup* = Call_DeleteSkillGroup_21626449(name: "deleteSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteSkillGroup",
    validator: validate_DeleteSkillGroup_21626450, base: "/",
    makeUrl: url_DeleteSkillGroup_21626451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_21626464 = ref object of OpenApiRestCall_21625435
proc url_DeleteUser_21626466(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUser_21626465(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626467 = header.getOrDefault("X-Amz-Date")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Date", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Security-Token", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Target")
  valid_21626469 = validateParameter(valid_21626469, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteUser"))
  if valid_21626469 != nil:
    section.add "X-Amz-Target", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Algorithm", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Signature")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Signature", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Credential")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Credential", valid_21626474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626476: Call_DeleteUser_21626464; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified user by user ARN and enrollment ARN.
  ## 
  let valid = call_21626476.validator(path, query, header, formData, body, _)
  let scheme = call_21626476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626476.makeUrl(scheme.get, call_21626476.host, call_21626476.base,
                               call_21626476.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626476, uri, valid, _)

proc call*(call_21626477: Call_DeleteUser_21626464; body: JsonNode): Recallable =
  ## deleteUser
  ## Deletes a specified user by user ARN and enrollment ARN.
  ##   body: JObject (required)
  var body_21626478 = newJObject()
  if body != nil:
    body_21626478 = body
  result = call_21626477.call(nil, nil, nil, nil, body_21626478)

var deleteUser* = Call_DeleteUser_21626464(name: "deleteUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DeleteUser",
                                        validator: validate_DeleteUser_21626465,
                                        base: "/", makeUrl: url_DeleteUser_21626466,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateContactFromAddressBook_21626479 = ref object of OpenApiRestCall_21625435
proc url_DisassociateContactFromAddressBook_21626481(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateContactFromAddressBook_21626480(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626482 = header.getOrDefault("X-Amz-Date")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Date", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Security-Token", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Target")
  valid_21626484 = validateParameter(valid_21626484, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateContactFromAddressBook"))
  if valid_21626484 != nil:
    section.add "X-Amz-Target", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Algorithm", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-Signature")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Signature", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Credential")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Credential", valid_21626489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626491: Call_DisassociateContactFromAddressBook_21626479;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates a contact from a given address book.
  ## 
  let valid = call_21626491.validator(path, query, header, formData, body, _)
  let scheme = call_21626491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626491.makeUrl(scheme.get, call_21626491.host, call_21626491.base,
                               call_21626491.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626491, uri, valid, _)

proc call*(call_21626492: Call_DisassociateContactFromAddressBook_21626479;
          body: JsonNode): Recallable =
  ## disassociateContactFromAddressBook
  ## Disassociates a contact from a given address book.
  ##   body: JObject (required)
  var body_21626493 = newJObject()
  if body != nil:
    body_21626493 = body
  result = call_21626492.call(nil, nil, nil, nil, body_21626493)

var disassociateContactFromAddressBook* = Call_DisassociateContactFromAddressBook_21626479(
    name: "disassociateContactFromAddressBook", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DisassociateContactFromAddressBook",
    validator: validate_DisassociateContactFromAddressBook_21626480, base: "/",
    makeUrl: url_DisassociateContactFromAddressBook_21626481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDeviceFromRoom_21626494 = ref object of OpenApiRestCall_21625435
proc url_DisassociateDeviceFromRoom_21626496(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateDeviceFromRoom_21626495(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626497 = header.getOrDefault("X-Amz-Date")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Date", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-Security-Token", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-Target")
  valid_21626499 = validateParameter(valid_21626499, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateDeviceFromRoom"))
  if valid_21626499 != nil:
    section.add "X-Amz-Target", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-Algorithm", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Signature")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Signature", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Credential")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Credential", valid_21626504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626506: Call_DisassociateDeviceFromRoom_21626494;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates a device from its current room. The device continues to be connected to the Wi-Fi network and is still registered to the account. The device settings and skills are removed from the room.
  ## 
  let valid = call_21626506.validator(path, query, header, formData, body, _)
  let scheme = call_21626506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626506.makeUrl(scheme.get, call_21626506.host, call_21626506.base,
                               call_21626506.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626506, uri, valid, _)

proc call*(call_21626507: Call_DisassociateDeviceFromRoom_21626494; body: JsonNode): Recallable =
  ## disassociateDeviceFromRoom
  ## Disassociates a device from its current room. The device continues to be connected to the Wi-Fi network and is still registered to the account. The device settings and skills are removed from the room.
  ##   body: JObject (required)
  var body_21626508 = newJObject()
  if body != nil:
    body_21626508 = body
  result = call_21626507.call(nil, nil, nil, nil, body_21626508)

var disassociateDeviceFromRoom* = Call_DisassociateDeviceFromRoom_21626494(
    name: "disassociateDeviceFromRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateDeviceFromRoom",
    validator: validate_DisassociateDeviceFromRoom_21626495, base: "/",
    makeUrl: url_DisassociateDeviceFromRoom_21626496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillFromSkillGroup_21626509 = ref object of OpenApiRestCall_21625435
proc url_DisassociateSkillFromSkillGroup_21626511(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateSkillFromSkillGroup_21626510(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626512 = header.getOrDefault("X-Amz-Date")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Date", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Security-Token", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Target")
  valid_21626514 = validateParameter(valid_21626514, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillFromSkillGroup"))
  if valid_21626514 != nil:
    section.add "X-Amz-Target", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Algorithm", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Signature")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Signature", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Credential")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Credential", valid_21626519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626521: Call_DisassociateSkillFromSkillGroup_21626509;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates a skill from a skill group.
  ## 
  let valid = call_21626521.validator(path, query, header, formData, body, _)
  let scheme = call_21626521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626521.makeUrl(scheme.get, call_21626521.host, call_21626521.base,
                               call_21626521.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626521, uri, valid, _)

proc call*(call_21626522: Call_DisassociateSkillFromSkillGroup_21626509;
          body: JsonNode): Recallable =
  ## disassociateSkillFromSkillGroup
  ## Disassociates a skill from a skill group.
  ##   body: JObject (required)
  var body_21626523 = newJObject()
  if body != nil:
    body_21626523 = body
  result = call_21626522.call(nil, nil, nil, nil, body_21626523)

var disassociateSkillFromSkillGroup* = Call_DisassociateSkillFromSkillGroup_21626509(
    name: "disassociateSkillFromSkillGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillFromSkillGroup",
    validator: validate_DisassociateSkillFromSkillGroup_21626510, base: "/",
    makeUrl: url_DisassociateSkillFromSkillGroup_21626511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillFromUsers_21626524 = ref object of OpenApiRestCall_21625435
proc url_DisassociateSkillFromUsers_21626526(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateSkillFromUsers_21626525(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626527 = header.getOrDefault("X-Amz-Date")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Date", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Security-Token", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Target")
  valid_21626529 = validateParameter(valid_21626529, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillFromUsers"))
  if valid_21626529 != nil:
    section.add "X-Amz-Target", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Algorithm", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-Signature")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Signature", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-Credential")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Credential", valid_21626534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626536: Call_DisassociateSkillFromUsers_21626524;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Makes a private skill unavailable for enrolled users and prevents them from enabling it on their devices.
  ## 
  let valid = call_21626536.validator(path, query, header, formData, body, _)
  let scheme = call_21626536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626536.makeUrl(scheme.get, call_21626536.host, call_21626536.base,
                               call_21626536.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626536, uri, valid, _)

proc call*(call_21626537: Call_DisassociateSkillFromUsers_21626524; body: JsonNode): Recallable =
  ## disassociateSkillFromUsers
  ## Makes a private skill unavailable for enrolled users and prevents them from enabling it on their devices.
  ##   body: JObject (required)
  var body_21626538 = newJObject()
  if body != nil:
    body_21626538 = body
  result = call_21626537.call(nil, nil, nil, nil, body_21626538)

var disassociateSkillFromUsers* = Call_DisassociateSkillFromUsers_21626524(
    name: "disassociateSkillFromUsers", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillFromUsers",
    validator: validate_DisassociateSkillFromUsers_21626525, base: "/",
    makeUrl: url_DisassociateSkillFromUsers_21626526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillGroupFromRoom_21626539 = ref object of OpenApiRestCall_21625435
proc url_DisassociateSkillGroupFromRoom_21626541(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateSkillGroupFromRoom_21626540(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626542 = header.getOrDefault("X-Amz-Date")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Date", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Security-Token", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Target")
  valid_21626544 = validateParameter(valid_21626544, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillGroupFromRoom"))
  if valid_21626544 != nil:
    section.add "X-Amz-Target", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Algorithm", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-Signature")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Signature", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Credential")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Credential", valid_21626549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626551: Call_DisassociateSkillGroupFromRoom_21626539;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates a skill group from a specified room. This disables all skills in the skill group on all devices in the room.
  ## 
  let valid = call_21626551.validator(path, query, header, formData, body, _)
  let scheme = call_21626551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626551.makeUrl(scheme.get, call_21626551.host, call_21626551.base,
                               call_21626551.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626551, uri, valid, _)

proc call*(call_21626552: Call_DisassociateSkillGroupFromRoom_21626539;
          body: JsonNode): Recallable =
  ## disassociateSkillGroupFromRoom
  ## Disassociates a skill group from a specified room. This disables all skills in the skill group on all devices in the room.
  ##   body: JObject (required)
  var body_21626553 = newJObject()
  if body != nil:
    body_21626553 = body
  result = call_21626552.call(nil, nil, nil, nil, body_21626553)

var disassociateSkillGroupFromRoom* = Call_DisassociateSkillGroupFromRoom_21626539(
    name: "disassociateSkillGroupFromRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillGroupFromRoom",
    validator: validate_DisassociateSkillGroupFromRoom_21626540, base: "/",
    makeUrl: url_DisassociateSkillGroupFromRoom_21626541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgetSmartHomeAppliances_21626554 = ref object of OpenApiRestCall_21625435
proc url_ForgetSmartHomeAppliances_21626556(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ForgetSmartHomeAppliances_21626555(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626557 = header.getOrDefault("X-Amz-Date")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Date", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Security-Token", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Target")
  valid_21626559 = validateParameter(valid_21626559, JString, required = true, default = newJString(
      "AlexaForBusiness.ForgetSmartHomeAppliances"))
  if valid_21626559 != nil:
    section.add "X-Amz-Target", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Algorithm", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Signature")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Signature", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-Credential")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-Credential", valid_21626564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626566: Call_ForgetSmartHomeAppliances_21626554;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Forgets smart home appliances associated to a room.
  ## 
  let valid = call_21626566.validator(path, query, header, formData, body, _)
  let scheme = call_21626566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626566.makeUrl(scheme.get, call_21626566.host, call_21626566.base,
                               call_21626566.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626566, uri, valid, _)

proc call*(call_21626567: Call_ForgetSmartHomeAppliances_21626554; body: JsonNode): Recallable =
  ## forgetSmartHomeAppliances
  ## Forgets smart home appliances associated to a room.
  ##   body: JObject (required)
  var body_21626568 = newJObject()
  if body != nil:
    body_21626568 = body
  result = call_21626567.call(nil, nil, nil, nil, body_21626568)

var forgetSmartHomeAppliances* = Call_ForgetSmartHomeAppliances_21626554(
    name: "forgetSmartHomeAppliances", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ForgetSmartHomeAppliances",
    validator: validate_ForgetSmartHomeAppliances_21626555, base: "/",
    makeUrl: url_ForgetSmartHomeAppliances_21626556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddressBook_21626569 = ref object of OpenApiRestCall_21625435
proc url_GetAddressBook_21626571(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddressBook_21626570(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626572 = header.getOrDefault("X-Amz-Date")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-Date", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-Security-Token", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-Target")
  valid_21626574 = validateParameter(valid_21626574, JString, required = true, default = newJString(
      "AlexaForBusiness.GetAddressBook"))
  if valid_21626574 != nil:
    section.add "X-Amz-Target", valid_21626574
  var valid_21626575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626575
  var valid_21626576 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Algorithm", valid_21626576
  var valid_21626577 = header.getOrDefault("X-Amz-Signature")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Signature", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Credential")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Credential", valid_21626579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626581: Call_GetAddressBook_21626569; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets address the book details by the address book ARN.
  ## 
  let valid = call_21626581.validator(path, query, header, formData, body, _)
  let scheme = call_21626581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626581.makeUrl(scheme.get, call_21626581.host, call_21626581.base,
                               call_21626581.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626581, uri, valid, _)

proc call*(call_21626582: Call_GetAddressBook_21626569; body: JsonNode): Recallable =
  ## getAddressBook
  ## Gets address the book details by the address book ARN.
  ##   body: JObject (required)
  var body_21626583 = newJObject()
  if body != nil:
    body_21626583 = body
  result = call_21626582.call(nil, nil, nil, nil, body_21626583)

var getAddressBook* = Call_GetAddressBook_21626569(name: "getAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetAddressBook",
    validator: validate_GetAddressBook_21626570, base: "/",
    makeUrl: url_GetAddressBook_21626571, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConferencePreference_21626584 = ref object of OpenApiRestCall_21625435
proc url_GetConferencePreference_21626586(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConferencePreference_21626585(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626587 = header.getOrDefault("X-Amz-Date")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-Date", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-Security-Token", valid_21626588
  var valid_21626589 = header.getOrDefault("X-Amz-Target")
  valid_21626589 = validateParameter(valid_21626589, JString, required = true, default = newJString(
      "AlexaForBusiness.GetConferencePreference"))
  if valid_21626589 != nil:
    section.add "X-Amz-Target", valid_21626589
  var valid_21626590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626590 = validateParameter(valid_21626590, JString, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626590
  var valid_21626591 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626591 = validateParameter(valid_21626591, JString, required = false,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "X-Amz-Algorithm", valid_21626591
  var valid_21626592 = header.getOrDefault("X-Amz-Signature")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "X-Amz-Signature", valid_21626592
  var valid_21626593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Credential")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Credential", valid_21626594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626596: Call_GetConferencePreference_21626584;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the existing conference preferences.
  ## 
  let valid = call_21626596.validator(path, query, header, formData, body, _)
  let scheme = call_21626596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626596.makeUrl(scheme.get, call_21626596.host, call_21626596.base,
                               call_21626596.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626596, uri, valid, _)

proc call*(call_21626597: Call_GetConferencePreference_21626584; body: JsonNode): Recallable =
  ## getConferencePreference
  ## Retrieves the existing conference preferences.
  ##   body: JObject (required)
  var body_21626598 = newJObject()
  if body != nil:
    body_21626598 = body
  result = call_21626597.call(nil, nil, nil, nil, body_21626598)

var getConferencePreference* = Call_GetConferencePreference_21626584(
    name: "getConferencePreference", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetConferencePreference",
    validator: validate_GetConferencePreference_21626585, base: "/",
    makeUrl: url_GetConferencePreference_21626586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConferenceProvider_21626599 = ref object of OpenApiRestCall_21625435
proc url_GetConferenceProvider_21626601(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConferenceProvider_21626600(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626602 = header.getOrDefault("X-Amz-Date")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Date", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-Security-Token", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-Target")
  valid_21626604 = validateParameter(valid_21626604, JString, required = true, default = newJString(
      "AlexaForBusiness.GetConferenceProvider"))
  if valid_21626604 != nil:
    section.add "X-Amz-Target", valid_21626604
  var valid_21626605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626605
  var valid_21626606 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626606 = validateParameter(valid_21626606, JString, required = false,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "X-Amz-Algorithm", valid_21626606
  var valid_21626607 = header.getOrDefault("X-Amz-Signature")
  valid_21626607 = validateParameter(valid_21626607, JString, required = false,
                                   default = nil)
  if valid_21626607 != nil:
    section.add "X-Amz-Signature", valid_21626607
  var valid_21626608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626608 = validateParameter(valid_21626608, JString, required = false,
                                   default = nil)
  if valid_21626608 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626608
  var valid_21626609 = header.getOrDefault("X-Amz-Credential")
  valid_21626609 = validateParameter(valid_21626609, JString, required = false,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "X-Amz-Credential", valid_21626609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626611: Call_GetConferenceProvider_21626599;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details about a specific conference provider.
  ## 
  let valid = call_21626611.validator(path, query, header, formData, body, _)
  let scheme = call_21626611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626611.makeUrl(scheme.get, call_21626611.host, call_21626611.base,
                               call_21626611.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626611, uri, valid, _)

proc call*(call_21626612: Call_GetConferenceProvider_21626599; body: JsonNode): Recallable =
  ## getConferenceProvider
  ## Gets details about a specific conference provider.
  ##   body: JObject (required)
  var body_21626613 = newJObject()
  if body != nil:
    body_21626613 = body
  result = call_21626612.call(nil, nil, nil, nil, body_21626613)

var getConferenceProvider* = Call_GetConferenceProvider_21626599(
    name: "getConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetConferenceProvider",
    validator: validate_GetConferenceProvider_21626600, base: "/",
    makeUrl: url_GetConferenceProvider_21626601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContact_21626614 = ref object of OpenApiRestCall_21625435
proc url_GetContact_21626616(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetContact_21626615(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626617 = header.getOrDefault("X-Amz-Date")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Date", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Security-Token", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Target")
  valid_21626619 = validateParameter(valid_21626619, JString, required = true, default = newJString(
      "AlexaForBusiness.GetContact"))
  if valid_21626619 != nil:
    section.add "X-Amz-Target", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626620
  var valid_21626621 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-Algorithm", valid_21626621
  var valid_21626622 = header.getOrDefault("X-Amz-Signature")
  valid_21626622 = validateParameter(valid_21626622, JString, required = false,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "X-Amz-Signature", valid_21626622
  var valid_21626623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626623 = validateParameter(valid_21626623, JString, required = false,
                                   default = nil)
  if valid_21626623 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626623
  var valid_21626624 = header.getOrDefault("X-Amz-Credential")
  valid_21626624 = validateParameter(valid_21626624, JString, required = false,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "X-Amz-Credential", valid_21626624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626626: Call_GetContact_21626614; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the contact details by the contact ARN.
  ## 
  let valid = call_21626626.validator(path, query, header, formData, body, _)
  let scheme = call_21626626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626626.makeUrl(scheme.get, call_21626626.host, call_21626626.base,
                               call_21626626.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626626, uri, valid, _)

proc call*(call_21626627: Call_GetContact_21626614; body: JsonNode): Recallable =
  ## getContact
  ## Gets the contact details by the contact ARN.
  ##   body: JObject (required)
  var body_21626628 = newJObject()
  if body != nil:
    body_21626628 = body
  result = call_21626627.call(nil, nil, nil, nil, body_21626628)

var getContact* = Call_GetContact_21626614(name: "getContact",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetContact",
                                        validator: validate_GetContact_21626615,
                                        base: "/", makeUrl: url_GetContact_21626616,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_21626629 = ref object of OpenApiRestCall_21625435
proc url_GetDevice_21626631(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDevice_21626630(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626632 = header.getOrDefault("X-Amz-Date")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Date", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Security-Token", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Target")
  valid_21626634 = validateParameter(valid_21626634, JString, required = true, default = newJString(
      "AlexaForBusiness.GetDevice"))
  if valid_21626634 != nil:
    section.add "X-Amz-Target", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626635
  var valid_21626636 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "X-Amz-Algorithm", valid_21626636
  var valid_21626637 = header.getOrDefault("X-Amz-Signature")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Signature", valid_21626637
  var valid_21626638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626638 = validateParameter(valid_21626638, JString, required = false,
                                   default = nil)
  if valid_21626638 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626638
  var valid_21626639 = header.getOrDefault("X-Amz-Credential")
  valid_21626639 = validateParameter(valid_21626639, JString, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "X-Amz-Credential", valid_21626639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626641: Call_GetDevice_21626629; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the details of a device by device ARN.
  ## 
  let valid = call_21626641.validator(path, query, header, formData, body, _)
  let scheme = call_21626641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626641.makeUrl(scheme.get, call_21626641.host, call_21626641.base,
                               call_21626641.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626641, uri, valid, _)

proc call*(call_21626642: Call_GetDevice_21626629; body: JsonNode): Recallable =
  ## getDevice
  ## Gets the details of a device by device ARN.
  ##   body: JObject (required)
  var body_21626643 = newJObject()
  if body != nil:
    body_21626643 = body
  result = call_21626642.call(nil, nil, nil, nil, body_21626643)

var getDevice* = Call_GetDevice_21626629(name: "getDevice",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetDevice",
                                      validator: validate_GetDevice_21626630,
                                      base: "/", makeUrl: url_GetDevice_21626631,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGateway_21626644 = ref object of OpenApiRestCall_21625435
proc url_GetGateway_21626646(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGateway_21626645(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626647 = header.getOrDefault("X-Amz-Date")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Date", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Security-Token", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Target")
  valid_21626649 = validateParameter(valid_21626649, JString, required = true, default = newJString(
      "AlexaForBusiness.GetGateway"))
  if valid_21626649 != nil:
    section.add "X-Amz-Target", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-Algorithm", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Signature")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Signature", valid_21626652
  var valid_21626653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626653 = validateParameter(valid_21626653, JString, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626653
  var valid_21626654 = header.getOrDefault("X-Amz-Credential")
  valid_21626654 = validateParameter(valid_21626654, JString, required = false,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "X-Amz-Credential", valid_21626654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626656: Call_GetGateway_21626644; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the details of a gateway.
  ## 
  let valid = call_21626656.validator(path, query, header, formData, body, _)
  let scheme = call_21626656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626656.makeUrl(scheme.get, call_21626656.host, call_21626656.base,
                               call_21626656.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626656, uri, valid, _)

proc call*(call_21626657: Call_GetGateway_21626644; body: JsonNode): Recallable =
  ## getGateway
  ## Retrieves the details of a gateway.
  ##   body: JObject (required)
  var body_21626658 = newJObject()
  if body != nil:
    body_21626658 = body
  result = call_21626657.call(nil, nil, nil, nil, body_21626658)

var getGateway* = Call_GetGateway_21626644(name: "getGateway",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetGateway",
                                        validator: validate_GetGateway_21626645,
                                        base: "/", makeUrl: url_GetGateway_21626646,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayGroup_21626659 = ref object of OpenApiRestCall_21625435
proc url_GetGatewayGroup_21626661(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGatewayGroup_21626660(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626662 = header.getOrDefault("X-Amz-Date")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Date", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Security-Token", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-Target")
  valid_21626664 = validateParameter(valid_21626664, JString, required = true, default = newJString(
      "AlexaForBusiness.GetGatewayGroup"))
  if valid_21626664 != nil:
    section.add "X-Amz-Target", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Algorithm", valid_21626666
  var valid_21626667 = header.getOrDefault("X-Amz-Signature")
  valid_21626667 = validateParameter(valid_21626667, JString, required = false,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "X-Amz-Signature", valid_21626667
  var valid_21626668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626668
  var valid_21626669 = header.getOrDefault("X-Amz-Credential")
  valid_21626669 = validateParameter(valid_21626669, JString, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "X-Amz-Credential", valid_21626669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626671: Call_GetGatewayGroup_21626659; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the details of a gateway group.
  ## 
  let valid = call_21626671.validator(path, query, header, formData, body, _)
  let scheme = call_21626671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626671.makeUrl(scheme.get, call_21626671.host, call_21626671.base,
                               call_21626671.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626671, uri, valid, _)

proc call*(call_21626672: Call_GetGatewayGroup_21626659; body: JsonNode): Recallable =
  ## getGatewayGroup
  ## Retrieves the details of a gateway group.
  ##   body: JObject (required)
  var body_21626673 = newJObject()
  if body != nil:
    body_21626673 = body
  result = call_21626672.call(nil, nil, nil, nil, body_21626673)

var getGatewayGroup* = Call_GetGatewayGroup_21626659(name: "getGatewayGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetGatewayGroup",
    validator: validate_GetGatewayGroup_21626660, base: "/",
    makeUrl: url_GetGatewayGroup_21626661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationConfiguration_21626674 = ref object of OpenApiRestCall_21625435
proc url_GetInvitationConfiguration_21626676(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInvitationConfiguration_21626675(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626677 = header.getOrDefault("X-Amz-Date")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Date", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Security-Token", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Target")
  valid_21626679 = validateParameter(valid_21626679, JString, required = true, default = newJString(
      "AlexaForBusiness.GetInvitationConfiguration"))
  if valid_21626679 != nil:
    section.add "X-Amz-Target", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Algorithm", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Signature")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-Signature", valid_21626682
  var valid_21626683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626683
  var valid_21626684 = header.getOrDefault("X-Amz-Credential")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-Credential", valid_21626684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626686: Call_GetInvitationConfiguration_21626674;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the configured values for the user enrollment invitation email template.
  ## 
  let valid = call_21626686.validator(path, query, header, formData, body, _)
  let scheme = call_21626686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626686.makeUrl(scheme.get, call_21626686.host, call_21626686.base,
                               call_21626686.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626686, uri, valid, _)

proc call*(call_21626687: Call_GetInvitationConfiguration_21626674; body: JsonNode): Recallable =
  ## getInvitationConfiguration
  ## Retrieves the configured values for the user enrollment invitation email template.
  ##   body: JObject (required)
  var body_21626688 = newJObject()
  if body != nil:
    body_21626688 = body
  result = call_21626687.call(nil, nil, nil, nil, body_21626688)

var getInvitationConfiguration* = Call_GetInvitationConfiguration_21626674(
    name: "getInvitationConfiguration", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetInvitationConfiguration",
    validator: validate_GetInvitationConfiguration_21626675, base: "/",
    makeUrl: url_GetInvitationConfiguration_21626676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_21626689 = ref object of OpenApiRestCall_21625435
proc url_GetNetworkProfile_21626691(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetNetworkProfile_21626690(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626692 = header.getOrDefault("X-Amz-Date")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Date", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-Security-Token", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Target")
  valid_21626694 = validateParameter(valid_21626694, JString, required = true, default = newJString(
      "AlexaForBusiness.GetNetworkProfile"))
  if valid_21626694 != nil:
    section.add "X-Amz-Target", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Algorithm", valid_21626696
  var valid_21626697 = header.getOrDefault("X-Amz-Signature")
  valid_21626697 = validateParameter(valid_21626697, JString, required = false,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "X-Amz-Signature", valid_21626697
  var valid_21626698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626698
  var valid_21626699 = header.getOrDefault("X-Amz-Credential")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "X-Amz-Credential", valid_21626699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626701: Call_GetNetworkProfile_21626689; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the network profile details by the network profile ARN.
  ## 
  let valid = call_21626701.validator(path, query, header, formData, body, _)
  let scheme = call_21626701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626701.makeUrl(scheme.get, call_21626701.host, call_21626701.base,
                               call_21626701.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626701, uri, valid, _)

proc call*(call_21626702: Call_GetNetworkProfile_21626689; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Gets the network profile details by the network profile ARN.
  ##   body: JObject (required)
  var body_21626703 = newJObject()
  if body != nil:
    body_21626703 = body
  result = call_21626702.call(nil, nil, nil, nil, body_21626703)

var getNetworkProfile* = Call_GetNetworkProfile_21626689(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetNetworkProfile",
    validator: validate_GetNetworkProfile_21626690, base: "/",
    makeUrl: url_GetNetworkProfile_21626691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProfile_21626704 = ref object of OpenApiRestCall_21625435
proc url_GetProfile_21626706(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetProfile_21626705(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626707 = header.getOrDefault("X-Amz-Date")
  valid_21626707 = validateParameter(valid_21626707, JString, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "X-Amz-Date", valid_21626707
  var valid_21626708 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-Security-Token", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-Target")
  valid_21626709 = validateParameter(valid_21626709, JString, required = true, default = newJString(
      "AlexaForBusiness.GetProfile"))
  if valid_21626709 != nil:
    section.add "X-Amz-Target", valid_21626709
  var valid_21626710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "X-Amz-Algorithm", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Signature")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Signature", valid_21626712
  var valid_21626713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-Credential")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Credential", valid_21626714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626716: Call_GetProfile_21626704; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the details of a room profile by profile ARN.
  ## 
  let valid = call_21626716.validator(path, query, header, formData, body, _)
  let scheme = call_21626716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626716.makeUrl(scheme.get, call_21626716.host, call_21626716.base,
                               call_21626716.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626716, uri, valid, _)

proc call*(call_21626717: Call_GetProfile_21626704; body: JsonNode): Recallable =
  ## getProfile
  ## Gets the details of a room profile by profile ARN.
  ##   body: JObject (required)
  var body_21626718 = newJObject()
  if body != nil:
    body_21626718 = body
  result = call_21626717.call(nil, nil, nil, nil, body_21626718)

var getProfile* = Call_GetProfile_21626704(name: "getProfile",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetProfile",
                                        validator: validate_GetProfile_21626705,
                                        base: "/", makeUrl: url_GetProfile_21626706,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoom_21626719 = ref object of OpenApiRestCall_21625435
proc url_GetRoom_21626721(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRoom_21626720(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626722 = header.getOrDefault("X-Amz-Date")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-Date", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-Security-Token", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Target")
  valid_21626724 = validateParameter(valid_21626724, JString, required = true, default = newJString(
      "AlexaForBusiness.GetRoom"))
  if valid_21626724 != nil:
    section.add "X-Amz-Target", valid_21626724
  var valid_21626725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626725
  var valid_21626726 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-Algorithm", valid_21626726
  var valid_21626727 = header.getOrDefault("X-Amz-Signature")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-Signature", valid_21626727
  var valid_21626728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626728 = validateParameter(valid_21626728, JString, required = false,
                                   default = nil)
  if valid_21626728 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626728
  var valid_21626729 = header.getOrDefault("X-Amz-Credential")
  valid_21626729 = validateParameter(valid_21626729, JString, required = false,
                                   default = nil)
  if valid_21626729 != nil:
    section.add "X-Amz-Credential", valid_21626729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626731: Call_GetRoom_21626719; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets room details by room ARN.
  ## 
  let valid = call_21626731.validator(path, query, header, formData, body, _)
  let scheme = call_21626731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626731.makeUrl(scheme.get, call_21626731.host, call_21626731.base,
                               call_21626731.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626731, uri, valid, _)

proc call*(call_21626732: Call_GetRoom_21626719; body: JsonNode): Recallable =
  ## getRoom
  ## Gets room details by room ARN.
  ##   body: JObject (required)
  var body_21626733 = newJObject()
  if body != nil:
    body_21626733 = body
  result = call_21626732.call(nil, nil, nil, nil, body_21626733)

var getRoom* = Call_GetRoom_21626719(name: "getRoom", meth: HttpMethod.HttpPost,
                                  host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetRoom",
                                  validator: validate_GetRoom_21626720, base: "/",
                                  makeUrl: url_GetRoom_21626721,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoomSkillParameter_21626734 = ref object of OpenApiRestCall_21625435
proc url_GetRoomSkillParameter_21626736(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRoomSkillParameter_21626735(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626737 = header.getOrDefault("X-Amz-Date")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-Date", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-Security-Token", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-Target")
  valid_21626739 = validateParameter(valid_21626739, JString, required = true, default = newJString(
      "AlexaForBusiness.GetRoomSkillParameter"))
  if valid_21626739 != nil:
    section.add "X-Amz-Target", valid_21626739
  var valid_21626740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626740
  var valid_21626741 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626741 = validateParameter(valid_21626741, JString, required = false,
                                   default = nil)
  if valid_21626741 != nil:
    section.add "X-Amz-Algorithm", valid_21626741
  var valid_21626742 = header.getOrDefault("X-Amz-Signature")
  valid_21626742 = validateParameter(valid_21626742, JString, required = false,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "X-Amz-Signature", valid_21626742
  var valid_21626743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626743
  var valid_21626744 = header.getOrDefault("X-Amz-Credential")
  valid_21626744 = validateParameter(valid_21626744, JString, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "X-Amz-Credential", valid_21626744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626746: Call_GetRoomSkillParameter_21626734;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets room skill parameter details by room, skill, and parameter key ARN.
  ## 
  let valid = call_21626746.validator(path, query, header, formData, body, _)
  let scheme = call_21626746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626746.makeUrl(scheme.get, call_21626746.host, call_21626746.base,
                               call_21626746.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626746, uri, valid, _)

proc call*(call_21626747: Call_GetRoomSkillParameter_21626734; body: JsonNode): Recallable =
  ## getRoomSkillParameter
  ## Gets room skill parameter details by room, skill, and parameter key ARN.
  ##   body: JObject (required)
  var body_21626748 = newJObject()
  if body != nil:
    body_21626748 = body
  result = call_21626747.call(nil, nil, nil, nil, body_21626748)

var getRoomSkillParameter* = Call_GetRoomSkillParameter_21626734(
    name: "getRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetRoomSkillParameter",
    validator: validate_GetRoomSkillParameter_21626735, base: "/",
    makeUrl: url_GetRoomSkillParameter_21626736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSkillGroup_21626749 = ref object of OpenApiRestCall_21625435
proc url_GetSkillGroup_21626751(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSkillGroup_21626750(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626752 = header.getOrDefault("X-Amz-Date")
  valid_21626752 = validateParameter(valid_21626752, JString, required = false,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "X-Amz-Date", valid_21626752
  var valid_21626753 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626753 = validateParameter(valid_21626753, JString, required = false,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "X-Amz-Security-Token", valid_21626753
  var valid_21626754 = header.getOrDefault("X-Amz-Target")
  valid_21626754 = validateParameter(valid_21626754, JString, required = true, default = newJString(
      "AlexaForBusiness.GetSkillGroup"))
  if valid_21626754 != nil:
    section.add "X-Amz-Target", valid_21626754
  var valid_21626755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626755 = validateParameter(valid_21626755, JString, required = false,
                                   default = nil)
  if valid_21626755 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626755
  var valid_21626756 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626756 = validateParameter(valid_21626756, JString, required = false,
                                   default = nil)
  if valid_21626756 != nil:
    section.add "X-Amz-Algorithm", valid_21626756
  var valid_21626757 = header.getOrDefault("X-Amz-Signature")
  valid_21626757 = validateParameter(valid_21626757, JString, required = false,
                                   default = nil)
  if valid_21626757 != nil:
    section.add "X-Amz-Signature", valid_21626757
  var valid_21626758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626758 = validateParameter(valid_21626758, JString, required = false,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626758
  var valid_21626759 = header.getOrDefault("X-Amz-Credential")
  valid_21626759 = validateParameter(valid_21626759, JString, required = false,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "X-Amz-Credential", valid_21626759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626761: Call_GetSkillGroup_21626749; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets skill group details by skill group ARN.
  ## 
  let valid = call_21626761.validator(path, query, header, formData, body, _)
  let scheme = call_21626761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626761.makeUrl(scheme.get, call_21626761.host, call_21626761.base,
                               call_21626761.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626761, uri, valid, _)

proc call*(call_21626762: Call_GetSkillGroup_21626749; body: JsonNode): Recallable =
  ## getSkillGroup
  ## Gets skill group details by skill group ARN.
  ##   body: JObject (required)
  var body_21626763 = newJObject()
  if body != nil:
    body_21626763 = body
  result = call_21626762.call(nil, nil, nil, nil, body_21626763)

var getSkillGroup* = Call_GetSkillGroup_21626749(name: "getSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetSkillGroup",
    validator: validate_GetSkillGroup_21626750, base: "/",
    makeUrl: url_GetSkillGroup_21626751, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBusinessReportSchedules_21626764 = ref object of OpenApiRestCall_21625435
proc url_ListBusinessReportSchedules_21626766(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBusinessReportSchedules_21626765(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the details of the schedules that a user configured. A download URL of the report associated with each schedule is returned every time this action is called. A new download URL is returned each time, and is valid for 24 hours.
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
  var valid_21626767 = query.getOrDefault("NextToken")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "NextToken", valid_21626767
  var valid_21626768 = query.getOrDefault("MaxResults")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "MaxResults", valid_21626768
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
  var valid_21626769 = header.getOrDefault("X-Amz-Date")
  valid_21626769 = validateParameter(valid_21626769, JString, required = false,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "X-Amz-Date", valid_21626769
  var valid_21626770 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626770 = validateParameter(valid_21626770, JString, required = false,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "X-Amz-Security-Token", valid_21626770
  var valid_21626771 = header.getOrDefault("X-Amz-Target")
  valid_21626771 = validateParameter(valid_21626771, JString, required = true, default = newJString(
      "AlexaForBusiness.ListBusinessReportSchedules"))
  if valid_21626771 != nil:
    section.add "X-Amz-Target", valid_21626771
  var valid_21626772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626772 = validateParameter(valid_21626772, JString, required = false,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626772
  var valid_21626773 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626773 = validateParameter(valid_21626773, JString, required = false,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "X-Amz-Algorithm", valid_21626773
  var valid_21626774 = header.getOrDefault("X-Amz-Signature")
  valid_21626774 = validateParameter(valid_21626774, JString, required = false,
                                   default = nil)
  if valid_21626774 != nil:
    section.add "X-Amz-Signature", valid_21626774
  var valid_21626775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626775 = validateParameter(valid_21626775, JString, required = false,
                                   default = nil)
  if valid_21626775 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626775
  var valid_21626776 = header.getOrDefault("X-Amz-Credential")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "X-Amz-Credential", valid_21626776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626778: Call_ListBusinessReportSchedules_21626764;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the details of the schedules that a user configured. A download URL of the report associated with each schedule is returned every time this action is called. A new download URL is returned each time, and is valid for 24 hours.
  ## 
  let valid = call_21626778.validator(path, query, header, formData, body, _)
  let scheme = call_21626778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626778.makeUrl(scheme.get, call_21626778.host, call_21626778.base,
                               call_21626778.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626778, uri, valid, _)

proc call*(call_21626779: Call_ListBusinessReportSchedules_21626764;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listBusinessReportSchedules
  ## Lists the details of the schedules that a user configured. A download URL of the report associated with each schedule is returned every time this action is called. A new download URL is returned each time, and is valid for 24 hours.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626781 = newJObject()
  var body_21626782 = newJObject()
  add(query_21626781, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626782 = body
  add(query_21626781, "MaxResults", newJString(MaxResults))
  result = call_21626779.call(nil, query_21626781, nil, nil, body_21626782)

var listBusinessReportSchedules* = Call_ListBusinessReportSchedules_21626764(
    name: "listBusinessReportSchedules", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListBusinessReportSchedules",
    validator: validate_ListBusinessReportSchedules_21626765, base: "/",
    makeUrl: url_ListBusinessReportSchedules_21626766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConferenceProviders_21626786 = ref object of OpenApiRestCall_21625435
proc url_ListConferenceProviders_21626788(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConferenceProviders_21626787(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626789 = query.getOrDefault("NextToken")
  valid_21626789 = validateParameter(valid_21626789, JString, required = false,
                                   default = nil)
  if valid_21626789 != nil:
    section.add "NextToken", valid_21626789
  var valid_21626790 = query.getOrDefault("MaxResults")
  valid_21626790 = validateParameter(valid_21626790, JString, required = false,
                                   default = nil)
  if valid_21626790 != nil:
    section.add "MaxResults", valid_21626790
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
  var valid_21626791 = header.getOrDefault("X-Amz-Date")
  valid_21626791 = validateParameter(valid_21626791, JString, required = false,
                                   default = nil)
  if valid_21626791 != nil:
    section.add "X-Amz-Date", valid_21626791
  var valid_21626792 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626792 = validateParameter(valid_21626792, JString, required = false,
                                   default = nil)
  if valid_21626792 != nil:
    section.add "X-Amz-Security-Token", valid_21626792
  var valid_21626793 = header.getOrDefault("X-Amz-Target")
  valid_21626793 = validateParameter(valid_21626793, JString, required = true, default = newJString(
      "AlexaForBusiness.ListConferenceProviders"))
  if valid_21626793 != nil:
    section.add "X-Amz-Target", valid_21626793
  var valid_21626794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626794 = validateParameter(valid_21626794, JString, required = false,
                                   default = nil)
  if valid_21626794 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626794
  var valid_21626795 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "X-Amz-Algorithm", valid_21626795
  var valid_21626796 = header.getOrDefault("X-Amz-Signature")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-Signature", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-Credential")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-Credential", valid_21626798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626800: Call_ListConferenceProviders_21626786;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists conference providers under a specific AWS account.
  ## 
  let valid = call_21626800.validator(path, query, header, formData, body, _)
  let scheme = call_21626800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626800.makeUrl(scheme.get, call_21626800.host, call_21626800.base,
                               call_21626800.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626800, uri, valid, _)

proc call*(call_21626801: Call_ListConferenceProviders_21626786; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listConferenceProviders
  ## Lists conference providers under a specific AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626802 = newJObject()
  var body_21626803 = newJObject()
  add(query_21626802, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626803 = body
  add(query_21626802, "MaxResults", newJString(MaxResults))
  result = call_21626801.call(nil, query_21626802, nil, nil, body_21626803)

var listConferenceProviders* = Call_ListConferenceProviders_21626786(
    name: "listConferenceProviders", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListConferenceProviders",
    validator: validate_ListConferenceProviders_21626787, base: "/",
    makeUrl: url_ListConferenceProviders_21626788,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceEvents_21626804 = ref object of OpenApiRestCall_21625435
proc url_ListDeviceEvents_21626806(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeviceEvents_21626805(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626807 = query.getOrDefault("NextToken")
  valid_21626807 = validateParameter(valid_21626807, JString, required = false,
                                   default = nil)
  if valid_21626807 != nil:
    section.add "NextToken", valid_21626807
  var valid_21626808 = query.getOrDefault("MaxResults")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "MaxResults", valid_21626808
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
  var valid_21626809 = header.getOrDefault("X-Amz-Date")
  valid_21626809 = validateParameter(valid_21626809, JString, required = false,
                                   default = nil)
  if valid_21626809 != nil:
    section.add "X-Amz-Date", valid_21626809
  var valid_21626810 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626810 = validateParameter(valid_21626810, JString, required = false,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "X-Amz-Security-Token", valid_21626810
  var valid_21626811 = header.getOrDefault("X-Amz-Target")
  valid_21626811 = validateParameter(valid_21626811, JString, required = true, default = newJString(
      "AlexaForBusiness.ListDeviceEvents"))
  if valid_21626811 != nil:
    section.add "X-Amz-Target", valid_21626811
  var valid_21626812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626812
  var valid_21626813 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "X-Amz-Algorithm", valid_21626813
  var valid_21626814 = header.getOrDefault("X-Amz-Signature")
  valid_21626814 = validateParameter(valid_21626814, JString, required = false,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "X-Amz-Signature", valid_21626814
  var valid_21626815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626815 = validateParameter(valid_21626815, JString, required = false,
                                   default = nil)
  if valid_21626815 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626815
  var valid_21626816 = header.getOrDefault("X-Amz-Credential")
  valid_21626816 = validateParameter(valid_21626816, JString, required = false,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "X-Amz-Credential", valid_21626816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626818: Call_ListDeviceEvents_21626804; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the device event history, including device connection status, for up to 30 days.
  ## 
  let valid = call_21626818.validator(path, query, header, formData, body, _)
  let scheme = call_21626818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626818.makeUrl(scheme.get, call_21626818.host, call_21626818.base,
                               call_21626818.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626818, uri, valid, _)

proc call*(call_21626819: Call_ListDeviceEvents_21626804; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDeviceEvents
  ## Lists the device event history, including device connection status, for up to 30 days.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626820 = newJObject()
  var body_21626821 = newJObject()
  add(query_21626820, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626821 = body
  add(query_21626820, "MaxResults", newJString(MaxResults))
  result = call_21626819.call(nil, query_21626820, nil, nil, body_21626821)

var listDeviceEvents* = Call_ListDeviceEvents_21626804(name: "listDeviceEvents",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListDeviceEvents",
    validator: validate_ListDeviceEvents_21626805, base: "/",
    makeUrl: url_ListDeviceEvents_21626806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGatewayGroups_21626822 = ref object of OpenApiRestCall_21625435
proc url_ListGatewayGroups_21626824(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGatewayGroups_21626823(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626825 = query.getOrDefault("NextToken")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "NextToken", valid_21626825
  var valid_21626826 = query.getOrDefault("MaxResults")
  valid_21626826 = validateParameter(valid_21626826, JString, required = false,
                                   default = nil)
  if valid_21626826 != nil:
    section.add "MaxResults", valid_21626826
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
  var valid_21626827 = header.getOrDefault("X-Amz-Date")
  valid_21626827 = validateParameter(valid_21626827, JString, required = false,
                                   default = nil)
  if valid_21626827 != nil:
    section.add "X-Amz-Date", valid_21626827
  var valid_21626828 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626828 = validateParameter(valid_21626828, JString, required = false,
                                   default = nil)
  if valid_21626828 != nil:
    section.add "X-Amz-Security-Token", valid_21626828
  var valid_21626829 = header.getOrDefault("X-Amz-Target")
  valid_21626829 = validateParameter(valid_21626829, JString, required = true, default = newJString(
      "AlexaForBusiness.ListGatewayGroups"))
  if valid_21626829 != nil:
    section.add "X-Amz-Target", valid_21626829
  var valid_21626830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626830 = validateParameter(valid_21626830, JString, required = false,
                                   default = nil)
  if valid_21626830 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626830
  var valid_21626831 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626831 = validateParameter(valid_21626831, JString, required = false,
                                   default = nil)
  if valid_21626831 != nil:
    section.add "X-Amz-Algorithm", valid_21626831
  var valid_21626832 = header.getOrDefault("X-Amz-Signature")
  valid_21626832 = validateParameter(valid_21626832, JString, required = false,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "X-Amz-Signature", valid_21626832
  var valid_21626833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626833 = validateParameter(valid_21626833, JString, required = false,
                                   default = nil)
  if valid_21626833 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626833
  var valid_21626834 = header.getOrDefault("X-Amz-Credential")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-Credential", valid_21626834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626836: Call_ListGatewayGroups_21626822; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
  ## 
  let valid = call_21626836.validator(path, query, header, formData, body, _)
  let scheme = call_21626836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626836.makeUrl(scheme.get, call_21626836.host, call_21626836.base,
                               call_21626836.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626836, uri, valid, _)

proc call*(call_21626837: Call_ListGatewayGroups_21626822; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listGatewayGroups
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626838 = newJObject()
  var body_21626839 = newJObject()
  add(query_21626838, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626839 = body
  add(query_21626838, "MaxResults", newJString(MaxResults))
  result = call_21626837.call(nil, query_21626838, nil, nil, body_21626839)

var listGatewayGroups* = Call_ListGatewayGroups_21626822(name: "listGatewayGroups",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListGatewayGroups",
    validator: validate_ListGatewayGroups_21626823, base: "/",
    makeUrl: url_ListGatewayGroups_21626824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGateways_21626840 = ref object of OpenApiRestCall_21625435
proc url_ListGateways_21626842(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGateways_21626841(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626843 = query.getOrDefault("NextToken")
  valid_21626843 = validateParameter(valid_21626843, JString, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "NextToken", valid_21626843
  var valid_21626844 = query.getOrDefault("MaxResults")
  valid_21626844 = validateParameter(valid_21626844, JString, required = false,
                                   default = nil)
  if valid_21626844 != nil:
    section.add "MaxResults", valid_21626844
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
  var valid_21626845 = header.getOrDefault("X-Amz-Date")
  valid_21626845 = validateParameter(valid_21626845, JString, required = false,
                                   default = nil)
  if valid_21626845 != nil:
    section.add "X-Amz-Date", valid_21626845
  var valid_21626846 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626846 = validateParameter(valid_21626846, JString, required = false,
                                   default = nil)
  if valid_21626846 != nil:
    section.add "X-Amz-Security-Token", valid_21626846
  var valid_21626847 = header.getOrDefault("X-Amz-Target")
  valid_21626847 = validateParameter(valid_21626847, JString, required = true, default = newJString(
      "AlexaForBusiness.ListGateways"))
  if valid_21626847 != nil:
    section.add "X-Amz-Target", valid_21626847
  var valid_21626848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626848 = validateParameter(valid_21626848, JString, required = false,
                                   default = nil)
  if valid_21626848 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626848
  var valid_21626849 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626849 = validateParameter(valid_21626849, JString, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "X-Amz-Algorithm", valid_21626849
  var valid_21626850 = header.getOrDefault("X-Amz-Signature")
  valid_21626850 = validateParameter(valid_21626850, JString, required = false,
                                   default = nil)
  if valid_21626850 != nil:
    section.add "X-Amz-Signature", valid_21626850
  var valid_21626851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626851 = validateParameter(valid_21626851, JString, required = false,
                                   default = nil)
  if valid_21626851 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626851
  var valid_21626852 = header.getOrDefault("X-Amz-Credential")
  valid_21626852 = validateParameter(valid_21626852, JString, required = false,
                                   default = nil)
  if valid_21626852 != nil:
    section.add "X-Amz-Credential", valid_21626852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626854: Call_ListGateways_21626840; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
  ## 
  let valid = call_21626854.validator(path, query, header, formData, body, _)
  let scheme = call_21626854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626854.makeUrl(scheme.get, call_21626854.host, call_21626854.base,
                               call_21626854.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626854, uri, valid, _)

proc call*(call_21626855: Call_ListGateways_21626840; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listGateways
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626856 = newJObject()
  var body_21626857 = newJObject()
  add(query_21626856, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626857 = body
  add(query_21626856, "MaxResults", newJString(MaxResults))
  result = call_21626855.call(nil, query_21626856, nil, nil, body_21626857)

var listGateways* = Call_ListGateways_21626840(name: "listGateways",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListGateways",
    validator: validate_ListGateways_21626841, base: "/", makeUrl: url_ListGateways_21626842,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkills_21626858 = ref object of OpenApiRestCall_21625435
proc url_ListSkills_21626860(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSkills_21626859(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626861 = query.getOrDefault("NextToken")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "NextToken", valid_21626861
  var valid_21626862 = query.getOrDefault("MaxResults")
  valid_21626862 = validateParameter(valid_21626862, JString, required = false,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "MaxResults", valid_21626862
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
  var valid_21626863 = header.getOrDefault("X-Amz-Date")
  valid_21626863 = validateParameter(valid_21626863, JString, required = false,
                                   default = nil)
  if valid_21626863 != nil:
    section.add "X-Amz-Date", valid_21626863
  var valid_21626864 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626864 = validateParameter(valid_21626864, JString, required = false,
                                   default = nil)
  if valid_21626864 != nil:
    section.add "X-Amz-Security-Token", valid_21626864
  var valid_21626865 = header.getOrDefault("X-Amz-Target")
  valid_21626865 = validateParameter(valid_21626865, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkills"))
  if valid_21626865 != nil:
    section.add "X-Amz-Target", valid_21626865
  var valid_21626866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626866 = validateParameter(valid_21626866, JString, required = false,
                                   default = nil)
  if valid_21626866 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626866
  var valid_21626867 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626867 = validateParameter(valid_21626867, JString, required = false,
                                   default = nil)
  if valid_21626867 != nil:
    section.add "X-Amz-Algorithm", valid_21626867
  var valid_21626868 = header.getOrDefault("X-Amz-Signature")
  valid_21626868 = validateParameter(valid_21626868, JString, required = false,
                                   default = nil)
  if valid_21626868 != nil:
    section.add "X-Amz-Signature", valid_21626868
  var valid_21626869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626869 = validateParameter(valid_21626869, JString, required = false,
                                   default = nil)
  if valid_21626869 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626869
  var valid_21626870 = header.getOrDefault("X-Amz-Credential")
  valid_21626870 = validateParameter(valid_21626870, JString, required = false,
                                   default = nil)
  if valid_21626870 != nil:
    section.add "X-Amz-Credential", valid_21626870
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626872: Call_ListSkills_21626858; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all enabled skills in a specific skill group.
  ## 
  let valid = call_21626872.validator(path, query, header, formData, body, _)
  let scheme = call_21626872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626872.makeUrl(scheme.get, call_21626872.host, call_21626872.base,
                               call_21626872.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626872, uri, valid, _)

proc call*(call_21626873: Call_ListSkills_21626858; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSkills
  ## Lists all enabled skills in a specific skill group.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626874 = newJObject()
  var body_21626875 = newJObject()
  add(query_21626874, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626875 = body
  add(query_21626874, "MaxResults", newJString(MaxResults))
  result = call_21626873.call(nil, query_21626874, nil, nil, body_21626875)

var listSkills* = Call_ListSkills_21626858(name: "listSkills",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ListSkills",
                                        validator: validate_ListSkills_21626859,
                                        base: "/", makeUrl: url_ListSkills_21626860,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkillsStoreCategories_21626876 = ref object of OpenApiRestCall_21625435
proc url_ListSkillsStoreCategories_21626878(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSkillsStoreCategories_21626877(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626879 = query.getOrDefault("NextToken")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "NextToken", valid_21626879
  var valid_21626880 = query.getOrDefault("MaxResults")
  valid_21626880 = validateParameter(valid_21626880, JString, required = false,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "MaxResults", valid_21626880
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
  var valid_21626881 = header.getOrDefault("X-Amz-Date")
  valid_21626881 = validateParameter(valid_21626881, JString, required = false,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "X-Amz-Date", valid_21626881
  var valid_21626882 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626882 = validateParameter(valid_21626882, JString, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "X-Amz-Security-Token", valid_21626882
  var valid_21626883 = header.getOrDefault("X-Amz-Target")
  valid_21626883 = validateParameter(valid_21626883, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkillsStoreCategories"))
  if valid_21626883 != nil:
    section.add "X-Amz-Target", valid_21626883
  var valid_21626884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626884 = validateParameter(valid_21626884, JString, required = false,
                                   default = nil)
  if valid_21626884 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626884
  var valid_21626885 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626885 = validateParameter(valid_21626885, JString, required = false,
                                   default = nil)
  if valid_21626885 != nil:
    section.add "X-Amz-Algorithm", valid_21626885
  var valid_21626886 = header.getOrDefault("X-Amz-Signature")
  valid_21626886 = validateParameter(valid_21626886, JString, required = false,
                                   default = nil)
  if valid_21626886 != nil:
    section.add "X-Amz-Signature", valid_21626886
  var valid_21626887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626887 = validateParameter(valid_21626887, JString, required = false,
                                   default = nil)
  if valid_21626887 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626887
  var valid_21626888 = header.getOrDefault("X-Amz-Credential")
  valid_21626888 = validateParameter(valid_21626888, JString, required = false,
                                   default = nil)
  if valid_21626888 != nil:
    section.add "X-Amz-Credential", valid_21626888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626890: Call_ListSkillsStoreCategories_21626876;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all categories in the Alexa skill store.
  ## 
  let valid = call_21626890.validator(path, query, header, formData, body, _)
  let scheme = call_21626890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626890.makeUrl(scheme.get, call_21626890.host, call_21626890.base,
                               call_21626890.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626890, uri, valid, _)

proc call*(call_21626891: Call_ListSkillsStoreCategories_21626876; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSkillsStoreCategories
  ## Lists all categories in the Alexa skill store.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626892 = newJObject()
  var body_21626893 = newJObject()
  add(query_21626892, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626893 = body
  add(query_21626892, "MaxResults", newJString(MaxResults))
  result = call_21626891.call(nil, query_21626892, nil, nil, body_21626893)

var listSkillsStoreCategories* = Call_ListSkillsStoreCategories_21626876(
    name: "listSkillsStoreCategories", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSkillsStoreCategories",
    validator: validate_ListSkillsStoreCategories_21626877, base: "/",
    makeUrl: url_ListSkillsStoreCategories_21626878,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkillsStoreSkillsByCategory_21626894 = ref object of OpenApiRestCall_21625435
proc url_ListSkillsStoreSkillsByCategory_21626896(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSkillsStoreSkillsByCategory_21626895(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626897 = query.getOrDefault("NextToken")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "NextToken", valid_21626897
  var valid_21626898 = query.getOrDefault("MaxResults")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "MaxResults", valid_21626898
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
  var valid_21626899 = header.getOrDefault("X-Amz-Date")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-Date", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-Security-Token", valid_21626900
  var valid_21626901 = header.getOrDefault("X-Amz-Target")
  valid_21626901 = validateParameter(valid_21626901, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkillsStoreSkillsByCategory"))
  if valid_21626901 != nil:
    section.add "X-Amz-Target", valid_21626901
  var valid_21626902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626902
  var valid_21626903 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626903 = validateParameter(valid_21626903, JString, required = false,
                                   default = nil)
  if valid_21626903 != nil:
    section.add "X-Amz-Algorithm", valid_21626903
  var valid_21626904 = header.getOrDefault("X-Amz-Signature")
  valid_21626904 = validateParameter(valid_21626904, JString, required = false,
                                   default = nil)
  if valid_21626904 != nil:
    section.add "X-Amz-Signature", valid_21626904
  var valid_21626905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626905 = validateParameter(valid_21626905, JString, required = false,
                                   default = nil)
  if valid_21626905 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626905
  var valid_21626906 = header.getOrDefault("X-Amz-Credential")
  valid_21626906 = validateParameter(valid_21626906, JString, required = false,
                                   default = nil)
  if valid_21626906 != nil:
    section.add "X-Amz-Credential", valid_21626906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626908: Call_ListSkillsStoreSkillsByCategory_21626894;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all skills in the Alexa skill store by category.
  ## 
  let valid = call_21626908.validator(path, query, header, formData, body, _)
  let scheme = call_21626908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626908.makeUrl(scheme.get, call_21626908.host, call_21626908.base,
                               call_21626908.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626908, uri, valid, _)

proc call*(call_21626909: Call_ListSkillsStoreSkillsByCategory_21626894;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSkillsStoreSkillsByCategory
  ## Lists all skills in the Alexa skill store by category.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626910 = newJObject()
  var body_21626911 = newJObject()
  add(query_21626910, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626911 = body
  add(query_21626910, "MaxResults", newJString(MaxResults))
  result = call_21626909.call(nil, query_21626910, nil, nil, body_21626911)

var listSkillsStoreSkillsByCategory* = Call_ListSkillsStoreSkillsByCategory_21626894(
    name: "listSkillsStoreSkillsByCategory", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSkillsStoreSkillsByCategory",
    validator: validate_ListSkillsStoreSkillsByCategory_21626895, base: "/",
    makeUrl: url_ListSkillsStoreSkillsByCategory_21626896,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSmartHomeAppliances_21626912 = ref object of OpenApiRestCall_21625435
proc url_ListSmartHomeAppliances_21626914(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSmartHomeAppliances_21626913(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626915 = query.getOrDefault("NextToken")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "NextToken", valid_21626915
  var valid_21626916 = query.getOrDefault("MaxResults")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "MaxResults", valid_21626916
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
  var valid_21626917 = header.getOrDefault("X-Amz-Date")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "X-Amz-Date", valid_21626917
  var valid_21626918 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "X-Amz-Security-Token", valid_21626918
  var valid_21626919 = header.getOrDefault("X-Amz-Target")
  valid_21626919 = validateParameter(valid_21626919, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSmartHomeAppliances"))
  if valid_21626919 != nil:
    section.add "X-Amz-Target", valid_21626919
  var valid_21626920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626920 = validateParameter(valid_21626920, JString, required = false,
                                   default = nil)
  if valid_21626920 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626920
  var valid_21626921 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626921 = validateParameter(valid_21626921, JString, required = false,
                                   default = nil)
  if valid_21626921 != nil:
    section.add "X-Amz-Algorithm", valid_21626921
  var valid_21626922 = header.getOrDefault("X-Amz-Signature")
  valid_21626922 = validateParameter(valid_21626922, JString, required = false,
                                   default = nil)
  if valid_21626922 != nil:
    section.add "X-Amz-Signature", valid_21626922
  var valid_21626923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626923 = validateParameter(valid_21626923, JString, required = false,
                                   default = nil)
  if valid_21626923 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626923
  var valid_21626924 = header.getOrDefault("X-Amz-Credential")
  valid_21626924 = validateParameter(valid_21626924, JString, required = false,
                                   default = nil)
  if valid_21626924 != nil:
    section.add "X-Amz-Credential", valid_21626924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626926: Call_ListSmartHomeAppliances_21626912;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all of the smart home appliances associated with a room.
  ## 
  let valid = call_21626926.validator(path, query, header, formData, body, _)
  let scheme = call_21626926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626926.makeUrl(scheme.get, call_21626926.host, call_21626926.base,
                               call_21626926.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626926, uri, valid, _)

proc call*(call_21626927: Call_ListSmartHomeAppliances_21626912; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSmartHomeAppliances
  ## Lists all of the smart home appliances associated with a room.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626928 = newJObject()
  var body_21626929 = newJObject()
  add(query_21626928, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626929 = body
  add(query_21626928, "MaxResults", newJString(MaxResults))
  result = call_21626927.call(nil, query_21626928, nil, nil, body_21626929)

var listSmartHomeAppliances* = Call_ListSmartHomeAppliances_21626912(
    name: "listSmartHomeAppliances", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSmartHomeAppliances",
    validator: validate_ListSmartHomeAppliances_21626913, base: "/",
    makeUrl: url_ListSmartHomeAppliances_21626914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_21626930 = ref object of OpenApiRestCall_21625435
proc url_ListTags_21626932(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTags_21626931(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626933 = query.getOrDefault("NextToken")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "NextToken", valid_21626933
  var valid_21626934 = query.getOrDefault("MaxResults")
  valid_21626934 = validateParameter(valid_21626934, JString, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "MaxResults", valid_21626934
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
  var valid_21626935 = header.getOrDefault("X-Amz-Date")
  valid_21626935 = validateParameter(valid_21626935, JString, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "X-Amz-Date", valid_21626935
  var valid_21626936 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626936 = validateParameter(valid_21626936, JString, required = false,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "X-Amz-Security-Token", valid_21626936
  var valid_21626937 = header.getOrDefault("X-Amz-Target")
  valid_21626937 = validateParameter(valid_21626937, JString, required = true, default = newJString(
      "AlexaForBusiness.ListTags"))
  if valid_21626937 != nil:
    section.add "X-Amz-Target", valid_21626937
  var valid_21626938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626938 = validateParameter(valid_21626938, JString, required = false,
                                   default = nil)
  if valid_21626938 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626938
  var valid_21626939 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626939 = validateParameter(valid_21626939, JString, required = false,
                                   default = nil)
  if valid_21626939 != nil:
    section.add "X-Amz-Algorithm", valid_21626939
  var valid_21626940 = header.getOrDefault("X-Amz-Signature")
  valid_21626940 = validateParameter(valid_21626940, JString, required = false,
                                   default = nil)
  if valid_21626940 != nil:
    section.add "X-Amz-Signature", valid_21626940
  var valid_21626941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626941 = validateParameter(valid_21626941, JString, required = false,
                                   default = nil)
  if valid_21626941 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626941
  var valid_21626942 = header.getOrDefault("X-Amz-Credential")
  valid_21626942 = validateParameter(valid_21626942, JString, required = false,
                                   default = nil)
  if valid_21626942 != nil:
    section.add "X-Amz-Credential", valid_21626942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626944: Call_ListTags_21626930; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all tags for the specified resource.
  ## 
  let valid = call_21626944.validator(path, query, header, formData, body, _)
  let scheme = call_21626944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626944.makeUrl(scheme.get, call_21626944.host, call_21626944.base,
                               call_21626944.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626944, uri, valid, _)

proc call*(call_21626945: Call_ListTags_21626930; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTags
  ## Lists all tags for the specified resource.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626946 = newJObject()
  var body_21626947 = newJObject()
  add(query_21626946, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626947 = body
  add(query_21626946, "MaxResults", newJString(MaxResults))
  result = call_21626945.call(nil, query_21626946, nil, nil, body_21626947)

var listTags* = Call_ListTags_21626930(name: "listTags", meth: HttpMethod.HttpPost,
                                    host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ListTags",
                                    validator: validate_ListTags_21626931,
                                    base: "/", makeUrl: url_ListTags_21626932,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConferencePreference_21626948 = ref object of OpenApiRestCall_21625435
proc url_PutConferencePreference_21626950(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutConferencePreference_21626949(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626951 = header.getOrDefault("X-Amz-Date")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-Date", valid_21626951
  var valid_21626952 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626952 = validateParameter(valid_21626952, JString, required = false,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "X-Amz-Security-Token", valid_21626952
  var valid_21626953 = header.getOrDefault("X-Amz-Target")
  valid_21626953 = validateParameter(valid_21626953, JString, required = true, default = newJString(
      "AlexaForBusiness.PutConferencePreference"))
  if valid_21626953 != nil:
    section.add "X-Amz-Target", valid_21626953
  var valid_21626954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626954 = validateParameter(valid_21626954, JString, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626954
  var valid_21626955 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626955 = validateParameter(valid_21626955, JString, required = false,
                                   default = nil)
  if valid_21626955 != nil:
    section.add "X-Amz-Algorithm", valid_21626955
  var valid_21626956 = header.getOrDefault("X-Amz-Signature")
  valid_21626956 = validateParameter(valid_21626956, JString, required = false,
                                   default = nil)
  if valid_21626956 != nil:
    section.add "X-Amz-Signature", valid_21626956
  var valid_21626957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626957 = validateParameter(valid_21626957, JString, required = false,
                                   default = nil)
  if valid_21626957 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626957
  var valid_21626958 = header.getOrDefault("X-Amz-Credential")
  valid_21626958 = validateParameter(valid_21626958, JString, required = false,
                                   default = nil)
  if valid_21626958 != nil:
    section.add "X-Amz-Credential", valid_21626958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626960: Call_PutConferencePreference_21626948;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the conference preferences on a specific conference provider at the account level.
  ## 
  let valid = call_21626960.validator(path, query, header, formData, body, _)
  let scheme = call_21626960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626960.makeUrl(scheme.get, call_21626960.host, call_21626960.base,
                               call_21626960.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626960, uri, valid, _)

proc call*(call_21626961: Call_PutConferencePreference_21626948; body: JsonNode): Recallable =
  ## putConferencePreference
  ## Sets the conference preferences on a specific conference provider at the account level.
  ##   body: JObject (required)
  var body_21626962 = newJObject()
  if body != nil:
    body_21626962 = body
  result = call_21626961.call(nil, nil, nil, nil, body_21626962)

var putConferencePreference* = Call_PutConferencePreference_21626948(
    name: "putConferencePreference", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutConferencePreference",
    validator: validate_PutConferencePreference_21626949, base: "/",
    makeUrl: url_PutConferencePreference_21626950,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInvitationConfiguration_21626963 = ref object of OpenApiRestCall_21625435
proc url_PutInvitationConfiguration_21626965(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutInvitationConfiguration_21626964(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626966 = header.getOrDefault("X-Amz-Date")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "X-Amz-Date", valid_21626966
  var valid_21626967 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626967 = validateParameter(valid_21626967, JString, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "X-Amz-Security-Token", valid_21626967
  var valid_21626968 = header.getOrDefault("X-Amz-Target")
  valid_21626968 = validateParameter(valid_21626968, JString, required = true, default = newJString(
      "AlexaForBusiness.PutInvitationConfiguration"))
  if valid_21626968 != nil:
    section.add "X-Amz-Target", valid_21626968
  var valid_21626969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626969 = validateParameter(valid_21626969, JString, required = false,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626969
  var valid_21626970 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626970 = validateParameter(valid_21626970, JString, required = false,
                                   default = nil)
  if valid_21626970 != nil:
    section.add "X-Amz-Algorithm", valid_21626970
  var valid_21626971 = header.getOrDefault("X-Amz-Signature")
  valid_21626971 = validateParameter(valid_21626971, JString, required = false,
                                   default = nil)
  if valid_21626971 != nil:
    section.add "X-Amz-Signature", valid_21626971
  var valid_21626972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626972 = validateParameter(valid_21626972, JString, required = false,
                                   default = nil)
  if valid_21626972 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626972
  var valid_21626973 = header.getOrDefault("X-Amz-Credential")
  valid_21626973 = validateParameter(valid_21626973, JString, required = false,
                                   default = nil)
  if valid_21626973 != nil:
    section.add "X-Amz-Credential", valid_21626973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626975: Call_PutInvitationConfiguration_21626963;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures the email template for the user enrollment invitation with the specified attributes.
  ## 
  let valid = call_21626975.validator(path, query, header, formData, body, _)
  let scheme = call_21626975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626975.makeUrl(scheme.get, call_21626975.host, call_21626975.base,
                               call_21626975.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626975, uri, valid, _)

proc call*(call_21626976: Call_PutInvitationConfiguration_21626963; body: JsonNode): Recallable =
  ## putInvitationConfiguration
  ## Configures the email template for the user enrollment invitation with the specified attributes.
  ##   body: JObject (required)
  var body_21626977 = newJObject()
  if body != nil:
    body_21626977 = body
  result = call_21626976.call(nil, nil, nil, nil, body_21626977)

var putInvitationConfiguration* = Call_PutInvitationConfiguration_21626963(
    name: "putInvitationConfiguration", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutInvitationConfiguration",
    validator: validate_PutInvitationConfiguration_21626964, base: "/",
    makeUrl: url_PutInvitationConfiguration_21626965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRoomSkillParameter_21626978 = ref object of OpenApiRestCall_21625435
proc url_PutRoomSkillParameter_21626980(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRoomSkillParameter_21626979(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626981 = header.getOrDefault("X-Amz-Date")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-Date", valid_21626981
  var valid_21626982 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626982 = validateParameter(valid_21626982, JString, required = false,
                                   default = nil)
  if valid_21626982 != nil:
    section.add "X-Amz-Security-Token", valid_21626982
  var valid_21626983 = header.getOrDefault("X-Amz-Target")
  valid_21626983 = validateParameter(valid_21626983, JString, required = true, default = newJString(
      "AlexaForBusiness.PutRoomSkillParameter"))
  if valid_21626983 != nil:
    section.add "X-Amz-Target", valid_21626983
  var valid_21626984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626984 = validateParameter(valid_21626984, JString, required = false,
                                   default = nil)
  if valid_21626984 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626984
  var valid_21626985 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626985 = validateParameter(valid_21626985, JString, required = false,
                                   default = nil)
  if valid_21626985 != nil:
    section.add "X-Amz-Algorithm", valid_21626985
  var valid_21626986 = header.getOrDefault("X-Amz-Signature")
  valid_21626986 = validateParameter(valid_21626986, JString, required = false,
                                   default = nil)
  if valid_21626986 != nil:
    section.add "X-Amz-Signature", valid_21626986
  var valid_21626987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626987 = validateParameter(valid_21626987, JString, required = false,
                                   default = nil)
  if valid_21626987 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626987
  var valid_21626988 = header.getOrDefault("X-Amz-Credential")
  valid_21626988 = validateParameter(valid_21626988, JString, required = false,
                                   default = nil)
  if valid_21626988 != nil:
    section.add "X-Amz-Credential", valid_21626988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626990: Call_PutRoomSkillParameter_21626978;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates room skill parameter details by room, skill, and parameter key ID. Not all skills have a room skill parameter.
  ## 
  let valid = call_21626990.validator(path, query, header, formData, body, _)
  let scheme = call_21626990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626990.makeUrl(scheme.get, call_21626990.host, call_21626990.base,
                               call_21626990.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626990, uri, valid, _)

proc call*(call_21626991: Call_PutRoomSkillParameter_21626978; body: JsonNode): Recallable =
  ## putRoomSkillParameter
  ## Updates room skill parameter details by room, skill, and parameter key ID. Not all skills have a room skill parameter.
  ##   body: JObject (required)
  var body_21626992 = newJObject()
  if body != nil:
    body_21626992 = body
  result = call_21626991.call(nil, nil, nil, nil, body_21626992)

var putRoomSkillParameter* = Call_PutRoomSkillParameter_21626978(
    name: "putRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutRoomSkillParameter",
    validator: validate_PutRoomSkillParameter_21626979, base: "/",
    makeUrl: url_PutRoomSkillParameter_21626980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSkillAuthorization_21626993 = ref object of OpenApiRestCall_21625435
proc url_PutSkillAuthorization_21626995(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutSkillAuthorization_21626994(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626996 = header.getOrDefault("X-Amz-Date")
  valid_21626996 = validateParameter(valid_21626996, JString, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "X-Amz-Date", valid_21626996
  var valid_21626997 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626997 = validateParameter(valid_21626997, JString, required = false,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "X-Amz-Security-Token", valid_21626997
  var valid_21626998 = header.getOrDefault("X-Amz-Target")
  valid_21626998 = validateParameter(valid_21626998, JString, required = true, default = newJString(
      "AlexaForBusiness.PutSkillAuthorization"))
  if valid_21626998 != nil:
    section.add "X-Amz-Target", valid_21626998
  var valid_21626999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626999 = validateParameter(valid_21626999, JString, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626999
  var valid_21627000 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627000 = validateParameter(valid_21627000, JString, required = false,
                                   default = nil)
  if valid_21627000 != nil:
    section.add "X-Amz-Algorithm", valid_21627000
  var valid_21627001 = header.getOrDefault("X-Amz-Signature")
  valid_21627001 = validateParameter(valid_21627001, JString, required = false,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "X-Amz-Signature", valid_21627001
  var valid_21627002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627002 = validateParameter(valid_21627002, JString, required = false,
                                   default = nil)
  if valid_21627002 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627002
  var valid_21627003 = header.getOrDefault("X-Amz-Credential")
  valid_21627003 = validateParameter(valid_21627003, JString, required = false,
                                   default = nil)
  if valid_21627003 != nil:
    section.add "X-Amz-Credential", valid_21627003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627005: Call_PutSkillAuthorization_21626993;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Links a user's account to a third-party skill provider. If this API operation is called by an assumed IAM role, the skill being linked must be a private skill. Also, the skill must be owned by the AWS account that assumed the IAM role.
  ## 
  let valid = call_21627005.validator(path, query, header, formData, body, _)
  let scheme = call_21627005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627005.makeUrl(scheme.get, call_21627005.host, call_21627005.base,
                               call_21627005.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627005, uri, valid, _)

proc call*(call_21627006: Call_PutSkillAuthorization_21626993; body: JsonNode): Recallable =
  ## putSkillAuthorization
  ## Links a user's account to a third-party skill provider. If this API operation is called by an assumed IAM role, the skill being linked must be a private skill. Also, the skill must be owned by the AWS account that assumed the IAM role.
  ##   body: JObject (required)
  var body_21627007 = newJObject()
  if body != nil:
    body_21627007 = body
  result = call_21627006.call(nil, nil, nil, nil, body_21627007)

var putSkillAuthorization* = Call_PutSkillAuthorization_21626993(
    name: "putSkillAuthorization", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutSkillAuthorization",
    validator: validate_PutSkillAuthorization_21626994, base: "/",
    makeUrl: url_PutSkillAuthorization_21626995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterAVSDevice_21627008 = ref object of OpenApiRestCall_21625435
proc url_RegisterAVSDevice_21627010(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterAVSDevice_21627009(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627011 = header.getOrDefault("X-Amz-Date")
  valid_21627011 = validateParameter(valid_21627011, JString, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "X-Amz-Date", valid_21627011
  var valid_21627012 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627012 = validateParameter(valid_21627012, JString, required = false,
                                   default = nil)
  if valid_21627012 != nil:
    section.add "X-Amz-Security-Token", valid_21627012
  var valid_21627013 = header.getOrDefault("X-Amz-Target")
  valid_21627013 = validateParameter(valid_21627013, JString, required = true, default = newJString(
      "AlexaForBusiness.RegisterAVSDevice"))
  if valid_21627013 != nil:
    section.add "X-Amz-Target", valid_21627013
  var valid_21627014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627014 = validateParameter(valid_21627014, JString, required = false,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627014
  var valid_21627015 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627015 = validateParameter(valid_21627015, JString, required = false,
                                   default = nil)
  if valid_21627015 != nil:
    section.add "X-Amz-Algorithm", valid_21627015
  var valid_21627016 = header.getOrDefault("X-Amz-Signature")
  valid_21627016 = validateParameter(valid_21627016, JString, required = false,
                                   default = nil)
  if valid_21627016 != nil:
    section.add "X-Amz-Signature", valid_21627016
  var valid_21627017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627017 = validateParameter(valid_21627017, JString, required = false,
                                   default = nil)
  if valid_21627017 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627017
  var valid_21627018 = header.getOrDefault("X-Amz-Credential")
  valid_21627018 = validateParameter(valid_21627018, JString, required = false,
                                   default = nil)
  if valid_21627018 != nil:
    section.add "X-Amz-Credential", valid_21627018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627020: Call_RegisterAVSDevice_21627008; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Registers an Alexa-enabled device built by an Original Equipment Manufacturer (OEM) using Alexa Voice Service (AVS).
  ## 
  let valid = call_21627020.validator(path, query, header, formData, body, _)
  let scheme = call_21627020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627020.makeUrl(scheme.get, call_21627020.host, call_21627020.base,
                               call_21627020.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627020, uri, valid, _)

proc call*(call_21627021: Call_RegisterAVSDevice_21627008; body: JsonNode): Recallable =
  ## registerAVSDevice
  ## Registers an Alexa-enabled device built by an Original Equipment Manufacturer (OEM) using Alexa Voice Service (AVS).
  ##   body: JObject (required)
  var body_21627022 = newJObject()
  if body != nil:
    body_21627022 = body
  result = call_21627021.call(nil, nil, nil, nil, body_21627022)

var registerAVSDevice* = Call_RegisterAVSDevice_21627008(name: "registerAVSDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.RegisterAVSDevice",
    validator: validate_RegisterAVSDevice_21627009, base: "/",
    makeUrl: url_RegisterAVSDevice_21627010, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectSkill_21627023 = ref object of OpenApiRestCall_21625435
proc url_RejectSkill_21627025(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RejectSkill_21627024(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627026 = header.getOrDefault("X-Amz-Date")
  valid_21627026 = validateParameter(valid_21627026, JString, required = false,
                                   default = nil)
  if valid_21627026 != nil:
    section.add "X-Amz-Date", valid_21627026
  var valid_21627027 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627027 = validateParameter(valid_21627027, JString, required = false,
                                   default = nil)
  if valid_21627027 != nil:
    section.add "X-Amz-Security-Token", valid_21627027
  var valid_21627028 = header.getOrDefault("X-Amz-Target")
  valid_21627028 = validateParameter(valid_21627028, JString, required = true, default = newJString(
      "AlexaForBusiness.RejectSkill"))
  if valid_21627028 != nil:
    section.add "X-Amz-Target", valid_21627028
  var valid_21627029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627029 = validateParameter(valid_21627029, JString, required = false,
                                   default = nil)
  if valid_21627029 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627029
  var valid_21627030 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627030 = validateParameter(valid_21627030, JString, required = false,
                                   default = nil)
  if valid_21627030 != nil:
    section.add "X-Amz-Algorithm", valid_21627030
  var valid_21627031 = header.getOrDefault("X-Amz-Signature")
  valid_21627031 = validateParameter(valid_21627031, JString, required = false,
                                   default = nil)
  if valid_21627031 != nil:
    section.add "X-Amz-Signature", valid_21627031
  var valid_21627032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627032 = validateParameter(valid_21627032, JString, required = false,
                                   default = nil)
  if valid_21627032 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627032
  var valid_21627033 = header.getOrDefault("X-Amz-Credential")
  valid_21627033 = validateParameter(valid_21627033, JString, required = false,
                                   default = nil)
  if valid_21627033 != nil:
    section.add "X-Amz-Credential", valid_21627033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627035: Call_RejectSkill_21627023; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates a skill from the organization under a user's AWS account. If the skill is a private skill, it moves to an AcceptStatus of PENDING. Any private or public skill that is rejected can be added later by calling the ApproveSkill API. 
  ## 
  let valid = call_21627035.validator(path, query, header, formData, body, _)
  let scheme = call_21627035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627035.makeUrl(scheme.get, call_21627035.host, call_21627035.base,
                               call_21627035.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627035, uri, valid, _)

proc call*(call_21627036: Call_RejectSkill_21627023; body: JsonNode): Recallable =
  ## rejectSkill
  ## Disassociates a skill from the organization under a user's AWS account. If the skill is a private skill, it moves to an AcceptStatus of PENDING. Any private or public skill that is rejected can be added later by calling the ApproveSkill API. 
  ##   body: JObject (required)
  var body_21627037 = newJObject()
  if body != nil:
    body_21627037 = body
  result = call_21627036.call(nil, nil, nil, nil, body_21627037)

var rejectSkill* = Call_RejectSkill_21627023(name: "rejectSkill",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.RejectSkill",
    validator: validate_RejectSkill_21627024, base: "/", makeUrl: url_RejectSkill_21627025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResolveRoom_21627038 = ref object of OpenApiRestCall_21625435
proc url_ResolveRoom_21627040(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResolveRoom_21627039(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627041 = header.getOrDefault("X-Amz-Date")
  valid_21627041 = validateParameter(valid_21627041, JString, required = false,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "X-Amz-Date", valid_21627041
  var valid_21627042 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627042 = validateParameter(valid_21627042, JString, required = false,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "X-Amz-Security-Token", valid_21627042
  var valid_21627043 = header.getOrDefault("X-Amz-Target")
  valid_21627043 = validateParameter(valid_21627043, JString, required = true, default = newJString(
      "AlexaForBusiness.ResolveRoom"))
  if valid_21627043 != nil:
    section.add "X-Amz-Target", valid_21627043
  var valid_21627044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627044 = validateParameter(valid_21627044, JString, required = false,
                                   default = nil)
  if valid_21627044 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627044
  var valid_21627045 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627045 = validateParameter(valid_21627045, JString, required = false,
                                   default = nil)
  if valid_21627045 != nil:
    section.add "X-Amz-Algorithm", valid_21627045
  var valid_21627046 = header.getOrDefault("X-Amz-Signature")
  valid_21627046 = validateParameter(valid_21627046, JString, required = false,
                                   default = nil)
  if valid_21627046 != nil:
    section.add "X-Amz-Signature", valid_21627046
  var valid_21627047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627047 = validateParameter(valid_21627047, JString, required = false,
                                   default = nil)
  if valid_21627047 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627047
  var valid_21627048 = header.getOrDefault("X-Amz-Credential")
  valid_21627048 = validateParameter(valid_21627048, JString, required = false,
                                   default = nil)
  if valid_21627048 != nil:
    section.add "X-Amz-Credential", valid_21627048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627050: Call_ResolveRoom_21627038; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Determines the details for the room from which a skill request was invoked. This operation is used by skill developers.
  ## 
  let valid = call_21627050.validator(path, query, header, formData, body, _)
  let scheme = call_21627050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627050.makeUrl(scheme.get, call_21627050.host, call_21627050.base,
                               call_21627050.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627050, uri, valid, _)

proc call*(call_21627051: Call_ResolveRoom_21627038; body: JsonNode): Recallable =
  ## resolveRoom
  ## Determines the details for the room from which a skill request was invoked. This operation is used by skill developers.
  ##   body: JObject (required)
  var body_21627052 = newJObject()
  if body != nil:
    body_21627052 = body
  result = call_21627051.call(nil, nil, nil, nil, body_21627052)

var resolveRoom* = Call_ResolveRoom_21627038(name: "resolveRoom",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ResolveRoom",
    validator: validate_ResolveRoom_21627039, base: "/", makeUrl: url_ResolveRoom_21627040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeInvitation_21627053 = ref object of OpenApiRestCall_21625435
proc url_RevokeInvitation_21627055(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RevokeInvitation_21627054(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627056 = header.getOrDefault("X-Amz-Date")
  valid_21627056 = validateParameter(valid_21627056, JString, required = false,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "X-Amz-Date", valid_21627056
  var valid_21627057 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627057 = validateParameter(valid_21627057, JString, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "X-Amz-Security-Token", valid_21627057
  var valid_21627058 = header.getOrDefault("X-Amz-Target")
  valid_21627058 = validateParameter(valid_21627058, JString, required = true, default = newJString(
      "AlexaForBusiness.RevokeInvitation"))
  if valid_21627058 != nil:
    section.add "X-Amz-Target", valid_21627058
  var valid_21627059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627059 = validateParameter(valid_21627059, JString, required = false,
                                   default = nil)
  if valid_21627059 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627059
  var valid_21627060 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627060 = validateParameter(valid_21627060, JString, required = false,
                                   default = nil)
  if valid_21627060 != nil:
    section.add "X-Amz-Algorithm", valid_21627060
  var valid_21627061 = header.getOrDefault("X-Amz-Signature")
  valid_21627061 = validateParameter(valid_21627061, JString, required = false,
                                   default = nil)
  if valid_21627061 != nil:
    section.add "X-Amz-Signature", valid_21627061
  var valid_21627062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627062 = validateParameter(valid_21627062, JString, required = false,
                                   default = nil)
  if valid_21627062 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627062
  var valid_21627063 = header.getOrDefault("X-Amz-Credential")
  valid_21627063 = validateParameter(valid_21627063, JString, required = false,
                                   default = nil)
  if valid_21627063 != nil:
    section.add "X-Amz-Credential", valid_21627063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627065: Call_RevokeInvitation_21627053; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Revokes an invitation and invalidates the enrollment URL.
  ## 
  let valid = call_21627065.validator(path, query, header, formData, body, _)
  let scheme = call_21627065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627065.makeUrl(scheme.get, call_21627065.host, call_21627065.base,
                               call_21627065.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627065, uri, valid, _)

proc call*(call_21627066: Call_RevokeInvitation_21627053; body: JsonNode): Recallable =
  ## revokeInvitation
  ## Revokes an invitation and invalidates the enrollment URL.
  ##   body: JObject (required)
  var body_21627067 = newJObject()
  if body != nil:
    body_21627067 = body
  result = call_21627066.call(nil, nil, nil, nil, body_21627067)

var revokeInvitation* = Call_RevokeInvitation_21627053(name: "revokeInvitation",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.RevokeInvitation",
    validator: validate_RevokeInvitation_21627054, base: "/",
    makeUrl: url_RevokeInvitation_21627055, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAddressBooks_21627068 = ref object of OpenApiRestCall_21625435
proc url_SearchAddressBooks_21627070(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchAddressBooks_21627069(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627071 = query.getOrDefault("NextToken")
  valid_21627071 = validateParameter(valid_21627071, JString, required = false,
                                   default = nil)
  if valid_21627071 != nil:
    section.add "NextToken", valid_21627071
  var valid_21627072 = query.getOrDefault("MaxResults")
  valid_21627072 = validateParameter(valid_21627072, JString, required = false,
                                   default = nil)
  if valid_21627072 != nil:
    section.add "MaxResults", valid_21627072
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
  var valid_21627073 = header.getOrDefault("X-Amz-Date")
  valid_21627073 = validateParameter(valid_21627073, JString, required = false,
                                   default = nil)
  if valid_21627073 != nil:
    section.add "X-Amz-Date", valid_21627073
  var valid_21627074 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627074 = validateParameter(valid_21627074, JString, required = false,
                                   default = nil)
  if valid_21627074 != nil:
    section.add "X-Amz-Security-Token", valid_21627074
  var valid_21627075 = header.getOrDefault("X-Amz-Target")
  valid_21627075 = validateParameter(valid_21627075, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchAddressBooks"))
  if valid_21627075 != nil:
    section.add "X-Amz-Target", valid_21627075
  var valid_21627076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627076 = validateParameter(valid_21627076, JString, required = false,
                                   default = nil)
  if valid_21627076 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627076
  var valid_21627077 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627077 = validateParameter(valid_21627077, JString, required = false,
                                   default = nil)
  if valid_21627077 != nil:
    section.add "X-Amz-Algorithm", valid_21627077
  var valid_21627078 = header.getOrDefault("X-Amz-Signature")
  valid_21627078 = validateParameter(valid_21627078, JString, required = false,
                                   default = nil)
  if valid_21627078 != nil:
    section.add "X-Amz-Signature", valid_21627078
  var valid_21627079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627079 = validateParameter(valid_21627079, JString, required = false,
                                   default = nil)
  if valid_21627079 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627079
  var valid_21627080 = header.getOrDefault("X-Amz-Credential")
  valid_21627080 = validateParameter(valid_21627080, JString, required = false,
                                   default = nil)
  if valid_21627080 != nil:
    section.add "X-Amz-Credential", valid_21627080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627082: Call_SearchAddressBooks_21627068; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_21627082.validator(path, query, header, formData, body, _)
  let scheme = call_21627082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627082.makeUrl(scheme.get, call_21627082.host, call_21627082.base,
                               call_21627082.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627082, uri, valid, _)

proc call*(call_21627083: Call_SearchAddressBooks_21627068; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchAddressBooks
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627084 = newJObject()
  var body_21627085 = newJObject()
  add(query_21627084, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627085 = body
  add(query_21627084, "MaxResults", newJString(MaxResults))
  result = call_21627083.call(nil, query_21627084, nil, nil, body_21627085)

var searchAddressBooks* = Call_SearchAddressBooks_21627068(
    name: "searchAddressBooks", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchAddressBooks",
    validator: validate_SearchAddressBooks_21627069, base: "/",
    makeUrl: url_SearchAddressBooks_21627070, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchContacts_21627086 = ref object of OpenApiRestCall_21625435
proc url_SearchContacts_21627088(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchContacts_21627087(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627089 = query.getOrDefault("NextToken")
  valid_21627089 = validateParameter(valid_21627089, JString, required = false,
                                   default = nil)
  if valid_21627089 != nil:
    section.add "NextToken", valid_21627089
  var valid_21627090 = query.getOrDefault("MaxResults")
  valid_21627090 = validateParameter(valid_21627090, JString, required = false,
                                   default = nil)
  if valid_21627090 != nil:
    section.add "MaxResults", valid_21627090
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
  var valid_21627091 = header.getOrDefault("X-Amz-Date")
  valid_21627091 = validateParameter(valid_21627091, JString, required = false,
                                   default = nil)
  if valid_21627091 != nil:
    section.add "X-Amz-Date", valid_21627091
  var valid_21627092 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627092 = validateParameter(valid_21627092, JString, required = false,
                                   default = nil)
  if valid_21627092 != nil:
    section.add "X-Amz-Security-Token", valid_21627092
  var valid_21627093 = header.getOrDefault("X-Amz-Target")
  valid_21627093 = validateParameter(valid_21627093, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchContacts"))
  if valid_21627093 != nil:
    section.add "X-Amz-Target", valid_21627093
  var valid_21627094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627094 = validateParameter(valid_21627094, JString, required = false,
                                   default = nil)
  if valid_21627094 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627094
  var valid_21627095 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627095 = validateParameter(valid_21627095, JString, required = false,
                                   default = nil)
  if valid_21627095 != nil:
    section.add "X-Amz-Algorithm", valid_21627095
  var valid_21627096 = header.getOrDefault("X-Amz-Signature")
  valid_21627096 = validateParameter(valid_21627096, JString, required = false,
                                   default = nil)
  if valid_21627096 != nil:
    section.add "X-Amz-Signature", valid_21627096
  var valid_21627097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627097 = validateParameter(valid_21627097, JString, required = false,
                                   default = nil)
  if valid_21627097 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627097
  var valid_21627098 = header.getOrDefault("X-Amz-Credential")
  valid_21627098 = validateParameter(valid_21627098, JString, required = false,
                                   default = nil)
  if valid_21627098 != nil:
    section.add "X-Amz-Credential", valid_21627098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627100: Call_SearchContacts_21627086; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_21627100.validator(path, query, header, formData, body, _)
  let scheme = call_21627100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627100.makeUrl(scheme.get, call_21627100.host, call_21627100.base,
                               call_21627100.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627100, uri, valid, _)

proc call*(call_21627101: Call_SearchContacts_21627086; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchContacts
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627102 = newJObject()
  var body_21627103 = newJObject()
  add(query_21627102, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627103 = body
  add(query_21627102, "MaxResults", newJString(MaxResults))
  result = call_21627101.call(nil, query_21627102, nil, nil, body_21627103)

var searchContacts* = Call_SearchContacts_21627086(name: "searchContacts",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchContacts",
    validator: validate_SearchContacts_21627087, base: "/",
    makeUrl: url_SearchContacts_21627088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchDevices_21627104 = ref object of OpenApiRestCall_21625435
proc url_SearchDevices_21627106(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchDevices_21627105(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627107 = query.getOrDefault("NextToken")
  valid_21627107 = validateParameter(valid_21627107, JString, required = false,
                                   default = nil)
  if valid_21627107 != nil:
    section.add "NextToken", valid_21627107
  var valid_21627108 = query.getOrDefault("MaxResults")
  valid_21627108 = validateParameter(valid_21627108, JString, required = false,
                                   default = nil)
  if valid_21627108 != nil:
    section.add "MaxResults", valid_21627108
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
  var valid_21627109 = header.getOrDefault("X-Amz-Date")
  valid_21627109 = validateParameter(valid_21627109, JString, required = false,
                                   default = nil)
  if valid_21627109 != nil:
    section.add "X-Amz-Date", valid_21627109
  var valid_21627110 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627110 = validateParameter(valid_21627110, JString, required = false,
                                   default = nil)
  if valid_21627110 != nil:
    section.add "X-Amz-Security-Token", valid_21627110
  var valid_21627111 = header.getOrDefault("X-Amz-Target")
  valid_21627111 = validateParameter(valid_21627111, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchDevices"))
  if valid_21627111 != nil:
    section.add "X-Amz-Target", valid_21627111
  var valid_21627112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627112 = validateParameter(valid_21627112, JString, required = false,
                                   default = nil)
  if valid_21627112 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627112
  var valid_21627113 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627113 = validateParameter(valid_21627113, JString, required = false,
                                   default = nil)
  if valid_21627113 != nil:
    section.add "X-Amz-Algorithm", valid_21627113
  var valid_21627114 = header.getOrDefault("X-Amz-Signature")
  valid_21627114 = validateParameter(valid_21627114, JString, required = false,
                                   default = nil)
  if valid_21627114 != nil:
    section.add "X-Amz-Signature", valid_21627114
  var valid_21627115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627115 = validateParameter(valid_21627115, JString, required = false,
                                   default = nil)
  if valid_21627115 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627115
  var valid_21627116 = header.getOrDefault("X-Amz-Credential")
  valid_21627116 = validateParameter(valid_21627116, JString, required = false,
                                   default = nil)
  if valid_21627116 != nil:
    section.add "X-Amz-Credential", valid_21627116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627118: Call_SearchDevices_21627104; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Searches devices and lists the ones that meet a set of filter criteria.
  ## 
  let valid = call_21627118.validator(path, query, header, formData, body, _)
  let scheme = call_21627118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627118.makeUrl(scheme.get, call_21627118.host, call_21627118.base,
                               call_21627118.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627118, uri, valid, _)

proc call*(call_21627119: Call_SearchDevices_21627104; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchDevices
  ## Searches devices and lists the ones that meet a set of filter criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627120 = newJObject()
  var body_21627121 = newJObject()
  add(query_21627120, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627121 = body
  add(query_21627120, "MaxResults", newJString(MaxResults))
  result = call_21627119.call(nil, query_21627120, nil, nil, body_21627121)

var searchDevices* = Call_SearchDevices_21627104(name: "searchDevices",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchDevices",
    validator: validate_SearchDevices_21627105, base: "/",
    makeUrl: url_SearchDevices_21627106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchNetworkProfiles_21627122 = ref object of OpenApiRestCall_21625435
proc url_SearchNetworkProfiles_21627124(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchNetworkProfiles_21627123(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627125 = query.getOrDefault("NextToken")
  valid_21627125 = validateParameter(valid_21627125, JString, required = false,
                                   default = nil)
  if valid_21627125 != nil:
    section.add "NextToken", valid_21627125
  var valid_21627126 = query.getOrDefault("MaxResults")
  valid_21627126 = validateParameter(valid_21627126, JString, required = false,
                                   default = nil)
  if valid_21627126 != nil:
    section.add "MaxResults", valid_21627126
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
  var valid_21627127 = header.getOrDefault("X-Amz-Date")
  valid_21627127 = validateParameter(valid_21627127, JString, required = false,
                                   default = nil)
  if valid_21627127 != nil:
    section.add "X-Amz-Date", valid_21627127
  var valid_21627128 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627128 = validateParameter(valid_21627128, JString, required = false,
                                   default = nil)
  if valid_21627128 != nil:
    section.add "X-Amz-Security-Token", valid_21627128
  var valid_21627129 = header.getOrDefault("X-Amz-Target")
  valid_21627129 = validateParameter(valid_21627129, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchNetworkProfiles"))
  if valid_21627129 != nil:
    section.add "X-Amz-Target", valid_21627129
  var valid_21627130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627130 = validateParameter(valid_21627130, JString, required = false,
                                   default = nil)
  if valid_21627130 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627130
  var valid_21627131 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627131 = validateParameter(valid_21627131, JString, required = false,
                                   default = nil)
  if valid_21627131 != nil:
    section.add "X-Amz-Algorithm", valid_21627131
  var valid_21627132 = header.getOrDefault("X-Amz-Signature")
  valid_21627132 = validateParameter(valid_21627132, JString, required = false,
                                   default = nil)
  if valid_21627132 != nil:
    section.add "X-Amz-Signature", valid_21627132
  var valid_21627133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627133 = validateParameter(valid_21627133, JString, required = false,
                                   default = nil)
  if valid_21627133 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627133
  var valid_21627134 = header.getOrDefault("X-Amz-Credential")
  valid_21627134 = validateParameter(valid_21627134, JString, required = false,
                                   default = nil)
  if valid_21627134 != nil:
    section.add "X-Amz-Credential", valid_21627134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627136: Call_SearchNetworkProfiles_21627122;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_21627136.validator(path, query, header, formData, body, _)
  let scheme = call_21627136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627136.makeUrl(scheme.get, call_21627136.host, call_21627136.base,
                               call_21627136.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627136, uri, valid, _)

proc call*(call_21627137: Call_SearchNetworkProfiles_21627122; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchNetworkProfiles
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627138 = newJObject()
  var body_21627139 = newJObject()
  add(query_21627138, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627139 = body
  add(query_21627138, "MaxResults", newJString(MaxResults))
  result = call_21627137.call(nil, query_21627138, nil, nil, body_21627139)

var searchNetworkProfiles* = Call_SearchNetworkProfiles_21627122(
    name: "searchNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchNetworkProfiles",
    validator: validate_SearchNetworkProfiles_21627123, base: "/",
    makeUrl: url_SearchNetworkProfiles_21627124,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProfiles_21627140 = ref object of OpenApiRestCall_21625435
proc url_SearchProfiles_21627142(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchProfiles_21627141(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627143 = query.getOrDefault("NextToken")
  valid_21627143 = validateParameter(valid_21627143, JString, required = false,
                                   default = nil)
  if valid_21627143 != nil:
    section.add "NextToken", valid_21627143
  var valid_21627144 = query.getOrDefault("MaxResults")
  valid_21627144 = validateParameter(valid_21627144, JString, required = false,
                                   default = nil)
  if valid_21627144 != nil:
    section.add "MaxResults", valid_21627144
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
  var valid_21627145 = header.getOrDefault("X-Amz-Date")
  valid_21627145 = validateParameter(valid_21627145, JString, required = false,
                                   default = nil)
  if valid_21627145 != nil:
    section.add "X-Amz-Date", valid_21627145
  var valid_21627146 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627146 = validateParameter(valid_21627146, JString, required = false,
                                   default = nil)
  if valid_21627146 != nil:
    section.add "X-Amz-Security-Token", valid_21627146
  var valid_21627147 = header.getOrDefault("X-Amz-Target")
  valid_21627147 = validateParameter(valid_21627147, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchProfiles"))
  if valid_21627147 != nil:
    section.add "X-Amz-Target", valid_21627147
  var valid_21627148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627148 = validateParameter(valid_21627148, JString, required = false,
                                   default = nil)
  if valid_21627148 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627148
  var valid_21627149 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627149 = validateParameter(valid_21627149, JString, required = false,
                                   default = nil)
  if valid_21627149 != nil:
    section.add "X-Amz-Algorithm", valid_21627149
  var valid_21627150 = header.getOrDefault("X-Amz-Signature")
  valid_21627150 = validateParameter(valid_21627150, JString, required = false,
                                   default = nil)
  if valid_21627150 != nil:
    section.add "X-Amz-Signature", valid_21627150
  var valid_21627151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627151 = validateParameter(valid_21627151, JString, required = false,
                                   default = nil)
  if valid_21627151 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627151
  var valid_21627152 = header.getOrDefault("X-Amz-Credential")
  valid_21627152 = validateParameter(valid_21627152, JString, required = false,
                                   default = nil)
  if valid_21627152 != nil:
    section.add "X-Amz-Credential", valid_21627152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627154: Call_SearchProfiles_21627140; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
  ## 
  let valid = call_21627154.validator(path, query, header, formData, body, _)
  let scheme = call_21627154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627154.makeUrl(scheme.get, call_21627154.host, call_21627154.base,
                               call_21627154.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627154, uri, valid, _)

proc call*(call_21627155: Call_SearchProfiles_21627140; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchProfiles
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627156 = newJObject()
  var body_21627157 = newJObject()
  add(query_21627156, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627157 = body
  add(query_21627156, "MaxResults", newJString(MaxResults))
  result = call_21627155.call(nil, query_21627156, nil, nil, body_21627157)

var searchProfiles* = Call_SearchProfiles_21627140(name: "searchProfiles",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchProfiles",
    validator: validate_SearchProfiles_21627141, base: "/",
    makeUrl: url_SearchProfiles_21627142, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchRooms_21627158 = ref object of OpenApiRestCall_21625435
proc url_SearchRooms_21627160(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchRooms_21627159(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627161 = query.getOrDefault("NextToken")
  valid_21627161 = validateParameter(valid_21627161, JString, required = false,
                                   default = nil)
  if valid_21627161 != nil:
    section.add "NextToken", valid_21627161
  var valid_21627162 = query.getOrDefault("MaxResults")
  valid_21627162 = validateParameter(valid_21627162, JString, required = false,
                                   default = nil)
  if valid_21627162 != nil:
    section.add "MaxResults", valid_21627162
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
  var valid_21627163 = header.getOrDefault("X-Amz-Date")
  valid_21627163 = validateParameter(valid_21627163, JString, required = false,
                                   default = nil)
  if valid_21627163 != nil:
    section.add "X-Amz-Date", valid_21627163
  var valid_21627164 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627164 = validateParameter(valid_21627164, JString, required = false,
                                   default = nil)
  if valid_21627164 != nil:
    section.add "X-Amz-Security-Token", valid_21627164
  var valid_21627165 = header.getOrDefault("X-Amz-Target")
  valid_21627165 = validateParameter(valid_21627165, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchRooms"))
  if valid_21627165 != nil:
    section.add "X-Amz-Target", valid_21627165
  var valid_21627166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627166 = validateParameter(valid_21627166, JString, required = false,
                                   default = nil)
  if valid_21627166 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627166
  var valid_21627167 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627167 = validateParameter(valid_21627167, JString, required = false,
                                   default = nil)
  if valid_21627167 != nil:
    section.add "X-Amz-Algorithm", valid_21627167
  var valid_21627168 = header.getOrDefault("X-Amz-Signature")
  valid_21627168 = validateParameter(valid_21627168, JString, required = false,
                                   default = nil)
  if valid_21627168 != nil:
    section.add "X-Amz-Signature", valid_21627168
  var valid_21627169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627169 = validateParameter(valid_21627169, JString, required = false,
                                   default = nil)
  if valid_21627169 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627169
  var valid_21627170 = header.getOrDefault("X-Amz-Credential")
  valid_21627170 = validateParameter(valid_21627170, JString, required = false,
                                   default = nil)
  if valid_21627170 != nil:
    section.add "X-Amz-Credential", valid_21627170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627172: Call_SearchRooms_21627158; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_21627172.validator(path, query, header, formData, body, _)
  let scheme = call_21627172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627172.makeUrl(scheme.get, call_21627172.host, call_21627172.base,
                               call_21627172.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627172, uri, valid, _)

proc call*(call_21627173: Call_SearchRooms_21627158; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchRooms
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627174 = newJObject()
  var body_21627175 = newJObject()
  add(query_21627174, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627175 = body
  add(query_21627174, "MaxResults", newJString(MaxResults))
  result = call_21627173.call(nil, query_21627174, nil, nil, body_21627175)

var searchRooms* = Call_SearchRooms_21627158(name: "searchRooms",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchRooms",
    validator: validate_SearchRooms_21627159, base: "/", makeUrl: url_SearchRooms_21627160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSkillGroups_21627176 = ref object of OpenApiRestCall_21625435
proc url_SearchSkillGroups_21627178(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchSkillGroups_21627177(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627179 = query.getOrDefault("NextToken")
  valid_21627179 = validateParameter(valid_21627179, JString, required = false,
                                   default = nil)
  if valid_21627179 != nil:
    section.add "NextToken", valid_21627179
  var valid_21627180 = query.getOrDefault("MaxResults")
  valid_21627180 = validateParameter(valid_21627180, JString, required = false,
                                   default = nil)
  if valid_21627180 != nil:
    section.add "MaxResults", valid_21627180
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
  var valid_21627181 = header.getOrDefault("X-Amz-Date")
  valid_21627181 = validateParameter(valid_21627181, JString, required = false,
                                   default = nil)
  if valid_21627181 != nil:
    section.add "X-Amz-Date", valid_21627181
  var valid_21627182 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627182 = validateParameter(valid_21627182, JString, required = false,
                                   default = nil)
  if valid_21627182 != nil:
    section.add "X-Amz-Security-Token", valid_21627182
  var valid_21627183 = header.getOrDefault("X-Amz-Target")
  valid_21627183 = validateParameter(valid_21627183, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchSkillGroups"))
  if valid_21627183 != nil:
    section.add "X-Amz-Target", valid_21627183
  var valid_21627184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627184 = validateParameter(valid_21627184, JString, required = false,
                                   default = nil)
  if valid_21627184 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627184
  var valid_21627185 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627185 = validateParameter(valid_21627185, JString, required = false,
                                   default = nil)
  if valid_21627185 != nil:
    section.add "X-Amz-Algorithm", valid_21627185
  var valid_21627186 = header.getOrDefault("X-Amz-Signature")
  valid_21627186 = validateParameter(valid_21627186, JString, required = false,
                                   default = nil)
  if valid_21627186 != nil:
    section.add "X-Amz-Signature", valid_21627186
  var valid_21627187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627187 = validateParameter(valid_21627187, JString, required = false,
                                   default = nil)
  if valid_21627187 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627187
  var valid_21627188 = header.getOrDefault("X-Amz-Credential")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-Credential", valid_21627188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627190: Call_SearchSkillGroups_21627176; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_21627190.validator(path, query, header, formData, body, _)
  let scheme = call_21627190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627190.makeUrl(scheme.get, call_21627190.host, call_21627190.base,
                               call_21627190.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627190, uri, valid, _)

proc call*(call_21627191: Call_SearchSkillGroups_21627176; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchSkillGroups
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627192 = newJObject()
  var body_21627193 = newJObject()
  add(query_21627192, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627193 = body
  add(query_21627192, "MaxResults", newJString(MaxResults))
  result = call_21627191.call(nil, query_21627192, nil, nil, body_21627193)

var searchSkillGroups* = Call_SearchSkillGroups_21627176(name: "searchSkillGroups",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchSkillGroups",
    validator: validate_SearchSkillGroups_21627177, base: "/",
    makeUrl: url_SearchSkillGroups_21627178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchUsers_21627194 = ref object of OpenApiRestCall_21625435
proc url_SearchUsers_21627196(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchUsers_21627195(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627197 = query.getOrDefault("NextToken")
  valid_21627197 = validateParameter(valid_21627197, JString, required = false,
                                   default = nil)
  if valid_21627197 != nil:
    section.add "NextToken", valid_21627197
  var valid_21627198 = query.getOrDefault("MaxResults")
  valid_21627198 = validateParameter(valid_21627198, JString, required = false,
                                   default = nil)
  if valid_21627198 != nil:
    section.add "MaxResults", valid_21627198
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
  var valid_21627199 = header.getOrDefault("X-Amz-Date")
  valid_21627199 = validateParameter(valid_21627199, JString, required = false,
                                   default = nil)
  if valid_21627199 != nil:
    section.add "X-Amz-Date", valid_21627199
  var valid_21627200 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627200 = validateParameter(valid_21627200, JString, required = false,
                                   default = nil)
  if valid_21627200 != nil:
    section.add "X-Amz-Security-Token", valid_21627200
  var valid_21627201 = header.getOrDefault("X-Amz-Target")
  valid_21627201 = validateParameter(valid_21627201, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchUsers"))
  if valid_21627201 != nil:
    section.add "X-Amz-Target", valid_21627201
  var valid_21627202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627202 = validateParameter(valid_21627202, JString, required = false,
                                   default = nil)
  if valid_21627202 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627202
  var valid_21627203 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627203 = validateParameter(valid_21627203, JString, required = false,
                                   default = nil)
  if valid_21627203 != nil:
    section.add "X-Amz-Algorithm", valid_21627203
  var valid_21627204 = header.getOrDefault("X-Amz-Signature")
  valid_21627204 = validateParameter(valid_21627204, JString, required = false,
                                   default = nil)
  if valid_21627204 != nil:
    section.add "X-Amz-Signature", valid_21627204
  var valid_21627205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627205 = validateParameter(valid_21627205, JString, required = false,
                                   default = nil)
  if valid_21627205 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627205
  var valid_21627206 = header.getOrDefault("X-Amz-Credential")
  valid_21627206 = validateParameter(valid_21627206, JString, required = false,
                                   default = nil)
  if valid_21627206 != nil:
    section.add "X-Amz-Credential", valid_21627206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627208: Call_SearchUsers_21627194; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_21627208.validator(path, query, header, formData, body, _)
  let scheme = call_21627208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627208.makeUrl(scheme.get, call_21627208.host, call_21627208.base,
                               call_21627208.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627208, uri, valid, _)

proc call*(call_21627209: Call_SearchUsers_21627194; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchUsers
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627210 = newJObject()
  var body_21627211 = newJObject()
  add(query_21627210, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627211 = body
  add(query_21627210, "MaxResults", newJString(MaxResults))
  result = call_21627209.call(nil, query_21627210, nil, nil, body_21627211)

var searchUsers* = Call_SearchUsers_21627194(name: "searchUsers",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchUsers",
    validator: validate_SearchUsers_21627195, base: "/", makeUrl: url_SearchUsers_21627196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAnnouncement_21627212 = ref object of OpenApiRestCall_21625435
proc url_SendAnnouncement_21627214(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendAnnouncement_21627213(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627215 = header.getOrDefault("X-Amz-Date")
  valid_21627215 = validateParameter(valid_21627215, JString, required = false,
                                   default = nil)
  if valid_21627215 != nil:
    section.add "X-Amz-Date", valid_21627215
  var valid_21627216 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627216 = validateParameter(valid_21627216, JString, required = false,
                                   default = nil)
  if valid_21627216 != nil:
    section.add "X-Amz-Security-Token", valid_21627216
  var valid_21627217 = header.getOrDefault("X-Amz-Target")
  valid_21627217 = validateParameter(valid_21627217, JString, required = true, default = newJString(
      "AlexaForBusiness.SendAnnouncement"))
  if valid_21627217 != nil:
    section.add "X-Amz-Target", valid_21627217
  var valid_21627218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627218 = validateParameter(valid_21627218, JString, required = false,
                                   default = nil)
  if valid_21627218 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627218
  var valid_21627219 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627219 = validateParameter(valid_21627219, JString, required = false,
                                   default = nil)
  if valid_21627219 != nil:
    section.add "X-Amz-Algorithm", valid_21627219
  var valid_21627220 = header.getOrDefault("X-Amz-Signature")
  valid_21627220 = validateParameter(valid_21627220, JString, required = false,
                                   default = nil)
  if valid_21627220 != nil:
    section.add "X-Amz-Signature", valid_21627220
  var valid_21627221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627221 = validateParameter(valid_21627221, JString, required = false,
                                   default = nil)
  if valid_21627221 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627221
  var valid_21627222 = header.getOrDefault("X-Amz-Credential")
  valid_21627222 = validateParameter(valid_21627222, JString, required = false,
                                   default = nil)
  if valid_21627222 != nil:
    section.add "X-Amz-Credential", valid_21627222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627224: Call_SendAnnouncement_21627212; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Triggers an asynchronous flow to send text, SSML, or audio announcements to rooms that are identified by a search or filter. 
  ## 
  let valid = call_21627224.validator(path, query, header, formData, body, _)
  let scheme = call_21627224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627224.makeUrl(scheme.get, call_21627224.host, call_21627224.base,
                               call_21627224.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627224, uri, valid, _)

proc call*(call_21627225: Call_SendAnnouncement_21627212; body: JsonNode): Recallable =
  ## sendAnnouncement
  ## Triggers an asynchronous flow to send text, SSML, or audio announcements to rooms that are identified by a search or filter. 
  ##   body: JObject (required)
  var body_21627226 = newJObject()
  if body != nil:
    body_21627226 = body
  result = call_21627225.call(nil, nil, nil, nil, body_21627226)

var sendAnnouncement* = Call_SendAnnouncement_21627212(name: "sendAnnouncement",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SendAnnouncement",
    validator: validate_SendAnnouncement_21627213, base: "/",
    makeUrl: url_SendAnnouncement_21627214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendInvitation_21627227 = ref object of OpenApiRestCall_21625435
proc url_SendInvitation_21627229(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendInvitation_21627228(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627230 = header.getOrDefault("X-Amz-Date")
  valid_21627230 = validateParameter(valid_21627230, JString, required = false,
                                   default = nil)
  if valid_21627230 != nil:
    section.add "X-Amz-Date", valid_21627230
  var valid_21627231 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627231 = validateParameter(valid_21627231, JString, required = false,
                                   default = nil)
  if valid_21627231 != nil:
    section.add "X-Amz-Security-Token", valid_21627231
  var valid_21627232 = header.getOrDefault("X-Amz-Target")
  valid_21627232 = validateParameter(valid_21627232, JString, required = true, default = newJString(
      "AlexaForBusiness.SendInvitation"))
  if valid_21627232 != nil:
    section.add "X-Amz-Target", valid_21627232
  var valid_21627233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627233 = validateParameter(valid_21627233, JString, required = false,
                                   default = nil)
  if valid_21627233 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627233
  var valid_21627234 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627234 = validateParameter(valid_21627234, JString, required = false,
                                   default = nil)
  if valid_21627234 != nil:
    section.add "X-Amz-Algorithm", valid_21627234
  var valid_21627235 = header.getOrDefault("X-Amz-Signature")
  valid_21627235 = validateParameter(valid_21627235, JString, required = false,
                                   default = nil)
  if valid_21627235 != nil:
    section.add "X-Amz-Signature", valid_21627235
  var valid_21627236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627236 = validateParameter(valid_21627236, JString, required = false,
                                   default = nil)
  if valid_21627236 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627236
  var valid_21627237 = header.getOrDefault("X-Amz-Credential")
  valid_21627237 = validateParameter(valid_21627237, JString, required = false,
                                   default = nil)
  if valid_21627237 != nil:
    section.add "X-Amz-Credential", valid_21627237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627239: Call_SendInvitation_21627227; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Sends an enrollment invitation email with a URL to a user. The URL is valid for 30 days or until you call this operation again, whichever comes first. 
  ## 
  let valid = call_21627239.validator(path, query, header, formData, body, _)
  let scheme = call_21627239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627239.makeUrl(scheme.get, call_21627239.host, call_21627239.base,
                               call_21627239.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627239, uri, valid, _)

proc call*(call_21627240: Call_SendInvitation_21627227; body: JsonNode): Recallable =
  ## sendInvitation
  ## Sends an enrollment invitation email with a URL to a user. The URL is valid for 30 days or until you call this operation again, whichever comes first. 
  ##   body: JObject (required)
  var body_21627241 = newJObject()
  if body != nil:
    body_21627241 = body
  result = call_21627240.call(nil, nil, nil, nil, body_21627241)

var sendInvitation* = Call_SendInvitation_21627227(name: "sendInvitation",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SendInvitation",
    validator: validate_SendInvitation_21627228, base: "/",
    makeUrl: url_SendInvitation_21627229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeviceSync_21627242 = ref object of OpenApiRestCall_21625435
proc url_StartDeviceSync_21627244(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartDeviceSync_21627243(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627245 = header.getOrDefault("X-Amz-Date")
  valid_21627245 = validateParameter(valid_21627245, JString, required = false,
                                   default = nil)
  if valid_21627245 != nil:
    section.add "X-Amz-Date", valid_21627245
  var valid_21627246 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627246 = validateParameter(valid_21627246, JString, required = false,
                                   default = nil)
  if valid_21627246 != nil:
    section.add "X-Amz-Security-Token", valid_21627246
  var valid_21627247 = header.getOrDefault("X-Amz-Target")
  valid_21627247 = validateParameter(valid_21627247, JString, required = true, default = newJString(
      "AlexaForBusiness.StartDeviceSync"))
  if valid_21627247 != nil:
    section.add "X-Amz-Target", valid_21627247
  var valid_21627248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627248 = validateParameter(valid_21627248, JString, required = false,
                                   default = nil)
  if valid_21627248 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627248
  var valid_21627249 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627249 = validateParameter(valid_21627249, JString, required = false,
                                   default = nil)
  if valid_21627249 != nil:
    section.add "X-Amz-Algorithm", valid_21627249
  var valid_21627250 = header.getOrDefault("X-Amz-Signature")
  valid_21627250 = validateParameter(valid_21627250, JString, required = false,
                                   default = nil)
  if valid_21627250 != nil:
    section.add "X-Amz-Signature", valid_21627250
  var valid_21627251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627251 = validateParameter(valid_21627251, JString, required = false,
                                   default = nil)
  if valid_21627251 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627251
  var valid_21627252 = header.getOrDefault("X-Amz-Credential")
  valid_21627252 = validateParameter(valid_21627252, JString, required = false,
                                   default = nil)
  if valid_21627252 != nil:
    section.add "X-Amz-Credential", valid_21627252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627254: Call_StartDeviceSync_21627242; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Resets a device and its account to the known default settings. This clears all information and settings set by previous users in the following ways:</p> <ul> <li> <p>Bluetooth - This unpairs all bluetooth devices paired with your echo device.</p> </li> <li> <p>Volume - This resets the echo device's volume to the default value.</p> </li> <li> <p>Notifications - This clears all notifications from your echo device.</p> </li> <li> <p>Lists - This clears all to-do items from your echo device.</p> </li> <li> <p>Settings - This internally syncs the room's profile (if the device is assigned to a room), contacts, address books, delegation access for account linking, and communications (if enabled on the room profile).</p> </li> </ul>
  ## 
  let valid = call_21627254.validator(path, query, header, formData, body, _)
  let scheme = call_21627254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627254.makeUrl(scheme.get, call_21627254.host, call_21627254.base,
                               call_21627254.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627254, uri, valid, _)

proc call*(call_21627255: Call_StartDeviceSync_21627242; body: JsonNode): Recallable =
  ## startDeviceSync
  ## <p>Resets a device and its account to the known default settings. This clears all information and settings set by previous users in the following ways:</p> <ul> <li> <p>Bluetooth - This unpairs all bluetooth devices paired with your echo device.</p> </li> <li> <p>Volume - This resets the echo device's volume to the default value.</p> </li> <li> <p>Notifications - This clears all notifications from your echo device.</p> </li> <li> <p>Lists - This clears all to-do items from your echo device.</p> </li> <li> <p>Settings - This internally syncs the room's profile (if the device is assigned to a room), contacts, address books, delegation access for account linking, and communications (if enabled on the room profile).</p> </li> </ul>
  ##   body: JObject (required)
  var body_21627256 = newJObject()
  if body != nil:
    body_21627256 = body
  result = call_21627255.call(nil, nil, nil, nil, body_21627256)

var startDeviceSync* = Call_StartDeviceSync_21627242(name: "startDeviceSync",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.StartDeviceSync",
    validator: validate_StartDeviceSync_21627243, base: "/",
    makeUrl: url_StartDeviceSync_21627244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSmartHomeApplianceDiscovery_21627257 = ref object of OpenApiRestCall_21625435
proc url_StartSmartHomeApplianceDiscovery_21627259(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartSmartHomeApplianceDiscovery_21627258(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627260 = header.getOrDefault("X-Amz-Date")
  valid_21627260 = validateParameter(valid_21627260, JString, required = false,
                                   default = nil)
  if valid_21627260 != nil:
    section.add "X-Amz-Date", valid_21627260
  var valid_21627261 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627261 = validateParameter(valid_21627261, JString, required = false,
                                   default = nil)
  if valid_21627261 != nil:
    section.add "X-Amz-Security-Token", valid_21627261
  var valid_21627262 = header.getOrDefault("X-Amz-Target")
  valid_21627262 = validateParameter(valid_21627262, JString, required = true, default = newJString(
      "AlexaForBusiness.StartSmartHomeApplianceDiscovery"))
  if valid_21627262 != nil:
    section.add "X-Amz-Target", valid_21627262
  var valid_21627263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627263 = validateParameter(valid_21627263, JString, required = false,
                                   default = nil)
  if valid_21627263 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627263
  var valid_21627264 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627264 = validateParameter(valid_21627264, JString, required = false,
                                   default = nil)
  if valid_21627264 != nil:
    section.add "X-Amz-Algorithm", valid_21627264
  var valid_21627265 = header.getOrDefault("X-Amz-Signature")
  valid_21627265 = validateParameter(valid_21627265, JString, required = false,
                                   default = nil)
  if valid_21627265 != nil:
    section.add "X-Amz-Signature", valid_21627265
  var valid_21627266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627266 = validateParameter(valid_21627266, JString, required = false,
                                   default = nil)
  if valid_21627266 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627266
  var valid_21627267 = header.getOrDefault("X-Amz-Credential")
  valid_21627267 = validateParameter(valid_21627267, JString, required = false,
                                   default = nil)
  if valid_21627267 != nil:
    section.add "X-Amz-Credential", valid_21627267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627269: Call_StartSmartHomeApplianceDiscovery_21627257;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Initiates the discovery of any smart home appliances associated with the room.
  ## 
  let valid = call_21627269.validator(path, query, header, formData, body, _)
  let scheme = call_21627269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627269.makeUrl(scheme.get, call_21627269.host, call_21627269.base,
                               call_21627269.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627269, uri, valid, _)

proc call*(call_21627270: Call_StartSmartHomeApplianceDiscovery_21627257;
          body: JsonNode): Recallable =
  ## startSmartHomeApplianceDiscovery
  ## Initiates the discovery of any smart home appliances associated with the room.
  ##   body: JObject (required)
  var body_21627271 = newJObject()
  if body != nil:
    body_21627271 = body
  result = call_21627270.call(nil, nil, nil, nil, body_21627271)

var startSmartHomeApplianceDiscovery* = Call_StartSmartHomeApplianceDiscovery_21627257(
    name: "startSmartHomeApplianceDiscovery", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.StartSmartHomeApplianceDiscovery",
    validator: validate_StartSmartHomeApplianceDiscovery_21627258, base: "/",
    makeUrl: url_StartSmartHomeApplianceDiscovery_21627259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21627272 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21627274(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21627273(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627275 = header.getOrDefault("X-Amz-Date")
  valid_21627275 = validateParameter(valid_21627275, JString, required = false,
                                   default = nil)
  if valid_21627275 != nil:
    section.add "X-Amz-Date", valid_21627275
  var valid_21627276 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627276 = validateParameter(valid_21627276, JString, required = false,
                                   default = nil)
  if valid_21627276 != nil:
    section.add "X-Amz-Security-Token", valid_21627276
  var valid_21627277 = header.getOrDefault("X-Amz-Target")
  valid_21627277 = validateParameter(valid_21627277, JString, required = true, default = newJString(
      "AlexaForBusiness.TagResource"))
  if valid_21627277 != nil:
    section.add "X-Amz-Target", valid_21627277
  var valid_21627278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627278 = validateParameter(valid_21627278, JString, required = false,
                                   default = nil)
  if valid_21627278 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627278
  var valid_21627279 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627279 = validateParameter(valid_21627279, JString, required = false,
                                   default = nil)
  if valid_21627279 != nil:
    section.add "X-Amz-Algorithm", valid_21627279
  var valid_21627280 = header.getOrDefault("X-Amz-Signature")
  valid_21627280 = validateParameter(valid_21627280, JString, required = false,
                                   default = nil)
  if valid_21627280 != nil:
    section.add "X-Amz-Signature", valid_21627280
  var valid_21627281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627281 = validateParameter(valid_21627281, JString, required = false,
                                   default = nil)
  if valid_21627281 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627281
  var valid_21627282 = header.getOrDefault("X-Amz-Credential")
  valid_21627282 = validateParameter(valid_21627282, JString, required = false,
                                   default = nil)
  if valid_21627282 != nil:
    section.add "X-Amz-Credential", valid_21627282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627284: Call_TagResource_21627272; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds metadata tags to a specified resource.
  ## 
  let valid = call_21627284.validator(path, query, header, formData, body, _)
  let scheme = call_21627284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627284.makeUrl(scheme.get, call_21627284.host, call_21627284.base,
                               call_21627284.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627284, uri, valid, _)

proc call*(call_21627285: Call_TagResource_21627272; body: JsonNode): Recallable =
  ## tagResource
  ## Adds metadata tags to a specified resource.
  ##   body: JObject (required)
  var body_21627286 = newJObject()
  if body != nil:
    body_21627286 = body
  result = call_21627285.call(nil, nil, nil, nil, body_21627286)

var tagResource* = Call_TagResource_21627272(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.TagResource",
    validator: validate_TagResource_21627273, base: "/", makeUrl: url_TagResource_21627274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21627287 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21627289(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21627288(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627290 = header.getOrDefault("X-Amz-Date")
  valid_21627290 = validateParameter(valid_21627290, JString, required = false,
                                   default = nil)
  if valid_21627290 != nil:
    section.add "X-Amz-Date", valid_21627290
  var valid_21627291 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627291 = validateParameter(valid_21627291, JString, required = false,
                                   default = nil)
  if valid_21627291 != nil:
    section.add "X-Amz-Security-Token", valid_21627291
  var valid_21627292 = header.getOrDefault("X-Amz-Target")
  valid_21627292 = validateParameter(valid_21627292, JString, required = true, default = newJString(
      "AlexaForBusiness.UntagResource"))
  if valid_21627292 != nil:
    section.add "X-Amz-Target", valid_21627292
  var valid_21627293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627293 = validateParameter(valid_21627293, JString, required = false,
                                   default = nil)
  if valid_21627293 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627293
  var valid_21627294 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627294 = validateParameter(valid_21627294, JString, required = false,
                                   default = nil)
  if valid_21627294 != nil:
    section.add "X-Amz-Algorithm", valid_21627294
  var valid_21627295 = header.getOrDefault("X-Amz-Signature")
  valid_21627295 = validateParameter(valid_21627295, JString, required = false,
                                   default = nil)
  if valid_21627295 != nil:
    section.add "X-Amz-Signature", valid_21627295
  var valid_21627296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627296 = validateParameter(valid_21627296, JString, required = false,
                                   default = nil)
  if valid_21627296 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627296
  var valid_21627297 = header.getOrDefault("X-Amz-Credential")
  valid_21627297 = validateParameter(valid_21627297, JString, required = false,
                                   default = nil)
  if valid_21627297 != nil:
    section.add "X-Amz-Credential", valid_21627297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627299: Call_UntagResource_21627287; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes metadata tags from a specified resource.
  ## 
  let valid = call_21627299.validator(path, query, header, formData, body, _)
  let scheme = call_21627299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627299.makeUrl(scheme.get, call_21627299.host, call_21627299.base,
                               call_21627299.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627299, uri, valid, _)

proc call*(call_21627300: Call_UntagResource_21627287; body: JsonNode): Recallable =
  ## untagResource
  ## Removes metadata tags from a specified resource.
  ##   body: JObject (required)
  var body_21627301 = newJObject()
  if body != nil:
    body_21627301 = body
  result = call_21627300.call(nil, nil, nil, nil, body_21627301)

var untagResource* = Call_UntagResource_21627287(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UntagResource",
    validator: validate_UntagResource_21627288, base: "/",
    makeUrl: url_UntagResource_21627289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAddressBook_21627302 = ref object of OpenApiRestCall_21625435
proc url_UpdateAddressBook_21627304(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAddressBook_21627303(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627305 = header.getOrDefault("X-Amz-Date")
  valid_21627305 = validateParameter(valid_21627305, JString, required = false,
                                   default = nil)
  if valid_21627305 != nil:
    section.add "X-Amz-Date", valid_21627305
  var valid_21627306 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627306 = validateParameter(valid_21627306, JString, required = false,
                                   default = nil)
  if valid_21627306 != nil:
    section.add "X-Amz-Security-Token", valid_21627306
  var valid_21627307 = header.getOrDefault("X-Amz-Target")
  valid_21627307 = validateParameter(valid_21627307, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateAddressBook"))
  if valid_21627307 != nil:
    section.add "X-Amz-Target", valid_21627307
  var valid_21627308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627308 = validateParameter(valid_21627308, JString, required = false,
                                   default = nil)
  if valid_21627308 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627308
  var valid_21627309 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627309 = validateParameter(valid_21627309, JString, required = false,
                                   default = nil)
  if valid_21627309 != nil:
    section.add "X-Amz-Algorithm", valid_21627309
  var valid_21627310 = header.getOrDefault("X-Amz-Signature")
  valid_21627310 = validateParameter(valid_21627310, JString, required = false,
                                   default = nil)
  if valid_21627310 != nil:
    section.add "X-Amz-Signature", valid_21627310
  var valid_21627311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627311 = validateParameter(valid_21627311, JString, required = false,
                                   default = nil)
  if valid_21627311 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627311
  var valid_21627312 = header.getOrDefault("X-Amz-Credential")
  valid_21627312 = validateParameter(valid_21627312, JString, required = false,
                                   default = nil)
  if valid_21627312 != nil:
    section.add "X-Amz-Credential", valid_21627312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627314: Call_UpdateAddressBook_21627302; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates address book details by the address book ARN.
  ## 
  let valid = call_21627314.validator(path, query, header, formData, body, _)
  let scheme = call_21627314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627314.makeUrl(scheme.get, call_21627314.host, call_21627314.base,
                               call_21627314.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627314, uri, valid, _)

proc call*(call_21627315: Call_UpdateAddressBook_21627302; body: JsonNode): Recallable =
  ## updateAddressBook
  ## Updates address book details by the address book ARN.
  ##   body: JObject (required)
  var body_21627316 = newJObject()
  if body != nil:
    body_21627316 = body
  result = call_21627315.call(nil, nil, nil, nil, body_21627316)

var updateAddressBook* = Call_UpdateAddressBook_21627302(name: "updateAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateAddressBook",
    validator: validate_UpdateAddressBook_21627303, base: "/",
    makeUrl: url_UpdateAddressBook_21627304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBusinessReportSchedule_21627317 = ref object of OpenApiRestCall_21625435
proc url_UpdateBusinessReportSchedule_21627319(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateBusinessReportSchedule_21627318(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627320 = header.getOrDefault("X-Amz-Date")
  valid_21627320 = validateParameter(valid_21627320, JString, required = false,
                                   default = nil)
  if valid_21627320 != nil:
    section.add "X-Amz-Date", valid_21627320
  var valid_21627321 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627321 = validateParameter(valid_21627321, JString, required = false,
                                   default = nil)
  if valid_21627321 != nil:
    section.add "X-Amz-Security-Token", valid_21627321
  var valid_21627322 = header.getOrDefault("X-Amz-Target")
  valid_21627322 = validateParameter(valid_21627322, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateBusinessReportSchedule"))
  if valid_21627322 != nil:
    section.add "X-Amz-Target", valid_21627322
  var valid_21627323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627323 = validateParameter(valid_21627323, JString, required = false,
                                   default = nil)
  if valid_21627323 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627323
  var valid_21627324 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627324 = validateParameter(valid_21627324, JString, required = false,
                                   default = nil)
  if valid_21627324 != nil:
    section.add "X-Amz-Algorithm", valid_21627324
  var valid_21627325 = header.getOrDefault("X-Amz-Signature")
  valid_21627325 = validateParameter(valid_21627325, JString, required = false,
                                   default = nil)
  if valid_21627325 != nil:
    section.add "X-Amz-Signature", valid_21627325
  var valid_21627326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627326 = validateParameter(valid_21627326, JString, required = false,
                                   default = nil)
  if valid_21627326 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627326
  var valid_21627327 = header.getOrDefault("X-Amz-Credential")
  valid_21627327 = validateParameter(valid_21627327, JString, required = false,
                                   default = nil)
  if valid_21627327 != nil:
    section.add "X-Amz-Credential", valid_21627327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627329: Call_UpdateBusinessReportSchedule_21627317;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the configuration of the report delivery schedule with the specified schedule ARN.
  ## 
  let valid = call_21627329.validator(path, query, header, formData, body, _)
  let scheme = call_21627329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627329.makeUrl(scheme.get, call_21627329.host, call_21627329.base,
                               call_21627329.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627329, uri, valid, _)

proc call*(call_21627330: Call_UpdateBusinessReportSchedule_21627317;
          body: JsonNode): Recallable =
  ## updateBusinessReportSchedule
  ## Updates the configuration of the report delivery schedule with the specified schedule ARN.
  ##   body: JObject (required)
  var body_21627331 = newJObject()
  if body != nil:
    body_21627331 = body
  result = call_21627330.call(nil, nil, nil, nil, body_21627331)

var updateBusinessReportSchedule* = Call_UpdateBusinessReportSchedule_21627317(
    name: "updateBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateBusinessReportSchedule",
    validator: validate_UpdateBusinessReportSchedule_21627318, base: "/",
    makeUrl: url_UpdateBusinessReportSchedule_21627319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConferenceProvider_21627332 = ref object of OpenApiRestCall_21625435
proc url_UpdateConferenceProvider_21627334(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateConferenceProvider_21627333(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627335 = header.getOrDefault("X-Amz-Date")
  valid_21627335 = validateParameter(valid_21627335, JString, required = false,
                                   default = nil)
  if valid_21627335 != nil:
    section.add "X-Amz-Date", valid_21627335
  var valid_21627336 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627336 = validateParameter(valid_21627336, JString, required = false,
                                   default = nil)
  if valid_21627336 != nil:
    section.add "X-Amz-Security-Token", valid_21627336
  var valid_21627337 = header.getOrDefault("X-Amz-Target")
  valid_21627337 = validateParameter(valid_21627337, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateConferenceProvider"))
  if valid_21627337 != nil:
    section.add "X-Amz-Target", valid_21627337
  var valid_21627338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627338 = validateParameter(valid_21627338, JString, required = false,
                                   default = nil)
  if valid_21627338 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627338
  var valid_21627339 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627339 = validateParameter(valid_21627339, JString, required = false,
                                   default = nil)
  if valid_21627339 != nil:
    section.add "X-Amz-Algorithm", valid_21627339
  var valid_21627340 = header.getOrDefault("X-Amz-Signature")
  valid_21627340 = validateParameter(valid_21627340, JString, required = false,
                                   default = nil)
  if valid_21627340 != nil:
    section.add "X-Amz-Signature", valid_21627340
  var valid_21627341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627341 = validateParameter(valid_21627341, JString, required = false,
                                   default = nil)
  if valid_21627341 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627341
  var valid_21627342 = header.getOrDefault("X-Amz-Credential")
  valid_21627342 = validateParameter(valid_21627342, JString, required = false,
                                   default = nil)
  if valid_21627342 != nil:
    section.add "X-Amz-Credential", valid_21627342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627344: Call_UpdateConferenceProvider_21627332;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing conference provider's settings.
  ## 
  let valid = call_21627344.validator(path, query, header, formData, body, _)
  let scheme = call_21627344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627344.makeUrl(scheme.get, call_21627344.host, call_21627344.base,
                               call_21627344.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627344, uri, valid, _)

proc call*(call_21627345: Call_UpdateConferenceProvider_21627332; body: JsonNode): Recallable =
  ## updateConferenceProvider
  ## Updates an existing conference provider's settings.
  ##   body: JObject (required)
  var body_21627346 = newJObject()
  if body != nil:
    body_21627346 = body
  result = call_21627345.call(nil, nil, nil, nil, body_21627346)

var updateConferenceProvider* = Call_UpdateConferenceProvider_21627332(
    name: "updateConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateConferenceProvider",
    validator: validate_UpdateConferenceProvider_21627333, base: "/",
    makeUrl: url_UpdateConferenceProvider_21627334,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContact_21627347 = ref object of OpenApiRestCall_21625435
proc url_UpdateContact_21627349(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateContact_21627348(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627350 = header.getOrDefault("X-Amz-Date")
  valid_21627350 = validateParameter(valid_21627350, JString, required = false,
                                   default = nil)
  if valid_21627350 != nil:
    section.add "X-Amz-Date", valid_21627350
  var valid_21627351 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627351 = validateParameter(valid_21627351, JString, required = false,
                                   default = nil)
  if valid_21627351 != nil:
    section.add "X-Amz-Security-Token", valid_21627351
  var valid_21627352 = header.getOrDefault("X-Amz-Target")
  valid_21627352 = validateParameter(valid_21627352, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateContact"))
  if valid_21627352 != nil:
    section.add "X-Amz-Target", valid_21627352
  var valid_21627353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627353 = validateParameter(valid_21627353, JString, required = false,
                                   default = nil)
  if valid_21627353 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627353
  var valid_21627354 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627354 = validateParameter(valid_21627354, JString, required = false,
                                   default = nil)
  if valid_21627354 != nil:
    section.add "X-Amz-Algorithm", valid_21627354
  var valid_21627355 = header.getOrDefault("X-Amz-Signature")
  valid_21627355 = validateParameter(valid_21627355, JString, required = false,
                                   default = nil)
  if valid_21627355 != nil:
    section.add "X-Amz-Signature", valid_21627355
  var valid_21627356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627356 = validateParameter(valid_21627356, JString, required = false,
                                   default = nil)
  if valid_21627356 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627356
  var valid_21627357 = header.getOrDefault("X-Amz-Credential")
  valid_21627357 = validateParameter(valid_21627357, JString, required = false,
                                   default = nil)
  if valid_21627357 != nil:
    section.add "X-Amz-Credential", valid_21627357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627359: Call_UpdateContact_21627347; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the contact details by the contact ARN.
  ## 
  let valid = call_21627359.validator(path, query, header, formData, body, _)
  let scheme = call_21627359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627359.makeUrl(scheme.get, call_21627359.host, call_21627359.base,
                               call_21627359.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627359, uri, valid, _)

proc call*(call_21627360: Call_UpdateContact_21627347; body: JsonNode): Recallable =
  ## updateContact
  ## Updates the contact details by the contact ARN.
  ##   body: JObject (required)
  var body_21627361 = newJObject()
  if body != nil:
    body_21627361 = body
  result = call_21627360.call(nil, nil, nil, nil, body_21627361)

var updateContact* = Call_UpdateContact_21627347(name: "updateContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateContact",
    validator: validate_UpdateContact_21627348, base: "/",
    makeUrl: url_UpdateContact_21627349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevice_21627362 = ref object of OpenApiRestCall_21625435
proc url_UpdateDevice_21627364(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDevice_21627363(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627365 = header.getOrDefault("X-Amz-Date")
  valid_21627365 = validateParameter(valid_21627365, JString, required = false,
                                   default = nil)
  if valid_21627365 != nil:
    section.add "X-Amz-Date", valid_21627365
  var valid_21627366 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627366 = validateParameter(valid_21627366, JString, required = false,
                                   default = nil)
  if valid_21627366 != nil:
    section.add "X-Amz-Security-Token", valid_21627366
  var valid_21627367 = header.getOrDefault("X-Amz-Target")
  valid_21627367 = validateParameter(valid_21627367, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateDevice"))
  if valid_21627367 != nil:
    section.add "X-Amz-Target", valid_21627367
  var valid_21627368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627368 = validateParameter(valid_21627368, JString, required = false,
                                   default = nil)
  if valid_21627368 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627368
  var valid_21627369 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627369 = validateParameter(valid_21627369, JString, required = false,
                                   default = nil)
  if valid_21627369 != nil:
    section.add "X-Amz-Algorithm", valid_21627369
  var valid_21627370 = header.getOrDefault("X-Amz-Signature")
  valid_21627370 = validateParameter(valid_21627370, JString, required = false,
                                   default = nil)
  if valid_21627370 != nil:
    section.add "X-Amz-Signature", valid_21627370
  var valid_21627371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627371 = validateParameter(valid_21627371, JString, required = false,
                                   default = nil)
  if valid_21627371 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627371
  var valid_21627372 = header.getOrDefault("X-Amz-Credential")
  valid_21627372 = validateParameter(valid_21627372, JString, required = false,
                                   default = nil)
  if valid_21627372 != nil:
    section.add "X-Amz-Credential", valid_21627372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627374: Call_UpdateDevice_21627362; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the device name by device ARN.
  ## 
  let valid = call_21627374.validator(path, query, header, formData, body, _)
  let scheme = call_21627374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627374.makeUrl(scheme.get, call_21627374.host, call_21627374.base,
                               call_21627374.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627374, uri, valid, _)

proc call*(call_21627375: Call_UpdateDevice_21627362; body: JsonNode): Recallable =
  ## updateDevice
  ## Updates the device name by device ARN.
  ##   body: JObject (required)
  var body_21627376 = newJObject()
  if body != nil:
    body_21627376 = body
  result = call_21627375.call(nil, nil, nil, nil, body_21627376)

var updateDevice* = Call_UpdateDevice_21627362(name: "updateDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateDevice",
    validator: validate_UpdateDevice_21627363, base: "/", makeUrl: url_UpdateDevice_21627364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGateway_21627377 = ref object of OpenApiRestCall_21625435
proc url_UpdateGateway_21627379(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGateway_21627378(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627380 = header.getOrDefault("X-Amz-Date")
  valid_21627380 = validateParameter(valid_21627380, JString, required = false,
                                   default = nil)
  if valid_21627380 != nil:
    section.add "X-Amz-Date", valid_21627380
  var valid_21627381 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627381 = validateParameter(valid_21627381, JString, required = false,
                                   default = nil)
  if valid_21627381 != nil:
    section.add "X-Amz-Security-Token", valid_21627381
  var valid_21627382 = header.getOrDefault("X-Amz-Target")
  valid_21627382 = validateParameter(valid_21627382, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateGateway"))
  if valid_21627382 != nil:
    section.add "X-Amz-Target", valid_21627382
  var valid_21627383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627383 = validateParameter(valid_21627383, JString, required = false,
                                   default = nil)
  if valid_21627383 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627383
  var valid_21627384 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627384 = validateParameter(valid_21627384, JString, required = false,
                                   default = nil)
  if valid_21627384 != nil:
    section.add "X-Amz-Algorithm", valid_21627384
  var valid_21627385 = header.getOrDefault("X-Amz-Signature")
  valid_21627385 = validateParameter(valid_21627385, JString, required = false,
                                   default = nil)
  if valid_21627385 != nil:
    section.add "X-Amz-Signature", valid_21627385
  var valid_21627386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627386 = validateParameter(valid_21627386, JString, required = false,
                                   default = nil)
  if valid_21627386 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627386
  var valid_21627387 = header.getOrDefault("X-Amz-Credential")
  valid_21627387 = validateParameter(valid_21627387, JString, required = false,
                                   default = nil)
  if valid_21627387 != nil:
    section.add "X-Amz-Credential", valid_21627387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627389: Call_UpdateGateway_21627377; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the details of a gateway. If any optional field is not provided, the existing corresponding value is left unmodified.
  ## 
  let valid = call_21627389.validator(path, query, header, formData, body, _)
  let scheme = call_21627389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627389.makeUrl(scheme.get, call_21627389.host, call_21627389.base,
                               call_21627389.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627389, uri, valid, _)

proc call*(call_21627390: Call_UpdateGateway_21627377; body: JsonNode): Recallable =
  ## updateGateway
  ## Updates the details of a gateway. If any optional field is not provided, the existing corresponding value is left unmodified.
  ##   body: JObject (required)
  var body_21627391 = newJObject()
  if body != nil:
    body_21627391 = body
  result = call_21627390.call(nil, nil, nil, nil, body_21627391)

var updateGateway* = Call_UpdateGateway_21627377(name: "updateGateway",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateGateway",
    validator: validate_UpdateGateway_21627378, base: "/",
    makeUrl: url_UpdateGateway_21627379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayGroup_21627392 = ref object of OpenApiRestCall_21625435
proc url_UpdateGatewayGroup_21627394(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGatewayGroup_21627393(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627395 = header.getOrDefault("X-Amz-Date")
  valid_21627395 = validateParameter(valid_21627395, JString, required = false,
                                   default = nil)
  if valid_21627395 != nil:
    section.add "X-Amz-Date", valid_21627395
  var valid_21627396 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627396 = validateParameter(valid_21627396, JString, required = false,
                                   default = nil)
  if valid_21627396 != nil:
    section.add "X-Amz-Security-Token", valid_21627396
  var valid_21627397 = header.getOrDefault("X-Amz-Target")
  valid_21627397 = validateParameter(valid_21627397, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateGatewayGroup"))
  if valid_21627397 != nil:
    section.add "X-Amz-Target", valid_21627397
  var valid_21627398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627398 = validateParameter(valid_21627398, JString, required = false,
                                   default = nil)
  if valid_21627398 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627398
  var valid_21627399 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627399 = validateParameter(valid_21627399, JString, required = false,
                                   default = nil)
  if valid_21627399 != nil:
    section.add "X-Amz-Algorithm", valid_21627399
  var valid_21627400 = header.getOrDefault("X-Amz-Signature")
  valid_21627400 = validateParameter(valid_21627400, JString, required = false,
                                   default = nil)
  if valid_21627400 != nil:
    section.add "X-Amz-Signature", valid_21627400
  var valid_21627401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627401 = validateParameter(valid_21627401, JString, required = false,
                                   default = nil)
  if valid_21627401 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627401
  var valid_21627402 = header.getOrDefault("X-Amz-Credential")
  valid_21627402 = validateParameter(valid_21627402, JString, required = false,
                                   default = nil)
  if valid_21627402 != nil:
    section.add "X-Amz-Credential", valid_21627402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627404: Call_UpdateGatewayGroup_21627392; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the details of a gateway group. If any optional field is not provided, the existing corresponding value is left unmodified.
  ## 
  let valid = call_21627404.validator(path, query, header, formData, body, _)
  let scheme = call_21627404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627404.makeUrl(scheme.get, call_21627404.host, call_21627404.base,
                               call_21627404.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627404, uri, valid, _)

proc call*(call_21627405: Call_UpdateGatewayGroup_21627392; body: JsonNode): Recallable =
  ## updateGatewayGroup
  ## Updates the details of a gateway group. If any optional field is not provided, the existing corresponding value is left unmodified.
  ##   body: JObject (required)
  var body_21627406 = newJObject()
  if body != nil:
    body_21627406 = body
  result = call_21627405.call(nil, nil, nil, nil, body_21627406)

var updateGatewayGroup* = Call_UpdateGatewayGroup_21627392(
    name: "updateGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateGatewayGroup",
    validator: validate_UpdateGatewayGroup_21627393, base: "/",
    makeUrl: url_UpdateGatewayGroup_21627394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_21627407 = ref object of OpenApiRestCall_21625435
proc url_UpdateNetworkProfile_21627409(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNetworkProfile_21627408(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627410 = header.getOrDefault("X-Amz-Date")
  valid_21627410 = validateParameter(valid_21627410, JString, required = false,
                                   default = nil)
  if valid_21627410 != nil:
    section.add "X-Amz-Date", valid_21627410
  var valid_21627411 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627411 = validateParameter(valid_21627411, JString, required = false,
                                   default = nil)
  if valid_21627411 != nil:
    section.add "X-Amz-Security-Token", valid_21627411
  var valid_21627412 = header.getOrDefault("X-Amz-Target")
  valid_21627412 = validateParameter(valid_21627412, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateNetworkProfile"))
  if valid_21627412 != nil:
    section.add "X-Amz-Target", valid_21627412
  var valid_21627413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627413 = validateParameter(valid_21627413, JString, required = false,
                                   default = nil)
  if valid_21627413 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627413
  var valid_21627414 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627414 = validateParameter(valid_21627414, JString, required = false,
                                   default = nil)
  if valid_21627414 != nil:
    section.add "X-Amz-Algorithm", valid_21627414
  var valid_21627415 = header.getOrDefault("X-Amz-Signature")
  valid_21627415 = validateParameter(valid_21627415, JString, required = false,
                                   default = nil)
  if valid_21627415 != nil:
    section.add "X-Amz-Signature", valid_21627415
  var valid_21627416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627416 = validateParameter(valid_21627416, JString, required = false,
                                   default = nil)
  if valid_21627416 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627416
  var valid_21627417 = header.getOrDefault("X-Amz-Credential")
  valid_21627417 = validateParameter(valid_21627417, JString, required = false,
                                   default = nil)
  if valid_21627417 != nil:
    section.add "X-Amz-Credential", valid_21627417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627419: Call_UpdateNetworkProfile_21627407; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a network profile by the network profile ARN.
  ## 
  let valid = call_21627419.validator(path, query, header, formData, body, _)
  let scheme = call_21627419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627419.makeUrl(scheme.get, call_21627419.host, call_21627419.base,
                               call_21627419.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627419, uri, valid, _)

proc call*(call_21627420: Call_UpdateNetworkProfile_21627407; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates a network profile by the network profile ARN.
  ##   body: JObject (required)
  var body_21627421 = newJObject()
  if body != nil:
    body_21627421 = body
  result = call_21627420.call(nil, nil, nil, nil, body_21627421)

var updateNetworkProfile* = Call_UpdateNetworkProfile_21627407(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_21627408, base: "/",
    makeUrl: url_UpdateNetworkProfile_21627409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProfile_21627422 = ref object of OpenApiRestCall_21625435
proc url_UpdateProfile_21627424(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProfile_21627423(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627425 = header.getOrDefault("X-Amz-Date")
  valid_21627425 = validateParameter(valid_21627425, JString, required = false,
                                   default = nil)
  if valid_21627425 != nil:
    section.add "X-Amz-Date", valid_21627425
  var valid_21627426 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627426 = validateParameter(valid_21627426, JString, required = false,
                                   default = nil)
  if valid_21627426 != nil:
    section.add "X-Amz-Security-Token", valid_21627426
  var valid_21627427 = header.getOrDefault("X-Amz-Target")
  valid_21627427 = validateParameter(valid_21627427, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateProfile"))
  if valid_21627427 != nil:
    section.add "X-Amz-Target", valid_21627427
  var valid_21627428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627428 = validateParameter(valid_21627428, JString, required = false,
                                   default = nil)
  if valid_21627428 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627428
  var valid_21627429 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627429 = validateParameter(valid_21627429, JString, required = false,
                                   default = nil)
  if valid_21627429 != nil:
    section.add "X-Amz-Algorithm", valid_21627429
  var valid_21627430 = header.getOrDefault("X-Amz-Signature")
  valid_21627430 = validateParameter(valid_21627430, JString, required = false,
                                   default = nil)
  if valid_21627430 != nil:
    section.add "X-Amz-Signature", valid_21627430
  var valid_21627431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627431 = validateParameter(valid_21627431, JString, required = false,
                                   default = nil)
  if valid_21627431 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627431
  var valid_21627432 = header.getOrDefault("X-Amz-Credential")
  valid_21627432 = validateParameter(valid_21627432, JString, required = false,
                                   default = nil)
  if valid_21627432 != nil:
    section.add "X-Amz-Credential", valid_21627432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627434: Call_UpdateProfile_21627422; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing room profile by room profile ARN.
  ## 
  let valid = call_21627434.validator(path, query, header, formData, body, _)
  let scheme = call_21627434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627434.makeUrl(scheme.get, call_21627434.host, call_21627434.base,
                               call_21627434.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627434, uri, valid, _)

proc call*(call_21627435: Call_UpdateProfile_21627422; body: JsonNode): Recallable =
  ## updateProfile
  ## Updates an existing room profile by room profile ARN.
  ##   body: JObject (required)
  var body_21627436 = newJObject()
  if body != nil:
    body_21627436 = body
  result = call_21627435.call(nil, nil, nil, nil, body_21627436)

var updateProfile* = Call_UpdateProfile_21627422(name: "updateProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateProfile",
    validator: validate_UpdateProfile_21627423, base: "/",
    makeUrl: url_UpdateProfile_21627424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoom_21627437 = ref object of OpenApiRestCall_21625435
proc url_UpdateRoom_21627439(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRoom_21627438(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627440 = header.getOrDefault("X-Amz-Date")
  valid_21627440 = validateParameter(valid_21627440, JString, required = false,
                                   default = nil)
  if valid_21627440 != nil:
    section.add "X-Amz-Date", valid_21627440
  var valid_21627441 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627441 = validateParameter(valid_21627441, JString, required = false,
                                   default = nil)
  if valid_21627441 != nil:
    section.add "X-Amz-Security-Token", valid_21627441
  var valid_21627442 = header.getOrDefault("X-Amz-Target")
  valid_21627442 = validateParameter(valid_21627442, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateRoom"))
  if valid_21627442 != nil:
    section.add "X-Amz-Target", valid_21627442
  var valid_21627443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627443 = validateParameter(valid_21627443, JString, required = false,
                                   default = nil)
  if valid_21627443 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627443
  var valid_21627444 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627444 = validateParameter(valid_21627444, JString, required = false,
                                   default = nil)
  if valid_21627444 != nil:
    section.add "X-Amz-Algorithm", valid_21627444
  var valid_21627445 = header.getOrDefault("X-Amz-Signature")
  valid_21627445 = validateParameter(valid_21627445, JString, required = false,
                                   default = nil)
  if valid_21627445 != nil:
    section.add "X-Amz-Signature", valid_21627445
  var valid_21627446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627446 = validateParameter(valid_21627446, JString, required = false,
                                   default = nil)
  if valid_21627446 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627446
  var valid_21627447 = header.getOrDefault("X-Amz-Credential")
  valid_21627447 = validateParameter(valid_21627447, JString, required = false,
                                   default = nil)
  if valid_21627447 != nil:
    section.add "X-Amz-Credential", valid_21627447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627449: Call_UpdateRoom_21627437; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates room details by room ARN.
  ## 
  let valid = call_21627449.validator(path, query, header, formData, body, _)
  let scheme = call_21627449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627449.makeUrl(scheme.get, call_21627449.host, call_21627449.base,
                               call_21627449.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627449, uri, valid, _)

proc call*(call_21627450: Call_UpdateRoom_21627437; body: JsonNode): Recallable =
  ## updateRoom
  ## Updates room details by room ARN.
  ##   body: JObject (required)
  var body_21627451 = newJObject()
  if body != nil:
    body_21627451 = body
  result = call_21627450.call(nil, nil, nil, nil, body_21627451)

var updateRoom* = Call_UpdateRoom_21627437(name: "updateRoom",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.UpdateRoom",
                                        validator: validate_UpdateRoom_21627438,
                                        base: "/", makeUrl: url_UpdateRoom_21627439,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSkillGroup_21627452 = ref object of OpenApiRestCall_21625435
proc url_UpdateSkillGroup_21627454(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSkillGroup_21627453(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627455 = header.getOrDefault("X-Amz-Date")
  valid_21627455 = validateParameter(valid_21627455, JString, required = false,
                                   default = nil)
  if valid_21627455 != nil:
    section.add "X-Amz-Date", valid_21627455
  var valid_21627456 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627456 = validateParameter(valid_21627456, JString, required = false,
                                   default = nil)
  if valid_21627456 != nil:
    section.add "X-Amz-Security-Token", valid_21627456
  var valid_21627457 = header.getOrDefault("X-Amz-Target")
  valid_21627457 = validateParameter(valid_21627457, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateSkillGroup"))
  if valid_21627457 != nil:
    section.add "X-Amz-Target", valid_21627457
  var valid_21627458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627458 = validateParameter(valid_21627458, JString, required = false,
                                   default = nil)
  if valid_21627458 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627458
  var valid_21627459 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627459 = validateParameter(valid_21627459, JString, required = false,
                                   default = nil)
  if valid_21627459 != nil:
    section.add "X-Amz-Algorithm", valid_21627459
  var valid_21627460 = header.getOrDefault("X-Amz-Signature")
  valid_21627460 = validateParameter(valid_21627460, JString, required = false,
                                   default = nil)
  if valid_21627460 != nil:
    section.add "X-Amz-Signature", valid_21627460
  var valid_21627461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627461 = validateParameter(valid_21627461, JString, required = false,
                                   default = nil)
  if valid_21627461 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627461
  var valid_21627462 = header.getOrDefault("X-Amz-Credential")
  valid_21627462 = validateParameter(valid_21627462, JString, required = false,
                                   default = nil)
  if valid_21627462 != nil:
    section.add "X-Amz-Credential", valid_21627462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627464: Call_UpdateSkillGroup_21627452; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates skill group details by skill group ARN.
  ## 
  let valid = call_21627464.validator(path, query, header, formData, body, _)
  let scheme = call_21627464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627464.makeUrl(scheme.get, call_21627464.host, call_21627464.base,
                               call_21627464.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627464, uri, valid, _)

proc call*(call_21627465: Call_UpdateSkillGroup_21627452; body: JsonNode): Recallable =
  ## updateSkillGroup
  ## Updates skill group details by skill group ARN.
  ##   body: JObject (required)
  var body_21627466 = newJObject()
  if body != nil:
    body_21627466 = body
  result = call_21627465.call(nil, nil, nil, nil, body_21627466)

var updateSkillGroup* = Call_UpdateSkillGroup_21627452(name: "updateSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateSkillGroup",
    validator: validate_UpdateSkillGroup_21627453, base: "/",
    makeUrl: url_UpdateSkillGroup_21627454, schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}