
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

  OpenApiRestCall_602450 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602450](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602450): Option[Scheme] {.used.} =
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
  Call_CreateLicenseConfiguration_602787 = ref object of OpenApiRestCall_602450
proc url_CreateLicenseConfiguration_602789(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLicenseConfiguration_602788(path: JsonNode; query: JsonNode;
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
  var valid_602901 = header.getOrDefault("X-Amz-Date")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Date", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Security-Token")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Security-Token", valid_602902
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602916 = header.getOrDefault("X-Amz-Target")
  valid_602916 = validateParameter(valid_602916, JString, required = true, default = newJString(
      "AWSLicenseManager.CreateLicenseConfiguration"))
  if valid_602916 != nil:
    section.add "X-Amz-Target", valid_602916
  var valid_602917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Content-Sha256", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Algorithm")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Algorithm", valid_602918
  var valid_602919 = header.getOrDefault("X-Amz-Signature")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Signature", valid_602919
  var valid_602920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-SignedHeaders", valid_602920
  var valid_602921 = header.getOrDefault("X-Amz-Credential")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Credential", valid_602921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602945: Call_CreateLicenseConfiguration_602787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new license configuration object. A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or VCPU), tenancy (shared tenancy, Amazon EC2 Dedicated Instance, Amazon EC2 Dedicated Host, or any of these), host affinity (how long a VM must be associated with a host), the number of licenses purchased and used.
  ## 
  let valid = call_602945.validator(path, query, header, formData, body)
  let scheme = call_602945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602945.url(scheme.get, call_602945.host, call_602945.base,
                         call_602945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602945, url, valid)

proc call*(call_603016: Call_CreateLicenseConfiguration_602787; body: JsonNode): Recallable =
  ## createLicenseConfiguration
  ## Creates a new license configuration object. A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or VCPU), tenancy (shared tenancy, Amazon EC2 Dedicated Instance, Amazon EC2 Dedicated Host, or any of these), host affinity (how long a VM must be associated with a host), the number of licenses purchased and used.
  ##   body: JObject (required)
  var body_603017 = newJObject()
  if body != nil:
    body_603017 = body
  result = call_603016.call(nil, nil, nil, nil, body_603017)

var createLicenseConfiguration* = Call_CreateLicenseConfiguration_602787(
    name: "createLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.CreateLicenseConfiguration",
    validator: validate_CreateLicenseConfiguration_602788, base: "/",
    url: url_CreateLicenseConfiguration_602789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLicenseConfiguration_603056 = ref object of OpenApiRestCall_602450
proc url_DeleteLicenseConfiguration_603058(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteLicenseConfiguration_603057(path: JsonNode; query: JsonNode;
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
  var valid_603059 = header.getOrDefault("X-Amz-Date")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "X-Amz-Date", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Security-Token")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Security-Token", valid_603060
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603061 = header.getOrDefault("X-Amz-Target")
  valid_603061 = validateParameter(valid_603061, JString, required = true, default = newJString(
      "AWSLicenseManager.DeleteLicenseConfiguration"))
  if valid_603061 != nil:
    section.add "X-Amz-Target", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Content-Sha256", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-Algorithm")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Algorithm", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Signature")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Signature", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-SignedHeaders", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Credential")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Credential", valid_603066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603068: Call_DeleteLicenseConfiguration_603056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing license configuration. This action fails if the configuration is in use.
  ## 
  let valid = call_603068.validator(path, query, header, formData, body)
  let scheme = call_603068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603068.url(scheme.get, call_603068.host, call_603068.base,
                         call_603068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603068, url, valid)

proc call*(call_603069: Call_DeleteLicenseConfiguration_603056; body: JsonNode): Recallable =
  ## deleteLicenseConfiguration
  ## Deletes an existing license configuration. This action fails if the configuration is in use.
  ##   body: JObject (required)
  var body_603070 = newJObject()
  if body != nil:
    body_603070 = body
  result = call_603069.call(nil, nil, nil, nil, body_603070)

var deleteLicenseConfiguration* = Call_DeleteLicenseConfiguration_603056(
    name: "deleteLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.DeleteLicenseConfiguration",
    validator: validate_DeleteLicenseConfiguration_603057, base: "/",
    url: url_DeleteLicenseConfiguration_603058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLicenseConfiguration_603071 = ref object of OpenApiRestCall_602450
proc url_GetLicenseConfiguration_603073(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLicenseConfiguration_603072(path: JsonNode; query: JsonNode;
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
  var valid_603074 = header.getOrDefault("X-Amz-Date")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Date", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Security-Token")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Security-Token", valid_603075
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603076 = header.getOrDefault("X-Amz-Target")
  valid_603076 = validateParameter(valid_603076, JString, required = true, default = newJString(
      "AWSLicenseManager.GetLicenseConfiguration"))
  if valid_603076 != nil:
    section.add "X-Amz-Target", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Content-Sha256", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Algorithm")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Algorithm", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Signature")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Signature", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-SignedHeaders", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Credential")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Credential", valid_603081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603083: Call_GetLicenseConfiguration_603071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a detailed description of a license configuration.
  ## 
  let valid = call_603083.validator(path, query, header, formData, body)
  let scheme = call_603083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603083.url(scheme.get, call_603083.host, call_603083.base,
                         call_603083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603083, url, valid)

proc call*(call_603084: Call_GetLicenseConfiguration_603071; body: JsonNode): Recallable =
  ## getLicenseConfiguration
  ## Returns a detailed description of a license configuration.
  ##   body: JObject (required)
  var body_603085 = newJObject()
  if body != nil:
    body_603085 = body
  result = call_603084.call(nil, nil, nil, nil, body_603085)

var getLicenseConfiguration* = Call_GetLicenseConfiguration_603071(
    name: "getLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.GetLicenseConfiguration",
    validator: validate_GetLicenseConfiguration_603072, base: "/",
    url: url_GetLicenseConfiguration_603073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSettings_603086 = ref object of OpenApiRestCall_602450
proc url_GetServiceSettings_603088(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetServiceSettings_603087(path: JsonNode; query: JsonNode;
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
  var valid_603089 = header.getOrDefault("X-Amz-Date")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Date", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Security-Token")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Security-Token", valid_603090
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603091 = header.getOrDefault("X-Amz-Target")
  valid_603091 = validateParameter(valid_603091, JString, required = true, default = newJString(
      "AWSLicenseManager.GetServiceSettings"))
  if valid_603091 != nil:
    section.add "X-Amz-Target", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Content-Sha256", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Algorithm")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Algorithm", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Signature")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Signature", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-SignedHeaders", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Credential")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Credential", valid_603096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603098: Call_GetServiceSettings_603086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets License Manager settings for a region. Exposes the configured S3 bucket, SNS topic, etc., for inspection. 
  ## 
  let valid = call_603098.validator(path, query, header, formData, body)
  let scheme = call_603098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603098.url(scheme.get, call_603098.host, call_603098.base,
                         call_603098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603098, url, valid)

proc call*(call_603099: Call_GetServiceSettings_603086; body: JsonNode): Recallable =
  ## getServiceSettings
  ## Gets License Manager settings for a region. Exposes the configured S3 bucket, SNS topic, etc., for inspection. 
  ##   body: JObject (required)
  var body_603100 = newJObject()
  if body != nil:
    body_603100 = body
  result = call_603099.call(nil, nil, nil, nil, body_603100)

var getServiceSettings* = Call_GetServiceSettings_603086(
    name: "getServiceSettings", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.GetServiceSettings",
    validator: validate_GetServiceSettings_603087, base: "/",
    url: url_GetServiceSettings_603088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationsForLicenseConfiguration_603101 = ref object of OpenApiRestCall_602450
proc url_ListAssociationsForLicenseConfiguration_603103(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAssociationsForLicenseConfiguration_603102(path: JsonNode;
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
  var valid_603104 = header.getOrDefault("X-Amz-Date")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Date", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Security-Token")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Security-Token", valid_603105
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603106 = header.getOrDefault("X-Amz-Target")
  valid_603106 = validateParameter(valid_603106, JString, required = true, default = newJString(
      "AWSLicenseManager.ListAssociationsForLicenseConfiguration"))
  if valid_603106 != nil:
    section.add "X-Amz-Target", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Content-Sha256", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Algorithm")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Algorithm", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Signature")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Signature", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-SignedHeaders", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Credential")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Credential", valid_603111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603113: Call_ListAssociationsForLicenseConfiguration_603101;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the resource associations for a license configuration. Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance may not consume a license (depending on the license rules). Use this operation to find all resources associated with a license configuration.
  ## 
  let valid = call_603113.validator(path, query, header, formData, body)
  let scheme = call_603113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603113.url(scheme.get, call_603113.host, call_603113.base,
                         call_603113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603113, url, valid)

proc call*(call_603114: Call_ListAssociationsForLicenseConfiguration_603101;
          body: JsonNode): Recallable =
  ## listAssociationsForLicenseConfiguration
  ## Lists the resource associations for a license configuration. Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance may not consume a license (depending on the license rules). Use this operation to find all resources associated with a license configuration.
  ##   body: JObject (required)
  var body_603115 = newJObject()
  if body != nil:
    body_603115 = body
  result = call_603114.call(nil, nil, nil, nil, body_603115)

var listAssociationsForLicenseConfiguration* = Call_ListAssociationsForLicenseConfiguration_603101(
    name: "listAssociationsForLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.ListAssociationsForLicenseConfiguration",
    validator: validate_ListAssociationsForLicenseConfiguration_603102, base: "/",
    url: url_ListAssociationsForLicenseConfiguration_603103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLicenseConfigurations_603116 = ref object of OpenApiRestCall_602450
proc url_ListLicenseConfigurations_603118(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLicenseConfigurations_603117(path: JsonNode; query: JsonNode;
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
  var valid_603119 = header.getOrDefault("X-Amz-Date")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Date", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Security-Token")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Security-Token", valid_603120
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603121 = header.getOrDefault("X-Amz-Target")
  valid_603121 = validateParameter(valid_603121, JString, required = true, default = newJString(
      "AWSLicenseManager.ListLicenseConfigurations"))
  if valid_603121 != nil:
    section.add "X-Amz-Target", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Content-Sha256", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Algorithm")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Algorithm", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Signature")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Signature", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-SignedHeaders", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Credential")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Credential", valid_603126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603128: Call_ListLicenseConfigurations_603116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists license configuration objects for an account, each containing the name, description, license type, and other license terms modeled from a license agreement.
  ## 
  let valid = call_603128.validator(path, query, header, formData, body)
  let scheme = call_603128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603128.url(scheme.get, call_603128.host, call_603128.base,
                         call_603128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603128, url, valid)

proc call*(call_603129: Call_ListLicenseConfigurations_603116; body: JsonNode): Recallable =
  ## listLicenseConfigurations
  ## Lists license configuration objects for an account, each containing the name, description, license type, and other license terms modeled from a license agreement.
  ##   body: JObject (required)
  var body_603130 = newJObject()
  if body != nil:
    body_603130 = body
  result = call_603129.call(nil, nil, nil, nil, body_603130)

var listLicenseConfigurations* = Call_ListLicenseConfigurations_603116(
    name: "listLicenseConfigurations", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListLicenseConfigurations",
    validator: validate_ListLicenseConfigurations_603117, base: "/",
    url: url_ListLicenseConfigurations_603118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLicenseSpecificationsForResource_603131 = ref object of OpenApiRestCall_602450
proc url_ListLicenseSpecificationsForResource_603133(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLicenseSpecificationsForResource_603132(path: JsonNode;
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
  var valid_603134 = header.getOrDefault("X-Amz-Date")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Date", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Security-Token")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Security-Token", valid_603135
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603136 = header.getOrDefault("X-Amz-Target")
  valid_603136 = validateParameter(valid_603136, JString, required = true, default = newJString(
      "AWSLicenseManager.ListLicenseSpecificationsForResource"))
  if valid_603136 != nil:
    section.add "X-Amz-Target", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Content-Sha256", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Algorithm")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Algorithm", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Signature")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Signature", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-SignedHeaders", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Credential")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Credential", valid_603141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603143: Call_ListLicenseSpecificationsForResource_603131;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the license configuration for a resource.
  ## 
  let valid = call_603143.validator(path, query, header, formData, body)
  let scheme = call_603143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603143.url(scheme.get, call_603143.host, call_603143.base,
                         call_603143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603143, url, valid)

proc call*(call_603144: Call_ListLicenseSpecificationsForResource_603131;
          body: JsonNode): Recallable =
  ## listLicenseSpecificationsForResource
  ## Returns the license configuration for a resource.
  ##   body: JObject (required)
  var body_603145 = newJObject()
  if body != nil:
    body_603145 = body
  result = call_603144.call(nil, nil, nil, nil, body_603145)

var listLicenseSpecificationsForResource* = Call_ListLicenseSpecificationsForResource_603131(
    name: "listLicenseSpecificationsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.ListLicenseSpecificationsForResource",
    validator: validate_ListLicenseSpecificationsForResource_603132, base: "/",
    url: url_ListLicenseSpecificationsForResource_603133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceInventory_603146 = ref object of OpenApiRestCall_602450
proc url_ListResourceInventory_603148(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResourceInventory_603147(path: JsonNode; query: JsonNode;
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
  var valid_603149 = header.getOrDefault("X-Amz-Date")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Date", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Security-Token")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Security-Token", valid_603150
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603151 = header.getOrDefault("X-Amz-Target")
  valid_603151 = validateParameter(valid_603151, JString, required = true, default = newJString(
      "AWSLicenseManager.ListResourceInventory"))
  if valid_603151 != nil:
    section.add "X-Amz-Target", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Content-Sha256", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Algorithm")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Algorithm", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Signature")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Signature", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-SignedHeaders", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Credential")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Credential", valid_603156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603158: Call_ListResourceInventory_603146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a detailed list of resources.
  ## 
  let valid = call_603158.validator(path, query, header, formData, body)
  let scheme = call_603158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603158.url(scheme.get, call_603158.host, call_603158.base,
                         call_603158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603158, url, valid)

proc call*(call_603159: Call_ListResourceInventory_603146; body: JsonNode): Recallable =
  ## listResourceInventory
  ## Returns a detailed list of resources.
  ##   body: JObject (required)
  var body_603160 = newJObject()
  if body != nil:
    body_603160 = body
  result = call_603159.call(nil, nil, nil, nil, body_603160)

var listResourceInventory* = Call_ListResourceInventory_603146(
    name: "listResourceInventory", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListResourceInventory",
    validator: validate_ListResourceInventory_603147, base: "/",
    url: url_ListResourceInventory_603148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603161 = ref object of OpenApiRestCall_602450
proc url_ListTagsForResource_603163(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_603162(path: JsonNode; query: JsonNode;
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
  var valid_603164 = header.getOrDefault("X-Amz-Date")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Date", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Security-Token")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Security-Token", valid_603165
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603166 = header.getOrDefault("X-Amz-Target")
  valid_603166 = validateParameter(valid_603166, JString, required = true, default = newJString(
      "AWSLicenseManager.ListTagsForResource"))
  if valid_603166 != nil:
    section.add "X-Amz-Target", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Content-Sha256", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Algorithm")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Algorithm", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Signature")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Signature", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-SignedHeaders", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Credential")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Credential", valid_603171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603173: Call_ListTagsForResource_603161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists tags attached to a resource.
  ## 
  let valid = call_603173.validator(path, query, header, formData, body)
  let scheme = call_603173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603173.url(scheme.get, call_603173.host, call_603173.base,
                         call_603173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603173, url, valid)

proc call*(call_603174: Call_ListTagsForResource_603161; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists tags attached to a resource.
  ##   body: JObject (required)
  var body_603175 = newJObject()
  if body != nil:
    body_603175 = body
  result = call_603174.call(nil, nil, nil, nil, body_603175)

var listTagsForResource* = Call_ListTagsForResource_603161(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListTagsForResource",
    validator: validate_ListTagsForResource_603162, base: "/",
    url: url_ListTagsForResource_603163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsageForLicenseConfiguration_603176 = ref object of OpenApiRestCall_602450
proc url_ListUsageForLicenseConfiguration_603178(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListUsageForLicenseConfiguration_603177(path: JsonNode;
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
  var valid_603179 = header.getOrDefault("X-Amz-Date")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Date", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Security-Token")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Security-Token", valid_603180
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603181 = header.getOrDefault("X-Amz-Target")
  valid_603181 = validateParameter(valid_603181, JString, required = true, default = newJString(
      "AWSLicenseManager.ListUsageForLicenseConfiguration"))
  if valid_603181 != nil:
    section.add "X-Amz-Target", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Content-Sha256", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Algorithm")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Algorithm", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Signature")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Signature", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-SignedHeaders", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Credential")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Credential", valid_603186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603188: Call_ListUsageForLicenseConfiguration_603176;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all license usage records for a license configuration, displaying license consumption details by resource at a selected point in time. Use this action to audit the current license consumption for any license inventory and configuration.
  ## 
  let valid = call_603188.validator(path, query, header, formData, body)
  let scheme = call_603188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603188.url(scheme.get, call_603188.host, call_603188.base,
                         call_603188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603188, url, valid)

proc call*(call_603189: Call_ListUsageForLicenseConfiguration_603176;
          body: JsonNode): Recallable =
  ## listUsageForLicenseConfiguration
  ## Lists all license usage records for a license configuration, displaying license consumption details by resource at a selected point in time. Use this action to audit the current license consumption for any license inventory and configuration.
  ##   body: JObject (required)
  var body_603190 = newJObject()
  if body != nil:
    body_603190 = body
  result = call_603189.call(nil, nil, nil, nil, body_603190)

var listUsageForLicenseConfiguration* = Call_ListUsageForLicenseConfiguration_603176(
    name: "listUsageForLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListUsageForLicenseConfiguration",
    validator: validate_ListUsageForLicenseConfiguration_603177, base: "/",
    url: url_ListUsageForLicenseConfiguration_603178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603191 = ref object of OpenApiRestCall_602450
proc url_TagResource_603193(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_603192(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603194 = header.getOrDefault("X-Amz-Date")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Date", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Security-Token")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Security-Token", valid_603195
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603196 = header.getOrDefault("X-Amz-Target")
  valid_603196 = validateParameter(valid_603196, JString, required = true, default = newJString(
      "AWSLicenseManager.TagResource"))
  if valid_603196 != nil:
    section.add "X-Amz-Target", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Content-Sha256", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Algorithm")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Algorithm", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Signature")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Signature", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-SignedHeaders", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Credential")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Credential", valid_603201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603203: Call_TagResource_603191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attach one of more tags to any resource.
  ## 
  let valid = call_603203.validator(path, query, header, formData, body)
  let scheme = call_603203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603203.url(scheme.get, call_603203.host, call_603203.base,
                         call_603203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603203, url, valid)

proc call*(call_603204: Call_TagResource_603191; body: JsonNode): Recallable =
  ## tagResource
  ## Attach one of more tags to any resource.
  ##   body: JObject (required)
  var body_603205 = newJObject()
  if body != nil:
    body_603205 = body
  result = call_603204.call(nil, nil, nil, nil, body_603205)

var tagResource* = Call_TagResource_603191(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.TagResource",
                                        validator: validate_TagResource_603192,
                                        base: "/", url: url_TagResource_603193,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603206 = ref object of OpenApiRestCall_602450
proc url_UntagResource_603208(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_603207(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603209 = header.getOrDefault("X-Amz-Date")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Date", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Security-Token")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Security-Token", valid_603210
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603211 = header.getOrDefault("X-Amz-Target")
  valid_603211 = validateParameter(valid_603211, JString, required = true, default = newJString(
      "AWSLicenseManager.UntagResource"))
  if valid_603211 != nil:
    section.add "X-Amz-Target", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Content-Sha256", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Algorithm")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Algorithm", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Signature")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Signature", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-SignedHeaders", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Credential")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Credential", valid_603216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603218: Call_UntagResource_603206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a resource.
  ## 
  let valid = call_603218.validator(path, query, header, formData, body)
  let scheme = call_603218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603218.url(scheme.get, call_603218.host, call_603218.base,
                         call_603218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603218, url, valid)

proc call*(call_603219: Call_UntagResource_603206; body: JsonNode): Recallable =
  ## untagResource
  ## Remove tags from a resource.
  ##   body: JObject (required)
  var body_603220 = newJObject()
  if body != nil:
    body_603220 = body
  result = call_603219.call(nil, nil, nil, nil, body_603220)

var untagResource* = Call_UntagResource_603206(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UntagResource",
    validator: validate_UntagResource_603207, base: "/", url: url_UntagResource_603208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLicenseConfiguration_603221 = ref object of OpenApiRestCall_602450
proc url_UpdateLicenseConfiguration_603223(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateLicenseConfiguration_603222(path: JsonNode; query: JsonNode;
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
  var valid_603224 = header.getOrDefault("X-Amz-Date")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Date", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Security-Token")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Security-Token", valid_603225
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603226 = header.getOrDefault("X-Amz-Target")
  valid_603226 = validateParameter(valid_603226, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateLicenseConfiguration"))
  if valid_603226 != nil:
    section.add "X-Amz-Target", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Content-Sha256", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Algorithm")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Algorithm", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Signature")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Signature", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-SignedHeaders", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Credential")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Credential", valid_603231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603233: Call_UpdateLicenseConfiguration_603221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the attributes of an existing license configuration object. A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (Instances, cores, sockets, VCPUs), tenancy (shared or Dedicated Host), host affinity (how long a VM is associated with a host), the number of licenses purchased and used.
  ## 
  let valid = call_603233.validator(path, query, header, formData, body)
  let scheme = call_603233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603233.url(scheme.get, call_603233.host, call_603233.base,
                         call_603233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603233, url, valid)

proc call*(call_603234: Call_UpdateLicenseConfiguration_603221; body: JsonNode): Recallable =
  ## updateLicenseConfiguration
  ## Modifies the attributes of an existing license configuration object. A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (Instances, cores, sockets, VCPUs), tenancy (shared or Dedicated Host), host affinity (how long a VM is associated with a host), the number of licenses purchased and used.
  ##   body: JObject (required)
  var body_603235 = newJObject()
  if body != nil:
    body_603235 = body
  result = call_603234.call(nil, nil, nil, nil, body_603235)

var updateLicenseConfiguration* = Call_UpdateLicenseConfiguration_603221(
    name: "updateLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UpdateLicenseConfiguration",
    validator: validate_UpdateLicenseConfiguration_603222, base: "/",
    url: url_UpdateLicenseConfiguration_603223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLicenseSpecificationsForResource_603236 = ref object of OpenApiRestCall_602450
proc url_UpdateLicenseSpecificationsForResource_603238(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateLicenseSpecificationsForResource_603237(path: JsonNode;
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
  var valid_603239 = header.getOrDefault("X-Amz-Date")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Date", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Security-Token")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Security-Token", valid_603240
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603241 = header.getOrDefault("X-Amz-Target")
  valid_603241 = validateParameter(valid_603241, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateLicenseSpecificationsForResource"))
  if valid_603241 != nil:
    section.add "X-Amz-Target", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Content-Sha256", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Algorithm")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Algorithm", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Signature")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Signature", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-SignedHeaders", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Credential")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Credential", valid_603246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603248: Call_UpdateLicenseSpecificationsForResource_603236;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds or removes license configurations for a specified AWS resource. This operation currently supports updating the license specifications of AMIs, instances, and hosts. Launch templates and AWS CloudFormation templates are not managed from this operation as those resources send the license configurations directly to a resource creation operation, such as <code>RunInstances</code>.
  ## 
  let valid = call_603248.validator(path, query, header, formData, body)
  let scheme = call_603248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603248.url(scheme.get, call_603248.host, call_603248.base,
                         call_603248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603248, url, valid)

proc call*(call_603249: Call_UpdateLicenseSpecificationsForResource_603236;
          body: JsonNode): Recallable =
  ## updateLicenseSpecificationsForResource
  ## Adds or removes license configurations for a specified AWS resource. This operation currently supports updating the license specifications of AMIs, instances, and hosts. Launch templates and AWS CloudFormation templates are not managed from this operation as those resources send the license configurations directly to a resource creation operation, such as <code>RunInstances</code>.
  ##   body: JObject (required)
  var body_603250 = newJObject()
  if body != nil:
    body_603250 = body
  result = call_603249.call(nil, nil, nil, nil, body_603250)

var updateLicenseSpecificationsForResource* = Call_UpdateLicenseSpecificationsForResource_603236(
    name: "updateLicenseSpecificationsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.UpdateLicenseSpecificationsForResource",
    validator: validate_UpdateLicenseSpecificationsForResource_603237, base: "/",
    url: url_UpdateLicenseSpecificationsForResource_603238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSettings_603251 = ref object of OpenApiRestCall_602450
proc url_UpdateServiceSettings_603253(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateServiceSettings_603252(path: JsonNode; query: JsonNode;
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
  var valid_603254 = header.getOrDefault("X-Amz-Date")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Date", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Security-Token")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Security-Token", valid_603255
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603256 = header.getOrDefault("X-Amz-Target")
  valid_603256 = validateParameter(valid_603256, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateServiceSettings"))
  if valid_603256 != nil:
    section.add "X-Amz-Target", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Content-Sha256", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Algorithm")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Algorithm", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Signature")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Signature", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-SignedHeaders", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Credential")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Credential", valid_603261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603263: Call_UpdateServiceSettings_603251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates License Manager service settings.
  ## 
  let valid = call_603263.validator(path, query, header, formData, body)
  let scheme = call_603263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603263.url(scheme.get, call_603263.host, call_603263.base,
                         call_603263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603263, url, valid)

proc call*(call_603264: Call_UpdateServiceSettings_603251; body: JsonNode): Recallable =
  ## updateServiceSettings
  ## Updates License Manager service settings.
  ##   body: JObject (required)
  var body_603265 = newJObject()
  if body != nil:
    body_603265 = body
  result = call_603264.call(nil, nil, nil, nil, body_603265)

var updateServiceSettings* = Call_UpdateServiceSettings_603251(
    name: "updateServiceSettings", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UpdateServiceSettings",
    validator: validate_UpdateServiceSettings_603252, base: "/",
    url: url_UpdateServiceSettings_603253, schemes: {Scheme.Https, Scheme.Http})
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
