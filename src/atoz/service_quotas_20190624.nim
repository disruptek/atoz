
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Service Quotas
## version: 2019-06-24
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p> Service Quotas is a web service that you can use to manage many of your AWS service quotas. Quotas, also referred to as limits, are the maximum values for a resource, item, or operation. This guide provide descriptions of the Service Quotas actions that you can call from an API. For the Service Quotas user guide, which explains how to use Service Quotas from the console, see <a href="https://docs.aws.amazon.com/servicequotas/latest/userguide/intro.html">What is Service Quotas</a>. </p> <note> <p>AWS provides SDKs that consist of libraries and sample code for programming languages and platforms (Java, Ruby, .NET, iOS, Android, etc...,). The SDKs provide a convenient way to create programmatic access to Service Quotas and AWS. For information about the AWS SDKs, including how to download and install them, see the <a href="https://docs.aws.amazon.com/aws.amazon.com/tools">Tools for Amazon Web Services</a> page.</p> </note>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/servicequotas/
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

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "servicequotas.ap-northeast-1.amazonaws.com", "ap-southeast-1": "servicequotas.ap-southeast-1.amazonaws.com", "us-west-2": "servicequotas.us-west-2.amazonaws.com", "eu-west-2": "servicequotas.eu-west-2.amazonaws.com", "ap-northeast-3": "servicequotas.ap-northeast-3.amazonaws.com", "eu-central-1": "servicequotas.eu-central-1.amazonaws.com", "us-east-2": "servicequotas.us-east-2.amazonaws.com", "us-east-1": "servicequotas.us-east-1.amazonaws.com", "cn-northwest-1": "servicequotas.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "servicequotas.ap-south-1.amazonaws.com", "eu-north-1": "servicequotas.eu-north-1.amazonaws.com", "ap-northeast-2": "servicequotas.ap-northeast-2.amazonaws.com", "us-west-1": "servicequotas.us-west-1.amazonaws.com", "us-gov-east-1": "servicequotas.us-gov-east-1.amazonaws.com", "eu-west-3": "servicequotas.eu-west-3.amazonaws.com", "cn-north-1": "servicequotas.cn-north-1.amazonaws.com.cn", "sa-east-1": "servicequotas.sa-east-1.amazonaws.com", "eu-west-1": "servicequotas.eu-west-1.amazonaws.com", "us-gov-west-1": "servicequotas.us-gov-west-1.amazonaws.com", "ap-southeast-2": "servicequotas.ap-southeast-2.amazonaws.com", "ca-central-1": "servicequotas.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "servicequotas.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "servicequotas.ap-southeast-1.amazonaws.com",
      "us-west-2": "servicequotas.us-west-2.amazonaws.com",
      "eu-west-2": "servicequotas.eu-west-2.amazonaws.com",
      "ap-northeast-3": "servicequotas.ap-northeast-3.amazonaws.com",
      "eu-central-1": "servicequotas.eu-central-1.amazonaws.com",
      "us-east-2": "servicequotas.us-east-2.amazonaws.com",
      "us-east-1": "servicequotas.us-east-1.amazonaws.com",
      "cn-northwest-1": "servicequotas.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "servicequotas.ap-south-1.amazonaws.com",
      "eu-north-1": "servicequotas.eu-north-1.amazonaws.com",
      "ap-northeast-2": "servicequotas.ap-northeast-2.amazonaws.com",
      "us-west-1": "servicequotas.us-west-1.amazonaws.com",
      "us-gov-east-1": "servicequotas.us-gov-east-1.amazonaws.com",
      "eu-west-3": "servicequotas.eu-west-3.amazonaws.com",
      "cn-north-1": "servicequotas.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "servicequotas.sa-east-1.amazonaws.com",
      "eu-west-1": "servicequotas.eu-west-1.amazonaws.com",
      "us-gov-west-1": "servicequotas.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "servicequotas.ap-southeast-2.amazonaws.com",
      "ca-central-1": "servicequotas.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "service-quotas"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AssociateServiceQuotaTemplate_600768 = ref object of OpenApiRestCall_600426
proc url_AssociateServiceQuotaTemplate_600770(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateServiceQuotaTemplate_600769(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates the Service Quotas template with your organization so that when new accounts are created in your organization, the template submits increase requests for the specified service quotas. Use the Service Quotas template to request an increase for any adjustable quota value. After you define the Service Quotas template, use this operation to associate, or enable, the template. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.AssociateServiceQuotaTemplate"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_AssociateServiceQuotaTemplate_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the Service Quotas template with your organization so that when new accounts are created in your organization, the template submits increase requests for the specified service quotas. Use the Service Quotas template to request an increase for any adjustable quota value. After you define the Service Quotas template, use this operation to associate, or enable, the template. 
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_AssociateServiceQuotaTemplate_600768; body: JsonNode): Recallable =
  ## associateServiceQuotaTemplate
  ## Associates the Service Quotas template with your organization so that when new accounts are created in your organization, the template submits increase requests for the specified service quotas. Use the Service Quotas template to request an increase for any adjustable quota value. After you define the Service Quotas template, use this operation to associate, or enable, the template. 
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var associateServiceQuotaTemplate* = Call_AssociateServiceQuotaTemplate_600768(
    name: "associateServiceQuotaTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.AssociateServiceQuotaTemplate",
    validator: validate_AssociateServiceQuotaTemplate_600769, base: "/",
    url: url_AssociateServiceQuotaTemplate_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceQuotaIncreaseRequestFromTemplate_601037 = ref object of OpenApiRestCall_600426
proc url_DeleteServiceQuotaIncreaseRequestFromTemplate_601039(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteServiceQuotaIncreaseRequestFromTemplate_601038(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Removes a service quota increase request from the Service Quotas template. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.DeleteServiceQuotaIncreaseRequestFromTemplate"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_DeleteServiceQuotaIncreaseRequestFromTemplate_601037;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a service quota increase request from the Service Quotas template. 
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_DeleteServiceQuotaIncreaseRequestFromTemplate_601037;
          body: JsonNode): Recallable =
  ## deleteServiceQuotaIncreaseRequestFromTemplate
  ## Removes a service quota increase request from the Service Quotas template. 
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var deleteServiceQuotaIncreaseRequestFromTemplate* = Call_DeleteServiceQuotaIncreaseRequestFromTemplate_601037(
    name: "deleteServiceQuotaIncreaseRequestFromTemplate",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.DeleteServiceQuotaIncreaseRequestFromTemplate",
    validator: validate_DeleteServiceQuotaIncreaseRequestFromTemplate_601038,
    base: "/", url: url_DeleteServiceQuotaIncreaseRequestFromTemplate_601039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceQuotaTemplate_601052 = ref object of OpenApiRestCall_600426
proc url_DisassociateServiceQuotaTemplate_601054(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateServiceQuotaTemplate_601053(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Disables the Service Quotas template. Once the template is disabled, it does not request quota increases for new accounts in your organization. Disabling the quota template does not apply the quota increase requests from the template. </p> <p> <b>Related operations</b> </p> <ul> <li> <p>To enable the quota template, call <a>AssociateServiceQuotaTemplate</a>. </p> </li> <li> <p>To delete a specific service quota from the template, use <a>DeleteServiceQuotaIncreaseRequestFromTemplate</a>.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.DisassociateServiceQuotaTemplate"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_DisassociateServiceQuotaTemplate_601052;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Disables the Service Quotas template. Once the template is disabled, it does not request quota increases for new accounts in your organization. Disabling the quota template does not apply the quota increase requests from the template. </p> <p> <b>Related operations</b> </p> <ul> <li> <p>To enable the quota template, call <a>AssociateServiceQuotaTemplate</a>. </p> </li> <li> <p>To delete a specific service quota from the template, use <a>DeleteServiceQuotaIncreaseRequestFromTemplate</a>.</p> </li> </ul>
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_DisassociateServiceQuotaTemplate_601052;
          body: JsonNode): Recallable =
  ## disassociateServiceQuotaTemplate
  ## <p>Disables the Service Quotas template. Once the template is disabled, it does not request quota increases for new accounts in your organization. Disabling the quota template does not apply the quota increase requests from the template. </p> <p> <b>Related operations</b> </p> <ul> <li> <p>To enable the quota template, call <a>AssociateServiceQuotaTemplate</a>. </p> </li> <li> <p>To delete a specific service quota from the template, use <a>DeleteServiceQuotaIncreaseRequestFromTemplate</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var disassociateServiceQuotaTemplate* = Call_DisassociateServiceQuotaTemplate_601052(
    name: "disassociateServiceQuotaTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.DisassociateServiceQuotaTemplate",
    validator: validate_DisassociateServiceQuotaTemplate_601053, base: "/",
    url: url_DisassociateServiceQuotaTemplate_601054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAWSDefaultServiceQuota_601067 = ref object of OpenApiRestCall_600426
proc url_GetAWSDefaultServiceQuota_601069(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAWSDefaultServiceQuota_601068(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the default service quotas values. The Value returned for each quota is the AWS default value, even if the quotas have been increased.. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetAWSDefaultServiceQuota"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_GetAWSDefaultServiceQuota_601067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the default service quotas values. The Value returned for each quota is the AWS default value, even if the quotas have been increased.. 
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_GetAWSDefaultServiceQuota_601067; body: JsonNode): Recallable =
  ## getAWSDefaultServiceQuota
  ## Retrieves the default service quotas values. The Value returned for each quota is the AWS default value, even if the quotas have been increased.. 
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var getAWSDefaultServiceQuota* = Call_GetAWSDefaultServiceQuota_601067(
    name: "getAWSDefaultServiceQuota", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.GetAWSDefaultServiceQuota",
    validator: validate_GetAWSDefaultServiceQuota_601068, base: "/",
    url: url_GetAWSDefaultServiceQuota_601069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssociationForServiceQuotaTemplate_601082 = ref object of OpenApiRestCall_600426
proc url_GetAssociationForServiceQuotaTemplate_601084(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAssociationForServiceQuotaTemplate_601083(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the <code>ServiceQuotaTemplateAssociationStatus</code> value from the service. Use this action to determine if the Service Quota template is associated, or enabled. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601087 = header.getOrDefault("X-Amz-Target")
  valid_601087 = validateParameter(valid_601087, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetAssociationForServiceQuotaTemplate"))
  if valid_601087 != nil:
    section.add "X-Amz-Target", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_GetAssociationForServiceQuotaTemplate_601082;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the <code>ServiceQuotaTemplateAssociationStatus</code> value from the service. Use this action to determine if the Service Quota template is associated, or enabled. 
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_GetAssociationForServiceQuotaTemplate_601082;
          body: JsonNode): Recallable =
  ## getAssociationForServiceQuotaTemplate
  ## Retrieves the <code>ServiceQuotaTemplateAssociationStatus</code> value from the service. Use this action to determine if the Service Quota template is associated, or enabled. 
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var getAssociationForServiceQuotaTemplate* = Call_GetAssociationForServiceQuotaTemplate_601082(
    name: "getAssociationForServiceQuotaTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.GetAssociationForServiceQuotaTemplate",
    validator: validate_GetAssociationForServiceQuotaTemplate_601083, base: "/",
    url: url_GetAssociationForServiceQuotaTemplate_601084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestedServiceQuotaChange_601097 = ref object of OpenApiRestCall_600426
proc url_GetRequestedServiceQuotaChange_601099(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRequestedServiceQuotaChange_601098(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the details for a particular increase request. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601102 = header.getOrDefault("X-Amz-Target")
  valid_601102 = validateParameter(valid_601102, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetRequestedServiceQuotaChange"))
  if valid_601102 != nil:
    section.add "X-Amz-Target", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Content-Sha256", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Algorithm")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Algorithm", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Signature")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Signature", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-SignedHeaders", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Credential")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Credential", valid_601107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_GetRequestedServiceQuotaChange_601097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details for a particular increase request. 
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_GetRequestedServiceQuotaChange_601097; body: JsonNode): Recallable =
  ## getRequestedServiceQuotaChange
  ## Retrieves the details for a particular increase request. 
  ##   body: JObject (required)
  var body_601111 = newJObject()
  if body != nil:
    body_601111 = body
  result = call_601110.call(nil, nil, nil, nil, body_601111)

var getRequestedServiceQuotaChange* = Call_GetRequestedServiceQuotaChange_601097(
    name: "getRequestedServiceQuotaChange", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.GetRequestedServiceQuotaChange",
    validator: validate_GetRequestedServiceQuotaChange_601098, base: "/",
    url: url_GetRequestedServiceQuotaChange_601099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceQuota_601112 = ref object of OpenApiRestCall_600426
proc url_GetServiceQuota_601114(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetServiceQuota_601113(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns the details for the specified service quota. This operation provides a different Value than the <code>GetAWSDefaultServiceQuota</code> operation. This operation returns the applied value for each quota. <code>GetAWSDefaultServiceQuota</code> returns the default AWS value for each quota. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601115 = header.getOrDefault("X-Amz-Date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Date", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Security-Token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Security-Token", valid_601116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601117 = header.getOrDefault("X-Amz-Target")
  valid_601117 = validateParameter(valid_601117, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetServiceQuota"))
  if valid_601117 != nil:
    section.add "X-Amz-Target", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Content-Sha256", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Algorithm")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Algorithm", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Signature")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Signature", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-SignedHeaders", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Credential")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Credential", valid_601122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_GetServiceQuota_601112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details for the specified service quota. This operation provides a different Value than the <code>GetAWSDefaultServiceQuota</code> operation. This operation returns the applied value for each quota. <code>GetAWSDefaultServiceQuota</code> returns the default AWS value for each quota. 
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_GetServiceQuota_601112; body: JsonNode): Recallable =
  ## getServiceQuota
  ## Returns the details for the specified service quota. This operation provides a different Value than the <code>GetAWSDefaultServiceQuota</code> operation. This operation returns the applied value for each quota. <code>GetAWSDefaultServiceQuota</code> returns the default AWS value for each quota. 
  ##   body: JObject (required)
  var body_601126 = newJObject()
  if body != nil:
    body_601126 = body
  result = call_601125.call(nil, nil, nil, nil, body_601126)

var getServiceQuota* = Call_GetServiceQuota_601112(name: "getServiceQuota",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.GetServiceQuota",
    validator: validate_GetServiceQuota_601113, base: "/", url: url_GetServiceQuota_601114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceQuotaIncreaseRequestFromTemplate_601127 = ref object of OpenApiRestCall_600426
proc url_GetServiceQuotaIncreaseRequestFromTemplate_601129(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetServiceQuotaIncreaseRequestFromTemplate_601128(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the details of the service quota increase request in your template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601132 = header.getOrDefault("X-Amz-Target")
  valid_601132 = validateParameter(valid_601132, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetServiceQuotaIncreaseRequestFromTemplate"))
  if valid_601132 != nil:
    section.add "X-Amz-Target", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Content-Sha256", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Algorithm")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Algorithm", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Signature")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Signature", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-SignedHeaders", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Credential")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Credential", valid_601137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_GetServiceQuotaIncreaseRequestFromTemplate_601127;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the details of the service quota increase request in your template.
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_GetServiceQuotaIncreaseRequestFromTemplate_601127;
          body: JsonNode): Recallable =
  ## getServiceQuotaIncreaseRequestFromTemplate
  ## Returns the details of the service quota increase request in your template.
  ##   body: JObject (required)
  var body_601141 = newJObject()
  if body != nil:
    body_601141 = body
  result = call_601140.call(nil, nil, nil, nil, body_601141)

var getServiceQuotaIncreaseRequestFromTemplate* = Call_GetServiceQuotaIncreaseRequestFromTemplate_601127(
    name: "getServiceQuotaIncreaseRequestFromTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.GetServiceQuotaIncreaseRequestFromTemplate",
    validator: validate_GetServiceQuotaIncreaseRequestFromTemplate_601128,
    base: "/", url: url_GetServiceQuotaIncreaseRequestFromTemplate_601129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAWSDefaultServiceQuotas_601142 = ref object of OpenApiRestCall_600426
proc url_ListAWSDefaultServiceQuotas_601144(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAWSDefaultServiceQuotas_601143(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all default service quotas for the specified AWS service or all AWS services. ListAWSDefaultServiceQuotas is similar to <a>ListServiceQuotas</a> except for the Value object. The Value object returned by <code>ListAWSDefaultServiceQuotas</code> is the default value assigned by AWS. This request returns a list of all service quotas for the specified service. The listing of each you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
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
  var valid_601145 = query.getOrDefault("NextToken")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "NextToken", valid_601145
  var valid_601146 = query.getOrDefault("MaxResults")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "MaxResults", valid_601146
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601147 = header.getOrDefault("X-Amz-Date")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Date", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Security-Token")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Security-Token", valid_601148
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601149 = header.getOrDefault("X-Amz-Target")
  valid_601149 = validateParameter(valid_601149, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListAWSDefaultServiceQuotas"))
  if valid_601149 != nil:
    section.add "X-Amz-Target", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Content-Sha256", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Algorithm")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Algorithm", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Signature")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Signature", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-SignedHeaders", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Credential")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Credential", valid_601154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601156: Call_ListAWSDefaultServiceQuotas_601142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all default service quotas for the specified AWS service or all AWS services. ListAWSDefaultServiceQuotas is similar to <a>ListServiceQuotas</a> except for the Value object. The Value object returned by <code>ListAWSDefaultServiceQuotas</code> is the default value assigned by AWS. This request returns a list of all service quotas for the specified service. The listing of each you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ## 
  let valid = call_601156.validator(path, query, header, formData, body)
  let scheme = call_601156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601156.url(scheme.get, call_601156.host, call_601156.base,
                         call_601156.route, valid.getOrDefault("path"))
  result = hook(call_601156, url, valid)

proc call*(call_601157: Call_ListAWSDefaultServiceQuotas_601142; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAWSDefaultServiceQuotas
  ## <p>Lists all default service quotas for the specified AWS service or all AWS services. ListAWSDefaultServiceQuotas is similar to <a>ListServiceQuotas</a> except for the Value object. The Value object returned by <code>ListAWSDefaultServiceQuotas</code> is the default value assigned by AWS. This request returns a list of all service quotas for the specified service. The listing of each you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601158 = newJObject()
  var body_601159 = newJObject()
  add(query_601158, "NextToken", newJString(NextToken))
  if body != nil:
    body_601159 = body
  add(query_601158, "MaxResults", newJString(MaxResults))
  result = call_601157.call(nil, query_601158, nil, nil, body_601159)

var listAWSDefaultServiceQuotas* = Call_ListAWSDefaultServiceQuotas_601142(
    name: "listAWSDefaultServiceQuotas", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.ListAWSDefaultServiceQuotas",
    validator: validate_ListAWSDefaultServiceQuotas_601143, base: "/",
    url: url_ListAWSDefaultServiceQuotas_601144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRequestedServiceQuotaChangeHistory_601161 = ref object of OpenApiRestCall_600426
proc url_ListRequestedServiceQuotaChangeHistory_601163(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListRequestedServiceQuotaChangeHistory_601162(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Requests a list of the changes to quotas for a service.
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
  var valid_601164 = query.getOrDefault("NextToken")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "NextToken", valid_601164
  var valid_601165 = query.getOrDefault("MaxResults")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "MaxResults", valid_601165
  result.add "query", section
  ## parameters in `header` object:
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
      "ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistory"))
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

proc call*(call_601175: Call_ListRequestedServiceQuotaChangeHistory_601161;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Requests a list of the changes to quotas for a service.
  ## 
  let valid = call_601175.validator(path, query, header, formData, body)
  let scheme = call_601175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601175.url(scheme.get, call_601175.host, call_601175.base,
                         call_601175.route, valid.getOrDefault("path"))
  result = hook(call_601175, url, valid)

proc call*(call_601176: Call_ListRequestedServiceQuotaChangeHistory_601161;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listRequestedServiceQuotaChangeHistory
  ## Requests a list of the changes to quotas for a service.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601177 = newJObject()
  var body_601178 = newJObject()
  add(query_601177, "NextToken", newJString(NextToken))
  if body != nil:
    body_601178 = body
  add(query_601177, "MaxResults", newJString(MaxResults))
  result = call_601176.call(nil, query_601177, nil, nil, body_601178)

var listRequestedServiceQuotaChangeHistory* = Call_ListRequestedServiceQuotaChangeHistory_601161(
    name: "listRequestedServiceQuotaChangeHistory", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistory",
    validator: validate_ListRequestedServiceQuotaChangeHistory_601162, base: "/",
    url: url_ListRequestedServiceQuotaChangeHistory_601163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRequestedServiceQuotaChangeHistoryByQuota_601179 = ref object of OpenApiRestCall_600426
proc url_ListRequestedServiceQuotaChangeHistoryByQuota_601181(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListRequestedServiceQuotaChangeHistoryByQuota_601180(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Requests a list of the changes to specific service quotas. This command provides additional granularity over the <code>ListRequestedServiceQuotaChangeHistory</code> command. Once a quota change request has reached <code>CASE_CLOSED, APPROVED,</code> or <code>DENIED</code>, the history has been kept for 90 days.
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
  var valid_601182 = query.getOrDefault("NextToken")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "NextToken", valid_601182
  var valid_601183 = query.getOrDefault("MaxResults")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "MaxResults", valid_601183
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601184 = header.getOrDefault("X-Amz-Date")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Date", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Security-Token")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Security-Token", valid_601185
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601186 = header.getOrDefault("X-Amz-Target")
  valid_601186 = validateParameter(valid_601186, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistoryByQuota"))
  if valid_601186 != nil:
    section.add "X-Amz-Target", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Content-Sha256", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Algorithm")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Algorithm", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Signature")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Signature", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-SignedHeaders", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Credential")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Credential", valid_601191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601193: Call_ListRequestedServiceQuotaChangeHistoryByQuota_601179;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Requests a list of the changes to specific service quotas. This command provides additional granularity over the <code>ListRequestedServiceQuotaChangeHistory</code> command. Once a quota change request has reached <code>CASE_CLOSED, APPROVED,</code> or <code>DENIED</code>, the history has been kept for 90 days.
  ## 
  let valid = call_601193.validator(path, query, header, formData, body)
  let scheme = call_601193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601193.url(scheme.get, call_601193.host, call_601193.base,
                         call_601193.route, valid.getOrDefault("path"))
  result = hook(call_601193, url, valid)

proc call*(call_601194: Call_ListRequestedServiceQuotaChangeHistoryByQuota_601179;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listRequestedServiceQuotaChangeHistoryByQuota
  ## Requests a list of the changes to specific service quotas. This command provides additional granularity over the <code>ListRequestedServiceQuotaChangeHistory</code> command. Once a quota change request has reached <code>CASE_CLOSED, APPROVED,</code> or <code>DENIED</code>, the history has been kept for 90 days.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601195 = newJObject()
  var body_601196 = newJObject()
  add(query_601195, "NextToken", newJString(NextToken))
  if body != nil:
    body_601196 = body
  add(query_601195, "MaxResults", newJString(MaxResults))
  result = call_601194.call(nil, query_601195, nil, nil, body_601196)

var listRequestedServiceQuotaChangeHistoryByQuota* = Call_ListRequestedServiceQuotaChangeHistoryByQuota_601179(
    name: "listRequestedServiceQuotaChangeHistoryByQuota",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistoryByQuota",
    validator: validate_ListRequestedServiceQuotaChangeHistoryByQuota_601180,
    base: "/", url: url_ListRequestedServiceQuotaChangeHistoryByQuota_601181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceQuotaIncreaseRequestsInTemplate_601197 = ref object of OpenApiRestCall_600426
proc url_ListServiceQuotaIncreaseRequestsInTemplate_601199(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListServiceQuotaIncreaseRequestsInTemplate_601198(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the quota increase requests in the template. 
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
  var valid_601200 = query.getOrDefault("NextToken")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "NextToken", valid_601200
  var valid_601201 = query.getOrDefault("MaxResults")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "MaxResults", valid_601201
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601202 = header.getOrDefault("X-Amz-Date")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Date", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Security-Token")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Security-Token", valid_601203
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601204 = header.getOrDefault("X-Amz-Target")
  valid_601204 = validateParameter(valid_601204, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListServiceQuotaIncreaseRequestsInTemplate"))
  if valid_601204 != nil:
    section.add "X-Amz-Target", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Content-Sha256", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Algorithm")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Algorithm", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Signature")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Signature", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-SignedHeaders", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Credential")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Credential", valid_601209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601211: Call_ListServiceQuotaIncreaseRequestsInTemplate_601197;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of the quota increase requests in the template. 
  ## 
  let valid = call_601211.validator(path, query, header, formData, body)
  let scheme = call_601211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601211.url(scheme.get, call_601211.host, call_601211.base,
                         call_601211.route, valid.getOrDefault("path"))
  result = hook(call_601211, url, valid)

proc call*(call_601212: Call_ListServiceQuotaIncreaseRequestsInTemplate_601197;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listServiceQuotaIncreaseRequestsInTemplate
  ## Returns a list of the quota increase requests in the template. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601213 = newJObject()
  var body_601214 = newJObject()
  add(query_601213, "NextToken", newJString(NextToken))
  if body != nil:
    body_601214 = body
  add(query_601213, "MaxResults", newJString(MaxResults))
  result = call_601212.call(nil, query_601213, nil, nil, body_601214)

var listServiceQuotaIncreaseRequestsInTemplate* = Call_ListServiceQuotaIncreaseRequestsInTemplate_601197(
    name: "listServiceQuotaIncreaseRequestsInTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.ListServiceQuotaIncreaseRequestsInTemplate",
    validator: validate_ListServiceQuotaIncreaseRequestsInTemplate_601198,
    base: "/", url: url_ListServiceQuotaIncreaseRequestsInTemplate_601199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceQuotas_601215 = ref object of OpenApiRestCall_600426
proc url_ListServiceQuotas_601217(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListServiceQuotas_601216(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Lists all service quotas for the specified AWS service. This request returns a list of the service quotas for the specified service. you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
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
  var valid_601218 = query.getOrDefault("NextToken")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "NextToken", valid_601218
  var valid_601219 = query.getOrDefault("MaxResults")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "MaxResults", valid_601219
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601220 = header.getOrDefault("X-Amz-Date")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Date", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Security-Token")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Security-Token", valid_601221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601222 = header.getOrDefault("X-Amz-Target")
  valid_601222 = validateParameter(valid_601222, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListServiceQuotas"))
  if valid_601222 != nil:
    section.add "X-Amz-Target", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Content-Sha256", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Algorithm")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Algorithm", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Signature")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Signature", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-SignedHeaders", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Credential")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Credential", valid_601227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601229: Call_ListServiceQuotas_601215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all service quotas for the specified AWS service. This request returns a list of the service quotas for the specified service. you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ## 
  let valid = call_601229.validator(path, query, header, formData, body)
  let scheme = call_601229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601229.url(scheme.get, call_601229.host, call_601229.base,
                         call_601229.route, valid.getOrDefault("path"))
  result = hook(call_601229, url, valid)

proc call*(call_601230: Call_ListServiceQuotas_601215; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listServiceQuotas
  ## <p>Lists all service quotas for the specified AWS service. This request returns a list of the service quotas for the specified service. you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601231 = newJObject()
  var body_601232 = newJObject()
  add(query_601231, "NextToken", newJString(NextToken))
  if body != nil:
    body_601232 = body
  add(query_601231, "MaxResults", newJString(MaxResults))
  result = call_601230.call(nil, query_601231, nil, nil, body_601232)

var listServiceQuotas* = Call_ListServiceQuotas_601215(name: "listServiceQuotas",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.ListServiceQuotas",
    validator: validate_ListServiceQuotas_601216, base: "/",
    url: url_ListServiceQuotas_601217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServices_601233 = ref object of OpenApiRestCall_600426
proc url_ListServices_601235(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListServices_601234(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the AWS services available in Service Quotas. Not all AWS services are available in Service Quotas. To list the see the list of the service quotas for a specific service, use <a>ListServiceQuotas</a>.
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
  var valid_601236 = query.getOrDefault("NextToken")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "NextToken", valid_601236
  var valid_601237 = query.getOrDefault("MaxResults")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "MaxResults", valid_601237
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601238 = header.getOrDefault("X-Amz-Date")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Date", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Security-Token")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Security-Token", valid_601239
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601240 = header.getOrDefault("X-Amz-Target")
  valid_601240 = validateParameter(valid_601240, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListServices"))
  if valid_601240 != nil:
    section.add "X-Amz-Target", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Content-Sha256", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Algorithm")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Algorithm", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Signature")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Signature", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-SignedHeaders", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Credential")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Credential", valid_601245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601247: Call_ListServices_601233; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS services available in Service Quotas. Not all AWS services are available in Service Quotas. To list the see the list of the service quotas for a specific service, use <a>ListServiceQuotas</a>.
  ## 
  let valid = call_601247.validator(path, query, header, formData, body)
  let scheme = call_601247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601247.url(scheme.get, call_601247.host, call_601247.base,
                         call_601247.route, valid.getOrDefault("path"))
  result = hook(call_601247, url, valid)

proc call*(call_601248: Call_ListServices_601233; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listServices
  ## Lists the AWS services available in Service Quotas. Not all AWS services are available in Service Quotas. To list the see the list of the service quotas for a specific service, use <a>ListServiceQuotas</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601249 = newJObject()
  var body_601250 = newJObject()
  add(query_601249, "NextToken", newJString(NextToken))
  if body != nil:
    body_601250 = body
  add(query_601249, "MaxResults", newJString(MaxResults))
  result = call_601248.call(nil, query_601249, nil, nil, body_601250)

var listServices* = Call_ListServices_601233(name: "listServices",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.ListServices",
    validator: validate_ListServices_601234, base: "/", url: url_ListServices_601235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutServiceQuotaIncreaseRequestIntoTemplate_601251 = ref object of OpenApiRestCall_600426
proc url_PutServiceQuotaIncreaseRequestIntoTemplate_601253(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutServiceQuotaIncreaseRequestIntoTemplate_601252(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Defines and adds a quota to the service quota template. To add a quota to the template, you must provide the <code>ServiceCode</code>, <code>QuotaCode</code>, <code>AwsRegion</code>, and <code>DesiredValue</code>. Once you add a quota to the template, use <a>ListServiceQuotaIncreaseRequestsInTemplate</a> to see the list of quotas in the template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601254 = header.getOrDefault("X-Amz-Date")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Date", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Security-Token")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Security-Token", valid_601255
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601256 = header.getOrDefault("X-Amz-Target")
  valid_601256 = validateParameter(valid_601256, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.PutServiceQuotaIncreaseRequestIntoTemplate"))
  if valid_601256 != nil:
    section.add "X-Amz-Target", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Content-Sha256", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Algorithm")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Algorithm", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Signature")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Signature", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-SignedHeaders", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Credential")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Credential", valid_601261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601263: Call_PutServiceQuotaIncreaseRequestIntoTemplate_601251;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Defines and adds a quota to the service quota template. To add a quota to the template, you must provide the <code>ServiceCode</code>, <code>QuotaCode</code>, <code>AwsRegion</code>, and <code>DesiredValue</code>. Once you add a quota to the template, use <a>ListServiceQuotaIncreaseRequestsInTemplate</a> to see the list of quotas in the template.
  ## 
  let valid = call_601263.validator(path, query, header, formData, body)
  let scheme = call_601263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601263.url(scheme.get, call_601263.host, call_601263.base,
                         call_601263.route, valid.getOrDefault("path"))
  result = hook(call_601263, url, valid)

proc call*(call_601264: Call_PutServiceQuotaIncreaseRequestIntoTemplate_601251;
          body: JsonNode): Recallable =
  ## putServiceQuotaIncreaseRequestIntoTemplate
  ## Defines and adds a quota to the service quota template. To add a quota to the template, you must provide the <code>ServiceCode</code>, <code>QuotaCode</code>, <code>AwsRegion</code>, and <code>DesiredValue</code>. Once you add a quota to the template, use <a>ListServiceQuotaIncreaseRequestsInTemplate</a> to see the list of quotas in the template.
  ##   body: JObject (required)
  var body_601265 = newJObject()
  if body != nil:
    body_601265 = body
  result = call_601264.call(nil, nil, nil, nil, body_601265)

var putServiceQuotaIncreaseRequestIntoTemplate* = Call_PutServiceQuotaIncreaseRequestIntoTemplate_601251(
    name: "putServiceQuotaIncreaseRequestIntoTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.PutServiceQuotaIncreaseRequestIntoTemplate",
    validator: validate_PutServiceQuotaIncreaseRequestIntoTemplate_601252,
    base: "/", url: url_PutServiceQuotaIncreaseRequestIntoTemplate_601253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RequestServiceQuotaIncrease_601266 = ref object of OpenApiRestCall_600426
proc url_RequestServiceQuotaIncrease_601268(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RequestServiceQuotaIncrease_601267(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the details of a service quota increase request. The response to this command provides the details in the <a>RequestedServiceQuotaChange</a> object. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601269 = header.getOrDefault("X-Amz-Date")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Date", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Security-Token")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Security-Token", valid_601270
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601271 = header.getOrDefault("X-Amz-Target")
  valid_601271 = validateParameter(valid_601271, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.RequestServiceQuotaIncrease"))
  if valid_601271 != nil:
    section.add "X-Amz-Target", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Content-Sha256", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Algorithm")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Algorithm", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-Signature")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Signature", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-SignedHeaders", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Credential")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Credential", valid_601276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601278: Call_RequestServiceQuotaIncrease_601266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details of a service quota increase request. The response to this command provides the details in the <a>RequestedServiceQuotaChange</a> object. 
  ## 
  let valid = call_601278.validator(path, query, header, formData, body)
  let scheme = call_601278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601278.url(scheme.get, call_601278.host, call_601278.base,
                         call_601278.route, valid.getOrDefault("path"))
  result = hook(call_601278, url, valid)

proc call*(call_601279: Call_RequestServiceQuotaIncrease_601266; body: JsonNode): Recallable =
  ## requestServiceQuotaIncrease
  ## Retrieves the details of a service quota increase request. The response to this command provides the details in the <a>RequestedServiceQuotaChange</a> object. 
  ##   body: JObject (required)
  var body_601280 = newJObject()
  if body != nil:
    body_601280 = body
  result = call_601279.call(nil, nil, nil, nil, body_601280)

var requestServiceQuotaIncrease* = Call_RequestServiceQuotaIncrease_601266(
    name: "requestServiceQuotaIncrease", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.RequestServiceQuotaIncrease",
    validator: validate_RequestServiceQuotaIncrease_601267, base: "/",
    url: url_RequestServiceQuotaIncrease_601268,
    schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
