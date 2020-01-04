
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateServiceQuotaTemplate_601727 = ref object of OpenApiRestCall_601389
proc url_AssociateServiceQuotaTemplate_601729(protocol: Scheme; host: string;
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

proc validate_AssociateServiceQuotaTemplate_601728(path: JsonNode; query: JsonNode;
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
  var valid_601854 = header.getOrDefault("X-Amz-Target")
  valid_601854 = validateParameter(valid_601854, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.AssociateServiceQuotaTemplate"))
  if valid_601854 != nil:
    section.add "X-Amz-Target", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-Signature")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Signature", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Content-Sha256", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Date")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Date", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Credential")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Credential", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Security-Token")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Security-Token", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-SignedHeaders", valid_601861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_AssociateServiceQuotaTemplate_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the Service Quotas template with your organization so that when new accounts are created in your organization, the template submits increase requests for the specified service quotas. Use the Service Quotas template to request an increase for any adjustable quota value. After you define the Service Quotas template, use this operation to associate, or enable, the template. 
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_AssociateServiceQuotaTemplate_601727; body: JsonNode): Recallable =
  ## associateServiceQuotaTemplate
  ## Associates the Service Quotas template with your organization so that when new accounts are created in your organization, the template submits increase requests for the specified service quotas. Use the Service Quotas template to request an increase for any adjustable quota value. After you define the Service Quotas template, use this operation to associate, or enable, the template. 
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var associateServiceQuotaTemplate* = Call_AssociateServiceQuotaTemplate_601727(
    name: "associateServiceQuotaTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.AssociateServiceQuotaTemplate",
    validator: validate_AssociateServiceQuotaTemplate_601728, base: "/",
    url: url_AssociateServiceQuotaTemplate_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceQuotaIncreaseRequestFromTemplate_601996 = ref object of OpenApiRestCall_601389
proc url_DeleteServiceQuotaIncreaseRequestFromTemplate_601998(protocol: Scheme;
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

proc validate_DeleteServiceQuotaIncreaseRequestFromTemplate_601997(
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
  var valid_601999 = header.getOrDefault("X-Amz-Target")
  valid_601999 = validateParameter(valid_601999, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.DeleteServiceQuotaIncreaseRequestFromTemplate"))
  if valid_601999 != nil:
    section.add "X-Amz-Target", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Date")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Date", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Credential")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Credential", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Algorithm")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Algorithm", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-SignedHeaders", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_DeleteServiceQuotaIncreaseRequestFromTemplate_601996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a service quota increase request from the Service Quotas template. 
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_DeleteServiceQuotaIncreaseRequestFromTemplate_601996;
          body: JsonNode): Recallable =
  ## deleteServiceQuotaIncreaseRequestFromTemplate
  ## Removes a service quota increase request from the Service Quotas template. 
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var deleteServiceQuotaIncreaseRequestFromTemplate* = Call_DeleteServiceQuotaIncreaseRequestFromTemplate_601996(
    name: "deleteServiceQuotaIncreaseRequestFromTemplate",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.DeleteServiceQuotaIncreaseRequestFromTemplate",
    validator: validate_DeleteServiceQuotaIncreaseRequestFromTemplate_601997,
    base: "/", url: url_DeleteServiceQuotaIncreaseRequestFromTemplate_601998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceQuotaTemplate_602011 = ref object of OpenApiRestCall_601389
proc url_DisassociateServiceQuotaTemplate_602013(protocol: Scheme; host: string;
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

proc validate_DisassociateServiceQuotaTemplate_602012(path: JsonNode;
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
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.DisassociateServiceQuotaTemplate"))
  if valid_602014 != nil:
    section.add "X-Amz-Target", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_DisassociateServiceQuotaTemplate_602011;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Disables the Service Quotas template. Once the template is disabled, it does not request quota increases for new accounts in your organization. Disabling the quota template does not apply the quota increase requests from the template. </p> <p> <b>Related operations</b> </p> <ul> <li> <p>To enable the quota template, call <a>AssociateServiceQuotaTemplate</a>. </p> </li> <li> <p>To delete a specific service quota from the template, use <a>DeleteServiceQuotaIncreaseRequestFromTemplate</a>.</p> </li> </ul>
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_DisassociateServiceQuotaTemplate_602011;
          body: JsonNode): Recallable =
  ## disassociateServiceQuotaTemplate
  ## <p>Disables the Service Quotas template. Once the template is disabled, it does not request quota increases for new accounts in your organization. Disabling the quota template does not apply the quota increase requests from the template. </p> <p> <b>Related operations</b> </p> <ul> <li> <p>To enable the quota template, call <a>AssociateServiceQuotaTemplate</a>. </p> </li> <li> <p>To delete a specific service quota from the template, use <a>DeleteServiceQuotaIncreaseRequestFromTemplate</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var disassociateServiceQuotaTemplate* = Call_DisassociateServiceQuotaTemplate_602011(
    name: "disassociateServiceQuotaTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.DisassociateServiceQuotaTemplate",
    validator: validate_DisassociateServiceQuotaTemplate_602012, base: "/",
    url: url_DisassociateServiceQuotaTemplate_602013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAWSDefaultServiceQuota_602026 = ref object of OpenApiRestCall_601389
proc url_GetAWSDefaultServiceQuota_602028(protocol: Scheme; host: string;
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

proc validate_GetAWSDefaultServiceQuota_602027(path: JsonNode; query: JsonNode;
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
  var valid_602029 = header.getOrDefault("X-Amz-Target")
  valid_602029 = validateParameter(valid_602029, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetAWSDefaultServiceQuota"))
  if valid_602029 != nil:
    section.add "X-Amz-Target", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_GetAWSDefaultServiceQuota_602026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the default service quotas values. The Value returned for each quota is the AWS default value, even if the quotas have been increased.. 
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_GetAWSDefaultServiceQuota_602026; body: JsonNode): Recallable =
  ## getAWSDefaultServiceQuota
  ## Retrieves the default service quotas values. The Value returned for each quota is the AWS default value, even if the quotas have been increased.. 
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var getAWSDefaultServiceQuota* = Call_GetAWSDefaultServiceQuota_602026(
    name: "getAWSDefaultServiceQuota", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.GetAWSDefaultServiceQuota",
    validator: validate_GetAWSDefaultServiceQuota_602027, base: "/",
    url: url_GetAWSDefaultServiceQuota_602028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssociationForServiceQuotaTemplate_602041 = ref object of OpenApiRestCall_601389
proc url_GetAssociationForServiceQuotaTemplate_602043(protocol: Scheme;
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

proc validate_GetAssociationForServiceQuotaTemplate_602042(path: JsonNode;
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
  var valid_602044 = header.getOrDefault("X-Amz-Target")
  valid_602044 = validateParameter(valid_602044, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetAssociationForServiceQuotaTemplate"))
  if valid_602044 != nil:
    section.add "X-Amz-Target", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Credential")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Credential", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Security-Token")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Security-Token", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-SignedHeaders", valid_602051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_GetAssociationForServiceQuotaTemplate_602041;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the <code>ServiceQuotaTemplateAssociationStatus</code> value from the service. Use this action to determine if the Service Quota template is associated, or enabled. 
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_GetAssociationForServiceQuotaTemplate_602041;
          body: JsonNode): Recallable =
  ## getAssociationForServiceQuotaTemplate
  ## Retrieves the <code>ServiceQuotaTemplateAssociationStatus</code> value from the service. Use this action to determine if the Service Quota template is associated, or enabled. 
  ##   body: JObject (required)
  var body_602055 = newJObject()
  if body != nil:
    body_602055 = body
  result = call_602054.call(nil, nil, nil, nil, body_602055)

var getAssociationForServiceQuotaTemplate* = Call_GetAssociationForServiceQuotaTemplate_602041(
    name: "getAssociationForServiceQuotaTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.GetAssociationForServiceQuotaTemplate",
    validator: validate_GetAssociationForServiceQuotaTemplate_602042, base: "/",
    url: url_GetAssociationForServiceQuotaTemplate_602043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestedServiceQuotaChange_602056 = ref object of OpenApiRestCall_601389
proc url_GetRequestedServiceQuotaChange_602058(protocol: Scheme; host: string;
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

proc validate_GetRequestedServiceQuotaChange_602057(path: JsonNode;
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
  var valid_602059 = header.getOrDefault("X-Amz-Target")
  valid_602059 = validateParameter(valid_602059, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetRequestedServiceQuotaChange"))
  if valid_602059 != nil:
    section.add "X-Amz-Target", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Signature")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Signature", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Content-Sha256", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Date")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Date", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Credential")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Credential", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Security-Token")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Security-Token", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Algorithm")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Algorithm", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-SignedHeaders", valid_602066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_GetRequestedServiceQuotaChange_602056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details for a particular increase request. 
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_GetRequestedServiceQuotaChange_602056; body: JsonNode): Recallable =
  ## getRequestedServiceQuotaChange
  ## Retrieves the details for a particular increase request. 
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var getRequestedServiceQuotaChange* = Call_GetRequestedServiceQuotaChange_602056(
    name: "getRequestedServiceQuotaChange", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.GetRequestedServiceQuotaChange",
    validator: validate_GetRequestedServiceQuotaChange_602057, base: "/",
    url: url_GetRequestedServiceQuotaChange_602058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceQuota_602071 = ref object of OpenApiRestCall_601389
proc url_GetServiceQuota_602073(protocol: Scheme; host: string; base: string;
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

proc validate_GetServiceQuota_602072(path: JsonNode; query: JsonNode;
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
  var valid_602074 = header.getOrDefault("X-Amz-Target")
  valid_602074 = validateParameter(valid_602074, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetServiceQuota"))
  if valid_602074 != nil:
    section.add "X-Amz-Target", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Signature")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Signature", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Content-Sha256", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Date")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Date", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Security-Token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Security-Token", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Algorithm")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Algorithm", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-SignedHeaders", valid_602081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_GetServiceQuota_602071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details for the specified service quota. This operation provides a different Value than the <code>GetAWSDefaultServiceQuota</code> operation. This operation returns the applied value for each quota. <code>GetAWSDefaultServiceQuota</code> returns the default AWS value for each quota. 
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_GetServiceQuota_602071; body: JsonNode): Recallable =
  ## getServiceQuota
  ## Returns the details for the specified service quota. This operation provides a different Value than the <code>GetAWSDefaultServiceQuota</code> operation. This operation returns the applied value for each quota. <code>GetAWSDefaultServiceQuota</code> returns the default AWS value for each quota. 
  ##   body: JObject (required)
  var body_602085 = newJObject()
  if body != nil:
    body_602085 = body
  result = call_602084.call(nil, nil, nil, nil, body_602085)

var getServiceQuota* = Call_GetServiceQuota_602071(name: "getServiceQuota",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.GetServiceQuota",
    validator: validate_GetServiceQuota_602072, base: "/", url: url_GetServiceQuota_602073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceQuotaIncreaseRequestFromTemplate_602086 = ref object of OpenApiRestCall_601389
proc url_GetServiceQuotaIncreaseRequestFromTemplate_602088(protocol: Scheme;
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

proc validate_GetServiceQuotaIncreaseRequestFromTemplate_602087(path: JsonNode;
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
  var valid_602089 = header.getOrDefault("X-Amz-Target")
  valid_602089 = validateParameter(valid_602089, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetServiceQuotaIncreaseRequestFromTemplate"))
  if valid_602089 != nil:
    section.add "X-Amz-Target", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-SignedHeaders", valid_602096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602098: Call_GetServiceQuotaIncreaseRequestFromTemplate_602086;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the details of the service quota increase request in your template.
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_GetServiceQuotaIncreaseRequestFromTemplate_602086;
          body: JsonNode): Recallable =
  ## getServiceQuotaIncreaseRequestFromTemplate
  ## Returns the details of the service quota increase request in your template.
  ##   body: JObject (required)
  var body_602100 = newJObject()
  if body != nil:
    body_602100 = body
  result = call_602099.call(nil, nil, nil, nil, body_602100)

var getServiceQuotaIncreaseRequestFromTemplate* = Call_GetServiceQuotaIncreaseRequestFromTemplate_602086(
    name: "getServiceQuotaIncreaseRequestFromTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.GetServiceQuotaIncreaseRequestFromTemplate",
    validator: validate_GetServiceQuotaIncreaseRequestFromTemplate_602087,
    base: "/", url: url_GetServiceQuotaIncreaseRequestFromTemplate_602088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAWSDefaultServiceQuotas_602101 = ref object of OpenApiRestCall_601389
proc url_ListAWSDefaultServiceQuotas_602103(protocol: Scheme; host: string;
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

proc validate_ListAWSDefaultServiceQuotas_602102(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all default service quotas for the specified AWS service or all AWS services. ListAWSDefaultServiceQuotas is similar to <a>ListServiceQuotas</a> except for the Value object. The Value object returned by <code>ListAWSDefaultServiceQuotas</code> is the default value assigned by AWS. This request returns a list of all service quotas for the specified service. The listing of each you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
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
  var valid_602104 = query.getOrDefault("MaxResults")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "MaxResults", valid_602104
  var valid_602105 = query.getOrDefault("NextToken")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "NextToken", valid_602105
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
  var valid_602106 = header.getOrDefault("X-Amz-Target")
  valid_602106 = validateParameter(valid_602106, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListAWSDefaultServiceQuotas"))
  if valid_602106 != nil:
    section.add "X-Amz-Target", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Signature")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Signature", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Content-Sha256", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Date")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Date", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Credential")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Credential", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Security-Token")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Security-Token", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Algorithm")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Algorithm", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-SignedHeaders", valid_602113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602115: Call_ListAWSDefaultServiceQuotas_602101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all default service quotas for the specified AWS service or all AWS services. ListAWSDefaultServiceQuotas is similar to <a>ListServiceQuotas</a> except for the Value object. The Value object returned by <code>ListAWSDefaultServiceQuotas</code> is the default value assigned by AWS. This request returns a list of all service quotas for the specified service. The listing of each you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ## 
  let valid = call_602115.validator(path, query, header, formData, body)
  let scheme = call_602115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602115.url(scheme.get, call_602115.host, call_602115.base,
                         call_602115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602115, url, valid)

proc call*(call_602116: Call_ListAWSDefaultServiceQuotas_602101; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAWSDefaultServiceQuotas
  ## <p>Lists all default service quotas for the specified AWS service or all AWS services. ListAWSDefaultServiceQuotas is similar to <a>ListServiceQuotas</a> except for the Value object. The Value object returned by <code>ListAWSDefaultServiceQuotas</code> is the default value assigned by AWS. This request returns a list of all service quotas for the specified service. The listing of each you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602117 = newJObject()
  var body_602118 = newJObject()
  add(query_602117, "MaxResults", newJString(MaxResults))
  add(query_602117, "NextToken", newJString(NextToken))
  if body != nil:
    body_602118 = body
  result = call_602116.call(nil, query_602117, nil, nil, body_602118)

var listAWSDefaultServiceQuotas* = Call_ListAWSDefaultServiceQuotas_602101(
    name: "listAWSDefaultServiceQuotas", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.ListAWSDefaultServiceQuotas",
    validator: validate_ListAWSDefaultServiceQuotas_602102, base: "/",
    url: url_ListAWSDefaultServiceQuotas_602103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRequestedServiceQuotaChangeHistory_602120 = ref object of OpenApiRestCall_601389
proc url_ListRequestedServiceQuotaChangeHistory_602122(protocol: Scheme;
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

proc validate_ListRequestedServiceQuotaChangeHistory_602121(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Requests a list of the changes to quotas for a service.
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
  var valid_602123 = query.getOrDefault("MaxResults")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "MaxResults", valid_602123
  var valid_602124 = query.getOrDefault("NextToken")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "NextToken", valid_602124
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
  var valid_602125 = header.getOrDefault("X-Amz-Target")
  valid_602125 = validateParameter(valid_602125, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistory"))
  if valid_602125 != nil:
    section.add "X-Amz-Target", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Signature")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Signature", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Content-Sha256", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Date")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Date", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Credential")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Credential", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Security-Token")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Security-Token", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-Algorithm")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Algorithm", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-SignedHeaders", valid_602132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602134: Call_ListRequestedServiceQuotaChangeHistory_602120;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Requests a list of the changes to quotas for a service.
  ## 
  let valid = call_602134.validator(path, query, header, formData, body)
  let scheme = call_602134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602134.url(scheme.get, call_602134.host, call_602134.base,
                         call_602134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602134, url, valid)

proc call*(call_602135: Call_ListRequestedServiceQuotaChangeHistory_602120;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listRequestedServiceQuotaChangeHistory
  ## Requests a list of the changes to quotas for a service.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602136 = newJObject()
  var body_602137 = newJObject()
  add(query_602136, "MaxResults", newJString(MaxResults))
  add(query_602136, "NextToken", newJString(NextToken))
  if body != nil:
    body_602137 = body
  result = call_602135.call(nil, query_602136, nil, nil, body_602137)

var listRequestedServiceQuotaChangeHistory* = Call_ListRequestedServiceQuotaChangeHistory_602120(
    name: "listRequestedServiceQuotaChangeHistory", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistory",
    validator: validate_ListRequestedServiceQuotaChangeHistory_602121, base: "/",
    url: url_ListRequestedServiceQuotaChangeHistory_602122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRequestedServiceQuotaChangeHistoryByQuota_602138 = ref object of OpenApiRestCall_601389
proc url_ListRequestedServiceQuotaChangeHistoryByQuota_602140(protocol: Scheme;
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

proc validate_ListRequestedServiceQuotaChangeHistoryByQuota_602139(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Requests a list of the changes to specific service quotas. This command provides additional granularity over the <code>ListRequestedServiceQuotaChangeHistory</code> command. Once a quota change request has reached <code>CASE_CLOSED, APPROVED,</code> or <code>DENIED</code>, the history has been kept for 90 days.
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
  var valid_602141 = query.getOrDefault("MaxResults")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "MaxResults", valid_602141
  var valid_602142 = query.getOrDefault("NextToken")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "NextToken", valid_602142
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
  var valid_602143 = header.getOrDefault("X-Amz-Target")
  valid_602143 = validateParameter(valid_602143, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistoryByQuota"))
  if valid_602143 != nil:
    section.add "X-Amz-Target", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Signature")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Signature", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Content-Sha256", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Date")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Date", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Credential")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Credential", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Security-Token")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Security-Token", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Algorithm")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Algorithm", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-SignedHeaders", valid_602150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602152: Call_ListRequestedServiceQuotaChangeHistoryByQuota_602138;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Requests a list of the changes to specific service quotas. This command provides additional granularity over the <code>ListRequestedServiceQuotaChangeHistory</code> command. Once a quota change request has reached <code>CASE_CLOSED, APPROVED,</code> or <code>DENIED</code>, the history has been kept for 90 days.
  ## 
  let valid = call_602152.validator(path, query, header, formData, body)
  let scheme = call_602152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602152.url(scheme.get, call_602152.host, call_602152.base,
                         call_602152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602152, url, valid)

proc call*(call_602153: Call_ListRequestedServiceQuotaChangeHistoryByQuota_602138;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listRequestedServiceQuotaChangeHistoryByQuota
  ## Requests a list of the changes to specific service quotas. This command provides additional granularity over the <code>ListRequestedServiceQuotaChangeHistory</code> command. Once a quota change request has reached <code>CASE_CLOSED, APPROVED,</code> or <code>DENIED</code>, the history has been kept for 90 days.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602154 = newJObject()
  var body_602155 = newJObject()
  add(query_602154, "MaxResults", newJString(MaxResults))
  add(query_602154, "NextToken", newJString(NextToken))
  if body != nil:
    body_602155 = body
  result = call_602153.call(nil, query_602154, nil, nil, body_602155)

var listRequestedServiceQuotaChangeHistoryByQuota* = Call_ListRequestedServiceQuotaChangeHistoryByQuota_602138(
    name: "listRequestedServiceQuotaChangeHistoryByQuota",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistoryByQuota",
    validator: validate_ListRequestedServiceQuotaChangeHistoryByQuota_602139,
    base: "/", url: url_ListRequestedServiceQuotaChangeHistoryByQuota_602140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceQuotaIncreaseRequestsInTemplate_602156 = ref object of OpenApiRestCall_601389
proc url_ListServiceQuotaIncreaseRequestsInTemplate_602158(protocol: Scheme;
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

proc validate_ListServiceQuotaIncreaseRequestsInTemplate_602157(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the quota increase requests in the template. 
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
  var valid_602159 = query.getOrDefault("MaxResults")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "MaxResults", valid_602159
  var valid_602160 = query.getOrDefault("NextToken")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "NextToken", valid_602160
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
  var valid_602161 = header.getOrDefault("X-Amz-Target")
  valid_602161 = validateParameter(valid_602161, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListServiceQuotaIncreaseRequestsInTemplate"))
  if valid_602161 != nil:
    section.add "X-Amz-Target", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Signature")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Signature", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Content-Sha256", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Date")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Date", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Credential")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Credential", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Security-Token")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Security-Token", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Algorithm")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Algorithm", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-SignedHeaders", valid_602168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602170: Call_ListServiceQuotaIncreaseRequestsInTemplate_602156;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of the quota increase requests in the template. 
  ## 
  let valid = call_602170.validator(path, query, header, formData, body)
  let scheme = call_602170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602170.url(scheme.get, call_602170.host, call_602170.base,
                         call_602170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602170, url, valid)

proc call*(call_602171: Call_ListServiceQuotaIncreaseRequestsInTemplate_602156;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listServiceQuotaIncreaseRequestsInTemplate
  ## Returns a list of the quota increase requests in the template. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602172 = newJObject()
  var body_602173 = newJObject()
  add(query_602172, "MaxResults", newJString(MaxResults))
  add(query_602172, "NextToken", newJString(NextToken))
  if body != nil:
    body_602173 = body
  result = call_602171.call(nil, query_602172, nil, nil, body_602173)

var listServiceQuotaIncreaseRequestsInTemplate* = Call_ListServiceQuotaIncreaseRequestsInTemplate_602156(
    name: "listServiceQuotaIncreaseRequestsInTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.ListServiceQuotaIncreaseRequestsInTemplate",
    validator: validate_ListServiceQuotaIncreaseRequestsInTemplate_602157,
    base: "/", url: url_ListServiceQuotaIncreaseRequestsInTemplate_602158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceQuotas_602174 = ref object of OpenApiRestCall_601389
proc url_ListServiceQuotas_602176(protocol: Scheme; host: string; base: string;
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

proc validate_ListServiceQuotas_602175(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Lists all service quotas for the specified AWS service. This request returns a list of the service quotas for the specified service. you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
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
  var valid_602177 = query.getOrDefault("MaxResults")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "MaxResults", valid_602177
  var valid_602178 = query.getOrDefault("NextToken")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "NextToken", valid_602178
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
  var valid_602179 = header.getOrDefault("X-Amz-Target")
  valid_602179 = validateParameter(valid_602179, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListServiceQuotas"))
  if valid_602179 != nil:
    section.add "X-Amz-Target", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Signature")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Signature", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Content-Sha256", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Date")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Date", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Credential")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Credential", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Security-Token")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Security-Token", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Algorithm")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Algorithm", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-SignedHeaders", valid_602186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602188: Call_ListServiceQuotas_602174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all service quotas for the specified AWS service. This request returns a list of the service quotas for the specified service. you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ## 
  let valid = call_602188.validator(path, query, header, formData, body)
  let scheme = call_602188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602188.url(scheme.get, call_602188.host, call_602188.base,
                         call_602188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602188, url, valid)

proc call*(call_602189: Call_ListServiceQuotas_602174; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listServiceQuotas
  ## <p>Lists all service quotas for the specified AWS service. This request returns a list of the service quotas for the specified service. you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602190 = newJObject()
  var body_602191 = newJObject()
  add(query_602190, "MaxResults", newJString(MaxResults))
  add(query_602190, "NextToken", newJString(NextToken))
  if body != nil:
    body_602191 = body
  result = call_602189.call(nil, query_602190, nil, nil, body_602191)

var listServiceQuotas* = Call_ListServiceQuotas_602174(name: "listServiceQuotas",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.ListServiceQuotas",
    validator: validate_ListServiceQuotas_602175, base: "/",
    url: url_ListServiceQuotas_602176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServices_602192 = ref object of OpenApiRestCall_601389
proc url_ListServices_602194(protocol: Scheme; host: string; base: string;
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

proc validate_ListServices_602193(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the AWS services available in Service Quotas. Not all AWS services are available in Service Quotas. To list the see the list of the service quotas for a specific service, use <a>ListServiceQuotas</a>.
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
  var valid_602195 = query.getOrDefault("MaxResults")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "MaxResults", valid_602195
  var valid_602196 = query.getOrDefault("NextToken")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "NextToken", valid_602196
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
  var valid_602197 = header.getOrDefault("X-Amz-Target")
  valid_602197 = validateParameter(valid_602197, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListServices"))
  if valid_602197 != nil:
    section.add "X-Amz-Target", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Signature")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Signature", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Content-Sha256", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Date")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Date", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Credential")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Credential", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Security-Token")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Security-Token", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-Algorithm")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-Algorithm", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-SignedHeaders", valid_602204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602206: Call_ListServices_602192; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS services available in Service Quotas. Not all AWS services are available in Service Quotas. To list the see the list of the service quotas for a specific service, use <a>ListServiceQuotas</a>.
  ## 
  let valid = call_602206.validator(path, query, header, formData, body)
  let scheme = call_602206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602206.url(scheme.get, call_602206.host, call_602206.base,
                         call_602206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602206, url, valid)

proc call*(call_602207: Call_ListServices_602192; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listServices
  ## Lists the AWS services available in Service Quotas. Not all AWS services are available in Service Quotas. To list the see the list of the service quotas for a specific service, use <a>ListServiceQuotas</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602208 = newJObject()
  var body_602209 = newJObject()
  add(query_602208, "MaxResults", newJString(MaxResults))
  add(query_602208, "NextToken", newJString(NextToken))
  if body != nil:
    body_602209 = body
  result = call_602207.call(nil, query_602208, nil, nil, body_602209)

var listServices* = Call_ListServices_602192(name: "listServices",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.ListServices",
    validator: validate_ListServices_602193, base: "/", url: url_ListServices_602194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutServiceQuotaIncreaseRequestIntoTemplate_602210 = ref object of OpenApiRestCall_601389
proc url_PutServiceQuotaIncreaseRequestIntoTemplate_602212(protocol: Scheme;
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

proc validate_PutServiceQuotaIncreaseRequestIntoTemplate_602211(path: JsonNode;
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
  var valid_602213 = header.getOrDefault("X-Amz-Target")
  valid_602213 = validateParameter(valid_602213, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.PutServiceQuotaIncreaseRequestIntoTemplate"))
  if valid_602213 != nil:
    section.add "X-Amz-Target", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Signature")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Signature", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Content-Sha256", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Date")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Date", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Credential")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Credential", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-Security-Token")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Security-Token", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Algorithm")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Algorithm", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-SignedHeaders", valid_602220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602222: Call_PutServiceQuotaIncreaseRequestIntoTemplate_602210;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Defines and adds a quota to the service quota template. To add a quota to the template, you must provide the <code>ServiceCode</code>, <code>QuotaCode</code>, <code>AwsRegion</code>, and <code>DesiredValue</code>. Once you add a quota to the template, use <a>ListServiceQuotaIncreaseRequestsInTemplate</a> to see the list of quotas in the template.
  ## 
  let valid = call_602222.validator(path, query, header, formData, body)
  let scheme = call_602222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602222.url(scheme.get, call_602222.host, call_602222.base,
                         call_602222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602222, url, valid)

proc call*(call_602223: Call_PutServiceQuotaIncreaseRequestIntoTemplate_602210;
          body: JsonNode): Recallable =
  ## putServiceQuotaIncreaseRequestIntoTemplate
  ## Defines and adds a quota to the service quota template. To add a quota to the template, you must provide the <code>ServiceCode</code>, <code>QuotaCode</code>, <code>AwsRegion</code>, and <code>DesiredValue</code>. Once you add a quota to the template, use <a>ListServiceQuotaIncreaseRequestsInTemplate</a> to see the list of quotas in the template.
  ##   body: JObject (required)
  var body_602224 = newJObject()
  if body != nil:
    body_602224 = body
  result = call_602223.call(nil, nil, nil, nil, body_602224)

var putServiceQuotaIncreaseRequestIntoTemplate* = Call_PutServiceQuotaIncreaseRequestIntoTemplate_602210(
    name: "putServiceQuotaIncreaseRequestIntoTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.PutServiceQuotaIncreaseRequestIntoTemplate",
    validator: validate_PutServiceQuotaIncreaseRequestIntoTemplate_602211,
    base: "/", url: url_PutServiceQuotaIncreaseRequestIntoTemplate_602212,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RequestServiceQuotaIncrease_602225 = ref object of OpenApiRestCall_601389
proc url_RequestServiceQuotaIncrease_602227(protocol: Scheme; host: string;
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

proc validate_RequestServiceQuotaIncrease_602226(path: JsonNode; query: JsonNode;
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
  var valid_602228 = header.getOrDefault("X-Amz-Target")
  valid_602228 = validateParameter(valid_602228, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.RequestServiceQuotaIncrease"))
  if valid_602228 != nil:
    section.add "X-Amz-Target", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Signature")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Signature", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Content-Sha256", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Date")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Date", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Credential")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Credential", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Security-Token")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Security-Token", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Algorithm")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Algorithm", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-SignedHeaders", valid_602235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602237: Call_RequestServiceQuotaIncrease_602225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details of a service quota increase request. The response to this command provides the details in the <a>RequestedServiceQuotaChange</a> object. 
  ## 
  let valid = call_602237.validator(path, query, header, formData, body)
  let scheme = call_602237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602237.url(scheme.get, call_602237.host, call_602237.base,
                         call_602237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602237, url, valid)

proc call*(call_602238: Call_RequestServiceQuotaIncrease_602225; body: JsonNode): Recallable =
  ## requestServiceQuotaIncrease
  ## Retrieves the details of a service quota increase request. The response to this command provides the details in the <a>RequestedServiceQuotaChange</a> object. 
  ##   body: JObject (required)
  var body_602239 = newJObject()
  if body != nil:
    body_602239 = body
  result = call_602238.call(nil, nil, nil, nil, body_602239)

var requestServiceQuotaIncrease* = Call_RequestServiceQuotaIncrease_602225(
    name: "requestServiceQuotaIncrease", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.RequestServiceQuotaIncrease",
    validator: validate_RequestServiceQuotaIncrease_602226, base: "/",
    url: url_RequestServiceQuotaIncrease_602227,
    schemes: {Scheme.Https, Scheme.Http})
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
