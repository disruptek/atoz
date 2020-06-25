
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625418 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625418](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625418): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateLicenseConfiguration_21625762 = ref object of OpenApiRestCall_21625418
proc url_CreateLicenseConfiguration_21625764(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLicenseConfiguration_21625763(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625865 = header.getOrDefault("X-Amz-Date")
  valid_21625865 = validateParameter(valid_21625865, JString, required = false,
                                   default = nil)
  if valid_21625865 != nil:
    section.add "X-Amz-Date", valid_21625865
  var valid_21625866 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625866 = validateParameter(valid_21625866, JString, required = false,
                                   default = nil)
  if valid_21625866 != nil:
    section.add "X-Amz-Security-Token", valid_21625866
  var valid_21625881 = header.getOrDefault("X-Amz-Target")
  valid_21625881 = validateParameter(valid_21625881, JString, required = true, default = newJString(
      "AWSLicenseManager.CreateLicenseConfiguration"))
  if valid_21625881 != nil:
    section.add "X-Amz-Target", valid_21625881
  var valid_21625882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Algorithm", valid_21625883
  var valid_21625884 = header.getOrDefault("X-Amz-Signature")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Signature", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625885
  var valid_21625886 = header.getOrDefault("X-Amz-Credential")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Credential", valid_21625886
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

proc call*(call_21625912: Call_CreateLicenseConfiguration_21625762;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
  ## 
  let valid = call_21625912.validator(path, query, header, formData, body, _)
  let scheme = call_21625912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625912.makeUrl(scheme.get, call_21625912.host, call_21625912.base,
                               call_21625912.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625912, uri, valid, _)

proc call*(call_21625975: Call_CreateLicenseConfiguration_21625762; body: JsonNode): Recallable =
  ## createLicenseConfiguration
  ## <p>Creates a license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
  ##   body: JObject (required)
  var body_21625976 = newJObject()
  if body != nil:
    body_21625976 = body
  result = call_21625975.call(nil, nil, nil, nil, body_21625976)

var createLicenseConfiguration* = Call_CreateLicenseConfiguration_21625762(
    name: "createLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.CreateLicenseConfiguration",
    validator: validate_CreateLicenseConfiguration_21625763, base: "/",
    makeUrl: url_CreateLicenseConfiguration_21625764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLicenseConfiguration_21626012 = ref object of OpenApiRestCall_21625418
proc url_DeleteLicenseConfiguration_21626014(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLicenseConfiguration_21626013(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the specified license configuration.</p> <p>You cannot delete a license configuration that is in use.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626015 = header.getOrDefault("X-Amz-Date")
  valid_21626015 = validateParameter(valid_21626015, JString, required = false,
                                   default = nil)
  if valid_21626015 != nil:
    section.add "X-Amz-Date", valid_21626015
  var valid_21626016 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626016 = validateParameter(valid_21626016, JString, required = false,
                                   default = nil)
  if valid_21626016 != nil:
    section.add "X-Amz-Security-Token", valid_21626016
  var valid_21626017 = header.getOrDefault("X-Amz-Target")
  valid_21626017 = validateParameter(valid_21626017, JString, required = true, default = newJString(
      "AWSLicenseManager.DeleteLicenseConfiguration"))
  if valid_21626017 != nil:
    section.add "X-Amz-Target", valid_21626017
  var valid_21626018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626018 = validateParameter(valid_21626018, JString, required = false,
                                   default = nil)
  if valid_21626018 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626018
  var valid_21626019 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626019 = validateParameter(valid_21626019, JString, required = false,
                                   default = nil)
  if valid_21626019 != nil:
    section.add "X-Amz-Algorithm", valid_21626019
  var valid_21626020 = header.getOrDefault("X-Amz-Signature")
  valid_21626020 = validateParameter(valid_21626020, JString, required = false,
                                   default = nil)
  if valid_21626020 != nil:
    section.add "X-Amz-Signature", valid_21626020
  var valid_21626021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626021 = validateParameter(valid_21626021, JString, required = false,
                                   default = nil)
  if valid_21626021 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626021
  var valid_21626022 = header.getOrDefault("X-Amz-Credential")
  valid_21626022 = validateParameter(valid_21626022, JString, required = false,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "X-Amz-Credential", valid_21626022
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

proc call*(call_21626024: Call_DeleteLicenseConfiguration_21626012;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified license configuration.</p> <p>You cannot delete a license configuration that is in use.</p>
  ## 
  let valid = call_21626024.validator(path, query, header, formData, body, _)
  let scheme = call_21626024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626024.makeUrl(scheme.get, call_21626024.host, call_21626024.base,
                               call_21626024.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626024, uri, valid, _)

proc call*(call_21626025: Call_DeleteLicenseConfiguration_21626012; body: JsonNode): Recallable =
  ## deleteLicenseConfiguration
  ## <p>Deletes the specified license configuration.</p> <p>You cannot delete a license configuration that is in use.</p>
  ##   body: JObject (required)
  var body_21626026 = newJObject()
  if body != nil:
    body_21626026 = body
  result = call_21626025.call(nil, nil, nil, nil, body_21626026)

var deleteLicenseConfiguration* = Call_DeleteLicenseConfiguration_21626012(
    name: "deleteLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.DeleteLicenseConfiguration",
    validator: validate_DeleteLicenseConfiguration_21626013, base: "/",
    makeUrl: url_DeleteLicenseConfiguration_21626014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLicenseConfiguration_21626027 = ref object of OpenApiRestCall_21625418
proc url_GetLicenseConfiguration_21626029(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLicenseConfiguration_21626028(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets detailed information about the specified license configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626030 = header.getOrDefault("X-Amz-Date")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-Date", valid_21626030
  var valid_21626031 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626031 = validateParameter(valid_21626031, JString, required = false,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "X-Amz-Security-Token", valid_21626031
  var valid_21626032 = header.getOrDefault("X-Amz-Target")
  valid_21626032 = validateParameter(valid_21626032, JString, required = true, default = newJString(
      "AWSLicenseManager.GetLicenseConfiguration"))
  if valid_21626032 != nil:
    section.add "X-Amz-Target", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Algorithm", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Signature")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Signature", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Credential")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Credential", valid_21626037
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

proc call*(call_21626039: Call_GetLicenseConfiguration_21626027;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets detailed information about the specified license configuration.
  ## 
  let valid = call_21626039.validator(path, query, header, formData, body, _)
  let scheme = call_21626039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626039.makeUrl(scheme.get, call_21626039.host, call_21626039.base,
                               call_21626039.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626039, uri, valid, _)

proc call*(call_21626040: Call_GetLicenseConfiguration_21626027; body: JsonNode): Recallable =
  ## getLicenseConfiguration
  ## Gets detailed information about the specified license configuration.
  ##   body: JObject (required)
  var body_21626041 = newJObject()
  if body != nil:
    body_21626041 = body
  result = call_21626040.call(nil, nil, nil, nil, body_21626041)

var getLicenseConfiguration* = Call_GetLicenseConfiguration_21626027(
    name: "getLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.GetLicenseConfiguration",
    validator: validate_GetLicenseConfiguration_21626028, base: "/",
    makeUrl: url_GetLicenseConfiguration_21626029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSettings_21626042 = ref object of OpenApiRestCall_21625418
proc url_GetServiceSettings_21626044(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServiceSettings_21626043(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the License Manager settings for the current Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626045 = header.getOrDefault("X-Amz-Date")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Date", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Security-Token", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-Target")
  valid_21626047 = validateParameter(valid_21626047, JString, required = true, default = newJString(
      "AWSLicenseManager.GetServiceSettings"))
  if valid_21626047 != nil:
    section.add "X-Amz-Target", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Algorithm", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Signature")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Signature", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Credential")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Credential", valid_21626052
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

proc call*(call_21626054: Call_GetServiceSettings_21626042; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the License Manager settings for the current Region.
  ## 
  let valid = call_21626054.validator(path, query, header, formData, body, _)
  let scheme = call_21626054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626054.makeUrl(scheme.get, call_21626054.host, call_21626054.base,
                               call_21626054.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626054, uri, valid, _)

proc call*(call_21626055: Call_GetServiceSettings_21626042; body: JsonNode): Recallable =
  ## getServiceSettings
  ## Gets the License Manager settings for the current Region.
  ##   body: JObject (required)
  var body_21626056 = newJObject()
  if body != nil:
    body_21626056 = body
  result = call_21626055.call(nil, nil, nil, nil, body_21626056)

var getServiceSettings* = Call_GetServiceSettings_21626042(
    name: "getServiceSettings", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.GetServiceSettings",
    validator: validate_GetServiceSettings_21626043, base: "/",
    makeUrl: url_GetServiceSettings_21626044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationsForLicenseConfiguration_21626057 = ref object of OpenApiRestCall_21625418
proc url_ListAssociationsForLicenseConfiguration_21626059(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssociationsForLicenseConfiguration_21626058(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Lists the resource associations for the specified license configuration.</p> <p>Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance might not consume a license (depending on the license rules).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626060 = header.getOrDefault("X-Amz-Date")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Date", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Security-Token", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Target")
  valid_21626062 = validateParameter(valid_21626062, JString, required = true, default = newJString(
      "AWSLicenseManager.ListAssociationsForLicenseConfiguration"))
  if valid_21626062 != nil:
    section.add "X-Amz-Target", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Algorithm", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Signature")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Signature", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Credential")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Credential", valid_21626067
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

proc call*(call_21626069: Call_ListAssociationsForLicenseConfiguration_21626057;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the resource associations for the specified license configuration.</p> <p>Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance might not consume a license (depending on the license rules).</p>
  ## 
  let valid = call_21626069.validator(path, query, header, formData, body, _)
  let scheme = call_21626069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626069.makeUrl(scheme.get, call_21626069.host, call_21626069.base,
                               call_21626069.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626069, uri, valid, _)

proc call*(call_21626070: Call_ListAssociationsForLicenseConfiguration_21626057;
          body: JsonNode): Recallable =
  ## listAssociationsForLicenseConfiguration
  ## <p>Lists the resource associations for the specified license configuration.</p> <p>Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance might not consume a license (depending on the license rules).</p>
  ##   body: JObject (required)
  var body_21626071 = newJObject()
  if body != nil:
    body_21626071 = body
  result = call_21626070.call(nil, nil, nil, nil, body_21626071)

var listAssociationsForLicenseConfiguration* = Call_ListAssociationsForLicenseConfiguration_21626057(
    name: "listAssociationsForLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.ListAssociationsForLicenseConfiguration",
    validator: validate_ListAssociationsForLicenseConfiguration_21626058,
    base: "/", makeUrl: url_ListAssociationsForLicenseConfiguration_21626059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFailuresForLicenseConfigurationOperations_21626072 = ref object of OpenApiRestCall_21625418
proc url_ListFailuresForLicenseConfigurationOperations_21626074(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFailuresForLicenseConfigurationOperations_21626073(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Lists the license configuration operations that failed.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626075 = header.getOrDefault("X-Amz-Date")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Date", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Security-Token", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Target")
  valid_21626077 = validateParameter(valid_21626077, JString, required = true, default = newJString(
      "AWSLicenseManager.ListFailuresForLicenseConfigurationOperations"))
  if valid_21626077 != nil:
    section.add "X-Amz-Target", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Algorithm", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Signature")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Signature", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Credential")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Credential", valid_21626082
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

proc call*(call_21626084: Call_ListFailuresForLicenseConfigurationOperations_21626072;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the license configuration operations that failed.
  ## 
  let valid = call_21626084.validator(path, query, header, formData, body, _)
  let scheme = call_21626084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626084.makeUrl(scheme.get, call_21626084.host, call_21626084.base,
                               call_21626084.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626084, uri, valid, _)

proc call*(call_21626085: Call_ListFailuresForLicenseConfigurationOperations_21626072;
          body: JsonNode): Recallable =
  ## listFailuresForLicenseConfigurationOperations
  ## Lists the license configuration operations that failed.
  ##   body: JObject (required)
  var body_21626086 = newJObject()
  if body != nil:
    body_21626086 = body
  result = call_21626085.call(nil, nil, nil, nil, body_21626086)

var listFailuresForLicenseConfigurationOperations* = Call_ListFailuresForLicenseConfigurationOperations_21626072(
    name: "listFailuresForLicenseConfigurationOperations",
    meth: HttpMethod.HttpPost, host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.ListFailuresForLicenseConfigurationOperations",
    validator: validate_ListFailuresForLicenseConfigurationOperations_21626073,
    base: "/", makeUrl: url_ListFailuresForLicenseConfigurationOperations_21626074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLicenseConfigurations_21626087 = ref object of OpenApiRestCall_21625418
proc url_ListLicenseConfigurations_21626089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLicenseConfigurations_21626088(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the license configurations for your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626090 = header.getOrDefault("X-Amz-Date")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Date", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-Security-Token", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-Target")
  valid_21626092 = validateParameter(valid_21626092, JString, required = true, default = newJString(
      "AWSLicenseManager.ListLicenseConfigurations"))
  if valid_21626092 != nil:
    section.add "X-Amz-Target", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Algorithm", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Signature")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Signature", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Credential")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Credential", valid_21626097
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

proc call*(call_21626099: Call_ListLicenseConfigurations_21626087;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the license configurations for your account.
  ## 
  let valid = call_21626099.validator(path, query, header, formData, body, _)
  let scheme = call_21626099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626099.makeUrl(scheme.get, call_21626099.host, call_21626099.base,
                               call_21626099.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626099, uri, valid, _)

proc call*(call_21626100: Call_ListLicenseConfigurations_21626087; body: JsonNode): Recallable =
  ## listLicenseConfigurations
  ## Lists the license configurations for your account.
  ##   body: JObject (required)
  var body_21626101 = newJObject()
  if body != nil:
    body_21626101 = body
  result = call_21626100.call(nil, nil, nil, nil, body_21626101)

var listLicenseConfigurations* = Call_ListLicenseConfigurations_21626087(
    name: "listLicenseConfigurations", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListLicenseConfigurations",
    validator: validate_ListLicenseConfigurations_21626088, base: "/",
    makeUrl: url_ListLicenseConfigurations_21626089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLicenseSpecificationsForResource_21626102 = ref object of OpenApiRestCall_21625418
proc url_ListLicenseSpecificationsForResource_21626104(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLicenseSpecificationsForResource_21626103(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describes the license configurations for the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626105 = header.getOrDefault("X-Amz-Date")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Date", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Security-Token", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-Target")
  valid_21626107 = validateParameter(valid_21626107, JString, required = true, default = newJString(
      "AWSLicenseManager.ListLicenseSpecificationsForResource"))
  if valid_21626107 != nil:
    section.add "X-Amz-Target", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Algorithm", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Signature")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Signature", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Credential")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Credential", valid_21626112
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

proc call*(call_21626114: Call_ListLicenseSpecificationsForResource_21626102;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the license configurations for the specified resource.
  ## 
  let valid = call_21626114.validator(path, query, header, formData, body, _)
  let scheme = call_21626114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626114.makeUrl(scheme.get, call_21626114.host, call_21626114.base,
                               call_21626114.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626114, uri, valid, _)

proc call*(call_21626115: Call_ListLicenseSpecificationsForResource_21626102;
          body: JsonNode): Recallable =
  ## listLicenseSpecificationsForResource
  ## Describes the license configurations for the specified resource.
  ##   body: JObject (required)
  var body_21626116 = newJObject()
  if body != nil:
    body_21626116 = body
  result = call_21626115.call(nil, nil, nil, nil, body_21626116)

var listLicenseSpecificationsForResource* = Call_ListLicenseSpecificationsForResource_21626102(
    name: "listLicenseSpecificationsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.ListLicenseSpecificationsForResource",
    validator: validate_ListLicenseSpecificationsForResource_21626103, base: "/",
    makeUrl: url_ListLicenseSpecificationsForResource_21626104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceInventory_21626117 = ref object of OpenApiRestCall_21625418
proc url_ListResourceInventory_21626119(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceInventory_21626118(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists resources managed using Systems Manager inventory.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626120 = header.getOrDefault("X-Amz-Date")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Date", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Security-Token", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-Target")
  valid_21626122 = validateParameter(valid_21626122, JString, required = true, default = newJString(
      "AWSLicenseManager.ListResourceInventory"))
  if valid_21626122 != nil:
    section.add "X-Amz-Target", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Algorithm", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Signature")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Signature", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Credential")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Credential", valid_21626127
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

proc call*(call_21626129: Call_ListResourceInventory_21626117;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists resources managed using Systems Manager inventory.
  ## 
  let valid = call_21626129.validator(path, query, header, formData, body, _)
  let scheme = call_21626129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626129.makeUrl(scheme.get, call_21626129.host, call_21626129.base,
                               call_21626129.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626129, uri, valid, _)

proc call*(call_21626130: Call_ListResourceInventory_21626117; body: JsonNode): Recallable =
  ## listResourceInventory
  ## Lists resources managed using Systems Manager inventory.
  ##   body: JObject (required)
  var body_21626131 = newJObject()
  if body != nil:
    body_21626131 = body
  result = call_21626130.call(nil, nil, nil, nil, body_21626131)

var listResourceInventory* = Call_ListResourceInventory_21626117(
    name: "listResourceInventory", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListResourceInventory",
    validator: validate_ListResourceInventory_21626118, base: "/",
    makeUrl: url_ListResourceInventory_21626119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626132 = ref object of OpenApiRestCall_21625418
proc url_ListTagsForResource_21626134(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_21626133(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the tags for the specified license configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626135 = header.getOrDefault("X-Amz-Date")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Date", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Security-Token", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Target")
  valid_21626137 = validateParameter(valid_21626137, JString, required = true, default = newJString(
      "AWSLicenseManager.ListTagsForResource"))
  if valid_21626137 != nil:
    section.add "X-Amz-Target", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Algorithm", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Signature")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Signature", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Credential")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Credential", valid_21626142
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

proc call*(call_21626144: Call_ListTagsForResource_21626132; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags for the specified license configuration.
  ## 
  let valid = call_21626144.validator(path, query, header, formData, body, _)
  let scheme = call_21626144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626144.makeUrl(scheme.get, call_21626144.host, call_21626144.base,
                               call_21626144.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626144, uri, valid, _)

proc call*(call_21626145: Call_ListTagsForResource_21626132; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified license configuration.
  ##   body: JObject (required)
  var body_21626146 = newJObject()
  if body != nil:
    body_21626146 = body
  result = call_21626145.call(nil, nil, nil, nil, body_21626146)

var listTagsForResource* = Call_ListTagsForResource_21626132(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListTagsForResource",
    validator: validate_ListTagsForResource_21626133, base: "/",
    makeUrl: url_ListTagsForResource_21626134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsageForLicenseConfiguration_21626147 = ref object of OpenApiRestCall_21625418
proc url_ListUsageForLicenseConfiguration_21626149(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUsageForLicenseConfiguration_21626148(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists all license usage records for a license configuration, displaying license consumption details by resource at a selected point in time. Use this action to audit the current license consumption for any license inventory and configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626150 = header.getOrDefault("X-Amz-Date")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Date", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Security-Token", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Target")
  valid_21626152 = validateParameter(valid_21626152, JString, required = true, default = newJString(
      "AWSLicenseManager.ListUsageForLicenseConfiguration"))
  if valid_21626152 != nil:
    section.add "X-Amz-Target", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Algorithm", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Signature")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Signature", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Credential")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Credential", valid_21626157
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

proc call*(call_21626159: Call_ListUsageForLicenseConfiguration_21626147;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all license usage records for a license configuration, displaying license consumption details by resource at a selected point in time. Use this action to audit the current license consumption for any license inventory and configuration.
  ## 
  let valid = call_21626159.validator(path, query, header, formData, body, _)
  let scheme = call_21626159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626159.makeUrl(scheme.get, call_21626159.host, call_21626159.base,
                               call_21626159.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626159, uri, valid, _)

proc call*(call_21626160: Call_ListUsageForLicenseConfiguration_21626147;
          body: JsonNode): Recallable =
  ## listUsageForLicenseConfiguration
  ## Lists all license usage records for a license configuration, displaying license consumption details by resource at a selected point in time. Use this action to audit the current license consumption for any license inventory and configuration.
  ##   body: JObject (required)
  var body_21626161 = newJObject()
  if body != nil:
    body_21626161 = body
  result = call_21626160.call(nil, nil, nil, nil, body_21626161)

var listUsageForLicenseConfiguration* = Call_ListUsageForLicenseConfiguration_21626147(
    name: "listUsageForLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListUsageForLicenseConfiguration",
    validator: validate_ListUsageForLicenseConfiguration_21626148, base: "/",
    makeUrl: url_ListUsageForLicenseConfiguration_21626149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626162 = ref object of OpenApiRestCall_21625418
proc url_TagResource_21626164(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21626163(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds the specified tags to the specified license configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626165 = header.getOrDefault("X-Amz-Date")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Date", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Security-Token", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Target")
  valid_21626167 = validateParameter(valid_21626167, JString, required = true, default = newJString(
      "AWSLicenseManager.TagResource"))
  if valid_21626167 != nil:
    section.add "X-Amz-Target", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Algorithm", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Signature")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Signature", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Credential")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Credential", valid_21626172
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

proc call*(call_21626174: Call_TagResource_21626162; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds the specified tags to the specified license configuration.
  ## 
  let valid = call_21626174.validator(path, query, header, formData, body, _)
  let scheme = call_21626174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626174.makeUrl(scheme.get, call_21626174.host, call_21626174.base,
                               call_21626174.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626174, uri, valid, _)

proc call*(call_21626175: Call_TagResource_21626162; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tags to the specified license configuration.
  ##   body: JObject (required)
  var body_21626176 = newJObject()
  if body != nil:
    body_21626176 = body
  result = call_21626175.call(nil, nil, nil, nil, body_21626176)

var tagResource* = Call_TagResource_21626162(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.TagResource",
    validator: validate_TagResource_21626163, base: "/", makeUrl: url_TagResource_21626164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626177 = ref object of OpenApiRestCall_21625418
proc url_UntagResource_21626179(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21626178(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Removes the specified tags from the specified license configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626180 = header.getOrDefault("X-Amz-Date")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Date", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Security-Token", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Target")
  valid_21626182 = validateParameter(valid_21626182, JString, required = true, default = newJString(
      "AWSLicenseManager.UntagResource"))
  if valid_21626182 != nil:
    section.add "X-Amz-Target", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Algorithm", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Signature")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Signature", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Credential")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Credential", valid_21626187
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

proc call*(call_21626189: Call_UntagResource_21626177; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified tags from the specified license configuration.
  ## 
  let valid = call_21626189.validator(path, query, header, formData, body, _)
  let scheme = call_21626189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626189.makeUrl(scheme.get, call_21626189.host, call_21626189.base,
                               call_21626189.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626189, uri, valid, _)

proc call*(call_21626190: Call_UntagResource_21626177; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified license configuration.
  ##   body: JObject (required)
  var body_21626191 = newJObject()
  if body != nil:
    body_21626191 = body
  result = call_21626190.call(nil, nil, nil, nil, body_21626191)

var untagResource* = Call_UntagResource_21626177(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UntagResource",
    validator: validate_UntagResource_21626178, base: "/",
    makeUrl: url_UntagResource_21626179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLicenseConfiguration_21626192 = ref object of OpenApiRestCall_21625418
proc url_UpdateLicenseConfiguration_21626194(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateLicenseConfiguration_21626193(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Modifies the attributes of an existing license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626195 = header.getOrDefault("X-Amz-Date")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Date", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Security-Token", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-Target")
  valid_21626197 = validateParameter(valid_21626197, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateLicenseConfiguration"))
  if valid_21626197 != nil:
    section.add "X-Amz-Target", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Algorithm", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Signature")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Signature", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Credential")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Credential", valid_21626202
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

proc call*(call_21626204: Call_UpdateLicenseConfiguration_21626192;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies the attributes of an existing license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
  ## 
  let valid = call_21626204.validator(path, query, header, formData, body, _)
  let scheme = call_21626204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626204.makeUrl(scheme.get, call_21626204.host, call_21626204.base,
                               call_21626204.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626204, uri, valid, _)

proc call*(call_21626205: Call_UpdateLicenseConfiguration_21626192; body: JsonNode): Recallable =
  ## updateLicenseConfiguration
  ## <p>Modifies the attributes of an existing license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
  ##   body: JObject (required)
  var body_21626206 = newJObject()
  if body != nil:
    body_21626206 = body
  result = call_21626205.call(nil, nil, nil, nil, body_21626206)

var updateLicenseConfiguration* = Call_UpdateLicenseConfiguration_21626192(
    name: "updateLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UpdateLicenseConfiguration",
    validator: validate_UpdateLicenseConfiguration_21626193, base: "/",
    makeUrl: url_UpdateLicenseConfiguration_21626194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLicenseSpecificationsForResource_21626207 = ref object of OpenApiRestCall_21625418
proc url_UpdateLicenseSpecificationsForResource_21626209(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateLicenseSpecificationsForResource_21626208(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Adds or removes the specified license configurations for the specified AWS resource.</p> <p>You can update the license specifications of AMIs, instances, and hosts. You cannot update the license specifications for launch templates and AWS CloudFormation templates, as they send license configurations to the operation that creates the resource.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626210 = header.getOrDefault("X-Amz-Date")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Date", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Security-Token", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Target")
  valid_21626212 = validateParameter(valid_21626212, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateLicenseSpecificationsForResource"))
  if valid_21626212 != nil:
    section.add "X-Amz-Target", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Algorithm", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Signature")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Signature", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Credential")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Credential", valid_21626217
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

proc call*(call_21626219: Call_UpdateLicenseSpecificationsForResource_21626207;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds or removes the specified license configurations for the specified AWS resource.</p> <p>You can update the license specifications of AMIs, instances, and hosts. You cannot update the license specifications for launch templates and AWS CloudFormation templates, as they send license configurations to the operation that creates the resource.</p>
  ## 
  let valid = call_21626219.validator(path, query, header, formData, body, _)
  let scheme = call_21626219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626219.makeUrl(scheme.get, call_21626219.host, call_21626219.base,
                               call_21626219.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626219, uri, valid, _)

proc call*(call_21626220: Call_UpdateLicenseSpecificationsForResource_21626207;
          body: JsonNode): Recallable =
  ## updateLicenseSpecificationsForResource
  ## <p>Adds or removes the specified license configurations for the specified AWS resource.</p> <p>You can update the license specifications of AMIs, instances, and hosts. You cannot update the license specifications for launch templates and AWS CloudFormation templates, as they send license configurations to the operation that creates the resource.</p>
  ##   body: JObject (required)
  var body_21626221 = newJObject()
  if body != nil:
    body_21626221 = body
  result = call_21626220.call(nil, nil, nil, nil, body_21626221)

var updateLicenseSpecificationsForResource* = Call_UpdateLicenseSpecificationsForResource_21626207(
    name: "updateLicenseSpecificationsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.UpdateLicenseSpecificationsForResource",
    validator: validate_UpdateLicenseSpecificationsForResource_21626208,
    base: "/", makeUrl: url_UpdateLicenseSpecificationsForResource_21626209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSettings_21626222 = ref object of OpenApiRestCall_21625418
proc url_UpdateServiceSettings_21626224(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateServiceSettings_21626223(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates License Manager settings for the current Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626225 = header.getOrDefault("X-Amz-Date")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "X-Amz-Date", valid_21626225
  var valid_21626226 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Security-Token", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-Target")
  valid_21626227 = validateParameter(valid_21626227, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateServiceSettings"))
  if valid_21626227 != nil:
    section.add "X-Amz-Target", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Algorithm", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Signature")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Signature", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Credential")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Credential", valid_21626232
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

proc call*(call_21626234: Call_UpdateServiceSettings_21626222;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates License Manager settings for the current Region.
  ## 
  let valid = call_21626234.validator(path, query, header, formData, body, _)
  let scheme = call_21626234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626234.makeUrl(scheme.get, call_21626234.host, call_21626234.base,
                               call_21626234.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626234, uri, valid, _)

proc call*(call_21626235: Call_UpdateServiceSettings_21626222; body: JsonNode): Recallable =
  ## updateServiceSettings
  ## Updates License Manager settings for the current Region.
  ##   body: JObject (required)
  var body_21626236 = newJObject()
  if body != nil:
    body_21626236 = body
  result = call_21626235.call(nil, nil, nil, nil, body_21626236)

var updateServiceSettings* = Call_UpdateServiceSettings_21626222(
    name: "updateServiceSettings", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UpdateServiceSettings",
    validator: validate_UpdateServiceSettings_21626223, base: "/",
    makeUrl: url_UpdateServiceSettings_21626224,
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