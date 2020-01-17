
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  Call_AssociateServiceQuotaTemplate_605927 = ref object of OpenApiRestCall_605589
proc url_AssociateServiceQuotaTemplate_605929(protocol: Scheme; host: string;
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

proc validate_AssociateServiceQuotaTemplate_605928(path: JsonNode; query: JsonNode;
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
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.AssociateServiceQuotaTemplate"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_AssociateServiceQuotaTemplate_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the Service Quotas template with your organization so that when new accounts are created in your organization, the template submits increase requests for the specified service quotas. Use the Service Quotas template to request an increase for any adjustable quota value. After you define the Service Quotas template, use this operation to associate, or enable, the template. 
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_AssociateServiceQuotaTemplate_605927; body: JsonNode): Recallable =
  ## associateServiceQuotaTemplate
  ## Associates the Service Quotas template with your organization so that when new accounts are created in your organization, the template submits increase requests for the specified service quotas. Use the Service Quotas template to request an increase for any adjustable quota value. After you define the Service Quotas template, use this operation to associate, or enable, the template. 
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var associateServiceQuotaTemplate* = Call_AssociateServiceQuotaTemplate_605927(
    name: "associateServiceQuotaTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.AssociateServiceQuotaTemplate",
    validator: validate_AssociateServiceQuotaTemplate_605928, base: "/",
    url: url_AssociateServiceQuotaTemplate_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceQuotaIncreaseRequestFromTemplate_606196 = ref object of OpenApiRestCall_605589
proc url_DeleteServiceQuotaIncreaseRequestFromTemplate_606198(protocol: Scheme;
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

proc validate_DeleteServiceQuotaIncreaseRequestFromTemplate_606197(
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
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.DeleteServiceQuotaIncreaseRequestFromTemplate"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_DeleteServiceQuotaIncreaseRequestFromTemplate_606196;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a service quota increase request from the Service Quotas template. 
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_DeleteServiceQuotaIncreaseRequestFromTemplate_606196;
          body: JsonNode): Recallable =
  ## deleteServiceQuotaIncreaseRequestFromTemplate
  ## Removes a service quota increase request from the Service Quotas template. 
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var deleteServiceQuotaIncreaseRequestFromTemplate* = Call_DeleteServiceQuotaIncreaseRequestFromTemplate_606196(
    name: "deleteServiceQuotaIncreaseRequestFromTemplate",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.DeleteServiceQuotaIncreaseRequestFromTemplate",
    validator: validate_DeleteServiceQuotaIncreaseRequestFromTemplate_606197,
    base: "/", url: url_DeleteServiceQuotaIncreaseRequestFromTemplate_606198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceQuotaTemplate_606211 = ref object of OpenApiRestCall_605589
proc url_DisassociateServiceQuotaTemplate_606213(protocol: Scheme; host: string;
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

proc validate_DisassociateServiceQuotaTemplate_606212(path: JsonNode;
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
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.DisassociateServiceQuotaTemplate"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_DisassociateServiceQuotaTemplate_606211;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Disables the Service Quotas template. Once the template is disabled, it does not request quota increases for new accounts in your organization. Disabling the quota template does not apply the quota increase requests from the template. </p> <p> <b>Related operations</b> </p> <ul> <li> <p>To enable the quota template, call <a>AssociateServiceQuotaTemplate</a>. </p> </li> <li> <p>To delete a specific service quota from the template, use <a>DeleteServiceQuotaIncreaseRequestFromTemplate</a>.</p> </li> </ul>
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_DisassociateServiceQuotaTemplate_606211;
          body: JsonNode): Recallable =
  ## disassociateServiceQuotaTemplate
  ## <p>Disables the Service Quotas template. Once the template is disabled, it does not request quota increases for new accounts in your organization. Disabling the quota template does not apply the quota increase requests from the template. </p> <p> <b>Related operations</b> </p> <ul> <li> <p>To enable the quota template, call <a>AssociateServiceQuotaTemplate</a>. </p> </li> <li> <p>To delete a specific service quota from the template, use <a>DeleteServiceQuotaIncreaseRequestFromTemplate</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var disassociateServiceQuotaTemplate* = Call_DisassociateServiceQuotaTemplate_606211(
    name: "disassociateServiceQuotaTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.DisassociateServiceQuotaTemplate",
    validator: validate_DisassociateServiceQuotaTemplate_606212, base: "/",
    url: url_DisassociateServiceQuotaTemplate_606213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAWSDefaultServiceQuota_606226 = ref object of OpenApiRestCall_605589
proc url_GetAWSDefaultServiceQuota_606228(protocol: Scheme; host: string;
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

proc validate_GetAWSDefaultServiceQuota_606227(path: JsonNode; query: JsonNode;
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
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetAWSDefaultServiceQuota"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_GetAWSDefaultServiceQuota_606226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the default service quotas values. The Value returned for each quota is the AWS default value, even if the quotas have been increased.. 
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_GetAWSDefaultServiceQuota_606226; body: JsonNode): Recallable =
  ## getAWSDefaultServiceQuota
  ## Retrieves the default service quotas values. The Value returned for each quota is the AWS default value, even if the quotas have been increased.. 
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var getAWSDefaultServiceQuota* = Call_GetAWSDefaultServiceQuota_606226(
    name: "getAWSDefaultServiceQuota", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.GetAWSDefaultServiceQuota",
    validator: validate_GetAWSDefaultServiceQuota_606227, base: "/",
    url: url_GetAWSDefaultServiceQuota_606228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssociationForServiceQuotaTemplate_606241 = ref object of OpenApiRestCall_605589
proc url_GetAssociationForServiceQuotaTemplate_606243(protocol: Scheme;
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

proc validate_GetAssociationForServiceQuotaTemplate_606242(path: JsonNode;
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
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetAssociationForServiceQuotaTemplate"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_GetAssociationForServiceQuotaTemplate_606241;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the <code>ServiceQuotaTemplateAssociationStatus</code> value from the service. Use this action to determine if the Service Quota template is associated, or enabled. 
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_GetAssociationForServiceQuotaTemplate_606241;
          body: JsonNode): Recallable =
  ## getAssociationForServiceQuotaTemplate
  ## Retrieves the <code>ServiceQuotaTemplateAssociationStatus</code> value from the service. Use this action to determine if the Service Quota template is associated, or enabled. 
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var getAssociationForServiceQuotaTemplate* = Call_GetAssociationForServiceQuotaTemplate_606241(
    name: "getAssociationForServiceQuotaTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.GetAssociationForServiceQuotaTemplate",
    validator: validate_GetAssociationForServiceQuotaTemplate_606242, base: "/",
    url: url_GetAssociationForServiceQuotaTemplate_606243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestedServiceQuotaChange_606256 = ref object of OpenApiRestCall_605589
proc url_GetRequestedServiceQuotaChange_606258(protocol: Scheme; host: string;
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

proc validate_GetRequestedServiceQuotaChange_606257(path: JsonNode;
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
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetRequestedServiceQuotaChange"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_GetRequestedServiceQuotaChange_606256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details for a particular increase request. 
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_GetRequestedServiceQuotaChange_606256; body: JsonNode): Recallable =
  ## getRequestedServiceQuotaChange
  ## Retrieves the details for a particular increase request. 
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var getRequestedServiceQuotaChange* = Call_GetRequestedServiceQuotaChange_606256(
    name: "getRequestedServiceQuotaChange", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.GetRequestedServiceQuotaChange",
    validator: validate_GetRequestedServiceQuotaChange_606257, base: "/",
    url: url_GetRequestedServiceQuotaChange_606258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceQuota_606271 = ref object of OpenApiRestCall_605589
proc url_GetServiceQuota_606273(protocol: Scheme; host: string; base: string;
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

proc validate_GetServiceQuota_606272(path: JsonNode; query: JsonNode;
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
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetServiceQuota"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_GetServiceQuota_606271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details for the specified service quota. This operation provides a different Value than the <code>GetAWSDefaultServiceQuota</code> operation. This operation returns the applied value for each quota. <code>GetAWSDefaultServiceQuota</code> returns the default AWS value for each quota. 
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_GetServiceQuota_606271; body: JsonNode): Recallable =
  ## getServiceQuota
  ## Returns the details for the specified service quota. This operation provides a different Value than the <code>GetAWSDefaultServiceQuota</code> operation. This operation returns the applied value for each quota. <code>GetAWSDefaultServiceQuota</code> returns the default AWS value for each quota. 
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var getServiceQuota* = Call_GetServiceQuota_606271(name: "getServiceQuota",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.GetServiceQuota",
    validator: validate_GetServiceQuota_606272, base: "/", url: url_GetServiceQuota_606273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceQuotaIncreaseRequestFromTemplate_606286 = ref object of OpenApiRestCall_605589
proc url_GetServiceQuotaIncreaseRequestFromTemplate_606288(protocol: Scheme;
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

proc validate_GetServiceQuotaIncreaseRequestFromTemplate_606287(path: JsonNode;
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
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetServiceQuotaIncreaseRequestFromTemplate"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_GetServiceQuotaIncreaseRequestFromTemplate_606286;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the details of the service quota increase request in your template.
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_GetServiceQuotaIncreaseRequestFromTemplate_606286;
          body: JsonNode): Recallable =
  ## getServiceQuotaIncreaseRequestFromTemplate
  ## Returns the details of the service quota increase request in your template.
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var getServiceQuotaIncreaseRequestFromTemplate* = Call_GetServiceQuotaIncreaseRequestFromTemplate_606286(
    name: "getServiceQuotaIncreaseRequestFromTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.GetServiceQuotaIncreaseRequestFromTemplate",
    validator: validate_GetServiceQuotaIncreaseRequestFromTemplate_606287,
    base: "/", url: url_GetServiceQuotaIncreaseRequestFromTemplate_606288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAWSDefaultServiceQuotas_606301 = ref object of OpenApiRestCall_605589
proc url_ListAWSDefaultServiceQuotas_606303(protocol: Scheme; host: string;
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

proc validate_ListAWSDefaultServiceQuotas_606302(path: JsonNode; query: JsonNode;
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
  var valid_606304 = query.getOrDefault("MaxResults")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "MaxResults", valid_606304
  var valid_606305 = query.getOrDefault("NextToken")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "NextToken", valid_606305
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
  var valid_606306 = header.getOrDefault("X-Amz-Target")
  valid_606306 = validateParameter(valid_606306, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListAWSDefaultServiceQuotas"))
  if valid_606306 != nil:
    section.add "X-Amz-Target", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Signature")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Signature", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Content-Sha256", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Date")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Date", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Credential")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Credential", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Security-Token")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Security-Token", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Algorithm")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Algorithm", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-SignedHeaders", valid_606313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606315: Call_ListAWSDefaultServiceQuotas_606301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all default service quotas for the specified AWS service or all AWS services. ListAWSDefaultServiceQuotas is similar to <a>ListServiceQuotas</a> except for the Value object. The Value object returned by <code>ListAWSDefaultServiceQuotas</code> is the default value assigned by AWS. This request returns a list of all service quotas for the specified service. The listing of each you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ## 
  let valid = call_606315.validator(path, query, header, formData, body)
  let scheme = call_606315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606315.url(scheme.get, call_606315.host, call_606315.base,
                         call_606315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606315, url, valid)

proc call*(call_606316: Call_ListAWSDefaultServiceQuotas_606301; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAWSDefaultServiceQuotas
  ## <p>Lists all default service quotas for the specified AWS service or all AWS services. ListAWSDefaultServiceQuotas is similar to <a>ListServiceQuotas</a> except for the Value object. The Value object returned by <code>ListAWSDefaultServiceQuotas</code> is the default value assigned by AWS. This request returns a list of all service quotas for the specified service. The listing of each you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606317 = newJObject()
  var body_606318 = newJObject()
  add(query_606317, "MaxResults", newJString(MaxResults))
  add(query_606317, "NextToken", newJString(NextToken))
  if body != nil:
    body_606318 = body
  result = call_606316.call(nil, query_606317, nil, nil, body_606318)

var listAWSDefaultServiceQuotas* = Call_ListAWSDefaultServiceQuotas_606301(
    name: "listAWSDefaultServiceQuotas", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.ListAWSDefaultServiceQuotas",
    validator: validate_ListAWSDefaultServiceQuotas_606302, base: "/",
    url: url_ListAWSDefaultServiceQuotas_606303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRequestedServiceQuotaChangeHistory_606320 = ref object of OpenApiRestCall_605589
proc url_ListRequestedServiceQuotaChangeHistory_606322(protocol: Scheme;
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

proc validate_ListRequestedServiceQuotaChangeHistory_606321(path: JsonNode;
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
  var valid_606323 = query.getOrDefault("MaxResults")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "MaxResults", valid_606323
  var valid_606324 = query.getOrDefault("NextToken")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "NextToken", valid_606324
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
  var valid_606325 = header.getOrDefault("X-Amz-Target")
  valid_606325 = validateParameter(valid_606325, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistory"))
  if valid_606325 != nil:
    section.add "X-Amz-Target", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Signature")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Signature", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Content-Sha256", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Date")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Date", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Credential")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Credential", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-Security-Token")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-Security-Token", valid_606330
  var valid_606331 = header.getOrDefault("X-Amz-Algorithm")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Algorithm", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-SignedHeaders", valid_606332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606334: Call_ListRequestedServiceQuotaChangeHistory_606320;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Requests a list of the changes to quotas for a service.
  ## 
  let valid = call_606334.validator(path, query, header, formData, body)
  let scheme = call_606334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606334.url(scheme.get, call_606334.host, call_606334.base,
                         call_606334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606334, url, valid)

proc call*(call_606335: Call_ListRequestedServiceQuotaChangeHistory_606320;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listRequestedServiceQuotaChangeHistory
  ## Requests a list of the changes to quotas for a service.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606336 = newJObject()
  var body_606337 = newJObject()
  add(query_606336, "MaxResults", newJString(MaxResults))
  add(query_606336, "NextToken", newJString(NextToken))
  if body != nil:
    body_606337 = body
  result = call_606335.call(nil, query_606336, nil, nil, body_606337)

var listRequestedServiceQuotaChangeHistory* = Call_ListRequestedServiceQuotaChangeHistory_606320(
    name: "listRequestedServiceQuotaChangeHistory", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistory",
    validator: validate_ListRequestedServiceQuotaChangeHistory_606321, base: "/",
    url: url_ListRequestedServiceQuotaChangeHistory_606322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRequestedServiceQuotaChangeHistoryByQuota_606338 = ref object of OpenApiRestCall_605589
proc url_ListRequestedServiceQuotaChangeHistoryByQuota_606340(protocol: Scheme;
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

proc validate_ListRequestedServiceQuotaChangeHistoryByQuota_606339(
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
  var valid_606341 = query.getOrDefault("MaxResults")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "MaxResults", valid_606341
  var valid_606342 = query.getOrDefault("NextToken")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "NextToken", valid_606342
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
  var valid_606343 = header.getOrDefault("X-Amz-Target")
  valid_606343 = validateParameter(valid_606343, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistoryByQuota"))
  if valid_606343 != nil:
    section.add "X-Amz-Target", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Signature")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Signature", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Content-Sha256", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Date")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Date", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Credential")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Credential", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Security-Token")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Security-Token", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-Algorithm")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Algorithm", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-SignedHeaders", valid_606350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606352: Call_ListRequestedServiceQuotaChangeHistoryByQuota_606338;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Requests a list of the changes to specific service quotas. This command provides additional granularity over the <code>ListRequestedServiceQuotaChangeHistory</code> command. Once a quota change request has reached <code>CASE_CLOSED, APPROVED,</code> or <code>DENIED</code>, the history has been kept for 90 days.
  ## 
  let valid = call_606352.validator(path, query, header, formData, body)
  let scheme = call_606352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606352.url(scheme.get, call_606352.host, call_606352.base,
                         call_606352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606352, url, valid)

proc call*(call_606353: Call_ListRequestedServiceQuotaChangeHistoryByQuota_606338;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listRequestedServiceQuotaChangeHistoryByQuota
  ## Requests a list of the changes to specific service quotas. This command provides additional granularity over the <code>ListRequestedServiceQuotaChangeHistory</code> command. Once a quota change request has reached <code>CASE_CLOSED, APPROVED,</code> or <code>DENIED</code>, the history has been kept for 90 days.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606354 = newJObject()
  var body_606355 = newJObject()
  add(query_606354, "MaxResults", newJString(MaxResults))
  add(query_606354, "NextToken", newJString(NextToken))
  if body != nil:
    body_606355 = body
  result = call_606353.call(nil, query_606354, nil, nil, body_606355)

var listRequestedServiceQuotaChangeHistoryByQuota* = Call_ListRequestedServiceQuotaChangeHistoryByQuota_606338(
    name: "listRequestedServiceQuotaChangeHistoryByQuota",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistoryByQuota",
    validator: validate_ListRequestedServiceQuotaChangeHistoryByQuota_606339,
    base: "/", url: url_ListRequestedServiceQuotaChangeHistoryByQuota_606340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceQuotaIncreaseRequestsInTemplate_606356 = ref object of OpenApiRestCall_605589
proc url_ListServiceQuotaIncreaseRequestsInTemplate_606358(protocol: Scheme;
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

proc validate_ListServiceQuotaIncreaseRequestsInTemplate_606357(path: JsonNode;
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
  var valid_606359 = query.getOrDefault("MaxResults")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "MaxResults", valid_606359
  var valid_606360 = query.getOrDefault("NextToken")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "NextToken", valid_606360
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
  var valid_606361 = header.getOrDefault("X-Amz-Target")
  valid_606361 = validateParameter(valid_606361, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListServiceQuotaIncreaseRequestsInTemplate"))
  if valid_606361 != nil:
    section.add "X-Amz-Target", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Signature")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Signature", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Content-Sha256", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-Date")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Date", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Credential")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Credential", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Security-Token")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Security-Token", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Algorithm")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Algorithm", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-SignedHeaders", valid_606368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606370: Call_ListServiceQuotaIncreaseRequestsInTemplate_606356;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of the quota increase requests in the template. 
  ## 
  let valid = call_606370.validator(path, query, header, formData, body)
  let scheme = call_606370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606370.url(scheme.get, call_606370.host, call_606370.base,
                         call_606370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606370, url, valid)

proc call*(call_606371: Call_ListServiceQuotaIncreaseRequestsInTemplate_606356;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listServiceQuotaIncreaseRequestsInTemplate
  ## Returns a list of the quota increase requests in the template. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606372 = newJObject()
  var body_606373 = newJObject()
  add(query_606372, "MaxResults", newJString(MaxResults))
  add(query_606372, "NextToken", newJString(NextToken))
  if body != nil:
    body_606373 = body
  result = call_606371.call(nil, query_606372, nil, nil, body_606373)

var listServiceQuotaIncreaseRequestsInTemplate* = Call_ListServiceQuotaIncreaseRequestsInTemplate_606356(
    name: "listServiceQuotaIncreaseRequestsInTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.ListServiceQuotaIncreaseRequestsInTemplate",
    validator: validate_ListServiceQuotaIncreaseRequestsInTemplate_606357,
    base: "/", url: url_ListServiceQuotaIncreaseRequestsInTemplate_606358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceQuotas_606374 = ref object of OpenApiRestCall_605589
proc url_ListServiceQuotas_606376(protocol: Scheme; host: string; base: string;
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

proc validate_ListServiceQuotas_606375(path: JsonNode; query: JsonNode;
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
  var valid_606377 = query.getOrDefault("MaxResults")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "MaxResults", valid_606377
  var valid_606378 = query.getOrDefault("NextToken")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "NextToken", valid_606378
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
  var valid_606379 = header.getOrDefault("X-Amz-Target")
  valid_606379 = validateParameter(valid_606379, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListServiceQuotas"))
  if valid_606379 != nil:
    section.add "X-Amz-Target", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Signature")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Signature", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Content-Sha256", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Date")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Date", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Credential")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Credential", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Security-Token")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Security-Token", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Algorithm")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Algorithm", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-SignedHeaders", valid_606386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_ListServiceQuotas_606374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all service quotas for the specified AWS service. This request returns a list of the service quotas for the specified service. you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ## 
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_ListServiceQuotas_606374; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listServiceQuotas
  ## <p>Lists all service quotas for the specified AWS service. This request returns a list of the service quotas for the specified service. you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606390 = newJObject()
  var body_606391 = newJObject()
  add(query_606390, "MaxResults", newJString(MaxResults))
  add(query_606390, "NextToken", newJString(NextToken))
  if body != nil:
    body_606391 = body
  result = call_606389.call(nil, query_606390, nil, nil, body_606391)

var listServiceQuotas* = Call_ListServiceQuotas_606374(name: "listServiceQuotas",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.ListServiceQuotas",
    validator: validate_ListServiceQuotas_606375, base: "/",
    url: url_ListServiceQuotas_606376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServices_606392 = ref object of OpenApiRestCall_605589
proc url_ListServices_606394(protocol: Scheme; host: string; base: string;
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

proc validate_ListServices_606393(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606395 = query.getOrDefault("MaxResults")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "MaxResults", valid_606395
  var valid_606396 = query.getOrDefault("NextToken")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "NextToken", valid_606396
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
  var valid_606397 = header.getOrDefault("X-Amz-Target")
  valid_606397 = validateParameter(valid_606397, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListServices"))
  if valid_606397 != nil:
    section.add "X-Amz-Target", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Signature")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Signature", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Content-Sha256", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Date")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Date", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Credential")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Credential", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-Security-Token")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Security-Token", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Algorithm")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Algorithm", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-SignedHeaders", valid_606404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606406: Call_ListServices_606392; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS services available in Service Quotas. Not all AWS services are available in Service Quotas. To list the see the list of the service quotas for a specific service, use <a>ListServiceQuotas</a>.
  ## 
  let valid = call_606406.validator(path, query, header, formData, body)
  let scheme = call_606406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606406.url(scheme.get, call_606406.host, call_606406.base,
                         call_606406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606406, url, valid)

proc call*(call_606407: Call_ListServices_606392; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listServices
  ## Lists the AWS services available in Service Quotas. Not all AWS services are available in Service Quotas. To list the see the list of the service quotas for a specific service, use <a>ListServiceQuotas</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606408 = newJObject()
  var body_606409 = newJObject()
  add(query_606408, "MaxResults", newJString(MaxResults))
  add(query_606408, "NextToken", newJString(NextToken))
  if body != nil:
    body_606409 = body
  result = call_606407.call(nil, query_606408, nil, nil, body_606409)

var listServices* = Call_ListServices_606392(name: "listServices",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.ListServices",
    validator: validate_ListServices_606393, base: "/", url: url_ListServices_606394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutServiceQuotaIncreaseRequestIntoTemplate_606410 = ref object of OpenApiRestCall_605589
proc url_PutServiceQuotaIncreaseRequestIntoTemplate_606412(protocol: Scheme;
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

proc validate_PutServiceQuotaIncreaseRequestIntoTemplate_606411(path: JsonNode;
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
  var valid_606413 = header.getOrDefault("X-Amz-Target")
  valid_606413 = validateParameter(valid_606413, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.PutServiceQuotaIncreaseRequestIntoTemplate"))
  if valid_606413 != nil:
    section.add "X-Amz-Target", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Signature")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Signature", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Content-Sha256", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Date")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Date", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Credential")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Credential", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Security-Token")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Security-Token", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Algorithm")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Algorithm", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-SignedHeaders", valid_606420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606422: Call_PutServiceQuotaIncreaseRequestIntoTemplate_606410;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Defines and adds a quota to the service quota template. To add a quota to the template, you must provide the <code>ServiceCode</code>, <code>QuotaCode</code>, <code>AwsRegion</code>, and <code>DesiredValue</code>. Once you add a quota to the template, use <a>ListServiceQuotaIncreaseRequestsInTemplate</a> to see the list of quotas in the template.
  ## 
  let valid = call_606422.validator(path, query, header, formData, body)
  let scheme = call_606422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606422.url(scheme.get, call_606422.host, call_606422.base,
                         call_606422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606422, url, valid)

proc call*(call_606423: Call_PutServiceQuotaIncreaseRequestIntoTemplate_606410;
          body: JsonNode): Recallable =
  ## putServiceQuotaIncreaseRequestIntoTemplate
  ## Defines and adds a quota to the service quota template. To add a quota to the template, you must provide the <code>ServiceCode</code>, <code>QuotaCode</code>, <code>AwsRegion</code>, and <code>DesiredValue</code>. Once you add a quota to the template, use <a>ListServiceQuotaIncreaseRequestsInTemplate</a> to see the list of quotas in the template.
  ##   body: JObject (required)
  var body_606424 = newJObject()
  if body != nil:
    body_606424 = body
  result = call_606423.call(nil, nil, nil, nil, body_606424)

var putServiceQuotaIncreaseRequestIntoTemplate* = Call_PutServiceQuotaIncreaseRequestIntoTemplate_606410(
    name: "putServiceQuotaIncreaseRequestIntoTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.PutServiceQuotaIncreaseRequestIntoTemplate",
    validator: validate_PutServiceQuotaIncreaseRequestIntoTemplate_606411,
    base: "/", url: url_PutServiceQuotaIncreaseRequestIntoTemplate_606412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RequestServiceQuotaIncrease_606425 = ref object of OpenApiRestCall_605589
proc url_RequestServiceQuotaIncrease_606427(protocol: Scheme; host: string;
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

proc validate_RequestServiceQuotaIncrease_606426(path: JsonNode; query: JsonNode;
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
  var valid_606428 = header.getOrDefault("X-Amz-Target")
  valid_606428 = validateParameter(valid_606428, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.RequestServiceQuotaIncrease"))
  if valid_606428 != nil:
    section.add "X-Amz-Target", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Signature")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Signature", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Content-Sha256", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Date")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Date", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Credential")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Credential", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Security-Token")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Security-Token", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Algorithm")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Algorithm", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-SignedHeaders", valid_606435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606437: Call_RequestServiceQuotaIncrease_606425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the details of a service quota increase request. The response to this command provides the details in the <a>RequestedServiceQuotaChange</a> object. 
  ## 
  let valid = call_606437.validator(path, query, header, formData, body)
  let scheme = call_606437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606437.url(scheme.get, call_606437.host, call_606437.base,
                         call_606437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606437, url, valid)

proc call*(call_606438: Call_RequestServiceQuotaIncrease_606425; body: JsonNode): Recallable =
  ## requestServiceQuotaIncrease
  ## Retrieves the details of a service quota increase request. The response to this command provides the details in the <a>RequestedServiceQuotaChange</a> object. 
  ##   body: JObject (required)
  var body_606439 = newJObject()
  if body != nil:
    body_606439 = body
  result = call_606438.call(nil, nil, nil, nil, body_606439)

var requestServiceQuotaIncrease* = Call_RequestServiceQuotaIncrease_606425(
    name: "requestServiceQuotaIncrease", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.RequestServiceQuotaIncrease",
    validator: validate_RequestServiceQuotaIncrease_606426, base: "/",
    url: url_RequestServiceQuotaIncrease_606427,
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
