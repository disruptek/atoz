
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
  Call_ApproveSkill_600774 = ref object of OpenApiRestCall_600437
proc url_ApproveSkill_600776(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ApproveSkill_600775(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600903 = header.getOrDefault("X-Amz-Target")
  valid_600903 = validateParameter(valid_600903, JString, required = true, default = newJString(
      "AlexaForBusiness.ApproveSkill"))
  if valid_600903 != nil:
    section.add "X-Amz-Target", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Content-Sha256", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Algorithm")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Algorithm", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Signature")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Signature", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-SignedHeaders", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Credential")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Credential", valid_600908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600932: Call_ApproveSkill_600774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill with the organization under the customer's AWS account. If a skill is private, the user implicitly accepts access to this skill during enablement.
  ## 
  let valid = call_600932.validator(path, query, header, formData, body)
  let scheme = call_600932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600932.url(scheme.get, call_600932.host, call_600932.base,
                         call_600932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600932, url, valid)

proc call*(call_601003: Call_ApproveSkill_600774; body: JsonNode): Recallable =
  ## approveSkill
  ## Associates a skill with the organization under the customer's AWS account. If a skill is private, the user implicitly accepts access to this skill during enablement.
  ##   body: JObject (required)
  var body_601004 = newJObject()
  if body != nil:
    body_601004 = body
  result = call_601003.call(nil, nil, nil, nil, body_601004)

var approveSkill* = Call_ApproveSkill_600774(name: "approveSkill",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ApproveSkill",
    validator: validate_ApproveSkill_600775, base: "/", url: url_ApproveSkill_600776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateContactWithAddressBook_601043 = ref object of OpenApiRestCall_600437
proc url_AssociateContactWithAddressBook_601045(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateContactWithAddressBook_601044(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601048 = header.getOrDefault("X-Amz-Target")
  valid_601048 = validateParameter(valid_601048, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateContactWithAddressBook"))
  if valid_601048 != nil:
    section.add "X-Amz-Target", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Content-Sha256", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Algorithm")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Algorithm", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Signature")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Signature", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-SignedHeaders", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Credential")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Credential", valid_601053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601055: Call_AssociateContactWithAddressBook_601043;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a contact with a given address book.
  ## 
  let valid = call_601055.validator(path, query, header, formData, body)
  let scheme = call_601055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601055.url(scheme.get, call_601055.host, call_601055.base,
                         call_601055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601055, url, valid)

proc call*(call_601056: Call_AssociateContactWithAddressBook_601043; body: JsonNode): Recallable =
  ## associateContactWithAddressBook
  ## Associates a contact with a given address book.
  ##   body: JObject (required)
  var body_601057 = newJObject()
  if body != nil:
    body_601057 = body
  result = call_601056.call(nil, nil, nil, nil, body_601057)

var associateContactWithAddressBook* = Call_AssociateContactWithAddressBook_601043(
    name: "associateContactWithAddressBook", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateContactWithAddressBook",
    validator: validate_AssociateContactWithAddressBook_601044, base: "/",
    url: url_AssociateContactWithAddressBook_601045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateDeviceWithNetworkProfile_601058 = ref object of OpenApiRestCall_600437
proc url_AssociateDeviceWithNetworkProfile_601060(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateDeviceWithNetworkProfile_601059(path: JsonNode;
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
  var valid_601061 = header.getOrDefault("X-Amz-Date")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Date", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Security-Token")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Security-Token", valid_601062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601063 = header.getOrDefault("X-Amz-Target")
  valid_601063 = validateParameter(valid_601063, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateDeviceWithNetworkProfile"))
  if valid_601063 != nil:
    section.add "X-Amz-Target", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Content-Sha256", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Algorithm")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Algorithm", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Signature")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Signature", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-SignedHeaders", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Credential")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Credential", valid_601068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601070: Call_AssociateDeviceWithNetworkProfile_601058;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a device with the specified network profile.
  ## 
  let valid = call_601070.validator(path, query, header, formData, body)
  let scheme = call_601070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601070.url(scheme.get, call_601070.host, call_601070.base,
                         call_601070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601070, url, valid)

proc call*(call_601071: Call_AssociateDeviceWithNetworkProfile_601058;
          body: JsonNode): Recallable =
  ## associateDeviceWithNetworkProfile
  ## Associates a device with the specified network profile.
  ##   body: JObject (required)
  var body_601072 = newJObject()
  if body != nil:
    body_601072 = body
  result = call_601071.call(nil, nil, nil, nil, body_601072)

var associateDeviceWithNetworkProfile* = Call_AssociateDeviceWithNetworkProfile_601058(
    name: "associateDeviceWithNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateDeviceWithNetworkProfile",
    validator: validate_AssociateDeviceWithNetworkProfile_601059, base: "/",
    url: url_AssociateDeviceWithNetworkProfile_601060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateDeviceWithRoom_601073 = ref object of OpenApiRestCall_600437
proc url_AssociateDeviceWithRoom_601075(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateDeviceWithRoom_601074(path: JsonNode; query: JsonNode;
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
  var valid_601076 = header.getOrDefault("X-Amz-Date")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Date", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Security-Token")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Security-Token", valid_601077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601078 = header.getOrDefault("X-Amz-Target")
  valid_601078 = validateParameter(valid_601078, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateDeviceWithRoom"))
  if valid_601078 != nil:
    section.add "X-Amz-Target", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Content-Sha256", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Algorithm")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Algorithm", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Signature")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Signature", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-SignedHeaders", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Credential")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Credential", valid_601083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601085: Call_AssociateDeviceWithRoom_601073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a device with a given room. This applies all the settings from the room profile to the device, and all the skills in any skill groups added to that room. This operation requires the device to be online, or else a manual sync is required. 
  ## 
  let valid = call_601085.validator(path, query, header, formData, body)
  let scheme = call_601085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601085.url(scheme.get, call_601085.host, call_601085.base,
                         call_601085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601085, url, valid)

proc call*(call_601086: Call_AssociateDeviceWithRoom_601073; body: JsonNode): Recallable =
  ## associateDeviceWithRoom
  ## Associates a device with a given room. This applies all the settings from the room profile to the device, and all the skills in any skill groups added to that room. This operation requires the device to be online, or else a manual sync is required. 
  ##   body: JObject (required)
  var body_601087 = newJObject()
  if body != nil:
    body_601087 = body
  result = call_601086.call(nil, nil, nil, nil, body_601087)

var associateDeviceWithRoom* = Call_AssociateDeviceWithRoom_601073(
    name: "associateDeviceWithRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateDeviceWithRoom",
    validator: validate_AssociateDeviceWithRoom_601074, base: "/",
    url: url_AssociateDeviceWithRoom_601075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillGroupWithRoom_601088 = ref object of OpenApiRestCall_600437
proc url_AssociateSkillGroupWithRoom_601090(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateSkillGroupWithRoom_601089(path: JsonNode; query: JsonNode;
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
  var valid_601091 = header.getOrDefault("X-Amz-Date")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Date", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Security-Token")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Security-Token", valid_601092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601093 = header.getOrDefault("X-Amz-Target")
  valid_601093 = validateParameter(valid_601093, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillGroupWithRoom"))
  if valid_601093 != nil:
    section.add "X-Amz-Target", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Content-Sha256", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Algorithm")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Algorithm", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Signature")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Signature", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-SignedHeaders", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Credential")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Credential", valid_601098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601100: Call_AssociateSkillGroupWithRoom_601088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill group with a given room. This enables all skills in the associated skill group on all devices in the room.
  ## 
  let valid = call_601100.validator(path, query, header, formData, body)
  let scheme = call_601100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601100.url(scheme.get, call_601100.host, call_601100.base,
                         call_601100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601100, url, valid)

proc call*(call_601101: Call_AssociateSkillGroupWithRoom_601088; body: JsonNode): Recallable =
  ## associateSkillGroupWithRoom
  ## Associates a skill group with a given room. This enables all skills in the associated skill group on all devices in the room.
  ##   body: JObject (required)
  var body_601102 = newJObject()
  if body != nil:
    body_601102 = body
  result = call_601101.call(nil, nil, nil, nil, body_601102)

var associateSkillGroupWithRoom* = Call_AssociateSkillGroupWithRoom_601088(
    name: "associateSkillGroupWithRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillGroupWithRoom",
    validator: validate_AssociateSkillGroupWithRoom_601089, base: "/",
    url: url_AssociateSkillGroupWithRoom_601090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillWithSkillGroup_601103 = ref object of OpenApiRestCall_600437
proc url_AssociateSkillWithSkillGroup_601105(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateSkillWithSkillGroup_601104(path: JsonNode; query: JsonNode;
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
  var valid_601106 = header.getOrDefault("X-Amz-Date")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Date", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Security-Token")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Security-Token", valid_601107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601108 = header.getOrDefault("X-Amz-Target")
  valid_601108 = validateParameter(valid_601108, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillWithSkillGroup"))
  if valid_601108 != nil:
    section.add "X-Amz-Target", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Content-Sha256", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Algorithm")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Algorithm", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Signature")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Signature", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-SignedHeaders", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Credential")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Credential", valid_601113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601115: Call_AssociateSkillWithSkillGroup_601103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a skill with a skill group.
  ## 
  let valid = call_601115.validator(path, query, header, formData, body)
  let scheme = call_601115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601115.url(scheme.get, call_601115.host, call_601115.base,
                         call_601115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601115, url, valid)

proc call*(call_601116: Call_AssociateSkillWithSkillGroup_601103; body: JsonNode): Recallable =
  ## associateSkillWithSkillGroup
  ## Associates a skill with a skill group.
  ##   body: JObject (required)
  var body_601117 = newJObject()
  if body != nil:
    body_601117 = body
  result = call_601116.call(nil, nil, nil, nil, body_601117)

var associateSkillWithSkillGroup* = Call_AssociateSkillWithSkillGroup_601103(
    name: "associateSkillWithSkillGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillWithSkillGroup",
    validator: validate_AssociateSkillWithSkillGroup_601104, base: "/",
    url: url_AssociateSkillWithSkillGroup_601105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateSkillWithUsers_601118 = ref object of OpenApiRestCall_600437
proc url_AssociateSkillWithUsers_601120(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateSkillWithUsers_601119(path: JsonNode; query: JsonNode;
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
  var valid_601121 = header.getOrDefault("X-Amz-Date")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Date", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Security-Token")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Security-Token", valid_601122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601123 = header.getOrDefault("X-Amz-Target")
  valid_601123 = validateParameter(valid_601123, JString, required = true, default = newJString(
      "AlexaForBusiness.AssociateSkillWithUsers"))
  if valid_601123 != nil:
    section.add "X-Amz-Target", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Content-Sha256", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Algorithm")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Algorithm", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Signature")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Signature", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-SignedHeaders", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Credential")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Credential", valid_601128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601130: Call_AssociateSkillWithUsers_601118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Makes a private skill available for enrolled users to enable on their devices.
  ## 
  let valid = call_601130.validator(path, query, header, formData, body)
  let scheme = call_601130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601130.url(scheme.get, call_601130.host, call_601130.base,
                         call_601130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601130, url, valid)

proc call*(call_601131: Call_AssociateSkillWithUsers_601118; body: JsonNode): Recallable =
  ## associateSkillWithUsers
  ## Makes a private skill available for enrolled users to enable on their devices.
  ##   body: JObject (required)
  var body_601132 = newJObject()
  if body != nil:
    body_601132 = body
  result = call_601131.call(nil, nil, nil, nil, body_601132)

var associateSkillWithUsers* = Call_AssociateSkillWithUsers_601118(
    name: "associateSkillWithUsers", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.AssociateSkillWithUsers",
    validator: validate_AssociateSkillWithUsers_601119, base: "/",
    url: url_AssociateSkillWithUsers_601120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAddressBook_601133 = ref object of OpenApiRestCall_600437
proc url_CreateAddressBook_601135(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAddressBook_601134(path: JsonNode; query: JsonNode;
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
  var valid_601136 = header.getOrDefault("X-Amz-Date")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Date", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Security-Token")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Security-Token", valid_601137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601138 = header.getOrDefault("X-Amz-Target")
  valid_601138 = validateParameter(valid_601138, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateAddressBook"))
  if valid_601138 != nil:
    section.add "X-Amz-Target", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Content-Sha256", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Algorithm")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Algorithm", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Signature")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Signature", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-SignedHeaders", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Credential")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Credential", valid_601143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601145: Call_CreateAddressBook_601133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an address book with the specified details.
  ## 
  let valid = call_601145.validator(path, query, header, formData, body)
  let scheme = call_601145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601145.url(scheme.get, call_601145.host, call_601145.base,
                         call_601145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601145, url, valid)

proc call*(call_601146: Call_CreateAddressBook_601133; body: JsonNode): Recallable =
  ## createAddressBook
  ## Creates an address book with the specified details.
  ##   body: JObject (required)
  var body_601147 = newJObject()
  if body != nil:
    body_601147 = body
  result = call_601146.call(nil, nil, nil, nil, body_601147)

var createAddressBook* = Call_CreateAddressBook_601133(name: "createAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateAddressBook",
    validator: validate_CreateAddressBook_601134, base: "/",
    url: url_CreateAddressBook_601135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBusinessReportSchedule_601148 = ref object of OpenApiRestCall_600437
proc url_CreateBusinessReportSchedule_601150(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateBusinessReportSchedule_601149(path: JsonNode; query: JsonNode;
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
  var valid_601151 = header.getOrDefault("X-Amz-Date")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Date", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Security-Token")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Security-Token", valid_601152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601153 = header.getOrDefault("X-Amz-Target")
  valid_601153 = validateParameter(valid_601153, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateBusinessReportSchedule"))
  if valid_601153 != nil:
    section.add "X-Amz-Target", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Content-Sha256", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Algorithm")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Algorithm", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Signature")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Signature", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-SignedHeaders", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Credential")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Credential", valid_601158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601160: Call_CreateBusinessReportSchedule_601148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a recurring schedule for usage reports to deliver to the specified S3 location with a specified daily or weekly interval.
  ## 
  let valid = call_601160.validator(path, query, header, formData, body)
  let scheme = call_601160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601160.url(scheme.get, call_601160.host, call_601160.base,
                         call_601160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601160, url, valid)

proc call*(call_601161: Call_CreateBusinessReportSchedule_601148; body: JsonNode): Recallable =
  ## createBusinessReportSchedule
  ## Creates a recurring schedule for usage reports to deliver to the specified S3 location with a specified daily or weekly interval.
  ##   body: JObject (required)
  var body_601162 = newJObject()
  if body != nil:
    body_601162 = body
  result = call_601161.call(nil, nil, nil, nil, body_601162)

var createBusinessReportSchedule* = Call_CreateBusinessReportSchedule_601148(
    name: "createBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateBusinessReportSchedule",
    validator: validate_CreateBusinessReportSchedule_601149, base: "/",
    url: url_CreateBusinessReportSchedule_601150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConferenceProvider_601163 = ref object of OpenApiRestCall_600437
proc url_CreateConferenceProvider_601165(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConferenceProvider_601164(path: JsonNode; query: JsonNode;
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
  var valid_601166 = header.getOrDefault("X-Amz-Date")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Date", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Security-Token")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Security-Token", valid_601167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601168 = header.getOrDefault("X-Amz-Target")
  valid_601168 = validateParameter(valid_601168, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateConferenceProvider"))
  if valid_601168 != nil:
    section.add "X-Amz-Target", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Content-Sha256", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Algorithm")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Algorithm", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Signature")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Signature", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-SignedHeaders", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Credential")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Credential", valid_601173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601175: Call_CreateConferenceProvider_601163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new conference provider under the user's AWS account.
  ## 
  let valid = call_601175.validator(path, query, header, formData, body)
  let scheme = call_601175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601175.url(scheme.get, call_601175.host, call_601175.base,
                         call_601175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601175, url, valid)

proc call*(call_601176: Call_CreateConferenceProvider_601163; body: JsonNode): Recallable =
  ## createConferenceProvider
  ## Adds a new conference provider under the user's AWS account.
  ##   body: JObject (required)
  var body_601177 = newJObject()
  if body != nil:
    body_601177 = body
  result = call_601176.call(nil, nil, nil, nil, body_601177)

var createConferenceProvider* = Call_CreateConferenceProvider_601163(
    name: "createConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateConferenceProvider",
    validator: validate_CreateConferenceProvider_601164, base: "/",
    url: url_CreateConferenceProvider_601165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateContact_601178 = ref object of OpenApiRestCall_600437
proc url_CreateContact_601180(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateContact_601179(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601181 = header.getOrDefault("X-Amz-Date")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Date", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Security-Token")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Security-Token", valid_601182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601183 = header.getOrDefault("X-Amz-Target")
  valid_601183 = validateParameter(valid_601183, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateContact"))
  if valid_601183 != nil:
    section.add "X-Amz-Target", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Content-Sha256", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Algorithm")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Algorithm", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Signature")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Signature", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-SignedHeaders", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Credential")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Credential", valid_601188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601190: Call_CreateContact_601178; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a contact with the specified details.
  ## 
  let valid = call_601190.validator(path, query, header, formData, body)
  let scheme = call_601190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601190.url(scheme.get, call_601190.host, call_601190.base,
                         call_601190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601190, url, valid)

proc call*(call_601191: Call_CreateContact_601178; body: JsonNode): Recallable =
  ## createContact
  ## Creates a contact with the specified details.
  ##   body: JObject (required)
  var body_601192 = newJObject()
  if body != nil:
    body_601192 = body
  result = call_601191.call(nil, nil, nil, nil, body_601192)

var createContact* = Call_CreateContact_601178(name: "createContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateContact",
    validator: validate_CreateContact_601179, base: "/", url: url_CreateContact_601180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGatewayGroup_601193 = ref object of OpenApiRestCall_600437
proc url_CreateGatewayGroup_601195(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateGatewayGroup_601194(path: JsonNode; query: JsonNode;
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
  var valid_601196 = header.getOrDefault("X-Amz-Date")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Date", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Security-Token")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Security-Token", valid_601197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601198 = header.getOrDefault("X-Amz-Target")
  valid_601198 = validateParameter(valid_601198, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateGatewayGroup"))
  if valid_601198 != nil:
    section.add "X-Amz-Target", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Content-Sha256", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Algorithm")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Algorithm", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Signature")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Signature", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-SignedHeaders", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Credential")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Credential", valid_601203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601205: Call_CreateGatewayGroup_601193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a gateway group with the specified details.
  ## 
  let valid = call_601205.validator(path, query, header, formData, body)
  let scheme = call_601205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601205.url(scheme.get, call_601205.host, call_601205.base,
                         call_601205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601205, url, valid)

proc call*(call_601206: Call_CreateGatewayGroup_601193; body: JsonNode): Recallable =
  ## createGatewayGroup
  ## Creates a gateway group with the specified details.
  ##   body: JObject (required)
  var body_601207 = newJObject()
  if body != nil:
    body_601207 = body
  result = call_601206.call(nil, nil, nil, nil, body_601207)

var createGatewayGroup* = Call_CreateGatewayGroup_601193(
    name: "createGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateGatewayGroup",
    validator: validate_CreateGatewayGroup_601194, base: "/",
    url: url_CreateGatewayGroup_601195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNetworkProfile_601208 = ref object of OpenApiRestCall_600437
proc url_CreateNetworkProfile_601210(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateNetworkProfile_601209(path: JsonNode; query: JsonNode;
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
  var valid_601211 = header.getOrDefault("X-Amz-Date")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Date", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Security-Token")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Security-Token", valid_601212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601213 = header.getOrDefault("X-Amz-Target")
  valid_601213 = validateParameter(valid_601213, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateNetworkProfile"))
  if valid_601213 != nil:
    section.add "X-Amz-Target", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Content-Sha256", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Algorithm")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Algorithm", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Signature")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Signature", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-SignedHeaders", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Credential")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Credential", valid_601218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601220: Call_CreateNetworkProfile_601208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a network profile with the specified details.
  ## 
  let valid = call_601220.validator(path, query, header, formData, body)
  let scheme = call_601220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601220.url(scheme.get, call_601220.host, call_601220.base,
                         call_601220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601220, url, valid)

proc call*(call_601221: Call_CreateNetworkProfile_601208; body: JsonNode): Recallable =
  ## createNetworkProfile
  ## Creates a network profile with the specified details.
  ##   body: JObject (required)
  var body_601222 = newJObject()
  if body != nil:
    body_601222 = body
  result = call_601221.call(nil, nil, nil, nil, body_601222)

var createNetworkProfile* = Call_CreateNetworkProfile_601208(
    name: "createNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateNetworkProfile",
    validator: validate_CreateNetworkProfile_601209, base: "/",
    url: url_CreateNetworkProfile_601210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProfile_601223 = ref object of OpenApiRestCall_600437
proc url_CreateProfile_601225(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProfile_601224(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601226 = header.getOrDefault("X-Amz-Date")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Date", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Security-Token")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Security-Token", valid_601227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601228 = header.getOrDefault("X-Amz-Target")
  valid_601228 = validateParameter(valid_601228, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateProfile"))
  if valid_601228 != nil:
    section.add "X-Amz-Target", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Content-Sha256", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Algorithm")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Algorithm", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Signature")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Signature", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-SignedHeaders", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Credential")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Credential", valid_601233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601235: Call_CreateProfile_601223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new room profile with the specified details.
  ## 
  let valid = call_601235.validator(path, query, header, formData, body)
  let scheme = call_601235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601235.url(scheme.get, call_601235.host, call_601235.base,
                         call_601235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601235, url, valid)

proc call*(call_601236: Call_CreateProfile_601223; body: JsonNode): Recallable =
  ## createProfile
  ## Creates a new room profile with the specified details.
  ##   body: JObject (required)
  var body_601237 = newJObject()
  if body != nil:
    body_601237 = body
  result = call_601236.call(nil, nil, nil, nil, body_601237)

var createProfile* = Call_CreateProfile_601223(name: "createProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateProfile",
    validator: validate_CreateProfile_601224, base: "/", url: url_CreateProfile_601225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoom_601238 = ref object of OpenApiRestCall_600437
proc url_CreateRoom_601240(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRoom_601239(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601241 = header.getOrDefault("X-Amz-Date")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Date", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Security-Token")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Security-Token", valid_601242
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601243 = header.getOrDefault("X-Amz-Target")
  valid_601243 = validateParameter(valid_601243, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateRoom"))
  if valid_601243 != nil:
    section.add "X-Amz-Target", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Content-Sha256", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Algorithm")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Algorithm", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Signature")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Signature", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-SignedHeaders", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Credential")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Credential", valid_601248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601250: Call_CreateRoom_601238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a room with the specified details.
  ## 
  let valid = call_601250.validator(path, query, header, formData, body)
  let scheme = call_601250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601250.url(scheme.get, call_601250.host, call_601250.base,
                         call_601250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601250, url, valid)

proc call*(call_601251: Call_CreateRoom_601238; body: JsonNode): Recallable =
  ## createRoom
  ## Creates a room with the specified details.
  ##   body: JObject (required)
  var body_601252 = newJObject()
  if body != nil:
    body_601252 = body
  result = call_601251.call(nil, nil, nil, nil, body_601252)

var createRoom* = Call_CreateRoom_601238(name: "createRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.CreateRoom",
                                      validator: validate_CreateRoom_601239,
                                      base: "/", url: url_CreateRoom_601240,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSkillGroup_601253 = ref object of OpenApiRestCall_600437
proc url_CreateSkillGroup_601255(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSkillGroup_601254(path: JsonNode; query: JsonNode;
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
  var valid_601256 = header.getOrDefault("X-Amz-Date")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Date", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Security-Token")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Security-Token", valid_601257
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601258 = header.getOrDefault("X-Amz-Target")
  valid_601258 = validateParameter(valid_601258, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateSkillGroup"))
  if valid_601258 != nil:
    section.add "X-Amz-Target", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Content-Sha256", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Algorithm")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Algorithm", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Signature")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Signature", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-SignedHeaders", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Credential")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Credential", valid_601263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601265: Call_CreateSkillGroup_601253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a skill group with a specified name and description.
  ## 
  let valid = call_601265.validator(path, query, header, formData, body)
  let scheme = call_601265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601265.url(scheme.get, call_601265.host, call_601265.base,
                         call_601265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601265, url, valid)

proc call*(call_601266: Call_CreateSkillGroup_601253; body: JsonNode): Recallable =
  ## createSkillGroup
  ## Creates a skill group with a specified name and description.
  ##   body: JObject (required)
  var body_601267 = newJObject()
  if body != nil:
    body_601267 = body
  result = call_601266.call(nil, nil, nil, nil, body_601267)

var createSkillGroup* = Call_CreateSkillGroup_601253(name: "createSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.CreateSkillGroup",
    validator: validate_CreateSkillGroup_601254, base: "/",
    url: url_CreateSkillGroup_601255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_601268 = ref object of OpenApiRestCall_600437
proc url_CreateUser_601270(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUser_601269(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601271 = header.getOrDefault("X-Amz-Date")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Date", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Security-Token")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Security-Token", valid_601272
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601273 = header.getOrDefault("X-Amz-Target")
  valid_601273 = validateParameter(valid_601273, JString, required = true, default = newJString(
      "AlexaForBusiness.CreateUser"))
  if valid_601273 != nil:
    section.add "X-Amz-Target", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Content-Sha256", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Algorithm")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Algorithm", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Signature")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Signature", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-SignedHeaders", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-Credential")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Credential", valid_601278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601280: Call_CreateUser_601268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user.
  ## 
  let valid = call_601280.validator(path, query, header, formData, body)
  let scheme = call_601280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601280.url(scheme.get, call_601280.host, call_601280.base,
                         call_601280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601280, url, valid)

proc call*(call_601281: Call_CreateUser_601268; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user.
  ##   body: JObject (required)
  var body_601282 = newJObject()
  if body != nil:
    body_601282 = body
  result = call_601281.call(nil, nil, nil, nil, body_601282)

var createUser* = Call_CreateUser_601268(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.CreateUser",
                                      validator: validate_CreateUser_601269,
                                      base: "/", url: url_CreateUser_601270,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAddressBook_601283 = ref object of OpenApiRestCall_600437
proc url_DeleteAddressBook_601285(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteAddressBook_601284(path: JsonNode; query: JsonNode;
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
  var valid_601286 = header.getOrDefault("X-Amz-Date")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Date", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Security-Token")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Security-Token", valid_601287
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601288 = header.getOrDefault("X-Amz-Target")
  valid_601288 = validateParameter(valid_601288, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteAddressBook"))
  if valid_601288 != nil:
    section.add "X-Amz-Target", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Content-Sha256", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Algorithm")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Algorithm", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Signature")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Signature", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-SignedHeaders", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Credential")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Credential", valid_601293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601295: Call_DeleteAddressBook_601283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an address book by the address book ARN.
  ## 
  let valid = call_601295.validator(path, query, header, formData, body)
  let scheme = call_601295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601295.url(scheme.get, call_601295.host, call_601295.base,
                         call_601295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601295, url, valid)

proc call*(call_601296: Call_DeleteAddressBook_601283; body: JsonNode): Recallable =
  ## deleteAddressBook
  ## Deletes an address book by the address book ARN.
  ##   body: JObject (required)
  var body_601297 = newJObject()
  if body != nil:
    body_601297 = body
  result = call_601296.call(nil, nil, nil, nil, body_601297)

var deleteAddressBook* = Call_DeleteAddressBook_601283(name: "deleteAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteAddressBook",
    validator: validate_DeleteAddressBook_601284, base: "/",
    url: url_DeleteAddressBook_601285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBusinessReportSchedule_601298 = ref object of OpenApiRestCall_600437
proc url_DeleteBusinessReportSchedule_601300(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteBusinessReportSchedule_601299(path: JsonNode; query: JsonNode;
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
  var valid_601301 = header.getOrDefault("X-Amz-Date")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Date", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Security-Token")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Security-Token", valid_601302
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601303 = header.getOrDefault("X-Amz-Target")
  valid_601303 = validateParameter(valid_601303, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteBusinessReportSchedule"))
  if valid_601303 != nil:
    section.add "X-Amz-Target", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Content-Sha256", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Algorithm")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Algorithm", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Signature")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Signature", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-SignedHeaders", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Credential")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Credential", valid_601308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601310: Call_DeleteBusinessReportSchedule_601298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the recurring report delivery schedule with the specified schedule ARN.
  ## 
  let valid = call_601310.validator(path, query, header, formData, body)
  let scheme = call_601310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601310.url(scheme.get, call_601310.host, call_601310.base,
                         call_601310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601310, url, valid)

proc call*(call_601311: Call_DeleteBusinessReportSchedule_601298; body: JsonNode): Recallable =
  ## deleteBusinessReportSchedule
  ## Deletes the recurring report delivery schedule with the specified schedule ARN.
  ##   body: JObject (required)
  var body_601312 = newJObject()
  if body != nil:
    body_601312 = body
  result = call_601311.call(nil, nil, nil, nil, body_601312)

var deleteBusinessReportSchedule* = Call_DeleteBusinessReportSchedule_601298(
    name: "deleteBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteBusinessReportSchedule",
    validator: validate_DeleteBusinessReportSchedule_601299, base: "/",
    url: url_DeleteBusinessReportSchedule_601300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConferenceProvider_601313 = ref object of OpenApiRestCall_600437
proc url_DeleteConferenceProvider_601315(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteConferenceProvider_601314(path: JsonNode; query: JsonNode;
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
  var valid_601316 = header.getOrDefault("X-Amz-Date")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Date", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Security-Token")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Security-Token", valid_601317
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601318 = header.getOrDefault("X-Amz-Target")
  valid_601318 = validateParameter(valid_601318, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteConferenceProvider"))
  if valid_601318 != nil:
    section.add "X-Amz-Target", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Content-Sha256", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-Algorithm")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Algorithm", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-Signature")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Signature", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-SignedHeaders", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-Credential")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Credential", valid_601323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601325: Call_DeleteConferenceProvider_601313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a conference provider.
  ## 
  let valid = call_601325.validator(path, query, header, formData, body)
  let scheme = call_601325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601325.url(scheme.get, call_601325.host, call_601325.base,
                         call_601325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601325, url, valid)

proc call*(call_601326: Call_DeleteConferenceProvider_601313; body: JsonNode): Recallable =
  ## deleteConferenceProvider
  ## Deletes a conference provider.
  ##   body: JObject (required)
  var body_601327 = newJObject()
  if body != nil:
    body_601327 = body
  result = call_601326.call(nil, nil, nil, nil, body_601327)

var deleteConferenceProvider* = Call_DeleteConferenceProvider_601313(
    name: "deleteConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteConferenceProvider",
    validator: validate_DeleteConferenceProvider_601314, base: "/",
    url: url_DeleteConferenceProvider_601315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteContact_601328 = ref object of OpenApiRestCall_600437
proc url_DeleteContact_601330(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteContact_601329(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601331 = header.getOrDefault("X-Amz-Date")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Date", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Security-Token")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Security-Token", valid_601332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601333 = header.getOrDefault("X-Amz-Target")
  valid_601333 = validateParameter(valid_601333, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteContact"))
  if valid_601333 != nil:
    section.add "X-Amz-Target", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-Content-Sha256", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-Algorithm")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Algorithm", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Signature")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Signature", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-SignedHeaders", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Credential")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Credential", valid_601338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601340: Call_DeleteContact_601328; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a contact by the contact ARN.
  ## 
  let valid = call_601340.validator(path, query, header, formData, body)
  let scheme = call_601340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601340.url(scheme.get, call_601340.host, call_601340.base,
                         call_601340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601340, url, valid)

proc call*(call_601341: Call_DeleteContact_601328; body: JsonNode): Recallable =
  ## deleteContact
  ## Deletes a contact by the contact ARN.
  ##   body: JObject (required)
  var body_601342 = newJObject()
  if body != nil:
    body_601342 = body
  result = call_601341.call(nil, nil, nil, nil, body_601342)

var deleteContact* = Call_DeleteContact_601328(name: "deleteContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteContact",
    validator: validate_DeleteContact_601329, base: "/", url: url_DeleteContact_601330,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevice_601343 = ref object of OpenApiRestCall_600437
proc url_DeleteDevice_601345(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDevice_601344(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601346 = header.getOrDefault("X-Amz-Date")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Date", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Security-Token")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Security-Token", valid_601347
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601348 = header.getOrDefault("X-Amz-Target")
  valid_601348 = validateParameter(valid_601348, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteDevice"))
  if valid_601348 != nil:
    section.add "X-Amz-Target", valid_601348
  var valid_601349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Content-Sha256", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Algorithm")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Algorithm", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-Signature")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-Signature", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-SignedHeaders", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Credential")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Credential", valid_601353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601355: Call_DeleteDevice_601343; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a device from Alexa For Business.
  ## 
  let valid = call_601355.validator(path, query, header, formData, body)
  let scheme = call_601355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601355.url(scheme.get, call_601355.host, call_601355.base,
                         call_601355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601355, url, valid)

proc call*(call_601356: Call_DeleteDevice_601343; body: JsonNode): Recallable =
  ## deleteDevice
  ## Removes a device from Alexa For Business.
  ##   body: JObject (required)
  var body_601357 = newJObject()
  if body != nil:
    body_601357 = body
  result = call_601356.call(nil, nil, nil, nil, body_601357)

var deleteDevice* = Call_DeleteDevice_601343(name: "deleteDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteDevice",
    validator: validate_DeleteDevice_601344, base: "/", url: url_DeleteDevice_601345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceUsageData_601358 = ref object of OpenApiRestCall_600437
proc url_DeleteDeviceUsageData_601360(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDeviceUsageData_601359(path: JsonNode; query: JsonNode;
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
  var valid_601361 = header.getOrDefault("X-Amz-Date")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Date", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Security-Token")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Security-Token", valid_601362
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601363 = header.getOrDefault("X-Amz-Target")
  valid_601363 = validateParameter(valid_601363, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteDeviceUsageData"))
  if valid_601363 != nil:
    section.add "X-Amz-Target", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-Content-Sha256", valid_601364
  var valid_601365 = header.getOrDefault("X-Amz-Algorithm")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Algorithm", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-Signature")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Signature", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-SignedHeaders", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Credential")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Credential", valid_601368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601370: Call_DeleteDeviceUsageData_601358; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## When this action is called for a specified shared device, it allows authorized users to delete the device's entire previous history of voice input data and associated response data. This action can be called once every 24 hours for a specific shared device.
  ## 
  let valid = call_601370.validator(path, query, header, formData, body)
  let scheme = call_601370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601370.url(scheme.get, call_601370.host, call_601370.base,
                         call_601370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601370, url, valid)

proc call*(call_601371: Call_DeleteDeviceUsageData_601358; body: JsonNode): Recallable =
  ## deleteDeviceUsageData
  ## When this action is called for a specified shared device, it allows authorized users to delete the device's entire previous history of voice input data and associated response data. This action can be called once every 24 hours for a specific shared device.
  ##   body: JObject (required)
  var body_601372 = newJObject()
  if body != nil:
    body_601372 = body
  result = call_601371.call(nil, nil, nil, nil, body_601372)

var deleteDeviceUsageData* = Call_DeleteDeviceUsageData_601358(
    name: "deleteDeviceUsageData", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteDeviceUsageData",
    validator: validate_DeleteDeviceUsageData_601359, base: "/",
    url: url_DeleteDeviceUsageData_601360, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGatewayGroup_601373 = ref object of OpenApiRestCall_600437
proc url_DeleteGatewayGroup_601375(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteGatewayGroup_601374(path: JsonNode; query: JsonNode;
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
  var valid_601376 = header.getOrDefault("X-Amz-Date")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Date", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Security-Token")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Security-Token", valid_601377
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601378 = header.getOrDefault("X-Amz-Target")
  valid_601378 = validateParameter(valid_601378, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteGatewayGroup"))
  if valid_601378 != nil:
    section.add "X-Amz-Target", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Content-Sha256", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Algorithm")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Algorithm", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Signature")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Signature", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-SignedHeaders", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Credential")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Credential", valid_601383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601385: Call_DeleteGatewayGroup_601373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a gateway group.
  ## 
  let valid = call_601385.validator(path, query, header, formData, body)
  let scheme = call_601385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601385.url(scheme.get, call_601385.host, call_601385.base,
                         call_601385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601385, url, valid)

proc call*(call_601386: Call_DeleteGatewayGroup_601373; body: JsonNode): Recallable =
  ## deleteGatewayGroup
  ## Deletes a gateway group.
  ##   body: JObject (required)
  var body_601387 = newJObject()
  if body != nil:
    body_601387 = body
  result = call_601386.call(nil, nil, nil, nil, body_601387)

var deleteGatewayGroup* = Call_DeleteGatewayGroup_601373(
    name: "deleteGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteGatewayGroup",
    validator: validate_DeleteGatewayGroup_601374, base: "/",
    url: url_DeleteGatewayGroup_601375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNetworkProfile_601388 = ref object of OpenApiRestCall_600437
proc url_DeleteNetworkProfile_601390(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteNetworkProfile_601389(path: JsonNode; query: JsonNode;
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
  var valid_601391 = header.getOrDefault("X-Amz-Date")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Date", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-Security-Token")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Security-Token", valid_601392
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601393 = header.getOrDefault("X-Amz-Target")
  valid_601393 = validateParameter(valid_601393, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteNetworkProfile"))
  if valid_601393 != nil:
    section.add "X-Amz-Target", valid_601393
  var valid_601394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Content-Sha256", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Algorithm")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Algorithm", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Signature")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Signature", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-SignedHeaders", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Credential")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Credential", valid_601398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601400: Call_DeleteNetworkProfile_601388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a network profile by the network profile ARN.
  ## 
  let valid = call_601400.validator(path, query, header, formData, body)
  let scheme = call_601400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601400.url(scheme.get, call_601400.host, call_601400.base,
                         call_601400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601400, url, valid)

proc call*(call_601401: Call_DeleteNetworkProfile_601388; body: JsonNode): Recallable =
  ## deleteNetworkProfile
  ## Deletes a network profile by the network profile ARN.
  ##   body: JObject (required)
  var body_601402 = newJObject()
  if body != nil:
    body_601402 = body
  result = call_601401.call(nil, nil, nil, nil, body_601402)

var deleteNetworkProfile* = Call_DeleteNetworkProfile_601388(
    name: "deleteNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteNetworkProfile",
    validator: validate_DeleteNetworkProfile_601389, base: "/",
    url: url_DeleteNetworkProfile_601390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProfile_601403 = ref object of OpenApiRestCall_600437
proc url_DeleteProfile_601405(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteProfile_601404(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601406 = header.getOrDefault("X-Amz-Date")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Date", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Security-Token")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Security-Token", valid_601407
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601408 = header.getOrDefault("X-Amz-Target")
  valid_601408 = validateParameter(valid_601408, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteProfile"))
  if valid_601408 != nil:
    section.add "X-Amz-Target", valid_601408
  var valid_601409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601409 = validateParameter(valid_601409, JString, required = false,
                                 default = nil)
  if valid_601409 != nil:
    section.add "X-Amz-Content-Sha256", valid_601409
  var valid_601410 = header.getOrDefault("X-Amz-Algorithm")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Algorithm", valid_601410
  var valid_601411 = header.getOrDefault("X-Amz-Signature")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "X-Amz-Signature", valid_601411
  var valid_601412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-SignedHeaders", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-Credential")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Credential", valid_601413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601415: Call_DeleteProfile_601403; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a room profile by the profile ARN.
  ## 
  let valid = call_601415.validator(path, query, header, formData, body)
  let scheme = call_601415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601415.url(scheme.get, call_601415.host, call_601415.base,
                         call_601415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601415, url, valid)

proc call*(call_601416: Call_DeleteProfile_601403; body: JsonNode): Recallable =
  ## deleteProfile
  ## Deletes a room profile by the profile ARN.
  ##   body: JObject (required)
  var body_601417 = newJObject()
  if body != nil:
    body_601417 = body
  result = call_601416.call(nil, nil, nil, nil, body_601417)

var deleteProfile* = Call_DeleteProfile_601403(name: "deleteProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteProfile",
    validator: validate_DeleteProfile_601404, base: "/", url: url_DeleteProfile_601405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoom_601418 = ref object of OpenApiRestCall_600437
proc url_DeleteRoom_601420(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRoom_601419(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601421 = header.getOrDefault("X-Amz-Date")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Date", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Security-Token")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Security-Token", valid_601422
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601423 = header.getOrDefault("X-Amz-Target")
  valid_601423 = validateParameter(valid_601423, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteRoom"))
  if valid_601423 != nil:
    section.add "X-Amz-Target", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-Content-Sha256", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-Algorithm")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Algorithm", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Signature")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Signature", valid_601426
  var valid_601427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "X-Amz-SignedHeaders", valid_601427
  var valid_601428 = header.getOrDefault("X-Amz-Credential")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Credential", valid_601428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601430: Call_DeleteRoom_601418; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a room by the room ARN.
  ## 
  let valid = call_601430.validator(path, query, header, formData, body)
  let scheme = call_601430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601430.url(scheme.get, call_601430.host, call_601430.base,
                         call_601430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601430, url, valid)

proc call*(call_601431: Call_DeleteRoom_601418; body: JsonNode): Recallable =
  ## deleteRoom
  ## Deletes a room by the room ARN.
  ##   body: JObject (required)
  var body_601432 = newJObject()
  if body != nil:
    body_601432 = body
  result = call_601431.call(nil, nil, nil, nil, body_601432)

var deleteRoom* = Call_DeleteRoom_601418(name: "deleteRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DeleteRoom",
                                      validator: validate_DeleteRoom_601419,
                                      base: "/", url: url_DeleteRoom_601420,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoomSkillParameter_601433 = ref object of OpenApiRestCall_600437
proc url_DeleteRoomSkillParameter_601435(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRoomSkillParameter_601434(path: JsonNode; query: JsonNode;
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
  var valid_601436 = header.getOrDefault("X-Amz-Date")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-Date", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Security-Token")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Security-Token", valid_601437
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601438 = header.getOrDefault("X-Amz-Target")
  valid_601438 = validateParameter(valid_601438, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteRoomSkillParameter"))
  if valid_601438 != nil:
    section.add "X-Amz-Target", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Content-Sha256", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-Algorithm")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Algorithm", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Signature")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Signature", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-SignedHeaders", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-Credential")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Credential", valid_601443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601445: Call_DeleteRoomSkillParameter_601433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes room skill parameter details by room, skill, and parameter key ID.
  ## 
  let valid = call_601445.validator(path, query, header, formData, body)
  let scheme = call_601445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601445.url(scheme.get, call_601445.host, call_601445.base,
                         call_601445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601445, url, valid)

proc call*(call_601446: Call_DeleteRoomSkillParameter_601433; body: JsonNode): Recallable =
  ## deleteRoomSkillParameter
  ## Deletes room skill parameter details by room, skill, and parameter key ID.
  ##   body: JObject (required)
  var body_601447 = newJObject()
  if body != nil:
    body_601447 = body
  result = call_601446.call(nil, nil, nil, nil, body_601447)

var deleteRoomSkillParameter* = Call_DeleteRoomSkillParameter_601433(
    name: "deleteRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteRoomSkillParameter",
    validator: validate_DeleteRoomSkillParameter_601434, base: "/",
    url: url_DeleteRoomSkillParameter_601435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSkillAuthorization_601448 = ref object of OpenApiRestCall_600437
proc url_DeleteSkillAuthorization_601450(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSkillAuthorization_601449(path: JsonNode; query: JsonNode;
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
  var valid_601451 = header.getOrDefault("X-Amz-Date")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Date", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Security-Token")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Security-Token", valid_601452
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601453 = header.getOrDefault("X-Amz-Target")
  valid_601453 = validateParameter(valid_601453, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteSkillAuthorization"))
  if valid_601453 != nil:
    section.add "X-Amz-Target", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Content-Sha256", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Algorithm")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Algorithm", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Signature")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Signature", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-SignedHeaders", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-Credential")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-Credential", valid_601458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601460: Call_DeleteSkillAuthorization_601448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Unlinks a third-party account from a skill.
  ## 
  let valid = call_601460.validator(path, query, header, formData, body)
  let scheme = call_601460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601460.url(scheme.get, call_601460.host, call_601460.base,
                         call_601460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601460, url, valid)

proc call*(call_601461: Call_DeleteSkillAuthorization_601448; body: JsonNode): Recallable =
  ## deleteSkillAuthorization
  ## Unlinks a third-party account from a skill.
  ##   body: JObject (required)
  var body_601462 = newJObject()
  if body != nil:
    body_601462 = body
  result = call_601461.call(nil, nil, nil, nil, body_601462)

var deleteSkillAuthorization* = Call_DeleteSkillAuthorization_601448(
    name: "deleteSkillAuthorization", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteSkillAuthorization",
    validator: validate_DeleteSkillAuthorization_601449, base: "/",
    url: url_DeleteSkillAuthorization_601450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSkillGroup_601463 = ref object of OpenApiRestCall_600437
proc url_DeleteSkillGroup_601465(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSkillGroup_601464(path: JsonNode; query: JsonNode;
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
  var valid_601466 = header.getOrDefault("X-Amz-Date")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-Date", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Security-Token")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Security-Token", valid_601467
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601468 = header.getOrDefault("X-Amz-Target")
  valid_601468 = validateParameter(valid_601468, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteSkillGroup"))
  if valid_601468 != nil:
    section.add "X-Amz-Target", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-Content-Sha256", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-Algorithm")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Algorithm", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Signature")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Signature", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-SignedHeaders", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-Credential")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-Credential", valid_601473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601475: Call_DeleteSkillGroup_601463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a skill group by skill group ARN.
  ## 
  let valid = call_601475.validator(path, query, header, formData, body)
  let scheme = call_601475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601475.url(scheme.get, call_601475.host, call_601475.base,
                         call_601475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601475, url, valid)

proc call*(call_601476: Call_DeleteSkillGroup_601463; body: JsonNode): Recallable =
  ## deleteSkillGroup
  ## Deletes a skill group by skill group ARN.
  ##   body: JObject (required)
  var body_601477 = newJObject()
  if body != nil:
    body_601477 = body
  result = call_601476.call(nil, nil, nil, nil, body_601477)

var deleteSkillGroup* = Call_DeleteSkillGroup_601463(name: "deleteSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DeleteSkillGroup",
    validator: validate_DeleteSkillGroup_601464, base: "/",
    url: url_DeleteSkillGroup_601465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_601478 = ref object of OpenApiRestCall_600437
proc url_DeleteUser_601480(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteUser_601479(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601481 = header.getOrDefault("X-Amz-Date")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Date", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-Security-Token")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Security-Token", valid_601482
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601483 = header.getOrDefault("X-Amz-Target")
  valid_601483 = validateParameter(valid_601483, JString, required = true, default = newJString(
      "AlexaForBusiness.DeleteUser"))
  if valid_601483 != nil:
    section.add "X-Amz-Target", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-Content-Sha256", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Algorithm")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Algorithm", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Signature")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Signature", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-SignedHeaders", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-Credential")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-Credential", valid_601488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601490: Call_DeleteUser_601478; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified user by user ARN and enrollment ARN.
  ## 
  let valid = call_601490.validator(path, query, header, formData, body)
  let scheme = call_601490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601490.url(scheme.get, call_601490.host, call_601490.base,
                         call_601490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601490, url, valid)

proc call*(call_601491: Call_DeleteUser_601478; body: JsonNode): Recallable =
  ## deleteUser
  ## Deletes a specified user by user ARN and enrollment ARN.
  ##   body: JObject (required)
  var body_601492 = newJObject()
  if body != nil:
    body_601492 = body
  result = call_601491.call(nil, nil, nil, nil, body_601492)

var deleteUser* = Call_DeleteUser_601478(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DeleteUser",
                                      validator: validate_DeleteUser_601479,
                                      base: "/", url: url_DeleteUser_601480,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateContactFromAddressBook_601493 = ref object of OpenApiRestCall_600437
proc url_DisassociateContactFromAddressBook_601495(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateContactFromAddressBook_601494(path: JsonNode;
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
  var valid_601496 = header.getOrDefault("X-Amz-Date")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-Date", valid_601496
  var valid_601497 = header.getOrDefault("X-Amz-Security-Token")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Security-Token", valid_601497
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601498 = header.getOrDefault("X-Amz-Target")
  valid_601498 = validateParameter(valid_601498, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateContactFromAddressBook"))
  if valid_601498 != nil:
    section.add "X-Amz-Target", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Content-Sha256", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Algorithm")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Algorithm", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-Signature")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Signature", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-SignedHeaders", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-Credential")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Credential", valid_601503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601505: Call_DisassociateContactFromAddressBook_601493;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a contact from a given address book.
  ## 
  let valid = call_601505.validator(path, query, header, formData, body)
  let scheme = call_601505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601505.url(scheme.get, call_601505.host, call_601505.base,
                         call_601505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601505, url, valid)

proc call*(call_601506: Call_DisassociateContactFromAddressBook_601493;
          body: JsonNode): Recallable =
  ## disassociateContactFromAddressBook
  ## Disassociates a contact from a given address book.
  ##   body: JObject (required)
  var body_601507 = newJObject()
  if body != nil:
    body_601507 = body
  result = call_601506.call(nil, nil, nil, nil, body_601507)

var disassociateContactFromAddressBook* = Call_DisassociateContactFromAddressBook_601493(
    name: "disassociateContactFromAddressBook", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.DisassociateContactFromAddressBook",
    validator: validate_DisassociateContactFromAddressBook_601494, base: "/",
    url: url_DisassociateContactFromAddressBook_601495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDeviceFromRoom_601508 = ref object of OpenApiRestCall_600437
proc url_DisassociateDeviceFromRoom_601510(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateDeviceFromRoom_601509(path: JsonNode; query: JsonNode;
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
  var valid_601511 = header.getOrDefault("X-Amz-Date")
  valid_601511 = validateParameter(valid_601511, JString, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "X-Amz-Date", valid_601511
  var valid_601512 = header.getOrDefault("X-Amz-Security-Token")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Security-Token", valid_601512
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601513 = header.getOrDefault("X-Amz-Target")
  valid_601513 = validateParameter(valid_601513, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateDeviceFromRoom"))
  if valid_601513 != nil:
    section.add "X-Amz-Target", valid_601513
  var valid_601514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-Content-Sha256", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Algorithm")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Algorithm", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-Signature")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Signature", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-SignedHeaders", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Credential")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Credential", valid_601518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601520: Call_DisassociateDeviceFromRoom_601508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a device from its current room. The device continues to be connected to the Wi-Fi network and is still registered to the account. The device settings and skills are removed from the room.
  ## 
  let valid = call_601520.validator(path, query, header, formData, body)
  let scheme = call_601520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601520.url(scheme.get, call_601520.host, call_601520.base,
                         call_601520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601520, url, valid)

proc call*(call_601521: Call_DisassociateDeviceFromRoom_601508; body: JsonNode): Recallable =
  ## disassociateDeviceFromRoom
  ## Disassociates a device from its current room. The device continues to be connected to the Wi-Fi network and is still registered to the account. The device settings and skills are removed from the room.
  ##   body: JObject (required)
  var body_601522 = newJObject()
  if body != nil:
    body_601522 = body
  result = call_601521.call(nil, nil, nil, nil, body_601522)

var disassociateDeviceFromRoom* = Call_DisassociateDeviceFromRoom_601508(
    name: "disassociateDeviceFromRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateDeviceFromRoom",
    validator: validate_DisassociateDeviceFromRoom_601509, base: "/",
    url: url_DisassociateDeviceFromRoom_601510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillFromSkillGroup_601523 = ref object of OpenApiRestCall_600437
proc url_DisassociateSkillFromSkillGroup_601525(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateSkillFromSkillGroup_601524(path: JsonNode;
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
  var valid_601526 = header.getOrDefault("X-Amz-Date")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "X-Amz-Date", valid_601526
  var valid_601527 = header.getOrDefault("X-Amz-Security-Token")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Security-Token", valid_601527
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601528 = header.getOrDefault("X-Amz-Target")
  valid_601528 = validateParameter(valid_601528, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillFromSkillGroup"))
  if valid_601528 != nil:
    section.add "X-Amz-Target", valid_601528
  var valid_601529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601529 = validateParameter(valid_601529, JString, required = false,
                                 default = nil)
  if valid_601529 != nil:
    section.add "X-Amz-Content-Sha256", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-Algorithm")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Algorithm", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-Signature")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Signature", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-SignedHeaders", valid_601532
  var valid_601533 = header.getOrDefault("X-Amz-Credential")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Credential", valid_601533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601535: Call_DisassociateSkillFromSkillGroup_601523;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a skill from a skill group.
  ## 
  let valid = call_601535.validator(path, query, header, formData, body)
  let scheme = call_601535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601535.url(scheme.get, call_601535.host, call_601535.base,
                         call_601535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601535, url, valid)

proc call*(call_601536: Call_DisassociateSkillFromSkillGroup_601523; body: JsonNode): Recallable =
  ## disassociateSkillFromSkillGroup
  ## Disassociates a skill from a skill group.
  ##   body: JObject (required)
  var body_601537 = newJObject()
  if body != nil:
    body_601537 = body
  result = call_601536.call(nil, nil, nil, nil, body_601537)

var disassociateSkillFromSkillGroup* = Call_DisassociateSkillFromSkillGroup_601523(
    name: "disassociateSkillFromSkillGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillFromSkillGroup",
    validator: validate_DisassociateSkillFromSkillGroup_601524, base: "/",
    url: url_DisassociateSkillFromSkillGroup_601525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillFromUsers_601538 = ref object of OpenApiRestCall_600437
proc url_DisassociateSkillFromUsers_601540(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateSkillFromUsers_601539(path: JsonNode; query: JsonNode;
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
  var valid_601541 = header.getOrDefault("X-Amz-Date")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-Date", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-Security-Token")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Security-Token", valid_601542
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601543 = header.getOrDefault("X-Amz-Target")
  valid_601543 = validateParameter(valid_601543, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillFromUsers"))
  if valid_601543 != nil:
    section.add "X-Amz-Target", valid_601543
  var valid_601544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "X-Amz-Content-Sha256", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Algorithm")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Algorithm", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-Signature")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-Signature", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-SignedHeaders", valid_601547
  var valid_601548 = header.getOrDefault("X-Amz-Credential")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Credential", valid_601548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601550: Call_DisassociateSkillFromUsers_601538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Makes a private skill unavailable for enrolled users and prevents them from enabling it on their devices.
  ## 
  let valid = call_601550.validator(path, query, header, formData, body)
  let scheme = call_601550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601550.url(scheme.get, call_601550.host, call_601550.base,
                         call_601550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601550, url, valid)

proc call*(call_601551: Call_DisassociateSkillFromUsers_601538; body: JsonNode): Recallable =
  ## disassociateSkillFromUsers
  ## Makes a private skill unavailable for enrolled users and prevents them from enabling it on their devices.
  ##   body: JObject (required)
  var body_601552 = newJObject()
  if body != nil:
    body_601552 = body
  result = call_601551.call(nil, nil, nil, nil, body_601552)

var disassociateSkillFromUsers* = Call_DisassociateSkillFromUsers_601538(
    name: "disassociateSkillFromUsers", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillFromUsers",
    validator: validate_DisassociateSkillFromUsers_601539, base: "/",
    url: url_DisassociateSkillFromUsers_601540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateSkillGroupFromRoom_601553 = ref object of OpenApiRestCall_600437
proc url_DisassociateSkillGroupFromRoom_601555(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateSkillGroupFromRoom_601554(path: JsonNode;
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
  var valid_601556 = header.getOrDefault("X-Amz-Date")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-Date", valid_601556
  var valid_601557 = header.getOrDefault("X-Amz-Security-Token")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Security-Token", valid_601557
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601558 = header.getOrDefault("X-Amz-Target")
  valid_601558 = validateParameter(valid_601558, JString, required = true, default = newJString(
      "AlexaForBusiness.DisassociateSkillGroupFromRoom"))
  if valid_601558 != nil:
    section.add "X-Amz-Target", valid_601558
  var valid_601559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "X-Amz-Content-Sha256", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Algorithm")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Algorithm", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-Signature")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Signature", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-SignedHeaders", valid_601562
  var valid_601563 = header.getOrDefault("X-Amz-Credential")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-Credential", valid_601563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601565: Call_DisassociateSkillGroupFromRoom_601553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a skill group from a specified room. This disables all skills in the skill group on all devices in the room.
  ## 
  let valid = call_601565.validator(path, query, header, formData, body)
  let scheme = call_601565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601565.url(scheme.get, call_601565.host, call_601565.base,
                         call_601565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601565, url, valid)

proc call*(call_601566: Call_DisassociateSkillGroupFromRoom_601553; body: JsonNode): Recallable =
  ## disassociateSkillGroupFromRoom
  ## Disassociates a skill group from a specified room. This disables all skills in the skill group on all devices in the room.
  ##   body: JObject (required)
  var body_601567 = newJObject()
  if body != nil:
    body_601567 = body
  result = call_601566.call(nil, nil, nil, nil, body_601567)

var disassociateSkillGroupFromRoom* = Call_DisassociateSkillGroupFromRoom_601553(
    name: "disassociateSkillGroupFromRoom", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.DisassociateSkillGroupFromRoom",
    validator: validate_DisassociateSkillGroupFromRoom_601554, base: "/",
    url: url_DisassociateSkillGroupFromRoom_601555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ForgetSmartHomeAppliances_601568 = ref object of OpenApiRestCall_600437
proc url_ForgetSmartHomeAppliances_601570(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ForgetSmartHomeAppliances_601569(path: JsonNode; query: JsonNode;
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
  var valid_601571 = header.getOrDefault("X-Amz-Date")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "X-Amz-Date", valid_601571
  var valid_601572 = header.getOrDefault("X-Amz-Security-Token")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Security-Token", valid_601572
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601573 = header.getOrDefault("X-Amz-Target")
  valid_601573 = validateParameter(valid_601573, JString, required = true, default = newJString(
      "AlexaForBusiness.ForgetSmartHomeAppliances"))
  if valid_601573 != nil:
    section.add "X-Amz-Target", valid_601573
  var valid_601574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = nil)
  if valid_601574 != nil:
    section.add "X-Amz-Content-Sha256", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-Algorithm")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-Algorithm", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-Signature")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-Signature", valid_601576
  var valid_601577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-SignedHeaders", valid_601577
  var valid_601578 = header.getOrDefault("X-Amz-Credential")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Credential", valid_601578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601580: Call_ForgetSmartHomeAppliances_601568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Forgets smart home appliances associated to a room.
  ## 
  let valid = call_601580.validator(path, query, header, formData, body)
  let scheme = call_601580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601580.url(scheme.get, call_601580.host, call_601580.base,
                         call_601580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601580, url, valid)

proc call*(call_601581: Call_ForgetSmartHomeAppliances_601568; body: JsonNode): Recallable =
  ## forgetSmartHomeAppliances
  ## Forgets smart home appliances associated to a room.
  ##   body: JObject (required)
  var body_601582 = newJObject()
  if body != nil:
    body_601582 = body
  result = call_601581.call(nil, nil, nil, nil, body_601582)

var forgetSmartHomeAppliances* = Call_ForgetSmartHomeAppliances_601568(
    name: "forgetSmartHomeAppliances", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ForgetSmartHomeAppliances",
    validator: validate_ForgetSmartHomeAppliances_601569, base: "/",
    url: url_ForgetSmartHomeAppliances_601570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddressBook_601583 = ref object of OpenApiRestCall_600437
proc url_GetAddressBook_601585(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddressBook_601584(path: JsonNode; query: JsonNode;
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
  var valid_601586 = header.getOrDefault("X-Amz-Date")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "X-Amz-Date", valid_601586
  var valid_601587 = header.getOrDefault("X-Amz-Security-Token")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-Security-Token", valid_601587
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601588 = header.getOrDefault("X-Amz-Target")
  valid_601588 = validateParameter(valid_601588, JString, required = true, default = newJString(
      "AlexaForBusiness.GetAddressBook"))
  if valid_601588 != nil:
    section.add "X-Amz-Target", valid_601588
  var valid_601589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "X-Amz-Content-Sha256", valid_601589
  var valid_601590 = header.getOrDefault("X-Amz-Algorithm")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-Algorithm", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-Signature")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Signature", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-SignedHeaders", valid_601592
  var valid_601593 = header.getOrDefault("X-Amz-Credential")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Credential", valid_601593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601595: Call_GetAddressBook_601583; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets address the book details by the address book ARN.
  ## 
  let valid = call_601595.validator(path, query, header, formData, body)
  let scheme = call_601595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601595.url(scheme.get, call_601595.host, call_601595.base,
                         call_601595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601595, url, valid)

proc call*(call_601596: Call_GetAddressBook_601583; body: JsonNode): Recallable =
  ## getAddressBook
  ## Gets address the book details by the address book ARN.
  ##   body: JObject (required)
  var body_601597 = newJObject()
  if body != nil:
    body_601597 = body
  result = call_601596.call(nil, nil, nil, nil, body_601597)

var getAddressBook* = Call_GetAddressBook_601583(name: "getAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetAddressBook",
    validator: validate_GetAddressBook_601584, base: "/", url: url_GetAddressBook_601585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConferencePreference_601598 = ref object of OpenApiRestCall_600437
proc url_GetConferencePreference_601600(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConferencePreference_601599(path: JsonNode; query: JsonNode;
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
  var valid_601601 = header.getOrDefault("X-Amz-Date")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "X-Amz-Date", valid_601601
  var valid_601602 = header.getOrDefault("X-Amz-Security-Token")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "X-Amz-Security-Token", valid_601602
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601603 = header.getOrDefault("X-Amz-Target")
  valid_601603 = validateParameter(valid_601603, JString, required = true, default = newJString(
      "AlexaForBusiness.GetConferencePreference"))
  if valid_601603 != nil:
    section.add "X-Amz-Target", valid_601603
  var valid_601604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601604 = validateParameter(valid_601604, JString, required = false,
                                 default = nil)
  if valid_601604 != nil:
    section.add "X-Amz-Content-Sha256", valid_601604
  var valid_601605 = header.getOrDefault("X-Amz-Algorithm")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Algorithm", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-Signature")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Signature", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-SignedHeaders", valid_601607
  var valid_601608 = header.getOrDefault("X-Amz-Credential")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-Credential", valid_601608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601610: Call_GetConferencePreference_601598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the existing conference preferences.
  ## 
  let valid = call_601610.validator(path, query, header, formData, body)
  let scheme = call_601610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601610.url(scheme.get, call_601610.host, call_601610.base,
                         call_601610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601610, url, valid)

proc call*(call_601611: Call_GetConferencePreference_601598; body: JsonNode): Recallable =
  ## getConferencePreference
  ## Retrieves the existing conference preferences.
  ##   body: JObject (required)
  var body_601612 = newJObject()
  if body != nil:
    body_601612 = body
  result = call_601611.call(nil, nil, nil, nil, body_601612)

var getConferencePreference* = Call_GetConferencePreference_601598(
    name: "getConferencePreference", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetConferencePreference",
    validator: validate_GetConferencePreference_601599, base: "/",
    url: url_GetConferencePreference_601600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConferenceProvider_601613 = ref object of OpenApiRestCall_600437
proc url_GetConferenceProvider_601615(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConferenceProvider_601614(path: JsonNode; query: JsonNode;
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
  var valid_601616 = header.getOrDefault("X-Amz-Date")
  valid_601616 = validateParameter(valid_601616, JString, required = false,
                                 default = nil)
  if valid_601616 != nil:
    section.add "X-Amz-Date", valid_601616
  var valid_601617 = header.getOrDefault("X-Amz-Security-Token")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-Security-Token", valid_601617
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601618 = header.getOrDefault("X-Amz-Target")
  valid_601618 = validateParameter(valid_601618, JString, required = true, default = newJString(
      "AlexaForBusiness.GetConferenceProvider"))
  if valid_601618 != nil:
    section.add "X-Amz-Target", valid_601618
  var valid_601619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601619 = validateParameter(valid_601619, JString, required = false,
                                 default = nil)
  if valid_601619 != nil:
    section.add "X-Amz-Content-Sha256", valid_601619
  var valid_601620 = header.getOrDefault("X-Amz-Algorithm")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-Algorithm", valid_601620
  var valid_601621 = header.getOrDefault("X-Amz-Signature")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Signature", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-SignedHeaders", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-Credential")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Credential", valid_601623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601625: Call_GetConferenceProvider_601613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a specific conference provider.
  ## 
  let valid = call_601625.validator(path, query, header, formData, body)
  let scheme = call_601625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601625.url(scheme.get, call_601625.host, call_601625.base,
                         call_601625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601625, url, valid)

proc call*(call_601626: Call_GetConferenceProvider_601613; body: JsonNode): Recallable =
  ## getConferenceProvider
  ## Gets details about a specific conference provider.
  ##   body: JObject (required)
  var body_601627 = newJObject()
  if body != nil:
    body_601627 = body
  result = call_601626.call(nil, nil, nil, nil, body_601627)

var getConferenceProvider* = Call_GetConferenceProvider_601613(
    name: "getConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetConferenceProvider",
    validator: validate_GetConferenceProvider_601614, base: "/",
    url: url_GetConferenceProvider_601615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContact_601628 = ref object of OpenApiRestCall_600437
proc url_GetContact_601630(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetContact_601629(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601631 = header.getOrDefault("X-Amz-Date")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "X-Amz-Date", valid_601631
  var valid_601632 = header.getOrDefault("X-Amz-Security-Token")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-Security-Token", valid_601632
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601633 = header.getOrDefault("X-Amz-Target")
  valid_601633 = validateParameter(valid_601633, JString, required = true, default = newJString(
      "AlexaForBusiness.GetContact"))
  if valid_601633 != nil:
    section.add "X-Amz-Target", valid_601633
  var valid_601634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601634 = validateParameter(valid_601634, JString, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "X-Amz-Content-Sha256", valid_601634
  var valid_601635 = header.getOrDefault("X-Amz-Algorithm")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "X-Amz-Algorithm", valid_601635
  var valid_601636 = header.getOrDefault("X-Amz-Signature")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-Signature", valid_601636
  var valid_601637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "X-Amz-SignedHeaders", valid_601637
  var valid_601638 = header.getOrDefault("X-Amz-Credential")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-Credential", valid_601638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601640: Call_GetContact_601628; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contact details by the contact ARN.
  ## 
  let valid = call_601640.validator(path, query, header, formData, body)
  let scheme = call_601640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601640.url(scheme.get, call_601640.host, call_601640.base,
                         call_601640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601640, url, valid)

proc call*(call_601641: Call_GetContact_601628; body: JsonNode): Recallable =
  ## getContact
  ## Gets the contact details by the contact ARN.
  ##   body: JObject (required)
  var body_601642 = newJObject()
  if body != nil:
    body_601642 = body
  result = call_601641.call(nil, nil, nil, nil, body_601642)

var getContact* = Call_GetContact_601628(name: "getContact",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetContact",
                                      validator: validate_GetContact_601629,
                                      base: "/", url: url_GetContact_601630,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevice_601643 = ref object of OpenApiRestCall_600437
proc url_GetDevice_601645(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevice_601644(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601646 = header.getOrDefault("X-Amz-Date")
  valid_601646 = validateParameter(valid_601646, JString, required = false,
                                 default = nil)
  if valid_601646 != nil:
    section.add "X-Amz-Date", valid_601646
  var valid_601647 = header.getOrDefault("X-Amz-Security-Token")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Security-Token", valid_601647
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601648 = header.getOrDefault("X-Amz-Target")
  valid_601648 = validateParameter(valid_601648, JString, required = true, default = newJString(
      "AlexaForBusiness.GetDevice"))
  if valid_601648 != nil:
    section.add "X-Amz-Target", valid_601648
  var valid_601649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-Content-Sha256", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-Algorithm")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Algorithm", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-Signature")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Signature", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-SignedHeaders", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-Credential")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Credential", valid_601653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601655: Call_GetDevice_601643; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details of a device by device ARN.
  ## 
  let valid = call_601655.validator(path, query, header, formData, body)
  let scheme = call_601655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601655.url(scheme.get, call_601655.host, call_601655.base,
                         call_601655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601655, url, valid)

proc call*(call_601656: Call_GetDevice_601643; body: JsonNode): Recallable =
  ## getDevice
  ## Gets the details of a device by device ARN.
  ##   body: JObject (required)
  var body_601657 = newJObject()
  if body != nil:
    body_601657 = body
  result = call_601656.call(nil, nil, nil, nil, body_601657)

var getDevice* = Call_GetDevice_601643(name: "getDevice", meth: HttpMethod.HttpPost,
                                    host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetDevice",
                                    validator: validate_GetDevice_601644,
                                    base: "/", url: url_GetDevice_601645,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGateway_601658 = ref object of OpenApiRestCall_600437
proc url_GetGateway_601660(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGateway_601659(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601661 = header.getOrDefault("X-Amz-Date")
  valid_601661 = validateParameter(valid_601661, JString, required = false,
                                 default = nil)
  if valid_601661 != nil:
    section.add "X-Amz-Date", valid_601661
  var valid_601662 = header.getOrDefault("X-Amz-Security-Token")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "X-Amz-Security-Token", valid_601662
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601663 = header.getOrDefault("X-Amz-Target")
  valid_601663 = validateParameter(valid_601663, JString, required = true, default = newJString(
      "AlexaForBusiness.GetGateway"))
  if valid_601663 != nil:
    section.add "X-Amz-Target", valid_601663
  var valid_601664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "X-Amz-Content-Sha256", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-Algorithm")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Algorithm", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-Signature")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-Signature", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-SignedHeaders", valid_601667
  var valid_601668 = header.getOrDefault("X-Amz-Credential")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-Credential", valid_601668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601670: Call_GetGateway_601658; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details of a gateway.
  ## 
  let valid = call_601670.validator(path, query, header, formData, body)
  let scheme = call_601670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601670.url(scheme.get, call_601670.host, call_601670.base,
                         call_601670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601670, url, valid)

proc call*(call_601671: Call_GetGateway_601658; body: JsonNode): Recallable =
  ## getGateway
  ## Retrieves the details of a gateway.
  ##   body: JObject (required)
  var body_601672 = newJObject()
  if body != nil:
    body_601672 = body
  result = call_601671.call(nil, nil, nil, nil, body_601672)

var getGateway* = Call_GetGateway_601658(name: "getGateway",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetGateway",
                                      validator: validate_GetGateway_601659,
                                      base: "/", url: url_GetGateway_601660,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGatewayGroup_601673 = ref object of OpenApiRestCall_600437
proc url_GetGatewayGroup_601675(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGatewayGroup_601674(path: JsonNode; query: JsonNode;
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
  var valid_601676 = header.getOrDefault("X-Amz-Date")
  valid_601676 = validateParameter(valid_601676, JString, required = false,
                                 default = nil)
  if valid_601676 != nil:
    section.add "X-Amz-Date", valid_601676
  var valid_601677 = header.getOrDefault("X-Amz-Security-Token")
  valid_601677 = validateParameter(valid_601677, JString, required = false,
                                 default = nil)
  if valid_601677 != nil:
    section.add "X-Amz-Security-Token", valid_601677
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601678 = header.getOrDefault("X-Amz-Target")
  valid_601678 = validateParameter(valid_601678, JString, required = true, default = newJString(
      "AlexaForBusiness.GetGatewayGroup"))
  if valid_601678 != nil:
    section.add "X-Amz-Target", valid_601678
  var valid_601679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601679 = validateParameter(valid_601679, JString, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "X-Amz-Content-Sha256", valid_601679
  var valid_601680 = header.getOrDefault("X-Amz-Algorithm")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-Algorithm", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-Signature")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Signature", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-SignedHeaders", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-Credential")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-Credential", valid_601683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601685: Call_GetGatewayGroup_601673; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details of a gateway group.
  ## 
  let valid = call_601685.validator(path, query, header, formData, body)
  let scheme = call_601685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601685.url(scheme.get, call_601685.host, call_601685.base,
                         call_601685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601685, url, valid)

proc call*(call_601686: Call_GetGatewayGroup_601673; body: JsonNode): Recallable =
  ## getGatewayGroup
  ## Retrieves the details of a gateway group.
  ##   body: JObject (required)
  var body_601687 = newJObject()
  if body != nil:
    body_601687 = body
  result = call_601686.call(nil, nil, nil, nil, body_601687)

var getGatewayGroup* = Call_GetGatewayGroup_601673(name: "getGatewayGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetGatewayGroup",
    validator: validate_GetGatewayGroup_601674, base: "/", url: url_GetGatewayGroup_601675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationConfiguration_601688 = ref object of OpenApiRestCall_600437
proc url_GetInvitationConfiguration_601690(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInvitationConfiguration_601689(path: JsonNode; query: JsonNode;
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
  var valid_601691 = header.getOrDefault("X-Amz-Date")
  valid_601691 = validateParameter(valid_601691, JString, required = false,
                                 default = nil)
  if valid_601691 != nil:
    section.add "X-Amz-Date", valid_601691
  var valid_601692 = header.getOrDefault("X-Amz-Security-Token")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-Security-Token", valid_601692
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601693 = header.getOrDefault("X-Amz-Target")
  valid_601693 = validateParameter(valid_601693, JString, required = true, default = newJString(
      "AlexaForBusiness.GetInvitationConfiguration"))
  if valid_601693 != nil:
    section.add "X-Amz-Target", valid_601693
  var valid_601694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "X-Amz-Content-Sha256", valid_601694
  var valid_601695 = header.getOrDefault("X-Amz-Algorithm")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Algorithm", valid_601695
  var valid_601696 = header.getOrDefault("X-Amz-Signature")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Signature", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-SignedHeaders", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-Credential")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-Credential", valid_601698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601700: Call_GetInvitationConfiguration_601688; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the configured values for the user enrollment invitation email template.
  ## 
  let valid = call_601700.validator(path, query, header, formData, body)
  let scheme = call_601700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601700.url(scheme.get, call_601700.host, call_601700.base,
                         call_601700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601700, url, valid)

proc call*(call_601701: Call_GetInvitationConfiguration_601688; body: JsonNode): Recallable =
  ## getInvitationConfiguration
  ## Retrieves the configured values for the user enrollment invitation email template.
  ##   body: JObject (required)
  var body_601702 = newJObject()
  if body != nil:
    body_601702 = body
  result = call_601701.call(nil, nil, nil, nil, body_601702)

var getInvitationConfiguration* = Call_GetInvitationConfiguration_601688(
    name: "getInvitationConfiguration", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetInvitationConfiguration",
    validator: validate_GetInvitationConfiguration_601689, base: "/",
    url: url_GetInvitationConfiguration_601690,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNetworkProfile_601703 = ref object of OpenApiRestCall_600437
proc url_GetNetworkProfile_601705(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetNetworkProfile_601704(path: JsonNode; query: JsonNode;
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
  var valid_601706 = header.getOrDefault("X-Amz-Date")
  valid_601706 = validateParameter(valid_601706, JString, required = false,
                                 default = nil)
  if valid_601706 != nil:
    section.add "X-Amz-Date", valid_601706
  var valid_601707 = header.getOrDefault("X-Amz-Security-Token")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-Security-Token", valid_601707
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601708 = header.getOrDefault("X-Amz-Target")
  valid_601708 = validateParameter(valid_601708, JString, required = true, default = newJString(
      "AlexaForBusiness.GetNetworkProfile"))
  if valid_601708 != nil:
    section.add "X-Amz-Target", valid_601708
  var valid_601709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601709 = validateParameter(valid_601709, JString, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "X-Amz-Content-Sha256", valid_601709
  var valid_601710 = header.getOrDefault("X-Amz-Algorithm")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-Algorithm", valid_601710
  var valid_601711 = header.getOrDefault("X-Amz-Signature")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = nil)
  if valid_601711 != nil:
    section.add "X-Amz-Signature", valid_601711
  var valid_601712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "X-Amz-SignedHeaders", valid_601712
  var valid_601713 = header.getOrDefault("X-Amz-Credential")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "X-Amz-Credential", valid_601713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601715: Call_GetNetworkProfile_601703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the network profile details by the network profile ARN.
  ## 
  let valid = call_601715.validator(path, query, header, formData, body)
  let scheme = call_601715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601715.url(scheme.get, call_601715.host, call_601715.base,
                         call_601715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601715, url, valid)

proc call*(call_601716: Call_GetNetworkProfile_601703; body: JsonNode): Recallable =
  ## getNetworkProfile
  ## Gets the network profile details by the network profile ARN.
  ##   body: JObject (required)
  var body_601717 = newJObject()
  if body != nil:
    body_601717 = body
  result = call_601716.call(nil, nil, nil, nil, body_601717)

var getNetworkProfile* = Call_GetNetworkProfile_601703(name: "getNetworkProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetNetworkProfile",
    validator: validate_GetNetworkProfile_601704, base: "/",
    url: url_GetNetworkProfile_601705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProfile_601718 = ref object of OpenApiRestCall_600437
proc url_GetProfile_601720(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetProfile_601719(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601721 = header.getOrDefault("X-Amz-Date")
  valid_601721 = validateParameter(valid_601721, JString, required = false,
                                 default = nil)
  if valid_601721 != nil:
    section.add "X-Amz-Date", valid_601721
  var valid_601722 = header.getOrDefault("X-Amz-Security-Token")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "X-Amz-Security-Token", valid_601722
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601723 = header.getOrDefault("X-Amz-Target")
  valid_601723 = validateParameter(valid_601723, JString, required = true, default = newJString(
      "AlexaForBusiness.GetProfile"))
  if valid_601723 != nil:
    section.add "X-Amz-Target", valid_601723
  var valid_601724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601724 = validateParameter(valid_601724, JString, required = false,
                                 default = nil)
  if valid_601724 != nil:
    section.add "X-Amz-Content-Sha256", valid_601724
  var valid_601725 = header.getOrDefault("X-Amz-Algorithm")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-Algorithm", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-Signature")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-Signature", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-SignedHeaders", valid_601727
  var valid_601728 = header.getOrDefault("X-Amz-Credential")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-Credential", valid_601728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601730: Call_GetProfile_601718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the details of a room profile by profile ARN.
  ## 
  let valid = call_601730.validator(path, query, header, formData, body)
  let scheme = call_601730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601730.url(scheme.get, call_601730.host, call_601730.base,
                         call_601730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601730, url, valid)

proc call*(call_601731: Call_GetProfile_601718; body: JsonNode): Recallable =
  ## getProfile
  ## Gets the details of a room profile by profile ARN.
  ##   body: JObject (required)
  var body_601732 = newJObject()
  if body != nil:
    body_601732 = body
  result = call_601731.call(nil, nil, nil, nil, body_601732)

var getProfile* = Call_GetProfile_601718(name: "getProfile",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetProfile",
                                      validator: validate_GetProfile_601719,
                                      base: "/", url: url_GetProfile_601720,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoom_601733 = ref object of OpenApiRestCall_600437
proc url_GetRoom_601735(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRoom_601734(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601736 = header.getOrDefault("X-Amz-Date")
  valid_601736 = validateParameter(valid_601736, JString, required = false,
                                 default = nil)
  if valid_601736 != nil:
    section.add "X-Amz-Date", valid_601736
  var valid_601737 = header.getOrDefault("X-Amz-Security-Token")
  valid_601737 = validateParameter(valid_601737, JString, required = false,
                                 default = nil)
  if valid_601737 != nil:
    section.add "X-Amz-Security-Token", valid_601737
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601738 = header.getOrDefault("X-Amz-Target")
  valid_601738 = validateParameter(valid_601738, JString, required = true, default = newJString(
      "AlexaForBusiness.GetRoom"))
  if valid_601738 != nil:
    section.add "X-Amz-Target", valid_601738
  var valid_601739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601739 = validateParameter(valid_601739, JString, required = false,
                                 default = nil)
  if valid_601739 != nil:
    section.add "X-Amz-Content-Sha256", valid_601739
  var valid_601740 = header.getOrDefault("X-Amz-Algorithm")
  valid_601740 = validateParameter(valid_601740, JString, required = false,
                                 default = nil)
  if valid_601740 != nil:
    section.add "X-Amz-Algorithm", valid_601740
  var valid_601741 = header.getOrDefault("X-Amz-Signature")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "X-Amz-Signature", valid_601741
  var valid_601742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "X-Amz-SignedHeaders", valid_601742
  var valid_601743 = header.getOrDefault("X-Amz-Credential")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "X-Amz-Credential", valid_601743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601745: Call_GetRoom_601733; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets room details by room ARN.
  ## 
  let valid = call_601745.validator(path, query, header, formData, body)
  let scheme = call_601745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601745.url(scheme.get, call_601745.host, call_601745.base,
                         call_601745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601745, url, valid)

proc call*(call_601746: Call_GetRoom_601733; body: JsonNode): Recallable =
  ## getRoom
  ## Gets room details by room ARN.
  ##   body: JObject (required)
  var body_601747 = newJObject()
  if body != nil:
    body_601747 = body
  result = call_601746.call(nil, nil, nil, nil, body_601747)

var getRoom* = Call_GetRoom_601733(name: "getRoom", meth: HttpMethod.HttpPost,
                                host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.GetRoom",
                                validator: validate_GetRoom_601734, base: "/",
                                url: url_GetRoom_601735,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoomSkillParameter_601748 = ref object of OpenApiRestCall_600437
proc url_GetRoomSkillParameter_601750(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRoomSkillParameter_601749(path: JsonNode; query: JsonNode;
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
  var valid_601751 = header.getOrDefault("X-Amz-Date")
  valid_601751 = validateParameter(valid_601751, JString, required = false,
                                 default = nil)
  if valid_601751 != nil:
    section.add "X-Amz-Date", valid_601751
  var valid_601752 = header.getOrDefault("X-Amz-Security-Token")
  valid_601752 = validateParameter(valid_601752, JString, required = false,
                                 default = nil)
  if valid_601752 != nil:
    section.add "X-Amz-Security-Token", valid_601752
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601753 = header.getOrDefault("X-Amz-Target")
  valid_601753 = validateParameter(valid_601753, JString, required = true, default = newJString(
      "AlexaForBusiness.GetRoomSkillParameter"))
  if valid_601753 != nil:
    section.add "X-Amz-Target", valid_601753
  var valid_601754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601754 = validateParameter(valid_601754, JString, required = false,
                                 default = nil)
  if valid_601754 != nil:
    section.add "X-Amz-Content-Sha256", valid_601754
  var valid_601755 = header.getOrDefault("X-Amz-Algorithm")
  valid_601755 = validateParameter(valid_601755, JString, required = false,
                                 default = nil)
  if valid_601755 != nil:
    section.add "X-Amz-Algorithm", valid_601755
  var valid_601756 = header.getOrDefault("X-Amz-Signature")
  valid_601756 = validateParameter(valid_601756, JString, required = false,
                                 default = nil)
  if valid_601756 != nil:
    section.add "X-Amz-Signature", valid_601756
  var valid_601757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601757 = validateParameter(valid_601757, JString, required = false,
                                 default = nil)
  if valid_601757 != nil:
    section.add "X-Amz-SignedHeaders", valid_601757
  var valid_601758 = header.getOrDefault("X-Amz-Credential")
  valid_601758 = validateParameter(valid_601758, JString, required = false,
                                 default = nil)
  if valid_601758 != nil:
    section.add "X-Amz-Credential", valid_601758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601760: Call_GetRoomSkillParameter_601748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets room skill parameter details by room, skill, and parameter key ARN.
  ## 
  let valid = call_601760.validator(path, query, header, formData, body)
  let scheme = call_601760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601760.url(scheme.get, call_601760.host, call_601760.base,
                         call_601760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601760, url, valid)

proc call*(call_601761: Call_GetRoomSkillParameter_601748; body: JsonNode): Recallable =
  ## getRoomSkillParameter
  ## Gets room skill parameter details by room, skill, and parameter key ARN.
  ##   body: JObject (required)
  var body_601762 = newJObject()
  if body != nil:
    body_601762 = body
  result = call_601761.call(nil, nil, nil, nil, body_601762)

var getRoomSkillParameter* = Call_GetRoomSkillParameter_601748(
    name: "getRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetRoomSkillParameter",
    validator: validate_GetRoomSkillParameter_601749, base: "/",
    url: url_GetRoomSkillParameter_601750, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSkillGroup_601763 = ref object of OpenApiRestCall_600437
proc url_GetSkillGroup_601765(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSkillGroup_601764(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601766 = header.getOrDefault("X-Amz-Date")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "X-Amz-Date", valid_601766
  var valid_601767 = header.getOrDefault("X-Amz-Security-Token")
  valid_601767 = validateParameter(valid_601767, JString, required = false,
                                 default = nil)
  if valid_601767 != nil:
    section.add "X-Amz-Security-Token", valid_601767
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601768 = header.getOrDefault("X-Amz-Target")
  valid_601768 = validateParameter(valid_601768, JString, required = true, default = newJString(
      "AlexaForBusiness.GetSkillGroup"))
  if valid_601768 != nil:
    section.add "X-Amz-Target", valid_601768
  var valid_601769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601769 = validateParameter(valid_601769, JString, required = false,
                                 default = nil)
  if valid_601769 != nil:
    section.add "X-Amz-Content-Sha256", valid_601769
  var valid_601770 = header.getOrDefault("X-Amz-Algorithm")
  valid_601770 = validateParameter(valid_601770, JString, required = false,
                                 default = nil)
  if valid_601770 != nil:
    section.add "X-Amz-Algorithm", valid_601770
  var valid_601771 = header.getOrDefault("X-Amz-Signature")
  valid_601771 = validateParameter(valid_601771, JString, required = false,
                                 default = nil)
  if valid_601771 != nil:
    section.add "X-Amz-Signature", valid_601771
  var valid_601772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601772 = validateParameter(valid_601772, JString, required = false,
                                 default = nil)
  if valid_601772 != nil:
    section.add "X-Amz-SignedHeaders", valid_601772
  var valid_601773 = header.getOrDefault("X-Amz-Credential")
  valid_601773 = validateParameter(valid_601773, JString, required = false,
                                 default = nil)
  if valid_601773 != nil:
    section.add "X-Amz-Credential", valid_601773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601775: Call_GetSkillGroup_601763; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets skill group details by skill group ARN.
  ## 
  let valid = call_601775.validator(path, query, header, formData, body)
  let scheme = call_601775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601775.url(scheme.get, call_601775.host, call_601775.base,
                         call_601775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601775, url, valid)

proc call*(call_601776: Call_GetSkillGroup_601763; body: JsonNode): Recallable =
  ## getSkillGroup
  ## Gets skill group details by skill group ARN.
  ##   body: JObject (required)
  var body_601777 = newJObject()
  if body != nil:
    body_601777 = body
  result = call_601776.call(nil, nil, nil, nil, body_601777)

var getSkillGroup* = Call_GetSkillGroup_601763(name: "getSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.GetSkillGroup",
    validator: validate_GetSkillGroup_601764, base: "/", url: url_GetSkillGroup_601765,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBusinessReportSchedules_601778 = ref object of OpenApiRestCall_600437
proc url_ListBusinessReportSchedules_601780(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBusinessReportSchedules_601779(path: JsonNode; query: JsonNode;
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
  var valid_601781 = query.getOrDefault("NextToken")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "NextToken", valid_601781
  var valid_601782 = query.getOrDefault("MaxResults")
  valid_601782 = validateParameter(valid_601782, JString, required = false,
                                 default = nil)
  if valid_601782 != nil:
    section.add "MaxResults", valid_601782
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601783 = header.getOrDefault("X-Amz-Date")
  valid_601783 = validateParameter(valid_601783, JString, required = false,
                                 default = nil)
  if valid_601783 != nil:
    section.add "X-Amz-Date", valid_601783
  var valid_601784 = header.getOrDefault("X-Amz-Security-Token")
  valid_601784 = validateParameter(valid_601784, JString, required = false,
                                 default = nil)
  if valid_601784 != nil:
    section.add "X-Amz-Security-Token", valid_601784
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601785 = header.getOrDefault("X-Amz-Target")
  valid_601785 = validateParameter(valid_601785, JString, required = true, default = newJString(
      "AlexaForBusiness.ListBusinessReportSchedules"))
  if valid_601785 != nil:
    section.add "X-Amz-Target", valid_601785
  var valid_601786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601786 = validateParameter(valid_601786, JString, required = false,
                                 default = nil)
  if valid_601786 != nil:
    section.add "X-Amz-Content-Sha256", valid_601786
  var valid_601787 = header.getOrDefault("X-Amz-Algorithm")
  valid_601787 = validateParameter(valid_601787, JString, required = false,
                                 default = nil)
  if valid_601787 != nil:
    section.add "X-Amz-Algorithm", valid_601787
  var valid_601788 = header.getOrDefault("X-Amz-Signature")
  valid_601788 = validateParameter(valid_601788, JString, required = false,
                                 default = nil)
  if valid_601788 != nil:
    section.add "X-Amz-Signature", valid_601788
  var valid_601789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601789 = validateParameter(valid_601789, JString, required = false,
                                 default = nil)
  if valid_601789 != nil:
    section.add "X-Amz-SignedHeaders", valid_601789
  var valid_601790 = header.getOrDefault("X-Amz-Credential")
  valid_601790 = validateParameter(valid_601790, JString, required = false,
                                 default = nil)
  if valid_601790 != nil:
    section.add "X-Amz-Credential", valid_601790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601792: Call_ListBusinessReportSchedules_601778; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the details of the schedules that a user configured.
  ## 
  let valid = call_601792.validator(path, query, header, formData, body)
  let scheme = call_601792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601792.url(scheme.get, call_601792.host, call_601792.base,
                         call_601792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601792, url, valid)

proc call*(call_601793: Call_ListBusinessReportSchedules_601778; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listBusinessReportSchedules
  ## Lists the details of the schedules that a user configured.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601794 = newJObject()
  var body_601795 = newJObject()
  add(query_601794, "NextToken", newJString(NextToken))
  if body != nil:
    body_601795 = body
  add(query_601794, "MaxResults", newJString(MaxResults))
  result = call_601793.call(nil, query_601794, nil, nil, body_601795)

var listBusinessReportSchedules* = Call_ListBusinessReportSchedules_601778(
    name: "listBusinessReportSchedules", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListBusinessReportSchedules",
    validator: validate_ListBusinessReportSchedules_601779, base: "/",
    url: url_ListBusinessReportSchedules_601780,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConferenceProviders_601797 = ref object of OpenApiRestCall_600437
proc url_ListConferenceProviders_601799(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListConferenceProviders_601798(path: JsonNode; query: JsonNode;
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
  var valid_601800 = query.getOrDefault("NextToken")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "NextToken", valid_601800
  var valid_601801 = query.getOrDefault("MaxResults")
  valid_601801 = validateParameter(valid_601801, JString, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "MaxResults", valid_601801
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601802 = header.getOrDefault("X-Amz-Date")
  valid_601802 = validateParameter(valid_601802, JString, required = false,
                                 default = nil)
  if valid_601802 != nil:
    section.add "X-Amz-Date", valid_601802
  var valid_601803 = header.getOrDefault("X-Amz-Security-Token")
  valid_601803 = validateParameter(valid_601803, JString, required = false,
                                 default = nil)
  if valid_601803 != nil:
    section.add "X-Amz-Security-Token", valid_601803
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601804 = header.getOrDefault("X-Amz-Target")
  valid_601804 = validateParameter(valid_601804, JString, required = true, default = newJString(
      "AlexaForBusiness.ListConferenceProviders"))
  if valid_601804 != nil:
    section.add "X-Amz-Target", valid_601804
  var valid_601805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601805 = validateParameter(valid_601805, JString, required = false,
                                 default = nil)
  if valid_601805 != nil:
    section.add "X-Amz-Content-Sha256", valid_601805
  var valid_601806 = header.getOrDefault("X-Amz-Algorithm")
  valid_601806 = validateParameter(valid_601806, JString, required = false,
                                 default = nil)
  if valid_601806 != nil:
    section.add "X-Amz-Algorithm", valid_601806
  var valid_601807 = header.getOrDefault("X-Amz-Signature")
  valid_601807 = validateParameter(valid_601807, JString, required = false,
                                 default = nil)
  if valid_601807 != nil:
    section.add "X-Amz-Signature", valid_601807
  var valid_601808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601808 = validateParameter(valid_601808, JString, required = false,
                                 default = nil)
  if valid_601808 != nil:
    section.add "X-Amz-SignedHeaders", valid_601808
  var valid_601809 = header.getOrDefault("X-Amz-Credential")
  valid_601809 = validateParameter(valid_601809, JString, required = false,
                                 default = nil)
  if valid_601809 != nil:
    section.add "X-Amz-Credential", valid_601809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601811: Call_ListConferenceProviders_601797; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists conference providers under a specific AWS account.
  ## 
  let valid = call_601811.validator(path, query, header, formData, body)
  let scheme = call_601811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601811.url(scheme.get, call_601811.host, call_601811.base,
                         call_601811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601811, url, valid)

proc call*(call_601812: Call_ListConferenceProviders_601797; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listConferenceProviders
  ## Lists conference providers under a specific AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601813 = newJObject()
  var body_601814 = newJObject()
  add(query_601813, "NextToken", newJString(NextToken))
  if body != nil:
    body_601814 = body
  add(query_601813, "MaxResults", newJString(MaxResults))
  result = call_601812.call(nil, query_601813, nil, nil, body_601814)

var listConferenceProviders* = Call_ListConferenceProviders_601797(
    name: "listConferenceProviders", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListConferenceProviders",
    validator: validate_ListConferenceProviders_601798, base: "/",
    url: url_ListConferenceProviders_601799, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceEvents_601815 = ref object of OpenApiRestCall_600437
proc url_ListDeviceEvents_601817(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeviceEvents_601816(path: JsonNode; query: JsonNode;
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
  var valid_601818 = query.getOrDefault("NextToken")
  valid_601818 = validateParameter(valid_601818, JString, required = false,
                                 default = nil)
  if valid_601818 != nil:
    section.add "NextToken", valid_601818
  var valid_601819 = query.getOrDefault("MaxResults")
  valid_601819 = validateParameter(valid_601819, JString, required = false,
                                 default = nil)
  if valid_601819 != nil:
    section.add "MaxResults", valid_601819
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601820 = header.getOrDefault("X-Amz-Date")
  valid_601820 = validateParameter(valid_601820, JString, required = false,
                                 default = nil)
  if valid_601820 != nil:
    section.add "X-Amz-Date", valid_601820
  var valid_601821 = header.getOrDefault("X-Amz-Security-Token")
  valid_601821 = validateParameter(valid_601821, JString, required = false,
                                 default = nil)
  if valid_601821 != nil:
    section.add "X-Amz-Security-Token", valid_601821
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601822 = header.getOrDefault("X-Amz-Target")
  valid_601822 = validateParameter(valid_601822, JString, required = true, default = newJString(
      "AlexaForBusiness.ListDeviceEvents"))
  if valid_601822 != nil:
    section.add "X-Amz-Target", valid_601822
  var valid_601823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601823 = validateParameter(valid_601823, JString, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "X-Amz-Content-Sha256", valid_601823
  var valid_601824 = header.getOrDefault("X-Amz-Algorithm")
  valid_601824 = validateParameter(valid_601824, JString, required = false,
                                 default = nil)
  if valid_601824 != nil:
    section.add "X-Amz-Algorithm", valid_601824
  var valid_601825 = header.getOrDefault("X-Amz-Signature")
  valid_601825 = validateParameter(valid_601825, JString, required = false,
                                 default = nil)
  if valid_601825 != nil:
    section.add "X-Amz-Signature", valid_601825
  var valid_601826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "X-Amz-SignedHeaders", valid_601826
  var valid_601827 = header.getOrDefault("X-Amz-Credential")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-Credential", valid_601827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601829: Call_ListDeviceEvents_601815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the device event history, including device connection status, for up to 30 days.
  ## 
  let valid = call_601829.validator(path, query, header, formData, body)
  let scheme = call_601829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601829.url(scheme.get, call_601829.host, call_601829.base,
                         call_601829.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601829, url, valid)

proc call*(call_601830: Call_ListDeviceEvents_601815; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDeviceEvents
  ## Lists the device event history, including device connection status, for up to 30 days.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601831 = newJObject()
  var body_601832 = newJObject()
  add(query_601831, "NextToken", newJString(NextToken))
  if body != nil:
    body_601832 = body
  add(query_601831, "MaxResults", newJString(MaxResults))
  result = call_601830.call(nil, query_601831, nil, nil, body_601832)

var listDeviceEvents* = Call_ListDeviceEvents_601815(name: "listDeviceEvents",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListDeviceEvents",
    validator: validate_ListDeviceEvents_601816, base: "/",
    url: url_ListDeviceEvents_601817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGatewayGroups_601833 = ref object of OpenApiRestCall_600437
proc url_ListGatewayGroups_601835(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGatewayGroups_601834(path: JsonNode; query: JsonNode;
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
  var valid_601836 = query.getOrDefault("NextToken")
  valid_601836 = validateParameter(valid_601836, JString, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "NextToken", valid_601836
  var valid_601837 = query.getOrDefault("MaxResults")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "MaxResults", valid_601837
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601838 = header.getOrDefault("X-Amz-Date")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "X-Amz-Date", valid_601838
  var valid_601839 = header.getOrDefault("X-Amz-Security-Token")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Security-Token", valid_601839
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601840 = header.getOrDefault("X-Amz-Target")
  valid_601840 = validateParameter(valid_601840, JString, required = true, default = newJString(
      "AlexaForBusiness.ListGatewayGroups"))
  if valid_601840 != nil:
    section.add "X-Amz-Target", valid_601840
  var valid_601841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Content-Sha256", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Algorithm")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Algorithm", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Signature")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Signature", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-SignedHeaders", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Credential")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Credential", valid_601845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601847: Call_ListGatewayGroups_601833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
  ## 
  let valid = call_601847.validator(path, query, header, formData, body)
  let scheme = call_601847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601847.url(scheme.get, call_601847.host, call_601847.base,
                         call_601847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601847, url, valid)

proc call*(call_601848: Call_ListGatewayGroups_601833; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listGatewayGroups
  ## Retrieves a list of gateway group summaries. Use GetGatewayGroup to retrieve details of a specific gateway group.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601849 = newJObject()
  var body_601850 = newJObject()
  add(query_601849, "NextToken", newJString(NextToken))
  if body != nil:
    body_601850 = body
  add(query_601849, "MaxResults", newJString(MaxResults))
  result = call_601848.call(nil, query_601849, nil, nil, body_601850)

var listGatewayGroups* = Call_ListGatewayGroups_601833(name: "listGatewayGroups",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListGatewayGroups",
    validator: validate_ListGatewayGroups_601834, base: "/",
    url: url_ListGatewayGroups_601835, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGateways_601851 = ref object of OpenApiRestCall_600437
proc url_ListGateways_601853(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGateways_601852(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601854 = query.getOrDefault("NextToken")
  valid_601854 = validateParameter(valid_601854, JString, required = false,
                                 default = nil)
  if valid_601854 != nil:
    section.add "NextToken", valid_601854
  var valid_601855 = query.getOrDefault("MaxResults")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "MaxResults", valid_601855
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601856 = header.getOrDefault("X-Amz-Date")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Date", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Security-Token")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Security-Token", valid_601857
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601858 = header.getOrDefault("X-Amz-Target")
  valid_601858 = validateParameter(valid_601858, JString, required = true, default = newJString(
      "AlexaForBusiness.ListGateways"))
  if valid_601858 != nil:
    section.add "X-Amz-Target", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Content-Sha256", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Signature")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Signature", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-SignedHeaders", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Credential")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Credential", valid_601863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601865: Call_ListGateways_601851; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
  ## 
  let valid = call_601865.validator(path, query, header, formData, body)
  let scheme = call_601865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601865.url(scheme.get, call_601865.host, call_601865.base,
                         call_601865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601865, url, valid)

proc call*(call_601866: Call_ListGateways_601851; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listGateways
  ## Retrieves a list of gateway summaries. Use GetGateway to retrieve details of a specific gateway. An optional gateway group ARN can be provided to only retrieve gateway summaries of gateways that are associated with that gateway group ARN.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601867 = newJObject()
  var body_601868 = newJObject()
  add(query_601867, "NextToken", newJString(NextToken))
  if body != nil:
    body_601868 = body
  add(query_601867, "MaxResults", newJString(MaxResults))
  result = call_601866.call(nil, query_601867, nil, nil, body_601868)

var listGateways* = Call_ListGateways_601851(name: "listGateways",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListGateways",
    validator: validate_ListGateways_601852, base: "/", url: url_ListGateways_601853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkills_601869 = ref object of OpenApiRestCall_600437
proc url_ListSkills_601871(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSkills_601870(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601872 = query.getOrDefault("NextToken")
  valid_601872 = validateParameter(valid_601872, JString, required = false,
                                 default = nil)
  if valid_601872 != nil:
    section.add "NextToken", valid_601872
  var valid_601873 = query.getOrDefault("MaxResults")
  valid_601873 = validateParameter(valid_601873, JString, required = false,
                                 default = nil)
  if valid_601873 != nil:
    section.add "MaxResults", valid_601873
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601874 = header.getOrDefault("X-Amz-Date")
  valid_601874 = validateParameter(valid_601874, JString, required = false,
                                 default = nil)
  if valid_601874 != nil:
    section.add "X-Amz-Date", valid_601874
  var valid_601875 = header.getOrDefault("X-Amz-Security-Token")
  valid_601875 = validateParameter(valid_601875, JString, required = false,
                                 default = nil)
  if valid_601875 != nil:
    section.add "X-Amz-Security-Token", valid_601875
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601876 = header.getOrDefault("X-Amz-Target")
  valid_601876 = validateParameter(valid_601876, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkills"))
  if valid_601876 != nil:
    section.add "X-Amz-Target", valid_601876
  var valid_601877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601877 = validateParameter(valid_601877, JString, required = false,
                                 default = nil)
  if valid_601877 != nil:
    section.add "X-Amz-Content-Sha256", valid_601877
  var valid_601878 = header.getOrDefault("X-Amz-Algorithm")
  valid_601878 = validateParameter(valid_601878, JString, required = false,
                                 default = nil)
  if valid_601878 != nil:
    section.add "X-Amz-Algorithm", valid_601878
  var valid_601879 = header.getOrDefault("X-Amz-Signature")
  valid_601879 = validateParameter(valid_601879, JString, required = false,
                                 default = nil)
  if valid_601879 != nil:
    section.add "X-Amz-Signature", valid_601879
  var valid_601880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601880 = validateParameter(valid_601880, JString, required = false,
                                 default = nil)
  if valid_601880 != nil:
    section.add "X-Amz-SignedHeaders", valid_601880
  var valid_601881 = header.getOrDefault("X-Amz-Credential")
  valid_601881 = validateParameter(valid_601881, JString, required = false,
                                 default = nil)
  if valid_601881 != nil:
    section.add "X-Amz-Credential", valid_601881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601883: Call_ListSkills_601869; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all enabled skills in a specific skill group.
  ## 
  let valid = call_601883.validator(path, query, header, formData, body)
  let scheme = call_601883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601883.url(scheme.get, call_601883.host, call_601883.base,
                         call_601883.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601883, url, valid)

proc call*(call_601884: Call_ListSkills_601869; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSkills
  ## Lists all enabled skills in a specific skill group.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601885 = newJObject()
  var body_601886 = newJObject()
  add(query_601885, "NextToken", newJString(NextToken))
  if body != nil:
    body_601886 = body
  add(query_601885, "MaxResults", newJString(MaxResults))
  result = call_601884.call(nil, query_601885, nil, nil, body_601886)

var listSkills* = Call_ListSkills_601869(name: "listSkills",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ListSkills",
                                      validator: validate_ListSkills_601870,
                                      base: "/", url: url_ListSkills_601871,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkillsStoreCategories_601887 = ref object of OpenApiRestCall_600437
proc url_ListSkillsStoreCategories_601889(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSkillsStoreCategories_601888(path: JsonNode; query: JsonNode;
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
  var valid_601890 = query.getOrDefault("NextToken")
  valid_601890 = validateParameter(valid_601890, JString, required = false,
                                 default = nil)
  if valid_601890 != nil:
    section.add "NextToken", valid_601890
  var valid_601891 = query.getOrDefault("MaxResults")
  valid_601891 = validateParameter(valid_601891, JString, required = false,
                                 default = nil)
  if valid_601891 != nil:
    section.add "MaxResults", valid_601891
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601892 = header.getOrDefault("X-Amz-Date")
  valid_601892 = validateParameter(valid_601892, JString, required = false,
                                 default = nil)
  if valid_601892 != nil:
    section.add "X-Amz-Date", valid_601892
  var valid_601893 = header.getOrDefault("X-Amz-Security-Token")
  valid_601893 = validateParameter(valid_601893, JString, required = false,
                                 default = nil)
  if valid_601893 != nil:
    section.add "X-Amz-Security-Token", valid_601893
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601894 = header.getOrDefault("X-Amz-Target")
  valid_601894 = validateParameter(valid_601894, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkillsStoreCategories"))
  if valid_601894 != nil:
    section.add "X-Amz-Target", valid_601894
  var valid_601895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601895 = validateParameter(valid_601895, JString, required = false,
                                 default = nil)
  if valid_601895 != nil:
    section.add "X-Amz-Content-Sha256", valid_601895
  var valid_601896 = header.getOrDefault("X-Amz-Algorithm")
  valid_601896 = validateParameter(valid_601896, JString, required = false,
                                 default = nil)
  if valid_601896 != nil:
    section.add "X-Amz-Algorithm", valid_601896
  var valid_601897 = header.getOrDefault("X-Amz-Signature")
  valid_601897 = validateParameter(valid_601897, JString, required = false,
                                 default = nil)
  if valid_601897 != nil:
    section.add "X-Amz-Signature", valid_601897
  var valid_601898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601898 = validateParameter(valid_601898, JString, required = false,
                                 default = nil)
  if valid_601898 != nil:
    section.add "X-Amz-SignedHeaders", valid_601898
  var valid_601899 = header.getOrDefault("X-Amz-Credential")
  valid_601899 = validateParameter(valid_601899, JString, required = false,
                                 default = nil)
  if valid_601899 != nil:
    section.add "X-Amz-Credential", valid_601899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601901: Call_ListSkillsStoreCategories_601887; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all categories in the Alexa skill store.
  ## 
  let valid = call_601901.validator(path, query, header, formData, body)
  let scheme = call_601901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601901.url(scheme.get, call_601901.host, call_601901.base,
                         call_601901.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601901, url, valid)

proc call*(call_601902: Call_ListSkillsStoreCategories_601887; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSkillsStoreCategories
  ## Lists all categories in the Alexa skill store.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601903 = newJObject()
  var body_601904 = newJObject()
  add(query_601903, "NextToken", newJString(NextToken))
  if body != nil:
    body_601904 = body
  add(query_601903, "MaxResults", newJString(MaxResults))
  result = call_601902.call(nil, query_601903, nil, nil, body_601904)

var listSkillsStoreCategories* = Call_ListSkillsStoreCategories_601887(
    name: "listSkillsStoreCategories", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSkillsStoreCategories",
    validator: validate_ListSkillsStoreCategories_601888, base: "/",
    url: url_ListSkillsStoreCategories_601889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSkillsStoreSkillsByCategory_601905 = ref object of OpenApiRestCall_600437
proc url_ListSkillsStoreSkillsByCategory_601907(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSkillsStoreSkillsByCategory_601906(path: JsonNode;
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
  var valid_601908 = query.getOrDefault("NextToken")
  valid_601908 = validateParameter(valid_601908, JString, required = false,
                                 default = nil)
  if valid_601908 != nil:
    section.add "NextToken", valid_601908
  var valid_601909 = query.getOrDefault("MaxResults")
  valid_601909 = validateParameter(valid_601909, JString, required = false,
                                 default = nil)
  if valid_601909 != nil:
    section.add "MaxResults", valid_601909
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601910 = header.getOrDefault("X-Amz-Date")
  valid_601910 = validateParameter(valid_601910, JString, required = false,
                                 default = nil)
  if valid_601910 != nil:
    section.add "X-Amz-Date", valid_601910
  var valid_601911 = header.getOrDefault("X-Amz-Security-Token")
  valid_601911 = validateParameter(valid_601911, JString, required = false,
                                 default = nil)
  if valid_601911 != nil:
    section.add "X-Amz-Security-Token", valid_601911
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601912 = header.getOrDefault("X-Amz-Target")
  valid_601912 = validateParameter(valid_601912, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSkillsStoreSkillsByCategory"))
  if valid_601912 != nil:
    section.add "X-Amz-Target", valid_601912
  var valid_601913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601913 = validateParameter(valid_601913, JString, required = false,
                                 default = nil)
  if valid_601913 != nil:
    section.add "X-Amz-Content-Sha256", valid_601913
  var valid_601914 = header.getOrDefault("X-Amz-Algorithm")
  valid_601914 = validateParameter(valid_601914, JString, required = false,
                                 default = nil)
  if valid_601914 != nil:
    section.add "X-Amz-Algorithm", valid_601914
  var valid_601915 = header.getOrDefault("X-Amz-Signature")
  valid_601915 = validateParameter(valid_601915, JString, required = false,
                                 default = nil)
  if valid_601915 != nil:
    section.add "X-Amz-Signature", valid_601915
  var valid_601916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601916 = validateParameter(valid_601916, JString, required = false,
                                 default = nil)
  if valid_601916 != nil:
    section.add "X-Amz-SignedHeaders", valid_601916
  var valid_601917 = header.getOrDefault("X-Amz-Credential")
  valid_601917 = validateParameter(valid_601917, JString, required = false,
                                 default = nil)
  if valid_601917 != nil:
    section.add "X-Amz-Credential", valid_601917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601919: Call_ListSkillsStoreSkillsByCategory_601905;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all skills in the Alexa skill store by category.
  ## 
  let valid = call_601919.validator(path, query, header, formData, body)
  let scheme = call_601919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601919.url(scheme.get, call_601919.host, call_601919.base,
                         call_601919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601919, url, valid)

proc call*(call_601920: Call_ListSkillsStoreSkillsByCategory_601905;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSkillsStoreSkillsByCategory
  ## Lists all skills in the Alexa skill store by category.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601921 = newJObject()
  var body_601922 = newJObject()
  add(query_601921, "NextToken", newJString(NextToken))
  if body != nil:
    body_601922 = body
  add(query_601921, "MaxResults", newJString(MaxResults))
  result = call_601920.call(nil, query_601921, nil, nil, body_601922)

var listSkillsStoreSkillsByCategory* = Call_ListSkillsStoreSkillsByCategory_601905(
    name: "listSkillsStoreSkillsByCategory", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSkillsStoreSkillsByCategory",
    validator: validate_ListSkillsStoreSkillsByCategory_601906, base: "/",
    url: url_ListSkillsStoreSkillsByCategory_601907,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSmartHomeAppliances_601923 = ref object of OpenApiRestCall_600437
proc url_ListSmartHomeAppliances_601925(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSmartHomeAppliances_601924(path: JsonNode; query: JsonNode;
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
  var valid_601926 = query.getOrDefault("NextToken")
  valid_601926 = validateParameter(valid_601926, JString, required = false,
                                 default = nil)
  if valid_601926 != nil:
    section.add "NextToken", valid_601926
  var valid_601927 = query.getOrDefault("MaxResults")
  valid_601927 = validateParameter(valid_601927, JString, required = false,
                                 default = nil)
  if valid_601927 != nil:
    section.add "MaxResults", valid_601927
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601928 = header.getOrDefault("X-Amz-Date")
  valid_601928 = validateParameter(valid_601928, JString, required = false,
                                 default = nil)
  if valid_601928 != nil:
    section.add "X-Amz-Date", valid_601928
  var valid_601929 = header.getOrDefault("X-Amz-Security-Token")
  valid_601929 = validateParameter(valid_601929, JString, required = false,
                                 default = nil)
  if valid_601929 != nil:
    section.add "X-Amz-Security-Token", valid_601929
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601930 = header.getOrDefault("X-Amz-Target")
  valid_601930 = validateParameter(valid_601930, JString, required = true, default = newJString(
      "AlexaForBusiness.ListSmartHomeAppliances"))
  if valid_601930 != nil:
    section.add "X-Amz-Target", valid_601930
  var valid_601931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601931 = validateParameter(valid_601931, JString, required = false,
                                 default = nil)
  if valid_601931 != nil:
    section.add "X-Amz-Content-Sha256", valid_601931
  var valid_601932 = header.getOrDefault("X-Amz-Algorithm")
  valid_601932 = validateParameter(valid_601932, JString, required = false,
                                 default = nil)
  if valid_601932 != nil:
    section.add "X-Amz-Algorithm", valid_601932
  var valid_601933 = header.getOrDefault("X-Amz-Signature")
  valid_601933 = validateParameter(valid_601933, JString, required = false,
                                 default = nil)
  if valid_601933 != nil:
    section.add "X-Amz-Signature", valid_601933
  var valid_601934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601934 = validateParameter(valid_601934, JString, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "X-Amz-SignedHeaders", valid_601934
  var valid_601935 = header.getOrDefault("X-Amz-Credential")
  valid_601935 = validateParameter(valid_601935, JString, required = false,
                                 default = nil)
  if valid_601935 != nil:
    section.add "X-Amz-Credential", valid_601935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601937: Call_ListSmartHomeAppliances_601923; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all of the smart home appliances associated with a room.
  ## 
  let valid = call_601937.validator(path, query, header, formData, body)
  let scheme = call_601937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601937.url(scheme.get, call_601937.host, call_601937.base,
                         call_601937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601937, url, valid)

proc call*(call_601938: Call_ListSmartHomeAppliances_601923; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSmartHomeAppliances
  ## Lists all of the smart home appliances associated with a room.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601939 = newJObject()
  var body_601940 = newJObject()
  add(query_601939, "NextToken", newJString(NextToken))
  if body != nil:
    body_601940 = body
  add(query_601939, "MaxResults", newJString(MaxResults))
  result = call_601938.call(nil, query_601939, nil, nil, body_601940)

var listSmartHomeAppliances* = Call_ListSmartHomeAppliances_601923(
    name: "listSmartHomeAppliances", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.ListSmartHomeAppliances",
    validator: validate_ListSmartHomeAppliances_601924, base: "/",
    url: url_ListSmartHomeAppliances_601925, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_601941 = ref object of OpenApiRestCall_600437
proc url_ListTags_601943(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTags_601942(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601944 = query.getOrDefault("NextToken")
  valid_601944 = validateParameter(valid_601944, JString, required = false,
                                 default = nil)
  if valid_601944 != nil:
    section.add "NextToken", valid_601944
  var valid_601945 = query.getOrDefault("MaxResults")
  valid_601945 = validateParameter(valid_601945, JString, required = false,
                                 default = nil)
  if valid_601945 != nil:
    section.add "MaxResults", valid_601945
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601946 = header.getOrDefault("X-Amz-Date")
  valid_601946 = validateParameter(valid_601946, JString, required = false,
                                 default = nil)
  if valid_601946 != nil:
    section.add "X-Amz-Date", valid_601946
  var valid_601947 = header.getOrDefault("X-Amz-Security-Token")
  valid_601947 = validateParameter(valid_601947, JString, required = false,
                                 default = nil)
  if valid_601947 != nil:
    section.add "X-Amz-Security-Token", valid_601947
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601948 = header.getOrDefault("X-Amz-Target")
  valid_601948 = validateParameter(valid_601948, JString, required = true, default = newJString(
      "AlexaForBusiness.ListTags"))
  if valid_601948 != nil:
    section.add "X-Amz-Target", valid_601948
  var valid_601949 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "X-Amz-Content-Sha256", valid_601949
  var valid_601950 = header.getOrDefault("X-Amz-Algorithm")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "X-Amz-Algorithm", valid_601950
  var valid_601951 = header.getOrDefault("X-Amz-Signature")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "X-Amz-Signature", valid_601951
  var valid_601952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-SignedHeaders", valid_601952
  var valid_601953 = header.getOrDefault("X-Amz-Credential")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "X-Amz-Credential", valid_601953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601955: Call_ListTags_601941; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags for the specified resource.
  ## 
  let valid = call_601955.validator(path, query, header, formData, body)
  let scheme = call_601955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601955.url(scheme.get, call_601955.host, call_601955.base,
                         call_601955.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601955, url, valid)

proc call*(call_601956: Call_ListTags_601941; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listTags
  ## Lists all tags for the specified resource.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601957 = newJObject()
  var body_601958 = newJObject()
  add(query_601957, "NextToken", newJString(NextToken))
  if body != nil:
    body_601958 = body
  add(query_601957, "MaxResults", newJString(MaxResults))
  result = call_601956.call(nil, query_601957, nil, nil, body_601958)

var listTags* = Call_ListTags_601941(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ListTags",
                                  validator: validate_ListTags_601942, base: "/",
                                  url: url_ListTags_601943,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConferencePreference_601959 = ref object of OpenApiRestCall_600437
proc url_PutConferencePreference_601961(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutConferencePreference_601960(path: JsonNode; query: JsonNode;
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
  var valid_601962 = header.getOrDefault("X-Amz-Date")
  valid_601962 = validateParameter(valid_601962, JString, required = false,
                                 default = nil)
  if valid_601962 != nil:
    section.add "X-Amz-Date", valid_601962
  var valid_601963 = header.getOrDefault("X-Amz-Security-Token")
  valid_601963 = validateParameter(valid_601963, JString, required = false,
                                 default = nil)
  if valid_601963 != nil:
    section.add "X-Amz-Security-Token", valid_601963
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601964 = header.getOrDefault("X-Amz-Target")
  valid_601964 = validateParameter(valid_601964, JString, required = true, default = newJString(
      "AlexaForBusiness.PutConferencePreference"))
  if valid_601964 != nil:
    section.add "X-Amz-Target", valid_601964
  var valid_601965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601965 = validateParameter(valid_601965, JString, required = false,
                                 default = nil)
  if valid_601965 != nil:
    section.add "X-Amz-Content-Sha256", valid_601965
  var valid_601966 = header.getOrDefault("X-Amz-Algorithm")
  valid_601966 = validateParameter(valid_601966, JString, required = false,
                                 default = nil)
  if valid_601966 != nil:
    section.add "X-Amz-Algorithm", valid_601966
  var valid_601967 = header.getOrDefault("X-Amz-Signature")
  valid_601967 = validateParameter(valid_601967, JString, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "X-Amz-Signature", valid_601967
  var valid_601968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601968 = validateParameter(valid_601968, JString, required = false,
                                 default = nil)
  if valid_601968 != nil:
    section.add "X-Amz-SignedHeaders", valid_601968
  var valid_601969 = header.getOrDefault("X-Amz-Credential")
  valid_601969 = validateParameter(valid_601969, JString, required = false,
                                 default = nil)
  if valid_601969 != nil:
    section.add "X-Amz-Credential", valid_601969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601971: Call_PutConferencePreference_601959; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the conference preferences on a specific conference provider at the account level.
  ## 
  let valid = call_601971.validator(path, query, header, formData, body)
  let scheme = call_601971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601971.url(scheme.get, call_601971.host, call_601971.base,
                         call_601971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601971, url, valid)

proc call*(call_601972: Call_PutConferencePreference_601959; body: JsonNode): Recallable =
  ## putConferencePreference
  ## Sets the conference preferences on a specific conference provider at the account level.
  ##   body: JObject (required)
  var body_601973 = newJObject()
  if body != nil:
    body_601973 = body
  result = call_601972.call(nil, nil, nil, nil, body_601973)

var putConferencePreference* = Call_PutConferencePreference_601959(
    name: "putConferencePreference", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutConferencePreference",
    validator: validate_PutConferencePreference_601960, base: "/",
    url: url_PutConferencePreference_601961, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInvitationConfiguration_601974 = ref object of OpenApiRestCall_600437
proc url_PutInvitationConfiguration_601976(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutInvitationConfiguration_601975(path: JsonNode; query: JsonNode;
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
  var valid_601977 = header.getOrDefault("X-Amz-Date")
  valid_601977 = validateParameter(valid_601977, JString, required = false,
                                 default = nil)
  if valid_601977 != nil:
    section.add "X-Amz-Date", valid_601977
  var valid_601978 = header.getOrDefault("X-Amz-Security-Token")
  valid_601978 = validateParameter(valid_601978, JString, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "X-Amz-Security-Token", valid_601978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601979 = header.getOrDefault("X-Amz-Target")
  valid_601979 = validateParameter(valid_601979, JString, required = true, default = newJString(
      "AlexaForBusiness.PutInvitationConfiguration"))
  if valid_601979 != nil:
    section.add "X-Amz-Target", valid_601979
  var valid_601980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "X-Amz-Content-Sha256", valid_601980
  var valid_601981 = header.getOrDefault("X-Amz-Algorithm")
  valid_601981 = validateParameter(valid_601981, JString, required = false,
                                 default = nil)
  if valid_601981 != nil:
    section.add "X-Amz-Algorithm", valid_601981
  var valid_601982 = header.getOrDefault("X-Amz-Signature")
  valid_601982 = validateParameter(valid_601982, JString, required = false,
                                 default = nil)
  if valid_601982 != nil:
    section.add "X-Amz-Signature", valid_601982
  var valid_601983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "X-Amz-SignedHeaders", valid_601983
  var valid_601984 = header.getOrDefault("X-Amz-Credential")
  valid_601984 = validateParameter(valid_601984, JString, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "X-Amz-Credential", valid_601984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601986: Call_PutInvitationConfiguration_601974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the email template for the user enrollment invitation with the specified attributes.
  ## 
  let valid = call_601986.validator(path, query, header, formData, body)
  let scheme = call_601986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601986.url(scheme.get, call_601986.host, call_601986.base,
                         call_601986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601986, url, valid)

proc call*(call_601987: Call_PutInvitationConfiguration_601974; body: JsonNode): Recallable =
  ## putInvitationConfiguration
  ## Configures the email template for the user enrollment invitation with the specified attributes.
  ##   body: JObject (required)
  var body_601988 = newJObject()
  if body != nil:
    body_601988 = body
  result = call_601987.call(nil, nil, nil, nil, body_601988)

var putInvitationConfiguration* = Call_PutInvitationConfiguration_601974(
    name: "putInvitationConfiguration", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutInvitationConfiguration",
    validator: validate_PutInvitationConfiguration_601975, base: "/",
    url: url_PutInvitationConfiguration_601976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRoomSkillParameter_601989 = ref object of OpenApiRestCall_600437
proc url_PutRoomSkillParameter_601991(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutRoomSkillParameter_601990(path: JsonNode; query: JsonNode;
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
  var valid_601992 = header.getOrDefault("X-Amz-Date")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Date", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Security-Token")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Security-Token", valid_601993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601994 = header.getOrDefault("X-Amz-Target")
  valid_601994 = validateParameter(valid_601994, JString, required = true, default = newJString(
      "AlexaForBusiness.PutRoomSkillParameter"))
  if valid_601994 != nil:
    section.add "X-Amz-Target", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-Content-Sha256", valid_601995
  var valid_601996 = header.getOrDefault("X-Amz-Algorithm")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Algorithm", valid_601996
  var valid_601997 = header.getOrDefault("X-Amz-Signature")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-Signature", valid_601997
  var valid_601998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "X-Amz-SignedHeaders", valid_601998
  var valid_601999 = header.getOrDefault("X-Amz-Credential")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-Credential", valid_601999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602001: Call_PutRoomSkillParameter_601989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room skill parameter details by room, skill, and parameter key ID. Not all skills have a room skill parameter.
  ## 
  let valid = call_602001.validator(path, query, header, formData, body)
  let scheme = call_602001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602001.url(scheme.get, call_602001.host, call_602001.base,
                         call_602001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602001, url, valid)

proc call*(call_602002: Call_PutRoomSkillParameter_601989; body: JsonNode): Recallable =
  ## putRoomSkillParameter
  ## Updates room skill parameter details by room, skill, and parameter key ID. Not all skills have a room skill parameter.
  ##   body: JObject (required)
  var body_602003 = newJObject()
  if body != nil:
    body_602003 = body
  result = call_602002.call(nil, nil, nil, nil, body_602003)

var putRoomSkillParameter* = Call_PutRoomSkillParameter_601989(
    name: "putRoomSkillParameter", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutRoomSkillParameter",
    validator: validate_PutRoomSkillParameter_601990, base: "/",
    url: url_PutRoomSkillParameter_601991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSkillAuthorization_602004 = ref object of OpenApiRestCall_600437
proc url_PutSkillAuthorization_602006(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutSkillAuthorization_602005(path: JsonNode; query: JsonNode;
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
  var valid_602007 = header.getOrDefault("X-Amz-Date")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Date", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Security-Token")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Security-Token", valid_602008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602009 = header.getOrDefault("X-Amz-Target")
  valid_602009 = validateParameter(valid_602009, JString, required = true, default = newJString(
      "AlexaForBusiness.PutSkillAuthorization"))
  if valid_602009 != nil:
    section.add "X-Amz-Target", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Content-Sha256", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Algorithm")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Algorithm", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Signature")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Signature", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-SignedHeaders", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-Credential")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-Credential", valid_602014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602016: Call_PutSkillAuthorization_602004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Links a user's account to a third-party skill provider. If this API operation is called by an assumed IAM role, the skill being linked must be a private skill. Also, the skill must be owned by the AWS account that assumed the IAM role.
  ## 
  let valid = call_602016.validator(path, query, header, formData, body)
  let scheme = call_602016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602016.url(scheme.get, call_602016.host, call_602016.base,
                         call_602016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602016, url, valid)

proc call*(call_602017: Call_PutSkillAuthorization_602004; body: JsonNode): Recallable =
  ## putSkillAuthorization
  ## Links a user's account to a third-party skill provider. If this API operation is called by an assumed IAM role, the skill being linked must be a private skill. Also, the skill must be owned by the AWS account that assumed the IAM role.
  ##   body: JObject (required)
  var body_602018 = newJObject()
  if body != nil:
    body_602018 = body
  result = call_602017.call(nil, nil, nil, nil, body_602018)

var putSkillAuthorization* = Call_PutSkillAuthorization_602004(
    name: "putSkillAuthorization", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.PutSkillAuthorization",
    validator: validate_PutSkillAuthorization_602005, base: "/",
    url: url_PutSkillAuthorization_602006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterAVSDevice_602019 = ref object of OpenApiRestCall_600437
proc url_RegisterAVSDevice_602021(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterAVSDevice_602020(path: JsonNode; query: JsonNode;
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
  var valid_602022 = header.getOrDefault("X-Amz-Date")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Date", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Security-Token")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Security-Token", valid_602023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602024 = header.getOrDefault("X-Amz-Target")
  valid_602024 = validateParameter(valid_602024, JString, required = true, default = newJString(
      "AlexaForBusiness.RegisterAVSDevice"))
  if valid_602024 != nil:
    section.add "X-Amz-Target", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Content-Sha256", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Algorithm")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Algorithm", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Signature")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Signature", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-SignedHeaders", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Credential")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Credential", valid_602029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602031: Call_RegisterAVSDevice_602019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers an Alexa-enabled device built by an Original Equipment Manufacturer (OEM) using Alexa Voice Service (AVS).
  ## 
  let valid = call_602031.validator(path, query, header, formData, body)
  let scheme = call_602031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602031.url(scheme.get, call_602031.host, call_602031.base,
                         call_602031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602031, url, valid)

proc call*(call_602032: Call_RegisterAVSDevice_602019; body: JsonNode): Recallable =
  ## registerAVSDevice
  ## Registers an Alexa-enabled device built by an Original Equipment Manufacturer (OEM) using Alexa Voice Service (AVS).
  ##   body: JObject (required)
  var body_602033 = newJObject()
  if body != nil:
    body_602033 = body
  result = call_602032.call(nil, nil, nil, nil, body_602033)

var registerAVSDevice* = Call_RegisterAVSDevice_602019(name: "registerAVSDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.RegisterAVSDevice",
    validator: validate_RegisterAVSDevice_602020, base: "/",
    url: url_RegisterAVSDevice_602021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectSkill_602034 = ref object of OpenApiRestCall_600437
proc url_RejectSkill_602036(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RejectSkill_602035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602037 = header.getOrDefault("X-Amz-Date")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Date", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Security-Token")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Security-Token", valid_602038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602039 = header.getOrDefault("X-Amz-Target")
  valid_602039 = validateParameter(valid_602039, JString, required = true, default = newJString(
      "AlexaForBusiness.RejectSkill"))
  if valid_602039 != nil:
    section.add "X-Amz-Target", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Content-Sha256", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Algorithm")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Algorithm", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Signature")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Signature", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-SignedHeaders", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Credential")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Credential", valid_602044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602046: Call_RejectSkill_602034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a skill from the organization under a user's AWS account. If the skill is a private skill, it moves to an AcceptStatus of PENDING. Any private or public skill that is rejected can be added later by calling the ApproveSkill API. 
  ## 
  let valid = call_602046.validator(path, query, header, formData, body)
  let scheme = call_602046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602046.url(scheme.get, call_602046.host, call_602046.base,
                         call_602046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602046, url, valid)

proc call*(call_602047: Call_RejectSkill_602034; body: JsonNode): Recallable =
  ## rejectSkill
  ## Disassociates a skill from the organization under a user's AWS account. If the skill is a private skill, it moves to an AcceptStatus of PENDING. Any private or public skill that is rejected can be added later by calling the ApproveSkill API. 
  ##   body: JObject (required)
  var body_602048 = newJObject()
  if body != nil:
    body_602048 = body
  result = call_602047.call(nil, nil, nil, nil, body_602048)

var rejectSkill* = Call_RejectSkill_602034(name: "rejectSkill",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.RejectSkill",
                                        validator: validate_RejectSkill_602035,
                                        base: "/", url: url_RejectSkill_602036,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResolveRoom_602049 = ref object of OpenApiRestCall_600437
proc url_ResolveRoom_602051(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResolveRoom_602050(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602052 = header.getOrDefault("X-Amz-Date")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Date", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Security-Token")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Security-Token", valid_602053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602054 = header.getOrDefault("X-Amz-Target")
  valid_602054 = validateParameter(valid_602054, JString, required = true, default = newJString(
      "AlexaForBusiness.ResolveRoom"))
  if valid_602054 != nil:
    section.add "X-Amz-Target", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Content-Sha256", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Algorithm")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Algorithm", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Signature")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Signature", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-SignedHeaders", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-Credential")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Credential", valid_602059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602061: Call_ResolveRoom_602049; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Determines the details for the room from which a skill request was invoked. This operation is used by skill developers.
  ## 
  let valid = call_602061.validator(path, query, header, formData, body)
  let scheme = call_602061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602061.url(scheme.get, call_602061.host, call_602061.base,
                         call_602061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602061, url, valid)

proc call*(call_602062: Call_ResolveRoom_602049; body: JsonNode): Recallable =
  ## resolveRoom
  ## Determines the details for the room from which a skill request was invoked. This operation is used by skill developers.
  ##   body: JObject (required)
  var body_602063 = newJObject()
  if body != nil:
    body_602063 = body
  result = call_602062.call(nil, nil, nil, nil, body_602063)

var resolveRoom* = Call_ResolveRoom_602049(name: "resolveRoom",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.ResolveRoom",
                                        validator: validate_ResolveRoom_602050,
                                        base: "/", url: url_ResolveRoom_602051,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeInvitation_602064 = ref object of OpenApiRestCall_600437
proc url_RevokeInvitation_602066(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RevokeInvitation_602065(path: JsonNode; query: JsonNode;
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
  var valid_602067 = header.getOrDefault("X-Amz-Date")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Date", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Security-Token")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Security-Token", valid_602068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602069 = header.getOrDefault("X-Amz-Target")
  valid_602069 = validateParameter(valid_602069, JString, required = true, default = newJString(
      "AlexaForBusiness.RevokeInvitation"))
  if valid_602069 != nil:
    section.add "X-Amz-Target", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Content-Sha256", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Algorithm")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Algorithm", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Signature")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Signature", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-SignedHeaders", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Credential")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Credential", valid_602074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602076: Call_RevokeInvitation_602064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes an invitation and invalidates the enrollment URL.
  ## 
  let valid = call_602076.validator(path, query, header, formData, body)
  let scheme = call_602076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602076.url(scheme.get, call_602076.host, call_602076.base,
                         call_602076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602076, url, valid)

proc call*(call_602077: Call_RevokeInvitation_602064; body: JsonNode): Recallable =
  ## revokeInvitation
  ## Revokes an invitation and invalidates the enrollment URL.
  ##   body: JObject (required)
  var body_602078 = newJObject()
  if body != nil:
    body_602078 = body
  result = call_602077.call(nil, nil, nil, nil, body_602078)

var revokeInvitation* = Call_RevokeInvitation_602064(name: "revokeInvitation",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.RevokeInvitation",
    validator: validate_RevokeInvitation_602065, base: "/",
    url: url_RevokeInvitation_602066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchAddressBooks_602079 = ref object of OpenApiRestCall_600437
proc url_SearchAddressBooks_602081(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchAddressBooks_602080(path: JsonNode; query: JsonNode;
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
  var valid_602082 = query.getOrDefault("NextToken")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "NextToken", valid_602082
  var valid_602083 = query.getOrDefault("MaxResults")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "MaxResults", valid_602083
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602084 = header.getOrDefault("X-Amz-Date")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Date", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Security-Token")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Security-Token", valid_602085
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602086 = header.getOrDefault("X-Amz-Target")
  valid_602086 = validateParameter(valid_602086, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchAddressBooks"))
  if valid_602086 != nil:
    section.add "X-Amz-Target", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Content-Sha256", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Algorithm")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Algorithm", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Signature")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Signature", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-SignedHeaders", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Credential")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Credential", valid_602091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602093: Call_SearchAddressBooks_602079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_602093.validator(path, query, header, formData, body)
  let scheme = call_602093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602093.url(scheme.get, call_602093.host, call_602093.base,
                         call_602093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602093, url, valid)

proc call*(call_602094: Call_SearchAddressBooks_602079; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchAddressBooks
  ## Searches address books and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_602095 = newJObject()
  var body_602096 = newJObject()
  add(query_602095, "NextToken", newJString(NextToken))
  if body != nil:
    body_602096 = body
  add(query_602095, "MaxResults", newJString(MaxResults))
  result = call_602094.call(nil, query_602095, nil, nil, body_602096)

var searchAddressBooks* = Call_SearchAddressBooks_602079(
    name: "searchAddressBooks", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchAddressBooks",
    validator: validate_SearchAddressBooks_602080, base: "/",
    url: url_SearchAddressBooks_602081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchContacts_602097 = ref object of OpenApiRestCall_600437
proc url_SearchContacts_602099(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchContacts_602098(path: JsonNode; query: JsonNode;
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
  var valid_602100 = query.getOrDefault("NextToken")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "NextToken", valid_602100
  var valid_602101 = query.getOrDefault("MaxResults")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "MaxResults", valid_602101
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602102 = header.getOrDefault("X-Amz-Date")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Date", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Security-Token")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Security-Token", valid_602103
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602104 = header.getOrDefault("X-Amz-Target")
  valid_602104 = validateParameter(valid_602104, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchContacts"))
  if valid_602104 != nil:
    section.add "X-Amz-Target", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Content-Sha256", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Algorithm")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Algorithm", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Signature")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Signature", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-SignedHeaders", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Credential")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Credential", valid_602109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602111: Call_SearchContacts_602097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_602111.validator(path, query, header, formData, body)
  let scheme = call_602111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602111.url(scheme.get, call_602111.host, call_602111.base,
                         call_602111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602111, url, valid)

proc call*(call_602112: Call_SearchContacts_602097; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchContacts
  ## Searches contacts and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_602113 = newJObject()
  var body_602114 = newJObject()
  add(query_602113, "NextToken", newJString(NextToken))
  if body != nil:
    body_602114 = body
  add(query_602113, "MaxResults", newJString(MaxResults))
  result = call_602112.call(nil, query_602113, nil, nil, body_602114)

var searchContacts* = Call_SearchContacts_602097(name: "searchContacts",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchContacts",
    validator: validate_SearchContacts_602098, base: "/", url: url_SearchContacts_602099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchDevices_602115 = ref object of OpenApiRestCall_600437
proc url_SearchDevices_602117(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchDevices_602116(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602118 = query.getOrDefault("NextToken")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "NextToken", valid_602118
  var valid_602119 = query.getOrDefault("MaxResults")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "MaxResults", valid_602119
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602120 = header.getOrDefault("X-Amz-Date")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Date", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Security-Token")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Security-Token", valid_602121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602122 = header.getOrDefault("X-Amz-Target")
  valid_602122 = validateParameter(valid_602122, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchDevices"))
  if valid_602122 != nil:
    section.add "X-Amz-Target", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Content-Sha256", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Algorithm")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Algorithm", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Signature")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Signature", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-SignedHeaders", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Credential")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Credential", valid_602127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602129: Call_SearchDevices_602115; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches devices and lists the ones that meet a set of filter criteria.
  ## 
  let valid = call_602129.validator(path, query, header, formData, body)
  let scheme = call_602129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602129.url(scheme.get, call_602129.host, call_602129.base,
                         call_602129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602129, url, valid)

proc call*(call_602130: Call_SearchDevices_602115; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchDevices
  ## Searches devices and lists the ones that meet a set of filter criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_602131 = newJObject()
  var body_602132 = newJObject()
  add(query_602131, "NextToken", newJString(NextToken))
  if body != nil:
    body_602132 = body
  add(query_602131, "MaxResults", newJString(MaxResults))
  result = call_602130.call(nil, query_602131, nil, nil, body_602132)

var searchDevices* = Call_SearchDevices_602115(name: "searchDevices",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchDevices",
    validator: validate_SearchDevices_602116, base: "/", url: url_SearchDevices_602117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchNetworkProfiles_602133 = ref object of OpenApiRestCall_600437
proc url_SearchNetworkProfiles_602135(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchNetworkProfiles_602134(path: JsonNode; query: JsonNode;
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
  var valid_602136 = query.getOrDefault("NextToken")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "NextToken", valid_602136
  var valid_602137 = query.getOrDefault("MaxResults")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "MaxResults", valid_602137
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602138 = header.getOrDefault("X-Amz-Date")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Date", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Security-Token")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Security-Token", valid_602139
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602140 = header.getOrDefault("X-Amz-Target")
  valid_602140 = validateParameter(valid_602140, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchNetworkProfiles"))
  if valid_602140 != nil:
    section.add "X-Amz-Target", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Content-Sha256", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Algorithm")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Algorithm", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Signature")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Signature", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-SignedHeaders", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Credential")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Credential", valid_602145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602147: Call_SearchNetworkProfiles_602133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_602147.validator(path, query, header, formData, body)
  let scheme = call_602147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602147.url(scheme.get, call_602147.host, call_602147.base,
                         call_602147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602147, url, valid)

proc call*(call_602148: Call_SearchNetworkProfiles_602133; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchNetworkProfiles
  ## Searches network profiles and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_602149 = newJObject()
  var body_602150 = newJObject()
  add(query_602149, "NextToken", newJString(NextToken))
  if body != nil:
    body_602150 = body
  add(query_602149, "MaxResults", newJString(MaxResults))
  result = call_602148.call(nil, query_602149, nil, nil, body_602150)

var searchNetworkProfiles* = Call_SearchNetworkProfiles_602133(
    name: "searchNetworkProfiles", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchNetworkProfiles",
    validator: validate_SearchNetworkProfiles_602134, base: "/",
    url: url_SearchNetworkProfiles_602135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProfiles_602151 = ref object of OpenApiRestCall_600437
proc url_SearchProfiles_602153(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchProfiles_602152(path: JsonNode; query: JsonNode;
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
  var valid_602154 = query.getOrDefault("NextToken")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "NextToken", valid_602154
  var valid_602155 = query.getOrDefault("MaxResults")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "MaxResults", valid_602155
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602156 = header.getOrDefault("X-Amz-Date")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Date", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Security-Token")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Security-Token", valid_602157
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602158 = header.getOrDefault("X-Amz-Target")
  valid_602158 = validateParameter(valid_602158, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchProfiles"))
  if valid_602158 != nil:
    section.add "X-Amz-Target", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Content-Sha256", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Algorithm")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Algorithm", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Signature")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Signature", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-SignedHeaders", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Credential")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Credential", valid_602163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602165: Call_SearchProfiles_602151; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
  ## 
  let valid = call_602165.validator(path, query, header, formData, body)
  let scheme = call_602165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602165.url(scheme.get, call_602165.host, call_602165.base,
                         call_602165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602165, url, valid)

proc call*(call_602166: Call_SearchProfiles_602151; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchProfiles
  ## Searches room profiles and lists the ones that meet a set of filter criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_602167 = newJObject()
  var body_602168 = newJObject()
  add(query_602167, "NextToken", newJString(NextToken))
  if body != nil:
    body_602168 = body
  add(query_602167, "MaxResults", newJString(MaxResults))
  result = call_602166.call(nil, query_602167, nil, nil, body_602168)

var searchProfiles* = Call_SearchProfiles_602151(name: "searchProfiles",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchProfiles",
    validator: validate_SearchProfiles_602152, base: "/", url: url_SearchProfiles_602153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchRooms_602169 = ref object of OpenApiRestCall_600437
proc url_SearchRooms_602171(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchRooms_602170(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602172 = query.getOrDefault("NextToken")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "NextToken", valid_602172
  var valid_602173 = query.getOrDefault("MaxResults")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "MaxResults", valid_602173
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602174 = header.getOrDefault("X-Amz-Date")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Date", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Security-Token")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Security-Token", valid_602175
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602176 = header.getOrDefault("X-Amz-Target")
  valid_602176 = validateParameter(valid_602176, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchRooms"))
  if valid_602176 != nil:
    section.add "X-Amz-Target", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Content-Sha256", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Algorithm")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Algorithm", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Signature")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Signature", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-SignedHeaders", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Credential")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Credential", valid_602181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602183: Call_SearchRooms_602169; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_602183.validator(path, query, header, formData, body)
  let scheme = call_602183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602183.url(scheme.get, call_602183.host, call_602183.base,
                         call_602183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602183, url, valid)

proc call*(call_602184: Call_SearchRooms_602169; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchRooms
  ## Searches rooms and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_602185 = newJObject()
  var body_602186 = newJObject()
  add(query_602185, "NextToken", newJString(NextToken))
  if body != nil:
    body_602186 = body
  add(query_602185, "MaxResults", newJString(MaxResults))
  result = call_602184.call(nil, query_602185, nil, nil, body_602186)

var searchRooms* = Call_SearchRooms_602169(name: "searchRooms",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.SearchRooms",
                                        validator: validate_SearchRooms_602170,
                                        base: "/", url: url_SearchRooms_602171,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSkillGroups_602187 = ref object of OpenApiRestCall_600437
proc url_SearchSkillGroups_602189(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchSkillGroups_602188(path: JsonNode; query: JsonNode;
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
  var valid_602190 = query.getOrDefault("NextToken")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "NextToken", valid_602190
  var valid_602191 = query.getOrDefault("MaxResults")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "MaxResults", valid_602191
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602192 = header.getOrDefault("X-Amz-Date")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Date", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Security-Token")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Security-Token", valid_602193
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602194 = header.getOrDefault("X-Amz-Target")
  valid_602194 = validateParameter(valid_602194, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchSkillGroups"))
  if valid_602194 != nil:
    section.add "X-Amz-Target", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Content-Sha256", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Algorithm")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Algorithm", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Signature")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Signature", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-SignedHeaders", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Credential")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Credential", valid_602199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602201: Call_SearchSkillGroups_602187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_602201.validator(path, query, header, formData, body)
  let scheme = call_602201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602201.url(scheme.get, call_602201.host, call_602201.base,
                         call_602201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602201, url, valid)

proc call*(call_602202: Call_SearchSkillGroups_602187; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchSkillGroups
  ## Searches skill groups and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_602203 = newJObject()
  var body_602204 = newJObject()
  add(query_602203, "NextToken", newJString(NextToken))
  if body != nil:
    body_602204 = body
  add(query_602203, "MaxResults", newJString(MaxResults))
  result = call_602202.call(nil, query_602203, nil, nil, body_602204)

var searchSkillGroups* = Call_SearchSkillGroups_602187(name: "searchSkillGroups",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SearchSkillGroups",
    validator: validate_SearchSkillGroups_602188, base: "/",
    url: url_SearchSkillGroups_602189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchUsers_602205 = ref object of OpenApiRestCall_600437
proc url_SearchUsers_602207(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchUsers_602206(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602208 = query.getOrDefault("NextToken")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "NextToken", valid_602208
  var valid_602209 = query.getOrDefault("MaxResults")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "MaxResults", valid_602209
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602210 = header.getOrDefault("X-Amz-Date")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Date", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Security-Token")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Security-Token", valid_602211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602212 = header.getOrDefault("X-Amz-Target")
  valid_602212 = validateParameter(valid_602212, JString, required = true, default = newJString(
      "AlexaForBusiness.SearchUsers"))
  if valid_602212 != nil:
    section.add "X-Amz-Target", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Content-Sha256", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Algorithm")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Algorithm", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Signature")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Signature", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-SignedHeaders", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Credential")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Credential", valid_602217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602219: Call_SearchUsers_602205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
  ## 
  let valid = call_602219.validator(path, query, header, formData, body)
  let scheme = call_602219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602219.url(scheme.get, call_602219.host, call_602219.base,
                         call_602219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602219, url, valid)

proc call*(call_602220: Call_SearchUsers_602205; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchUsers
  ## Searches users and lists the ones that meet a set of filter and sort criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_602221 = newJObject()
  var body_602222 = newJObject()
  add(query_602221, "NextToken", newJString(NextToken))
  if body != nil:
    body_602222 = body
  add(query_602221, "MaxResults", newJString(MaxResults))
  result = call_602220.call(nil, query_602221, nil, nil, body_602222)

var searchUsers* = Call_SearchUsers_602205(name: "searchUsers",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.SearchUsers",
                                        validator: validate_SearchUsers_602206,
                                        base: "/", url: url_SearchUsers_602207,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAnnouncement_602223 = ref object of OpenApiRestCall_600437
proc url_SendAnnouncement_602225(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendAnnouncement_602224(path: JsonNode; query: JsonNode;
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
  var valid_602226 = header.getOrDefault("X-Amz-Date")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Date", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Security-Token")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Security-Token", valid_602227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602228 = header.getOrDefault("X-Amz-Target")
  valid_602228 = validateParameter(valid_602228, JString, required = true, default = newJString(
      "AlexaForBusiness.SendAnnouncement"))
  if valid_602228 != nil:
    section.add "X-Amz-Target", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Content-Sha256", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Algorithm")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Algorithm", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Signature")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Signature", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-SignedHeaders", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Credential")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Credential", valid_602233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602235: Call_SendAnnouncement_602223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Triggers an asynchronous flow to send text, SSML, or audio announcements to rooms that are identified by a search or filter. 
  ## 
  let valid = call_602235.validator(path, query, header, formData, body)
  let scheme = call_602235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602235.url(scheme.get, call_602235.host, call_602235.base,
                         call_602235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602235, url, valid)

proc call*(call_602236: Call_SendAnnouncement_602223; body: JsonNode): Recallable =
  ## sendAnnouncement
  ## Triggers an asynchronous flow to send text, SSML, or audio announcements to rooms that are identified by a search or filter. 
  ##   body: JObject (required)
  var body_602237 = newJObject()
  if body != nil:
    body_602237 = body
  result = call_602236.call(nil, nil, nil, nil, body_602237)

var sendAnnouncement* = Call_SendAnnouncement_602223(name: "sendAnnouncement",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SendAnnouncement",
    validator: validate_SendAnnouncement_602224, base: "/",
    url: url_SendAnnouncement_602225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendInvitation_602238 = ref object of OpenApiRestCall_600437
proc url_SendInvitation_602240(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendInvitation_602239(path: JsonNode; query: JsonNode;
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
  var valid_602241 = header.getOrDefault("X-Amz-Date")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Date", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Security-Token")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Security-Token", valid_602242
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602243 = header.getOrDefault("X-Amz-Target")
  valid_602243 = validateParameter(valid_602243, JString, required = true, default = newJString(
      "AlexaForBusiness.SendInvitation"))
  if valid_602243 != nil:
    section.add "X-Amz-Target", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Content-Sha256", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Algorithm")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Algorithm", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Signature")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Signature", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-SignedHeaders", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Credential")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Credential", valid_602248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602250: Call_SendInvitation_602238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends an enrollment invitation email with a URL to a user. The URL is valid for 30 days or until you call this operation again, whichever comes first. 
  ## 
  let valid = call_602250.validator(path, query, header, formData, body)
  let scheme = call_602250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602250.url(scheme.get, call_602250.host, call_602250.base,
                         call_602250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602250, url, valid)

proc call*(call_602251: Call_SendInvitation_602238; body: JsonNode): Recallable =
  ## sendInvitation
  ## Sends an enrollment invitation email with a URL to a user. The URL is valid for 30 days or until you call this operation again, whichever comes first. 
  ##   body: JObject (required)
  var body_602252 = newJObject()
  if body != nil:
    body_602252 = body
  result = call_602251.call(nil, nil, nil, nil, body_602252)

var sendInvitation* = Call_SendInvitation_602238(name: "sendInvitation",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.SendInvitation",
    validator: validate_SendInvitation_602239, base: "/", url: url_SendInvitation_602240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeviceSync_602253 = ref object of OpenApiRestCall_600437
proc url_StartDeviceSync_602255(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartDeviceSync_602254(path: JsonNode; query: JsonNode;
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
  var valid_602256 = header.getOrDefault("X-Amz-Date")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Date", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Security-Token")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Security-Token", valid_602257
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602258 = header.getOrDefault("X-Amz-Target")
  valid_602258 = validateParameter(valid_602258, JString, required = true, default = newJString(
      "AlexaForBusiness.StartDeviceSync"))
  if valid_602258 != nil:
    section.add "X-Amz-Target", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Content-Sha256", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Algorithm")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Algorithm", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-Signature")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Signature", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-SignedHeaders", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-Credential")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Credential", valid_602263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602265: Call_StartDeviceSync_602253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets a device and its account to the known default settings. This clears all information and settings set by previous users in the following ways:</p> <ul> <li> <p>Bluetooth - This unpairs all bluetooth devices paired with your echo device.</p> </li> <li> <p>Volume - This resets the echo device's volume to the default value.</p> </li> <li> <p>Notifications - This clears all notifications from your echo device.</p> </li> <li> <p>Lists - This clears all to-do items from your echo device.</p> </li> <li> <p>Settings - This internally syncs the room's profile (if the device is assigned to a room), contacts, address books, delegation access for account linking, and communications (if enabled on the room profile).</p> </li> </ul>
  ## 
  let valid = call_602265.validator(path, query, header, formData, body)
  let scheme = call_602265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602265.url(scheme.get, call_602265.host, call_602265.base,
                         call_602265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602265, url, valid)

proc call*(call_602266: Call_StartDeviceSync_602253; body: JsonNode): Recallable =
  ## startDeviceSync
  ## <p>Resets a device and its account to the known default settings. This clears all information and settings set by previous users in the following ways:</p> <ul> <li> <p>Bluetooth - This unpairs all bluetooth devices paired with your echo device.</p> </li> <li> <p>Volume - This resets the echo device's volume to the default value.</p> </li> <li> <p>Notifications - This clears all notifications from your echo device.</p> </li> <li> <p>Lists - This clears all to-do items from your echo device.</p> </li> <li> <p>Settings - This internally syncs the room's profile (if the device is assigned to a room), contacts, address books, delegation access for account linking, and communications (if enabled on the room profile).</p> </li> </ul>
  ##   body: JObject (required)
  var body_602267 = newJObject()
  if body != nil:
    body_602267 = body
  result = call_602266.call(nil, nil, nil, nil, body_602267)

var startDeviceSync* = Call_StartDeviceSync_602253(name: "startDeviceSync",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.StartDeviceSync",
    validator: validate_StartDeviceSync_602254, base: "/", url: url_StartDeviceSync_602255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSmartHomeApplianceDiscovery_602268 = ref object of OpenApiRestCall_600437
proc url_StartSmartHomeApplianceDiscovery_602270(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartSmartHomeApplianceDiscovery_602269(path: JsonNode;
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
  var valid_602271 = header.getOrDefault("X-Amz-Date")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Date", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Security-Token")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Security-Token", valid_602272
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602273 = header.getOrDefault("X-Amz-Target")
  valid_602273 = validateParameter(valid_602273, JString, required = true, default = newJString(
      "AlexaForBusiness.StartSmartHomeApplianceDiscovery"))
  if valid_602273 != nil:
    section.add "X-Amz-Target", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Content-Sha256", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Algorithm")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Algorithm", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Signature")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Signature", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-SignedHeaders", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Credential")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Credential", valid_602278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602280: Call_StartSmartHomeApplianceDiscovery_602268;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Initiates the discovery of any smart home appliances associated with the room.
  ## 
  let valid = call_602280.validator(path, query, header, formData, body)
  let scheme = call_602280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602280.url(scheme.get, call_602280.host, call_602280.base,
                         call_602280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602280, url, valid)

proc call*(call_602281: Call_StartSmartHomeApplianceDiscovery_602268;
          body: JsonNode): Recallable =
  ## startSmartHomeApplianceDiscovery
  ## Initiates the discovery of any smart home appliances associated with the room.
  ##   body: JObject (required)
  var body_602282 = newJObject()
  if body != nil:
    body_602282 = body
  result = call_602281.call(nil, nil, nil, nil, body_602282)

var startSmartHomeApplianceDiscovery* = Call_StartSmartHomeApplianceDiscovery_602268(
    name: "startSmartHomeApplianceDiscovery", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.StartSmartHomeApplianceDiscovery",
    validator: validate_StartSmartHomeApplianceDiscovery_602269, base: "/",
    url: url_StartSmartHomeApplianceDiscovery_602270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602283 = ref object of OpenApiRestCall_600437
proc url_TagResource_602285(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_602284(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602286 = header.getOrDefault("X-Amz-Date")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Date", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Security-Token")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Security-Token", valid_602287
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602288 = header.getOrDefault("X-Amz-Target")
  valid_602288 = validateParameter(valid_602288, JString, required = true, default = newJString(
      "AlexaForBusiness.TagResource"))
  if valid_602288 != nil:
    section.add "X-Amz-Target", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Content-Sha256", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-Algorithm")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Algorithm", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Signature")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Signature", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-SignedHeaders", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-Credential")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Credential", valid_602293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602295: Call_TagResource_602283; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to a specified resource.
  ## 
  let valid = call_602295.validator(path, query, header, formData, body)
  let scheme = call_602295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602295.url(scheme.get, call_602295.host, call_602295.base,
                         call_602295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602295, url, valid)

proc call*(call_602296: Call_TagResource_602283; body: JsonNode): Recallable =
  ## tagResource
  ## Adds metadata tags to a specified resource.
  ##   body: JObject (required)
  var body_602297 = newJObject()
  if body != nil:
    body_602297 = body
  result = call_602296.call(nil, nil, nil, nil, body_602297)

var tagResource* = Call_TagResource_602283(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.TagResource",
                                        validator: validate_TagResource_602284,
                                        base: "/", url: url_TagResource_602285,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602298 = ref object of OpenApiRestCall_600437
proc url_UntagResource_602300(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_602299(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602301 = header.getOrDefault("X-Amz-Date")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Date", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Security-Token")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Security-Token", valid_602302
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602303 = header.getOrDefault("X-Amz-Target")
  valid_602303 = validateParameter(valid_602303, JString, required = true, default = newJString(
      "AlexaForBusiness.UntagResource"))
  if valid_602303 != nil:
    section.add "X-Amz-Target", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Content-Sha256", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Algorithm")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Algorithm", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-Signature")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-Signature", valid_602306
  var valid_602307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-SignedHeaders", valid_602307
  var valid_602308 = header.getOrDefault("X-Amz-Credential")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Credential", valid_602308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602310: Call_UntagResource_602298; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from a specified resource.
  ## 
  let valid = call_602310.validator(path, query, header, formData, body)
  let scheme = call_602310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602310.url(scheme.get, call_602310.host, call_602310.base,
                         call_602310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602310, url, valid)

proc call*(call_602311: Call_UntagResource_602298; body: JsonNode): Recallable =
  ## untagResource
  ## Removes metadata tags from a specified resource.
  ##   body: JObject (required)
  var body_602312 = newJObject()
  if body != nil:
    body_602312 = body
  result = call_602311.call(nil, nil, nil, nil, body_602312)

var untagResource* = Call_UntagResource_602298(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UntagResource",
    validator: validate_UntagResource_602299, base: "/", url: url_UntagResource_602300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAddressBook_602313 = ref object of OpenApiRestCall_600437
proc url_UpdateAddressBook_602315(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAddressBook_602314(path: JsonNode; query: JsonNode;
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
  var valid_602316 = header.getOrDefault("X-Amz-Date")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Date", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Security-Token")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Security-Token", valid_602317
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602318 = header.getOrDefault("X-Amz-Target")
  valid_602318 = validateParameter(valid_602318, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateAddressBook"))
  if valid_602318 != nil:
    section.add "X-Amz-Target", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Content-Sha256", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Algorithm")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Algorithm", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-Signature")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Signature", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-SignedHeaders", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Credential")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Credential", valid_602323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602325: Call_UpdateAddressBook_602313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates address book details by the address book ARN.
  ## 
  let valid = call_602325.validator(path, query, header, formData, body)
  let scheme = call_602325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602325.url(scheme.get, call_602325.host, call_602325.base,
                         call_602325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602325, url, valid)

proc call*(call_602326: Call_UpdateAddressBook_602313; body: JsonNode): Recallable =
  ## updateAddressBook
  ## Updates address book details by the address book ARN.
  ##   body: JObject (required)
  var body_602327 = newJObject()
  if body != nil:
    body_602327 = body
  result = call_602326.call(nil, nil, nil, nil, body_602327)

var updateAddressBook* = Call_UpdateAddressBook_602313(name: "updateAddressBook",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateAddressBook",
    validator: validate_UpdateAddressBook_602314, base: "/",
    url: url_UpdateAddressBook_602315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBusinessReportSchedule_602328 = ref object of OpenApiRestCall_600437
proc url_UpdateBusinessReportSchedule_602330(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateBusinessReportSchedule_602329(path: JsonNode; query: JsonNode;
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
  var valid_602331 = header.getOrDefault("X-Amz-Date")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Date", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Security-Token")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Security-Token", valid_602332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602333 = header.getOrDefault("X-Amz-Target")
  valid_602333 = validateParameter(valid_602333, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateBusinessReportSchedule"))
  if valid_602333 != nil:
    section.add "X-Amz-Target", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Content-Sha256", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Algorithm")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Algorithm", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-Signature")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Signature", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-SignedHeaders", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-Credential")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-Credential", valid_602338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602340: Call_UpdateBusinessReportSchedule_602328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration of the report delivery schedule with the specified schedule ARN.
  ## 
  let valid = call_602340.validator(path, query, header, formData, body)
  let scheme = call_602340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602340.url(scheme.get, call_602340.host, call_602340.base,
                         call_602340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602340, url, valid)

proc call*(call_602341: Call_UpdateBusinessReportSchedule_602328; body: JsonNode): Recallable =
  ## updateBusinessReportSchedule
  ## Updates the configuration of the report delivery schedule with the specified schedule ARN.
  ##   body: JObject (required)
  var body_602342 = newJObject()
  if body != nil:
    body_602342 = body
  result = call_602341.call(nil, nil, nil, nil, body_602342)

var updateBusinessReportSchedule* = Call_UpdateBusinessReportSchedule_602328(
    name: "updateBusinessReportSchedule", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateBusinessReportSchedule",
    validator: validate_UpdateBusinessReportSchedule_602329, base: "/",
    url: url_UpdateBusinessReportSchedule_602330,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConferenceProvider_602343 = ref object of OpenApiRestCall_600437
proc url_UpdateConferenceProvider_602345(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateConferenceProvider_602344(path: JsonNode; query: JsonNode;
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
  var valid_602346 = header.getOrDefault("X-Amz-Date")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Date", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Security-Token")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Security-Token", valid_602347
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602348 = header.getOrDefault("X-Amz-Target")
  valid_602348 = validateParameter(valid_602348, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateConferenceProvider"))
  if valid_602348 != nil:
    section.add "X-Amz-Target", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Content-Sha256", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Algorithm")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Algorithm", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Signature")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Signature", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-SignedHeaders", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Credential")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Credential", valid_602353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602355: Call_UpdateConferenceProvider_602343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing conference provider's settings.
  ## 
  let valid = call_602355.validator(path, query, header, formData, body)
  let scheme = call_602355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602355.url(scheme.get, call_602355.host, call_602355.base,
                         call_602355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602355, url, valid)

proc call*(call_602356: Call_UpdateConferenceProvider_602343; body: JsonNode): Recallable =
  ## updateConferenceProvider
  ## Updates an existing conference provider's settings.
  ##   body: JObject (required)
  var body_602357 = newJObject()
  if body != nil:
    body_602357 = body
  result = call_602356.call(nil, nil, nil, nil, body_602357)

var updateConferenceProvider* = Call_UpdateConferenceProvider_602343(
    name: "updateConferenceProvider", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateConferenceProvider",
    validator: validate_UpdateConferenceProvider_602344, base: "/",
    url: url_UpdateConferenceProvider_602345, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContact_602358 = ref object of OpenApiRestCall_600437
proc url_UpdateContact_602360(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateContact_602359(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602361 = header.getOrDefault("X-Amz-Date")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Date", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Security-Token")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Security-Token", valid_602362
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602363 = header.getOrDefault("X-Amz-Target")
  valid_602363 = validateParameter(valid_602363, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateContact"))
  if valid_602363 != nil:
    section.add "X-Amz-Target", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Content-Sha256", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Algorithm")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Algorithm", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Signature")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Signature", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-SignedHeaders", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Credential")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Credential", valid_602368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602370: Call_UpdateContact_602358; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the contact details by the contact ARN.
  ## 
  let valid = call_602370.validator(path, query, header, formData, body)
  let scheme = call_602370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602370.url(scheme.get, call_602370.host, call_602370.base,
                         call_602370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602370, url, valid)

proc call*(call_602371: Call_UpdateContact_602358; body: JsonNode): Recallable =
  ## updateContact
  ## Updates the contact details by the contact ARN.
  ##   body: JObject (required)
  var body_602372 = newJObject()
  if body != nil:
    body_602372 = body
  result = call_602371.call(nil, nil, nil, nil, body_602372)

var updateContact* = Call_UpdateContact_602358(name: "updateContact",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateContact",
    validator: validate_UpdateContact_602359, base: "/", url: url_UpdateContact_602360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevice_602373 = ref object of OpenApiRestCall_600437
proc url_UpdateDevice_602375(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDevice_602374(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602376 = header.getOrDefault("X-Amz-Date")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Date", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-Security-Token")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Security-Token", valid_602377
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602378 = header.getOrDefault("X-Amz-Target")
  valid_602378 = validateParameter(valid_602378, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateDevice"))
  if valid_602378 != nil:
    section.add "X-Amz-Target", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Content-Sha256", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-Algorithm")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Algorithm", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-Signature")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Signature", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-SignedHeaders", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Credential")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Credential", valid_602383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602385: Call_UpdateDevice_602373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the device name by device ARN.
  ## 
  let valid = call_602385.validator(path, query, header, formData, body)
  let scheme = call_602385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602385.url(scheme.get, call_602385.host, call_602385.base,
                         call_602385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602385, url, valid)

proc call*(call_602386: Call_UpdateDevice_602373; body: JsonNode): Recallable =
  ## updateDevice
  ## Updates the device name by device ARN.
  ##   body: JObject (required)
  var body_602387 = newJObject()
  if body != nil:
    body_602387 = body
  result = call_602386.call(nil, nil, nil, nil, body_602387)

var updateDevice* = Call_UpdateDevice_602373(name: "updateDevice",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateDevice",
    validator: validate_UpdateDevice_602374, base: "/", url: url_UpdateDevice_602375,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGateway_602388 = ref object of OpenApiRestCall_600437
proc url_UpdateGateway_602390(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGateway_602389(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602391 = header.getOrDefault("X-Amz-Date")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Date", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-Security-Token")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Security-Token", valid_602392
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602393 = header.getOrDefault("X-Amz-Target")
  valid_602393 = validateParameter(valid_602393, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateGateway"))
  if valid_602393 != nil:
    section.add "X-Amz-Target", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Content-Sha256", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Algorithm")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Algorithm", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Signature")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Signature", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-SignedHeaders", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Credential")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Credential", valid_602398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602400: Call_UpdateGateway_602388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details of a gateway. If any optional field is not provided, the existing corresponding value is left unmodified.
  ## 
  let valid = call_602400.validator(path, query, header, formData, body)
  let scheme = call_602400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602400.url(scheme.get, call_602400.host, call_602400.base,
                         call_602400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602400, url, valid)

proc call*(call_602401: Call_UpdateGateway_602388; body: JsonNode): Recallable =
  ## updateGateway
  ## Updates the details of a gateway. If any optional field is not provided, the existing corresponding value is left unmodified.
  ##   body: JObject (required)
  var body_602402 = newJObject()
  if body != nil:
    body_602402 = body
  result = call_602401.call(nil, nil, nil, nil, body_602402)

var updateGateway* = Call_UpdateGateway_602388(name: "updateGateway",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateGateway",
    validator: validate_UpdateGateway_602389, base: "/", url: url_UpdateGateway_602390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGatewayGroup_602403 = ref object of OpenApiRestCall_600437
proc url_UpdateGatewayGroup_602405(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGatewayGroup_602404(path: JsonNode; query: JsonNode;
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
  var valid_602406 = header.getOrDefault("X-Amz-Date")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Date", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-Security-Token")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Security-Token", valid_602407
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602408 = header.getOrDefault("X-Amz-Target")
  valid_602408 = validateParameter(valid_602408, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateGatewayGroup"))
  if valid_602408 != nil:
    section.add "X-Amz-Target", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Content-Sha256", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Algorithm")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Algorithm", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Signature")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Signature", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-SignedHeaders", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Credential")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Credential", valid_602413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602415: Call_UpdateGatewayGroup_602403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details of a gateway group. If any optional field is not provided, the existing corresponding value is left unmodified.
  ## 
  let valid = call_602415.validator(path, query, header, formData, body)
  let scheme = call_602415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602415.url(scheme.get, call_602415.host, call_602415.base,
                         call_602415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602415, url, valid)

proc call*(call_602416: Call_UpdateGatewayGroup_602403; body: JsonNode): Recallable =
  ## updateGatewayGroup
  ## Updates the details of a gateway group. If any optional field is not provided, the existing corresponding value is left unmodified.
  ##   body: JObject (required)
  var body_602417 = newJObject()
  if body != nil:
    body_602417 = body
  result = call_602416.call(nil, nil, nil, nil, body_602417)

var updateGatewayGroup* = Call_UpdateGatewayGroup_602403(
    name: "updateGatewayGroup", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateGatewayGroup",
    validator: validate_UpdateGatewayGroup_602404, base: "/",
    url: url_UpdateGatewayGroup_602405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNetworkProfile_602418 = ref object of OpenApiRestCall_600437
proc url_UpdateNetworkProfile_602420(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateNetworkProfile_602419(path: JsonNode; query: JsonNode;
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
  var valid_602421 = header.getOrDefault("X-Amz-Date")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Date", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-Security-Token")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-Security-Token", valid_602422
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602423 = header.getOrDefault("X-Amz-Target")
  valid_602423 = validateParameter(valid_602423, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateNetworkProfile"))
  if valid_602423 != nil:
    section.add "X-Amz-Target", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Content-Sha256", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Algorithm")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Algorithm", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-Signature")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-Signature", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-SignedHeaders", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Credential")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Credential", valid_602428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602430: Call_UpdateNetworkProfile_602418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a network profile by the network profile ARN.
  ## 
  let valid = call_602430.validator(path, query, header, formData, body)
  let scheme = call_602430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602430.url(scheme.get, call_602430.host, call_602430.base,
                         call_602430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602430, url, valid)

proc call*(call_602431: Call_UpdateNetworkProfile_602418; body: JsonNode): Recallable =
  ## updateNetworkProfile
  ## Updates a network profile by the network profile ARN.
  ##   body: JObject (required)
  var body_602432 = newJObject()
  if body != nil:
    body_602432 = body
  result = call_602431.call(nil, nil, nil, nil, body_602432)

var updateNetworkProfile* = Call_UpdateNetworkProfile_602418(
    name: "updateNetworkProfile", meth: HttpMethod.HttpPost,
    host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateNetworkProfile",
    validator: validate_UpdateNetworkProfile_602419, base: "/",
    url: url_UpdateNetworkProfile_602420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProfile_602433 = ref object of OpenApiRestCall_600437
proc url_UpdateProfile_602435(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProfile_602434(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602436 = header.getOrDefault("X-Amz-Date")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Date", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Security-Token")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Security-Token", valid_602437
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602438 = header.getOrDefault("X-Amz-Target")
  valid_602438 = validateParameter(valid_602438, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateProfile"))
  if valid_602438 != nil:
    section.add "X-Amz-Target", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-Content-Sha256", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-Algorithm")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Algorithm", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-Signature")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Signature", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-SignedHeaders", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Credential")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Credential", valid_602443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602445: Call_UpdateProfile_602433; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing room profile by room profile ARN.
  ## 
  let valid = call_602445.validator(path, query, header, formData, body)
  let scheme = call_602445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602445.url(scheme.get, call_602445.host, call_602445.base,
                         call_602445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602445, url, valid)

proc call*(call_602446: Call_UpdateProfile_602433; body: JsonNode): Recallable =
  ## updateProfile
  ## Updates an existing room profile by room profile ARN.
  ##   body: JObject (required)
  var body_602447 = newJObject()
  if body != nil:
    body_602447 = body
  result = call_602446.call(nil, nil, nil, nil, body_602447)

var updateProfile* = Call_UpdateProfile_602433(name: "updateProfile",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateProfile",
    validator: validate_UpdateProfile_602434, base: "/", url: url_UpdateProfile_602435,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoom_602448 = ref object of OpenApiRestCall_600437
proc url_UpdateRoom_602450(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRoom_602449(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602451 = header.getOrDefault("X-Amz-Date")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Date", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Security-Token")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Security-Token", valid_602452
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602453 = header.getOrDefault("X-Amz-Target")
  valid_602453 = validateParameter(valid_602453, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateRoom"))
  if valid_602453 != nil:
    section.add "X-Amz-Target", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Content-Sha256", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Algorithm")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Algorithm", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-Signature")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-Signature", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-SignedHeaders", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Credential")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Credential", valid_602458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602460: Call_UpdateRoom_602448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates room details by room ARN.
  ## 
  let valid = call_602460.validator(path, query, header, formData, body)
  let scheme = call_602460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602460.url(scheme.get, call_602460.host, call_602460.base,
                         call_602460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602460, url, valid)

proc call*(call_602461: Call_UpdateRoom_602448; body: JsonNode): Recallable =
  ## updateRoom
  ## Updates room details by room ARN.
  ##   body: JObject (required)
  var body_602462 = newJObject()
  if body != nil:
    body_602462 = body
  result = call_602461.call(nil, nil, nil, nil, body_602462)

var updateRoom* = Call_UpdateRoom_602448(name: "updateRoom",
                                      meth: HttpMethod.HttpPost,
                                      host: "a4b.amazonaws.com", route: "/#X-Amz-Target=AlexaForBusiness.UpdateRoom",
                                      validator: validate_UpdateRoom_602449,
                                      base: "/", url: url_UpdateRoom_602450,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSkillGroup_602463 = ref object of OpenApiRestCall_600437
proc url_UpdateSkillGroup_602465(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSkillGroup_602464(path: JsonNode; query: JsonNode;
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
  var valid_602466 = header.getOrDefault("X-Amz-Date")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Date", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Security-Token")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Security-Token", valid_602467
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602468 = header.getOrDefault("X-Amz-Target")
  valid_602468 = validateParameter(valid_602468, JString, required = true, default = newJString(
      "AlexaForBusiness.UpdateSkillGroup"))
  if valid_602468 != nil:
    section.add "X-Amz-Target", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Content-Sha256", valid_602469
  var valid_602470 = header.getOrDefault("X-Amz-Algorithm")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-Algorithm", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-Signature")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Signature", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-SignedHeaders", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Credential")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Credential", valid_602473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602475: Call_UpdateSkillGroup_602463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates skill group details by skill group ARN.
  ## 
  let valid = call_602475.validator(path, query, header, formData, body)
  let scheme = call_602475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602475.url(scheme.get, call_602475.host, call_602475.base,
                         call_602475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602475, url, valid)

proc call*(call_602476: Call_UpdateSkillGroup_602463; body: JsonNode): Recallable =
  ## updateSkillGroup
  ## Updates skill group details by skill group ARN.
  ##   body: JObject (required)
  var body_602477 = newJObject()
  if body != nil:
    body_602477 = body
  result = call_602476.call(nil, nil, nil, nil, body_602477)

var updateSkillGroup* = Call_UpdateSkillGroup_602463(name: "updateSkillGroup",
    meth: HttpMethod.HttpPost, host: "a4b.amazonaws.com",
    route: "/#X-Amz-Target=AlexaForBusiness.UpdateSkillGroup",
    validator: validate_UpdateSkillGroup_602464, base: "/",
    url: url_UpdateSkillGroup_602465, schemes: {Scheme.Https, Scheme.Http})
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
