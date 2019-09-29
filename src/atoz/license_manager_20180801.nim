
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS License Manager
## version: 2018-08-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname> AWS License Manager </fullname> <p> <i>This is the AWS License Manager API Reference.</i> It provides descriptions, syntax, and usage examples for each of the actions and data types for License Manager. The topic for each action shows the Query API request parameters and the XML response. You can also view the XML request elements in the WSDL. </p> <p> Alternatively, you can use one of the AWS SDKs to access an API that's tailored to the programming language or platform that you're using. For more information, see <a href="http://aws.amazon.com/tools/#SDKs">AWS SDKs</a>. </p>
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

  OpenApiRestCall_593421 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593421](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593421): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateLicenseConfiguration_593758 = ref object of OpenApiRestCall_593421
proc url_CreateLicenseConfiguration_593760(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLicenseConfiguration_593759(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new license configuration object. A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or VCPU), tenancy (shared tenancy, Amazon EC2 Dedicated Instance, Amazon EC2 Dedicated Host, or any of these), host affinity (how long a VM must be associated with a host), the number of licenses purchased and used.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593872 = header.getOrDefault("X-Amz-Date")
  valid_593872 = validateParameter(valid_593872, JString, required = false,
                                 default = nil)
  if valid_593872 != nil:
    section.add "X-Amz-Date", valid_593872
  var valid_593873 = header.getOrDefault("X-Amz-Security-Token")
  valid_593873 = validateParameter(valid_593873, JString, required = false,
                                 default = nil)
  if valid_593873 != nil:
    section.add "X-Amz-Security-Token", valid_593873
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593887 = header.getOrDefault("X-Amz-Target")
  valid_593887 = validateParameter(valid_593887, JString, required = true, default = newJString(
      "AWSLicenseManager.CreateLicenseConfiguration"))
  if valid_593887 != nil:
    section.add "X-Amz-Target", valid_593887
  var valid_593888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Content-Sha256", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Algorithm")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Algorithm", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-Signature")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Signature", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-SignedHeaders", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-Credential")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Credential", valid_593892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593916: Call_CreateLicenseConfiguration_593758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new license configuration object. A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or VCPU), tenancy (shared tenancy, Amazon EC2 Dedicated Instance, Amazon EC2 Dedicated Host, or any of these), host affinity (how long a VM must be associated with a host), the number of licenses purchased and used.
  ## 
  let valid = call_593916.validator(path, query, header, formData, body)
  let scheme = call_593916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593916.url(scheme.get, call_593916.host, call_593916.base,
                         call_593916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593916, url, valid)

proc call*(call_593987: Call_CreateLicenseConfiguration_593758; body: JsonNode): Recallable =
  ## createLicenseConfiguration
  ## Creates a new license configuration object. A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or VCPU), tenancy (shared tenancy, Amazon EC2 Dedicated Instance, Amazon EC2 Dedicated Host, or any of these), host affinity (how long a VM must be associated with a host), the number of licenses purchased and used.
  ##   body: JObject (required)
  var body_593988 = newJObject()
  if body != nil:
    body_593988 = body
  result = call_593987.call(nil, nil, nil, nil, body_593988)

var createLicenseConfiguration* = Call_CreateLicenseConfiguration_593758(
    name: "createLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.CreateLicenseConfiguration",
    validator: validate_CreateLicenseConfiguration_593759, base: "/",
    url: url_CreateLicenseConfiguration_593760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLicenseConfiguration_594027 = ref object of OpenApiRestCall_593421
proc url_DeleteLicenseConfiguration_594029(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteLicenseConfiguration_594028(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing license configuration. This action fails if the configuration is in use.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594030 = header.getOrDefault("X-Amz-Date")
  valid_594030 = validateParameter(valid_594030, JString, required = false,
                                 default = nil)
  if valid_594030 != nil:
    section.add "X-Amz-Date", valid_594030
  var valid_594031 = header.getOrDefault("X-Amz-Security-Token")
  valid_594031 = validateParameter(valid_594031, JString, required = false,
                                 default = nil)
  if valid_594031 != nil:
    section.add "X-Amz-Security-Token", valid_594031
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594032 = header.getOrDefault("X-Amz-Target")
  valid_594032 = validateParameter(valid_594032, JString, required = true, default = newJString(
      "AWSLicenseManager.DeleteLicenseConfiguration"))
  if valid_594032 != nil:
    section.add "X-Amz-Target", valid_594032
  var valid_594033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-Content-Sha256", valid_594033
  var valid_594034 = header.getOrDefault("X-Amz-Algorithm")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "X-Amz-Algorithm", valid_594034
  var valid_594035 = header.getOrDefault("X-Amz-Signature")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Signature", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-SignedHeaders", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Credential")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Credential", valid_594037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594039: Call_DeleteLicenseConfiguration_594027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing license configuration. This action fails if the configuration is in use.
  ## 
  let valid = call_594039.validator(path, query, header, formData, body)
  let scheme = call_594039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594039.url(scheme.get, call_594039.host, call_594039.base,
                         call_594039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594039, url, valid)

proc call*(call_594040: Call_DeleteLicenseConfiguration_594027; body: JsonNode): Recallable =
  ## deleteLicenseConfiguration
  ## Deletes an existing license configuration. This action fails if the configuration is in use.
  ##   body: JObject (required)
  var body_594041 = newJObject()
  if body != nil:
    body_594041 = body
  result = call_594040.call(nil, nil, nil, nil, body_594041)

var deleteLicenseConfiguration* = Call_DeleteLicenseConfiguration_594027(
    name: "deleteLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.DeleteLicenseConfiguration",
    validator: validate_DeleteLicenseConfiguration_594028, base: "/",
    url: url_DeleteLicenseConfiguration_594029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLicenseConfiguration_594042 = ref object of OpenApiRestCall_593421
proc url_GetLicenseConfiguration_594044(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLicenseConfiguration_594043(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a detailed description of a license configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594045 = header.getOrDefault("X-Amz-Date")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-Date", valid_594045
  var valid_594046 = header.getOrDefault("X-Amz-Security-Token")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Security-Token", valid_594046
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594047 = header.getOrDefault("X-Amz-Target")
  valid_594047 = validateParameter(valid_594047, JString, required = true, default = newJString(
      "AWSLicenseManager.GetLicenseConfiguration"))
  if valid_594047 != nil:
    section.add "X-Amz-Target", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Content-Sha256", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Algorithm")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Algorithm", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Signature")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Signature", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-SignedHeaders", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Credential")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Credential", valid_594052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594054: Call_GetLicenseConfiguration_594042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a detailed description of a license configuration.
  ## 
  let valid = call_594054.validator(path, query, header, formData, body)
  let scheme = call_594054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594054.url(scheme.get, call_594054.host, call_594054.base,
                         call_594054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594054, url, valid)

proc call*(call_594055: Call_GetLicenseConfiguration_594042; body: JsonNode): Recallable =
  ## getLicenseConfiguration
  ## Returns a detailed description of a license configuration.
  ##   body: JObject (required)
  var body_594056 = newJObject()
  if body != nil:
    body_594056 = body
  result = call_594055.call(nil, nil, nil, nil, body_594056)

var getLicenseConfiguration* = Call_GetLicenseConfiguration_594042(
    name: "getLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.GetLicenseConfiguration",
    validator: validate_GetLicenseConfiguration_594043, base: "/",
    url: url_GetLicenseConfiguration_594044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSettings_594057 = ref object of OpenApiRestCall_593421
proc url_GetServiceSettings_594059(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetServiceSettings_594058(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets License Manager settings for a region. Exposes the configured S3 bucket, SNS topic, etc., for inspection. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594060 = header.getOrDefault("X-Amz-Date")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-Date", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-Security-Token")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Security-Token", valid_594061
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594062 = header.getOrDefault("X-Amz-Target")
  valid_594062 = validateParameter(valid_594062, JString, required = true, default = newJString(
      "AWSLicenseManager.GetServiceSettings"))
  if valid_594062 != nil:
    section.add "X-Amz-Target", valid_594062
  var valid_594063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Content-Sha256", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Algorithm")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Algorithm", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Signature")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Signature", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-SignedHeaders", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Credential")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Credential", valid_594067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594069: Call_GetServiceSettings_594057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets License Manager settings for a region. Exposes the configured S3 bucket, SNS topic, etc., for inspection. 
  ## 
  let valid = call_594069.validator(path, query, header, formData, body)
  let scheme = call_594069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594069.url(scheme.get, call_594069.host, call_594069.base,
                         call_594069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594069, url, valid)

proc call*(call_594070: Call_GetServiceSettings_594057; body: JsonNode): Recallable =
  ## getServiceSettings
  ## Gets License Manager settings for a region. Exposes the configured S3 bucket, SNS topic, etc., for inspection. 
  ##   body: JObject (required)
  var body_594071 = newJObject()
  if body != nil:
    body_594071 = body
  result = call_594070.call(nil, nil, nil, nil, body_594071)

var getServiceSettings* = Call_GetServiceSettings_594057(
    name: "getServiceSettings", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.GetServiceSettings",
    validator: validate_GetServiceSettings_594058, base: "/",
    url: url_GetServiceSettings_594059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationsForLicenseConfiguration_594072 = ref object of OpenApiRestCall_593421
proc url_ListAssociationsForLicenseConfiguration_594074(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAssociationsForLicenseConfiguration_594073(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the resource associations for a license configuration. Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance may not consume a license (depending on the license rules). Use this operation to find all resources associated with a license configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594075 = header.getOrDefault("X-Amz-Date")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Date", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Security-Token")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Security-Token", valid_594076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594077 = header.getOrDefault("X-Amz-Target")
  valid_594077 = validateParameter(valid_594077, JString, required = true, default = newJString(
      "AWSLicenseManager.ListAssociationsForLicenseConfiguration"))
  if valid_594077 != nil:
    section.add "X-Amz-Target", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Content-Sha256", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Algorithm")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Algorithm", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Signature")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Signature", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-SignedHeaders", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Credential")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Credential", valid_594082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594084: Call_ListAssociationsForLicenseConfiguration_594072;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the resource associations for a license configuration. Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance may not consume a license (depending on the license rules). Use this operation to find all resources associated with a license configuration.
  ## 
  let valid = call_594084.validator(path, query, header, formData, body)
  let scheme = call_594084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594084.url(scheme.get, call_594084.host, call_594084.base,
                         call_594084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594084, url, valid)

proc call*(call_594085: Call_ListAssociationsForLicenseConfiguration_594072;
          body: JsonNode): Recallable =
  ## listAssociationsForLicenseConfiguration
  ## Lists the resource associations for a license configuration. Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance may not consume a license (depending on the license rules). Use this operation to find all resources associated with a license configuration.
  ##   body: JObject (required)
  var body_594086 = newJObject()
  if body != nil:
    body_594086 = body
  result = call_594085.call(nil, nil, nil, nil, body_594086)

var listAssociationsForLicenseConfiguration* = Call_ListAssociationsForLicenseConfiguration_594072(
    name: "listAssociationsForLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.ListAssociationsForLicenseConfiguration",
    validator: validate_ListAssociationsForLicenseConfiguration_594073, base: "/",
    url: url_ListAssociationsForLicenseConfiguration_594074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLicenseConfigurations_594087 = ref object of OpenApiRestCall_593421
proc url_ListLicenseConfigurations_594089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLicenseConfigurations_594088(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists license configuration objects for an account, each containing the name, description, license type, and other license terms modeled from a license agreement.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594090 = header.getOrDefault("X-Amz-Date")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Date", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Security-Token")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Security-Token", valid_594091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594092 = header.getOrDefault("X-Amz-Target")
  valid_594092 = validateParameter(valid_594092, JString, required = true, default = newJString(
      "AWSLicenseManager.ListLicenseConfigurations"))
  if valid_594092 != nil:
    section.add "X-Amz-Target", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Content-Sha256", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Algorithm")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Algorithm", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Signature")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Signature", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-SignedHeaders", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Credential")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Credential", valid_594097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594099: Call_ListLicenseConfigurations_594087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists license configuration objects for an account, each containing the name, description, license type, and other license terms modeled from a license agreement.
  ## 
  let valid = call_594099.validator(path, query, header, formData, body)
  let scheme = call_594099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594099.url(scheme.get, call_594099.host, call_594099.base,
                         call_594099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594099, url, valid)

proc call*(call_594100: Call_ListLicenseConfigurations_594087; body: JsonNode): Recallable =
  ## listLicenseConfigurations
  ## Lists license configuration objects for an account, each containing the name, description, license type, and other license terms modeled from a license agreement.
  ##   body: JObject (required)
  var body_594101 = newJObject()
  if body != nil:
    body_594101 = body
  result = call_594100.call(nil, nil, nil, nil, body_594101)

var listLicenseConfigurations* = Call_ListLicenseConfigurations_594087(
    name: "listLicenseConfigurations", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListLicenseConfigurations",
    validator: validate_ListLicenseConfigurations_594088, base: "/",
    url: url_ListLicenseConfigurations_594089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLicenseSpecificationsForResource_594102 = ref object of OpenApiRestCall_593421
proc url_ListLicenseSpecificationsForResource_594104(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLicenseSpecificationsForResource_594103(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the license configuration for a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594105 = header.getOrDefault("X-Amz-Date")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-Date", valid_594105
  var valid_594106 = header.getOrDefault("X-Amz-Security-Token")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Security-Token", valid_594106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594107 = header.getOrDefault("X-Amz-Target")
  valid_594107 = validateParameter(valid_594107, JString, required = true, default = newJString(
      "AWSLicenseManager.ListLicenseSpecificationsForResource"))
  if valid_594107 != nil:
    section.add "X-Amz-Target", valid_594107
  var valid_594108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Content-Sha256", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Algorithm")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Algorithm", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Signature")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Signature", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-SignedHeaders", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Credential")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Credential", valid_594112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594114: Call_ListLicenseSpecificationsForResource_594102;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the license configuration for a resource.
  ## 
  let valid = call_594114.validator(path, query, header, formData, body)
  let scheme = call_594114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594114.url(scheme.get, call_594114.host, call_594114.base,
                         call_594114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594114, url, valid)

proc call*(call_594115: Call_ListLicenseSpecificationsForResource_594102;
          body: JsonNode): Recallable =
  ## listLicenseSpecificationsForResource
  ## Returns the license configuration for a resource.
  ##   body: JObject (required)
  var body_594116 = newJObject()
  if body != nil:
    body_594116 = body
  result = call_594115.call(nil, nil, nil, nil, body_594116)

var listLicenseSpecificationsForResource* = Call_ListLicenseSpecificationsForResource_594102(
    name: "listLicenseSpecificationsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.ListLicenseSpecificationsForResource",
    validator: validate_ListLicenseSpecificationsForResource_594103, base: "/",
    url: url_ListLicenseSpecificationsForResource_594104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceInventory_594117 = ref object of OpenApiRestCall_593421
proc url_ListResourceInventory_594119(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResourceInventory_594118(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a detailed list of resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594120 = header.getOrDefault("X-Amz-Date")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-Date", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-Security-Token")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Security-Token", valid_594121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594122 = header.getOrDefault("X-Amz-Target")
  valid_594122 = validateParameter(valid_594122, JString, required = true, default = newJString(
      "AWSLicenseManager.ListResourceInventory"))
  if valid_594122 != nil:
    section.add "X-Amz-Target", valid_594122
  var valid_594123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Content-Sha256", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Algorithm")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Algorithm", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Signature")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Signature", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-SignedHeaders", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Credential")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Credential", valid_594127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594129: Call_ListResourceInventory_594117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a detailed list of resources.
  ## 
  let valid = call_594129.validator(path, query, header, formData, body)
  let scheme = call_594129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594129.url(scheme.get, call_594129.host, call_594129.base,
                         call_594129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594129, url, valid)

proc call*(call_594130: Call_ListResourceInventory_594117; body: JsonNode): Recallable =
  ## listResourceInventory
  ## Returns a detailed list of resources.
  ##   body: JObject (required)
  var body_594131 = newJObject()
  if body != nil:
    body_594131 = body
  result = call_594130.call(nil, nil, nil, nil, body_594131)

var listResourceInventory* = Call_ListResourceInventory_594117(
    name: "listResourceInventory", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListResourceInventory",
    validator: validate_ListResourceInventory_594118, base: "/",
    url: url_ListResourceInventory_594119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594132 = ref object of OpenApiRestCall_593421
proc url_ListTagsForResource_594134(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_594133(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists tags attached to a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594135 = header.getOrDefault("X-Amz-Date")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Date", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Security-Token")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Security-Token", valid_594136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594137 = header.getOrDefault("X-Amz-Target")
  valid_594137 = validateParameter(valid_594137, JString, required = true, default = newJString(
      "AWSLicenseManager.ListTagsForResource"))
  if valid_594137 != nil:
    section.add "X-Amz-Target", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-Content-Sha256", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Algorithm")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Algorithm", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Signature")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Signature", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-SignedHeaders", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-Credential")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-Credential", valid_594142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594144: Call_ListTagsForResource_594132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists tags attached to a resource.
  ## 
  let valid = call_594144.validator(path, query, header, formData, body)
  let scheme = call_594144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594144.url(scheme.get, call_594144.host, call_594144.base,
                         call_594144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594144, url, valid)

proc call*(call_594145: Call_ListTagsForResource_594132; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists tags attached to a resource.
  ##   body: JObject (required)
  var body_594146 = newJObject()
  if body != nil:
    body_594146 = body
  result = call_594145.call(nil, nil, nil, nil, body_594146)

var listTagsForResource* = Call_ListTagsForResource_594132(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListTagsForResource",
    validator: validate_ListTagsForResource_594133, base: "/",
    url: url_ListTagsForResource_594134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsageForLicenseConfiguration_594147 = ref object of OpenApiRestCall_593421
proc url_ListUsageForLicenseConfiguration_594149(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListUsageForLicenseConfiguration_594148(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594150 = header.getOrDefault("X-Amz-Date")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Date", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Security-Token")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Security-Token", valid_594151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594152 = header.getOrDefault("X-Amz-Target")
  valid_594152 = validateParameter(valid_594152, JString, required = true, default = newJString(
      "AWSLicenseManager.ListUsageForLicenseConfiguration"))
  if valid_594152 != nil:
    section.add "X-Amz-Target", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Content-Sha256", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Algorithm")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Algorithm", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Signature")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Signature", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-SignedHeaders", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-Credential")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-Credential", valid_594157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594159: Call_ListUsageForLicenseConfiguration_594147;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all license usage records for a license configuration, displaying license consumption details by resource at a selected point in time. Use this action to audit the current license consumption for any license inventory and configuration.
  ## 
  let valid = call_594159.validator(path, query, header, formData, body)
  let scheme = call_594159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594159.url(scheme.get, call_594159.host, call_594159.base,
                         call_594159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594159, url, valid)

proc call*(call_594160: Call_ListUsageForLicenseConfiguration_594147;
          body: JsonNode): Recallable =
  ## listUsageForLicenseConfiguration
  ## Lists all license usage records for a license configuration, displaying license consumption details by resource at a selected point in time. Use this action to audit the current license consumption for any license inventory and configuration.
  ##   body: JObject (required)
  var body_594161 = newJObject()
  if body != nil:
    body_594161 = body
  result = call_594160.call(nil, nil, nil, nil, body_594161)

var listUsageForLicenseConfiguration* = Call_ListUsageForLicenseConfiguration_594147(
    name: "listUsageForLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListUsageForLicenseConfiguration",
    validator: validate_ListUsageForLicenseConfiguration_594148, base: "/",
    url: url_ListUsageForLicenseConfiguration_594149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594162 = ref object of OpenApiRestCall_593421
proc url_TagResource_594164(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_594163(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Attach one of more tags to any resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594165 = header.getOrDefault("X-Amz-Date")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Date", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Security-Token")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Security-Token", valid_594166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594167 = header.getOrDefault("X-Amz-Target")
  valid_594167 = validateParameter(valid_594167, JString, required = true, default = newJString(
      "AWSLicenseManager.TagResource"))
  if valid_594167 != nil:
    section.add "X-Amz-Target", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Content-Sha256", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Algorithm")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Algorithm", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Signature")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Signature", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-SignedHeaders", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Credential")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Credential", valid_594172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594174: Call_TagResource_594162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attach one of more tags to any resource.
  ## 
  let valid = call_594174.validator(path, query, header, formData, body)
  let scheme = call_594174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594174.url(scheme.get, call_594174.host, call_594174.base,
                         call_594174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594174, url, valid)

proc call*(call_594175: Call_TagResource_594162; body: JsonNode): Recallable =
  ## tagResource
  ## Attach one of more tags to any resource.
  ##   body: JObject (required)
  var body_594176 = newJObject()
  if body != nil:
    body_594176 = body
  result = call_594175.call(nil, nil, nil, nil, body_594176)

var tagResource* = Call_TagResource_594162(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.TagResource",
                                        validator: validate_TagResource_594163,
                                        base: "/", url: url_TagResource_594164,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594177 = ref object of OpenApiRestCall_593421
proc url_UntagResource_594179(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_594178(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594180 = header.getOrDefault("X-Amz-Date")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Date", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Security-Token")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Security-Token", valid_594181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594182 = header.getOrDefault("X-Amz-Target")
  valid_594182 = validateParameter(valid_594182, JString, required = true, default = newJString(
      "AWSLicenseManager.UntagResource"))
  if valid_594182 != nil:
    section.add "X-Amz-Target", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Content-Sha256", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Algorithm")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Algorithm", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Signature")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Signature", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-SignedHeaders", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-Credential")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-Credential", valid_594187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594189: Call_UntagResource_594177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a resource.
  ## 
  let valid = call_594189.validator(path, query, header, formData, body)
  let scheme = call_594189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594189.url(scheme.get, call_594189.host, call_594189.base,
                         call_594189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594189, url, valid)

proc call*(call_594190: Call_UntagResource_594177; body: JsonNode): Recallable =
  ## untagResource
  ## Remove tags from a resource.
  ##   body: JObject (required)
  var body_594191 = newJObject()
  if body != nil:
    body_594191 = body
  result = call_594190.call(nil, nil, nil, nil, body_594191)

var untagResource* = Call_UntagResource_594177(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UntagResource",
    validator: validate_UntagResource_594178, base: "/", url: url_UntagResource_594179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLicenseConfiguration_594192 = ref object of OpenApiRestCall_593421
proc url_UpdateLicenseConfiguration_594194(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateLicenseConfiguration_594193(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the attributes of an existing license configuration object. A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (Instances, cores, sockets, VCPUs), tenancy (shared or Dedicated Host), host affinity (how long a VM is associated with a host), the number of licenses purchased and used.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594195 = header.getOrDefault("X-Amz-Date")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Date", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Security-Token")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Security-Token", valid_594196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594197 = header.getOrDefault("X-Amz-Target")
  valid_594197 = validateParameter(valid_594197, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateLicenseConfiguration"))
  if valid_594197 != nil:
    section.add "X-Amz-Target", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Content-Sha256", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Algorithm")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Algorithm", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Signature")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Signature", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-SignedHeaders", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-Credential")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-Credential", valid_594202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594204: Call_UpdateLicenseConfiguration_594192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the attributes of an existing license configuration object. A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (Instances, cores, sockets, VCPUs), tenancy (shared or Dedicated Host), host affinity (how long a VM is associated with a host), the number of licenses purchased and used.
  ## 
  let valid = call_594204.validator(path, query, header, formData, body)
  let scheme = call_594204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594204.url(scheme.get, call_594204.host, call_594204.base,
                         call_594204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594204, url, valid)

proc call*(call_594205: Call_UpdateLicenseConfiguration_594192; body: JsonNode): Recallable =
  ## updateLicenseConfiguration
  ## Modifies the attributes of an existing license configuration object. A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (Instances, cores, sockets, VCPUs), tenancy (shared or Dedicated Host), host affinity (how long a VM is associated with a host), the number of licenses purchased and used.
  ##   body: JObject (required)
  var body_594206 = newJObject()
  if body != nil:
    body_594206 = body
  result = call_594205.call(nil, nil, nil, nil, body_594206)

var updateLicenseConfiguration* = Call_UpdateLicenseConfiguration_594192(
    name: "updateLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UpdateLicenseConfiguration",
    validator: validate_UpdateLicenseConfiguration_594193, base: "/",
    url: url_UpdateLicenseConfiguration_594194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLicenseSpecificationsForResource_594207 = ref object of OpenApiRestCall_593421
proc url_UpdateLicenseSpecificationsForResource_594209(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateLicenseSpecificationsForResource_594208(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds or removes license configurations for a specified AWS resource. This operation currently supports updating the license specifications of AMIs, instances, and hosts. Launch templates and AWS CloudFormation templates are not managed from this operation as those resources send the license configurations directly to a resource creation operation, such as <code>RunInstances</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594210 = header.getOrDefault("X-Amz-Date")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Date", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Security-Token")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Security-Token", valid_594211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594212 = header.getOrDefault("X-Amz-Target")
  valid_594212 = validateParameter(valid_594212, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateLicenseSpecificationsForResource"))
  if valid_594212 != nil:
    section.add "X-Amz-Target", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Content-Sha256", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Algorithm")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Algorithm", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Signature")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Signature", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-SignedHeaders", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-Credential")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-Credential", valid_594217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594219: Call_UpdateLicenseSpecificationsForResource_594207;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds or removes license configurations for a specified AWS resource. This operation currently supports updating the license specifications of AMIs, instances, and hosts. Launch templates and AWS CloudFormation templates are not managed from this operation as those resources send the license configurations directly to a resource creation operation, such as <code>RunInstances</code>.
  ## 
  let valid = call_594219.validator(path, query, header, formData, body)
  let scheme = call_594219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594219.url(scheme.get, call_594219.host, call_594219.base,
                         call_594219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594219, url, valid)

proc call*(call_594220: Call_UpdateLicenseSpecificationsForResource_594207;
          body: JsonNode): Recallable =
  ## updateLicenseSpecificationsForResource
  ## Adds or removes license configurations for a specified AWS resource. This operation currently supports updating the license specifications of AMIs, instances, and hosts. Launch templates and AWS CloudFormation templates are not managed from this operation as those resources send the license configurations directly to a resource creation operation, such as <code>RunInstances</code>.
  ##   body: JObject (required)
  var body_594221 = newJObject()
  if body != nil:
    body_594221 = body
  result = call_594220.call(nil, nil, nil, nil, body_594221)

var updateLicenseSpecificationsForResource* = Call_UpdateLicenseSpecificationsForResource_594207(
    name: "updateLicenseSpecificationsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.UpdateLicenseSpecificationsForResource",
    validator: validate_UpdateLicenseSpecificationsForResource_594208, base: "/",
    url: url_UpdateLicenseSpecificationsForResource_594209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSettings_594222 = ref object of OpenApiRestCall_593421
proc url_UpdateServiceSettings_594224(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateServiceSettings_594223(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates License Manager service settings.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594225 = header.getOrDefault("X-Amz-Date")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Date", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Security-Token")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Security-Token", valid_594226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594227 = header.getOrDefault("X-Amz-Target")
  valid_594227 = validateParameter(valid_594227, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateServiceSettings"))
  if valid_594227 != nil:
    section.add "X-Amz-Target", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Content-Sha256", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Algorithm")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Algorithm", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Signature")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Signature", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-SignedHeaders", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-Credential")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-Credential", valid_594232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594234: Call_UpdateServiceSettings_594222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates License Manager service settings.
  ## 
  let valid = call_594234.validator(path, query, header, formData, body)
  let scheme = call_594234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594234.url(scheme.get, call_594234.host, call_594234.base,
                         call_594234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594234, url, valid)

proc call*(call_594235: Call_UpdateServiceSettings_594222; body: JsonNode): Recallable =
  ## updateServiceSettings
  ## Updates License Manager service settings.
  ##   body: JObject (required)
  var body_594236 = newJObject()
  if body != nil:
    body_594236 = body
  result = call_594235.call(nil, nil, nil, nil, body_594236)

var updateServiceSettings* = Call_UpdateServiceSettings_594222(
    name: "updateServiceSettings", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UpdateServiceSettings",
    validator: validate_UpdateServiceSettings_594223, base: "/",
    url: url_UpdateServiceSettings_594224, schemes: {Scheme.Https, Scheme.Http})
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
