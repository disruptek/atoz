
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "servicequotas.ap-northeast-1.amazonaws.com", "ap-southeast-1": "servicequotas.ap-southeast-1.amazonaws.com", "us-west-2": "servicequotas.us-west-2.amazonaws.com", "eu-west-2": "servicequotas.eu-west-2.amazonaws.com", "ap-northeast-3": "servicequotas.ap-northeast-3.amazonaws.com", "eu-central-1": "servicequotas.eu-central-1.amazonaws.com", "us-east-2": "servicequotas.us-east-2.amazonaws.com", "us-east-1": "servicequotas.us-east-1.amazonaws.com", "cn-northwest-1": "servicequotas.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "servicequotas.ap-south-1.amazonaws.com", "eu-north-1": "servicequotas.eu-north-1.amazonaws.com", "ap-northeast-2": "servicequotas.ap-northeast-2.amazonaws.com", "us-west-1": "servicequotas.us-west-1.amazonaws.com", "us-gov-east-1": "servicequotas.us-gov-east-1.amazonaws.com", "eu-west-3": "servicequotas.eu-west-3.amazonaws.com", "cn-north-1": "servicequotas.cn-north-1.amazonaws.com.cn", "sa-east-1": "servicequotas.sa-east-1.amazonaws.com", "eu-west-1": "servicequotas.eu-west-1.amazonaws.com", "us-gov-west-1": "servicequotas.us-gov-west-1.amazonaws.com", "ap-southeast-2": "servicequotas.ap-southeast-2.amazonaws.com", "ca-central-1": "servicequotas.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AssociateServiceQuotaTemplate_402656288 = ref object of OpenApiRestCall_402656038
proc url_AssociateServiceQuotaTemplate_402656290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateServiceQuotaTemplate_402656289(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656384 = header.getOrDefault("X-Amz-Target")
  valid_402656384 = validateParameter(valid_402656384, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.AssociateServiceQuotaTemplate"))
  if valid_402656384 != nil:
    section.add "X-Amz-Target", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Security-Token", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Signature")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Signature", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Algorithm", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Date")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Date", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-Credential")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-Credential", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656391
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

proc call*(call_402656406: Call_AssociateServiceQuotaTemplate_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the Service Quotas template with your organization so that when new accounts are created in your organization, the template submits increase requests for the specified service quotas. Use the Service Quotas template to request an increase for any adjustable quota value. After you define the Service Quotas template, use this operation to associate, or enable, the template. 
                                                                                         ## 
  let valid = call_402656406.validator(path, query, header, formData, body, _)
  let scheme = call_402656406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656406.makeUrl(scheme.get, call_402656406.host, call_402656406.base,
                                   call_402656406.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656406, uri, valid, _)

proc call*(call_402656455: Call_AssociateServiceQuotaTemplate_402656288;
           body: JsonNode): Recallable =
  ## associateServiceQuotaTemplate
  ## Associates the Service Quotas template with your organization so that when new accounts are created in your organization, the template submits increase requests for the specified service quotas. Use the Service Quotas template to request an increase for any adjustable quota value. After you define the Service Quotas template, use this operation to associate, or enable, the template. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656456 = newJObject()
  if body != nil:
    body_402656456 = body
  result = call_402656455.call(nil, nil, nil, nil, body_402656456)

var associateServiceQuotaTemplate* = Call_AssociateServiceQuotaTemplate_402656288(
    name: "associateServiceQuotaTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.AssociateServiceQuotaTemplate",
    validator: validate_AssociateServiceQuotaTemplate_402656289, base: "/",
    makeUrl: url_AssociateServiceQuotaTemplate_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceQuotaIncreaseRequestFromTemplate_402656483 = ref object of OpenApiRestCall_402656038
proc url_DeleteServiceQuotaIncreaseRequestFromTemplate_402656485(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteServiceQuotaIncreaseRequestFromTemplate_402656484(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656486 = header.getOrDefault("X-Amz-Target")
  valid_402656486 = validateParameter(valid_402656486, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.DeleteServiceQuotaIncreaseRequestFromTemplate"))
  if valid_402656486 != nil:
    section.add "X-Amz-Target", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Security-Token", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Signature")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Signature", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Algorithm", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-Date")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Date", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Credential")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Credential", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656493
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

proc call*(call_402656495: Call_DeleteServiceQuotaIncreaseRequestFromTemplate_402656483;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a service quota increase request from the Service Quotas template. 
                                                                                         ## 
  let valid = call_402656495.validator(path, query, header, formData, body, _)
  let scheme = call_402656495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656495.makeUrl(scheme.get, call_402656495.host, call_402656495.base,
                                   call_402656495.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656495, uri, valid, _)

proc call*(call_402656496: Call_DeleteServiceQuotaIncreaseRequestFromTemplate_402656483;
           body: JsonNode): Recallable =
  ## deleteServiceQuotaIncreaseRequestFromTemplate
  ## Removes a service quota increase request from the Service Quotas template. 
  ##   
                                                                                ## body: JObject (required)
  var body_402656497 = newJObject()
  if body != nil:
    body_402656497 = body
  result = call_402656496.call(nil, nil, nil, nil, body_402656497)

var deleteServiceQuotaIncreaseRequestFromTemplate* = Call_DeleteServiceQuotaIncreaseRequestFromTemplate_402656483(
    name: "deleteServiceQuotaIncreaseRequestFromTemplate",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.DeleteServiceQuotaIncreaseRequestFromTemplate",
    validator: validate_DeleteServiceQuotaIncreaseRequestFromTemplate_402656484,
    base: "/", makeUrl: url_DeleteServiceQuotaIncreaseRequestFromTemplate_402656485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceQuotaTemplate_402656498 = ref object of OpenApiRestCall_402656038
proc url_DisassociateServiceQuotaTemplate_402656500(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateServiceQuotaTemplate_402656499(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656501 = header.getOrDefault("X-Amz-Target")
  valid_402656501 = validateParameter(valid_402656501, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.DisassociateServiceQuotaTemplate"))
  if valid_402656501 != nil:
    section.add "X-Amz-Target", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Security-Token", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Signature")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Signature", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Algorithm", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Date")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Date", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Credential")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Credential", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656508
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

proc call*(call_402656510: Call_DisassociateServiceQuotaTemplate_402656498;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disables the Service Quotas template. Once the template is disabled, it does not request quota increases for new accounts in your organization. Disabling the quota template does not apply the quota increase requests from the template. </p> <p> <b>Related operations</b> </p> <ul> <li> <p>To enable the quota template, call <a>AssociateServiceQuotaTemplate</a>. </p> </li> <li> <p>To delete a specific service quota from the template, use <a>DeleteServiceQuotaIncreaseRequestFromTemplate</a>.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656510.validator(path, query, header, formData, body, _)
  let scheme = call_402656510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656510.makeUrl(scheme.get, call_402656510.host, call_402656510.base,
                                   call_402656510.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656510, uri, valid, _)

proc call*(call_402656511: Call_DisassociateServiceQuotaTemplate_402656498;
           body: JsonNode): Recallable =
  ## disassociateServiceQuotaTemplate
  ## <p>Disables the Service Quotas template. Once the template is disabled, it does not request quota increases for new accounts in your organization. Disabling the quota template does not apply the quota increase requests from the template. </p> <p> <b>Related operations</b> </p> <ul> <li> <p>To enable the quota template, call <a>AssociateServiceQuotaTemplate</a>. </p> </li> <li> <p>To delete a specific service quota from the template, use <a>DeleteServiceQuotaIncreaseRequestFromTemplate</a>.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656512 = newJObject()
  if body != nil:
    body_402656512 = body
  result = call_402656511.call(nil, nil, nil, nil, body_402656512)

var disassociateServiceQuotaTemplate* = Call_DisassociateServiceQuotaTemplate_402656498(
    name: "disassociateServiceQuotaTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.DisassociateServiceQuotaTemplate",
    validator: validate_DisassociateServiceQuotaTemplate_402656499, base: "/",
    makeUrl: url_DisassociateServiceQuotaTemplate_402656500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAWSDefaultServiceQuota_402656513 = ref object of OpenApiRestCall_402656038
proc url_GetAWSDefaultServiceQuota_402656515(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAWSDefaultServiceQuota_402656514(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656516 = header.getOrDefault("X-Amz-Target")
  valid_402656516 = validateParameter(valid_402656516, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetAWSDefaultServiceQuota"))
  if valid_402656516 != nil:
    section.add "X-Amz-Target", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Security-Token", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Signature")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Signature", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Algorithm", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Date")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Date", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Credential")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Credential", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656523
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

proc call*(call_402656525: Call_GetAWSDefaultServiceQuota_402656513;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the default service quotas values. The Value returned for each quota is the AWS default value, even if the quotas have been increased.. 
                                                                                         ## 
  let valid = call_402656525.validator(path, query, header, formData, body, _)
  let scheme = call_402656525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656525.makeUrl(scheme.get, call_402656525.host, call_402656525.base,
                                   call_402656525.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656525, uri, valid, _)

proc call*(call_402656526: Call_GetAWSDefaultServiceQuota_402656513;
           body: JsonNode): Recallable =
  ## getAWSDefaultServiceQuota
  ## Retrieves the default service quotas values. The Value returned for each quota is the AWS default value, even if the quotas have been increased.. 
  ##   
                                                                                                                                                       ## body: JObject (required)
  var body_402656527 = newJObject()
  if body != nil:
    body_402656527 = body
  result = call_402656526.call(nil, nil, nil, nil, body_402656527)

var getAWSDefaultServiceQuota* = Call_GetAWSDefaultServiceQuota_402656513(
    name: "getAWSDefaultServiceQuota", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.GetAWSDefaultServiceQuota",
    validator: validate_GetAWSDefaultServiceQuota_402656514, base: "/",
    makeUrl: url_GetAWSDefaultServiceQuota_402656515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssociationForServiceQuotaTemplate_402656528 = ref object of OpenApiRestCall_402656038
proc url_GetAssociationForServiceQuotaTemplate_402656530(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAssociationForServiceQuotaTemplate_402656529(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656531 = header.getOrDefault("X-Amz-Target")
  valid_402656531 = validateParameter(valid_402656531, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetAssociationForServiceQuotaTemplate"))
  if valid_402656531 != nil:
    section.add "X-Amz-Target", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Security-Token", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Signature")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Signature", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Algorithm", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Date")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Date", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Credential")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Credential", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656538
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

proc call*(call_402656540: Call_GetAssociationForServiceQuotaTemplate_402656528;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the <code>ServiceQuotaTemplateAssociationStatus</code> value from the service. Use this action to determine if the Service Quota template is associated, or enabled. 
                                                                                         ## 
  let valid = call_402656540.validator(path, query, header, formData, body, _)
  let scheme = call_402656540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656540.makeUrl(scheme.get, call_402656540.host, call_402656540.base,
                                   call_402656540.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656540, uri, valid, _)

proc call*(call_402656541: Call_GetAssociationForServiceQuotaTemplate_402656528;
           body: JsonNode): Recallable =
  ## getAssociationForServiceQuotaTemplate
  ## Retrieves the <code>ServiceQuotaTemplateAssociationStatus</code> value from the service. Use this action to determine if the Service Quota template is associated, or enabled. 
  ##   
                                                                                                                                                                                    ## body: JObject (required)
  var body_402656542 = newJObject()
  if body != nil:
    body_402656542 = body
  result = call_402656541.call(nil, nil, nil, nil, body_402656542)

var getAssociationForServiceQuotaTemplate* = Call_GetAssociationForServiceQuotaTemplate_402656528(
    name: "getAssociationForServiceQuotaTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.GetAssociationForServiceQuotaTemplate",
    validator: validate_GetAssociationForServiceQuotaTemplate_402656529,
    base: "/", makeUrl: url_GetAssociationForServiceQuotaTemplate_402656530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestedServiceQuotaChange_402656543 = ref object of OpenApiRestCall_402656038
proc url_GetRequestedServiceQuotaChange_402656545(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRequestedServiceQuotaChange_402656544(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656546 = header.getOrDefault("X-Amz-Target")
  valid_402656546 = validateParameter(valid_402656546, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetRequestedServiceQuotaChange"))
  if valid_402656546 != nil:
    section.add "X-Amz-Target", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Security-Token", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Signature")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Signature", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Algorithm", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Date")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Date", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Credential")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Credential", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656553
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

proc call*(call_402656555: Call_GetRequestedServiceQuotaChange_402656543;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the details for a particular increase request. 
                                                                                         ## 
  let valid = call_402656555.validator(path, query, header, formData, body, _)
  let scheme = call_402656555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656555.makeUrl(scheme.get, call_402656555.host, call_402656555.base,
                                   call_402656555.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656555, uri, valid, _)

proc call*(call_402656556: Call_GetRequestedServiceQuotaChange_402656543;
           body: JsonNode): Recallable =
  ## getRequestedServiceQuotaChange
  ## Retrieves the details for a particular increase request. 
  ##   body: JObject (required)
  var body_402656557 = newJObject()
  if body != nil:
    body_402656557 = body
  result = call_402656556.call(nil, nil, nil, nil, body_402656557)

var getRequestedServiceQuotaChange* = Call_GetRequestedServiceQuotaChange_402656543(
    name: "getRequestedServiceQuotaChange", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.GetRequestedServiceQuotaChange",
    validator: validate_GetRequestedServiceQuotaChange_402656544, base: "/",
    makeUrl: url_GetRequestedServiceQuotaChange_402656545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceQuota_402656558 = ref object of OpenApiRestCall_402656038
proc url_GetServiceQuota_402656560(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServiceQuota_402656559(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656561 = header.getOrDefault("X-Amz-Target")
  valid_402656561 = validateParameter(valid_402656561, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetServiceQuota"))
  if valid_402656561 != nil:
    section.add "X-Amz-Target", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Security-Token", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Signature")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Signature", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Algorithm", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Date")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Date", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Credential")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Credential", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656568
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

proc call*(call_402656570: Call_GetServiceQuota_402656558; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the details for the specified service quota. This operation provides a different Value than the <code>GetAWSDefaultServiceQuota</code> operation. This operation returns the applied value for each quota. <code>GetAWSDefaultServiceQuota</code> returns the default AWS value for each quota. 
                                                                                         ## 
  let valid = call_402656570.validator(path, query, header, formData, body, _)
  let scheme = call_402656570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656570.makeUrl(scheme.get, call_402656570.host, call_402656570.base,
                                   call_402656570.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656570, uri, valid, _)

proc call*(call_402656571: Call_GetServiceQuota_402656558; body: JsonNode): Recallable =
  ## getServiceQuota
  ## Returns the details for the specified service quota. This operation provides a different Value than the <code>GetAWSDefaultServiceQuota</code> operation. This operation returns the applied value for each quota. <code>GetAWSDefaultServiceQuota</code> returns the default AWS value for each quota. 
  ##   
                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656572 = newJObject()
  if body != nil:
    body_402656572 = body
  result = call_402656571.call(nil, nil, nil, nil, body_402656572)

var getServiceQuota* = Call_GetServiceQuota_402656558(name: "getServiceQuota",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.GetServiceQuota",
    validator: validate_GetServiceQuota_402656559, base: "/",
    makeUrl: url_GetServiceQuota_402656560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceQuotaIncreaseRequestFromTemplate_402656573 = ref object of OpenApiRestCall_402656038
proc url_GetServiceQuotaIncreaseRequestFromTemplate_402656575(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServiceQuotaIncreaseRequestFromTemplate_402656574(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656576 = header.getOrDefault("X-Amz-Target")
  valid_402656576 = validateParameter(valid_402656576, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetServiceQuotaIncreaseRequestFromTemplate"))
  if valid_402656576 != nil:
    section.add "X-Amz-Target", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Security-Token", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Signature")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Signature", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Algorithm", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Date")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Date", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Credential")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Credential", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656583
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

proc call*(call_402656585: Call_GetServiceQuotaIncreaseRequestFromTemplate_402656573;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the details of the service quota increase request in your template.
                                                                                         ## 
  let valid = call_402656585.validator(path, query, header, formData, body, _)
  let scheme = call_402656585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656585.makeUrl(scheme.get, call_402656585.host, call_402656585.base,
                                   call_402656585.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656585, uri, valid, _)

proc call*(call_402656586: Call_GetServiceQuotaIncreaseRequestFromTemplate_402656573;
           body: JsonNode): Recallable =
  ## getServiceQuotaIncreaseRequestFromTemplate
  ## Returns the details of the service quota increase request in your template.
  ##   
                                                                                ## body: JObject (required)
  var body_402656587 = newJObject()
  if body != nil:
    body_402656587 = body
  result = call_402656586.call(nil, nil, nil, nil, body_402656587)

var getServiceQuotaIncreaseRequestFromTemplate* = Call_GetServiceQuotaIncreaseRequestFromTemplate_402656573(
    name: "getServiceQuotaIncreaseRequestFromTemplate",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.GetServiceQuotaIncreaseRequestFromTemplate",
    validator: validate_GetServiceQuotaIncreaseRequestFromTemplate_402656574,
    base: "/", makeUrl: url_GetServiceQuotaIncreaseRequestFromTemplate_402656575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAWSDefaultServiceQuotas_402656588 = ref object of OpenApiRestCall_402656038
proc url_ListAWSDefaultServiceQuotas_402656590(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAWSDefaultServiceQuotas_402656589(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656591 = query.getOrDefault("MaxResults")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "MaxResults", valid_402656591
  var valid_402656592 = query.getOrDefault("NextToken")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "NextToken", valid_402656592
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656593 = header.getOrDefault("X-Amz-Target")
  valid_402656593 = validateParameter(valid_402656593, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListAWSDefaultServiceQuotas"))
  if valid_402656593 != nil:
    section.add "X-Amz-Target", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Security-Token", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Signature")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Signature", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Algorithm", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Date")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Date", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Credential")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Credential", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656600
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

proc call*(call_402656602: Call_ListAWSDefaultServiceQuotas_402656588;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists all default service quotas for the specified AWS service or all AWS services. ListAWSDefaultServiceQuotas is similar to <a>ListServiceQuotas</a> except for the Value object. The Value object returned by <code>ListAWSDefaultServiceQuotas</code> is the default value assigned by AWS. This request returns a list of all service quotas for the specified service. The listing of each you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
                                                                                         ## 
  let valid = call_402656602.validator(path, query, header, formData, body, _)
  let scheme = call_402656602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656602.makeUrl(scheme.get, call_402656602.host, call_402656602.base,
                                   call_402656602.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656602, uri, valid, _)

proc call*(call_402656603: Call_ListAWSDefaultServiceQuotas_402656588;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAWSDefaultServiceQuotas
  ## <p>Lists all default service quotas for the specified AWS service or all AWS services. ListAWSDefaultServiceQuotas is similar to <a>ListServiceQuotas</a> except for the Value object. The Value object returned by <code>ListAWSDefaultServiceQuotas</code> is the default value assigned by AWS. This request returns a list of all service quotas for the specified service. The listing of each you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## token
  var query_402656604 = newJObject()
  var body_402656605 = newJObject()
  add(query_402656604, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656605 = body
  add(query_402656604, "NextToken", newJString(NextToken))
  result = call_402656603.call(nil, query_402656604, nil, nil, body_402656605)

var listAWSDefaultServiceQuotas* = Call_ListAWSDefaultServiceQuotas_402656588(
    name: "listAWSDefaultServiceQuotas", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.ListAWSDefaultServiceQuotas",
    validator: validate_ListAWSDefaultServiceQuotas_402656589, base: "/",
    makeUrl: url_ListAWSDefaultServiceQuotas_402656590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRequestedServiceQuotaChangeHistory_402656606 = ref object of OpenApiRestCall_402656038
proc url_ListRequestedServiceQuotaChangeHistory_402656608(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRequestedServiceQuotaChangeHistory_402656607(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656609 = query.getOrDefault("MaxResults")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "MaxResults", valid_402656609
  var valid_402656610 = query.getOrDefault("NextToken")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "NextToken", valid_402656610
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656611 = header.getOrDefault("X-Amz-Target")
  valid_402656611 = validateParameter(valid_402656611, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistory"))
  if valid_402656611 != nil:
    section.add "X-Amz-Target", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Security-Token", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Signature")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Signature", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Algorithm", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Date")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Date", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Credential")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Credential", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656618
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

proc call*(call_402656620: Call_ListRequestedServiceQuotaChangeHistory_402656606;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Requests a list of the changes to quotas for a service.
                                                                                         ## 
  let valid = call_402656620.validator(path, query, header, formData, body, _)
  let scheme = call_402656620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656620.makeUrl(scheme.get, call_402656620.host, call_402656620.base,
                                   call_402656620.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656620, uri, valid, _)

proc call*(call_402656621: Call_ListRequestedServiceQuotaChangeHistory_402656606;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listRequestedServiceQuotaChangeHistory
  ## Requests a list of the changes to quotas for a service.
  ##   MaxResults: string
                                                            ##             : Pagination limit
  ##   
                                                                                             ## body: JObject (required)
  ##   
                                                                                                                        ## NextToken: string
                                                                                                                        ##            
                                                                                                                        ## : 
                                                                                                                        ## Pagination 
                                                                                                                        ## token
  var query_402656622 = newJObject()
  var body_402656623 = newJObject()
  add(query_402656622, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656623 = body
  add(query_402656622, "NextToken", newJString(NextToken))
  result = call_402656621.call(nil, query_402656622, nil, nil, body_402656623)

var listRequestedServiceQuotaChangeHistory* = Call_ListRequestedServiceQuotaChangeHistory_402656606(
    name: "listRequestedServiceQuotaChangeHistory", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistory",
    validator: validate_ListRequestedServiceQuotaChangeHistory_402656607,
    base: "/", makeUrl: url_ListRequestedServiceQuotaChangeHistory_402656608,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRequestedServiceQuotaChangeHistoryByQuota_402656624 = ref object of OpenApiRestCall_402656038
proc url_ListRequestedServiceQuotaChangeHistoryByQuota_402656626(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRequestedServiceQuotaChangeHistoryByQuota_402656625(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656627 = query.getOrDefault("MaxResults")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "MaxResults", valid_402656627
  var valid_402656628 = query.getOrDefault("NextToken")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "NextToken", valid_402656628
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656629 = header.getOrDefault("X-Amz-Target")
  valid_402656629 = validateParameter(valid_402656629, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistoryByQuota"))
  if valid_402656629 != nil:
    section.add "X-Amz-Target", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Security-Token", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Signature")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Signature", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Algorithm", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Date")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Date", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Credential")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Credential", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656636
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

proc call*(call_402656638: Call_ListRequestedServiceQuotaChangeHistoryByQuota_402656624;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Requests a list of the changes to specific service quotas. This command provides additional granularity over the <code>ListRequestedServiceQuotaChangeHistory</code> command. Once a quota change request has reached <code>CASE_CLOSED, APPROVED,</code> or <code>DENIED</code>, the history has been kept for 90 days.
                                                                                         ## 
  let valid = call_402656638.validator(path, query, header, formData, body, _)
  let scheme = call_402656638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656638.makeUrl(scheme.get, call_402656638.host, call_402656638.base,
                                   call_402656638.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656638, uri, valid, _)

proc call*(call_402656639: Call_ListRequestedServiceQuotaChangeHistoryByQuota_402656624;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listRequestedServiceQuotaChangeHistoryByQuota
  ## Requests a list of the changes to specific service quotas. This command provides additional granularity over the <code>ListRequestedServiceQuotaChangeHistory</code> command. Once a quota change request has reached <code>CASE_CLOSED, APPROVED,</code> or <code>DENIED</code>, the history has been kept for 90 days.
  ##   
                                                                                                                                                                                                                                                                                                                             ## MaxResults: string
                                                                                                                                                                                                                                                                                                                             ##             
                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                                                                                                                                             ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                ## token
  var query_402656640 = newJObject()
  var body_402656641 = newJObject()
  add(query_402656640, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656641 = body
  add(query_402656640, "NextToken", newJString(NextToken))
  result = call_402656639.call(nil, query_402656640, nil, nil, body_402656641)

var listRequestedServiceQuotaChangeHistoryByQuota* = Call_ListRequestedServiceQuotaChangeHistoryByQuota_402656624(
    name: "listRequestedServiceQuotaChangeHistoryByQuota",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistoryByQuota",
    validator: validate_ListRequestedServiceQuotaChangeHistoryByQuota_402656625,
    base: "/", makeUrl: url_ListRequestedServiceQuotaChangeHistoryByQuota_402656626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceQuotaIncreaseRequestsInTemplate_402656642 = ref object of OpenApiRestCall_402656038
proc url_ListServiceQuotaIncreaseRequestsInTemplate_402656644(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServiceQuotaIncreaseRequestsInTemplate_402656643(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656645 = query.getOrDefault("MaxResults")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "MaxResults", valid_402656645
  var valid_402656646 = query.getOrDefault("NextToken")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "NextToken", valid_402656646
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656647 = header.getOrDefault("X-Amz-Target")
  valid_402656647 = validateParameter(valid_402656647, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListServiceQuotaIncreaseRequestsInTemplate"))
  if valid_402656647 != nil:
    section.add "X-Amz-Target", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Security-Token", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Signature")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Signature", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Algorithm", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Date")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Date", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Credential")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Credential", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656654
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

proc call*(call_402656656: Call_ListServiceQuotaIncreaseRequestsInTemplate_402656642;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the quota increase requests in the template. 
                                                                                         ## 
  let valid = call_402656656.validator(path, query, header, formData, body, _)
  let scheme = call_402656656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656656.makeUrl(scheme.get, call_402656656.host, call_402656656.base,
                                   call_402656656.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656656, uri, valid, _)

proc call*(call_402656657: Call_ListServiceQuotaIncreaseRequestsInTemplate_402656642;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listServiceQuotaIncreaseRequestsInTemplate
  ## Returns a list of the quota increase requests in the template. 
  ##   MaxResults: string
                                                                    ##             : Pagination limit
  ##   
                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                ## NextToken: string
                                                                                                                                ##            
                                                                                                                                ## : 
                                                                                                                                ## Pagination 
                                                                                                                                ## token
  var query_402656658 = newJObject()
  var body_402656659 = newJObject()
  add(query_402656658, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656659 = body
  add(query_402656658, "NextToken", newJString(NextToken))
  result = call_402656657.call(nil, query_402656658, nil, nil, body_402656659)

var listServiceQuotaIncreaseRequestsInTemplate* = Call_ListServiceQuotaIncreaseRequestsInTemplate_402656642(
    name: "listServiceQuotaIncreaseRequestsInTemplate",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.ListServiceQuotaIncreaseRequestsInTemplate",
    validator: validate_ListServiceQuotaIncreaseRequestsInTemplate_402656643,
    base: "/", makeUrl: url_ListServiceQuotaIncreaseRequestsInTemplate_402656644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceQuotas_402656660 = ref object of OpenApiRestCall_402656038
proc url_ListServiceQuotas_402656662(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServiceQuotas_402656661(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656663 = query.getOrDefault("MaxResults")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "MaxResults", valid_402656663
  var valid_402656664 = query.getOrDefault("NextToken")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "NextToken", valid_402656664
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656665 = header.getOrDefault("X-Amz-Target")
  valid_402656665 = validateParameter(valid_402656665, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListServiceQuotas"))
  if valid_402656665 != nil:
    section.add "X-Amz-Target", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Security-Token", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Signature")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Signature", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Algorithm", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Date")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Date", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Credential")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Credential", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656672
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

proc call*(call_402656674: Call_ListServiceQuotas_402656660;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists all service quotas for the specified AWS service. This request returns a list of the service quotas for the specified service. you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
                                                                                         ## 
  let valid = call_402656674.validator(path, query, header, formData, body, _)
  let scheme = call_402656674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656674.makeUrl(scheme.get, call_402656674.host, call_402656674.base,
                                   call_402656674.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656674, uri, valid, _)

proc call*(call_402656675: Call_ListServiceQuotas_402656660; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listServiceQuotas
  ## <p>Lists all service quotas for the specified AWS service. This request returns a list of the service quotas for the specified service. you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## token
  var query_402656676 = newJObject()
  var body_402656677 = newJObject()
  add(query_402656676, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656677 = body
  add(query_402656676, "NextToken", newJString(NextToken))
  result = call_402656675.call(nil, query_402656676, nil, nil, body_402656677)

var listServiceQuotas* = Call_ListServiceQuotas_402656660(
    name: "listServiceQuotas", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.ListServiceQuotas",
    validator: validate_ListServiceQuotas_402656661, base: "/",
    makeUrl: url_ListServiceQuotas_402656662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServices_402656678 = ref object of OpenApiRestCall_402656038
proc url_ListServices_402656680(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServices_402656679(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656681 = query.getOrDefault("MaxResults")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "MaxResults", valid_402656681
  var valid_402656682 = query.getOrDefault("NextToken")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "NextToken", valid_402656682
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656683 = header.getOrDefault("X-Amz-Target")
  valid_402656683 = validateParameter(valid_402656683, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListServices"))
  if valid_402656683 != nil:
    section.add "X-Amz-Target", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Security-Token", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Signature")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Signature", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Algorithm", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Date")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Date", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Credential")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Credential", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656690
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

proc call*(call_402656692: Call_ListServices_402656678; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the AWS services available in Service Quotas. Not all AWS services are available in Service Quotas. To list the see the list of the service quotas for a specific service, use <a>ListServiceQuotas</a>.
                                                                                         ## 
  let valid = call_402656692.validator(path, query, header, formData, body, _)
  let scheme = call_402656692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656692.makeUrl(scheme.get, call_402656692.host, call_402656692.base,
                                   call_402656692.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656692, uri, valid, _)

proc call*(call_402656693: Call_ListServices_402656678; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listServices
  ## Lists the AWS services available in Service Quotas. Not all AWS services are available in Service Quotas. To list the see the list of the service quotas for a specific service, use <a>ListServiceQuotas</a>.
  ##   
                                                                                                                                                                                                                   ## MaxResults: string
                                                                                                                                                                                                                   ##             
                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                   ## Pagination 
                                                                                                                                                                                                                   ## limit
  ##   
                                                                                                                                                                                                                           ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                      ## NextToken: string
                                                                                                                                                                                                                                                      ##            
                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                      ## Pagination 
                                                                                                                                                                                                                                                      ## token
  var query_402656694 = newJObject()
  var body_402656695 = newJObject()
  add(query_402656694, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656695 = body
  add(query_402656694, "NextToken", newJString(NextToken))
  result = call_402656693.call(nil, query_402656694, nil, nil, body_402656695)

var listServices* = Call_ListServices_402656678(name: "listServices",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.ListServices",
    validator: validate_ListServices_402656679, base: "/",
    makeUrl: url_ListServices_402656680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutServiceQuotaIncreaseRequestIntoTemplate_402656696 = ref object of OpenApiRestCall_402656038
proc url_PutServiceQuotaIncreaseRequestIntoTemplate_402656698(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutServiceQuotaIncreaseRequestIntoTemplate_402656697(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656699 = header.getOrDefault("X-Amz-Target")
  valid_402656699 = validateParameter(valid_402656699, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.PutServiceQuotaIncreaseRequestIntoTemplate"))
  if valid_402656699 != nil:
    section.add "X-Amz-Target", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Security-Token", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Signature")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Signature", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Algorithm", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Date")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Date", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Credential")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Credential", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656706
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

proc call*(call_402656708: Call_PutServiceQuotaIncreaseRequestIntoTemplate_402656696;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Defines and adds a quota to the service quota template. To add a quota to the template, you must provide the <code>ServiceCode</code>, <code>QuotaCode</code>, <code>AwsRegion</code>, and <code>DesiredValue</code>. Once you add a quota to the template, use <a>ListServiceQuotaIncreaseRequestsInTemplate</a> to see the list of quotas in the template.
                                                                                         ## 
  let valid = call_402656708.validator(path, query, header, formData, body, _)
  let scheme = call_402656708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656708.makeUrl(scheme.get, call_402656708.host, call_402656708.base,
                                   call_402656708.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656708, uri, valid, _)

proc call*(call_402656709: Call_PutServiceQuotaIncreaseRequestIntoTemplate_402656696;
           body: JsonNode): Recallable =
  ## putServiceQuotaIncreaseRequestIntoTemplate
  ## Defines and adds a quota to the service quota template. To add a quota to the template, you must provide the <code>ServiceCode</code>, <code>QuotaCode</code>, <code>AwsRegion</code>, and <code>DesiredValue</code>. Once you add a quota to the template, use <a>ListServiceQuotaIncreaseRequestsInTemplate</a> to see the list of quotas in the template.
  ##   
                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656710 = newJObject()
  if body != nil:
    body_402656710 = body
  result = call_402656709.call(nil, nil, nil, nil, body_402656710)

var putServiceQuotaIncreaseRequestIntoTemplate* = Call_PutServiceQuotaIncreaseRequestIntoTemplate_402656696(
    name: "putServiceQuotaIncreaseRequestIntoTemplate",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.PutServiceQuotaIncreaseRequestIntoTemplate",
    validator: validate_PutServiceQuotaIncreaseRequestIntoTemplate_402656697,
    base: "/", makeUrl: url_PutServiceQuotaIncreaseRequestIntoTemplate_402656698,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RequestServiceQuotaIncrease_402656711 = ref object of OpenApiRestCall_402656038
proc url_RequestServiceQuotaIncrease_402656713(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RequestServiceQuotaIncrease_402656712(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656714 = header.getOrDefault("X-Amz-Target")
  valid_402656714 = validateParameter(valid_402656714, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.RequestServiceQuotaIncrease"))
  if valid_402656714 != nil:
    section.add "X-Amz-Target", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Security-Token", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-Signature")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Signature", valid_402656716
  var valid_402656717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Algorithm", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Date")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Date", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Credential")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Credential", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656721
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

proc call*(call_402656723: Call_RequestServiceQuotaIncrease_402656711;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the details of a service quota increase request. The response to this command provides the details in the <a>RequestedServiceQuotaChange</a> object. 
                                                                                         ## 
  let valid = call_402656723.validator(path, query, header, formData, body, _)
  let scheme = call_402656723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656723.makeUrl(scheme.get, call_402656723.host, call_402656723.base,
                                   call_402656723.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656723, uri, valid, _)

proc call*(call_402656724: Call_RequestServiceQuotaIncrease_402656711;
           body: JsonNode): Recallable =
  ## requestServiceQuotaIncrease
  ## Retrieves the details of a service quota increase request. The response to this command provides the details in the <a>RequestedServiceQuotaChange</a> object. 
  ##   
                                                                                                                                                                    ## body: JObject (required)
  var body_402656725 = newJObject()
  if body != nil:
    body_402656725 = body
  result = call_402656724.call(nil, nil, nil, nil, body_402656725)

var requestServiceQuotaIncrease* = Call_RequestServiceQuotaIncrease_402656711(
    name: "requestServiceQuotaIncrease", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.RequestServiceQuotaIncrease",
    validator: validate_RequestServiceQuotaIncrease_402656712, base: "/",
    makeUrl: url_RequestServiceQuotaIncrease_402656713,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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