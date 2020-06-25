
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AssociateServiceQuotaTemplate_21625779 = ref object of OpenApiRestCall_21625435
proc url_AssociateServiceQuotaTemplate_21625781(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateServiceQuotaTemplate_21625780(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625898 = header.getOrDefault("X-Amz-Target")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.AssociateServiceQuotaTemplate"))
  if valid_21625898 != nil:
    section.add "X-Amz-Target", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
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

proc call*(call_21625929: Call_AssociateServiceQuotaTemplate_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the Service Quotas template with your organization so that when new accounts are created in your organization, the template submits increase requests for the specified service quotas. Use the Service Quotas template to request an increase for any adjustable quota value. After you define the Service Quotas template, use this operation to associate, or enable, the template. 
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_AssociateServiceQuotaTemplate_21625779;
          body: JsonNode): Recallable =
  ## associateServiceQuotaTemplate
  ## Associates the Service Quotas template with your organization so that when new accounts are created in your organization, the template submits increase requests for the specified service quotas. Use the Service Quotas template to request an increase for any adjustable quota value. After you define the Service Quotas template, use this operation to associate, or enable, the template. 
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var associateServiceQuotaTemplate* = Call_AssociateServiceQuotaTemplate_21625779(
    name: "associateServiceQuotaTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.AssociateServiceQuotaTemplate",
    validator: validate_AssociateServiceQuotaTemplate_21625780, base: "/",
    makeUrl: url_AssociateServiceQuotaTemplate_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceQuotaIncreaseRequestFromTemplate_21626029 = ref object of OpenApiRestCall_21625435
proc url_DeleteServiceQuotaIncreaseRequestFromTemplate_21626031(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteServiceQuotaIncreaseRequestFromTemplate_21626030(
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Target")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.DeleteServiceQuotaIncreaseRequestFromTemplate"))
  if valid_21626034 != nil:
    section.add "X-Amz-Target", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
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

proc call*(call_21626041: Call_DeleteServiceQuotaIncreaseRequestFromTemplate_21626029;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a service quota increase request from the Service Quotas template. 
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_DeleteServiceQuotaIncreaseRequestFromTemplate_21626029;
          body: JsonNode): Recallable =
  ## deleteServiceQuotaIncreaseRequestFromTemplate
  ## Removes a service quota increase request from the Service Quotas template. 
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var deleteServiceQuotaIncreaseRequestFromTemplate* = Call_DeleteServiceQuotaIncreaseRequestFromTemplate_21626029(
    name: "deleteServiceQuotaIncreaseRequestFromTemplate",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.DeleteServiceQuotaIncreaseRequestFromTemplate",
    validator: validate_DeleteServiceQuotaIncreaseRequestFromTemplate_21626030,
    base: "/", makeUrl: url_DeleteServiceQuotaIncreaseRequestFromTemplate_21626031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceQuotaTemplate_21626044 = ref object of OpenApiRestCall_21625435
proc url_DisassociateServiceQuotaTemplate_21626046(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateServiceQuotaTemplate_21626045(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Target")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.DisassociateServiceQuotaTemplate"))
  if valid_21626049 != nil:
    section.add "X-Amz-Target", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
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

proc call*(call_21626056: Call_DisassociateServiceQuotaTemplate_21626044;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disables the Service Quotas template. Once the template is disabled, it does not request quota increases for new accounts in your organization. Disabling the quota template does not apply the quota increase requests from the template. </p> <p> <b>Related operations</b> </p> <ul> <li> <p>To enable the quota template, call <a>AssociateServiceQuotaTemplate</a>. </p> </li> <li> <p>To delete a specific service quota from the template, use <a>DeleteServiceQuotaIncreaseRequestFromTemplate</a>.</p> </li> </ul>
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_DisassociateServiceQuotaTemplate_21626044;
          body: JsonNode): Recallable =
  ## disassociateServiceQuotaTemplate
  ## <p>Disables the Service Quotas template. Once the template is disabled, it does not request quota increases for new accounts in your organization. Disabling the quota template does not apply the quota increase requests from the template. </p> <p> <b>Related operations</b> </p> <ul> <li> <p>To enable the quota template, call <a>AssociateServiceQuotaTemplate</a>. </p> </li> <li> <p>To delete a specific service quota from the template, use <a>DeleteServiceQuotaIncreaseRequestFromTemplate</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var disassociateServiceQuotaTemplate* = Call_DisassociateServiceQuotaTemplate_21626044(
    name: "disassociateServiceQuotaTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.DisassociateServiceQuotaTemplate",
    validator: validate_DisassociateServiceQuotaTemplate_21626045, base: "/",
    makeUrl: url_DisassociateServiceQuotaTemplate_21626046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAWSDefaultServiceQuota_21626059 = ref object of OpenApiRestCall_21625435
proc url_GetAWSDefaultServiceQuota_21626061(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAWSDefaultServiceQuota_21626060(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626062 = header.getOrDefault("X-Amz-Date")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Date", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Security-Token", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Target")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetAWSDefaultServiceQuota"))
  if valid_21626064 != nil:
    section.add "X-Amz-Target", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
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

proc call*(call_21626071: Call_GetAWSDefaultServiceQuota_21626059;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the default service quotas values. The Value returned for each quota is the AWS default value, even if the quotas have been increased.. 
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_GetAWSDefaultServiceQuota_21626059; body: JsonNode): Recallable =
  ## getAWSDefaultServiceQuota
  ## Retrieves the default service quotas values. The Value returned for each quota is the AWS default value, even if the quotas have been increased.. 
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var getAWSDefaultServiceQuota* = Call_GetAWSDefaultServiceQuota_21626059(
    name: "getAWSDefaultServiceQuota", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.GetAWSDefaultServiceQuota",
    validator: validate_GetAWSDefaultServiceQuota_21626060, base: "/",
    makeUrl: url_GetAWSDefaultServiceQuota_21626061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssociationForServiceQuotaTemplate_21626074 = ref object of OpenApiRestCall_21625435
proc url_GetAssociationForServiceQuotaTemplate_21626076(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAssociationForServiceQuotaTemplate_21626075(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626077 = header.getOrDefault("X-Amz-Date")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Date", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Security-Token", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Target")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetAssociationForServiceQuotaTemplate"))
  if valid_21626079 != nil:
    section.add "X-Amz-Target", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
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

proc call*(call_21626086: Call_GetAssociationForServiceQuotaTemplate_21626074;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the <code>ServiceQuotaTemplateAssociationStatus</code> value from the service. Use this action to determine if the Service Quota template is associated, or enabled. 
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_GetAssociationForServiceQuotaTemplate_21626074;
          body: JsonNode): Recallable =
  ## getAssociationForServiceQuotaTemplate
  ## Retrieves the <code>ServiceQuotaTemplateAssociationStatus</code> value from the service. Use this action to determine if the Service Quota template is associated, or enabled. 
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var getAssociationForServiceQuotaTemplate* = Call_GetAssociationForServiceQuotaTemplate_21626074(
    name: "getAssociationForServiceQuotaTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.GetAssociationForServiceQuotaTemplate",
    validator: validate_GetAssociationForServiceQuotaTemplate_21626075, base: "/",
    makeUrl: url_GetAssociationForServiceQuotaTemplate_21626076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestedServiceQuotaChange_21626089 = ref object of OpenApiRestCall_21625435
proc url_GetRequestedServiceQuotaChange_21626091(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRequestedServiceQuotaChange_21626090(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Target")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetRequestedServiceQuotaChange"))
  if valid_21626094 != nil:
    section.add "X-Amz-Target", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Credential")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Credential", valid_21626099
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

proc call*(call_21626101: Call_GetRequestedServiceQuotaChange_21626089;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the details for a particular increase request. 
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_GetRequestedServiceQuotaChange_21626089;
          body: JsonNode): Recallable =
  ## getRequestedServiceQuotaChange
  ## Retrieves the details for a particular increase request. 
  ##   body: JObject (required)
  var body_21626103 = newJObject()
  if body != nil:
    body_21626103 = body
  result = call_21626102.call(nil, nil, nil, nil, body_21626103)

var getRequestedServiceQuotaChange* = Call_GetRequestedServiceQuotaChange_21626089(
    name: "getRequestedServiceQuotaChange", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.GetRequestedServiceQuotaChange",
    validator: validate_GetRequestedServiceQuotaChange_21626090, base: "/",
    makeUrl: url_GetRequestedServiceQuotaChange_21626091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceQuota_21626104 = ref object of OpenApiRestCall_21625435
proc url_GetServiceQuota_21626106(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServiceQuota_21626105(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626107 = header.getOrDefault("X-Amz-Date")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Date", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Security-Token", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Target")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetServiceQuota"))
  if valid_21626109 != nil:
    section.add "X-Amz-Target", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
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

proc call*(call_21626116: Call_GetServiceQuota_21626104; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the details for the specified service quota. This operation provides a different Value than the <code>GetAWSDefaultServiceQuota</code> operation. This operation returns the applied value for each quota. <code>GetAWSDefaultServiceQuota</code> returns the default AWS value for each quota. 
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_GetServiceQuota_21626104; body: JsonNode): Recallable =
  ## getServiceQuota
  ## Returns the details for the specified service quota. This operation provides a different Value than the <code>GetAWSDefaultServiceQuota</code> operation. This operation returns the applied value for each quota. <code>GetAWSDefaultServiceQuota</code> returns the default AWS value for each quota. 
  ##   body: JObject (required)
  var body_21626118 = newJObject()
  if body != nil:
    body_21626118 = body
  result = call_21626117.call(nil, nil, nil, nil, body_21626118)

var getServiceQuota* = Call_GetServiceQuota_21626104(name: "getServiceQuota",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.GetServiceQuota",
    validator: validate_GetServiceQuota_21626105, base: "/",
    makeUrl: url_GetServiceQuota_21626106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceQuotaIncreaseRequestFromTemplate_21626119 = ref object of OpenApiRestCall_21625435
proc url_GetServiceQuotaIncreaseRequestFromTemplate_21626121(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServiceQuotaIncreaseRequestFromTemplate_21626120(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626122 = header.getOrDefault("X-Amz-Date")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Date", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Security-Token", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Target")
  valid_21626124 = validateParameter(valid_21626124, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.GetServiceQuotaIncreaseRequestFromTemplate"))
  if valid_21626124 != nil:
    section.add "X-Amz-Target", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
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

proc call*(call_21626131: Call_GetServiceQuotaIncreaseRequestFromTemplate_21626119;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the details of the service quota increase request in your template.
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_GetServiceQuotaIncreaseRequestFromTemplate_21626119;
          body: JsonNode): Recallable =
  ## getServiceQuotaIncreaseRequestFromTemplate
  ## Returns the details of the service quota increase request in your template.
  ##   body: JObject (required)
  var body_21626133 = newJObject()
  if body != nil:
    body_21626133 = body
  result = call_21626132.call(nil, nil, nil, nil, body_21626133)

var getServiceQuotaIncreaseRequestFromTemplate* = Call_GetServiceQuotaIncreaseRequestFromTemplate_21626119(
    name: "getServiceQuotaIncreaseRequestFromTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.GetServiceQuotaIncreaseRequestFromTemplate",
    validator: validate_GetServiceQuotaIncreaseRequestFromTemplate_21626120,
    base: "/", makeUrl: url_GetServiceQuotaIncreaseRequestFromTemplate_21626121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAWSDefaultServiceQuotas_21626134 = ref object of OpenApiRestCall_21625435
proc url_ListAWSDefaultServiceQuotas_21626136(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAWSDefaultServiceQuotas_21626135(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626137 = query.getOrDefault("NextToken")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "NextToken", valid_21626137
  var valid_21626138 = query.getOrDefault("MaxResults")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "MaxResults", valid_21626138
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
  var valid_21626139 = header.getOrDefault("X-Amz-Date")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Date", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Security-Token", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Target")
  valid_21626141 = validateParameter(valid_21626141, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListAWSDefaultServiceQuotas"))
  if valid_21626141 != nil:
    section.add "X-Amz-Target", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Algorithm", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Signature")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Signature", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Credential")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Credential", valid_21626146
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

proc call*(call_21626148: Call_ListAWSDefaultServiceQuotas_21626134;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists all default service quotas for the specified AWS service or all AWS services. ListAWSDefaultServiceQuotas is similar to <a>ListServiceQuotas</a> except for the Value object. The Value object returned by <code>ListAWSDefaultServiceQuotas</code> is the default value assigned by AWS. This request returns a list of all service quotas for the specified service. The listing of each you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ## 
  let valid = call_21626148.validator(path, query, header, formData, body, _)
  let scheme = call_21626148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626148.makeUrl(scheme.get, call_21626148.host, call_21626148.base,
                               call_21626148.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626148, uri, valid, _)

proc call*(call_21626149: Call_ListAWSDefaultServiceQuotas_21626134;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAWSDefaultServiceQuotas
  ## <p>Lists all default service quotas for the specified AWS service or all AWS services. ListAWSDefaultServiceQuotas is similar to <a>ListServiceQuotas</a> except for the Value object. The Value object returned by <code>ListAWSDefaultServiceQuotas</code> is the default value assigned by AWS. This request returns a list of all service quotas for the specified service. The listing of each you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626151 = newJObject()
  var body_21626152 = newJObject()
  add(query_21626151, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626152 = body
  add(query_21626151, "MaxResults", newJString(MaxResults))
  result = call_21626149.call(nil, query_21626151, nil, nil, body_21626152)

var listAWSDefaultServiceQuotas* = Call_ListAWSDefaultServiceQuotas_21626134(
    name: "listAWSDefaultServiceQuotas", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.ListAWSDefaultServiceQuotas",
    validator: validate_ListAWSDefaultServiceQuotas_21626135, base: "/",
    makeUrl: url_ListAWSDefaultServiceQuotas_21626136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRequestedServiceQuotaChangeHistory_21626156 = ref object of OpenApiRestCall_21625435
proc url_ListRequestedServiceQuotaChangeHistory_21626158(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRequestedServiceQuotaChangeHistory_21626157(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626159 = query.getOrDefault("NextToken")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "NextToken", valid_21626159
  var valid_21626160 = query.getOrDefault("MaxResults")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "MaxResults", valid_21626160
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
  var valid_21626161 = header.getOrDefault("X-Amz-Date")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Date", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Security-Token", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Target")
  valid_21626163 = validateParameter(valid_21626163, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistory"))
  if valid_21626163 != nil:
    section.add "X-Amz-Target", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Algorithm", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Signature")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Signature", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Credential")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Credential", valid_21626168
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

proc call*(call_21626170: Call_ListRequestedServiceQuotaChangeHistory_21626156;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Requests a list of the changes to quotas for a service.
  ## 
  let valid = call_21626170.validator(path, query, header, formData, body, _)
  let scheme = call_21626170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626170.makeUrl(scheme.get, call_21626170.host, call_21626170.base,
                               call_21626170.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626170, uri, valid, _)

proc call*(call_21626171: Call_ListRequestedServiceQuotaChangeHistory_21626156;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listRequestedServiceQuotaChangeHistory
  ## Requests a list of the changes to quotas for a service.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626172 = newJObject()
  var body_21626173 = newJObject()
  add(query_21626172, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626173 = body
  add(query_21626172, "MaxResults", newJString(MaxResults))
  result = call_21626171.call(nil, query_21626172, nil, nil, body_21626173)

var listRequestedServiceQuotaChangeHistory* = Call_ListRequestedServiceQuotaChangeHistory_21626156(
    name: "listRequestedServiceQuotaChangeHistory", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistory",
    validator: validate_ListRequestedServiceQuotaChangeHistory_21626157,
    base: "/", makeUrl: url_ListRequestedServiceQuotaChangeHistory_21626158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRequestedServiceQuotaChangeHistoryByQuota_21626174 = ref object of OpenApiRestCall_21625435
proc url_ListRequestedServiceQuotaChangeHistoryByQuota_21626176(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRequestedServiceQuotaChangeHistoryByQuota_21626175(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626177 = query.getOrDefault("NextToken")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "NextToken", valid_21626177
  var valid_21626178 = query.getOrDefault("MaxResults")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "MaxResults", valid_21626178
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
  var valid_21626179 = header.getOrDefault("X-Amz-Date")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Date", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Security-Token", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Target")
  valid_21626181 = validateParameter(valid_21626181, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistoryByQuota"))
  if valid_21626181 != nil:
    section.add "X-Amz-Target", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Algorithm", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Signature")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Signature", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Credential")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Credential", valid_21626186
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

proc call*(call_21626188: Call_ListRequestedServiceQuotaChangeHistoryByQuota_21626174;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Requests a list of the changes to specific service quotas. This command provides additional granularity over the <code>ListRequestedServiceQuotaChangeHistory</code> command. Once a quota change request has reached <code>CASE_CLOSED, APPROVED,</code> or <code>DENIED</code>, the history has been kept for 90 days.
  ## 
  let valid = call_21626188.validator(path, query, header, formData, body, _)
  let scheme = call_21626188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626188.makeUrl(scheme.get, call_21626188.host, call_21626188.base,
                               call_21626188.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626188, uri, valid, _)

proc call*(call_21626189: Call_ListRequestedServiceQuotaChangeHistoryByQuota_21626174;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listRequestedServiceQuotaChangeHistoryByQuota
  ## Requests a list of the changes to specific service quotas. This command provides additional granularity over the <code>ListRequestedServiceQuotaChangeHistory</code> command. Once a quota change request has reached <code>CASE_CLOSED, APPROVED,</code> or <code>DENIED</code>, the history has been kept for 90 days.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626190 = newJObject()
  var body_21626191 = newJObject()
  add(query_21626190, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626191 = body
  add(query_21626190, "MaxResults", newJString(MaxResults))
  result = call_21626189.call(nil, query_21626190, nil, nil, body_21626191)

var listRequestedServiceQuotaChangeHistoryByQuota* = Call_ListRequestedServiceQuotaChangeHistoryByQuota_21626174(
    name: "listRequestedServiceQuotaChangeHistoryByQuota",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.ListRequestedServiceQuotaChangeHistoryByQuota",
    validator: validate_ListRequestedServiceQuotaChangeHistoryByQuota_21626175,
    base: "/", makeUrl: url_ListRequestedServiceQuotaChangeHistoryByQuota_21626176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceQuotaIncreaseRequestsInTemplate_21626192 = ref object of OpenApiRestCall_21625435
proc url_ListServiceQuotaIncreaseRequestsInTemplate_21626194(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServiceQuotaIncreaseRequestsInTemplate_21626193(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626195 = query.getOrDefault("NextToken")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "NextToken", valid_21626195
  var valid_21626196 = query.getOrDefault("MaxResults")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "MaxResults", valid_21626196
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
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Target")
  valid_21626199 = validateParameter(valid_21626199, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListServiceQuotaIncreaseRequestsInTemplate"))
  if valid_21626199 != nil:
    section.add "X-Amz-Target", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
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

proc call*(call_21626206: Call_ListServiceQuotaIncreaseRequestsInTemplate_21626192;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the quota increase requests in the template. 
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_ListServiceQuotaIncreaseRequestsInTemplate_21626192;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listServiceQuotaIncreaseRequestsInTemplate
  ## Returns a list of the quota increase requests in the template. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626208 = newJObject()
  var body_21626209 = newJObject()
  add(query_21626208, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626209 = body
  add(query_21626208, "MaxResults", newJString(MaxResults))
  result = call_21626207.call(nil, query_21626208, nil, nil, body_21626209)

var listServiceQuotaIncreaseRequestsInTemplate* = Call_ListServiceQuotaIncreaseRequestsInTemplate_21626192(
    name: "listServiceQuotaIncreaseRequestsInTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.ListServiceQuotaIncreaseRequestsInTemplate",
    validator: validate_ListServiceQuotaIncreaseRequestsInTemplate_21626193,
    base: "/", makeUrl: url_ListServiceQuotaIncreaseRequestsInTemplate_21626194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceQuotas_21626210 = ref object of OpenApiRestCall_21625435
proc url_ListServiceQuotas_21626212(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServiceQuotas_21626211(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626213 = query.getOrDefault("NextToken")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "NextToken", valid_21626213
  var valid_21626214 = query.getOrDefault("MaxResults")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "MaxResults", valid_21626214
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
  var valid_21626215 = header.getOrDefault("X-Amz-Date")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Date", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Security-Token", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Target")
  valid_21626217 = validateParameter(valid_21626217, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListServiceQuotas"))
  if valid_21626217 != nil:
    section.add "X-Amz-Target", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Algorithm", valid_21626219
  var valid_21626220 = header.getOrDefault("X-Amz-Signature")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "X-Amz-Signature", valid_21626220
  var valid_21626221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626221
  var valid_21626222 = header.getOrDefault("X-Amz-Credential")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "X-Amz-Credential", valid_21626222
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

proc call*(call_21626224: Call_ListServiceQuotas_21626210; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists all service quotas for the specified AWS service. This request returns a list of the service quotas for the specified service. you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ## 
  let valid = call_21626224.validator(path, query, header, formData, body, _)
  let scheme = call_21626224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626224.makeUrl(scheme.get, call_21626224.host, call_21626224.base,
                               call_21626224.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626224, uri, valid, _)

proc call*(call_21626225: Call_ListServiceQuotas_21626210; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listServiceQuotas
  ## <p>Lists all service quotas for the specified AWS service. This request returns a list of the service quotas for the specified service. you'll see the default values are the values that AWS provides for the quotas. </p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can return an unexpected list of results, even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass the next call to the same API to request the next part of the list.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626226 = newJObject()
  var body_21626227 = newJObject()
  add(query_21626226, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626227 = body
  add(query_21626226, "MaxResults", newJString(MaxResults))
  result = call_21626225.call(nil, query_21626226, nil, nil, body_21626227)

var listServiceQuotas* = Call_ListServiceQuotas_21626210(name: "listServiceQuotas",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.ListServiceQuotas",
    validator: validate_ListServiceQuotas_21626211, base: "/",
    makeUrl: url_ListServiceQuotas_21626212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServices_21626228 = ref object of OpenApiRestCall_21625435
proc url_ListServices_21626230(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServices_21626229(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626231 = query.getOrDefault("NextToken")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "NextToken", valid_21626231
  var valid_21626232 = query.getOrDefault("MaxResults")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "MaxResults", valid_21626232
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
  var valid_21626233 = header.getOrDefault("X-Amz-Date")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Date", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Security-Token", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-Target")
  valid_21626235 = validateParameter(valid_21626235, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.ListServices"))
  if valid_21626235 != nil:
    section.add "X-Amz-Target", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626236
  var valid_21626237 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-Algorithm", valid_21626237
  var valid_21626238 = header.getOrDefault("X-Amz-Signature")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "X-Amz-Signature", valid_21626238
  var valid_21626239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626239 = validateParameter(valid_21626239, JString, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626239
  var valid_21626240 = header.getOrDefault("X-Amz-Credential")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "X-Amz-Credential", valid_21626240
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

proc call*(call_21626242: Call_ListServices_21626228; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the AWS services available in Service Quotas. Not all AWS services are available in Service Quotas. To list the see the list of the service quotas for a specific service, use <a>ListServiceQuotas</a>.
  ## 
  let valid = call_21626242.validator(path, query, header, formData, body, _)
  let scheme = call_21626242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626242.makeUrl(scheme.get, call_21626242.host, call_21626242.base,
                               call_21626242.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626242, uri, valid, _)

proc call*(call_21626243: Call_ListServices_21626228; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listServices
  ## Lists the AWS services available in Service Quotas. Not all AWS services are available in Service Quotas. To list the see the list of the service quotas for a specific service, use <a>ListServiceQuotas</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626244 = newJObject()
  var body_21626245 = newJObject()
  add(query_21626244, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626245 = body
  add(query_21626244, "MaxResults", newJString(MaxResults))
  result = call_21626243.call(nil, query_21626244, nil, nil, body_21626245)

var listServices* = Call_ListServices_21626228(name: "listServices",
    meth: HttpMethod.HttpPost, host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.ListServices",
    validator: validate_ListServices_21626229, base: "/", makeUrl: url_ListServices_21626230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutServiceQuotaIncreaseRequestIntoTemplate_21626246 = ref object of OpenApiRestCall_21625435
proc url_PutServiceQuotaIncreaseRequestIntoTemplate_21626248(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutServiceQuotaIncreaseRequestIntoTemplate_21626247(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626249 = header.getOrDefault("X-Amz-Date")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Date", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Security-Token", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Target")
  valid_21626251 = validateParameter(valid_21626251, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.PutServiceQuotaIncreaseRequestIntoTemplate"))
  if valid_21626251 != nil:
    section.add "X-Amz-Target", valid_21626251
  var valid_21626252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626252
  var valid_21626253 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Algorithm", valid_21626253
  var valid_21626254 = header.getOrDefault("X-Amz-Signature")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-Signature", valid_21626254
  var valid_21626255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626255
  var valid_21626256 = header.getOrDefault("X-Amz-Credential")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Credential", valid_21626256
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

proc call*(call_21626258: Call_PutServiceQuotaIncreaseRequestIntoTemplate_21626246;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Defines and adds a quota to the service quota template. To add a quota to the template, you must provide the <code>ServiceCode</code>, <code>QuotaCode</code>, <code>AwsRegion</code>, and <code>DesiredValue</code>. Once you add a quota to the template, use <a>ListServiceQuotaIncreaseRequestsInTemplate</a> to see the list of quotas in the template.
  ## 
  let valid = call_21626258.validator(path, query, header, formData, body, _)
  let scheme = call_21626258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626258.makeUrl(scheme.get, call_21626258.host, call_21626258.base,
                               call_21626258.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626258, uri, valid, _)

proc call*(call_21626259: Call_PutServiceQuotaIncreaseRequestIntoTemplate_21626246;
          body: JsonNode): Recallable =
  ## putServiceQuotaIncreaseRequestIntoTemplate
  ## Defines and adds a quota to the service quota template. To add a quota to the template, you must provide the <code>ServiceCode</code>, <code>QuotaCode</code>, <code>AwsRegion</code>, and <code>DesiredValue</code>. Once you add a quota to the template, use <a>ListServiceQuotaIncreaseRequestsInTemplate</a> to see the list of quotas in the template.
  ##   body: JObject (required)
  var body_21626260 = newJObject()
  if body != nil:
    body_21626260 = body
  result = call_21626259.call(nil, nil, nil, nil, body_21626260)

var putServiceQuotaIncreaseRequestIntoTemplate* = Call_PutServiceQuotaIncreaseRequestIntoTemplate_21626246(
    name: "putServiceQuotaIncreaseRequestIntoTemplate", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com", route: "/#X-Amz-Target=ServiceQuotasV20190624.PutServiceQuotaIncreaseRequestIntoTemplate",
    validator: validate_PutServiceQuotaIncreaseRequestIntoTemplate_21626247,
    base: "/", makeUrl: url_PutServiceQuotaIncreaseRequestIntoTemplate_21626248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RequestServiceQuotaIncrease_21626261 = ref object of OpenApiRestCall_21625435
proc url_RequestServiceQuotaIncrease_21626263(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RequestServiceQuotaIncrease_21626262(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626264 = header.getOrDefault("X-Amz-Date")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Date", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Security-Token", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Target")
  valid_21626266 = validateParameter(valid_21626266, JString, required = true, default = newJString(
      "ServiceQuotasV20190624.RequestServiceQuotaIncrease"))
  if valid_21626266 != nil:
    section.add "X-Amz-Target", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Algorithm", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Signature")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Signature", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Credential")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Credential", valid_21626271
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

proc call*(call_21626273: Call_RequestServiceQuotaIncrease_21626261;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the details of a service quota increase request. The response to this command provides the details in the <a>RequestedServiceQuotaChange</a> object. 
  ## 
  let valid = call_21626273.validator(path, query, header, formData, body, _)
  let scheme = call_21626273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626273.makeUrl(scheme.get, call_21626273.host, call_21626273.base,
                               call_21626273.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626273, uri, valid, _)

proc call*(call_21626274: Call_RequestServiceQuotaIncrease_21626261; body: JsonNode): Recallable =
  ## requestServiceQuotaIncrease
  ## Retrieves the details of a service quota increase request. The response to this command provides the details in the <a>RequestedServiceQuotaChange</a> object. 
  ##   body: JObject (required)
  var body_21626275 = newJObject()
  if body != nil:
    body_21626275 = body
  result = call_21626274.call(nil, nil, nil, nil, body_21626275)

var requestServiceQuotaIncrease* = Call_RequestServiceQuotaIncrease_21626261(
    name: "requestServiceQuotaIncrease", meth: HttpMethod.HttpPost,
    host: "servicequotas.amazonaws.com",
    route: "/#X-Amz-Target=ServiceQuotasV20190624.RequestServiceQuotaIncrease",
    validator: validate_RequestServiceQuotaIncrease_21626262, base: "/",
    makeUrl: url_RequestServiceQuotaIncrease_21626263,
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