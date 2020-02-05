
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS License Manager
## version: 2018-08-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname> AWS License Manager </fullname> <p>AWS License Manager makes it easier to manage licenses from software vendors across multiple AWS accounts and on-premises servers.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/license-manager/
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

  OpenApiRestCall_612642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612642): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "license-manager.ap-northeast-1.amazonaws.com", "ap-southeast-1": "license-manager.ap-southeast-1.amazonaws.com", "us-west-2": "license-manager.us-west-2.amazonaws.com", "eu-west-2": "license-manager.eu-west-2.amazonaws.com", "ap-northeast-3": "license-manager.ap-northeast-3.amazonaws.com", "eu-central-1": "license-manager.eu-central-1.amazonaws.com", "us-east-2": "license-manager.us-east-2.amazonaws.com", "us-east-1": "license-manager.us-east-1.amazonaws.com", "cn-northwest-1": "license-manager.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "license-manager.ap-south-1.amazonaws.com", "eu-north-1": "license-manager.eu-north-1.amazonaws.com", "ap-northeast-2": "license-manager.ap-northeast-2.amazonaws.com", "us-west-1": "license-manager.us-west-1.amazonaws.com", "us-gov-east-1": "license-manager.us-gov-east-1.amazonaws.com", "eu-west-3": "license-manager.eu-west-3.amazonaws.com", "cn-north-1": "license-manager.cn-north-1.amazonaws.com.cn", "sa-east-1": "license-manager.sa-east-1.amazonaws.com", "eu-west-1": "license-manager.eu-west-1.amazonaws.com", "us-gov-west-1": "license-manager.us-gov-west-1.amazonaws.com", "ap-southeast-2": "license-manager.ap-southeast-2.amazonaws.com", "ca-central-1": "license-manager.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "license-manager.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "license-manager.ap-southeast-1.amazonaws.com",
      "us-west-2": "license-manager.us-west-2.amazonaws.com",
      "eu-west-2": "license-manager.eu-west-2.amazonaws.com",
      "ap-northeast-3": "license-manager.ap-northeast-3.amazonaws.com",
      "eu-central-1": "license-manager.eu-central-1.amazonaws.com",
      "us-east-2": "license-manager.us-east-2.amazonaws.com",
      "us-east-1": "license-manager.us-east-1.amazonaws.com",
      "cn-northwest-1": "license-manager.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "license-manager.ap-south-1.amazonaws.com",
      "eu-north-1": "license-manager.eu-north-1.amazonaws.com",
      "ap-northeast-2": "license-manager.ap-northeast-2.amazonaws.com",
      "us-west-1": "license-manager.us-west-1.amazonaws.com",
      "us-gov-east-1": "license-manager.us-gov-east-1.amazonaws.com",
      "eu-west-3": "license-manager.eu-west-3.amazonaws.com",
      "cn-north-1": "license-manager.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "license-manager.sa-east-1.amazonaws.com",
      "eu-west-1": "license-manager.eu-west-1.amazonaws.com",
      "us-gov-west-1": "license-manager.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "license-manager.ap-southeast-2.amazonaws.com",
      "ca-central-1": "license-manager.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "license-manager"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateLicenseConfiguration_612980 = ref object of OpenApiRestCall_612642
proc url_CreateLicenseConfiguration_612982(protocol: Scheme; host: string;
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

proc validate_CreateLicenseConfiguration_612981(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
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
  var valid_613107 = header.getOrDefault("X-Amz-Target")
  valid_613107 = validateParameter(valid_613107, JString, required = true, default = newJString(
      "AWSLicenseManager.CreateLicenseConfiguration"))
  if valid_613107 != nil:
    section.add "X-Amz-Target", valid_613107
  var valid_613108 = header.getOrDefault("X-Amz-Signature")
  valid_613108 = validateParameter(valid_613108, JString, required = false,
                                 default = nil)
  if valid_613108 != nil:
    section.add "X-Amz-Signature", valid_613108
  var valid_613109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613109 = validateParameter(valid_613109, JString, required = false,
                                 default = nil)
  if valid_613109 != nil:
    section.add "X-Amz-Content-Sha256", valid_613109
  var valid_613110 = header.getOrDefault("X-Amz-Date")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-Date", valid_613110
  var valid_613111 = header.getOrDefault("X-Amz-Credential")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Credential", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-Security-Token")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Security-Token", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Algorithm")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Algorithm", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-SignedHeaders", valid_613114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613138: Call_CreateLicenseConfiguration_612980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
  ## 
  let valid = call_613138.validator(path, query, header, formData, body)
  let scheme = call_613138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613138.url(scheme.get, call_613138.host, call_613138.base,
                         call_613138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613138, url, valid)

proc call*(call_613209: Call_CreateLicenseConfiguration_612980; body: JsonNode): Recallable =
  ## createLicenseConfiguration
  ## <p>Creates a license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
  ##   body: JObject (required)
  var body_613210 = newJObject()
  if body != nil:
    body_613210 = body
  result = call_613209.call(nil, nil, nil, nil, body_613210)

var createLicenseConfiguration* = Call_CreateLicenseConfiguration_612980(
    name: "createLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.CreateLicenseConfiguration",
    validator: validate_CreateLicenseConfiguration_612981, base: "/",
    url: url_CreateLicenseConfiguration_612982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLicenseConfiguration_613249 = ref object of OpenApiRestCall_612642
proc url_DeleteLicenseConfiguration_613251(protocol: Scheme; host: string;
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

proc validate_DeleteLicenseConfiguration_613250(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified license configuration.</p> <p>You cannot delete a license configuration that is in use.</p>
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
  var valid_613252 = header.getOrDefault("X-Amz-Target")
  valid_613252 = validateParameter(valid_613252, JString, required = true, default = newJString(
      "AWSLicenseManager.DeleteLicenseConfiguration"))
  if valid_613252 != nil:
    section.add "X-Amz-Target", valid_613252
  var valid_613253 = header.getOrDefault("X-Amz-Signature")
  valid_613253 = validateParameter(valid_613253, JString, required = false,
                                 default = nil)
  if valid_613253 != nil:
    section.add "X-Amz-Signature", valid_613253
  var valid_613254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613254 = validateParameter(valid_613254, JString, required = false,
                                 default = nil)
  if valid_613254 != nil:
    section.add "X-Amz-Content-Sha256", valid_613254
  var valid_613255 = header.getOrDefault("X-Amz-Date")
  valid_613255 = validateParameter(valid_613255, JString, required = false,
                                 default = nil)
  if valid_613255 != nil:
    section.add "X-Amz-Date", valid_613255
  var valid_613256 = header.getOrDefault("X-Amz-Credential")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Credential", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-Security-Token")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Security-Token", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Algorithm")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Algorithm", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-SignedHeaders", valid_613259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613261: Call_DeleteLicenseConfiguration_613249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified license configuration.</p> <p>You cannot delete a license configuration that is in use.</p>
  ## 
  let valid = call_613261.validator(path, query, header, formData, body)
  let scheme = call_613261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613261.url(scheme.get, call_613261.host, call_613261.base,
                         call_613261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613261, url, valid)

proc call*(call_613262: Call_DeleteLicenseConfiguration_613249; body: JsonNode): Recallable =
  ## deleteLicenseConfiguration
  ## <p>Deletes the specified license configuration.</p> <p>You cannot delete a license configuration that is in use.</p>
  ##   body: JObject (required)
  var body_613263 = newJObject()
  if body != nil:
    body_613263 = body
  result = call_613262.call(nil, nil, nil, nil, body_613263)

var deleteLicenseConfiguration* = Call_DeleteLicenseConfiguration_613249(
    name: "deleteLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.DeleteLicenseConfiguration",
    validator: validate_DeleteLicenseConfiguration_613250, base: "/",
    url: url_DeleteLicenseConfiguration_613251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLicenseConfiguration_613264 = ref object of OpenApiRestCall_612642
proc url_GetLicenseConfiguration_613266(protocol: Scheme; host: string; base: string;
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

proc validate_GetLicenseConfiguration_613265(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets detailed information about the specified license configuration.
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
  var valid_613267 = header.getOrDefault("X-Amz-Target")
  valid_613267 = validateParameter(valid_613267, JString, required = true, default = newJString(
      "AWSLicenseManager.GetLicenseConfiguration"))
  if valid_613267 != nil:
    section.add "X-Amz-Target", valid_613267
  var valid_613268 = header.getOrDefault("X-Amz-Signature")
  valid_613268 = validateParameter(valid_613268, JString, required = false,
                                 default = nil)
  if valid_613268 != nil:
    section.add "X-Amz-Signature", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Content-Sha256", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Date")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Date", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Credential")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Credential", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Security-Token")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Security-Token", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Algorithm")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Algorithm", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-SignedHeaders", valid_613274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613276: Call_GetLicenseConfiguration_613264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets detailed information about the specified license configuration.
  ## 
  let valid = call_613276.validator(path, query, header, formData, body)
  let scheme = call_613276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613276.url(scheme.get, call_613276.host, call_613276.base,
                         call_613276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613276, url, valid)

proc call*(call_613277: Call_GetLicenseConfiguration_613264; body: JsonNode): Recallable =
  ## getLicenseConfiguration
  ## Gets detailed information about the specified license configuration.
  ##   body: JObject (required)
  var body_613278 = newJObject()
  if body != nil:
    body_613278 = body
  result = call_613277.call(nil, nil, nil, nil, body_613278)

var getLicenseConfiguration* = Call_GetLicenseConfiguration_613264(
    name: "getLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.GetLicenseConfiguration",
    validator: validate_GetLicenseConfiguration_613265, base: "/",
    url: url_GetLicenseConfiguration_613266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSettings_613279 = ref object of OpenApiRestCall_612642
proc url_GetServiceSettings_613281(protocol: Scheme; host: string; base: string;
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

proc validate_GetServiceSettings_613280(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets the License Manager settings for the current Region.
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
  var valid_613282 = header.getOrDefault("X-Amz-Target")
  valid_613282 = validateParameter(valid_613282, JString, required = true, default = newJString(
      "AWSLicenseManager.GetServiceSettings"))
  if valid_613282 != nil:
    section.add "X-Amz-Target", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-Signature")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-Signature", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Content-Sha256", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Date")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Date", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Credential")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Credential", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Security-Token")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Security-Token", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Algorithm")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Algorithm", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-SignedHeaders", valid_613289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613291: Call_GetServiceSettings_613279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the License Manager settings for the current Region.
  ## 
  let valid = call_613291.validator(path, query, header, formData, body)
  let scheme = call_613291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613291.url(scheme.get, call_613291.host, call_613291.base,
                         call_613291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613291, url, valid)

proc call*(call_613292: Call_GetServiceSettings_613279; body: JsonNode): Recallable =
  ## getServiceSettings
  ## Gets the License Manager settings for the current Region.
  ##   body: JObject (required)
  var body_613293 = newJObject()
  if body != nil:
    body_613293 = body
  result = call_613292.call(nil, nil, nil, nil, body_613293)

var getServiceSettings* = Call_GetServiceSettings_613279(
    name: "getServiceSettings", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.GetServiceSettings",
    validator: validate_GetServiceSettings_613280, base: "/",
    url: url_GetServiceSettings_613281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationsForLicenseConfiguration_613294 = ref object of OpenApiRestCall_612642
proc url_ListAssociationsForLicenseConfiguration_613296(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssociationsForLicenseConfiguration_613295(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the resource associations for the specified license configuration.</p> <p>Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance might not consume a license (depending on the license rules).</p>
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
  var valid_613297 = header.getOrDefault("X-Amz-Target")
  valid_613297 = validateParameter(valid_613297, JString, required = true, default = newJString(
      "AWSLicenseManager.ListAssociationsForLicenseConfiguration"))
  if valid_613297 != nil:
    section.add "X-Amz-Target", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Signature")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Signature", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Content-Sha256", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Date")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Date", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Credential")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Credential", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Security-Token")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Security-Token", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Algorithm")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Algorithm", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-SignedHeaders", valid_613304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613306: Call_ListAssociationsForLicenseConfiguration_613294;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the resource associations for the specified license configuration.</p> <p>Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance might not consume a license (depending on the license rules).</p>
  ## 
  let valid = call_613306.validator(path, query, header, formData, body)
  let scheme = call_613306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613306.url(scheme.get, call_613306.host, call_613306.base,
                         call_613306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613306, url, valid)

proc call*(call_613307: Call_ListAssociationsForLicenseConfiguration_613294;
          body: JsonNode): Recallable =
  ## listAssociationsForLicenseConfiguration
  ## <p>Lists the resource associations for the specified license configuration.</p> <p>Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance might not consume a license (depending on the license rules).</p>
  ##   body: JObject (required)
  var body_613308 = newJObject()
  if body != nil:
    body_613308 = body
  result = call_613307.call(nil, nil, nil, nil, body_613308)

var listAssociationsForLicenseConfiguration* = Call_ListAssociationsForLicenseConfiguration_613294(
    name: "listAssociationsForLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.ListAssociationsForLicenseConfiguration",
    validator: validate_ListAssociationsForLicenseConfiguration_613295, base: "/",
    url: url_ListAssociationsForLicenseConfiguration_613296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFailuresForLicenseConfigurationOperations_613309 = ref object of OpenApiRestCall_612642
proc url_ListFailuresForLicenseConfigurationOperations_613311(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFailuresForLicenseConfigurationOperations_613310(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Lists the license configuration operations that failed.
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
  var valid_613312 = header.getOrDefault("X-Amz-Target")
  valid_613312 = validateParameter(valid_613312, JString, required = true, default = newJString(
      "AWSLicenseManager.ListFailuresForLicenseConfigurationOperations"))
  if valid_613312 != nil:
    section.add "X-Amz-Target", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Signature")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Signature", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Content-Sha256", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Date")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Date", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Credential")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Credential", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Security-Token")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Security-Token", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Algorithm")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Algorithm", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-SignedHeaders", valid_613319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613321: Call_ListFailuresForLicenseConfigurationOperations_613309;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the license configuration operations that failed.
  ## 
  let valid = call_613321.validator(path, query, header, formData, body)
  let scheme = call_613321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613321.url(scheme.get, call_613321.host, call_613321.base,
                         call_613321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613321, url, valid)

proc call*(call_613322: Call_ListFailuresForLicenseConfigurationOperations_613309;
          body: JsonNode): Recallable =
  ## listFailuresForLicenseConfigurationOperations
  ## Lists the license configuration operations that failed.
  ##   body: JObject (required)
  var body_613323 = newJObject()
  if body != nil:
    body_613323 = body
  result = call_613322.call(nil, nil, nil, nil, body_613323)

var listFailuresForLicenseConfigurationOperations* = Call_ListFailuresForLicenseConfigurationOperations_613309(
    name: "listFailuresForLicenseConfigurationOperations",
    meth: HttpMethod.HttpPost, host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.ListFailuresForLicenseConfigurationOperations",
    validator: validate_ListFailuresForLicenseConfigurationOperations_613310,
    base: "/", url: url_ListFailuresForLicenseConfigurationOperations_613311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLicenseConfigurations_613324 = ref object of OpenApiRestCall_612642
proc url_ListLicenseConfigurations_613326(protocol: Scheme; host: string;
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

proc validate_ListLicenseConfigurations_613325(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the license configurations for your account.
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
  var valid_613327 = header.getOrDefault("X-Amz-Target")
  valid_613327 = validateParameter(valid_613327, JString, required = true, default = newJString(
      "AWSLicenseManager.ListLicenseConfigurations"))
  if valid_613327 != nil:
    section.add "X-Amz-Target", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Signature")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Signature", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Content-Sha256", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Date")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Date", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Credential")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Credential", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Security-Token")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Security-Token", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Algorithm")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Algorithm", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-SignedHeaders", valid_613334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613336: Call_ListLicenseConfigurations_613324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the license configurations for your account.
  ## 
  let valid = call_613336.validator(path, query, header, formData, body)
  let scheme = call_613336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613336.url(scheme.get, call_613336.host, call_613336.base,
                         call_613336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613336, url, valid)

proc call*(call_613337: Call_ListLicenseConfigurations_613324; body: JsonNode): Recallable =
  ## listLicenseConfigurations
  ## Lists the license configurations for your account.
  ##   body: JObject (required)
  var body_613338 = newJObject()
  if body != nil:
    body_613338 = body
  result = call_613337.call(nil, nil, nil, nil, body_613338)

var listLicenseConfigurations* = Call_ListLicenseConfigurations_613324(
    name: "listLicenseConfigurations", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListLicenseConfigurations",
    validator: validate_ListLicenseConfigurations_613325, base: "/",
    url: url_ListLicenseConfigurations_613326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLicenseSpecificationsForResource_613339 = ref object of OpenApiRestCall_612642
proc url_ListLicenseSpecificationsForResource_613341(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLicenseSpecificationsForResource_613340(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the license configurations for the specified resource.
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
  var valid_613342 = header.getOrDefault("X-Amz-Target")
  valid_613342 = validateParameter(valid_613342, JString, required = true, default = newJString(
      "AWSLicenseManager.ListLicenseSpecificationsForResource"))
  if valid_613342 != nil:
    section.add "X-Amz-Target", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Signature")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Signature", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Content-Sha256", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Date")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Date", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Credential")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Credential", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Security-Token")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Security-Token", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Algorithm")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Algorithm", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-SignedHeaders", valid_613349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613351: Call_ListLicenseSpecificationsForResource_613339;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the license configurations for the specified resource.
  ## 
  let valid = call_613351.validator(path, query, header, formData, body)
  let scheme = call_613351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613351.url(scheme.get, call_613351.host, call_613351.base,
                         call_613351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613351, url, valid)

proc call*(call_613352: Call_ListLicenseSpecificationsForResource_613339;
          body: JsonNode): Recallable =
  ## listLicenseSpecificationsForResource
  ## Describes the license configurations for the specified resource.
  ##   body: JObject (required)
  var body_613353 = newJObject()
  if body != nil:
    body_613353 = body
  result = call_613352.call(nil, nil, nil, nil, body_613353)

var listLicenseSpecificationsForResource* = Call_ListLicenseSpecificationsForResource_613339(
    name: "listLicenseSpecificationsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.ListLicenseSpecificationsForResource",
    validator: validate_ListLicenseSpecificationsForResource_613340, base: "/",
    url: url_ListLicenseSpecificationsForResource_613341,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceInventory_613354 = ref object of OpenApiRestCall_612642
proc url_ListResourceInventory_613356(protocol: Scheme; host: string; base: string;
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

proc validate_ListResourceInventory_613355(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists resources managed using Systems Manager inventory.
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
  var valid_613357 = header.getOrDefault("X-Amz-Target")
  valid_613357 = validateParameter(valid_613357, JString, required = true, default = newJString(
      "AWSLicenseManager.ListResourceInventory"))
  if valid_613357 != nil:
    section.add "X-Amz-Target", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Signature")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Signature", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Content-Sha256", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Date")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Date", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Credential")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Credential", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Security-Token")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Security-Token", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Algorithm")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Algorithm", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-SignedHeaders", valid_613364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613366: Call_ListResourceInventory_613354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists resources managed using Systems Manager inventory.
  ## 
  let valid = call_613366.validator(path, query, header, formData, body)
  let scheme = call_613366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613366.url(scheme.get, call_613366.host, call_613366.base,
                         call_613366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613366, url, valid)

proc call*(call_613367: Call_ListResourceInventory_613354; body: JsonNode): Recallable =
  ## listResourceInventory
  ## Lists resources managed using Systems Manager inventory.
  ##   body: JObject (required)
  var body_613368 = newJObject()
  if body != nil:
    body_613368 = body
  result = call_613367.call(nil, nil, nil, nil, body_613368)

var listResourceInventory* = Call_ListResourceInventory_613354(
    name: "listResourceInventory", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListResourceInventory",
    validator: validate_ListResourceInventory_613355, base: "/",
    url: url_ListResourceInventory_613356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613369 = ref object of OpenApiRestCall_612642
proc url_ListTagsForResource_613371(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_613370(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the tags for the specified license configuration.
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
  var valid_613372 = header.getOrDefault("X-Amz-Target")
  valid_613372 = validateParameter(valid_613372, JString, required = true, default = newJString(
      "AWSLicenseManager.ListTagsForResource"))
  if valid_613372 != nil:
    section.add "X-Amz-Target", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Signature")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Signature", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Content-Sha256", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Date")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Date", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Credential")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Credential", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Security-Token")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Security-Token", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Algorithm")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Algorithm", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-SignedHeaders", valid_613379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613381: Call_ListTagsForResource_613369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified license configuration.
  ## 
  let valid = call_613381.validator(path, query, header, formData, body)
  let scheme = call_613381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613381.url(scheme.get, call_613381.host, call_613381.base,
                         call_613381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613381, url, valid)

proc call*(call_613382: Call_ListTagsForResource_613369; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified license configuration.
  ##   body: JObject (required)
  var body_613383 = newJObject()
  if body != nil:
    body_613383 = body
  result = call_613382.call(nil, nil, nil, nil, body_613383)

var listTagsForResource* = Call_ListTagsForResource_613369(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListTagsForResource",
    validator: validate_ListTagsForResource_613370, base: "/",
    url: url_ListTagsForResource_613371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsageForLicenseConfiguration_613384 = ref object of OpenApiRestCall_612642
proc url_ListUsageForLicenseConfiguration_613386(protocol: Scheme; host: string;
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

proc validate_ListUsageForLicenseConfiguration_613385(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all license usage records for a license configuration, displaying license consumption details by resource at a selected point in time. Use this action to audit the current license consumption for any license inventory and configuration.
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
  var valid_613387 = header.getOrDefault("X-Amz-Target")
  valid_613387 = validateParameter(valid_613387, JString, required = true, default = newJString(
      "AWSLicenseManager.ListUsageForLicenseConfiguration"))
  if valid_613387 != nil:
    section.add "X-Amz-Target", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Signature")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Signature", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Content-Sha256", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Date")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Date", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Credential")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Credential", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Security-Token")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Security-Token", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Algorithm")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Algorithm", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-SignedHeaders", valid_613394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613396: Call_ListUsageForLicenseConfiguration_613384;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all license usage records for a license configuration, displaying license consumption details by resource at a selected point in time. Use this action to audit the current license consumption for any license inventory and configuration.
  ## 
  let valid = call_613396.validator(path, query, header, formData, body)
  let scheme = call_613396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613396.url(scheme.get, call_613396.host, call_613396.base,
                         call_613396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613396, url, valid)

proc call*(call_613397: Call_ListUsageForLicenseConfiguration_613384;
          body: JsonNode): Recallable =
  ## listUsageForLicenseConfiguration
  ## Lists all license usage records for a license configuration, displaying license consumption details by resource at a selected point in time. Use this action to audit the current license consumption for any license inventory and configuration.
  ##   body: JObject (required)
  var body_613398 = newJObject()
  if body != nil:
    body_613398 = body
  result = call_613397.call(nil, nil, nil, nil, body_613398)

var listUsageForLicenseConfiguration* = Call_ListUsageForLicenseConfiguration_613384(
    name: "listUsageForLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListUsageForLicenseConfiguration",
    validator: validate_ListUsageForLicenseConfiguration_613385, base: "/",
    url: url_ListUsageForLicenseConfiguration_613386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613399 = ref object of OpenApiRestCall_612642
proc url_TagResource_613401(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_613400(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds the specified tags to the specified license configuration.
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
  var valid_613402 = header.getOrDefault("X-Amz-Target")
  valid_613402 = validateParameter(valid_613402, JString, required = true, default = newJString(
      "AWSLicenseManager.TagResource"))
  if valid_613402 != nil:
    section.add "X-Amz-Target", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Signature")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Signature", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Content-Sha256", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Date")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Date", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Credential")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Credential", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Security-Token")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Security-Token", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Algorithm")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Algorithm", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-SignedHeaders", valid_613409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613411: Call_TagResource_613399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified tags to the specified license configuration.
  ## 
  let valid = call_613411.validator(path, query, header, formData, body)
  let scheme = call_613411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613411.url(scheme.get, call_613411.host, call_613411.base,
                         call_613411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613411, url, valid)

proc call*(call_613412: Call_TagResource_613399; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tags to the specified license configuration.
  ##   body: JObject (required)
  var body_613413 = newJObject()
  if body != nil:
    body_613413 = body
  result = call_613412.call(nil, nil, nil, nil, body_613413)

var tagResource* = Call_TagResource_613399(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.TagResource",
                                        validator: validate_TagResource_613400,
                                        base: "/", url: url_TagResource_613401,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613414 = ref object of OpenApiRestCall_612642
proc url_UntagResource_613416(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_613415(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified tags from the specified license configuration.
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
  var valid_613417 = header.getOrDefault("X-Amz-Target")
  valid_613417 = validateParameter(valid_613417, JString, required = true, default = newJString(
      "AWSLicenseManager.UntagResource"))
  if valid_613417 != nil:
    section.add "X-Amz-Target", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Signature")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Signature", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Content-Sha256", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Date")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Date", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Credential")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Credential", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Security-Token")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Security-Token", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Algorithm")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Algorithm", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-SignedHeaders", valid_613424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613426: Call_UntagResource_613414; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from the specified license configuration.
  ## 
  let valid = call_613426.validator(path, query, header, formData, body)
  let scheme = call_613426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613426.url(scheme.get, call_613426.host, call_613426.base,
                         call_613426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613426, url, valid)

proc call*(call_613427: Call_UntagResource_613414; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified license configuration.
  ##   body: JObject (required)
  var body_613428 = newJObject()
  if body != nil:
    body_613428 = body
  result = call_613427.call(nil, nil, nil, nil, body_613428)

var untagResource* = Call_UntagResource_613414(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UntagResource",
    validator: validate_UntagResource_613415, base: "/", url: url_UntagResource_613416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLicenseConfiguration_613429 = ref object of OpenApiRestCall_612642
proc url_UpdateLicenseConfiguration_613431(protocol: Scheme; host: string;
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

proc validate_UpdateLicenseConfiguration_613430(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the attributes of an existing license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
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
  var valid_613432 = header.getOrDefault("X-Amz-Target")
  valid_613432 = validateParameter(valid_613432, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateLicenseConfiguration"))
  if valid_613432 != nil:
    section.add "X-Amz-Target", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Signature")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Signature", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Content-Sha256", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Date")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Date", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Credential")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Credential", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Security-Token")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Security-Token", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Algorithm")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Algorithm", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-SignedHeaders", valid_613439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613441: Call_UpdateLicenseConfiguration_613429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the attributes of an existing license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
  ## 
  let valid = call_613441.validator(path, query, header, formData, body)
  let scheme = call_613441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613441.url(scheme.get, call_613441.host, call_613441.base,
                         call_613441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613441, url, valid)

proc call*(call_613442: Call_UpdateLicenseConfiguration_613429; body: JsonNode): Recallable =
  ## updateLicenseConfiguration
  ## <p>Modifies the attributes of an existing license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
  ##   body: JObject (required)
  var body_613443 = newJObject()
  if body != nil:
    body_613443 = body
  result = call_613442.call(nil, nil, nil, nil, body_613443)

var updateLicenseConfiguration* = Call_UpdateLicenseConfiguration_613429(
    name: "updateLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UpdateLicenseConfiguration",
    validator: validate_UpdateLicenseConfiguration_613430, base: "/",
    url: url_UpdateLicenseConfiguration_613431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLicenseSpecificationsForResource_613444 = ref object of OpenApiRestCall_612642
proc url_UpdateLicenseSpecificationsForResource_613446(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateLicenseSpecificationsForResource_613445(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds or removes the specified license configurations for the specified AWS resource.</p> <p>You can update the license specifications of AMIs, instances, and hosts. You cannot update the license specifications for launch templates and AWS CloudFormation templates, as they send license configurations to the operation that creates the resource.</p>
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
  var valid_613447 = header.getOrDefault("X-Amz-Target")
  valid_613447 = validateParameter(valid_613447, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateLicenseSpecificationsForResource"))
  if valid_613447 != nil:
    section.add "X-Amz-Target", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Signature")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Signature", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Content-Sha256", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Date")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Date", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Credential")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Credential", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Security-Token")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Security-Token", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Algorithm")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Algorithm", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-SignedHeaders", valid_613454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613456: Call_UpdateLicenseSpecificationsForResource_613444;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds or removes the specified license configurations for the specified AWS resource.</p> <p>You can update the license specifications of AMIs, instances, and hosts. You cannot update the license specifications for launch templates and AWS CloudFormation templates, as they send license configurations to the operation that creates the resource.</p>
  ## 
  let valid = call_613456.validator(path, query, header, formData, body)
  let scheme = call_613456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613456.url(scheme.get, call_613456.host, call_613456.base,
                         call_613456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613456, url, valid)

proc call*(call_613457: Call_UpdateLicenseSpecificationsForResource_613444;
          body: JsonNode): Recallable =
  ## updateLicenseSpecificationsForResource
  ## <p>Adds or removes the specified license configurations for the specified AWS resource.</p> <p>You can update the license specifications of AMIs, instances, and hosts. You cannot update the license specifications for launch templates and AWS CloudFormation templates, as they send license configurations to the operation that creates the resource.</p>
  ##   body: JObject (required)
  var body_613458 = newJObject()
  if body != nil:
    body_613458 = body
  result = call_613457.call(nil, nil, nil, nil, body_613458)

var updateLicenseSpecificationsForResource* = Call_UpdateLicenseSpecificationsForResource_613444(
    name: "updateLicenseSpecificationsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.UpdateLicenseSpecificationsForResource",
    validator: validate_UpdateLicenseSpecificationsForResource_613445, base: "/",
    url: url_UpdateLicenseSpecificationsForResource_613446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSettings_613459 = ref object of OpenApiRestCall_612642
proc url_UpdateServiceSettings_613461(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateServiceSettings_613460(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates License Manager settings for the current Region.
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
  var valid_613462 = header.getOrDefault("X-Amz-Target")
  valid_613462 = validateParameter(valid_613462, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateServiceSettings"))
  if valid_613462 != nil:
    section.add "X-Amz-Target", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Signature")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Signature", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Content-Sha256", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Date")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Date", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Credential")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Credential", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Security-Token")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Security-Token", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Algorithm")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Algorithm", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-SignedHeaders", valid_613469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613471: Call_UpdateServiceSettings_613459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates License Manager settings for the current Region.
  ## 
  let valid = call_613471.validator(path, query, header, formData, body)
  let scheme = call_613471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613471.url(scheme.get, call_613471.host, call_613471.base,
                         call_613471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613471, url, valid)

proc call*(call_613472: Call_UpdateServiceSettings_613459; body: JsonNode): Recallable =
  ## updateServiceSettings
  ## Updates License Manager settings for the current Region.
  ##   body: JObject (required)
  var body_613473 = newJObject()
  if body != nil:
    body_613473 = body
  result = call_613472.call(nil, nil, nil, nil, body_613473)

var updateServiceSettings* = Call_UpdateServiceSettings_613459(
    name: "updateServiceSettings", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UpdateServiceSettings",
    validator: validate_UpdateServiceSettings_613460, base: "/",
    url: url_UpdateServiceSettings_613461, schemes: {Scheme.Https, Scheme.Http})
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
