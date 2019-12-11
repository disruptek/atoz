
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

  OpenApiRestCall_597373 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597373](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597373): Option[Scheme] {.used.} =
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
  Call_CreateLicenseConfiguration_597711 = ref object of OpenApiRestCall_597373
proc url_CreateLicenseConfiguration_597713(protocol: Scheme; host: string;
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

proc validate_CreateLicenseConfiguration_597712(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_597838 = header.getOrDefault("X-Amz-Target")
  valid_597838 = validateParameter(valid_597838, JString, required = true, default = newJString(
      "AWSLicenseManager.CreateLicenseConfiguration"))
  if valid_597838 != nil:
    section.add "X-Amz-Target", valid_597838
  var valid_597839 = header.getOrDefault("X-Amz-Signature")
  valid_597839 = validateParameter(valid_597839, JString, required = false,
                                 default = nil)
  if valid_597839 != nil:
    section.add "X-Amz-Signature", valid_597839
  var valid_597840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597840 = validateParameter(valid_597840, JString, required = false,
                                 default = nil)
  if valid_597840 != nil:
    section.add "X-Amz-Content-Sha256", valid_597840
  var valid_597841 = header.getOrDefault("X-Amz-Date")
  valid_597841 = validateParameter(valid_597841, JString, required = false,
                                 default = nil)
  if valid_597841 != nil:
    section.add "X-Amz-Date", valid_597841
  var valid_597842 = header.getOrDefault("X-Amz-Credential")
  valid_597842 = validateParameter(valid_597842, JString, required = false,
                                 default = nil)
  if valid_597842 != nil:
    section.add "X-Amz-Credential", valid_597842
  var valid_597843 = header.getOrDefault("X-Amz-Security-Token")
  valid_597843 = validateParameter(valid_597843, JString, required = false,
                                 default = nil)
  if valid_597843 != nil:
    section.add "X-Amz-Security-Token", valid_597843
  var valid_597844 = header.getOrDefault("X-Amz-Algorithm")
  valid_597844 = validateParameter(valid_597844, JString, required = false,
                                 default = nil)
  if valid_597844 != nil:
    section.add "X-Amz-Algorithm", valid_597844
  var valid_597845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597845 = validateParameter(valid_597845, JString, required = false,
                                 default = nil)
  if valid_597845 != nil:
    section.add "X-Amz-SignedHeaders", valid_597845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597869: Call_CreateLicenseConfiguration_597711; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
  ## 
  let valid = call_597869.validator(path, query, header, formData, body)
  let scheme = call_597869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597869.url(scheme.get, call_597869.host, call_597869.base,
                         call_597869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597869, url, valid)

proc call*(call_597940: Call_CreateLicenseConfiguration_597711; body: JsonNode): Recallable =
  ## createLicenseConfiguration
  ## <p>Creates a license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
  ##   body: JObject (required)
  var body_597941 = newJObject()
  if body != nil:
    body_597941 = body
  result = call_597940.call(nil, nil, nil, nil, body_597941)

var createLicenseConfiguration* = Call_CreateLicenseConfiguration_597711(
    name: "createLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.CreateLicenseConfiguration",
    validator: validate_CreateLicenseConfiguration_597712, base: "/",
    url: url_CreateLicenseConfiguration_597713,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLicenseConfiguration_597980 = ref object of OpenApiRestCall_597373
proc url_DeleteLicenseConfiguration_597982(protocol: Scheme; host: string;
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

proc validate_DeleteLicenseConfiguration_597981(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_597983 = header.getOrDefault("X-Amz-Target")
  valid_597983 = validateParameter(valid_597983, JString, required = true, default = newJString(
      "AWSLicenseManager.DeleteLicenseConfiguration"))
  if valid_597983 != nil:
    section.add "X-Amz-Target", valid_597983
  var valid_597984 = header.getOrDefault("X-Amz-Signature")
  valid_597984 = validateParameter(valid_597984, JString, required = false,
                                 default = nil)
  if valid_597984 != nil:
    section.add "X-Amz-Signature", valid_597984
  var valid_597985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597985 = validateParameter(valid_597985, JString, required = false,
                                 default = nil)
  if valid_597985 != nil:
    section.add "X-Amz-Content-Sha256", valid_597985
  var valid_597986 = header.getOrDefault("X-Amz-Date")
  valid_597986 = validateParameter(valid_597986, JString, required = false,
                                 default = nil)
  if valid_597986 != nil:
    section.add "X-Amz-Date", valid_597986
  var valid_597987 = header.getOrDefault("X-Amz-Credential")
  valid_597987 = validateParameter(valid_597987, JString, required = false,
                                 default = nil)
  if valid_597987 != nil:
    section.add "X-Amz-Credential", valid_597987
  var valid_597988 = header.getOrDefault("X-Amz-Security-Token")
  valid_597988 = validateParameter(valid_597988, JString, required = false,
                                 default = nil)
  if valid_597988 != nil:
    section.add "X-Amz-Security-Token", valid_597988
  var valid_597989 = header.getOrDefault("X-Amz-Algorithm")
  valid_597989 = validateParameter(valid_597989, JString, required = false,
                                 default = nil)
  if valid_597989 != nil:
    section.add "X-Amz-Algorithm", valid_597989
  var valid_597990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597990 = validateParameter(valid_597990, JString, required = false,
                                 default = nil)
  if valid_597990 != nil:
    section.add "X-Amz-SignedHeaders", valid_597990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597992: Call_DeleteLicenseConfiguration_597980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified license configuration.</p> <p>You cannot delete a license configuration that is in use.</p>
  ## 
  let valid = call_597992.validator(path, query, header, formData, body)
  let scheme = call_597992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597992.url(scheme.get, call_597992.host, call_597992.base,
                         call_597992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597992, url, valid)

proc call*(call_597993: Call_DeleteLicenseConfiguration_597980; body: JsonNode): Recallable =
  ## deleteLicenseConfiguration
  ## <p>Deletes the specified license configuration.</p> <p>You cannot delete a license configuration that is in use.</p>
  ##   body: JObject (required)
  var body_597994 = newJObject()
  if body != nil:
    body_597994 = body
  result = call_597993.call(nil, nil, nil, nil, body_597994)

var deleteLicenseConfiguration* = Call_DeleteLicenseConfiguration_597980(
    name: "deleteLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.DeleteLicenseConfiguration",
    validator: validate_DeleteLicenseConfiguration_597981, base: "/",
    url: url_DeleteLicenseConfiguration_597982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLicenseConfiguration_597995 = ref object of OpenApiRestCall_597373
proc url_GetLicenseConfiguration_597997(protocol: Scheme; host: string; base: string;
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

proc validate_GetLicenseConfiguration_597996(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_597998 = header.getOrDefault("X-Amz-Target")
  valid_597998 = validateParameter(valid_597998, JString, required = true, default = newJString(
      "AWSLicenseManager.GetLicenseConfiguration"))
  if valid_597998 != nil:
    section.add "X-Amz-Target", valid_597998
  var valid_597999 = header.getOrDefault("X-Amz-Signature")
  valid_597999 = validateParameter(valid_597999, JString, required = false,
                                 default = nil)
  if valid_597999 != nil:
    section.add "X-Amz-Signature", valid_597999
  var valid_598000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598000 = validateParameter(valid_598000, JString, required = false,
                                 default = nil)
  if valid_598000 != nil:
    section.add "X-Amz-Content-Sha256", valid_598000
  var valid_598001 = header.getOrDefault("X-Amz-Date")
  valid_598001 = validateParameter(valid_598001, JString, required = false,
                                 default = nil)
  if valid_598001 != nil:
    section.add "X-Amz-Date", valid_598001
  var valid_598002 = header.getOrDefault("X-Amz-Credential")
  valid_598002 = validateParameter(valid_598002, JString, required = false,
                                 default = nil)
  if valid_598002 != nil:
    section.add "X-Amz-Credential", valid_598002
  var valid_598003 = header.getOrDefault("X-Amz-Security-Token")
  valid_598003 = validateParameter(valid_598003, JString, required = false,
                                 default = nil)
  if valid_598003 != nil:
    section.add "X-Amz-Security-Token", valid_598003
  var valid_598004 = header.getOrDefault("X-Amz-Algorithm")
  valid_598004 = validateParameter(valid_598004, JString, required = false,
                                 default = nil)
  if valid_598004 != nil:
    section.add "X-Amz-Algorithm", valid_598004
  var valid_598005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "X-Amz-SignedHeaders", valid_598005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598007: Call_GetLicenseConfiguration_597995; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets detailed information about the specified license configuration.
  ## 
  let valid = call_598007.validator(path, query, header, formData, body)
  let scheme = call_598007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598007.url(scheme.get, call_598007.host, call_598007.base,
                         call_598007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598007, url, valid)

proc call*(call_598008: Call_GetLicenseConfiguration_597995; body: JsonNode): Recallable =
  ## getLicenseConfiguration
  ## Gets detailed information about the specified license configuration.
  ##   body: JObject (required)
  var body_598009 = newJObject()
  if body != nil:
    body_598009 = body
  result = call_598008.call(nil, nil, nil, nil, body_598009)

var getLicenseConfiguration* = Call_GetLicenseConfiguration_597995(
    name: "getLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.GetLicenseConfiguration",
    validator: validate_GetLicenseConfiguration_597996, base: "/",
    url: url_GetLicenseConfiguration_597997, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSettings_598010 = ref object of OpenApiRestCall_597373
proc url_GetServiceSettings_598012(protocol: Scheme; host: string; base: string;
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

proc validate_GetServiceSettings_598011(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598013 = header.getOrDefault("X-Amz-Target")
  valid_598013 = validateParameter(valid_598013, JString, required = true, default = newJString(
      "AWSLicenseManager.GetServiceSettings"))
  if valid_598013 != nil:
    section.add "X-Amz-Target", valid_598013
  var valid_598014 = header.getOrDefault("X-Amz-Signature")
  valid_598014 = validateParameter(valid_598014, JString, required = false,
                                 default = nil)
  if valid_598014 != nil:
    section.add "X-Amz-Signature", valid_598014
  var valid_598015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598015 = validateParameter(valid_598015, JString, required = false,
                                 default = nil)
  if valid_598015 != nil:
    section.add "X-Amz-Content-Sha256", valid_598015
  var valid_598016 = header.getOrDefault("X-Amz-Date")
  valid_598016 = validateParameter(valid_598016, JString, required = false,
                                 default = nil)
  if valid_598016 != nil:
    section.add "X-Amz-Date", valid_598016
  var valid_598017 = header.getOrDefault("X-Amz-Credential")
  valid_598017 = validateParameter(valid_598017, JString, required = false,
                                 default = nil)
  if valid_598017 != nil:
    section.add "X-Amz-Credential", valid_598017
  var valid_598018 = header.getOrDefault("X-Amz-Security-Token")
  valid_598018 = validateParameter(valid_598018, JString, required = false,
                                 default = nil)
  if valid_598018 != nil:
    section.add "X-Amz-Security-Token", valid_598018
  var valid_598019 = header.getOrDefault("X-Amz-Algorithm")
  valid_598019 = validateParameter(valid_598019, JString, required = false,
                                 default = nil)
  if valid_598019 != nil:
    section.add "X-Amz-Algorithm", valid_598019
  var valid_598020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598020 = validateParameter(valid_598020, JString, required = false,
                                 default = nil)
  if valid_598020 != nil:
    section.add "X-Amz-SignedHeaders", valid_598020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598022: Call_GetServiceSettings_598010; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the License Manager settings for the current Region.
  ## 
  let valid = call_598022.validator(path, query, header, formData, body)
  let scheme = call_598022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598022.url(scheme.get, call_598022.host, call_598022.base,
                         call_598022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598022, url, valid)

proc call*(call_598023: Call_GetServiceSettings_598010; body: JsonNode): Recallable =
  ## getServiceSettings
  ## Gets the License Manager settings for the current Region.
  ##   body: JObject (required)
  var body_598024 = newJObject()
  if body != nil:
    body_598024 = body
  result = call_598023.call(nil, nil, nil, nil, body_598024)

var getServiceSettings* = Call_GetServiceSettings_598010(
    name: "getServiceSettings", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.GetServiceSettings",
    validator: validate_GetServiceSettings_598011, base: "/",
    url: url_GetServiceSettings_598012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationsForLicenseConfiguration_598025 = ref object of OpenApiRestCall_597373
proc url_ListAssociationsForLicenseConfiguration_598027(protocol: Scheme;
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

proc validate_ListAssociationsForLicenseConfiguration_598026(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598028 = header.getOrDefault("X-Amz-Target")
  valid_598028 = validateParameter(valid_598028, JString, required = true, default = newJString(
      "AWSLicenseManager.ListAssociationsForLicenseConfiguration"))
  if valid_598028 != nil:
    section.add "X-Amz-Target", valid_598028
  var valid_598029 = header.getOrDefault("X-Amz-Signature")
  valid_598029 = validateParameter(valid_598029, JString, required = false,
                                 default = nil)
  if valid_598029 != nil:
    section.add "X-Amz-Signature", valid_598029
  var valid_598030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598030 = validateParameter(valid_598030, JString, required = false,
                                 default = nil)
  if valid_598030 != nil:
    section.add "X-Amz-Content-Sha256", valid_598030
  var valid_598031 = header.getOrDefault("X-Amz-Date")
  valid_598031 = validateParameter(valid_598031, JString, required = false,
                                 default = nil)
  if valid_598031 != nil:
    section.add "X-Amz-Date", valid_598031
  var valid_598032 = header.getOrDefault("X-Amz-Credential")
  valid_598032 = validateParameter(valid_598032, JString, required = false,
                                 default = nil)
  if valid_598032 != nil:
    section.add "X-Amz-Credential", valid_598032
  var valid_598033 = header.getOrDefault("X-Amz-Security-Token")
  valid_598033 = validateParameter(valid_598033, JString, required = false,
                                 default = nil)
  if valid_598033 != nil:
    section.add "X-Amz-Security-Token", valid_598033
  var valid_598034 = header.getOrDefault("X-Amz-Algorithm")
  valid_598034 = validateParameter(valid_598034, JString, required = false,
                                 default = nil)
  if valid_598034 != nil:
    section.add "X-Amz-Algorithm", valid_598034
  var valid_598035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598035 = validateParameter(valid_598035, JString, required = false,
                                 default = nil)
  if valid_598035 != nil:
    section.add "X-Amz-SignedHeaders", valid_598035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598037: Call_ListAssociationsForLicenseConfiguration_598025;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the resource associations for the specified license configuration.</p> <p>Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance might not consume a license (depending on the license rules).</p>
  ## 
  let valid = call_598037.validator(path, query, header, formData, body)
  let scheme = call_598037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598037.url(scheme.get, call_598037.host, call_598037.base,
                         call_598037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598037, url, valid)

proc call*(call_598038: Call_ListAssociationsForLicenseConfiguration_598025;
          body: JsonNode): Recallable =
  ## listAssociationsForLicenseConfiguration
  ## <p>Lists the resource associations for the specified license configuration.</p> <p>Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance might not consume a license (depending on the license rules).</p>
  ##   body: JObject (required)
  var body_598039 = newJObject()
  if body != nil:
    body_598039 = body
  result = call_598038.call(nil, nil, nil, nil, body_598039)

var listAssociationsForLicenseConfiguration* = Call_ListAssociationsForLicenseConfiguration_598025(
    name: "listAssociationsForLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.ListAssociationsForLicenseConfiguration",
    validator: validate_ListAssociationsForLicenseConfiguration_598026, base: "/",
    url: url_ListAssociationsForLicenseConfiguration_598027,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFailuresForLicenseConfigurationOperations_598040 = ref object of OpenApiRestCall_597373
proc url_ListFailuresForLicenseConfigurationOperations_598042(protocol: Scheme;
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

proc validate_ListFailuresForLicenseConfigurationOperations_598041(
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598043 = header.getOrDefault("X-Amz-Target")
  valid_598043 = validateParameter(valid_598043, JString, required = true, default = newJString(
      "AWSLicenseManager.ListFailuresForLicenseConfigurationOperations"))
  if valid_598043 != nil:
    section.add "X-Amz-Target", valid_598043
  var valid_598044 = header.getOrDefault("X-Amz-Signature")
  valid_598044 = validateParameter(valid_598044, JString, required = false,
                                 default = nil)
  if valid_598044 != nil:
    section.add "X-Amz-Signature", valid_598044
  var valid_598045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598045 = validateParameter(valid_598045, JString, required = false,
                                 default = nil)
  if valid_598045 != nil:
    section.add "X-Amz-Content-Sha256", valid_598045
  var valid_598046 = header.getOrDefault("X-Amz-Date")
  valid_598046 = validateParameter(valid_598046, JString, required = false,
                                 default = nil)
  if valid_598046 != nil:
    section.add "X-Amz-Date", valid_598046
  var valid_598047 = header.getOrDefault("X-Amz-Credential")
  valid_598047 = validateParameter(valid_598047, JString, required = false,
                                 default = nil)
  if valid_598047 != nil:
    section.add "X-Amz-Credential", valid_598047
  var valid_598048 = header.getOrDefault("X-Amz-Security-Token")
  valid_598048 = validateParameter(valid_598048, JString, required = false,
                                 default = nil)
  if valid_598048 != nil:
    section.add "X-Amz-Security-Token", valid_598048
  var valid_598049 = header.getOrDefault("X-Amz-Algorithm")
  valid_598049 = validateParameter(valid_598049, JString, required = false,
                                 default = nil)
  if valid_598049 != nil:
    section.add "X-Amz-Algorithm", valid_598049
  var valid_598050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598050 = validateParameter(valid_598050, JString, required = false,
                                 default = nil)
  if valid_598050 != nil:
    section.add "X-Amz-SignedHeaders", valid_598050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598052: Call_ListFailuresForLicenseConfigurationOperations_598040;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the license configuration operations that failed.
  ## 
  let valid = call_598052.validator(path, query, header, formData, body)
  let scheme = call_598052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598052.url(scheme.get, call_598052.host, call_598052.base,
                         call_598052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598052, url, valid)

proc call*(call_598053: Call_ListFailuresForLicenseConfigurationOperations_598040;
          body: JsonNode): Recallable =
  ## listFailuresForLicenseConfigurationOperations
  ## Lists the license configuration operations that failed.
  ##   body: JObject (required)
  var body_598054 = newJObject()
  if body != nil:
    body_598054 = body
  result = call_598053.call(nil, nil, nil, nil, body_598054)

var listFailuresForLicenseConfigurationOperations* = Call_ListFailuresForLicenseConfigurationOperations_598040(
    name: "listFailuresForLicenseConfigurationOperations",
    meth: HttpMethod.HttpPost, host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.ListFailuresForLicenseConfigurationOperations",
    validator: validate_ListFailuresForLicenseConfigurationOperations_598041,
    base: "/", url: url_ListFailuresForLicenseConfigurationOperations_598042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLicenseConfigurations_598055 = ref object of OpenApiRestCall_597373
proc url_ListLicenseConfigurations_598057(protocol: Scheme; host: string;
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

proc validate_ListLicenseConfigurations_598056(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598058 = header.getOrDefault("X-Amz-Target")
  valid_598058 = validateParameter(valid_598058, JString, required = true, default = newJString(
      "AWSLicenseManager.ListLicenseConfigurations"))
  if valid_598058 != nil:
    section.add "X-Amz-Target", valid_598058
  var valid_598059 = header.getOrDefault("X-Amz-Signature")
  valid_598059 = validateParameter(valid_598059, JString, required = false,
                                 default = nil)
  if valid_598059 != nil:
    section.add "X-Amz-Signature", valid_598059
  var valid_598060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598060 = validateParameter(valid_598060, JString, required = false,
                                 default = nil)
  if valid_598060 != nil:
    section.add "X-Amz-Content-Sha256", valid_598060
  var valid_598061 = header.getOrDefault("X-Amz-Date")
  valid_598061 = validateParameter(valid_598061, JString, required = false,
                                 default = nil)
  if valid_598061 != nil:
    section.add "X-Amz-Date", valid_598061
  var valid_598062 = header.getOrDefault("X-Amz-Credential")
  valid_598062 = validateParameter(valid_598062, JString, required = false,
                                 default = nil)
  if valid_598062 != nil:
    section.add "X-Amz-Credential", valid_598062
  var valid_598063 = header.getOrDefault("X-Amz-Security-Token")
  valid_598063 = validateParameter(valid_598063, JString, required = false,
                                 default = nil)
  if valid_598063 != nil:
    section.add "X-Amz-Security-Token", valid_598063
  var valid_598064 = header.getOrDefault("X-Amz-Algorithm")
  valid_598064 = validateParameter(valid_598064, JString, required = false,
                                 default = nil)
  if valid_598064 != nil:
    section.add "X-Amz-Algorithm", valid_598064
  var valid_598065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598065 = validateParameter(valid_598065, JString, required = false,
                                 default = nil)
  if valid_598065 != nil:
    section.add "X-Amz-SignedHeaders", valid_598065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598067: Call_ListLicenseConfigurations_598055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the license configurations for your account.
  ## 
  let valid = call_598067.validator(path, query, header, formData, body)
  let scheme = call_598067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598067.url(scheme.get, call_598067.host, call_598067.base,
                         call_598067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598067, url, valid)

proc call*(call_598068: Call_ListLicenseConfigurations_598055; body: JsonNode): Recallable =
  ## listLicenseConfigurations
  ## Lists the license configurations for your account.
  ##   body: JObject (required)
  var body_598069 = newJObject()
  if body != nil:
    body_598069 = body
  result = call_598068.call(nil, nil, nil, nil, body_598069)

var listLicenseConfigurations* = Call_ListLicenseConfigurations_598055(
    name: "listLicenseConfigurations", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListLicenseConfigurations",
    validator: validate_ListLicenseConfigurations_598056, base: "/",
    url: url_ListLicenseConfigurations_598057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLicenseSpecificationsForResource_598070 = ref object of OpenApiRestCall_597373
proc url_ListLicenseSpecificationsForResource_598072(protocol: Scheme;
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

proc validate_ListLicenseSpecificationsForResource_598071(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598073 = header.getOrDefault("X-Amz-Target")
  valid_598073 = validateParameter(valid_598073, JString, required = true, default = newJString(
      "AWSLicenseManager.ListLicenseSpecificationsForResource"))
  if valid_598073 != nil:
    section.add "X-Amz-Target", valid_598073
  var valid_598074 = header.getOrDefault("X-Amz-Signature")
  valid_598074 = validateParameter(valid_598074, JString, required = false,
                                 default = nil)
  if valid_598074 != nil:
    section.add "X-Amz-Signature", valid_598074
  var valid_598075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598075 = validateParameter(valid_598075, JString, required = false,
                                 default = nil)
  if valid_598075 != nil:
    section.add "X-Amz-Content-Sha256", valid_598075
  var valid_598076 = header.getOrDefault("X-Amz-Date")
  valid_598076 = validateParameter(valid_598076, JString, required = false,
                                 default = nil)
  if valid_598076 != nil:
    section.add "X-Amz-Date", valid_598076
  var valid_598077 = header.getOrDefault("X-Amz-Credential")
  valid_598077 = validateParameter(valid_598077, JString, required = false,
                                 default = nil)
  if valid_598077 != nil:
    section.add "X-Amz-Credential", valid_598077
  var valid_598078 = header.getOrDefault("X-Amz-Security-Token")
  valid_598078 = validateParameter(valid_598078, JString, required = false,
                                 default = nil)
  if valid_598078 != nil:
    section.add "X-Amz-Security-Token", valid_598078
  var valid_598079 = header.getOrDefault("X-Amz-Algorithm")
  valid_598079 = validateParameter(valid_598079, JString, required = false,
                                 default = nil)
  if valid_598079 != nil:
    section.add "X-Amz-Algorithm", valid_598079
  var valid_598080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598080 = validateParameter(valid_598080, JString, required = false,
                                 default = nil)
  if valid_598080 != nil:
    section.add "X-Amz-SignedHeaders", valid_598080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598082: Call_ListLicenseSpecificationsForResource_598070;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the license configurations for the specified resource.
  ## 
  let valid = call_598082.validator(path, query, header, formData, body)
  let scheme = call_598082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598082.url(scheme.get, call_598082.host, call_598082.base,
                         call_598082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598082, url, valid)

proc call*(call_598083: Call_ListLicenseSpecificationsForResource_598070;
          body: JsonNode): Recallable =
  ## listLicenseSpecificationsForResource
  ## Describes the license configurations for the specified resource.
  ##   body: JObject (required)
  var body_598084 = newJObject()
  if body != nil:
    body_598084 = body
  result = call_598083.call(nil, nil, nil, nil, body_598084)

var listLicenseSpecificationsForResource* = Call_ListLicenseSpecificationsForResource_598070(
    name: "listLicenseSpecificationsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.ListLicenseSpecificationsForResource",
    validator: validate_ListLicenseSpecificationsForResource_598071, base: "/",
    url: url_ListLicenseSpecificationsForResource_598072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceInventory_598085 = ref object of OpenApiRestCall_597373
proc url_ListResourceInventory_598087(protocol: Scheme; host: string; base: string;
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

proc validate_ListResourceInventory_598086(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598088 = header.getOrDefault("X-Amz-Target")
  valid_598088 = validateParameter(valid_598088, JString, required = true, default = newJString(
      "AWSLicenseManager.ListResourceInventory"))
  if valid_598088 != nil:
    section.add "X-Amz-Target", valid_598088
  var valid_598089 = header.getOrDefault("X-Amz-Signature")
  valid_598089 = validateParameter(valid_598089, JString, required = false,
                                 default = nil)
  if valid_598089 != nil:
    section.add "X-Amz-Signature", valid_598089
  var valid_598090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598090 = validateParameter(valid_598090, JString, required = false,
                                 default = nil)
  if valid_598090 != nil:
    section.add "X-Amz-Content-Sha256", valid_598090
  var valid_598091 = header.getOrDefault("X-Amz-Date")
  valid_598091 = validateParameter(valid_598091, JString, required = false,
                                 default = nil)
  if valid_598091 != nil:
    section.add "X-Amz-Date", valid_598091
  var valid_598092 = header.getOrDefault("X-Amz-Credential")
  valid_598092 = validateParameter(valid_598092, JString, required = false,
                                 default = nil)
  if valid_598092 != nil:
    section.add "X-Amz-Credential", valid_598092
  var valid_598093 = header.getOrDefault("X-Amz-Security-Token")
  valid_598093 = validateParameter(valid_598093, JString, required = false,
                                 default = nil)
  if valid_598093 != nil:
    section.add "X-Amz-Security-Token", valid_598093
  var valid_598094 = header.getOrDefault("X-Amz-Algorithm")
  valid_598094 = validateParameter(valid_598094, JString, required = false,
                                 default = nil)
  if valid_598094 != nil:
    section.add "X-Amz-Algorithm", valid_598094
  var valid_598095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598095 = validateParameter(valid_598095, JString, required = false,
                                 default = nil)
  if valid_598095 != nil:
    section.add "X-Amz-SignedHeaders", valid_598095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598097: Call_ListResourceInventory_598085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists resources managed using Systems Manager inventory.
  ## 
  let valid = call_598097.validator(path, query, header, formData, body)
  let scheme = call_598097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598097.url(scheme.get, call_598097.host, call_598097.base,
                         call_598097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598097, url, valid)

proc call*(call_598098: Call_ListResourceInventory_598085; body: JsonNode): Recallable =
  ## listResourceInventory
  ## Lists resources managed using Systems Manager inventory.
  ##   body: JObject (required)
  var body_598099 = newJObject()
  if body != nil:
    body_598099 = body
  result = call_598098.call(nil, nil, nil, nil, body_598099)

var listResourceInventory* = Call_ListResourceInventory_598085(
    name: "listResourceInventory", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListResourceInventory",
    validator: validate_ListResourceInventory_598086, base: "/",
    url: url_ListResourceInventory_598087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_598100 = ref object of OpenApiRestCall_597373
proc url_ListTagsForResource_598102(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_598101(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598103 = header.getOrDefault("X-Amz-Target")
  valid_598103 = validateParameter(valid_598103, JString, required = true, default = newJString(
      "AWSLicenseManager.ListTagsForResource"))
  if valid_598103 != nil:
    section.add "X-Amz-Target", valid_598103
  var valid_598104 = header.getOrDefault("X-Amz-Signature")
  valid_598104 = validateParameter(valid_598104, JString, required = false,
                                 default = nil)
  if valid_598104 != nil:
    section.add "X-Amz-Signature", valid_598104
  var valid_598105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598105 = validateParameter(valid_598105, JString, required = false,
                                 default = nil)
  if valid_598105 != nil:
    section.add "X-Amz-Content-Sha256", valid_598105
  var valid_598106 = header.getOrDefault("X-Amz-Date")
  valid_598106 = validateParameter(valid_598106, JString, required = false,
                                 default = nil)
  if valid_598106 != nil:
    section.add "X-Amz-Date", valid_598106
  var valid_598107 = header.getOrDefault("X-Amz-Credential")
  valid_598107 = validateParameter(valid_598107, JString, required = false,
                                 default = nil)
  if valid_598107 != nil:
    section.add "X-Amz-Credential", valid_598107
  var valid_598108 = header.getOrDefault("X-Amz-Security-Token")
  valid_598108 = validateParameter(valid_598108, JString, required = false,
                                 default = nil)
  if valid_598108 != nil:
    section.add "X-Amz-Security-Token", valid_598108
  var valid_598109 = header.getOrDefault("X-Amz-Algorithm")
  valid_598109 = validateParameter(valid_598109, JString, required = false,
                                 default = nil)
  if valid_598109 != nil:
    section.add "X-Amz-Algorithm", valid_598109
  var valid_598110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598110 = validateParameter(valid_598110, JString, required = false,
                                 default = nil)
  if valid_598110 != nil:
    section.add "X-Amz-SignedHeaders", valid_598110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598112: Call_ListTagsForResource_598100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified license configuration.
  ## 
  let valid = call_598112.validator(path, query, header, formData, body)
  let scheme = call_598112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598112.url(scheme.get, call_598112.host, call_598112.base,
                         call_598112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598112, url, valid)

proc call*(call_598113: Call_ListTagsForResource_598100; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified license configuration.
  ##   body: JObject (required)
  var body_598114 = newJObject()
  if body != nil:
    body_598114 = body
  result = call_598113.call(nil, nil, nil, nil, body_598114)

var listTagsForResource* = Call_ListTagsForResource_598100(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListTagsForResource",
    validator: validate_ListTagsForResource_598101, base: "/",
    url: url_ListTagsForResource_598102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsageForLicenseConfiguration_598115 = ref object of OpenApiRestCall_597373
proc url_ListUsageForLicenseConfiguration_598117(protocol: Scheme; host: string;
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

proc validate_ListUsageForLicenseConfiguration_598116(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598118 = header.getOrDefault("X-Amz-Target")
  valid_598118 = validateParameter(valid_598118, JString, required = true, default = newJString(
      "AWSLicenseManager.ListUsageForLicenseConfiguration"))
  if valid_598118 != nil:
    section.add "X-Amz-Target", valid_598118
  var valid_598119 = header.getOrDefault("X-Amz-Signature")
  valid_598119 = validateParameter(valid_598119, JString, required = false,
                                 default = nil)
  if valid_598119 != nil:
    section.add "X-Amz-Signature", valid_598119
  var valid_598120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598120 = validateParameter(valid_598120, JString, required = false,
                                 default = nil)
  if valid_598120 != nil:
    section.add "X-Amz-Content-Sha256", valid_598120
  var valid_598121 = header.getOrDefault("X-Amz-Date")
  valid_598121 = validateParameter(valid_598121, JString, required = false,
                                 default = nil)
  if valid_598121 != nil:
    section.add "X-Amz-Date", valid_598121
  var valid_598122 = header.getOrDefault("X-Amz-Credential")
  valid_598122 = validateParameter(valid_598122, JString, required = false,
                                 default = nil)
  if valid_598122 != nil:
    section.add "X-Amz-Credential", valid_598122
  var valid_598123 = header.getOrDefault("X-Amz-Security-Token")
  valid_598123 = validateParameter(valid_598123, JString, required = false,
                                 default = nil)
  if valid_598123 != nil:
    section.add "X-Amz-Security-Token", valid_598123
  var valid_598124 = header.getOrDefault("X-Amz-Algorithm")
  valid_598124 = validateParameter(valid_598124, JString, required = false,
                                 default = nil)
  if valid_598124 != nil:
    section.add "X-Amz-Algorithm", valid_598124
  var valid_598125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598125 = validateParameter(valid_598125, JString, required = false,
                                 default = nil)
  if valid_598125 != nil:
    section.add "X-Amz-SignedHeaders", valid_598125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598127: Call_ListUsageForLicenseConfiguration_598115;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all license usage records for a license configuration, displaying license consumption details by resource at a selected point in time. Use this action to audit the current license consumption for any license inventory and configuration.
  ## 
  let valid = call_598127.validator(path, query, header, formData, body)
  let scheme = call_598127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598127.url(scheme.get, call_598127.host, call_598127.base,
                         call_598127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598127, url, valid)

proc call*(call_598128: Call_ListUsageForLicenseConfiguration_598115;
          body: JsonNode): Recallable =
  ## listUsageForLicenseConfiguration
  ## Lists all license usage records for a license configuration, displaying license consumption details by resource at a selected point in time. Use this action to audit the current license consumption for any license inventory and configuration.
  ##   body: JObject (required)
  var body_598129 = newJObject()
  if body != nil:
    body_598129 = body
  result = call_598128.call(nil, nil, nil, nil, body_598129)

var listUsageForLicenseConfiguration* = Call_ListUsageForLicenseConfiguration_598115(
    name: "listUsageForLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListUsageForLicenseConfiguration",
    validator: validate_ListUsageForLicenseConfiguration_598116, base: "/",
    url: url_ListUsageForLicenseConfiguration_598117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_598130 = ref object of OpenApiRestCall_597373
proc url_TagResource_598132(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_598131(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598133 = header.getOrDefault("X-Amz-Target")
  valid_598133 = validateParameter(valid_598133, JString, required = true, default = newJString(
      "AWSLicenseManager.TagResource"))
  if valid_598133 != nil:
    section.add "X-Amz-Target", valid_598133
  var valid_598134 = header.getOrDefault("X-Amz-Signature")
  valid_598134 = validateParameter(valid_598134, JString, required = false,
                                 default = nil)
  if valid_598134 != nil:
    section.add "X-Amz-Signature", valid_598134
  var valid_598135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598135 = validateParameter(valid_598135, JString, required = false,
                                 default = nil)
  if valid_598135 != nil:
    section.add "X-Amz-Content-Sha256", valid_598135
  var valid_598136 = header.getOrDefault("X-Amz-Date")
  valid_598136 = validateParameter(valid_598136, JString, required = false,
                                 default = nil)
  if valid_598136 != nil:
    section.add "X-Amz-Date", valid_598136
  var valid_598137 = header.getOrDefault("X-Amz-Credential")
  valid_598137 = validateParameter(valid_598137, JString, required = false,
                                 default = nil)
  if valid_598137 != nil:
    section.add "X-Amz-Credential", valid_598137
  var valid_598138 = header.getOrDefault("X-Amz-Security-Token")
  valid_598138 = validateParameter(valid_598138, JString, required = false,
                                 default = nil)
  if valid_598138 != nil:
    section.add "X-Amz-Security-Token", valid_598138
  var valid_598139 = header.getOrDefault("X-Amz-Algorithm")
  valid_598139 = validateParameter(valid_598139, JString, required = false,
                                 default = nil)
  if valid_598139 != nil:
    section.add "X-Amz-Algorithm", valid_598139
  var valid_598140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598140 = validateParameter(valid_598140, JString, required = false,
                                 default = nil)
  if valid_598140 != nil:
    section.add "X-Amz-SignedHeaders", valid_598140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598142: Call_TagResource_598130; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified tags to the specified license configuration.
  ## 
  let valid = call_598142.validator(path, query, header, formData, body)
  let scheme = call_598142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598142.url(scheme.get, call_598142.host, call_598142.base,
                         call_598142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598142, url, valid)

proc call*(call_598143: Call_TagResource_598130; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tags to the specified license configuration.
  ##   body: JObject (required)
  var body_598144 = newJObject()
  if body != nil:
    body_598144 = body
  result = call_598143.call(nil, nil, nil, nil, body_598144)

var tagResource* = Call_TagResource_598130(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.TagResource",
                                        validator: validate_TagResource_598131,
                                        base: "/", url: url_TagResource_598132,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_598145 = ref object of OpenApiRestCall_597373
proc url_UntagResource_598147(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_598146(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598148 = header.getOrDefault("X-Amz-Target")
  valid_598148 = validateParameter(valid_598148, JString, required = true, default = newJString(
      "AWSLicenseManager.UntagResource"))
  if valid_598148 != nil:
    section.add "X-Amz-Target", valid_598148
  var valid_598149 = header.getOrDefault("X-Amz-Signature")
  valid_598149 = validateParameter(valid_598149, JString, required = false,
                                 default = nil)
  if valid_598149 != nil:
    section.add "X-Amz-Signature", valid_598149
  var valid_598150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598150 = validateParameter(valid_598150, JString, required = false,
                                 default = nil)
  if valid_598150 != nil:
    section.add "X-Amz-Content-Sha256", valid_598150
  var valid_598151 = header.getOrDefault("X-Amz-Date")
  valid_598151 = validateParameter(valid_598151, JString, required = false,
                                 default = nil)
  if valid_598151 != nil:
    section.add "X-Amz-Date", valid_598151
  var valid_598152 = header.getOrDefault("X-Amz-Credential")
  valid_598152 = validateParameter(valid_598152, JString, required = false,
                                 default = nil)
  if valid_598152 != nil:
    section.add "X-Amz-Credential", valid_598152
  var valid_598153 = header.getOrDefault("X-Amz-Security-Token")
  valid_598153 = validateParameter(valid_598153, JString, required = false,
                                 default = nil)
  if valid_598153 != nil:
    section.add "X-Amz-Security-Token", valid_598153
  var valid_598154 = header.getOrDefault("X-Amz-Algorithm")
  valid_598154 = validateParameter(valid_598154, JString, required = false,
                                 default = nil)
  if valid_598154 != nil:
    section.add "X-Amz-Algorithm", valid_598154
  var valid_598155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598155 = validateParameter(valid_598155, JString, required = false,
                                 default = nil)
  if valid_598155 != nil:
    section.add "X-Amz-SignedHeaders", valid_598155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598157: Call_UntagResource_598145; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from the specified license configuration.
  ## 
  let valid = call_598157.validator(path, query, header, formData, body)
  let scheme = call_598157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598157.url(scheme.get, call_598157.host, call_598157.base,
                         call_598157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598157, url, valid)

proc call*(call_598158: Call_UntagResource_598145; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified license configuration.
  ##   body: JObject (required)
  var body_598159 = newJObject()
  if body != nil:
    body_598159 = body
  result = call_598158.call(nil, nil, nil, nil, body_598159)

var untagResource* = Call_UntagResource_598145(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UntagResource",
    validator: validate_UntagResource_598146, base: "/", url: url_UntagResource_598147,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLicenseConfiguration_598160 = ref object of OpenApiRestCall_597373
proc url_UpdateLicenseConfiguration_598162(protocol: Scheme; host: string;
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

proc validate_UpdateLicenseConfiguration_598161(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598163 = header.getOrDefault("X-Amz-Target")
  valid_598163 = validateParameter(valid_598163, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateLicenseConfiguration"))
  if valid_598163 != nil:
    section.add "X-Amz-Target", valid_598163
  var valid_598164 = header.getOrDefault("X-Amz-Signature")
  valid_598164 = validateParameter(valid_598164, JString, required = false,
                                 default = nil)
  if valid_598164 != nil:
    section.add "X-Amz-Signature", valid_598164
  var valid_598165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598165 = validateParameter(valid_598165, JString, required = false,
                                 default = nil)
  if valid_598165 != nil:
    section.add "X-Amz-Content-Sha256", valid_598165
  var valid_598166 = header.getOrDefault("X-Amz-Date")
  valid_598166 = validateParameter(valid_598166, JString, required = false,
                                 default = nil)
  if valid_598166 != nil:
    section.add "X-Amz-Date", valid_598166
  var valid_598167 = header.getOrDefault("X-Amz-Credential")
  valid_598167 = validateParameter(valid_598167, JString, required = false,
                                 default = nil)
  if valid_598167 != nil:
    section.add "X-Amz-Credential", valid_598167
  var valid_598168 = header.getOrDefault("X-Amz-Security-Token")
  valid_598168 = validateParameter(valid_598168, JString, required = false,
                                 default = nil)
  if valid_598168 != nil:
    section.add "X-Amz-Security-Token", valid_598168
  var valid_598169 = header.getOrDefault("X-Amz-Algorithm")
  valid_598169 = validateParameter(valid_598169, JString, required = false,
                                 default = nil)
  if valid_598169 != nil:
    section.add "X-Amz-Algorithm", valid_598169
  var valid_598170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598170 = validateParameter(valid_598170, JString, required = false,
                                 default = nil)
  if valid_598170 != nil:
    section.add "X-Amz-SignedHeaders", valid_598170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598172: Call_UpdateLicenseConfiguration_598160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the attributes of an existing license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
  ## 
  let valid = call_598172.validator(path, query, header, formData, body)
  let scheme = call_598172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598172.url(scheme.get, call_598172.host, call_598172.base,
                         call_598172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598172, url, valid)

proc call*(call_598173: Call_UpdateLicenseConfiguration_598160; body: JsonNode): Recallable =
  ## updateLicenseConfiguration
  ## <p>Modifies the attributes of an existing license configuration.</p> <p>A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), host affinity (how long a VM must be associated with a host), and the number of licenses purchased and used.</p>
  ##   body: JObject (required)
  var body_598174 = newJObject()
  if body != nil:
    body_598174 = body
  result = call_598173.call(nil, nil, nil, nil, body_598174)

var updateLicenseConfiguration* = Call_UpdateLicenseConfiguration_598160(
    name: "updateLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UpdateLicenseConfiguration",
    validator: validate_UpdateLicenseConfiguration_598161, base: "/",
    url: url_UpdateLicenseConfiguration_598162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLicenseSpecificationsForResource_598175 = ref object of OpenApiRestCall_597373
proc url_UpdateLicenseSpecificationsForResource_598177(protocol: Scheme;
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

proc validate_UpdateLicenseSpecificationsForResource_598176(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598178 = header.getOrDefault("X-Amz-Target")
  valid_598178 = validateParameter(valid_598178, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateLicenseSpecificationsForResource"))
  if valid_598178 != nil:
    section.add "X-Amz-Target", valid_598178
  var valid_598179 = header.getOrDefault("X-Amz-Signature")
  valid_598179 = validateParameter(valid_598179, JString, required = false,
                                 default = nil)
  if valid_598179 != nil:
    section.add "X-Amz-Signature", valid_598179
  var valid_598180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598180 = validateParameter(valid_598180, JString, required = false,
                                 default = nil)
  if valid_598180 != nil:
    section.add "X-Amz-Content-Sha256", valid_598180
  var valid_598181 = header.getOrDefault("X-Amz-Date")
  valid_598181 = validateParameter(valid_598181, JString, required = false,
                                 default = nil)
  if valid_598181 != nil:
    section.add "X-Amz-Date", valid_598181
  var valid_598182 = header.getOrDefault("X-Amz-Credential")
  valid_598182 = validateParameter(valid_598182, JString, required = false,
                                 default = nil)
  if valid_598182 != nil:
    section.add "X-Amz-Credential", valid_598182
  var valid_598183 = header.getOrDefault("X-Amz-Security-Token")
  valid_598183 = validateParameter(valid_598183, JString, required = false,
                                 default = nil)
  if valid_598183 != nil:
    section.add "X-Amz-Security-Token", valid_598183
  var valid_598184 = header.getOrDefault("X-Amz-Algorithm")
  valid_598184 = validateParameter(valid_598184, JString, required = false,
                                 default = nil)
  if valid_598184 != nil:
    section.add "X-Amz-Algorithm", valid_598184
  var valid_598185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598185 = validateParameter(valid_598185, JString, required = false,
                                 default = nil)
  if valid_598185 != nil:
    section.add "X-Amz-SignedHeaders", valid_598185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598187: Call_UpdateLicenseSpecificationsForResource_598175;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds or removes the specified license configurations for the specified AWS resource.</p> <p>You can update the license specifications of AMIs, instances, and hosts. You cannot update the license specifications for launch templates and AWS CloudFormation templates, as they send license configurations to the operation that creates the resource.</p>
  ## 
  let valid = call_598187.validator(path, query, header, formData, body)
  let scheme = call_598187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598187.url(scheme.get, call_598187.host, call_598187.base,
                         call_598187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598187, url, valid)

proc call*(call_598188: Call_UpdateLicenseSpecificationsForResource_598175;
          body: JsonNode): Recallable =
  ## updateLicenseSpecificationsForResource
  ## <p>Adds or removes the specified license configurations for the specified AWS resource.</p> <p>You can update the license specifications of AMIs, instances, and hosts. You cannot update the license specifications for launch templates and AWS CloudFormation templates, as they send license configurations to the operation that creates the resource.</p>
  ##   body: JObject (required)
  var body_598189 = newJObject()
  if body != nil:
    body_598189 = body
  result = call_598188.call(nil, nil, nil, nil, body_598189)

var updateLicenseSpecificationsForResource* = Call_UpdateLicenseSpecificationsForResource_598175(
    name: "updateLicenseSpecificationsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.UpdateLicenseSpecificationsForResource",
    validator: validate_UpdateLicenseSpecificationsForResource_598176, base: "/",
    url: url_UpdateLicenseSpecificationsForResource_598177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSettings_598190 = ref object of OpenApiRestCall_597373
proc url_UpdateServiceSettings_598192(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateServiceSettings_598191(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598193 = header.getOrDefault("X-Amz-Target")
  valid_598193 = validateParameter(valid_598193, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateServiceSettings"))
  if valid_598193 != nil:
    section.add "X-Amz-Target", valid_598193
  var valid_598194 = header.getOrDefault("X-Amz-Signature")
  valid_598194 = validateParameter(valid_598194, JString, required = false,
                                 default = nil)
  if valid_598194 != nil:
    section.add "X-Amz-Signature", valid_598194
  var valid_598195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598195 = validateParameter(valid_598195, JString, required = false,
                                 default = nil)
  if valid_598195 != nil:
    section.add "X-Amz-Content-Sha256", valid_598195
  var valid_598196 = header.getOrDefault("X-Amz-Date")
  valid_598196 = validateParameter(valid_598196, JString, required = false,
                                 default = nil)
  if valid_598196 != nil:
    section.add "X-Amz-Date", valid_598196
  var valid_598197 = header.getOrDefault("X-Amz-Credential")
  valid_598197 = validateParameter(valid_598197, JString, required = false,
                                 default = nil)
  if valid_598197 != nil:
    section.add "X-Amz-Credential", valid_598197
  var valid_598198 = header.getOrDefault("X-Amz-Security-Token")
  valid_598198 = validateParameter(valid_598198, JString, required = false,
                                 default = nil)
  if valid_598198 != nil:
    section.add "X-Amz-Security-Token", valid_598198
  var valid_598199 = header.getOrDefault("X-Amz-Algorithm")
  valid_598199 = validateParameter(valid_598199, JString, required = false,
                                 default = nil)
  if valid_598199 != nil:
    section.add "X-Amz-Algorithm", valid_598199
  var valid_598200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598200 = validateParameter(valid_598200, JString, required = false,
                                 default = nil)
  if valid_598200 != nil:
    section.add "X-Amz-SignedHeaders", valid_598200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598202: Call_UpdateServiceSettings_598190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates License Manager settings for the current Region.
  ## 
  let valid = call_598202.validator(path, query, header, formData, body)
  let scheme = call_598202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598202.url(scheme.get, call_598202.host, call_598202.base,
                         call_598202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598202, url, valid)

proc call*(call_598203: Call_UpdateServiceSettings_598190; body: JsonNode): Recallable =
  ## updateServiceSettings
  ## Updates License Manager settings for the current Region.
  ##   body: JObject (required)
  var body_598204 = newJObject()
  if body != nil:
    body_598204 = body
  result = call_598203.call(nil, nil, nil, nil, body_598204)

var updateServiceSettings* = Call_UpdateServiceSettings_598190(
    name: "updateServiceSettings", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UpdateServiceSettings",
    validator: validate_UpdateServiceSettings_598191, base: "/",
    url: url_UpdateServiceSettings_598192, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
