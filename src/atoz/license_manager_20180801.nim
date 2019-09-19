
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772581 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772581](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772581): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateLicenseConfiguration_772917 = ref object of OpenApiRestCall_772581
proc url_CreateLicenseConfiguration_772919(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateLicenseConfiguration_772918(path: JsonNode; query: JsonNode;
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
  var valid_773031 = header.getOrDefault("X-Amz-Date")
  valid_773031 = validateParameter(valid_773031, JString, required = false,
                                 default = nil)
  if valid_773031 != nil:
    section.add "X-Amz-Date", valid_773031
  var valid_773032 = header.getOrDefault("X-Amz-Security-Token")
  valid_773032 = validateParameter(valid_773032, JString, required = false,
                                 default = nil)
  if valid_773032 != nil:
    section.add "X-Amz-Security-Token", valid_773032
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773046 = header.getOrDefault("X-Amz-Target")
  valid_773046 = validateParameter(valid_773046, JString, required = true, default = newJString(
      "AWSLicenseManager.CreateLicenseConfiguration"))
  if valid_773046 != nil:
    section.add "X-Amz-Target", valid_773046
  var valid_773047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Content-Sha256", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Algorithm")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Algorithm", valid_773048
  var valid_773049 = header.getOrDefault("X-Amz-Signature")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Signature", valid_773049
  var valid_773050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "X-Amz-SignedHeaders", valid_773050
  var valid_773051 = header.getOrDefault("X-Amz-Credential")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-Credential", valid_773051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773075: Call_CreateLicenseConfiguration_772917; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new license configuration object. A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or VCPU), tenancy (shared tenancy, Amazon EC2 Dedicated Instance, Amazon EC2 Dedicated Host, or any of these), host affinity (how long a VM must be associated with a host), the number of licenses purchased and used.
  ## 
  let valid = call_773075.validator(path, query, header, formData, body)
  let scheme = call_773075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773075.url(scheme.get, call_773075.host, call_773075.base,
                         call_773075.route, valid.getOrDefault("path"))
  result = hook(call_773075, url, valid)

proc call*(call_773146: Call_CreateLicenseConfiguration_772917; body: JsonNode): Recallable =
  ## createLicenseConfiguration
  ## Creates a new license configuration object. A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or VCPU), tenancy (shared tenancy, Amazon EC2 Dedicated Instance, Amazon EC2 Dedicated Host, or any of these), host affinity (how long a VM must be associated with a host), the number of licenses purchased and used.
  ##   body: JObject (required)
  var body_773147 = newJObject()
  if body != nil:
    body_773147 = body
  result = call_773146.call(nil, nil, nil, nil, body_773147)

var createLicenseConfiguration* = Call_CreateLicenseConfiguration_772917(
    name: "createLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.CreateLicenseConfiguration",
    validator: validate_CreateLicenseConfiguration_772918, base: "/",
    url: url_CreateLicenseConfiguration_772919,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLicenseConfiguration_773186 = ref object of OpenApiRestCall_772581
proc url_DeleteLicenseConfiguration_773188(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteLicenseConfiguration_773187(path: JsonNode; query: JsonNode;
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
  var valid_773189 = header.getOrDefault("X-Amz-Date")
  valid_773189 = validateParameter(valid_773189, JString, required = false,
                                 default = nil)
  if valid_773189 != nil:
    section.add "X-Amz-Date", valid_773189
  var valid_773190 = header.getOrDefault("X-Amz-Security-Token")
  valid_773190 = validateParameter(valid_773190, JString, required = false,
                                 default = nil)
  if valid_773190 != nil:
    section.add "X-Amz-Security-Token", valid_773190
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773191 = header.getOrDefault("X-Amz-Target")
  valid_773191 = validateParameter(valid_773191, JString, required = true, default = newJString(
      "AWSLicenseManager.DeleteLicenseConfiguration"))
  if valid_773191 != nil:
    section.add "X-Amz-Target", valid_773191
  var valid_773192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773192 = validateParameter(valid_773192, JString, required = false,
                                 default = nil)
  if valid_773192 != nil:
    section.add "X-Amz-Content-Sha256", valid_773192
  var valid_773193 = header.getOrDefault("X-Amz-Algorithm")
  valid_773193 = validateParameter(valid_773193, JString, required = false,
                                 default = nil)
  if valid_773193 != nil:
    section.add "X-Amz-Algorithm", valid_773193
  var valid_773194 = header.getOrDefault("X-Amz-Signature")
  valid_773194 = validateParameter(valid_773194, JString, required = false,
                                 default = nil)
  if valid_773194 != nil:
    section.add "X-Amz-Signature", valid_773194
  var valid_773195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773195 = validateParameter(valid_773195, JString, required = false,
                                 default = nil)
  if valid_773195 != nil:
    section.add "X-Amz-SignedHeaders", valid_773195
  var valid_773196 = header.getOrDefault("X-Amz-Credential")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-Credential", valid_773196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773198: Call_DeleteLicenseConfiguration_773186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing license configuration. This action fails if the configuration is in use.
  ## 
  let valid = call_773198.validator(path, query, header, formData, body)
  let scheme = call_773198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773198.url(scheme.get, call_773198.host, call_773198.base,
                         call_773198.route, valid.getOrDefault("path"))
  result = hook(call_773198, url, valid)

proc call*(call_773199: Call_DeleteLicenseConfiguration_773186; body: JsonNode): Recallable =
  ## deleteLicenseConfiguration
  ## Deletes an existing license configuration. This action fails if the configuration is in use.
  ##   body: JObject (required)
  var body_773200 = newJObject()
  if body != nil:
    body_773200 = body
  result = call_773199.call(nil, nil, nil, nil, body_773200)

var deleteLicenseConfiguration* = Call_DeleteLicenseConfiguration_773186(
    name: "deleteLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.DeleteLicenseConfiguration",
    validator: validate_DeleteLicenseConfiguration_773187, base: "/",
    url: url_DeleteLicenseConfiguration_773188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLicenseConfiguration_773201 = ref object of OpenApiRestCall_772581
proc url_GetLicenseConfiguration_773203(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetLicenseConfiguration_773202(path: JsonNode; query: JsonNode;
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
  var valid_773204 = header.getOrDefault("X-Amz-Date")
  valid_773204 = validateParameter(valid_773204, JString, required = false,
                                 default = nil)
  if valid_773204 != nil:
    section.add "X-Amz-Date", valid_773204
  var valid_773205 = header.getOrDefault("X-Amz-Security-Token")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Security-Token", valid_773205
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773206 = header.getOrDefault("X-Amz-Target")
  valid_773206 = validateParameter(valid_773206, JString, required = true, default = newJString(
      "AWSLicenseManager.GetLicenseConfiguration"))
  if valid_773206 != nil:
    section.add "X-Amz-Target", valid_773206
  var valid_773207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "X-Amz-Content-Sha256", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Algorithm")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Algorithm", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Signature")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Signature", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-SignedHeaders", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Credential")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Credential", valid_773211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773213: Call_GetLicenseConfiguration_773201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a detailed description of a license configuration.
  ## 
  let valid = call_773213.validator(path, query, header, formData, body)
  let scheme = call_773213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773213.url(scheme.get, call_773213.host, call_773213.base,
                         call_773213.route, valid.getOrDefault("path"))
  result = hook(call_773213, url, valid)

proc call*(call_773214: Call_GetLicenseConfiguration_773201; body: JsonNode): Recallable =
  ## getLicenseConfiguration
  ## Returns a detailed description of a license configuration.
  ##   body: JObject (required)
  var body_773215 = newJObject()
  if body != nil:
    body_773215 = body
  result = call_773214.call(nil, nil, nil, nil, body_773215)

var getLicenseConfiguration* = Call_GetLicenseConfiguration_773201(
    name: "getLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.GetLicenseConfiguration",
    validator: validate_GetLicenseConfiguration_773202, base: "/",
    url: url_GetLicenseConfiguration_773203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSettings_773216 = ref object of OpenApiRestCall_772581
proc url_GetServiceSettings_773218(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetServiceSettings_773217(path: JsonNode; query: JsonNode;
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
  var valid_773219 = header.getOrDefault("X-Amz-Date")
  valid_773219 = validateParameter(valid_773219, JString, required = false,
                                 default = nil)
  if valid_773219 != nil:
    section.add "X-Amz-Date", valid_773219
  var valid_773220 = header.getOrDefault("X-Amz-Security-Token")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Security-Token", valid_773220
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773221 = header.getOrDefault("X-Amz-Target")
  valid_773221 = validateParameter(valid_773221, JString, required = true, default = newJString(
      "AWSLicenseManager.GetServiceSettings"))
  if valid_773221 != nil:
    section.add "X-Amz-Target", valid_773221
  var valid_773222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "X-Amz-Content-Sha256", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Algorithm")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Algorithm", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Signature")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Signature", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-SignedHeaders", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-Credential")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Credential", valid_773226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773228: Call_GetServiceSettings_773216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets License Manager settings for a region. Exposes the configured S3 bucket, SNS topic, etc., for inspection. 
  ## 
  let valid = call_773228.validator(path, query, header, formData, body)
  let scheme = call_773228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773228.url(scheme.get, call_773228.host, call_773228.base,
                         call_773228.route, valid.getOrDefault("path"))
  result = hook(call_773228, url, valid)

proc call*(call_773229: Call_GetServiceSettings_773216; body: JsonNode): Recallable =
  ## getServiceSettings
  ## Gets License Manager settings for a region. Exposes the configured S3 bucket, SNS topic, etc., for inspection. 
  ##   body: JObject (required)
  var body_773230 = newJObject()
  if body != nil:
    body_773230 = body
  result = call_773229.call(nil, nil, nil, nil, body_773230)

var getServiceSettings* = Call_GetServiceSettings_773216(
    name: "getServiceSettings", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.GetServiceSettings",
    validator: validate_GetServiceSettings_773217, base: "/",
    url: url_GetServiceSettings_773218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationsForLicenseConfiguration_773231 = ref object of OpenApiRestCall_772581
proc url_ListAssociationsForLicenseConfiguration_773233(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssociationsForLicenseConfiguration_773232(path: JsonNode;
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
  var valid_773234 = header.getOrDefault("X-Amz-Date")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Date", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-Security-Token")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Security-Token", valid_773235
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773236 = header.getOrDefault("X-Amz-Target")
  valid_773236 = validateParameter(valid_773236, JString, required = true, default = newJString(
      "AWSLicenseManager.ListAssociationsForLicenseConfiguration"))
  if valid_773236 != nil:
    section.add "X-Amz-Target", valid_773236
  var valid_773237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Content-Sha256", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Algorithm")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Algorithm", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Signature")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Signature", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-SignedHeaders", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-Credential")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Credential", valid_773241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773243: Call_ListAssociationsForLicenseConfiguration_773231;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the resource associations for a license configuration. Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance may not consume a license (depending on the license rules). Use this operation to find all resources associated with a license configuration.
  ## 
  let valid = call_773243.validator(path, query, header, formData, body)
  let scheme = call_773243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773243.url(scheme.get, call_773243.host, call_773243.base,
                         call_773243.route, valid.getOrDefault("path"))
  result = hook(call_773243, url, valid)

proc call*(call_773244: Call_ListAssociationsForLicenseConfiguration_773231;
          body: JsonNode): Recallable =
  ## listAssociationsForLicenseConfiguration
  ## Lists the resource associations for a license configuration. Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance may not consume a license (depending on the license rules). Use this operation to find all resources associated with a license configuration.
  ##   body: JObject (required)
  var body_773245 = newJObject()
  if body != nil:
    body_773245 = body
  result = call_773244.call(nil, nil, nil, nil, body_773245)

var listAssociationsForLicenseConfiguration* = Call_ListAssociationsForLicenseConfiguration_773231(
    name: "listAssociationsForLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.ListAssociationsForLicenseConfiguration",
    validator: validate_ListAssociationsForLicenseConfiguration_773232, base: "/",
    url: url_ListAssociationsForLicenseConfiguration_773233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLicenseConfigurations_773246 = ref object of OpenApiRestCall_772581
proc url_ListLicenseConfigurations_773248(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListLicenseConfigurations_773247(path: JsonNode; query: JsonNode;
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
  var valid_773249 = header.getOrDefault("X-Amz-Date")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Date", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-Security-Token")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Security-Token", valid_773250
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773251 = header.getOrDefault("X-Amz-Target")
  valid_773251 = validateParameter(valid_773251, JString, required = true, default = newJString(
      "AWSLicenseManager.ListLicenseConfigurations"))
  if valid_773251 != nil:
    section.add "X-Amz-Target", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-Content-Sha256", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Algorithm")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Algorithm", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Signature")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Signature", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-SignedHeaders", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Credential")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Credential", valid_773256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773258: Call_ListLicenseConfigurations_773246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists license configuration objects for an account, each containing the name, description, license type, and other license terms modeled from a license agreement.
  ## 
  let valid = call_773258.validator(path, query, header, formData, body)
  let scheme = call_773258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773258.url(scheme.get, call_773258.host, call_773258.base,
                         call_773258.route, valid.getOrDefault("path"))
  result = hook(call_773258, url, valid)

proc call*(call_773259: Call_ListLicenseConfigurations_773246; body: JsonNode): Recallable =
  ## listLicenseConfigurations
  ## Lists license configuration objects for an account, each containing the name, description, license type, and other license terms modeled from a license agreement.
  ##   body: JObject (required)
  var body_773260 = newJObject()
  if body != nil:
    body_773260 = body
  result = call_773259.call(nil, nil, nil, nil, body_773260)

var listLicenseConfigurations* = Call_ListLicenseConfigurations_773246(
    name: "listLicenseConfigurations", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListLicenseConfigurations",
    validator: validate_ListLicenseConfigurations_773247, base: "/",
    url: url_ListLicenseConfigurations_773248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLicenseSpecificationsForResource_773261 = ref object of OpenApiRestCall_772581
proc url_ListLicenseSpecificationsForResource_773263(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListLicenseSpecificationsForResource_773262(path: JsonNode;
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
  var valid_773264 = header.getOrDefault("X-Amz-Date")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "X-Amz-Date", valid_773264
  var valid_773265 = header.getOrDefault("X-Amz-Security-Token")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Security-Token", valid_773265
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773266 = header.getOrDefault("X-Amz-Target")
  valid_773266 = validateParameter(valid_773266, JString, required = true, default = newJString(
      "AWSLicenseManager.ListLicenseSpecificationsForResource"))
  if valid_773266 != nil:
    section.add "X-Amz-Target", valid_773266
  var valid_773267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Content-Sha256", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Algorithm")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Algorithm", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Signature")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Signature", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-SignedHeaders", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Credential")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Credential", valid_773271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773273: Call_ListLicenseSpecificationsForResource_773261;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the license configuration for a resource.
  ## 
  let valid = call_773273.validator(path, query, header, formData, body)
  let scheme = call_773273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773273.url(scheme.get, call_773273.host, call_773273.base,
                         call_773273.route, valid.getOrDefault("path"))
  result = hook(call_773273, url, valid)

proc call*(call_773274: Call_ListLicenseSpecificationsForResource_773261;
          body: JsonNode): Recallable =
  ## listLicenseSpecificationsForResource
  ## Returns the license configuration for a resource.
  ##   body: JObject (required)
  var body_773275 = newJObject()
  if body != nil:
    body_773275 = body
  result = call_773274.call(nil, nil, nil, nil, body_773275)

var listLicenseSpecificationsForResource* = Call_ListLicenseSpecificationsForResource_773261(
    name: "listLicenseSpecificationsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.ListLicenseSpecificationsForResource",
    validator: validate_ListLicenseSpecificationsForResource_773262, base: "/",
    url: url_ListLicenseSpecificationsForResource_773263,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceInventory_773276 = ref object of OpenApiRestCall_772581
proc url_ListResourceInventory_773278(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListResourceInventory_773277(path: JsonNode; query: JsonNode;
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
  var valid_773279 = header.getOrDefault("X-Amz-Date")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "X-Amz-Date", valid_773279
  var valid_773280 = header.getOrDefault("X-Amz-Security-Token")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Security-Token", valid_773280
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773281 = header.getOrDefault("X-Amz-Target")
  valid_773281 = validateParameter(valid_773281, JString, required = true, default = newJString(
      "AWSLicenseManager.ListResourceInventory"))
  if valid_773281 != nil:
    section.add "X-Amz-Target", valid_773281
  var valid_773282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-Content-Sha256", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Algorithm")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Algorithm", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Signature")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Signature", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-SignedHeaders", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Credential")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Credential", valid_773286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773288: Call_ListResourceInventory_773276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a detailed list of resources.
  ## 
  let valid = call_773288.validator(path, query, header, formData, body)
  let scheme = call_773288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773288.url(scheme.get, call_773288.host, call_773288.base,
                         call_773288.route, valid.getOrDefault("path"))
  result = hook(call_773288, url, valid)

proc call*(call_773289: Call_ListResourceInventory_773276; body: JsonNode): Recallable =
  ## listResourceInventory
  ## Returns a detailed list of resources.
  ##   body: JObject (required)
  var body_773290 = newJObject()
  if body != nil:
    body_773290 = body
  result = call_773289.call(nil, nil, nil, nil, body_773290)

var listResourceInventory* = Call_ListResourceInventory_773276(
    name: "listResourceInventory", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListResourceInventory",
    validator: validate_ListResourceInventory_773277, base: "/",
    url: url_ListResourceInventory_773278, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_773291 = ref object of OpenApiRestCall_772581
proc url_ListTagsForResource_773293(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_773292(path: JsonNode; query: JsonNode;
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
  var valid_773294 = header.getOrDefault("X-Amz-Date")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-Date", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-Security-Token")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Security-Token", valid_773295
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773296 = header.getOrDefault("X-Amz-Target")
  valid_773296 = validateParameter(valid_773296, JString, required = true, default = newJString(
      "AWSLicenseManager.ListTagsForResource"))
  if valid_773296 != nil:
    section.add "X-Amz-Target", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-Content-Sha256", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Algorithm")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Algorithm", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Signature")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Signature", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-SignedHeaders", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-Credential")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-Credential", valid_773301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773303: Call_ListTagsForResource_773291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists tags attached to a resource.
  ## 
  let valid = call_773303.validator(path, query, header, formData, body)
  let scheme = call_773303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773303.url(scheme.get, call_773303.host, call_773303.base,
                         call_773303.route, valid.getOrDefault("path"))
  result = hook(call_773303, url, valid)

proc call*(call_773304: Call_ListTagsForResource_773291; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists tags attached to a resource.
  ##   body: JObject (required)
  var body_773305 = newJObject()
  if body != nil:
    body_773305 = body
  result = call_773304.call(nil, nil, nil, nil, body_773305)

var listTagsForResource* = Call_ListTagsForResource_773291(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListTagsForResource",
    validator: validate_ListTagsForResource_773292, base: "/",
    url: url_ListTagsForResource_773293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsageForLicenseConfiguration_773306 = ref object of OpenApiRestCall_772581
proc url_ListUsageForLicenseConfiguration_773308(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListUsageForLicenseConfiguration_773307(path: JsonNode;
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
  var valid_773309 = header.getOrDefault("X-Amz-Date")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Date", valid_773309
  var valid_773310 = header.getOrDefault("X-Amz-Security-Token")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Security-Token", valid_773310
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773311 = header.getOrDefault("X-Amz-Target")
  valid_773311 = validateParameter(valid_773311, JString, required = true, default = newJString(
      "AWSLicenseManager.ListUsageForLicenseConfiguration"))
  if valid_773311 != nil:
    section.add "X-Amz-Target", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-Content-Sha256", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Algorithm")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Algorithm", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Signature")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Signature", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-SignedHeaders", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-Credential")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-Credential", valid_773316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773318: Call_ListUsageForLicenseConfiguration_773306;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all license usage records for a license configuration, displaying license consumption details by resource at a selected point in time. Use this action to audit the current license consumption for any license inventory and configuration.
  ## 
  let valid = call_773318.validator(path, query, header, formData, body)
  let scheme = call_773318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773318.url(scheme.get, call_773318.host, call_773318.base,
                         call_773318.route, valid.getOrDefault("path"))
  result = hook(call_773318, url, valid)

proc call*(call_773319: Call_ListUsageForLicenseConfiguration_773306;
          body: JsonNode): Recallable =
  ## listUsageForLicenseConfiguration
  ## Lists all license usage records for a license configuration, displaying license consumption details by resource at a selected point in time. Use this action to audit the current license consumption for any license inventory and configuration.
  ##   body: JObject (required)
  var body_773320 = newJObject()
  if body != nil:
    body_773320 = body
  result = call_773319.call(nil, nil, nil, nil, body_773320)

var listUsageForLicenseConfiguration* = Call_ListUsageForLicenseConfiguration_773306(
    name: "listUsageForLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.ListUsageForLicenseConfiguration",
    validator: validate_ListUsageForLicenseConfiguration_773307, base: "/",
    url: url_ListUsageForLicenseConfiguration_773308,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_773321 = ref object of OpenApiRestCall_772581
proc url_TagResource_773323(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_773322(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773324 = header.getOrDefault("X-Amz-Date")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-Date", valid_773324
  var valid_773325 = header.getOrDefault("X-Amz-Security-Token")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Security-Token", valid_773325
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773326 = header.getOrDefault("X-Amz-Target")
  valid_773326 = validateParameter(valid_773326, JString, required = true, default = newJString(
      "AWSLicenseManager.TagResource"))
  if valid_773326 != nil:
    section.add "X-Amz-Target", valid_773326
  var valid_773327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-Content-Sha256", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Algorithm")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Algorithm", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Signature")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Signature", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-SignedHeaders", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-Credential")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-Credential", valid_773331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773333: Call_TagResource_773321; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attach one of more tags to any resource.
  ## 
  let valid = call_773333.validator(path, query, header, formData, body)
  let scheme = call_773333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773333.url(scheme.get, call_773333.host, call_773333.base,
                         call_773333.route, valid.getOrDefault("path"))
  result = hook(call_773333, url, valid)

proc call*(call_773334: Call_TagResource_773321; body: JsonNode): Recallable =
  ## tagResource
  ## Attach one of more tags to any resource.
  ##   body: JObject (required)
  var body_773335 = newJObject()
  if body != nil:
    body_773335 = body
  result = call_773334.call(nil, nil, nil, nil, body_773335)

var tagResource* = Call_TagResource_773321(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.TagResource",
                                        validator: validate_TagResource_773322,
                                        base: "/", url: url_TagResource_773323,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_773336 = ref object of OpenApiRestCall_772581
proc url_UntagResource_773338(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_773337(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773339 = header.getOrDefault("X-Amz-Date")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = nil)
  if valid_773339 != nil:
    section.add "X-Amz-Date", valid_773339
  var valid_773340 = header.getOrDefault("X-Amz-Security-Token")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Security-Token", valid_773340
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773341 = header.getOrDefault("X-Amz-Target")
  valid_773341 = validateParameter(valid_773341, JString, required = true, default = newJString(
      "AWSLicenseManager.UntagResource"))
  if valid_773341 != nil:
    section.add "X-Amz-Target", valid_773341
  var valid_773342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "X-Amz-Content-Sha256", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Algorithm")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Algorithm", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Signature")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Signature", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-SignedHeaders", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-Credential")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Credential", valid_773346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773348: Call_UntagResource_773336; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a resource.
  ## 
  let valid = call_773348.validator(path, query, header, formData, body)
  let scheme = call_773348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773348.url(scheme.get, call_773348.host, call_773348.base,
                         call_773348.route, valid.getOrDefault("path"))
  result = hook(call_773348, url, valid)

proc call*(call_773349: Call_UntagResource_773336; body: JsonNode): Recallable =
  ## untagResource
  ## Remove tags from a resource.
  ##   body: JObject (required)
  var body_773350 = newJObject()
  if body != nil:
    body_773350 = body
  result = call_773349.call(nil, nil, nil, nil, body_773350)

var untagResource* = Call_UntagResource_773336(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UntagResource",
    validator: validate_UntagResource_773337, base: "/", url: url_UntagResource_773338,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLicenseConfiguration_773351 = ref object of OpenApiRestCall_772581
proc url_UpdateLicenseConfiguration_773353(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateLicenseConfiguration_773352(path: JsonNode; query: JsonNode;
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
  var valid_773354 = header.getOrDefault("X-Amz-Date")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-Date", valid_773354
  var valid_773355 = header.getOrDefault("X-Amz-Security-Token")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Security-Token", valid_773355
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773356 = header.getOrDefault("X-Amz-Target")
  valid_773356 = validateParameter(valid_773356, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateLicenseConfiguration"))
  if valid_773356 != nil:
    section.add "X-Amz-Target", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Content-Sha256", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Algorithm")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Algorithm", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Signature")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Signature", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-SignedHeaders", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Credential")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Credential", valid_773361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773363: Call_UpdateLicenseConfiguration_773351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the attributes of an existing license configuration object. A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (Instances, cores, sockets, VCPUs), tenancy (shared or Dedicated Host), host affinity (how long a VM is associated with a host), the number of licenses purchased and used.
  ## 
  let valid = call_773363.validator(path, query, header, formData, body)
  let scheme = call_773363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773363.url(scheme.get, call_773363.host, call_773363.base,
                         call_773363.route, valid.getOrDefault("path"))
  result = hook(call_773363, url, valid)

proc call*(call_773364: Call_UpdateLicenseConfiguration_773351; body: JsonNode): Recallable =
  ## updateLicenseConfiguration
  ## Modifies the attributes of an existing license configuration object. A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (Instances, cores, sockets, VCPUs), tenancy (shared or Dedicated Host), host affinity (how long a VM is associated with a host), the number of licenses purchased and used.
  ##   body: JObject (required)
  var body_773365 = newJObject()
  if body != nil:
    body_773365 = body
  result = call_773364.call(nil, nil, nil, nil, body_773365)

var updateLicenseConfiguration* = Call_UpdateLicenseConfiguration_773351(
    name: "updateLicenseConfiguration", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UpdateLicenseConfiguration",
    validator: validate_UpdateLicenseConfiguration_773352, base: "/",
    url: url_UpdateLicenseConfiguration_773353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLicenseSpecificationsForResource_773366 = ref object of OpenApiRestCall_772581
proc url_UpdateLicenseSpecificationsForResource_773368(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateLicenseSpecificationsForResource_773367(path: JsonNode;
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
  var valid_773369 = header.getOrDefault("X-Amz-Date")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Date", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-Security-Token")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Security-Token", valid_773370
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773371 = header.getOrDefault("X-Amz-Target")
  valid_773371 = validateParameter(valid_773371, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateLicenseSpecificationsForResource"))
  if valid_773371 != nil:
    section.add "X-Amz-Target", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Content-Sha256", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Algorithm")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Algorithm", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Signature")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Signature", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-SignedHeaders", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-Credential")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-Credential", valid_773376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773378: Call_UpdateLicenseSpecificationsForResource_773366;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds or removes license configurations for a specified AWS resource. This operation currently supports updating the license specifications of AMIs, instances, and hosts. Launch templates and AWS CloudFormation templates are not managed from this operation as those resources send the license configurations directly to a resource creation operation, such as <code>RunInstances</code>.
  ## 
  let valid = call_773378.validator(path, query, header, formData, body)
  let scheme = call_773378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773378.url(scheme.get, call_773378.host, call_773378.base,
                         call_773378.route, valid.getOrDefault("path"))
  result = hook(call_773378, url, valid)

proc call*(call_773379: Call_UpdateLicenseSpecificationsForResource_773366;
          body: JsonNode): Recallable =
  ## updateLicenseSpecificationsForResource
  ## Adds or removes license configurations for a specified AWS resource. This operation currently supports updating the license specifications of AMIs, instances, and hosts. Launch templates and AWS CloudFormation templates are not managed from this operation as those resources send the license configurations directly to a resource creation operation, such as <code>RunInstances</code>.
  ##   body: JObject (required)
  var body_773380 = newJObject()
  if body != nil:
    body_773380 = body
  result = call_773379.call(nil, nil, nil, nil, body_773380)

var updateLicenseSpecificationsForResource* = Call_UpdateLicenseSpecificationsForResource_773366(
    name: "updateLicenseSpecificationsForResource", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com", route: "/#X-Amz-Target=AWSLicenseManager.UpdateLicenseSpecificationsForResource",
    validator: validate_UpdateLicenseSpecificationsForResource_773367, base: "/",
    url: url_UpdateLicenseSpecificationsForResource_773368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSettings_773381 = ref object of OpenApiRestCall_772581
proc url_UpdateServiceSettings_773383(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateServiceSettings_773382(path: JsonNode; query: JsonNode;
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
  var valid_773384 = header.getOrDefault("X-Amz-Date")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "X-Amz-Date", valid_773384
  var valid_773385 = header.getOrDefault("X-Amz-Security-Token")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Security-Token", valid_773385
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773386 = header.getOrDefault("X-Amz-Target")
  valid_773386 = validateParameter(valid_773386, JString, required = true, default = newJString(
      "AWSLicenseManager.UpdateServiceSettings"))
  if valid_773386 != nil:
    section.add "X-Amz-Target", valid_773386
  var valid_773387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-Content-Sha256", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Algorithm")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Algorithm", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Signature")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Signature", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-SignedHeaders", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-Credential")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-Credential", valid_773391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773393: Call_UpdateServiceSettings_773381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates License Manager service settings.
  ## 
  let valid = call_773393.validator(path, query, header, formData, body)
  let scheme = call_773393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773393.url(scheme.get, call_773393.host, call_773393.base,
                         call_773393.route, valid.getOrDefault("path"))
  result = hook(call_773393, url, valid)

proc call*(call_773394: Call_UpdateServiceSettings_773381; body: JsonNode): Recallable =
  ## updateServiceSettings
  ## Updates License Manager service settings.
  ##   body: JObject (required)
  var body_773395 = newJObject()
  if body != nil:
    body_773395 = body
  result = call_773394.call(nil, nil, nil, nil, body_773395)

var updateServiceSettings* = Call_UpdateServiceSettings_773381(
    name: "updateServiceSettings", meth: HttpMethod.HttpPost,
    host: "license-manager.amazonaws.com",
    route: "/#X-Amz-Target=AWSLicenseManager.UpdateServiceSettings",
    validator: validate_UpdateServiceSettings_773382, base: "/",
    url: url_UpdateServiceSettings_773383, schemes: {Scheme.Https, Scheme.Http})
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
