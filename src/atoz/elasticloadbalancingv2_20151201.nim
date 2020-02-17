
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Elastic Load Balancing
## version: 2015-12-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Elastic Load Balancing</fullname> <p>A load balancer distributes incoming traffic across targets, such as your EC2 instances. This enables you to increase the availability of your application. The load balancer also monitors the health of its registered targets and ensures that it routes traffic only to healthy targets. You configure your load balancer to accept incoming traffic by specifying one or more listeners, which are configured with a protocol and port number for connections from clients to the load balancer. You configure a target group with a protocol and port number for connections from the load balancer to the targets, and with health check settings to be used when checking the health status of the targets.</p> <p>Elastic Load Balancing supports the following types of load balancers: Application Load Balancers, Network Load Balancers, and Classic Load Balancers. This reference covers Application Load Balancers and Network Load Balancers.</p> <p>An Application Load Balancer makes routing and load balancing decisions at the application layer (HTTP/HTTPS). A Network Load Balancer makes routing and load balancing decisions at the transport layer (TCP/TLS). Both Application Load Balancers and Network Load Balancers can route requests to one or more ports on each EC2 instance or container instance in your virtual private cloud (VPC). For more information, see the <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/">Elastic Load Balancing User Guide</a>.</p> <p>All Elastic Load Balancing operations are idempotent, which means that they complete at most one time. If you repeat an operation, it succeeds.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/elasticloadbalancing/
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "elasticloadbalancing.ap-northeast-1.amazonaws.com", "ap-southeast-1": "elasticloadbalancing.ap-southeast-1.amazonaws.com", "us-west-2": "elasticloadbalancing.us-west-2.amazonaws.com", "eu-west-2": "elasticloadbalancing.eu-west-2.amazonaws.com", "ap-northeast-3": "elasticloadbalancing.ap-northeast-3.amazonaws.com", "eu-central-1": "elasticloadbalancing.eu-central-1.amazonaws.com", "us-east-2": "elasticloadbalancing.us-east-2.amazonaws.com", "us-east-1": "elasticloadbalancing.us-east-1.amazonaws.com", "cn-northwest-1": "elasticloadbalancing.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "elasticloadbalancing.ap-south-1.amazonaws.com", "eu-north-1": "elasticloadbalancing.eu-north-1.amazonaws.com", "ap-northeast-2": "elasticloadbalancing.ap-northeast-2.amazonaws.com", "us-west-1": "elasticloadbalancing.us-west-1.amazonaws.com", "us-gov-east-1": "elasticloadbalancing.us-gov-east-1.amazonaws.com", "eu-west-3": "elasticloadbalancing.eu-west-3.amazonaws.com", "cn-north-1": "elasticloadbalancing.cn-north-1.amazonaws.com.cn", "sa-east-1": "elasticloadbalancing.sa-east-1.amazonaws.com", "eu-west-1": "elasticloadbalancing.eu-west-1.amazonaws.com", "us-gov-west-1": "elasticloadbalancing.us-gov-west-1.amazonaws.com", "ap-southeast-2": "elasticloadbalancing.ap-southeast-2.amazonaws.com", "ca-central-1": "elasticloadbalancing.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "elasticloadbalancing.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "elasticloadbalancing.ap-southeast-1.amazonaws.com",
      "us-west-2": "elasticloadbalancing.us-west-2.amazonaws.com",
      "eu-west-2": "elasticloadbalancing.eu-west-2.amazonaws.com",
      "ap-northeast-3": "elasticloadbalancing.ap-northeast-3.amazonaws.com",
      "eu-central-1": "elasticloadbalancing.eu-central-1.amazonaws.com",
      "us-east-2": "elasticloadbalancing.us-east-2.amazonaws.com",
      "us-east-1": "elasticloadbalancing.us-east-1.amazonaws.com",
      "cn-northwest-1": "elasticloadbalancing.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "elasticloadbalancing.ap-south-1.amazonaws.com",
      "eu-north-1": "elasticloadbalancing.eu-north-1.amazonaws.com",
      "ap-northeast-2": "elasticloadbalancing.ap-northeast-2.amazonaws.com",
      "us-west-1": "elasticloadbalancing.us-west-1.amazonaws.com",
      "us-gov-east-1": "elasticloadbalancing.us-gov-east-1.amazonaws.com",
      "eu-west-3": "elasticloadbalancing.eu-west-3.amazonaws.com",
      "cn-north-1": "elasticloadbalancing.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "elasticloadbalancing.sa-east-1.amazonaws.com",
      "eu-west-1": "elasticloadbalancing.eu-west-1.amazonaws.com",
      "us-gov-west-1": "elasticloadbalancing.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "elasticloadbalancing.ap-southeast-2.amazonaws.com",
      "ca-central-1": "elasticloadbalancing.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "elasticloadbalancingv2"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddListenerCertificates_611268 = ref object of OpenApiRestCall_610658
proc url_PostAddListenerCertificates_611270(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddListenerCertificates_611269(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611271 = query.getOrDefault("Action")
  valid_611271 = validateParameter(valid_611271, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_611271 != nil:
    section.add "Action", valid_611271
  var valid_611272 = query.getOrDefault("Version")
  valid_611272 = validateParameter(valid_611272, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611272 != nil:
    section.add "Version", valid_611272
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611273 = header.getOrDefault("X-Amz-Signature")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Signature", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Content-Sha256", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Date")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Date", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Credential")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Credential", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Security-Token")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Security-Token", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-Algorithm")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Algorithm", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-SignedHeaders", valid_611279
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_611280 = formData.getOrDefault("Certificates")
  valid_611280 = validateParameter(valid_611280, JArray, required = true, default = nil)
  if valid_611280 != nil:
    section.add "Certificates", valid_611280
  var valid_611281 = formData.getOrDefault("ListenerArn")
  valid_611281 = validateParameter(valid_611281, JString, required = true,
                                 default = nil)
  if valid_611281 != nil:
    section.add "ListenerArn", valid_611281
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611282: Call_PostAddListenerCertificates_611268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611282.validator(path, query, header, formData, body)
  let scheme = call_611282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611282.url(scheme.get, call_611282.host, call_611282.base,
                         call_611282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611282, url, valid)

proc call*(call_611283: Call_PostAddListenerCertificates_611268;
          Certificates: JsonNode; ListenerArn: string;
          Action: string = "AddListenerCertificates"; Version: string = "2015-12-01"): Recallable =
  ## postAddListenerCertificates
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611284 = newJObject()
  var formData_611285 = newJObject()
  if Certificates != nil:
    formData_611285.add "Certificates", Certificates
  add(formData_611285, "ListenerArn", newJString(ListenerArn))
  add(query_611284, "Action", newJString(Action))
  add(query_611284, "Version", newJString(Version))
  result = call_611283.call(nil, query_611284, nil, formData_611285, nil)

var postAddListenerCertificates* = Call_PostAddListenerCertificates_611268(
    name: "postAddListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_PostAddListenerCertificates_611269, base: "/",
    url: url_PostAddListenerCertificates_611270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddListenerCertificates_610996 = ref object of OpenApiRestCall_610658
proc url_GetAddListenerCertificates_610998(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddListenerCertificates_610997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ListenerArn` field"
  var valid_611110 = query.getOrDefault("ListenerArn")
  valid_611110 = validateParameter(valid_611110, JString, required = true,
                                 default = nil)
  if valid_611110 != nil:
    section.add "ListenerArn", valid_611110
  var valid_611111 = query.getOrDefault("Certificates")
  valid_611111 = validateParameter(valid_611111, JArray, required = true, default = nil)
  if valid_611111 != nil:
    section.add "Certificates", valid_611111
  var valid_611125 = query.getOrDefault("Action")
  valid_611125 = validateParameter(valid_611125, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_611125 != nil:
    section.add "Action", valid_611125
  var valid_611126 = query.getOrDefault("Version")
  valid_611126 = validateParameter(valid_611126, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611126 != nil:
    section.add "Version", valid_611126
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611127 = header.getOrDefault("X-Amz-Signature")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Signature", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Content-Sha256", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Date")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Date", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Credential")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Credential", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-Security-Token")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-Security-Token", valid_611131
  var valid_611132 = header.getOrDefault("X-Amz-Algorithm")
  valid_611132 = validateParameter(valid_611132, JString, required = false,
                                 default = nil)
  if valid_611132 != nil:
    section.add "X-Amz-Algorithm", valid_611132
  var valid_611133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611133 = validateParameter(valid_611133, JString, required = false,
                                 default = nil)
  if valid_611133 != nil:
    section.add "X-Amz-SignedHeaders", valid_611133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611156: Call_GetAddListenerCertificates_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611156.validator(path, query, header, formData, body)
  let scheme = call_611156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611156.url(scheme.get, call_611156.host, call_611156.base,
                         call_611156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611156, url, valid)

proc call*(call_611227: Call_GetAddListenerCertificates_610996;
          ListenerArn: string; Certificates: JsonNode;
          Action: string = "AddListenerCertificates"; Version: string = "2015-12-01"): Recallable =
  ## getAddListenerCertificates
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611228 = newJObject()
  add(query_611228, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_611228.add "Certificates", Certificates
  add(query_611228, "Action", newJString(Action))
  add(query_611228, "Version", newJString(Version))
  result = call_611227.call(nil, query_611228, nil, nil, nil)

var getAddListenerCertificates* = Call_GetAddListenerCertificates_610996(
    name: "getAddListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_GetAddListenerCertificates_610997, base: "/",
    url: url_GetAddListenerCertificates_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTags_611303 = ref object of OpenApiRestCall_610658
proc url_PostAddTags_611305(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddTags_611304(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611306 = query.getOrDefault("Action")
  valid_611306 = validateParameter(valid_611306, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_611306 != nil:
    section.add "Action", valid_611306
  var valid_611307 = query.getOrDefault("Version")
  valid_611307 = validateParameter(valid_611307, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611307 != nil:
    section.add "Version", valid_611307
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611308 = header.getOrDefault("X-Amz-Signature")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Signature", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Content-Sha256", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-Date")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Date", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Credential")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Credential", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Security-Token")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Security-Token", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Algorithm")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Algorithm", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-SignedHeaders", valid_611314
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_611315 = formData.getOrDefault("ResourceArns")
  valid_611315 = validateParameter(valid_611315, JArray, required = true, default = nil)
  if valid_611315 != nil:
    section.add "ResourceArns", valid_611315
  var valid_611316 = formData.getOrDefault("Tags")
  valid_611316 = validateParameter(valid_611316, JArray, required = true, default = nil)
  if valid_611316 != nil:
    section.add "Tags", valid_611316
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611317: Call_PostAddTags_611303; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_611317.validator(path, query, header, formData, body)
  let scheme = call_611317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611317.url(scheme.get, call_611317.host, call_611317.base,
                         call_611317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611317, url, valid)

proc call*(call_611318: Call_PostAddTags_611303; ResourceArns: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2015-12-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Version: string (required)
  var query_611319 = newJObject()
  var formData_611320 = newJObject()
  if ResourceArns != nil:
    formData_611320.add "ResourceArns", ResourceArns
  add(query_611319, "Action", newJString(Action))
  if Tags != nil:
    formData_611320.add "Tags", Tags
  add(query_611319, "Version", newJString(Version))
  result = call_611318.call(nil, query_611319, nil, formData_611320, nil)

var postAddTags* = Call_PostAddTags_611303(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_611304,
                                        base: "/", url: url_PostAddTags_611305,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_611286 = ref object of OpenApiRestCall_610658
proc url_GetAddTags_611288(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTags_611287(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_611289 = query.getOrDefault("Tags")
  valid_611289 = validateParameter(valid_611289, JArray, required = true, default = nil)
  if valid_611289 != nil:
    section.add "Tags", valid_611289
  var valid_611290 = query.getOrDefault("ResourceArns")
  valid_611290 = validateParameter(valid_611290, JArray, required = true, default = nil)
  if valid_611290 != nil:
    section.add "ResourceArns", valid_611290
  var valid_611291 = query.getOrDefault("Action")
  valid_611291 = validateParameter(valid_611291, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_611291 != nil:
    section.add "Action", valid_611291
  var valid_611292 = query.getOrDefault("Version")
  valid_611292 = validateParameter(valid_611292, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611292 != nil:
    section.add "Version", valid_611292
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611293 = header.getOrDefault("X-Amz-Signature")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Signature", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Content-Sha256", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-Date")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Date", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-Credential")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Credential", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Security-Token")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Security-Token", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-Algorithm")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Algorithm", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-SignedHeaders", valid_611299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611300: Call_GetAddTags_611286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_611300.validator(path, query, header, formData, body)
  let scheme = call_611300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611300.url(scheme.get, call_611300.host, call_611300.base,
                         call_611300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611300, url, valid)

proc call*(call_611301: Call_GetAddTags_611286; Tags: JsonNode;
          ResourceArns: JsonNode; Action: string = "AddTags";
          Version: string = "2015-12-01"): Recallable =
  ## getAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611302 = newJObject()
  if Tags != nil:
    query_611302.add "Tags", Tags
  if ResourceArns != nil:
    query_611302.add "ResourceArns", ResourceArns
  add(query_611302, "Action", newJString(Action))
  add(query_611302, "Version", newJString(Version))
  result = call_611301.call(nil, query_611302, nil, nil, nil)

var getAddTags* = Call_GetAddTags_611286(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_611287,
                                      base: "/", url: url_GetAddTags_611288,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateListener_611342 = ref object of OpenApiRestCall_610658
proc url_PostCreateListener_611344(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateListener_611343(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611345 = query.getOrDefault("Action")
  valid_611345 = validateParameter(valid_611345, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_611345 != nil:
    section.add "Action", valid_611345
  var valid_611346 = query.getOrDefault("Version")
  valid_611346 = validateParameter(valid_611346, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611346 != nil:
    section.add "Version", valid_611346
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611347 = header.getOrDefault("X-Amz-Signature")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Signature", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Content-Sha256", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Date")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Date", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-Credential")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Credential", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Security-Token")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Security-Token", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-Algorithm")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Algorithm", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-SignedHeaders", valid_611353
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt (required)
  ##       : The port on which the load balancer is listening.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list for the listener, use <a>AddListenerCertificates</a>.</p>
  ##   DefaultActions: JArray (required)
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Protocol: JString (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   SslPolicy: JString
  ##            : [HTTPS and TLS listeners] The security policy that defines which ciphers and protocols are supported. The default is the current predefined security policy.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Port` field"
  var valid_611354 = formData.getOrDefault("Port")
  valid_611354 = validateParameter(valid_611354, JInt, required = true, default = nil)
  if valid_611354 != nil:
    section.add "Port", valid_611354
  var valid_611355 = formData.getOrDefault("Certificates")
  valid_611355 = validateParameter(valid_611355, JArray, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "Certificates", valid_611355
  var valid_611356 = formData.getOrDefault("DefaultActions")
  valid_611356 = validateParameter(valid_611356, JArray, required = true, default = nil)
  if valid_611356 != nil:
    section.add "DefaultActions", valid_611356
  var valid_611357 = formData.getOrDefault("Protocol")
  valid_611357 = validateParameter(valid_611357, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_611357 != nil:
    section.add "Protocol", valid_611357
  var valid_611358 = formData.getOrDefault("SslPolicy")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "SslPolicy", valid_611358
  var valid_611359 = formData.getOrDefault("LoadBalancerArn")
  valid_611359 = validateParameter(valid_611359, JString, required = true,
                                 default = nil)
  if valid_611359 != nil:
    section.add "LoadBalancerArn", valid_611359
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611360: Call_PostCreateListener_611342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611360.validator(path, query, header, formData, body)
  let scheme = call_611360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611360.url(scheme.get, call_611360.host, call_611360.base,
                         call_611360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611360, url, valid)

proc call*(call_611361: Call_PostCreateListener_611342; Port: int;
          DefaultActions: JsonNode; LoadBalancerArn: string;
          Certificates: JsonNode = nil; Protocol: string = "HTTP";
          Action: string = "CreateListener"; SslPolicy: string = "";
          Version: string = "2015-12-01"): Recallable =
  ## postCreateListener
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Port: int (required)
  ##       : The port on which the load balancer is listening.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list for the listener, use <a>AddListenerCertificates</a>.</p>
  ##   DefaultActions: JArray (required)
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Protocol: string (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   Action: string (required)
  ##   SslPolicy: string
  ##            : [HTTPS and TLS listeners] The security policy that defines which ciphers and protocols are supported. The default is the current predefined security policy.
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_611362 = newJObject()
  var formData_611363 = newJObject()
  add(formData_611363, "Port", newJInt(Port))
  if Certificates != nil:
    formData_611363.add "Certificates", Certificates
  if DefaultActions != nil:
    formData_611363.add "DefaultActions", DefaultActions
  add(formData_611363, "Protocol", newJString(Protocol))
  add(query_611362, "Action", newJString(Action))
  add(formData_611363, "SslPolicy", newJString(SslPolicy))
  add(query_611362, "Version", newJString(Version))
  add(formData_611363, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_611361.call(nil, query_611362, nil, formData_611363, nil)

var postCreateListener* = Call_PostCreateListener_611342(
    name: "postCreateListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=CreateListener",
    validator: validate_PostCreateListener_611343, base: "/",
    url: url_PostCreateListener_611344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateListener_611321 = ref object of OpenApiRestCall_610658
proc url_GetCreateListener_611323(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateListener_611322(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SslPolicy: JString
  ##            : [HTTPS and TLS listeners] The security policy that defines which ciphers and protocols are supported. The default is the current predefined security policy.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list for the listener, use <a>AddListenerCertificates</a>.</p>
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   DefaultActions: JArray (required)
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Action: JString (required)
  ##   Protocol: JString (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   Port: JInt (required)
  ##       : The port on which the load balancer is listening.
  ##   Version: JString (required)
  section = newJObject()
  var valid_611324 = query.getOrDefault("SslPolicy")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "SslPolicy", valid_611324
  var valid_611325 = query.getOrDefault("Certificates")
  valid_611325 = validateParameter(valid_611325, JArray, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "Certificates", valid_611325
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_611326 = query.getOrDefault("LoadBalancerArn")
  valid_611326 = validateParameter(valid_611326, JString, required = true,
                                 default = nil)
  if valid_611326 != nil:
    section.add "LoadBalancerArn", valid_611326
  var valid_611327 = query.getOrDefault("DefaultActions")
  valid_611327 = validateParameter(valid_611327, JArray, required = true, default = nil)
  if valid_611327 != nil:
    section.add "DefaultActions", valid_611327
  var valid_611328 = query.getOrDefault("Action")
  valid_611328 = validateParameter(valid_611328, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_611328 != nil:
    section.add "Action", valid_611328
  var valid_611329 = query.getOrDefault("Protocol")
  valid_611329 = validateParameter(valid_611329, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_611329 != nil:
    section.add "Protocol", valid_611329
  var valid_611330 = query.getOrDefault("Port")
  valid_611330 = validateParameter(valid_611330, JInt, required = true, default = nil)
  if valid_611330 != nil:
    section.add "Port", valid_611330
  var valid_611331 = query.getOrDefault("Version")
  valid_611331 = validateParameter(valid_611331, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611331 != nil:
    section.add "Version", valid_611331
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611332 = header.getOrDefault("X-Amz-Signature")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Signature", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Content-Sha256", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Date")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Date", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-Credential")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Credential", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-Security-Token")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Security-Token", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-Algorithm")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Algorithm", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-SignedHeaders", valid_611338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611339: Call_GetCreateListener_611321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611339.validator(path, query, header, formData, body)
  let scheme = call_611339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611339.url(scheme.get, call_611339.host, call_611339.base,
                         call_611339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611339, url, valid)

proc call*(call_611340: Call_GetCreateListener_611321; LoadBalancerArn: string;
          DefaultActions: JsonNode; Port: int; SslPolicy: string = "";
          Certificates: JsonNode = nil; Action: string = "CreateListener";
          Protocol: string = "HTTP"; Version: string = "2015-12-01"): Recallable =
  ## getCreateListener
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   SslPolicy: string
  ##            : [HTTPS and TLS listeners] The security policy that defines which ciphers and protocols are supported. The default is the current predefined security policy.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list for the listener, use <a>AddListenerCertificates</a>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   DefaultActions: JArray (required)
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Action: string (required)
  ##   Protocol: string (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   Port: int (required)
  ##       : The port on which the load balancer is listening.
  ##   Version: string (required)
  var query_611341 = newJObject()
  add(query_611341, "SslPolicy", newJString(SslPolicy))
  if Certificates != nil:
    query_611341.add "Certificates", Certificates
  add(query_611341, "LoadBalancerArn", newJString(LoadBalancerArn))
  if DefaultActions != nil:
    query_611341.add "DefaultActions", DefaultActions
  add(query_611341, "Action", newJString(Action))
  add(query_611341, "Protocol", newJString(Protocol))
  add(query_611341, "Port", newJInt(Port))
  add(query_611341, "Version", newJString(Version))
  result = call_611340.call(nil, query_611341, nil, nil, nil)

var getCreateListener* = Call_GetCreateListener_611321(name: "getCreateListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateListener", validator: validate_GetCreateListener_611322,
    base: "/", url: url_GetCreateListener_611323,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_611387 = ref object of OpenApiRestCall_610658
proc url_PostCreateLoadBalancer_611389(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateLoadBalancer_611388(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611390 = query.getOrDefault("Action")
  valid_611390 = validateParameter(valid_611390, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_611390 != nil:
    section.add "Action", valid_611390
  var valid_611391 = query.getOrDefault("Version")
  valid_611391 = validateParameter(valid_611391, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611391 != nil:
    section.add "Version", valid_611391
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611392 = header.getOrDefault("X-Amz-Signature")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Signature", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Content-Sha256", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Date")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Date", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-Credential")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Credential", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-Security-Token")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Security-Token", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Algorithm")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Algorithm", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-SignedHeaders", valid_611398
  result.add "header", section
  ## parameters in `formData` object:
  ##   IpAddressType: JString
  ##                : [Application Load Balancers] The type of IP addresses used by the subnets for your load balancer. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>.
  ##   Scheme: JString
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can route requests only from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
  ##   SecurityGroups: JArray
  ##                 : [Application Load Balancers] The IDs of the security groups for the load balancer.
  ##   Subnets: JArray
  ##          : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones.</p>
  ##   Type: JString
  ##       : The type of load balancer. The default is <code>application</code>.
  ##   Name: JString (required)
  ##       : <p>The name of the load balancer.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, must not begin or end with a hyphen, and must not begin with "internal-".</p>
  ##   Tags: JArray
  ##       : One or more tags to assign to the load balancer.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your internet-facing load balancer. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  section = newJObject()
  var valid_611399 = formData.getOrDefault("IpAddressType")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_611399 != nil:
    section.add "IpAddressType", valid_611399
  var valid_611400 = formData.getOrDefault("Scheme")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_611400 != nil:
    section.add "Scheme", valid_611400
  var valid_611401 = formData.getOrDefault("SecurityGroups")
  valid_611401 = validateParameter(valid_611401, JArray, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "SecurityGroups", valid_611401
  var valid_611402 = formData.getOrDefault("Subnets")
  valid_611402 = validateParameter(valid_611402, JArray, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "Subnets", valid_611402
  var valid_611403 = formData.getOrDefault("Type")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = newJString("application"))
  if valid_611403 != nil:
    section.add "Type", valid_611403
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_611404 = formData.getOrDefault("Name")
  valid_611404 = validateParameter(valid_611404, JString, required = true,
                                 default = nil)
  if valid_611404 != nil:
    section.add "Name", valid_611404
  var valid_611405 = formData.getOrDefault("Tags")
  valid_611405 = validateParameter(valid_611405, JArray, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "Tags", valid_611405
  var valid_611406 = formData.getOrDefault("SubnetMappings")
  valid_611406 = validateParameter(valid_611406, JArray, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "SubnetMappings", valid_611406
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611407: Call_PostCreateLoadBalancer_611387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611407.validator(path, query, header, formData, body)
  let scheme = call_611407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611407.url(scheme.get, call_611407.host, call_611407.base,
                         call_611407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611407, url, valid)

proc call*(call_611408: Call_PostCreateLoadBalancer_611387; Name: string;
          IpAddressType: string = "ipv4"; Scheme: string = "internet-facing";
          SecurityGroups: JsonNode = nil; Subnets: JsonNode = nil;
          Type: string = "application"; Action: string = "CreateLoadBalancer";
          Tags: JsonNode = nil; SubnetMappings: JsonNode = nil;
          Version: string = "2015-12-01"): Recallable =
  ## postCreateLoadBalancer
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   IpAddressType: string
  ##                : [Application Load Balancers] The type of IP addresses used by the subnets for your load balancer. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>.
  ##   Scheme: string
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can route requests only from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
  ##   SecurityGroups: JArray
  ##                 : [Application Load Balancers] The IDs of the security groups for the load balancer.
  ##   Subnets: JArray
  ##          : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones.</p>
  ##   Type: string
  ##       : The type of load balancer. The default is <code>application</code>.
  ##   Action: string (required)
  ##   Name: string (required)
  ##       : <p>The name of the load balancer.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, must not begin or end with a hyphen, and must not begin with "internal-".</p>
  ##   Tags: JArray
  ##       : One or more tags to assign to the load balancer.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your internet-facing load balancer. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   Version: string (required)
  var query_611409 = newJObject()
  var formData_611410 = newJObject()
  add(formData_611410, "IpAddressType", newJString(IpAddressType))
  add(formData_611410, "Scheme", newJString(Scheme))
  if SecurityGroups != nil:
    formData_611410.add "SecurityGroups", SecurityGroups
  if Subnets != nil:
    formData_611410.add "Subnets", Subnets
  add(formData_611410, "Type", newJString(Type))
  add(query_611409, "Action", newJString(Action))
  add(formData_611410, "Name", newJString(Name))
  if Tags != nil:
    formData_611410.add "Tags", Tags
  if SubnetMappings != nil:
    formData_611410.add "SubnetMappings", SubnetMappings
  add(query_611409, "Version", newJString(Version))
  result = call_611408.call(nil, query_611409, nil, formData_611410, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_611387(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_611388, base: "/",
    url: url_PostCreateLoadBalancer_611389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_611364 = ref object of OpenApiRestCall_610658
proc url_GetCreateLoadBalancer_611366(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateLoadBalancer_611365(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your internet-facing load balancer. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   Type: JString
  ##       : The type of load balancer. The default is <code>application</code>.
  ##   Tags: JArray
  ##       : One or more tags to assign to the load balancer.
  ##   Scheme: JString
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can route requests only from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
  ##   IpAddressType: JString
  ##                : [Application Load Balancers] The type of IP addresses used by the subnets for your load balancer. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>.
  ##   SecurityGroups: JArray
  ##                 : [Application Load Balancers] The IDs of the security groups for the load balancer.
  ##   Name: JString (required)
  ##       : <p>The name of the load balancer.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, must not begin or end with a hyphen, and must not begin with "internal-".</p>
  ##   Action: JString (required)
  ##   Subnets: JArray
  ##          : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_611367 = query.getOrDefault("SubnetMappings")
  valid_611367 = validateParameter(valid_611367, JArray, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "SubnetMappings", valid_611367
  var valid_611368 = query.getOrDefault("Type")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = newJString("application"))
  if valid_611368 != nil:
    section.add "Type", valid_611368
  var valid_611369 = query.getOrDefault("Tags")
  valid_611369 = validateParameter(valid_611369, JArray, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "Tags", valid_611369
  var valid_611370 = query.getOrDefault("Scheme")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_611370 != nil:
    section.add "Scheme", valid_611370
  var valid_611371 = query.getOrDefault("IpAddressType")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_611371 != nil:
    section.add "IpAddressType", valid_611371
  var valid_611372 = query.getOrDefault("SecurityGroups")
  valid_611372 = validateParameter(valid_611372, JArray, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "SecurityGroups", valid_611372
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_611373 = query.getOrDefault("Name")
  valid_611373 = validateParameter(valid_611373, JString, required = true,
                                 default = nil)
  if valid_611373 != nil:
    section.add "Name", valid_611373
  var valid_611374 = query.getOrDefault("Action")
  valid_611374 = validateParameter(valid_611374, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_611374 != nil:
    section.add "Action", valid_611374
  var valid_611375 = query.getOrDefault("Subnets")
  valid_611375 = validateParameter(valid_611375, JArray, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "Subnets", valid_611375
  var valid_611376 = query.getOrDefault("Version")
  valid_611376 = validateParameter(valid_611376, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611376 != nil:
    section.add "Version", valid_611376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611377 = header.getOrDefault("X-Amz-Signature")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Signature", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Content-Sha256", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Date")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Date", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-Credential")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Credential", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-Security-Token")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Security-Token", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-Algorithm")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Algorithm", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-SignedHeaders", valid_611383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611384: Call_GetCreateLoadBalancer_611364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611384.validator(path, query, header, formData, body)
  let scheme = call_611384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611384.url(scheme.get, call_611384.host, call_611384.base,
                         call_611384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611384, url, valid)

proc call*(call_611385: Call_GetCreateLoadBalancer_611364; Name: string;
          SubnetMappings: JsonNode = nil; Type: string = "application";
          Tags: JsonNode = nil; Scheme: string = "internet-facing";
          IpAddressType: string = "ipv4"; SecurityGroups: JsonNode = nil;
          Action: string = "CreateLoadBalancer"; Subnets: JsonNode = nil;
          Version: string = "2015-12-01"): Recallable =
  ## getCreateLoadBalancer
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your internet-facing load balancer. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   Type: string
  ##       : The type of load balancer. The default is <code>application</code>.
  ##   Tags: JArray
  ##       : One or more tags to assign to the load balancer.
  ##   Scheme: string
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can route requests only from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
  ##   IpAddressType: string
  ##                : [Application Load Balancers] The type of IP addresses used by the subnets for your load balancer. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>.
  ##   SecurityGroups: JArray
  ##                 : [Application Load Balancers] The IDs of the security groups for the load balancer.
  ##   Name: string (required)
  ##       : <p>The name of the load balancer.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, must not begin or end with a hyphen, and must not begin with "internal-".</p>
  ##   Action: string (required)
  ##   Subnets: JArray
  ##          : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones.</p>
  ##   Version: string (required)
  var query_611386 = newJObject()
  if SubnetMappings != nil:
    query_611386.add "SubnetMappings", SubnetMappings
  add(query_611386, "Type", newJString(Type))
  if Tags != nil:
    query_611386.add "Tags", Tags
  add(query_611386, "Scheme", newJString(Scheme))
  add(query_611386, "IpAddressType", newJString(IpAddressType))
  if SecurityGroups != nil:
    query_611386.add "SecurityGroups", SecurityGroups
  add(query_611386, "Name", newJString(Name))
  add(query_611386, "Action", newJString(Action))
  if Subnets != nil:
    query_611386.add "Subnets", Subnets
  add(query_611386, "Version", newJString(Version))
  result = call_611385.call(nil, query_611386, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_611364(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_611365, base: "/",
    url: url_GetCreateLoadBalancer_611366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateRule_611430 = ref object of OpenApiRestCall_610658
proc url_PostCreateRule_611432(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateRule_611431(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611433 = query.getOrDefault("Action")
  valid_611433 = validateParameter(valid_611433, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_611433 != nil:
    section.add "Action", valid_611433
  var valid_611434 = query.getOrDefault("Version")
  valid_611434 = validateParameter(valid_611434, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611434 != nil:
    section.add "Version", valid_611434
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611435 = header.getOrDefault("X-Amz-Signature")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Signature", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Content-Sha256", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Date")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Date", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Credential")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Credential", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Security-Token")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Security-Token", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-Algorithm")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-Algorithm", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-SignedHeaders", valid_611441
  result.add "header", section
  ## parameters in `formData` object:
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Priority: JInt (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Actions` field"
  var valid_611442 = formData.getOrDefault("Actions")
  valid_611442 = validateParameter(valid_611442, JArray, required = true, default = nil)
  if valid_611442 != nil:
    section.add "Actions", valid_611442
  var valid_611443 = formData.getOrDefault("Conditions")
  valid_611443 = validateParameter(valid_611443, JArray, required = true, default = nil)
  if valid_611443 != nil:
    section.add "Conditions", valid_611443
  var valid_611444 = formData.getOrDefault("ListenerArn")
  valid_611444 = validateParameter(valid_611444, JString, required = true,
                                 default = nil)
  if valid_611444 != nil:
    section.add "ListenerArn", valid_611444
  var valid_611445 = formData.getOrDefault("Priority")
  valid_611445 = validateParameter(valid_611445, JInt, required = true, default = nil)
  if valid_611445 != nil:
    section.add "Priority", valid_611445
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611446: Call_PostCreateRule_611430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_611446.validator(path, query, header, formData, body)
  let scheme = call_611446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611446.url(scheme.get, call_611446.host, call_611446.base,
                         call_611446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611446, url, valid)

proc call*(call_611447: Call_PostCreateRule_611430; Actions: JsonNode;
          Conditions: JsonNode; ListenerArn: string; Priority: int;
          Action: string = "CreateRule"; Version: string = "2015-12-01"): Recallable =
  ## postCreateRule
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Priority: int (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611448 = newJObject()
  var formData_611449 = newJObject()
  if Actions != nil:
    formData_611449.add "Actions", Actions
  if Conditions != nil:
    formData_611449.add "Conditions", Conditions
  add(formData_611449, "ListenerArn", newJString(ListenerArn))
  add(formData_611449, "Priority", newJInt(Priority))
  add(query_611448, "Action", newJString(Action))
  add(query_611448, "Version", newJString(Version))
  result = call_611447.call(nil, query_611448, nil, formData_611449, nil)

var postCreateRule* = Call_PostCreateRule_611430(name: "postCreateRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_PostCreateRule_611431,
    base: "/", url: url_PostCreateRule_611432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateRule_611411 = ref object of OpenApiRestCall_610658
proc url_GetCreateRule_611413(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateRule_611412(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Priority: JInt (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Actions` field"
  var valid_611414 = query.getOrDefault("Actions")
  valid_611414 = validateParameter(valid_611414, JArray, required = true, default = nil)
  if valid_611414 != nil:
    section.add "Actions", valid_611414
  var valid_611415 = query.getOrDefault("ListenerArn")
  valid_611415 = validateParameter(valid_611415, JString, required = true,
                                 default = nil)
  if valid_611415 != nil:
    section.add "ListenerArn", valid_611415
  var valid_611416 = query.getOrDefault("Priority")
  valid_611416 = validateParameter(valid_611416, JInt, required = true, default = nil)
  if valid_611416 != nil:
    section.add "Priority", valid_611416
  var valid_611417 = query.getOrDefault("Action")
  valid_611417 = validateParameter(valid_611417, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_611417 != nil:
    section.add "Action", valid_611417
  var valid_611418 = query.getOrDefault("Version")
  valid_611418 = validateParameter(valid_611418, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611418 != nil:
    section.add "Version", valid_611418
  var valid_611419 = query.getOrDefault("Conditions")
  valid_611419 = validateParameter(valid_611419, JArray, required = true, default = nil)
  if valid_611419 != nil:
    section.add "Conditions", valid_611419
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611420 = header.getOrDefault("X-Amz-Signature")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Signature", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Content-Sha256", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Date")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Date", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Credential")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Credential", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Security-Token")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Security-Token", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-Algorithm")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Algorithm", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-SignedHeaders", valid_611426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611427: Call_GetCreateRule_611411; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_611427.validator(path, query, header, formData, body)
  let scheme = call_611427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611427.url(scheme.get, call_611427.host, call_611427.base,
                         call_611427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611427, url, valid)

proc call*(call_611428: Call_GetCreateRule_611411; Actions: JsonNode;
          ListenerArn: string; Priority: int; Conditions: JsonNode;
          Action: string = "CreateRule"; Version: string = "2015-12-01"): Recallable =
  ## getCreateRule
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Priority: int (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  var query_611429 = newJObject()
  if Actions != nil:
    query_611429.add "Actions", Actions
  add(query_611429, "ListenerArn", newJString(ListenerArn))
  add(query_611429, "Priority", newJInt(Priority))
  add(query_611429, "Action", newJString(Action))
  add(query_611429, "Version", newJString(Version))
  if Conditions != nil:
    query_611429.add "Conditions", Conditions
  result = call_611428.call(nil, query_611429, nil, nil, nil)

var getCreateRule* = Call_GetCreateRule_611411(name: "getCreateRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_GetCreateRule_611412,
    base: "/", url: url_GetCreateRule_611413, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTargetGroup_611479 = ref object of OpenApiRestCall_610658
proc url_PostCreateTargetGroup_611481(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateTargetGroup_611480(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611482 = query.getOrDefault("Action")
  valid_611482 = validateParameter(valid_611482, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_611482 != nil:
    section.add "Action", valid_611482
  var valid_611483 = query.getOrDefault("Version")
  valid_611483 = validateParameter(valid_611483, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611483 != nil:
    section.add "Version", valid_611483
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611484 = header.getOrDefault("X-Amz-Signature")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Signature", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Content-Sha256", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Date")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Date", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-Credential")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-Credential", valid_611487
  var valid_611488 = header.getOrDefault("X-Amz-Security-Token")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "X-Amz-Security-Token", valid_611488
  var valid_611489 = header.getOrDefault("X-Amz-Algorithm")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Algorithm", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-SignedHeaders", valid_611490
  result.add "header", section
  ## parameters in `formData` object:
  ##   HealthCheckProtocol: JString
  ##                      : The protocol the load balancer uses when performing health checks on targets. For Application Load Balancers, the default is HTTP. For Network Load Balancers, the default is TCP. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.
  ##   Port: JInt
  ##       : The port on which the targets receive traffic. This port is used unless you specify a port override when registering the target. If the target is a Lambda function, this parameter does not apply.
  ##   HealthCheckPort: JString
  ##                  : The port the load balancer uses when performing health checks on targets. The default is <code>traffic-port</code>, which is the port on which each target receives traffic from the load balancer.
  ##   VpcId: JString
  ##        : The identifier of the virtual private cloud (VPC). If the target is a Lambda function, this parameter does not apply. Otherwise, this parameter is required.
  ##   HealthCheckEnabled: JBool
  ##                     : Indicates whether health checks are enabled. If the target type is <code>lambda</code>, health checks are disabled by default but can be enabled. If the target type is <code>instance</code> or <code>ip</code>, health checks are always enabled and cannot be disabled.
  ##   HealthCheckPath: JString
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination on the targets for health checks. The default is /.
  ##   TargetType: JString
  ##             : <p>The type of target that you must specify when registering targets with this target group. You can't specify targets for a target group using more than one target type.</p> <ul> <li> <p> <code>instance</code> - Targets are specified by instance ID. This is the default value. If the target group protocol is UDP or TCP_UDP, the target type must be <code>instance</code>.</p> </li> <li> <p> <code>ip</code> - Targets are specified by IP address. You can specify IP addresses from the subnets of the virtual private cloud (VPC) for the target group, the RFC 1918 range (10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16), and the RFC 6598 range (100.64.0.0/10). You can't specify publicly routable IP addresses.</p> </li> <li> <p> <code>lambda</code> - The target groups contains a single Lambda function.</p> </li> </ul>
  ##   HealthCheckTimeoutSeconds: JInt
  ##                            : The amount of time, in seconds, during which no response from a target means a failed health check. For target groups with a protocol of HTTP or HTTPS, the default is 5 seconds. For target groups with a protocol of TCP or TLS, this value must be 6 seconds for HTTP health checks and 10 seconds for TCP and HTTPS health checks. If the target type is <code>lambda</code>, the default is 30 seconds.
  ##   HealthyThresholdCount: JInt
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy. For target groups with a protocol of HTTP or HTTPS, the default is 5. For target groups with a protocol of TCP or TLS, the default is 3. If the target type is <code>lambda</code>, the default is 5.
  ##   HealthCheckIntervalSeconds: JInt
  ##                             : The approximate amount of time, in seconds, between health checks of an individual target. For HTTP and HTTPS health checks, the range is 5–300 seconds. For TCP health checks, the supported values are 10 and 30 seconds. If the target type is <code>instance</code> or <code>ip</code>, the default is 30 seconds. If the target type is <code>lambda</code>, the default is 35 seconds.
  ##   Protocol: JString
  ##           : The protocol to use for routing traffic to the targets. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, or TCP_UDP. A TCP_UDP listener must be associated with a TCP_UDP target group. If the target is a Lambda function, this parameter does not apply.
  ##   UnhealthyThresholdCount: JInt
  ##                          : The number of consecutive health check failures required before considering a target unhealthy. For target groups with a protocol of HTTP or HTTPS, the default is 2. For target groups with a protocol of TCP or TLS, this value must be the same as the healthy threshold count. If the target type is <code>lambda</code>, the default is 2.
  ##   Matcher.HttpCode: JString
  ##                   : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   Name: JString (required)
  ##       : <p>The name of the target group.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen.</p>
  section = newJObject()
  var valid_611491 = formData.getOrDefault("HealthCheckProtocol")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_611491 != nil:
    section.add "HealthCheckProtocol", valid_611491
  var valid_611492 = formData.getOrDefault("Port")
  valid_611492 = validateParameter(valid_611492, JInt, required = false, default = nil)
  if valid_611492 != nil:
    section.add "Port", valid_611492
  var valid_611493 = formData.getOrDefault("HealthCheckPort")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "HealthCheckPort", valid_611493
  var valid_611494 = formData.getOrDefault("VpcId")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "VpcId", valid_611494
  var valid_611495 = formData.getOrDefault("HealthCheckEnabled")
  valid_611495 = validateParameter(valid_611495, JBool, required = false, default = nil)
  if valid_611495 != nil:
    section.add "HealthCheckEnabled", valid_611495
  var valid_611496 = formData.getOrDefault("HealthCheckPath")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "HealthCheckPath", valid_611496
  var valid_611497 = formData.getOrDefault("TargetType")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = newJString("instance"))
  if valid_611497 != nil:
    section.add "TargetType", valid_611497
  var valid_611498 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_611498 = validateParameter(valid_611498, JInt, required = false, default = nil)
  if valid_611498 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_611498
  var valid_611499 = formData.getOrDefault("HealthyThresholdCount")
  valid_611499 = validateParameter(valid_611499, JInt, required = false, default = nil)
  if valid_611499 != nil:
    section.add "HealthyThresholdCount", valid_611499
  var valid_611500 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_611500 = validateParameter(valid_611500, JInt, required = false, default = nil)
  if valid_611500 != nil:
    section.add "HealthCheckIntervalSeconds", valid_611500
  var valid_611501 = formData.getOrDefault("Protocol")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_611501 != nil:
    section.add "Protocol", valid_611501
  var valid_611502 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_611502 = validateParameter(valid_611502, JInt, required = false, default = nil)
  if valid_611502 != nil:
    section.add "UnhealthyThresholdCount", valid_611502
  var valid_611503 = formData.getOrDefault("Matcher.HttpCode")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "Matcher.HttpCode", valid_611503
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_611504 = formData.getOrDefault("Name")
  valid_611504 = validateParameter(valid_611504, JString, required = true,
                                 default = nil)
  if valid_611504 != nil:
    section.add "Name", valid_611504
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611505: Call_PostCreateTargetGroup_611479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611505.validator(path, query, header, formData, body)
  let scheme = call_611505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611505.url(scheme.get, call_611505.host, call_611505.base,
                         call_611505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611505, url, valid)

proc call*(call_611506: Call_PostCreateTargetGroup_611479; Name: string;
          HealthCheckProtocol: string = "HTTP"; Port: int = 0;
          HealthCheckPort: string = ""; VpcId: string = "";
          HealthCheckEnabled: bool = false; HealthCheckPath: string = "";
          TargetType: string = "instance"; HealthCheckTimeoutSeconds: int = 0;
          HealthyThresholdCount: int = 0; HealthCheckIntervalSeconds: int = 0;
          Protocol: string = "HTTP"; UnhealthyThresholdCount: int = 0;
          MatcherHttpCode: string = ""; Action: string = "CreateTargetGroup";
          Version: string = "2015-12-01"): Recallable =
  ## postCreateTargetGroup
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   HealthCheckProtocol: string
  ##                      : The protocol the load balancer uses when performing health checks on targets. For Application Load Balancers, the default is HTTP. For Network Load Balancers, the default is TCP. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.
  ##   Port: int
  ##       : The port on which the targets receive traffic. This port is used unless you specify a port override when registering the target. If the target is a Lambda function, this parameter does not apply.
  ##   HealthCheckPort: string
  ##                  : The port the load balancer uses when performing health checks on targets. The default is <code>traffic-port</code>, which is the port on which each target receives traffic from the load balancer.
  ##   VpcId: string
  ##        : The identifier of the virtual private cloud (VPC). If the target is a Lambda function, this parameter does not apply. Otherwise, this parameter is required.
  ##   HealthCheckEnabled: bool
  ##                     : Indicates whether health checks are enabled. If the target type is <code>lambda</code>, health checks are disabled by default but can be enabled. If the target type is <code>instance</code> or <code>ip</code>, health checks are always enabled and cannot be disabled.
  ##   HealthCheckPath: string
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination on the targets for health checks. The default is /.
  ##   TargetType: string
  ##             : <p>The type of target that you must specify when registering targets with this target group. You can't specify targets for a target group using more than one target type.</p> <ul> <li> <p> <code>instance</code> - Targets are specified by instance ID. This is the default value. If the target group protocol is UDP or TCP_UDP, the target type must be <code>instance</code>.</p> </li> <li> <p> <code>ip</code> - Targets are specified by IP address. You can specify IP addresses from the subnets of the virtual private cloud (VPC) for the target group, the RFC 1918 range (10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16), and the RFC 6598 range (100.64.0.0/10). You can't specify publicly routable IP addresses.</p> </li> <li> <p> <code>lambda</code> - The target groups contains a single Lambda function.</p> </li> </ul>
  ##   HealthCheckTimeoutSeconds: int
  ##                            : The amount of time, in seconds, during which no response from a target means a failed health check. For target groups with a protocol of HTTP or HTTPS, the default is 5 seconds. For target groups with a protocol of TCP or TLS, this value must be 6 seconds for HTTP health checks and 10 seconds for TCP and HTTPS health checks. If the target type is <code>lambda</code>, the default is 30 seconds.
  ##   HealthyThresholdCount: int
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy. For target groups with a protocol of HTTP or HTTPS, the default is 5. For target groups with a protocol of TCP or TLS, the default is 3. If the target type is <code>lambda</code>, the default is 5.
  ##   HealthCheckIntervalSeconds: int
  ##                             : The approximate amount of time, in seconds, between health checks of an individual target. For HTTP and HTTPS health checks, the range is 5–300 seconds. For TCP health checks, the supported values are 10 and 30 seconds. If the target type is <code>instance</code> or <code>ip</code>, the default is 30 seconds. If the target type is <code>lambda</code>, the default is 35 seconds.
  ##   Protocol: string
  ##           : The protocol to use for routing traffic to the targets. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, or TCP_UDP. A TCP_UDP listener must be associated with a TCP_UDP target group. If the target is a Lambda function, this parameter does not apply.
  ##   UnhealthyThresholdCount: int
  ##                          : The number of consecutive health check failures required before considering a target unhealthy. For target groups with a protocol of HTTP or HTTPS, the default is 2. For target groups with a protocol of TCP or TLS, this value must be the same as the healthy threshold count. If the target type is <code>lambda</code>, the default is 2.
  ##   MatcherHttpCode: string
  ##                  : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   Action: string (required)
  ##   Name: string (required)
  ##       : <p>The name of the target group.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen.</p>
  ##   Version: string (required)
  var query_611507 = newJObject()
  var formData_611508 = newJObject()
  add(formData_611508, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_611508, "Port", newJInt(Port))
  add(formData_611508, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_611508, "VpcId", newJString(VpcId))
  add(formData_611508, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_611508, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_611508, "TargetType", newJString(TargetType))
  add(formData_611508, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_611508, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_611508, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_611508, "Protocol", newJString(Protocol))
  add(formData_611508, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_611508, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_611507, "Action", newJString(Action))
  add(formData_611508, "Name", newJString(Name))
  add(query_611507, "Version", newJString(Version))
  result = call_611506.call(nil, query_611507, nil, formData_611508, nil)

var postCreateTargetGroup* = Call_PostCreateTargetGroup_611479(
    name: "postCreateTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup",
    validator: validate_PostCreateTargetGroup_611480, base: "/",
    url: url_PostCreateTargetGroup_611481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTargetGroup_611450 = ref object of OpenApiRestCall_610658
proc url_GetCreateTargetGroup_611452(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateTargetGroup_611451(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   HealthCheckPort: JString
  ##                  : The port the load balancer uses when performing health checks on targets. The default is <code>traffic-port</code>, which is the port on which each target receives traffic from the load balancer.
  ##   TargetType: JString
  ##             : <p>The type of target that you must specify when registering targets with this target group. You can't specify targets for a target group using more than one target type.</p> <ul> <li> <p> <code>instance</code> - Targets are specified by instance ID. This is the default value. If the target group protocol is UDP or TCP_UDP, the target type must be <code>instance</code>.</p> </li> <li> <p> <code>ip</code> - Targets are specified by IP address. You can specify IP addresses from the subnets of the virtual private cloud (VPC) for the target group, the RFC 1918 range (10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16), and the RFC 6598 range (100.64.0.0/10). You can't specify publicly routable IP addresses.</p> </li> <li> <p> <code>lambda</code> - The target groups contains a single Lambda function.</p> </li> </ul>
  ##   HealthCheckPath: JString
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination on the targets for health checks. The default is /.
  ##   VpcId: JString
  ##        : The identifier of the virtual private cloud (VPC). If the target is a Lambda function, this parameter does not apply. Otherwise, this parameter is required.
  ##   HealthCheckProtocol: JString
  ##                      : The protocol the load balancer uses when performing health checks on targets. For Application Load Balancers, the default is HTTP. For Network Load Balancers, the default is TCP. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.
  ##   Matcher.HttpCode: JString
  ##                   : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   Name: JString (required)
  ##       : <p>The name of the target group.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen.</p>
  ##   HealthCheckIntervalSeconds: JInt
  ##                             : The approximate amount of time, in seconds, between health checks of an individual target. For HTTP and HTTPS health checks, the range is 5–300 seconds. For TCP health checks, the supported values are 10 and 30 seconds. If the target type is <code>instance</code> or <code>ip</code>, the default is 30 seconds. If the target type is <code>lambda</code>, the default is 35 seconds.
  ##   HealthCheckEnabled: JBool
  ##                     : Indicates whether health checks are enabled. If the target type is <code>lambda</code>, health checks are disabled by default but can be enabled. If the target type is <code>instance</code> or <code>ip</code>, health checks are always enabled and cannot be disabled.
  ##   HealthyThresholdCount: JInt
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy. For target groups with a protocol of HTTP or HTTPS, the default is 5. For target groups with a protocol of TCP or TLS, the default is 3. If the target type is <code>lambda</code>, the default is 5.
  ##   UnhealthyThresholdCount: JInt
  ##                          : The number of consecutive health check failures required before considering a target unhealthy. For target groups with a protocol of HTTP or HTTPS, the default is 2. For target groups with a protocol of TCP or TLS, this value must be the same as the healthy threshold count. If the target type is <code>lambda</code>, the default is 2.
  ##   Action: JString (required)
  ##   Protocol: JString
  ##           : The protocol to use for routing traffic to the targets. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, or TCP_UDP. A TCP_UDP listener must be associated with a TCP_UDP target group. If the target is a Lambda function, this parameter does not apply.
  ##   Port: JInt
  ##       : The port on which the targets receive traffic. This port is used unless you specify a port override when registering the target. If the target is a Lambda function, this parameter does not apply.
  ##   HealthCheckTimeoutSeconds: JInt
  ##                            : The amount of time, in seconds, during which no response from a target means a failed health check. For target groups with a protocol of HTTP or HTTPS, the default is 5 seconds. For target groups with a protocol of TCP or TLS, this value must be 6 seconds for HTTP health checks and 10 seconds for TCP and HTTPS health checks. If the target type is <code>lambda</code>, the default is 30 seconds.
  ##   Version: JString (required)
  section = newJObject()
  var valid_611453 = query.getOrDefault("HealthCheckPort")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "HealthCheckPort", valid_611453
  var valid_611454 = query.getOrDefault("TargetType")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = newJString("instance"))
  if valid_611454 != nil:
    section.add "TargetType", valid_611454
  var valid_611455 = query.getOrDefault("HealthCheckPath")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "HealthCheckPath", valid_611455
  var valid_611456 = query.getOrDefault("VpcId")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "VpcId", valid_611456
  var valid_611457 = query.getOrDefault("HealthCheckProtocol")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_611457 != nil:
    section.add "HealthCheckProtocol", valid_611457
  var valid_611458 = query.getOrDefault("Matcher.HttpCode")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "Matcher.HttpCode", valid_611458
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_611459 = query.getOrDefault("Name")
  valid_611459 = validateParameter(valid_611459, JString, required = true,
                                 default = nil)
  if valid_611459 != nil:
    section.add "Name", valid_611459
  var valid_611460 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_611460 = validateParameter(valid_611460, JInt, required = false, default = nil)
  if valid_611460 != nil:
    section.add "HealthCheckIntervalSeconds", valid_611460
  var valid_611461 = query.getOrDefault("HealthCheckEnabled")
  valid_611461 = validateParameter(valid_611461, JBool, required = false, default = nil)
  if valid_611461 != nil:
    section.add "HealthCheckEnabled", valid_611461
  var valid_611462 = query.getOrDefault("HealthyThresholdCount")
  valid_611462 = validateParameter(valid_611462, JInt, required = false, default = nil)
  if valid_611462 != nil:
    section.add "HealthyThresholdCount", valid_611462
  var valid_611463 = query.getOrDefault("UnhealthyThresholdCount")
  valid_611463 = validateParameter(valid_611463, JInt, required = false, default = nil)
  if valid_611463 != nil:
    section.add "UnhealthyThresholdCount", valid_611463
  var valid_611464 = query.getOrDefault("Action")
  valid_611464 = validateParameter(valid_611464, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_611464 != nil:
    section.add "Action", valid_611464
  var valid_611465 = query.getOrDefault("Protocol")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_611465 != nil:
    section.add "Protocol", valid_611465
  var valid_611466 = query.getOrDefault("Port")
  valid_611466 = validateParameter(valid_611466, JInt, required = false, default = nil)
  if valid_611466 != nil:
    section.add "Port", valid_611466
  var valid_611467 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_611467 = validateParameter(valid_611467, JInt, required = false, default = nil)
  if valid_611467 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_611467
  var valid_611468 = query.getOrDefault("Version")
  valid_611468 = validateParameter(valid_611468, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611468 != nil:
    section.add "Version", valid_611468
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611469 = header.getOrDefault("X-Amz-Signature")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Signature", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Content-Sha256", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-Date")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-Date", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-Credential")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-Credential", valid_611472
  var valid_611473 = header.getOrDefault("X-Amz-Security-Token")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "X-Amz-Security-Token", valid_611473
  var valid_611474 = header.getOrDefault("X-Amz-Algorithm")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-Algorithm", valid_611474
  var valid_611475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-SignedHeaders", valid_611475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611476: Call_GetCreateTargetGroup_611450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611476.validator(path, query, header, formData, body)
  let scheme = call_611476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611476.url(scheme.get, call_611476.host, call_611476.base,
                         call_611476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611476, url, valid)

proc call*(call_611477: Call_GetCreateTargetGroup_611450; Name: string;
          HealthCheckPort: string = ""; TargetType: string = "instance";
          HealthCheckPath: string = ""; VpcId: string = "";
          HealthCheckProtocol: string = "HTTP"; MatcherHttpCode: string = "";
          HealthCheckIntervalSeconds: int = 0; HealthCheckEnabled: bool = false;
          HealthyThresholdCount: int = 0; UnhealthyThresholdCount: int = 0;
          Action: string = "CreateTargetGroup"; Protocol: string = "HTTP";
          Port: int = 0; HealthCheckTimeoutSeconds: int = 0;
          Version: string = "2015-12-01"): Recallable =
  ## getCreateTargetGroup
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   HealthCheckPort: string
  ##                  : The port the load balancer uses when performing health checks on targets. The default is <code>traffic-port</code>, which is the port on which each target receives traffic from the load balancer.
  ##   TargetType: string
  ##             : <p>The type of target that you must specify when registering targets with this target group. You can't specify targets for a target group using more than one target type.</p> <ul> <li> <p> <code>instance</code> - Targets are specified by instance ID. This is the default value. If the target group protocol is UDP or TCP_UDP, the target type must be <code>instance</code>.</p> </li> <li> <p> <code>ip</code> - Targets are specified by IP address. You can specify IP addresses from the subnets of the virtual private cloud (VPC) for the target group, the RFC 1918 range (10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16), and the RFC 6598 range (100.64.0.0/10). You can't specify publicly routable IP addresses.</p> </li> <li> <p> <code>lambda</code> - The target groups contains a single Lambda function.</p> </li> </ul>
  ##   HealthCheckPath: string
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination on the targets for health checks. The default is /.
  ##   VpcId: string
  ##        : The identifier of the virtual private cloud (VPC). If the target is a Lambda function, this parameter does not apply. Otherwise, this parameter is required.
  ##   HealthCheckProtocol: string
  ##                      : The protocol the load balancer uses when performing health checks on targets. For Application Load Balancers, the default is HTTP. For Network Load Balancers, the default is TCP. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.
  ##   MatcherHttpCode: string
  ##                  : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   Name: string (required)
  ##       : <p>The name of the target group.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen.</p>
  ##   HealthCheckIntervalSeconds: int
  ##                             : The approximate amount of time, in seconds, between health checks of an individual target. For HTTP and HTTPS health checks, the range is 5–300 seconds. For TCP health checks, the supported values are 10 and 30 seconds. If the target type is <code>instance</code> or <code>ip</code>, the default is 30 seconds. If the target type is <code>lambda</code>, the default is 35 seconds.
  ##   HealthCheckEnabled: bool
  ##                     : Indicates whether health checks are enabled. If the target type is <code>lambda</code>, health checks are disabled by default but can be enabled. If the target type is <code>instance</code> or <code>ip</code>, health checks are always enabled and cannot be disabled.
  ##   HealthyThresholdCount: int
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy. For target groups with a protocol of HTTP or HTTPS, the default is 5. For target groups with a protocol of TCP or TLS, the default is 3. If the target type is <code>lambda</code>, the default is 5.
  ##   UnhealthyThresholdCount: int
  ##                          : The number of consecutive health check failures required before considering a target unhealthy. For target groups with a protocol of HTTP or HTTPS, the default is 2. For target groups with a protocol of TCP or TLS, this value must be the same as the healthy threshold count. If the target type is <code>lambda</code>, the default is 2.
  ##   Action: string (required)
  ##   Protocol: string
  ##           : The protocol to use for routing traffic to the targets. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, or TCP_UDP. A TCP_UDP listener must be associated with a TCP_UDP target group. If the target is a Lambda function, this parameter does not apply.
  ##   Port: int
  ##       : The port on which the targets receive traffic. This port is used unless you specify a port override when registering the target. If the target is a Lambda function, this parameter does not apply.
  ##   HealthCheckTimeoutSeconds: int
  ##                            : The amount of time, in seconds, during which no response from a target means a failed health check. For target groups with a protocol of HTTP or HTTPS, the default is 5 seconds. For target groups with a protocol of TCP or TLS, this value must be 6 seconds for HTTP health checks and 10 seconds for TCP and HTTPS health checks. If the target type is <code>lambda</code>, the default is 30 seconds.
  ##   Version: string (required)
  var query_611478 = newJObject()
  add(query_611478, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_611478, "TargetType", newJString(TargetType))
  add(query_611478, "HealthCheckPath", newJString(HealthCheckPath))
  add(query_611478, "VpcId", newJString(VpcId))
  add(query_611478, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_611478, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_611478, "Name", newJString(Name))
  add(query_611478, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_611478, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_611478, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_611478, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_611478, "Action", newJString(Action))
  add(query_611478, "Protocol", newJString(Protocol))
  add(query_611478, "Port", newJInt(Port))
  add(query_611478, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_611478, "Version", newJString(Version))
  result = call_611477.call(nil, query_611478, nil, nil, nil)

var getCreateTargetGroup* = Call_GetCreateTargetGroup_611450(
    name: "getCreateTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup", validator: validate_GetCreateTargetGroup_611451,
    base: "/", url: url_GetCreateTargetGroup_611452,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteListener_611525 = ref object of OpenApiRestCall_610658
proc url_PostDeleteListener_611527(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteListener_611526(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611528 = query.getOrDefault("Action")
  valid_611528 = validateParameter(valid_611528, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_611528 != nil:
    section.add "Action", valid_611528
  var valid_611529 = query.getOrDefault("Version")
  valid_611529 = validateParameter(valid_611529, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611529 != nil:
    section.add "Version", valid_611529
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611530 = header.getOrDefault("X-Amz-Signature")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-Signature", valid_611530
  var valid_611531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-Content-Sha256", valid_611531
  var valid_611532 = header.getOrDefault("X-Amz-Date")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Date", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-Credential")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-Credential", valid_611533
  var valid_611534 = header.getOrDefault("X-Amz-Security-Token")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-Security-Token", valid_611534
  var valid_611535 = header.getOrDefault("X-Amz-Algorithm")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "X-Amz-Algorithm", valid_611535
  var valid_611536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-SignedHeaders", valid_611536
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_611537 = formData.getOrDefault("ListenerArn")
  valid_611537 = validateParameter(valid_611537, JString, required = true,
                                 default = nil)
  if valid_611537 != nil:
    section.add "ListenerArn", valid_611537
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611538: Call_PostDeleteListener_611525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_611538.validator(path, query, header, formData, body)
  let scheme = call_611538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611538.url(scheme.get, call_611538.host, call_611538.base,
                         call_611538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611538, url, valid)

proc call*(call_611539: Call_PostDeleteListener_611525; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611540 = newJObject()
  var formData_611541 = newJObject()
  add(formData_611541, "ListenerArn", newJString(ListenerArn))
  add(query_611540, "Action", newJString(Action))
  add(query_611540, "Version", newJString(Version))
  result = call_611539.call(nil, query_611540, nil, formData_611541, nil)

var postDeleteListener* = Call_PostDeleteListener_611525(
    name: "postDeleteListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=DeleteListener",
    validator: validate_PostDeleteListener_611526, base: "/",
    url: url_PostDeleteListener_611527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteListener_611509 = ref object of OpenApiRestCall_610658
proc url_GetDeleteListener_611511(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteListener_611510(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ListenerArn` field"
  var valid_611512 = query.getOrDefault("ListenerArn")
  valid_611512 = validateParameter(valid_611512, JString, required = true,
                                 default = nil)
  if valid_611512 != nil:
    section.add "ListenerArn", valid_611512
  var valid_611513 = query.getOrDefault("Action")
  valid_611513 = validateParameter(valid_611513, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_611513 != nil:
    section.add "Action", valid_611513
  var valid_611514 = query.getOrDefault("Version")
  valid_611514 = validateParameter(valid_611514, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611514 != nil:
    section.add "Version", valid_611514
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611515 = header.getOrDefault("X-Amz-Signature")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Signature", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Content-Sha256", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Date")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Date", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-Credential")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Credential", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-Security-Token")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Security-Token", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-Algorithm")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Algorithm", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-SignedHeaders", valid_611521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611522: Call_GetDeleteListener_611509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_611522.validator(path, query, header, formData, body)
  let scheme = call_611522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611522.url(scheme.get, call_611522.host, call_611522.base,
                         call_611522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611522, url, valid)

proc call*(call_611523: Call_GetDeleteListener_611509; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611524 = newJObject()
  add(query_611524, "ListenerArn", newJString(ListenerArn))
  add(query_611524, "Action", newJString(Action))
  add(query_611524, "Version", newJString(Version))
  result = call_611523.call(nil, query_611524, nil, nil, nil)

var getDeleteListener* = Call_GetDeleteListener_611509(name: "getDeleteListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteListener", validator: validate_GetDeleteListener_611510,
    base: "/", url: url_GetDeleteListener_611511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_611558 = ref object of OpenApiRestCall_610658
proc url_PostDeleteLoadBalancer_611560(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteLoadBalancer_611559(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611561 = query.getOrDefault("Action")
  valid_611561 = validateParameter(valid_611561, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_611561 != nil:
    section.add "Action", valid_611561
  var valid_611562 = query.getOrDefault("Version")
  valid_611562 = validateParameter(valid_611562, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611562 != nil:
    section.add "Version", valid_611562
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611563 = header.getOrDefault("X-Amz-Signature")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-Signature", valid_611563
  var valid_611564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Content-Sha256", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-Date")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-Date", valid_611565
  var valid_611566 = header.getOrDefault("X-Amz-Credential")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Credential", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-Security-Token")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Security-Token", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-Algorithm")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Algorithm", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-SignedHeaders", valid_611569
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_611570 = formData.getOrDefault("LoadBalancerArn")
  valid_611570 = validateParameter(valid_611570, JString, required = true,
                                 default = nil)
  if valid_611570 != nil:
    section.add "LoadBalancerArn", valid_611570
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611571: Call_PostDeleteLoadBalancer_611558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_611571.validator(path, query, header, formData, body)
  let scheme = call_611571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611571.url(scheme.get, call_611571.host, call_611571.base,
                         call_611571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611571, url, valid)

proc call*(call_611572: Call_PostDeleteLoadBalancer_611558;
          LoadBalancerArn: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2015-12-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_611573 = newJObject()
  var formData_611574 = newJObject()
  add(query_611573, "Action", newJString(Action))
  add(query_611573, "Version", newJString(Version))
  add(formData_611574, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_611572.call(nil, query_611573, nil, formData_611574, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_611558(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_611559, base: "/",
    url: url_PostDeleteLoadBalancer_611560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_611542 = ref object of OpenApiRestCall_610658
proc url_GetDeleteLoadBalancer_611544(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteLoadBalancer_611543(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_611545 = query.getOrDefault("LoadBalancerArn")
  valid_611545 = validateParameter(valid_611545, JString, required = true,
                                 default = nil)
  if valid_611545 != nil:
    section.add "LoadBalancerArn", valid_611545
  var valid_611546 = query.getOrDefault("Action")
  valid_611546 = validateParameter(valid_611546, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_611546 != nil:
    section.add "Action", valid_611546
  var valid_611547 = query.getOrDefault("Version")
  valid_611547 = validateParameter(valid_611547, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611547 != nil:
    section.add "Version", valid_611547
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611548 = header.getOrDefault("X-Amz-Signature")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Signature", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Content-Sha256", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-Date")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-Date", valid_611550
  var valid_611551 = header.getOrDefault("X-Amz-Credential")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-Credential", valid_611551
  var valid_611552 = header.getOrDefault("X-Amz-Security-Token")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Security-Token", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Algorithm")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Algorithm", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-SignedHeaders", valid_611554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611555: Call_GetDeleteLoadBalancer_611542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_611555.validator(path, query, header, formData, body)
  let scheme = call_611555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611555.url(scheme.get, call_611555.host, call_611555.base,
                         call_611555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611555, url, valid)

proc call*(call_611556: Call_GetDeleteLoadBalancer_611542; LoadBalancerArn: string;
          Action: string = "DeleteLoadBalancer"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611557 = newJObject()
  add(query_611557, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_611557, "Action", newJString(Action))
  add(query_611557, "Version", newJString(Version))
  result = call_611556.call(nil, query_611557, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_611542(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_611543, base: "/",
    url: url_GetDeleteLoadBalancer_611544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRule_611591 = ref object of OpenApiRestCall_610658
proc url_PostDeleteRule_611593(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteRule_611592(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes the specified rule.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611594 = query.getOrDefault("Action")
  valid_611594 = validateParameter(valid_611594, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_611594 != nil:
    section.add "Action", valid_611594
  var valid_611595 = query.getOrDefault("Version")
  valid_611595 = validateParameter(valid_611595, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611595 != nil:
    section.add "Version", valid_611595
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611596 = header.getOrDefault("X-Amz-Signature")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-Signature", valid_611596
  var valid_611597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611597 = validateParameter(valid_611597, JString, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "X-Amz-Content-Sha256", valid_611597
  var valid_611598 = header.getOrDefault("X-Amz-Date")
  valid_611598 = validateParameter(valid_611598, JString, required = false,
                                 default = nil)
  if valid_611598 != nil:
    section.add "X-Amz-Date", valid_611598
  var valid_611599 = header.getOrDefault("X-Amz-Credential")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Credential", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Security-Token")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Security-Token", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Algorithm")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Algorithm", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-SignedHeaders", valid_611602
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_611603 = formData.getOrDefault("RuleArn")
  valid_611603 = validateParameter(valid_611603, JString, required = true,
                                 default = nil)
  if valid_611603 != nil:
    section.add "RuleArn", valid_611603
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611604: Call_PostDeleteRule_611591; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_611604.validator(path, query, header, formData, body)
  let scheme = call_611604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611604.url(scheme.get, call_611604.host, call_611604.base,
                         call_611604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611604, url, valid)

proc call*(call_611605: Call_PostDeleteRule_611591; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611606 = newJObject()
  var formData_611607 = newJObject()
  add(formData_611607, "RuleArn", newJString(RuleArn))
  add(query_611606, "Action", newJString(Action))
  add(query_611606, "Version", newJString(Version))
  result = call_611605.call(nil, query_611606, nil, formData_611607, nil)

var postDeleteRule* = Call_PostDeleteRule_611591(name: "postDeleteRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_PostDeleteRule_611592,
    base: "/", url: url_PostDeleteRule_611593, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRule_611575 = ref object of OpenApiRestCall_610658
proc url_GetDeleteRule_611577(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteRule_611576(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified rule.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `RuleArn` field"
  var valid_611578 = query.getOrDefault("RuleArn")
  valid_611578 = validateParameter(valid_611578, JString, required = true,
                                 default = nil)
  if valid_611578 != nil:
    section.add "RuleArn", valid_611578
  var valid_611579 = query.getOrDefault("Action")
  valid_611579 = validateParameter(valid_611579, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_611579 != nil:
    section.add "Action", valid_611579
  var valid_611580 = query.getOrDefault("Version")
  valid_611580 = validateParameter(valid_611580, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611580 != nil:
    section.add "Version", valid_611580
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611581 = header.getOrDefault("X-Amz-Signature")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-Signature", valid_611581
  var valid_611582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-Content-Sha256", valid_611582
  var valid_611583 = header.getOrDefault("X-Amz-Date")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Date", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Credential")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Credential", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Security-Token")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Security-Token", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Algorithm")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Algorithm", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-SignedHeaders", valid_611587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611588: Call_GetDeleteRule_611575; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_611588.validator(path, query, header, formData, body)
  let scheme = call_611588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611588.url(scheme.get, call_611588.host, call_611588.base,
                         call_611588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611588, url, valid)

proc call*(call_611589: Call_GetDeleteRule_611575; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611590 = newJObject()
  add(query_611590, "RuleArn", newJString(RuleArn))
  add(query_611590, "Action", newJString(Action))
  add(query_611590, "Version", newJString(Version))
  result = call_611589.call(nil, query_611590, nil, nil, nil)

var getDeleteRule* = Call_GetDeleteRule_611575(name: "getDeleteRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_GetDeleteRule_611576,
    base: "/", url: url_GetDeleteRule_611577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTargetGroup_611624 = ref object of OpenApiRestCall_610658
proc url_PostDeleteTargetGroup_611626(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteTargetGroup_611625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611627 = query.getOrDefault("Action")
  valid_611627 = validateParameter(valid_611627, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_611627 != nil:
    section.add "Action", valid_611627
  var valid_611628 = query.getOrDefault("Version")
  valid_611628 = validateParameter(valid_611628, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611628 != nil:
    section.add "Version", valid_611628
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611629 = header.getOrDefault("X-Amz-Signature")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Signature", valid_611629
  var valid_611630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-Content-Sha256", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Date")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Date", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Credential")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Credential", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Security-Token")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Security-Token", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Algorithm")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Algorithm", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-SignedHeaders", valid_611635
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_611636 = formData.getOrDefault("TargetGroupArn")
  valid_611636 = validateParameter(valid_611636, JString, required = true,
                                 default = nil)
  if valid_611636 != nil:
    section.add "TargetGroupArn", valid_611636
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611637: Call_PostDeleteTargetGroup_611624; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_611637.validator(path, query, header, formData, body)
  let scheme = call_611637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611637.url(scheme.get, call_611637.host, call_611637.base,
                         call_611637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611637, url, valid)

proc call*(call_611638: Call_PostDeleteTargetGroup_611624; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_611639 = newJObject()
  var formData_611640 = newJObject()
  add(query_611639, "Action", newJString(Action))
  add(formData_611640, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_611639, "Version", newJString(Version))
  result = call_611638.call(nil, query_611639, nil, formData_611640, nil)

var postDeleteTargetGroup* = Call_PostDeleteTargetGroup_611624(
    name: "postDeleteTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup",
    validator: validate_PostDeleteTargetGroup_611625, base: "/",
    url: url_PostDeleteTargetGroup_611626, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTargetGroup_611608 = ref object of OpenApiRestCall_610658
proc url_GetDeleteTargetGroup_611610(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteTargetGroup_611609(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_611611 = query.getOrDefault("TargetGroupArn")
  valid_611611 = validateParameter(valid_611611, JString, required = true,
                                 default = nil)
  if valid_611611 != nil:
    section.add "TargetGroupArn", valid_611611
  var valid_611612 = query.getOrDefault("Action")
  valid_611612 = validateParameter(valid_611612, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_611612 != nil:
    section.add "Action", valid_611612
  var valid_611613 = query.getOrDefault("Version")
  valid_611613 = validateParameter(valid_611613, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611613 != nil:
    section.add "Version", valid_611613
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611614 = header.getOrDefault("X-Amz-Signature")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Signature", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Content-Sha256", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Date")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Date", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Credential")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Credential", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Security-Token")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Security-Token", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-Algorithm")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Algorithm", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-SignedHeaders", valid_611620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611621: Call_GetDeleteTargetGroup_611608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_611621.validator(path, query, header, formData, body)
  let scheme = call_611621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611621.url(scheme.get, call_611621.host, call_611621.base,
                         call_611621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611621, url, valid)

proc call*(call_611622: Call_GetDeleteTargetGroup_611608; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611623 = newJObject()
  add(query_611623, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_611623, "Action", newJString(Action))
  add(query_611623, "Version", newJString(Version))
  result = call_611622.call(nil, query_611623, nil, nil, nil)

var getDeleteTargetGroup* = Call_GetDeleteTargetGroup_611608(
    name: "getDeleteTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup", validator: validate_GetDeleteTargetGroup_611609,
    base: "/", url: url_GetDeleteTargetGroup_611610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterTargets_611658 = ref object of OpenApiRestCall_610658
proc url_PostDeregisterTargets_611660(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeregisterTargets_611659(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611661 = query.getOrDefault("Action")
  valid_611661 = validateParameter(valid_611661, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_611661 != nil:
    section.add "Action", valid_611661
  var valid_611662 = query.getOrDefault("Version")
  valid_611662 = validateParameter(valid_611662, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611662 != nil:
    section.add "Version", valid_611662
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611663 = header.getOrDefault("X-Amz-Signature")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Signature", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Content-Sha256", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-Date")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-Date", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Credential")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Credential", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Security-Token")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Security-Token", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Algorithm")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Algorithm", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-SignedHeaders", valid_611669
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_611670 = formData.getOrDefault("Targets")
  valid_611670 = validateParameter(valid_611670, JArray, required = true, default = nil)
  if valid_611670 != nil:
    section.add "Targets", valid_611670
  var valid_611671 = formData.getOrDefault("TargetGroupArn")
  valid_611671 = validateParameter(valid_611671, JString, required = true,
                                 default = nil)
  if valid_611671 != nil:
    section.add "TargetGroupArn", valid_611671
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611672: Call_PostDeregisterTargets_611658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_611672.validator(path, query, header, formData, body)
  let scheme = call_611672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611672.url(scheme.get, call_611672.host, call_611672.base,
                         call_611672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611672, url, valid)

proc call*(call_611673: Call_PostDeregisterTargets_611658; Targets: JsonNode;
          TargetGroupArn: string; Action: string = "DeregisterTargets";
          Version: string = "2015-12-01"): Recallable =
  ## postDeregisterTargets
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_611674 = newJObject()
  var formData_611675 = newJObject()
  if Targets != nil:
    formData_611675.add "Targets", Targets
  add(query_611674, "Action", newJString(Action))
  add(formData_611675, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_611674, "Version", newJString(Version))
  result = call_611673.call(nil, query_611674, nil, formData_611675, nil)

var postDeregisterTargets* = Call_PostDeregisterTargets_611658(
    name: "postDeregisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets",
    validator: validate_PostDeregisterTargets_611659, base: "/",
    url: url_PostDeregisterTargets_611660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterTargets_611641 = ref object of OpenApiRestCall_610658
proc url_GetDeregisterTargets_611643(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeregisterTargets_611642(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Targets` field"
  var valid_611644 = query.getOrDefault("Targets")
  valid_611644 = validateParameter(valid_611644, JArray, required = true, default = nil)
  if valid_611644 != nil:
    section.add "Targets", valid_611644
  var valid_611645 = query.getOrDefault("TargetGroupArn")
  valid_611645 = validateParameter(valid_611645, JString, required = true,
                                 default = nil)
  if valid_611645 != nil:
    section.add "TargetGroupArn", valid_611645
  var valid_611646 = query.getOrDefault("Action")
  valid_611646 = validateParameter(valid_611646, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_611646 != nil:
    section.add "Action", valid_611646
  var valid_611647 = query.getOrDefault("Version")
  valid_611647 = validateParameter(valid_611647, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611647 != nil:
    section.add "Version", valid_611647
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611648 = header.getOrDefault("X-Amz-Signature")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Signature", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Content-Sha256", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-Date")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-Date", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Credential")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Credential", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-Security-Token")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Security-Token", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-Algorithm")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-Algorithm", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-SignedHeaders", valid_611654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611655: Call_GetDeregisterTargets_611641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_611655.validator(path, query, header, formData, body)
  let scheme = call_611655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611655.url(scheme.get, call_611655.host, call_611655.base,
                         call_611655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611655, url, valid)

proc call*(call_611656: Call_GetDeregisterTargets_611641; Targets: JsonNode;
          TargetGroupArn: string; Action: string = "DeregisterTargets";
          Version: string = "2015-12-01"): Recallable =
  ## getDeregisterTargets
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611657 = newJObject()
  if Targets != nil:
    query_611657.add "Targets", Targets
  add(query_611657, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_611657, "Action", newJString(Action))
  add(query_611657, "Version", newJString(Version))
  result = call_611656.call(nil, query_611657, nil, nil, nil)

var getDeregisterTargets* = Call_GetDeregisterTargets_611641(
    name: "getDeregisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets", validator: validate_GetDeregisterTargets_611642,
    base: "/", url: url_GetDeregisterTargets_611643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_611693 = ref object of OpenApiRestCall_610658
proc url_PostDescribeAccountLimits_611695(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAccountLimits_611694(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611696 = query.getOrDefault("Action")
  valid_611696 = validateParameter(valid_611696, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_611696 != nil:
    section.add "Action", valid_611696
  var valid_611697 = query.getOrDefault("Version")
  valid_611697 = validateParameter(valid_611697, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611697 != nil:
    section.add "Version", valid_611697
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611698 = header.getOrDefault("X-Amz-Signature")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "X-Amz-Signature", valid_611698
  var valid_611699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611699 = validateParameter(valid_611699, JString, required = false,
                                 default = nil)
  if valid_611699 != nil:
    section.add "X-Amz-Content-Sha256", valid_611699
  var valid_611700 = header.getOrDefault("X-Amz-Date")
  valid_611700 = validateParameter(valid_611700, JString, required = false,
                                 default = nil)
  if valid_611700 != nil:
    section.add "X-Amz-Date", valid_611700
  var valid_611701 = header.getOrDefault("X-Amz-Credential")
  valid_611701 = validateParameter(valid_611701, JString, required = false,
                                 default = nil)
  if valid_611701 != nil:
    section.add "X-Amz-Credential", valid_611701
  var valid_611702 = header.getOrDefault("X-Amz-Security-Token")
  valid_611702 = validateParameter(valid_611702, JString, required = false,
                                 default = nil)
  if valid_611702 != nil:
    section.add "X-Amz-Security-Token", valid_611702
  var valid_611703 = header.getOrDefault("X-Amz-Algorithm")
  valid_611703 = validateParameter(valid_611703, JString, required = false,
                                 default = nil)
  if valid_611703 != nil:
    section.add "X-Amz-Algorithm", valid_611703
  var valid_611704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611704 = validateParameter(valid_611704, JString, required = false,
                                 default = nil)
  if valid_611704 != nil:
    section.add "X-Amz-SignedHeaders", valid_611704
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_611705 = formData.getOrDefault("Marker")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "Marker", valid_611705
  var valid_611706 = formData.getOrDefault("PageSize")
  valid_611706 = validateParameter(valid_611706, JInt, required = false, default = nil)
  if valid_611706 != nil:
    section.add "PageSize", valid_611706
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611707: Call_PostDescribeAccountLimits_611693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611707.validator(path, query, header, formData, body)
  let scheme = call_611707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611707.url(scheme.get, call_611707.host, call_611707.base,
                         call_611707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611707, url, valid)

proc call*(call_611708: Call_PostDescribeAccountLimits_611693; Marker: string = "";
          Action: string = "DescribeAccountLimits"; PageSize: int = 0;
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeAccountLimits
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_611709 = newJObject()
  var formData_611710 = newJObject()
  add(formData_611710, "Marker", newJString(Marker))
  add(query_611709, "Action", newJString(Action))
  add(formData_611710, "PageSize", newJInt(PageSize))
  add(query_611709, "Version", newJString(Version))
  result = call_611708.call(nil, query_611709, nil, formData_611710, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_611693(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_611694, base: "/",
    url: url_PostDescribeAccountLimits_611695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_611676 = ref object of OpenApiRestCall_610658
proc url_GetDescribeAccountLimits_611678(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAccountLimits_611677(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611679 = query.getOrDefault("Marker")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "Marker", valid_611679
  var valid_611680 = query.getOrDefault("PageSize")
  valid_611680 = validateParameter(valid_611680, JInt, required = false, default = nil)
  if valid_611680 != nil:
    section.add "PageSize", valid_611680
  var valid_611681 = query.getOrDefault("Action")
  valid_611681 = validateParameter(valid_611681, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_611681 != nil:
    section.add "Action", valid_611681
  var valid_611682 = query.getOrDefault("Version")
  valid_611682 = validateParameter(valid_611682, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611682 != nil:
    section.add "Version", valid_611682
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611683 = header.getOrDefault("X-Amz-Signature")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Signature", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-Content-Sha256", valid_611684
  var valid_611685 = header.getOrDefault("X-Amz-Date")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-Date", valid_611685
  var valid_611686 = header.getOrDefault("X-Amz-Credential")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "X-Amz-Credential", valid_611686
  var valid_611687 = header.getOrDefault("X-Amz-Security-Token")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-Security-Token", valid_611687
  var valid_611688 = header.getOrDefault("X-Amz-Algorithm")
  valid_611688 = validateParameter(valid_611688, JString, required = false,
                                 default = nil)
  if valid_611688 != nil:
    section.add "X-Amz-Algorithm", valid_611688
  var valid_611689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611689 = validateParameter(valid_611689, JString, required = false,
                                 default = nil)
  if valid_611689 != nil:
    section.add "X-Amz-SignedHeaders", valid_611689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611690: Call_GetDescribeAccountLimits_611676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611690.validator(path, query, header, formData, body)
  let scheme = call_611690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611690.url(scheme.get, call_611690.host, call_611690.base,
                         call_611690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611690, url, valid)

proc call*(call_611691: Call_GetDescribeAccountLimits_611676; Marker: string = "";
          PageSize: int = 0; Action: string = "DescribeAccountLimits";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeAccountLimits
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611692 = newJObject()
  add(query_611692, "Marker", newJString(Marker))
  add(query_611692, "PageSize", newJInt(PageSize))
  add(query_611692, "Action", newJString(Action))
  add(query_611692, "Version", newJString(Version))
  result = call_611691.call(nil, query_611692, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_611676(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_611677, base: "/",
    url: url_GetDescribeAccountLimits_611678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListenerCertificates_611729 = ref object of OpenApiRestCall_610658
proc url_PostDescribeListenerCertificates_611731(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeListenerCertificates_611730(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611732 = query.getOrDefault("Action")
  valid_611732 = validateParameter(valid_611732, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_611732 != nil:
    section.add "Action", valid_611732
  var valid_611733 = query.getOrDefault("Version")
  valid_611733 = validateParameter(valid_611733, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611733 != nil:
    section.add "Version", valid_611733
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611734 = header.getOrDefault("X-Amz-Signature")
  valid_611734 = validateParameter(valid_611734, JString, required = false,
                                 default = nil)
  if valid_611734 != nil:
    section.add "X-Amz-Signature", valid_611734
  var valid_611735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611735 = validateParameter(valid_611735, JString, required = false,
                                 default = nil)
  if valid_611735 != nil:
    section.add "X-Amz-Content-Sha256", valid_611735
  var valid_611736 = header.getOrDefault("X-Amz-Date")
  valid_611736 = validateParameter(valid_611736, JString, required = false,
                                 default = nil)
  if valid_611736 != nil:
    section.add "X-Amz-Date", valid_611736
  var valid_611737 = header.getOrDefault("X-Amz-Credential")
  valid_611737 = validateParameter(valid_611737, JString, required = false,
                                 default = nil)
  if valid_611737 != nil:
    section.add "X-Amz-Credential", valid_611737
  var valid_611738 = header.getOrDefault("X-Amz-Security-Token")
  valid_611738 = validateParameter(valid_611738, JString, required = false,
                                 default = nil)
  if valid_611738 != nil:
    section.add "X-Amz-Security-Token", valid_611738
  var valid_611739 = header.getOrDefault("X-Amz-Algorithm")
  valid_611739 = validateParameter(valid_611739, JString, required = false,
                                 default = nil)
  if valid_611739 != nil:
    section.add "X-Amz-Algorithm", valid_611739
  var valid_611740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-SignedHeaders", valid_611740
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Names (ARN) of the listener.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_611741 = formData.getOrDefault("ListenerArn")
  valid_611741 = validateParameter(valid_611741, JString, required = true,
                                 default = nil)
  if valid_611741 != nil:
    section.add "ListenerArn", valid_611741
  var valid_611742 = formData.getOrDefault("Marker")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "Marker", valid_611742
  var valid_611743 = formData.getOrDefault("PageSize")
  valid_611743 = validateParameter(valid_611743, JInt, required = false, default = nil)
  if valid_611743 != nil:
    section.add "PageSize", valid_611743
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611744: Call_PostDescribeListenerCertificates_611729;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611744.validator(path, query, header, formData, body)
  let scheme = call_611744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611744.url(scheme.get, call_611744.host, call_611744.base,
                         call_611744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611744, url, valid)

proc call*(call_611745: Call_PostDescribeListenerCertificates_611729;
          ListenerArn: string; Marker: string = "";
          Action: string = "DescribeListenerCertificates"; PageSize: int = 0;
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeListenerCertificates
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Names (ARN) of the listener.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_611746 = newJObject()
  var formData_611747 = newJObject()
  add(formData_611747, "ListenerArn", newJString(ListenerArn))
  add(formData_611747, "Marker", newJString(Marker))
  add(query_611746, "Action", newJString(Action))
  add(formData_611747, "PageSize", newJInt(PageSize))
  add(query_611746, "Version", newJString(Version))
  result = call_611745.call(nil, query_611746, nil, formData_611747, nil)

var postDescribeListenerCertificates* = Call_PostDescribeListenerCertificates_611729(
    name: "postDescribeListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_PostDescribeListenerCertificates_611730, base: "/",
    url: url_PostDescribeListenerCertificates_611731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListenerCertificates_611711 = ref object of OpenApiRestCall_610658
proc url_GetDescribeListenerCertificates_611713(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeListenerCertificates_611712(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Names (ARN) of the listener.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611714 = query.getOrDefault("Marker")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "Marker", valid_611714
  assert query != nil,
        "query argument is necessary due to required `ListenerArn` field"
  var valid_611715 = query.getOrDefault("ListenerArn")
  valid_611715 = validateParameter(valid_611715, JString, required = true,
                                 default = nil)
  if valid_611715 != nil:
    section.add "ListenerArn", valid_611715
  var valid_611716 = query.getOrDefault("PageSize")
  valid_611716 = validateParameter(valid_611716, JInt, required = false, default = nil)
  if valid_611716 != nil:
    section.add "PageSize", valid_611716
  var valid_611717 = query.getOrDefault("Action")
  valid_611717 = validateParameter(valid_611717, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_611717 != nil:
    section.add "Action", valid_611717
  var valid_611718 = query.getOrDefault("Version")
  valid_611718 = validateParameter(valid_611718, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611718 != nil:
    section.add "Version", valid_611718
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611719 = header.getOrDefault("X-Amz-Signature")
  valid_611719 = validateParameter(valid_611719, JString, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "X-Amz-Signature", valid_611719
  var valid_611720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611720 = validateParameter(valid_611720, JString, required = false,
                                 default = nil)
  if valid_611720 != nil:
    section.add "X-Amz-Content-Sha256", valid_611720
  var valid_611721 = header.getOrDefault("X-Amz-Date")
  valid_611721 = validateParameter(valid_611721, JString, required = false,
                                 default = nil)
  if valid_611721 != nil:
    section.add "X-Amz-Date", valid_611721
  var valid_611722 = header.getOrDefault("X-Amz-Credential")
  valid_611722 = validateParameter(valid_611722, JString, required = false,
                                 default = nil)
  if valid_611722 != nil:
    section.add "X-Amz-Credential", valid_611722
  var valid_611723 = header.getOrDefault("X-Amz-Security-Token")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-Security-Token", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Algorithm")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Algorithm", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-SignedHeaders", valid_611725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611726: Call_GetDescribeListenerCertificates_611711;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611726.validator(path, query, header, formData, body)
  let scheme = call_611726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611726.url(scheme.get, call_611726.host, call_611726.base,
                         call_611726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611726, url, valid)

proc call*(call_611727: Call_GetDescribeListenerCertificates_611711;
          ListenerArn: string; Marker: string = ""; PageSize: int = 0;
          Action: string = "DescribeListenerCertificates";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeListenerCertificates
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Names (ARN) of the listener.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611728 = newJObject()
  add(query_611728, "Marker", newJString(Marker))
  add(query_611728, "ListenerArn", newJString(ListenerArn))
  add(query_611728, "PageSize", newJInt(PageSize))
  add(query_611728, "Action", newJString(Action))
  add(query_611728, "Version", newJString(Version))
  result = call_611727.call(nil, query_611728, nil, nil, nil)

var getDescribeListenerCertificates* = Call_GetDescribeListenerCertificates_611711(
    name: "getDescribeListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_GetDescribeListenerCertificates_611712, base: "/",
    url: url_GetDescribeListenerCertificates_611713,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListeners_611767 = ref object of OpenApiRestCall_610658
proc url_PostDescribeListeners_611769(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeListeners_611768(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611770 = query.getOrDefault("Action")
  valid_611770 = validateParameter(valid_611770, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_611770 != nil:
    section.add "Action", valid_611770
  var valid_611771 = query.getOrDefault("Version")
  valid_611771 = validateParameter(valid_611771, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611771 != nil:
    section.add "Version", valid_611771
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611772 = header.getOrDefault("X-Amz-Signature")
  valid_611772 = validateParameter(valid_611772, JString, required = false,
                                 default = nil)
  if valid_611772 != nil:
    section.add "X-Amz-Signature", valid_611772
  var valid_611773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "X-Amz-Content-Sha256", valid_611773
  var valid_611774 = header.getOrDefault("X-Amz-Date")
  valid_611774 = validateParameter(valid_611774, JString, required = false,
                                 default = nil)
  if valid_611774 != nil:
    section.add "X-Amz-Date", valid_611774
  var valid_611775 = header.getOrDefault("X-Amz-Credential")
  valid_611775 = validateParameter(valid_611775, JString, required = false,
                                 default = nil)
  if valid_611775 != nil:
    section.add "X-Amz-Credential", valid_611775
  var valid_611776 = header.getOrDefault("X-Amz-Security-Token")
  valid_611776 = validateParameter(valid_611776, JString, required = false,
                                 default = nil)
  if valid_611776 != nil:
    section.add "X-Amz-Security-Token", valid_611776
  var valid_611777 = header.getOrDefault("X-Amz-Algorithm")
  valid_611777 = validateParameter(valid_611777, JString, required = false,
                                 default = nil)
  if valid_611777 != nil:
    section.add "X-Amz-Algorithm", valid_611777
  var valid_611778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611778 = validateParameter(valid_611778, JString, required = false,
                                 default = nil)
  if valid_611778 != nil:
    section.add "X-Amz-SignedHeaders", valid_611778
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   LoadBalancerArn: JString
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   ListenerArns: JArray
  ##               : The Amazon Resource Names (ARN) of the listeners.
  section = newJObject()
  var valid_611779 = formData.getOrDefault("Marker")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "Marker", valid_611779
  var valid_611780 = formData.getOrDefault("PageSize")
  valid_611780 = validateParameter(valid_611780, JInt, required = false, default = nil)
  if valid_611780 != nil:
    section.add "PageSize", valid_611780
  var valid_611781 = formData.getOrDefault("LoadBalancerArn")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "LoadBalancerArn", valid_611781
  var valid_611782 = formData.getOrDefault("ListenerArns")
  valid_611782 = validateParameter(valid_611782, JArray, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "ListenerArns", valid_611782
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611783: Call_PostDescribeListeners_611767; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_611783.validator(path, query, header, formData, body)
  let scheme = call_611783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611783.url(scheme.get, call_611783.host, call_611783.base,
                         call_611783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611783, url, valid)

proc call*(call_611784: Call_PostDescribeListeners_611767; Marker: string = "";
          Action: string = "DescribeListeners"; PageSize: int = 0;
          Version: string = "2015-12-01"; LoadBalancerArn: string = "";
          ListenerArns: JsonNode = nil): Recallable =
  ## postDescribeListeners
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  ##   LoadBalancerArn: string
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   ListenerArns: JArray
  ##               : The Amazon Resource Names (ARN) of the listeners.
  var query_611785 = newJObject()
  var formData_611786 = newJObject()
  add(formData_611786, "Marker", newJString(Marker))
  add(query_611785, "Action", newJString(Action))
  add(formData_611786, "PageSize", newJInt(PageSize))
  add(query_611785, "Version", newJString(Version))
  add(formData_611786, "LoadBalancerArn", newJString(LoadBalancerArn))
  if ListenerArns != nil:
    formData_611786.add "ListenerArns", ListenerArns
  result = call_611784.call(nil, query_611785, nil, formData_611786, nil)

var postDescribeListeners* = Call_PostDescribeListeners_611767(
    name: "postDescribeListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners",
    validator: validate_PostDescribeListeners_611768, base: "/",
    url: url_PostDescribeListeners_611769, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListeners_611748 = ref object of OpenApiRestCall_610658
proc url_GetDescribeListeners_611750(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeListeners_611749(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerArn: JString
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   ListenerArns: JArray
  ##               : The Amazon Resource Names (ARN) of the listeners.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611751 = query.getOrDefault("Marker")
  valid_611751 = validateParameter(valid_611751, JString, required = false,
                                 default = nil)
  if valid_611751 != nil:
    section.add "Marker", valid_611751
  var valid_611752 = query.getOrDefault("LoadBalancerArn")
  valid_611752 = validateParameter(valid_611752, JString, required = false,
                                 default = nil)
  if valid_611752 != nil:
    section.add "LoadBalancerArn", valid_611752
  var valid_611753 = query.getOrDefault("ListenerArns")
  valid_611753 = validateParameter(valid_611753, JArray, required = false,
                                 default = nil)
  if valid_611753 != nil:
    section.add "ListenerArns", valid_611753
  var valid_611754 = query.getOrDefault("PageSize")
  valid_611754 = validateParameter(valid_611754, JInt, required = false, default = nil)
  if valid_611754 != nil:
    section.add "PageSize", valid_611754
  var valid_611755 = query.getOrDefault("Action")
  valid_611755 = validateParameter(valid_611755, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_611755 != nil:
    section.add "Action", valid_611755
  var valid_611756 = query.getOrDefault("Version")
  valid_611756 = validateParameter(valid_611756, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611756 != nil:
    section.add "Version", valid_611756
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611757 = header.getOrDefault("X-Amz-Signature")
  valid_611757 = validateParameter(valid_611757, JString, required = false,
                                 default = nil)
  if valid_611757 != nil:
    section.add "X-Amz-Signature", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Content-Sha256", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-Date")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-Date", valid_611759
  var valid_611760 = header.getOrDefault("X-Amz-Credential")
  valid_611760 = validateParameter(valid_611760, JString, required = false,
                                 default = nil)
  if valid_611760 != nil:
    section.add "X-Amz-Credential", valid_611760
  var valid_611761 = header.getOrDefault("X-Amz-Security-Token")
  valid_611761 = validateParameter(valid_611761, JString, required = false,
                                 default = nil)
  if valid_611761 != nil:
    section.add "X-Amz-Security-Token", valid_611761
  var valid_611762 = header.getOrDefault("X-Amz-Algorithm")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "X-Amz-Algorithm", valid_611762
  var valid_611763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611763 = validateParameter(valid_611763, JString, required = false,
                                 default = nil)
  if valid_611763 != nil:
    section.add "X-Amz-SignedHeaders", valid_611763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611764: Call_GetDescribeListeners_611748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_611764.validator(path, query, header, formData, body)
  let scheme = call_611764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611764.url(scheme.get, call_611764.host, call_611764.base,
                         call_611764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611764, url, valid)

proc call*(call_611765: Call_GetDescribeListeners_611748; Marker: string = "";
          LoadBalancerArn: string = ""; ListenerArns: JsonNode = nil; PageSize: int = 0;
          Action: string = "DescribeListeners"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeListeners
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerArn: string
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   ListenerArns: JArray
  ##               : The Amazon Resource Names (ARN) of the listeners.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611766 = newJObject()
  add(query_611766, "Marker", newJString(Marker))
  add(query_611766, "LoadBalancerArn", newJString(LoadBalancerArn))
  if ListenerArns != nil:
    query_611766.add "ListenerArns", ListenerArns
  add(query_611766, "PageSize", newJInt(PageSize))
  add(query_611766, "Action", newJString(Action))
  add(query_611766, "Version", newJString(Version))
  result = call_611765.call(nil, query_611766, nil, nil, nil)

var getDescribeListeners* = Call_GetDescribeListeners_611748(
    name: "getDescribeListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners", validator: validate_GetDescribeListeners_611749,
    base: "/", url: url_GetDescribeListeners_611750,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_611803 = ref object of OpenApiRestCall_610658
proc url_PostDescribeLoadBalancerAttributes_611805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancerAttributes_611804(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611806 = query.getOrDefault("Action")
  valid_611806 = validateParameter(valid_611806, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_611806 != nil:
    section.add "Action", valid_611806
  var valid_611807 = query.getOrDefault("Version")
  valid_611807 = validateParameter(valid_611807, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611807 != nil:
    section.add "Version", valid_611807
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611808 = header.getOrDefault("X-Amz-Signature")
  valid_611808 = validateParameter(valid_611808, JString, required = false,
                                 default = nil)
  if valid_611808 != nil:
    section.add "X-Amz-Signature", valid_611808
  var valid_611809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611809 = validateParameter(valid_611809, JString, required = false,
                                 default = nil)
  if valid_611809 != nil:
    section.add "X-Amz-Content-Sha256", valid_611809
  var valid_611810 = header.getOrDefault("X-Amz-Date")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-Date", valid_611810
  var valid_611811 = header.getOrDefault("X-Amz-Credential")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-Credential", valid_611811
  var valid_611812 = header.getOrDefault("X-Amz-Security-Token")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-Security-Token", valid_611812
  var valid_611813 = header.getOrDefault("X-Amz-Algorithm")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Algorithm", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-SignedHeaders", valid_611814
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_611815 = formData.getOrDefault("LoadBalancerArn")
  valid_611815 = validateParameter(valid_611815, JString, required = true,
                                 default = nil)
  if valid_611815 != nil:
    section.add "LoadBalancerArn", valid_611815
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611816: Call_PostDescribeLoadBalancerAttributes_611803;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611816.validator(path, query, header, formData, body)
  let scheme = call_611816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611816.url(scheme.get, call_611816.host, call_611816.base,
                         call_611816.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611816, url, valid)

proc call*(call_611817: Call_PostDescribeLoadBalancerAttributes_611803;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_611818 = newJObject()
  var formData_611819 = newJObject()
  add(query_611818, "Action", newJString(Action))
  add(query_611818, "Version", newJString(Version))
  add(formData_611819, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_611817.call(nil, query_611818, nil, formData_611819, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_611803(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_611804, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_611805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_611787 = ref object of OpenApiRestCall_610658
proc url_GetDescribeLoadBalancerAttributes_611789(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancerAttributes_611788(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_611790 = query.getOrDefault("LoadBalancerArn")
  valid_611790 = validateParameter(valid_611790, JString, required = true,
                                 default = nil)
  if valid_611790 != nil:
    section.add "LoadBalancerArn", valid_611790
  var valid_611791 = query.getOrDefault("Action")
  valid_611791 = validateParameter(valid_611791, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_611791 != nil:
    section.add "Action", valid_611791
  var valid_611792 = query.getOrDefault("Version")
  valid_611792 = validateParameter(valid_611792, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611792 != nil:
    section.add "Version", valid_611792
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611793 = header.getOrDefault("X-Amz-Signature")
  valid_611793 = validateParameter(valid_611793, JString, required = false,
                                 default = nil)
  if valid_611793 != nil:
    section.add "X-Amz-Signature", valid_611793
  var valid_611794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Content-Sha256", valid_611794
  var valid_611795 = header.getOrDefault("X-Amz-Date")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-Date", valid_611795
  var valid_611796 = header.getOrDefault("X-Amz-Credential")
  valid_611796 = validateParameter(valid_611796, JString, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "X-Amz-Credential", valid_611796
  var valid_611797 = header.getOrDefault("X-Amz-Security-Token")
  valid_611797 = validateParameter(valid_611797, JString, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "X-Amz-Security-Token", valid_611797
  var valid_611798 = header.getOrDefault("X-Amz-Algorithm")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "X-Amz-Algorithm", valid_611798
  var valid_611799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "X-Amz-SignedHeaders", valid_611799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611800: Call_GetDescribeLoadBalancerAttributes_611787;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611800.validator(path, query, header, formData, body)
  let scheme = call_611800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611800.url(scheme.get, call_611800.host, call_611800.base,
                         call_611800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611800, url, valid)

proc call*(call_611801: Call_GetDescribeLoadBalancerAttributes_611787;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611802 = newJObject()
  add(query_611802, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_611802, "Action", newJString(Action))
  add(query_611802, "Version", newJString(Version))
  result = call_611801.call(nil, query_611802, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_611787(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_611788, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_611789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_611839 = ref object of OpenApiRestCall_610658
proc url_PostDescribeLoadBalancers_611841(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancers_611840(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611842 = query.getOrDefault("Action")
  valid_611842 = validateParameter(valid_611842, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_611842 != nil:
    section.add "Action", valid_611842
  var valid_611843 = query.getOrDefault("Version")
  valid_611843 = validateParameter(valid_611843, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611843 != nil:
    section.add "Version", valid_611843
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611844 = header.getOrDefault("X-Amz-Signature")
  valid_611844 = validateParameter(valid_611844, JString, required = false,
                                 default = nil)
  if valid_611844 != nil:
    section.add "X-Amz-Signature", valid_611844
  var valid_611845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611845 = validateParameter(valid_611845, JString, required = false,
                                 default = nil)
  if valid_611845 != nil:
    section.add "X-Amz-Content-Sha256", valid_611845
  var valid_611846 = header.getOrDefault("X-Amz-Date")
  valid_611846 = validateParameter(valid_611846, JString, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "X-Amz-Date", valid_611846
  var valid_611847 = header.getOrDefault("X-Amz-Credential")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-Credential", valid_611847
  var valid_611848 = header.getOrDefault("X-Amz-Security-Token")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "X-Amz-Security-Token", valid_611848
  var valid_611849 = header.getOrDefault("X-Amz-Algorithm")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Algorithm", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-SignedHeaders", valid_611850
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the load balancers.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   LoadBalancerArns: JArray
  ##                   : The Amazon Resource Names (ARN) of the load balancers. You can specify up to 20 load balancers in a single call.
  section = newJObject()
  var valid_611851 = formData.getOrDefault("Names")
  valid_611851 = validateParameter(valid_611851, JArray, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "Names", valid_611851
  var valid_611852 = formData.getOrDefault("Marker")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "Marker", valid_611852
  var valid_611853 = formData.getOrDefault("PageSize")
  valid_611853 = validateParameter(valid_611853, JInt, required = false, default = nil)
  if valid_611853 != nil:
    section.add "PageSize", valid_611853
  var valid_611854 = formData.getOrDefault("LoadBalancerArns")
  valid_611854 = validateParameter(valid_611854, JArray, required = false,
                                 default = nil)
  if valid_611854 != nil:
    section.add "LoadBalancerArns", valid_611854
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611855: Call_PostDescribeLoadBalancers_611839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_611855.validator(path, query, header, formData, body)
  let scheme = call_611855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611855.url(scheme.get, call_611855.host, call_611855.base,
                         call_611855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611855, url, valid)

proc call*(call_611856: Call_PostDescribeLoadBalancers_611839;
          Names: JsonNode = nil; Marker: string = "";
          Action: string = "DescribeLoadBalancers"; PageSize: int = 0;
          Version: string = "2015-12-01"; LoadBalancerArns: JsonNode = nil): Recallable =
  ## postDescribeLoadBalancers
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ##   Names: JArray
  ##        : The names of the load balancers.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  ##   LoadBalancerArns: JArray
  ##                   : The Amazon Resource Names (ARN) of the load balancers. You can specify up to 20 load balancers in a single call.
  var query_611857 = newJObject()
  var formData_611858 = newJObject()
  if Names != nil:
    formData_611858.add "Names", Names
  add(formData_611858, "Marker", newJString(Marker))
  add(query_611857, "Action", newJString(Action))
  add(formData_611858, "PageSize", newJInt(PageSize))
  add(query_611857, "Version", newJString(Version))
  if LoadBalancerArns != nil:
    formData_611858.add "LoadBalancerArns", LoadBalancerArns
  result = call_611856.call(nil, query_611857, nil, formData_611858, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_611839(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_611840, base: "/",
    url: url_PostDescribeLoadBalancers_611841,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_611820 = ref object of OpenApiRestCall_610658
proc url_GetDescribeLoadBalancers_611822(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancers_611821(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   LoadBalancerArns: JArray
  ##                   : The Amazon Resource Names (ARN) of the load balancers. You can specify up to 20 load balancers in a single call.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Names: JArray
  ##        : The names of the load balancers.
  section = newJObject()
  var valid_611823 = query.getOrDefault("Marker")
  valid_611823 = validateParameter(valid_611823, JString, required = false,
                                 default = nil)
  if valid_611823 != nil:
    section.add "Marker", valid_611823
  var valid_611824 = query.getOrDefault("PageSize")
  valid_611824 = validateParameter(valid_611824, JInt, required = false, default = nil)
  if valid_611824 != nil:
    section.add "PageSize", valid_611824
  var valid_611825 = query.getOrDefault("LoadBalancerArns")
  valid_611825 = validateParameter(valid_611825, JArray, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "LoadBalancerArns", valid_611825
  var valid_611826 = query.getOrDefault("Action")
  valid_611826 = validateParameter(valid_611826, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_611826 != nil:
    section.add "Action", valid_611826
  var valid_611827 = query.getOrDefault("Version")
  valid_611827 = validateParameter(valid_611827, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611827 != nil:
    section.add "Version", valid_611827
  var valid_611828 = query.getOrDefault("Names")
  valid_611828 = validateParameter(valid_611828, JArray, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "Names", valid_611828
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611829 = header.getOrDefault("X-Amz-Signature")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-Signature", valid_611829
  var valid_611830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "X-Amz-Content-Sha256", valid_611830
  var valid_611831 = header.getOrDefault("X-Amz-Date")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-Date", valid_611831
  var valid_611832 = header.getOrDefault("X-Amz-Credential")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-Credential", valid_611832
  var valid_611833 = header.getOrDefault("X-Amz-Security-Token")
  valid_611833 = validateParameter(valid_611833, JString, required = false,
                                 default = nil)
  if valid_611833 != nil:
    section.add "X-Amz-Security-Token", valid_611833
  var valid_611834 = header.getOrDefault("X-Amz-Algorithm")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-Algorithm", valid_611834
  var valid_611835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611835 = validateParameter(valid_611835, JString, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "X-Amz-SignedHeaders", valid_611835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611836: Call_GetDescribeLoadBalancers_611820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_611836.validator(path, query, header, formData, body)
  let scheme = call_611836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611836.url(scheme.get, call_611836.host, call_611836.base,
                         call_611836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611836, url, valid)

proc call*(call_611837: Call_GetDescribeLoadBalancers_611820; Marker: string = "";
          PageSize: int = 0; LoadBalancerArns: JsonNode = nil;
          Action: string = "DescribeLoadBalancers"; Version: string = "2015-12-01";
          Names: JsonNode = nil): Recallable =
  ## getDescribeLoadBalancers
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   LoadBalancerArns: JArray
  ##                   : The Amazon Resource Names (ARN) of the load balancers. You can specify up to 20 load balancers in a single call.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Names: JArray
  ##        : The names of the load balancers.
  var query_611838 = newJObject()
  add(query_611838, "Marker", newJString(Marker))
  add(query_611838, "PageSize", newJInt(PageSize))
  if LoadBalancerArns != nil:
    query_611838.add "LoadBalancerArns", LoadBalancerArns
  add(query_611838, "Action", newJString(Action))
  add(query_611838, "Version", newJString(Version))
  if Names != nil:
    query_611838.add "Names", Names
  result = call_611837.call(nil, query_611838, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_611820(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_611821, base: "/",
    url: url_GetDescribeLoadBalancers_611822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRules_611878 = ref object of OpenApiRestCall_610658
proc url_PostDescribeRules_611880(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeRules_611879(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611881 = query.getOrDefault("Action")
  valid_611881 = validateParameter(valid_611881, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_611881 != nil:
    section.add "Action", valid_611881
  var valid_611882 = query.getOrDefault("Version")
  valid_611882 = validateParameter(valid_611882, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611882 != nil:
    section.add "Version", valid_611882
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611883 = header.getOrDefault("X-Amz-Signature")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-Signature", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-Content-Sha256", valid_611884
  var valid_611885 = header.getOrDefault("X-Amz-Date")
  valid_611885 = validateParameter(valid_611885, JString, required = false,
                                 default = nil)
  if valid_611885 != nil:
    section.add "X-Amz-Date", valid_611885
  var valid_611886 = header.getOrDefault("X-Amz-Credential")
  valid_611886 = validateParameter(valid_611886, JString, required = false,
                                 default = nil)
  if valid_611886 != nil:
    section.add "X-Amz-Credential", valid_611886
  var valid_611887 = header.getOrDefault("X-Amz-Security-Token")
  valid_611887 = validateParameter(valid_611887, JString, required = false,
                                 default = nil)
  if valid_611887 != nil:
    section.add "X-Amz-Security-Token", valid_611887
  var valid_611888 = header.getOrDefault("X-Amz-Algorithm")
  valid_611888 = validateParameter(valid_611888, JString, required = false,
                                 default = nil)
  if valid_611888 != nil:
    section.add "X-Amz-Algorithm", valid_611888
  var valid_611889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611889 = validateParameter(valid_611889, JString, required = false,
                                 default = nil)
  if valid_611889 != nil:
    section.add "X-Amz-SignedHeaders", valid_611889
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   RuleArns: JArray
  ##           : The Amazon Resource Names (ARN) of the rules.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_611890 = formData.getOrDefault("ListenerArn")
  valid_611890 = validateParameter(valid_611890, JString, required = false,
                                 default = nil)
  if valid_611890 != nil:
    section.add "ListenerArn", valid_611890
  var valid_611891 = formData.getOrDefault("Marker")
  valid_611891 = validateParameter(valid_611891, JString, required = false,
                                 default = nil)
  if valid_611891 != nil:
    section.add "Marker", valid_611891
  var valid_611892 = formData.getOrDefault("RuleArns")
  valid_611892 = validateParameter(valid_611892, JArray, required = false,
                                 default = nil)
  if valid_611892 != nil:
    section.add "RuleArns", valid_611892
  var valid_611893 = formData.getOrDefault("PageSize")
  valid_611893 = validateParameter(valid_611893, JInt, required = false, default = nil)
  if valid_611893 != nil:
    section.add "PageSize", valid_611893
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611894: Call_PostDescribeRules_611878; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_611894.validator(path, query, header, formData, body)
  let scheme = call_611894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611894.url(scheme.get, call_611894.host, call_611894.base,
                         call_611894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611894, url, valid)

proc call*(call_611895: Call_PostDescribeRules_611878; ListenerArn: string = "";
          Marker: string = ""; RuleArns: JsonNode = nil;
          Action: string = "DescribeRules"; PageSize: int = 0;
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeRules
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ##   ListenerArn: string
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   RuleArns: JArray
  ##           : The Amazon Resource Names (ARN) of the rules.
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_611896 = newJObject()
  var formData_611897 = newJObject()
  add(formData_611897, "ListenerArn", newJString(ListenerArn))
  add(formData_611897, "Marker", newJString(Marker))
  if RuleArns != nil:
    formData_611897.add "RuleArns", RuleArns
  add(query_611896, "Action", newJString(Action))
  add(formData_611897, "PageSize", newJInt(PageSize))
  add(query_611896, "Version", newJString(Version))
  result = call_611895.call(nil, query_611896, nil, formData_611897, nil)

var postDescribeRules* = Call_PostDescribeRules_611878(name: "postDescribeRules",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_PostDescribeRules_611879,
    base: "/", url: url_PostDescribeRules_611880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRules_611859 = ref object of OpenApiRestCall_610658
proc url_GetDescribeRules_611861(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeRules_611860(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   ListenerArn: JString
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   RuleArns: JArray
  ##           : The Amazon Resource Names (ARN) of the rules.
  section = newJObject()
  var valid_611862 = query.getOrDefault("Marker")
  valid_611862 = validateParameter(valid_611862, JString, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "Marker", valid_611862
  var valid_611863 = query.getOrDefault("ListenerArn")
  valid_611863 = validateParameter(valid_611863, JString, required = false,
                                 default = nil)
  if valid_611863 != nil:
    section.add "ListenerArn", valid_611863
  var valid_611864 = query.getOrDefault("PageSize")
  valid_611864 = validateParameter(valid_611864, JInt, required = false, default = nil)
  if valid_611864 != nil:
    section.add "PageSize", valid_611864
  var valid_611865 = query.getOrDefault("Action")
  valid_611865 = validateParameter(valid_611865, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_611865 != nil:
    section.add "Action", valid_611865
  var valid_611866 = query.getOrDefault("Version")
  valid_611866 = validateParameter(valid_611866, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611866 != nil:
    section.add "Version", valid_611866
  var valid_611867 = query.getOrDefault("RuleArns")
  valid_611867 = validateParameter(valid_611867, JArray, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "RuleArns", valid_611867
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611868 = header.getOrDefault("X-Amz-Signature")
  valid_611868 = validateParameter(valid_611868, JString, required = false,
                                 default = nil)
  if valid_611868 != nil:
    section.add "X-Amz-Signature", valid_611868
  var valid_611869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611869 = validateParameter(valid_611869, JString, required = false,
                                 default = nil)
  if valid_611869 != nil:
    section.add "X-Amz-Content-Sha256", valid_611869
  var valid_611870 = header.getOrDefault("X-Amz-Date")
  valid_611870 = validateParameter(valid_611870, JString, required = false,
                                 default = nil)
  if valid_611870 != nil:
    section.add "X-Amz-Date", valid_611870
  var valid_611871 = header.getOrDefault("X-Amz-Credential")
  valid_611871 = validateParameter(valid_611871, JString, required = false,
                                 default = nil)
  if valid_611871 != nil:
    section.add "X-Amz-Credential", valid_611871
  var valid_611872 = header.getOrDefault("X-Amz-Security-Token")
  valid_611872 = validateParameter(valid_611872, JString, required = false,
                                 default = nil)
  if valid_611872 != nil:
    section.add "X-Amz-Security-Token", valid_611872
  var valid_611873 = header.getOrDefault("X-Amz-Algorithm")
  valid_611873 = validateParameter(valid_611873, JString, required = false,
                                 default = nil)
  if valid_611873 != nil:
    section.add "X-Amz-Algorithm", valid_611873
  var valid_611874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611874 = validateParameter(valid_611874, JString, required = false,
                                 default = nil)
  if valid_611874 != nil:
    section.add "X-Amz-SignedHeaders", valid_611874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611875: Call_GetDescribeRules_611859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_611875.validator(path, query, header, formData, body)
  let scheme = call_611875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611875.url(scheme.get, call_611875.host, call_611875.base,
                         call_611875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611875, url, valid)

proc call*(call_611876: Call_GetDescribeRules_611859; Marker: string = "";
          ListenerArn: string = ""; PageSize: int = 0; Action: string = "DescribeRules";
          Version: string = "2015-12-01"; RuleArns: JsonNode = nil): Recallable =
  ## getDescribeRules
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   ListenerArn: string
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   RuleArns: JArray
  ##           : The Amazon Resource Names (ARN) of the rules.
  var query_611877 = newJObject()
  add(query_611877, "Marker", newJString(Marker))
  add(query_611877, "ListenerArn", newJString(ListenerArn))
  add(query_611877, "PageSize", newJInt(PageSize))
  add(query_611877, "Action", newJString(Action))
  add(query_611877, "Version", newJString(Version))
  if RuleArns != nil:
    query_611877.add "RuleArns", RuleArns
  result = call_611876.call(nil, query_611877, nil, nil, nil)

var getDescribeRules* = Call_GetDescribeRules_611859(name: "getDescribeRules",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_GetDescribeRules_611860,
    base: "/", url: url_GetDescribeRules_611861,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSSLPolicies_611916 = ref object of OpenApiRestCall_610658
proc url_PostDescribeSSLPolicies_611918(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeSSLPolicies_611917(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611919 = query.getOrDefault("Action")
  valid_611919 = validateParameter(valid_611919, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_611919 != nil:
    section.add "Action", valid_611919
  var valid_611920 = query.getOrDefault("Version")
  valid_611920 = validateParameter(valid_611920, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611920 != nil:
    section.add "Version", valid_611920
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611921 = header.getOrDefault("X-Amz-Signature")
  valid_611921 = validateParameter(valid_611921, JString, required = false,
                                 default = nil)
  if valid_611921 != nil:
    section.add "X-Amz-Signature", valid_611921
  var valid_611922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611922 = validateParameter(valid_611922, JString, required = false,
                                 default = nil)
  if valid_611922 != nil:
    section.add "X-Amz-Content-Sha256", valid_611922
  var valid_611923 = header.getOrDefault("X-Amz-Date")
  valid_611923 = validateParameter(valid_611923, JString, required = false,
                                 default = nil)
  if valid_611923 != nil:
    section.add "X-Amz-Date", valid_611923
  var valid_611924 = header.getOrDefault("X-Amz-Credential")
  valid_611924 = validateParameter(valid_611924, JString, required = false,
                                 default = nil)
  if valid_611924 != nil:
    section.add "X-Amz-Credential", valid_611924
  var valid_611925 = header.getOrDefault("X-Amz-Security-Token")
  valid_611925 = validateParameter(valid_611925, JString, required = false,
                                 default = nil)
  if valid_611925 != nil:
    section.add "X-Amz-Security-Token", valid_611925
  var valid_611926 = header.getOrDefault("X-Amz-Algorithm")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "X-Amz-Algorithm", valid_611926
  var valid_611927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "X-Amz-SignedHeaders", valid_611927
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the policies.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_611928 = formData.getOrDefault("Names")
  valid_611928 = validateParameter(valid_611928, JArray, required = false,
                                 default = nil)
  if valid_611928 != nil:
    section.add "Names", valid_611928
  var valid_611929 = formData.getOrDefault("Marker")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "Marker", valid_611929
  var valid_611930 = formData.getOrDefault("PageSize")
  valid_611930 = validateParameter(valid_611930, JInt, required = false, default = nil)
  if valid_611930 != nil:
    section.add "PageSize", valid_611930
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611931: Call_PostDescribeSSLPolicies_611916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611931.validator(path, query, header, formData, body)
  let scheme = call_611931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611931.url(scheme.get, call_611931.host, call_611931.base,
                         call_611931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611931, url, valid)

proc call*(call_611932: Call_PostDescribeSSLPolicies_611916; Names: JsonNode = nil;
          Marker: string = ""; Action: string = "DescribeSSLPolicies";
          PageSize: int = 0; Version: string = "2015-12-01"): Recallable =
  ## postDescribeSSLPolicies
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ##   Names: JArray
  ##        : The names of the policies.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_611933 = newJObject()
  var formData_611934 = newJObject()
  if Names != nil:
    formData_611934.add "Names", Names
  add(formData_611934, "Marker", newJString(Marker))
  add(query_611933, "Action", newJString(Action))
  add(formData_611934, "PageSize", newJInt(PageSize))
  add(query_611933, "Version", newJString(Version))
  result = call_611932.call(nil, query_611933, nil, formData_611934, nil)

var postDescribeSSLPolicies* = Call_PostDescribeSSLPolicies_611916(
    name: "postDescribeSSLPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_PostDescribeSSLPolicies_611917, base: "/",
    url: url_PostDescribeSSLPolicies_611918, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSSLPolicies_611898 = ref object of OpenApiRestCall_610658
proc url_GetDescribeSSLPolicies_611900(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeSSLPolicies_611899(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Names: JArray
  ##        : The names of the policies.
  section = newJObject()
  var valid_611901 = query.getOrDefault("Marker")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "Marker", valid_611901
  var valid_611902 = query.getOrDefault("PageSize")
  valid_611902 = validateParameter(valid_611902, JInt, required = false, default = nil)
  if valid_611902 != nil:
    section.add "PageSize", valid_611902
  var valid_611903 = query.getOrDefault("Action")
  valid_611903 = validateParameter(valid_611903, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_611903 != nil:
    section.add "Action", valid_611903
  var valid_611904 = query.getOrDefault("Version")
  valid_611904 = validateParameter(valid_611904, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611904 != nil:
    section.add "Version", valid_611904
  var valid_611905 = query.getOrDefault("Names")
  valid_611905 = validateParameter(valid_611905, JArray, required = false,
                                 default = nil)
  if valid_611905 != nil:
    section.add "Names", valid_611905
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611906 = header.getOrDefault("X-Amz-Signature")
  valid_611906 = validateParameter(valid_611906, JString, required = false,
                                 default = nil)
  if valid_611906 != nil:
    section.add "X-Amz-Signature", valid_611906
  var valid_611907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611907 = validateParameter(valid_611907, JString, required = false,
                                 default = nil)
  if valid_611907 != nil:
    section.add "X-Amz-Content-Sha256", valid_611907
  var valid_611908 = header.getOrDefault("X-Amz-Date")
  valid_611908 = validateParameter(valid_611908, JString, required = false,
                                 default = nil)
  if valid_611908 != nil:
    section.add "X-Amz-Date", valid_611908
  var valid_611909 = header.getOrDefault("X-Amz-Credential")
  valid_611909 = validateParameter(valid_611909, JString, required = false,
                                 default = nil)
  if valid_611909 != nil:
    section.add "X-Amz-Credential", valid_611909
  var valid_611910 = header.getOrDefault("X-Amz-Security-Token")
  valid_611910 = validateParameter(valid_611910, JString, required = false,
                                 default = nil)
  if valid_611910 != nil:
    section.add "X-Amz-Security-Token", valid_611910
  var valid_611911 = header.getOrDefault("X-Amz-Algorithm")
  valid_611911 = validateParameter(valid_611911, JString, required = false,
                                 default = nil)
  if valid_611911 != nil:
    section.add "X-Amz-Algorithm", valid_611911
  var valid_611912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-SignedHeaders", valid_611912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611913: Call_GetDescribeSSLPolicies_611898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611913.validator(path, query, header, formData, body)
  let scheme = call_611913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611913.url(scheme.get, call_611913.host, call_611913.base,
                         call_611913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611913, url, valid)

proc call*(call_611914: Call_GetDescribeSSLPolicies_611898; Marker: string = "";
          PageSize: int = 0; Action: string = "DescribeSSLPolicies";
          Version: string = "2015-12-01"; Names: JsonNode = nil): Recallable =
  ## getDescribeSSLPolicies
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Names: JArray
  ##        : The names of the policies.
  var query_611915 = newJObject()
  add(query_611915, "Marker", newJString(Marker))
  add(query_611915, "PageSize", newJInt(PageSize))
  add(query_611915, "Action", newJString(Action))
  add(query_611915, "Version", newJString(Version))
  if Names != nil:
    query_611915.add "Names", Names
  result = call_611914.call(nil, query_611915, nil, nil, nil)

var getDescribeSSLPolicies* = Call_GetDescribeSSLPolicies_611898(
    name: "getDescribeSSLPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_GetDescribeSSLPolicies_611899, base: "/",
    url: url_GetDescribeSSLPolicies_611900, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_611951 = ref object of OpenApiRestCall_610658
proc url_PostDescribeTags_611953(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTags_611952(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611954 = query.getOrDefault("Action")
  valid_611954 = validateParameter(valid_611954, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_611954 != nil:
    section.add "Action", valid_611954
  var valid_611955 = query.getOrDefault("Version")
  valid_611955 = validateParameter(valid_611955, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611955 != nil:
    section.add "Version", valid_611955
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611956 = header.getOrDefault("X-Amz-Signature")
  valid_611956 = validateParameter(valid_611956, JString, required = false,
                                 default = nil)
  if valid_611956 != nil:
    section.add "X-Amz-Signature", valid_611956
  var valid_611957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611957 = validateParameter(valid_611957, JString, required = false,
                                 default = nil)
  if valid_611957 != nil:
    section.add "X-Amz-Content-Sha256", valid_611957
  var valid_611958 = header.getOrDefault("X-Amz-Date")
  valid_611958 = validateParameter(valid_611958, JString, required = false,
                                 default = nil)
  if valid_611958 != nil:
    section.add "X-Amz-Date", valid_611958
  var valid_611959 = header.getOrDefault("X-Amz-Credential")
  valid_611959 = validateParameter(valid_611959, JString, required = false,
                                 default = nil)
  if valid_611959 != nil:
    section.add "X-Amz-Credential", valid_611959
  var valid_611960 = header.getOrDefault("X-Amz-Security-Token")
  valid_611960 = validateParameter(valid_611960, JString, required = false,
                                 default = nil)
  if valid_611960 != nil:
    section.add "X-Amz-Security-Token", valid_611960
  var valid_611961 = header.getOrDefault("X-Amz-Algorithm")
  valid_611961 = validateParameter(valid_611961, JString, required = false,
                                 default = nil)
  if valid_611961 != nil:
    section.add "X-Amz-Algorithm", valid_611961
  var valid_611962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611962 = validateParameter(valid_611962, JString, required = false,
                                 default = nil)
  if valid_611962 != nil:
    section.add "X-Amz-SignedHeaders", valid_611962
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_611963 = formData.getOrDefault("ResourceArns")
  valid_611963 = validateParameter(valid_611963, JArray, required = true, default = nil)
  if valid_611963 != nil:
    section.add "ResourceArns", valid_611963
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611964: Call_PostDescribeTags_611951; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_611964.validator(path, query, header, formData, body)
  let scheme = call_611964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611964.url(scheme.get, call_611964.host, call_611964.base,
                         call_611964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611964, url, valid)

proc call*(call_611965: Call_PostDescribeTags_611951; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611966 = newJObject()
  var formData_611967 = newJObject()
  if ResourceArns != nil:
    formData_611967.add "ResourceArns", ResourceArns
  add(query_611966, "Action", newJString(Action))
  add(query_611966, "Version", newJString(Version))
  result = call_611965.call(nil, query_611966, nil, formData_611967, nil)

var postDescribeTags* = Call_PostDescribeTags_611951(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_611952,
    base: "/", url: url_PostDescribeTags_611953,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_611935 = ref object of OpenApiRestCall_610658
proc url_GetDescribeTags_611937(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTags_611936(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArns` field"
  var valid_611938 = query.getOrDefault("ResourceArns")
  valid_611938 = validateParameter(valid_611938, JArray, required = true, default = nil)
  if valid_611938 != nil:
    section.add "ResourceArns", valid_611938
  var valid_611939 = query.getOrDefault("Action")
  valid_611939 = validateParameter(valid_611939, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_611939 != nil:
    section.add "Action", valid_611939
  var valid_611940 = query.getOrDefault("Version")
  valid_611940 = validateParameter(valid_611940, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611940 != nil:
    section.add "Version", valid_611940
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611941 = header.getOrDefault("X-Amz-Signature")
  valid_611941 = validateParameter(valid_611941, JString, required = false,
                                 default = nil)
  if valid_611941 != nil:
    section.add "X-Amz-Signature", valid_611941
  var valid_611942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611942 = validateParameter(valid_611942, JString, required = false,
                                 default = nil)
  if valid_611942 != nil:
    section.add "X-Amz-Content-Sha256", valid_611942
  var valid_611943 = header.getOrDefault("X-Amz-Date")
  valid_611943 = validateParameter(valid_611943, JString, required = false,
                                 default = nil)
  if valid_611943 != nil:
    section.add "X-Amz-Date", valid_611943
  var valid_611944 = header.getOrDefault("X-Amz-Credential")
  valid_611944 = validateParameter(valid_611944, JString, required = false,
                                 default = nil)
  if valid_611944 != nil:
    section.add "X-Amz-Credential", valid_611944
  var valid_611945 = header.getOrDefault("X-Amz-Security-Token")
  valid_611945 = validateParameter(valid_611945, JString, required = false,
                                 default = nil)
  if valid_611945 != nil:
    section.add "X-Amz-Security-Token", valid_611945
  var valid_611946 = header.getOrDefault("X-Amz-Algorithm")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "X-Amz-Algorithm", valid_611946
  var valid_611947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "X-Amz-SignedHeaders", valid_611947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611948: Call_GetDescribeTags_611935; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_611948.validator(path, query, header, formData, body)
  let scheme = call_611948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611948.url(scheme.get, call_611948.host, call_611948.base,
                         call_611948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611948, url, valid)

proc call*(call_611949: Call_GetDescribeTags_611935; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611950 = newJObject()
  if ResourceArns != nil:
    query_611950.add "ResourceArns", ResourceArns
  add(query_611950, "Action", newJString(Action))
  add(query_611950, "Version", newJString(Version))
  result = call_611949.call(nil, query_611950, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_611935(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_611936,
    base: "/", url: url_GetDescribeTags_611937, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroupAttributes_611984 = ref object of OpenApiRestCall_610658
proc url_PostDescribeTargetGroupAttributes_611986(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTargetGroupAttributes_611985(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611987 = query.getOrDefault("Action")
  valid_611987 = validateParameter(valid_611987, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_611987 != nil:
    section.add "Action", valid_611987
  var valid_611988 = query.getOrDefault("Version")
  valid_611988 = validateParameter(valid_611988, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611988 != nil:
    section.add "Version", valid_611988
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611989 = header.getOrDefault("X-Amz-Signature")
  valid_611989 = validateParameter(valid_611989, JString, required = false,
                                 default = nil)
  if valid_611989 != nil:
    section.add "X-Amz-Signature", valid_611989
  var valid_611990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611990 = validateParameter(valid_611990, JString, required = false,
                                 default = nil)
  if valid_611990 != nil:
    section.add "X-Amz-Content-Sha256", valid_611990
  var valid_611991 = header.getOrDefault("X-Amz-Date")
  valid_611991 = validateParameter(valid_611991, JString, required = false,
                                 default = nil)
  if valid_611991 != nil:
    section.add "X-Amz-Date", valid_611991
  var valid_611992 = header.getOrDefault("X-Amz-Credential")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "X-Amz-Credential", valid_611992
  var valid_611993 = header.getOrDefault("X-Amz-Security-Token")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "X-Amz-Security-Token", valid_611993
  var valid_611994 = header.getOrDefault("X-Amz-Algorithm")
  valid_611994 = validateParameter(valid_611994, JString, required = false,
                                 default = nil)
  if valid_611994 != nil:
    section.add "X-Amz-Algorithm", valid_611994
  var valid_611995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611995 = validateParameter(valid_611995, JString, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "X-Amz-SignedHeaders", valid_611995
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_611996 = formData.getOrDefault("TargetGroupArn")
  valid_611996 = validateParameter(valid_611996, JString, required = true,
                                 default = nil)
  if valid_611996 != nil:
    section.add "TargetGroupArn", valid_611996
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611997: Call_PostDescribeTargetGroupAttributes_611984;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611997.validator(path, query, header, formData, body)
  let scheme = call_611997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611997.url(scheme.get, call_611997.host, call_611997.base,
                         call_611997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611997, url, valid)

proc call*(call_611998: Call_PostDescribeTargetGroupAttributes_611984;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_611999 = newJObject()
  var formData_612000 = newJObject()
  add(query_611999, "Action", newJString(Action))
  add(formData_612000, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_611999, "Version", newJString(Version))
  result = call_611998.call(nil, query_611999, nil, formData_612000, nil)

var postDescribeTargetGroupAttributes* = Call_PostDescribeTargetGroupAttributes_611984(
    name: "postDescribeTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_PostDescribeTargetGroupAttributes_611985, base: "/",
    url: url_PostDescribeTargetGroupAttributes_611986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroupAttributes_611968 = ref object of OpenApiRestCall_610658
proc url_GetDescribeTargetGroupAttributes_611970(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTargetGroupAttributes_611969(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_611971 = query.getOrDefault("TargetGroupArn")
  valid_611971 = validateParameter(valid_611971, JString, required = true,
                                 default = nil)
  if valid_611971 != nil:
    section.add "TargetGroupArn", valid_611971
  var valid_611972 = query.getOrDefault("Action")
  valid_611972 = validateParameter(valid_611972, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_611972 != nil:
    section.add "Action", valid_611972
  var valid_611973 = query.getOrDefault("Version")
  valid_611973 = validateParameter(valid_611973, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_611973 != nil:
    section.add "Version", valid_611973
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611974 = header.getOrDefault("X-Amz-Signature")
  valid_611974 = validateParameter(valid_611974, JString, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "X-Amz-Signature", valid_611974
  var valid_611975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611975 = validateParameter(valid_611975, JString, required = false,
                                 default = nil)
  if valid_611975 != nil:
    section.add "X-Amz-Content-Sha256", valid_611975
  var valid_611976 = header.getOrDefault("X-Amz-Date")
  valid_611976 = validateParameter(valid_611976, JString, required = false,
                                 default = nil)
  if valid_611976 != nil:
    section.add "X-Amz-Date", valid_611976
  var valid_611977 = header.getOrDefault("X-Amz-Credential")
  valid_611977 = validateParameter(valid_611977, JString, required = false,
                                 default = nil)
  if valid_611977 != nil:
    section.add "X-Amz-Credential", valid_611977
  var valid_611978 = header.getOrDefault("X-Amz-Security-Token")
  valid_611978 = validateParameter(valid_611978, JString, required = false,
                                 default = nil)
  if valid_611978 != nil:
    section.add "X-Amz-Security-Token", valid_611978
  var valid_611979 = header.getOrDefault("X-Amz-Algorithm")
  valid_611979 = validateParameter(valid_611979, JString, required = false,
                                 default = nil)
  if valid_611979 != nil:
    section.add "X-Amz-Algorithm", valid_611979
  var valid_611980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611980 = validateParameter(valid_611980, JString, required = false,
                                 default = nil)
  if valid_611980 != nil:
    section.add "X-Amz-SignedHeaders", valid_611980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611981: Call_GetDescribeTargetGroupAttributes_611968;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611981.validator(path, query, header, formData, body)
  let scheme = call_611981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611981.url(scheme.get, call_611981.host, call_611981.base,
                         call_611981.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611981, url, valid)

proc call*(call_611982: Call_GetDescribeTargetGroupAttributes_611968;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611983 = newJObject()
  add(query_611983, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_611983, "Action", newJString(Action))
  add(query_611983, "Version", newJString(Version))
  result = call_611982.call(nil, query_611983, nil, nil, nil)

var getDescribeTargetGroupAttributes* = Call_GetDescribeTargetGroupAttributes_611968(
    name: "getDescribeTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_GetDescribeTargetGroupAttributes_611969, base: "/",
    url: url_GetDescribeTargetGroupAttributes_611970,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroups_612021 = ref object of OpenApiRestCall_610658
proc url_PostDescribeTargetGroups_612023(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTargetGroups_612022(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612024 = query.getOrDefault("Action")
  valid_612024 = validateParameter(valid_612024, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_612024 != nil:
    section.add "Action", valid_612024
  var valid_612025 = query.getOrDefault("Version")
  valid_612025 = validateParameter(valid_612025, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612025 != nil:
    section.add "Version", valid_612025
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612026 = header.getOrDefault("X-Amz-Signature")
  valid_612026 = validateParameter(valid_612026, JString, required = false,
                                 default = nil)
  if valid_612026 != nil:
    section.add "X-Amz-Signature", valid_612026
  var valid_612027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612027 = validateParameter(valid_612027, JString, required = false,
                                 default = nil)
  if valid_612027 != nil:
    section.add "X-Amz-Content-Sha256", valid_612027
  var valid_612028 = header.getOrDefault("X-Amz-Date")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "X-Amz-Date", valid_612028
  var valid_612029 = header.getOrDefault("X-Amz-Credential")
  valid_612029 = validateParameter(valid_612029, JString, required = false,
                                 default = nil)
  if valid_612029 != nil:
    section.add "X-Amz-Credential", valid_612029
  var valid_612030 = header.getOrDefault("X-Amz-Security-Token")
  valid_612030 = validateParameter(valid_612030, JString, required = false,
                                 default = nil)
  if valid_612030 != nil:
    section.add "X-Amz-Security-Token", valid_612030
  var valid_612031 = header.getOrDefault("X-Amz-Algorithm")
  valid_612031 = validateParameter(valid_612031, JString, required = false,
                                 default = nil)
  if valid_612031 != nil:
    section.add "X-Amz-Algorithm", valid_612031
  var valid_612032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612032 = validateParameter(valid_612032, JString, required = false,
                                 default = nil)
  if valid_612032 != nil:
    section.add "X-Amz-SignedHeaders", valid_612032
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the target groups.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   TargetGroupArns: JArray
  ##                  : The Amazon Resource Names (ARN) of the target groups.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   LoadBalancerArn: JString
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  var valid_612033 = formData.getOrDefault("Names")
  valid_612033 = validateParameter(valid_612033, JArray, required = false,
                                 default = nil)
  if valid_612033 != nil:
    section.add "Names", valid_612033
  var valid_612034 = formData.getOrDefault("Marker")
  valid_612034 = validateParameter(valid_612034, JString, required = false,
                                 default = nil)
  if valid_612034 != nil:
    section.add "Marker", valid_612034
  var valid_612035 = formData.getOrDefault("TargetGroupArns")
  valid_612035 = validateParameter(valid_612035, JArray, required = false,
                                 default = nil)
  if valid_612035 != nil:
    section.add "TargetGroupArns", valid_612035
  var valid_612036 = formData.getOrDefault("PageSize")
  valid_612036 = validateParameter(valid_612036, JInt, required = false, default = nil)
  if valid_612036 != nil:
    section.add "PageSize", valid_612036
  var valid_612037 = formData.getOrDefault("LoadBalancerArn")
  valid_612037 = validateParameter(valid_612037, JString, required = false,
                                 default = nil)
  if valid_612037 != nil:
    section.add "LoadBalancerArn", valid_612037
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612038: Call_PostDescribeTargetGroups_612021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_612038.validator(path, query, header, formData, body)
  let scheme = call_612038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612038.url(scheme.get, call_612038.host, call_612038.base,
                         call_612038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612038, url, valid)

proc call*(call_612039: Call_PostDescribeTargetGroups_612021;
          Names: JsonNode = nil; Marker: string = "";
          Action: string = "DescribeTargetGroups"; TargetGroupArns: JsonNode = nil;
          PageSize: int = 0; Version: string = "2015-12-01";
          LoadBalancerArn: string = ""): Recallable =
  ## postDescribeTargetGroups
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ##   Names: JArray
  ##        : The names of the target groups.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   TargetGroupArns: JArray
  ##                  : The Amazon Resource Names (ARN) of the target groups.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  ##   LoadBalancerArn: string
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_612040 = newJObject()
  var formData_612041 = newJObject()
  if Names != nil:
    formData_612041.add "Names", Names
  add(formData_612041, "Marker", newJString(Marker))
  add(query_612040, "Action", newJString(Action))
  if TargetGroupArns != nil:
    formData_612041.add "TargetGroupArns", TargetGroupArns
  add(formData_612041, "PageSize", newJInt(PageSize))
  add(query_612040, "Version", newJString(Version))
  add(formData_612041, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_612039.call(nil, query_612040, nil, formData_612041, nil)

var postDescribeTargetGroups* = Call_PostDescribeTargetGroups_612021(
    name: "postDescribeTargetGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_PostDescribeTargetGroups_612022, base: "/",
    url: url_PostDescribeTargetGroups_612023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroups_612001 = ref object of OpenApiRestCall_610658
proc url_GetDescribeTargetGroups_612003(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTargetGroups_612002(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerArn: JString
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   TargetGroupArns: JArray
  ##                  : The Amazon Resource Names (ARN) of the target groups.
  ##   Version: JString (required)
  ##   Names: JArray
  ##        : The names of the target groups.
  section = newJObject()
  var valid_612004 = query.getOrDefault("Marker")
  valid_612004 = validateParameter(valid_612004, JString, required = false,
                                 default = nil)
  if valid_612004 != nil:
    section.add "Marker", valid_612004
  var valid_612005 = query.getOrDefault("LoadBalancerArn")
  valid_612005 = validateParameter(valid_612005, JString, required = false,
                                 default = nil)
  if valid_612005 != nil:
    section.add "LoadBalancerArn", valid_612005
  var valid_612006 = query.getOrDefault("PageSize")
  valid_612006 = validateParameter(valid_612006, JInt, required = false, default = nil)
  if valid_612006 != nil:
    section.add "PageSize", valid_612006
  var valid_612007 = query.getOrDefault("Action")
  valid_612007 = validateParameter(valid_612007, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_612007 != nil:
    section.add "Action", valid_612007
  var valid_612008 = query.getOrDefault("TargetGroupArns")
  valid_612008 = validateParameter(valid_612008, JArray, required = false,
                                 default = nil)
  if valid_612008 != nil:
    section.add "TargetGroupArns", valid_612008
  var valid_612009 = query.getOrDefault("Version")
  valid_612009 = validateParameter(valid_612009, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612009 != nil:
    section.add "Version", valid_612009
  var valid_612010 = query.getOrDefault("Names")
  valid_612010 = validateParameter(valid_612010, JArray, required = false,
                                 default = nil)
  if valid_612010 != nil:
    section.add "Names", valid_612010
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612011 = header.getOrDefault("X-Amz-Signature")
  valid_612011 = validateParameter(valid_612011, JString, required = false,
                                 default = nil)
  if valid_612011 != nil:
    section.add "X-Amz-Signature", valid_612011
  var valid_612012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612012 = validateParameter(valid_612012, JString, required = false,
                                 default = nil)
  if valid_612012 != nil:
    section.add "X-Amz-Content-Sha256", valid_612012
  var valid_612013 = header.getOrDefault("X-Amz-Date")
  valid_612013 = validateParameter(valid_612013, JString, required = false,
                                 default = nil)
  if valid_612013 != nil:
    section.add "X-Amz-Date", valid_612013
  var valid_612014 = header.getOrDefault("X-Amz-Credential")
  valid_612014 = validateParameter(valid_612014, JString, required = false,
                                 default = nil)
  if valid_612014 != nil:
    section.add "X-Amz-Credential", valid_612014
  var valid_612015 = header.getOrDefault("X-Amz-Security-Token")
  valid_612015 = validateParameter(valid_612015, JString, required = false,
                                 default = nil)
  if valid_612015 != nil:
    section.add "X-Amz-Security-Token", valid_612015
  var valid_612016 = header.getOrDefault("X-Amz-Algorithm")
  valid_612016 = validateParameter(valid_612016, JString, required = false,
                                 default = nil)
  if valid_612016 != nil:
    section.add "X-Amz-Algorithm", valid_612016
  var valid_612017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612017 = validateParameter(valid_612017, JString, required = false,
                                 default = nil)
  if valid_612017 != nil:
    section.add "X-Amz-SignedHeaders", valid_612017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612018: Call_GetDescribeTargetGroups_612001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_612018.validator(path, query, header, formData, body)
  let scheme = call_612018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612018.url(scheme.get, call_612018.host, call_612018.base,
                         call_612018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612018, url, valid)

proc call*(call_612019: Call_GetDescribeTargetGroups_612001; Marker: string = "";
          LoadBalancerArn: string = ""; PageSize: int = 0;
          Action: string = "DescribeTargetGroups"; TargetGroupArns: JsonNode = nil;
          Version: string = "2015-12-01"; Names: JsonNode = nil): Recallable =
  ## getDescribeTargetGroups
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerArn: string
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   TargetGroupArns: JArray
  ##                  : The Amazon Resource Names (ARN) of the target groups.
  ##   Version: string (required)
  ##   Names: JArray
  ##        : The names of the target groups.
  var query_612020 = newJObject()
  add(query_612020, "Marker", newJString(Marker))
  add(query_612020, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_612020, "PageSize", newJInt(PageSize))
  add(query_612020, "Action", newJString(Action))
  if TargetGroupArns != nil:
    query_612020.add "TargetGroupArns", TargetGroupArns
  add(query_612020, "Version", newJString(Version))
  if Names != nil:
    query_612020.add "Names", Names
  result = call_612019.call(nil, query_612020, nil, nil, nil)

var getDescribeTargetGroups* = Call_GetDescribeTargetGroups_612001(
    name: "getDescribeTargetGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_GetDescribeTargetGroups_612002, base: "/",
    url: url_GetDescribeTargetGroups_612003, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetHealth_612059 = ref object of OpenApiRestCall_610658
proc url_PostDescribeTargetHealth_612061(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTargetHealth_612060(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612062 = query.getOrDefault("Action")
  valid_612062 = validateParameter(valid_612062, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_612062 != nil:
    section.add "Action", valid_612062
  var valid_612063 = query.getOrDefault("Version")
  valid_612063 = validateParameter(valid_612063, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612063 != nil:
    section.add "Version", valid_612063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612064 = header.getOrDefault("X-Amz-Signature")
  valid_612064 = validateParameter(valid_612064, JString, required = false,
                                 default = nil)
  if valid_612064 != nil:
    section.add "X-Amz-Signature", valid_612064
  var valid_612065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612065 = validateParameter(valid_612065, JString, required = false,
                                 default = nil)
  if valid_612065 != nil:
    section.add "X-Amz-Content-Sha256", valid_612065
  var valid_612066 = header.getOrDefault("X-Amz-Date")
  valid_612066 = validateParameter(valid_612066, JString, required = false,
                                 default = nil)
  if valid_612066 != nil:
    section.add "X-Amz-Date", valid_612066
  var valid_612067 = header.getOrDefault("X-Amz-Credential")
  valid_612067 = validateParameter(valid_612067, JString, required = false,
                                 default = nil)
  if valid_612067 != nil:
    section.add "X-Amz-Credential", valid_612067
  var valid_612068 = header.getOrDefault("X-Amz-Security-Token")
  valid_612068 = validateParameter(valid_612068, JString, required = false,
                                 default = nil)
  if valid_612068 != nil:
    section.add "X-Amz-Security-Token", valid_612068
  var valid_612069 = header.getOrDefault("X-Amz-Algorithm")
  valid_612069 = validateParameter(valid_612069, JString, required = false,
                                 default = nil)
  if valid_612069 != nil:
    section.add "X-Amz-Algorithm", valid_612069
  var valid_612070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612070 = validateParameter(valid_612070, JString, required = false,
                                 default = nil)
  if valid_612070 != nil:
    section.add "X-Amz-SignedHeaders", valid_612070
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_612071 = formData.getOrDefault("Targets")
  valid_612071 = validateParameter(valid_612071, JArray, required = false,
                                 default = nil)
  if valid_612071 != nil:
    section.add "Targets", valid_612071
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_612072 = formData.getOrDefault("TargetGroupArn")
  valid_612072 = validateParameter(valid_612072, JString, required = true,
                                 default = nil)
  if valid_612072 != nil:
    section.add "TargetGroupArn", valid_612072
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612073: Call_PostDescribeTargetHealth_612059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_612073.validator(path, query, header, formData, body)
  let scheme = call_612073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612073.url(scheme.get, call_612073.host, call_612073.base,
                         call_612073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612073, url, valid)

proc call*(call_612074: Call_PostDescribeTargetHealth_612059;
          TargetGroupArn: string; Targets: JsonNode = nil;
          Action: string = "DescribeTargetHealth"; Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetHealth
  ## Describes the health of the specified targets or all of your targets.
  ##   Targets: JArray
  ##          : The targets.
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_612075 = newJObject()
  var formData_612076 = newJObject()
  if Targets != nil:
    formData_612076.add "Targets", Targets
  add(query_612075, "Action", newJString(Action))
  add(formData_612076, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_612075, "Version", newJString(Version))
  result = call_612074.call(nil, query_612075, nil, formData_612076, nil)

var postDescribeTargetHealth* = Call_PostDescribeTargetHealth_612059(
    name: "postDescribeTargetHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_PostDescribeTargetHealth_612060, base: "/",
    url: url_PostDescribeTargetHealth_612061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetHealth_612042 = ref object of OpenApiRestCall_610658
proc url_GetDescribeTargetHealth_612044(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTargetHealth_612043(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612045 = query.getOrDefault("Targets")
  valid_612045 = validateParameter(valid_612045, JArray, required = false,
                                 default = nil)
  if valid_612045 != nil:
    section.add "Targets", valid_612045
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_612046 = query.getOrDefault("TargetGroupArn")
  valid_612046 = validateParameter(valid_612046, JString, required = true,
                                 default = nil)
  if valid_612046 != nil:
    section.add "TargetGroupArn", valid_612046
  var valid_612047 = query.getOrDefault("Action")
  valid_612047 = validateParameter(valid_612047, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_612047 != nil:
    section.add "Action", valid_612047
  var valid_612048 = query.getOrDefault("Version")
  valid_612048 = validateParameter(valid_612048, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612048 != nil:
    section.add "Version", valid_612048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612049 = header.getOrDefault("X-Amz-Signature")
  valid_612049 = validateParameter(valid_612049, JString, required = false,
                                 default = nil)
  if valid_612049 != nil:
    section.add "X-Amz-Signature", valid_612049
  var valid_612050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612050 = validateParameter(valid_612050, JString, required = false,
                                 default = nil)
  if valid_612050 != nil:
    section.add "X-Amz-Content-Sha256", valid_612050
  var valid_612051 = header.getOrDefault("X-Amz-Date")
  valid_612051 = validateParameter(valid_612051, JString, required = false,
                                 default = nil)
  if valid_612051 != nil:
    section.add "X-Amz-Date", valid_612051
  var valid_612052 = header.getOrDefault("X-Amz-Credential")
  valid_612052 = validateParameter(valid_612052, JString, required = false,
                                 default = nil)
  if valid_612052 != nil:
    section.add "X-Amz-Credential", valid_612052
  var valid_612053 = header.getOrDefault("X-Amz-Security-Token")
  valid_612053 = validateParameter(valid_612053, JString, required = false,
                                 default = nil)
  if valid_612053 != nil:
    section.add "X-Amz-Security-Token", valid_612053
  var valid_612054 = header.getOrDefault("X-Amz-Algorithm")
  valid_612054 = validateParameter(valid_612054, JString, required = false,
                                 default = nil)
  if valid_612054 != nil:
    section.add "X-Amz-Algorithm", valid_612054
  var valid_612055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612055 = validateParameter(valid_612055, JString, required = false,
                                 default = nil)
  if valid_612055 != nil:
    section.add "X-Amz-SignedHeaders", valid_612055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612056: Call_GetDescribeTargetHealth_612042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_612056.validator(path, query, header, formData, body)
  let scheme = call_612056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612056.url(scheme.get, call_612056.host, call_612056.base,
                         call_612056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612056, url, valid)

proc call*(call_612057: Call_GetDescribeTargetHealth_612042;
          TargetGroupArn: string; Targets: JsonNode = nil;
          Action: string = "DescribeTargetHealth"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetHealth
  ## Describes the health of the specified targets or all of your targets.
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612058 = newJObject()
  if Targets != nil:
    query_612058.add "Targets", Targets
  add(query_612058, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_612058, "Action", newJString(Action))
  add(query_612058, "Version", newJString(Version))
  result = call_612057.call(nil, query_612058, nil, nil, nil)

var getDescribeTargetHealth* = Call_GetDescribeTargetHealth_612042(
    name: "getDescribeTargetHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_GetDescribeTargetHealth_612043, base: "/",
    url: url_GetDescribeTargetHealth_612044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyListener_612098 = ref object of OpenApiRestCall_610658
proc url_PostModifyListener_612100(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyListener_612099(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612101 = query.getOrDefault("Action")
  valid_612101 = validateParameter(valid_612101, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_612101 != nil:
    section.add "Action", valid_612101
  var valid_612102 = query.getOrDefault("Version")
  valid_612102 = validateParameter(valid_612102, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612102 != nil:
    section.add "Version", valid_612102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612103 = header.getOrDefault("X-Amz-Signature")
  valid_612103 = validateParameter(valid_612103, JString, required = false,
                                 default = nil)
  if valid_612103 != nil:
    section.add "X-Amz-Signature", valid_612103
  var valid_612104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612104 = validateParameter(valid_612104, JString, required = false,
                                 default = nil)
  if valid_612104 != nil:
    section.add "X-Amz-Content-Sha256", valid_612104
  var valid_612105 = header.getOrDefault("X-Amz-Date")
  valid_612105 = validateParameter(valid_612105, JString, required = false,
                                 default = nil)
  if valid_612105 != nil:
    section.add "X-Amz-Date", valid_612105
  var valid_612106 = header.getOrDefault("X-Amz-Credential")
  valid_612106 = validateParameter(valid_612106, JString, required = false,
                                 default = nil)
  if valid_612106 != nil:
    section.add "X-Amz-Credential", valid_612106
  var valid_612107 = header.getOrDefault("X-Amz-Security-Token")
  valid_612107 = validateParameter(valid_612107, JString, required = false,
                                 default = nil)
  if valid_612107 != nil:
    section.add "X-Amz-Security-Token", valid_612107
  var valid_612108 = header.getOrDefault("X-Amz-Algorithm")
  valid_612108 = validateParameter(valid_612108, JString, required = false,
                                 default = nil)
  if valid_612108 != nil:
    section.add "X-Amz-Algorithm", valid_612108
  var valid_612109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612109 = validateParameter(valid_612109, JString, required = false,
                                 default = nil)
  if valid_612109 != nil:
    section.add "X-Amz-SignedHeaders", valid_612109
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : The port for connections from clients to the load balancer.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list, use <a>AddListenerCertificates</a>.</p>
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   DefaultActions: JArray
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Protocol: JString
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   SslPolicy: JString
  ##            : [HTTPS and TLS listeners] The security policy that defines which protocols and ciphers are supported. For more information, see <a 
  ## href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.
  section = newJObject()
  var valid_612110 = formData.getOrDefault("Port")
  valid_612110 = validateParameter(valid_612110, JInt, required = false, default = nil)
  if valid_612110 != nil:
    section.add "Port", valid_612110
  var valid_612111 = formData.getOrDefault("Certificates")
  valid_612111 = validateParameter(valid_612111, JArray, required = false,
                                 default = nil)
  if valid_612111 != nil:
    section.add "Certificates", valid_612111
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_612112 = formData.getOrDefault("ListenerArn")
  valid_612112 = validateParameter(valid_612112, JString, required = true,
                                 default = nil)
  if valid_612112 != nil:
    section.add "ListenerArn", valid_612112
  var valid_612113 = formData.getOrDefault("DefaultActions")
  valid_612113 = validateParameter(valid_612113, JArray, required = false,
                                 default = nil)
  if valid_612113 != nil:
    section.add "DefaultActions", valid_612113
  var valid_612114 = formData.getOrDefault("Protocol")
  valid_612114 = validateParameter(valid_612114, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_612114 != nil:
    section.add "Protocol", valid_612114
  var valid_612115 = formData.getOrDefault("SslPolicy")
  valid_612115 = validateParameter(valid_612115, JString, required = false,
                                 default = nil)
  if valid_612115 != nil:
    section.add "SslPolicy", valid_612115
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612116: Call_PostModifyListener_612098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ## 
  let valid = call_612116.validator(path, query, header, formData, body)
  let scheme = call_612116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612116.url(scheme.get, call_612116.host, call_612116.base,
                         call_612116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612116, url, valid)

proc call*(call_612117: Call_PostModifyListener_612098; ListenerArn: string;
          Port: int = 0; Certificates: JsonNode = nil; DefaultActions: JsonNode = nil;
          Protocol: string = "HTTP"; Action: string = "ModifyListener";
          SslPolicy: string = ""; Version: string = "2015-12-01"): Recallable =
  ## postModifyListener
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ##   Port: int
  ##       : The port for connections from clients to the load balancer.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list, use <a>AddListenerCertificates</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   DefaultActions: JArray
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Protocol: string
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   Action: string (required)
  ##   SslPolicy: string
  ##            : [HTTPS and TLS listeners] The security policy that defines which protocols and ciphers are supported. For more information, see <a 
  ## href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.
  ##   Version: string (required)
  var query_612118 = newJObject()
  var formData_612119 = newJObject()
  add(formData_612119, "Port", newJInt(Port))
  if Certificates != nil:
    formData_612119.add "Certificates", Certificates
  add(formData_612119, "ListenerArn", newJString(ListenerArn))
  if DefaultActions != nil:
    formData_612119.add "DefaultActions", DefaultActions
  add(formData_612119, "Protocol", newJString(Protocol))
  add(query_612118, "Action", newJString(Action))
  add(formData_612119, "SslPolicy", newJString(SslPolicy))
  add(query_612118, "Version", newJString(Version))
  result = call_612117.call(nil, query_612118, nil, formData_612119, nil)

var postModifyListener* = Call_PostModifyListener_612098(
    name: "postModifyListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=ModifyListener",
    validator: validate_PostModifyListener_612099, base: "/",
    url: url_PostModifyListener_612100, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyListener_612077 = ref object of OpenApiRestCall_610658
proc url_GetModifyListener_612079(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyListener_612078(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SslPolicy: JString
  ##            : [HTTPS and TLS listeners] The security policy that defines which protocols and ciphers are supported. For more information, see <a 
  ## href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list, use <a>AddListenerCertificates</a>.</p>
  ##   DefaultActions: JArray
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Action: JString (required)
  ##   Port: JInt
  ##       : The port for connections from clients to the load balancer.
  ##   Protocol: JString
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   Version: JString (required)
  section = newJObject()
  var valid_612080 = query.getOrDefault("SslPolicy")
  valid_612080 = validateParameter(valid_612080, JString, required = false,
                                 default = nil)
  if valid_612080 != nil:
    section.add "SslPolicy", valid_612080
  assert query != nil,
        "query argument is necessary due to required `ListenerArn` field"
  var valid_612081 = query.getOrDefault("ListenerArn")
  valid_612081 = validateParameter(valid_612081, JString, required = true,
                                 default = nil)
  if valid_612081 != nil:
    section.add "ListenerArn", valid_612081
  var valid_612082 = query.getOrDefault("Certificates")
  valid_612082 = validateParameter(valid_612082, JArray, required = false,
                                 default = nil)
  if valid_612082 != nil:
    section.add "Certificates", valid_612082
  var valid_612083 = query.getOrDefault("DefaultActions")
  valid_612083 = validateParameter(valid_612083, JArray, required = false,
                                 default = nil)
  if valid_612083 != nil:
    section.add "DefaultActions", valid_612083
  var valid_612084 = query.getOrDefault("Action")
  valid_612084 = validateParameter(valid_612084, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_612084 != nil:
    section.add "Action", valid_612084
  var valid_612085 = query.getOrDefault("Port")
  valid_612085 = validateParameter(valid_612085, JInt, required = false, default = nil)
  if valid_612085 != nil:
    section.add "Port", valid_612085
  var valid_612086 = query.getOrDefault("Protocol")
  valid_612086 = validateParameter(valid_612086, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_612086 != nil:
    section.add "Protocol", valid_612086
  var valid_612087 = query.getOrDefault("Version")
  valid_612087 = validateParameter(valid_612087, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612087 != nil:
    section.add "Version", valid_612087
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612088 = header.getOrDefault("X-Amz-Signature")
  valid_612088 = validateParameter(valid_612088, JString, required = false,
                                 default = nil)
  if valid_612088 != nil:
    section.add "X-Amz-Signature", valid_612088
  var valid_612089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "X-Amz-Content-Sha256", valid_612089
  var valid_612090 = header.getOrDefault("X-Amz-Date")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "X-Amz-Date", valid_612090
  var valid_612091 = header.getOrDefault("X-Amz-Credential")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "X-Amz-Credential", valid_612091
  var valid_612092 = header.getOrDefault("X-Amz-Security-Token")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "X-Amz-Security-Token", valid_612092
  var valid_612093 = header.getOrDefault("X-Amz-Algorithm")
  valid_612093 = validateParameter(valid_612093, JString, required = false,
                                 default = nil)
  if valid_612093 != nil:
    section.add "X-Amz-Algorithm", valid_612093
  var valid_612094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612094 = validateParameter(valid_612094, JString, required = false,
                                 default = nil)
  if valid_612094 != nil:
    section.add "X-Amz-SignedHeaders", valid_612094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612095: Call_GetModifyListener_612077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ## 
  let valid = call_612095.validator(path, query, header, formData, body)
  let scheme = call_612095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612095.url(scheme.get, call_612095.host, call_612095.base,
                         call_612095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612095, url, valid)

proc call*(call_612096: Call_GetModifyListener_612077; ListenerArn: string;
          SslPolicy: string = ""; Certificates: JsonNode = nil;
          DefaultActions: JsonNode = nil; Action: string = "ModifyListener";
          Port: int = 0; Protocol: string = "HTTP"; Version: string = "2015-12-01"): Recallable =
  ## getModifyListener
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ##   SslPolicy: string
  ##            : [HTTPS and TLS listeners] The security policy that defines which protocols and ciphers are supported. For more information, see <a 
  ## href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list, use <a>AddListenerCertificates</a>.</p>
  ##   DefaultActions: JArray
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Action: string (required)
  ##   Port: int
  ##       : The port for connections from clients to the load balancer.
  ##   Protocol: string
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   Version: string (required)
  var query_612097 = newJObject()
  add(query_612097, "SslPolicy", newJString(SslPolicy))
  add(query_612097, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_612097.add "Certificates", Certificates
  if DefaultActions != nil:
    query_612097.add "DefaultActions", DefaultActions
  add(query_612097, "Action", newJString(Action))
  add(query_612097, "Port", newJInt(Port))
  add(query_612097, "Protocol", newJString(Protocol))
  add(query_612097, "Version", newJString(Version))
  result = call_612096.call(nil, query_612097, nil, nil, nil)

var getModifyListener* = Call_GetModifyListener_612077(name: "getModifyListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyListener", validator: validate_GetModifyListener_612078,
    base: "/", url: url_GetModifyListener_612079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_612137 = ref object of OpenApiRestCall_610658
proc url_PostModifyLoadBalancerAttributes_612139(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyLoadBalancerAttributes_612138(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612140 = query.getOrDefault("Action")
  valid_612140 = validateParameter(valid_612140, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_612140 != nil:
    section.add "Action", valid_612140
  var valid_612141 = query.getOrDefault("Version")
  valid_612141 = validateParameter(valid_612141, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612141 != nil:
    section.add "Version", valid_612141
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612142 = header.getOrDefault("X-Amz-Signature")
  valid_612142 = validateParameter(valid_612142, JString, required = false,
                                 default = nil)
  if valid_612142 != nil:
    section.add "X-Amz-Signature", valid_612142
  var valid_612143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612143 = validateParameter(valid_612143, JString, required = false,
                                 default = nil)
  if valid_612143 != nil:
    section.add "X-Amz-Content-Sha256", valid_612143
  var valid_612144 = header.getOrDefault("X-Amz-Date")
  valid_612144 = validateParameter(valid_612144, JString, required = false,
                                 default = nil)
  if valid_612144 != nil:
    section.add "X-Amz-Date", valid_612144
  var valid_612145 = header.getOrDefault("X-Amz-Credential")
  valid_612145 = validateParameter(valid_612145, JString, required = false,
                                 default = nil)
  if valid_612145 != nil:
    section.add "X-Amz-Credential", valid_612145
  var valid_612146 = header.getOrDefault("X-Amz-Security-Token")
  valid_612146 = validateParameter(valid_612146, JString, required = false,
                                 default = nil)
  if valid_612146 != nil:
    section.add "X-Amz-Security-Token", valid_612146
  var valid_612147 = header.getOrDefault("X-Amz-Algorithm")
  valid_612147 = validateParameter(valid_612147, JString, required = false,
                                 default = nil)
  if valid_612147 != nil:
    section.add "X-Amz-Algorithm", valid_612147
  var valid_612148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612148 = validateParameter(valid_612148, JString, required = false,
                                 default = nil)
  if valid_612148 != nil:
    section.add "X-Amz-SignedHeaders", valid_612148
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_612149 = formData.getOrDefault("Attributes")
  valid_612149 = validateParameter(valid_612149, JArray, required = true, default = nil)
  if valid_612149 != nil:
    section.add "Attributes", valid_612149
  var valid_612150 = formData.getOrDefault("LoadBalancerArn")
  valid_612150 = validateParameter(valid_612150, JString, required = true,
                                 default = nil)
  if valid_612150 != nil:
    section.add "LoadBalancerArn", valid_612150
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612151: Call_PostModifyLoadBalancerAttributes_612137;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_612151.validator(path, query, header, formData, body)
  let scheme = call_612151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612151.url(scheme.get, call_612151.host, call_612151.base,
                         call_612151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612151, url, valid)

proc call*(call_612152: Call_PostModifyLoadBalancerAttributes_612137;
          Attributes: JsonNode; LoadBalancerArn: string;
          Action: string = "ModifyLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postModifyLoadBalancerAttributes
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_612153 = newJObject()
  var formData_612154 = newJObject()
  if Attributes != nil:
    formData_612154.add "Attributes", Attributes
  add(query_612153, "Action", newJString(Action))
  add(query_612153, "Version", newJString(Version))
  add(formData_612154, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_612152.call(nil, query_612153, nil, formData_612154, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_612137(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_612138, base: "/",
    url: url_PostModifyLoadBalancerAttributes_612139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_612120 = ref object of OpenApiRestCall_610658
proc url_GetModifyLoadBalancerAttributes_612122(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyLoadBalancerAttributes_612121(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_612123 = query.getOrDefault("LoadBalancerArn")
  valid_612123 = validateParameter(valid_612123, JString, required = true,
                                 default = nil)
  if valid_612123 != nil:
    section.add "LoadBalancerArn", valid_612123
  var valid_612124 = query.getOrDefault("Attributes")
  valid_612124 = validateParameter(valid_612124, JArray, required = true, default = nil)
  if valid_612124 != nil:
    section.add "Attributes", valid_612124
  var valid_612125 = query.getOrDefault("Action")
  valid_612125 = validateParameter(valid_612125, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_612125 != nil:
    section.add "Action", valid_612125
  var valid_612126 = query.getOrDefault("Version")
  valid_612126 = validateParameter(valid_612126, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612126 != nil:
    section.add "Version", valid_612126
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612127 = header.getOrDefault("X-Amz-Signature")
  valid_612127 = validateParameter(valid_612127, JString, required = false,
                                 default = nil)
  if valid_612127 != nil:
    section.add "X-Amz-Signature", valid_612127
  var valid_612128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612128 = validateParameter(valid_612128, JString, required = false,
                                 default = nil)
  if valid_612128 != nil:
    section.add "X-Amz-Content-Sha256", valid_612128
  var valid_612129 = header.getOrDefault("X-Amz-Date")
  valid_612129 = validateParameter(valid_612129, JString, required = false,
                                 default = nil)
  if valid_612129 != nil:
    section.add "X-Amz-Date", valid_612129
  var valid_612130 = header.getOrDefault("X-Amz-Credential")
  valid_612130 = validateParameter(valid_612130, JString, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "X-Amz-Credential", valid_612130
  var valid_612131 = header.getOrDefault("X-Amz-Security-Token")
  valid_612131 = validateParameter(valid_612131, JString, required = false,
                                 default = nil)
  if valid_612131 != nil:
    section.add "X-Amz-Security-Token", valid_612131
  var valid_612132 = header.getOrDefault("X-Amz-Algorithm")
  valid_612132 = validateParameter(valid_612132, JString, required = false,
                                 default = nil)
  if valid_612132 != nil:
    section.add "X-Amz-Algorithm", valid_612132
  var valid_612133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612133 = validateParameter(valid_612133, JString, required = false,
                                 default = nil)
  if valid_612133 != nil:
    section.add "X-Amz-SignedHeaders", valid_612133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612134: Call_GetModifyLoadBalancerAttributes_612120;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_612134.validator(path, query, header, formData, body)
  let scheme = call_612134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612134.url(scheme.get, call_612134.host, call_612134.base,
                         call_612134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612134, url, valid)

proc call*(call_612135: Call_GetModifyLoadBalancerAttributes_612120;
          LoadBalancerArn: string; Attributes: JsonNode;
          Action: string = "ModifyLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getModifyLoadBalancerAttributes
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612136 = newJObject()
  add(query_612136, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Attributes != nil:
    query_612136.add "Attributes", Attributes
  add(query_612136, "Action", newJString(Action))
  add(query_612136, "Version", newJString(Version))
  result = call_612135.call(nil, query_612136, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_612120(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_612121, base: "/",
    url: url_GetModifyLoadBalancerAttributes_612122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyRule_612173 = ref object of OpenApiRestCall_610658
proc url_PostModifyRule_612175(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyRule_612174(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612176 = query.getOrDefault("Action")
  valid_612176 = validateParameter(valid_612176, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_612176 != nil:
    section.add "Action", valid_612176
  var valid_612177 = query.getOrDefault("Version")
  valid_612177 = validateParameter(valid_612177, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612177 != nil:
    section.add "Version", valid_612177
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612178 = header.getOrDefault("X-Amz-Signature")
  valid_612178 = validateParameter(valid_612178, JString, required = false,
                                 default = nil)
  if valid_612178 != nil:
    section.add "X-Amz-Signature", valid_612178
  var valid_612179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612179 = validateParameter(valid_612179, JString, required = false,
                                 default = nil)
  if valid_612179 != nil:
    section.add "X-Amz-Content-Sha256", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-Date")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-Date", valid_612180
  var valid_612181 = header.getOrDefault("X-Amz-Credential")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "X-Amz-Credential", valid_612181
  var valid_612182 = header.getOrDefault("X-Amz-Security-Token")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-Security-Token", valid_612182
  var valid_612183 = header.getOrDefault("X-Amz-Algorithm")
  valid_612183 = validateParameter(valid_612183, JString, required = false,
                                 default = nil)
  if valid_612183 != nil:
    section.add "X-Amz-Algorithm", valid_612183
  var valid_612184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612184 = validateParameter(valid_612184, JString, required = false,
                                 default = nil)
  if valid_612184 != nil:
    section.add "X-Amz-SignedHeaders", valid_612184
  result.add "header", section
  ## parameters in `formData` object:
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  var valid_612185 = formData.getOrDefault("Actions")
  valid_612185 = validateParameter(valid_612185, JArray, required = false,
                                 default = nil)
  if valid_612185 != nil:
    section.add "Actions", valid_612185
  var valid_612186 = formData.getOrDefault("Conditions")
  valid_612186 = validateParameter(valid_612186, JArray, required = false,
                                 default = nil)
  if valid_612186 != nil:
    section.add "Conditions", valid_612186
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_612187 = formData.getOrDefault("RuleArn")
  valid_612187 = validateParameter(valid_612187, JString, required = true,
                                 default = nil)
  if valid_612187 != nil:
    section.add "RuleArn", valid_612187
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612188: Call_PostModifyRule_612173; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_612188.validator(path, query, header, formData, body)
  let scheme = call_612188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612188.url(scheme.get, call_612188.host, call_612188.base,
                         call_612188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612188, url, valid)

proc call*(call_612189: Call_PostModifyRule_612173; RuleArn: string;
          Actions: JsonNode = nil; Conditions: JsonNode = nil;
          Action: string = "ModifyRule"; Version: string = "2015-12-01"): Recallable =
  ## postModifyRule
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612190 = newJObject()
  var formData_612191 = newJObject()
  if Actions != nil:
    formData_612191.add "Actions", Actions
  if Conditions != nil:
    formData_612191.add "Conditions", Conditions
  add(formData_612191, "RuleArn", newJString(RuleArn))
  add(query_612190, "Action", newJString(Action))
  add(query_612190, "Version", newJString(Version))
  result = call_612189.call(nil, query_612190, nil, formData_612191, nil)

var postModifyRule* = Call_PostModifyRule_612173(name: "postModifyRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_PostModifyRule_612174,
    base: "/", url: url_PostModifyRule_612175, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyRule_612155 = ref object of OpenApiRestCall_610658
proc url_GetModifyRule_612157(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyRule_612156(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `RuleArn` field"
  var valid_612158 = query.getOrDefault("RuleArn")
  valid_612158 = validateParameter(valid_612158, JString, required = true,
                                 default = nil)
  if valid_612158 != nil:
    section.add "RuleArn", valid_612158
  var valid_612159 = query.getOrDefault("Actions")
  valid_612159 = validateParameter(valid_612159, JArray, required = false,
                                 default = nil)
  if valid_612159 != nil:
    section.add "Actions", valid_612159
  var valid_612160 = query.getOrDefault("Action")
  valid_612160 = validateParameter(valid_612160, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_612160 != nil:
    section.add "Action", valid_612160
  var valid_612161 = query.getOrDefault("Version")
  valid_612161 = validateParameter(valid_612161, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612161 != nil:
    section.add "Version", valid_612161
  var valid_612162 = query.getOrDefault("Conditions")
  valid_612162 = validateParameter(valid_612162, JArray, required = false,
                                 default = nil)
  if valid_612162 != nil:
    section.add "Conditions", valid_612162
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612163 = header.getOrDefault("X-Amz-Signature")
  valid_612163 = validateParameter(valid_612163, JString, required = false,
                                 default = nil)
  if valid_612163 != nil:
    section.add "X-Amz-Signature", valid_612163
  var valid_612164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612164 = validateParameter(valid_612164, JString, required = false,
                                 default = nil)
  if valid_612164 != nil:
    section.add "X-Amz-Content-Sha256", valid_612164
  var valid_612165 = header.getOrDefault("X-Amz-Date")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "X-Amz-Date", valid_612165
  var valid_612166 = header.getOrDefault("X-Amz-Credential")
  valid_612166 = validateParameter(valid_612166, JString, required = false,
                                 default = nil)
  if valid_612166 != nil:
    section.add "X-Amz-Credential", valid_612166
  var valid_612167 = header.getOrDefault("X-Amz-Security-Token")
  valid_612167 = validateParameter(valid_612167, JString, required = false,
                                 default = nil)
  if valid_612167 != nil:
    section.add "X-Amz-Security-Token", valid_612167
  var valid_612168 = header.getOrDefault("X-Amz-Algorithm")
  valid_612168 = validateParameter(valid_612168, JString, required = false,
                                 default = nil)
  if valid_612168 != nil:
    section.add "X-Amz-Algorithm", valid_612168
  var valid_612169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612169 = validateParameter(valid_612169, JString, required = false,
                                 default = nil)
  if valid_612169 != nil:
    section.add "X-Amz-SignedHeaders", valid_612169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612170: Call_GetModifyRule_612155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_612170.validator(path, query, header, formData, body)
  let scheme = call_612170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612170.url(scheme.get, call_612170.host, call_612170.base,
                         call_612170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612170, url, valid)

proc call*(call_612171: Call_GetModifyRule_612155; RuleArn: string;
          Actions: JsonNode = nil; Action: string = "ModifyRule";
          Version: string = "2015-12-01"; Conditions: JsonNode = nil): Recallable =
  ## getModifyRule
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  var query_612172 = newJObject()
  add(query_612172, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    query_612172.add "Actions", Actions
  add(query_612172, "Action", newJString(Action))
  add(query_612172, "Version", newJString(Version))
  if Conditions != nil:
    query_612172.add "Conditions", Conditions
  result = call_612171.call(nil, query_612172, nil, nil, nil)

var getModifyRule* = Call_GetModifyRule_612155(name: "getModifyRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_GetModifyRule_612156,
    base: "/", url: url_GetModifyRule_612157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroup_612217 = ref object of OpenApiRestCall_610658
proc url_PostModifyTargetGroup_612219(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyTargetGroup_612218(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612220 = query.getOrDefault("Action")
  valid_612220 = validateParameter(valid_612220, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_612220 != nil:
    section.add "Action", valid_612220
  var valid_612221 = query.getOrDefault("Version")
  valid_612221 = validateParameter(valid_612221, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612221 != nil:
    section.add "Version", valid_612221
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612222 = header.getOrDefault("X-Amz-Signature")
  valid_612222 = validateParameter(valid_612222, JString, required = false,
                                 default = nil)
  if valid_612222 != nil:
    section.add "X-Amz-Signature", valid_612222
  var valid_612223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612223 = validateParameter(valid_612223, JString, required = false,
                                 default = nil)
  if valid_612223 != nil:
    section.add "X-Amz-Content-Sha256", valid_612223
  var valid_612224 = header.getOrDefault("X-Amz-Date")
  valid_612224 = validateParameter(valid_612224, JString, required = false,
                                 default = nil)
  if valid_612224 != nil:
    section.add "X-Amz-Date", valid_612224
  var valid_612225 = header.getOrDefault("X-Amz-Credential")
  valid_612225 = validateParameter(valid_612225, JString, required = false,
                                 default = nil)
  if valid_612225 != nil:
    section.add "X-Amz-Credential", valid_612225
  var valid_612226 = header.getOrDefault("X-Amz-Security-Token")
  valid_612226 = validateParameter(valid_612226, JString, required = false,
                                 default = nil)
  if valid_612226 != nil:
    section.add "X-Amz-Security-Token", valid_612226
  var valid_612227 = header.getOrDefault("X-Amz-Algorithm")
  valid_612227 = validateParameter(valid_612227, JString, required = false,
                                 default = nil)
  if valid_612227 != nil:
    section.add "X-Amz-Algorithm", valid_612227
  var valid_612228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612228 = validateParameter(valid_612228, JString, required = false,
                                 default = nil)
  if valid_612228 != nil:
    section.add "X-Amz-SignedHeaders", valid_612228
  result.add "header", section
  ## parameters in `formData` object:
  ##   HealthCheckProtocol: JString
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   HealthCheckPort: JString
  ##                  : The port the load balancer uses when performing health checks on targets.
  ##   HealthCheckEnabled: JBool
  ##                     : Indicates whether health checks are enabled.
  ##   HealthCheckPath: JString
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination for the health check request.
  ##   HealthCheckTimeoutSeconds: JInt
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   HealthyThresholdCount: JInt
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   HealthCheckIntervalSeconds: JInt
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   UnhealthyThresholdCount: JInt
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   Matcher.HttpCode: JString
  ##                   : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_612229 = formData.getOrDefault("HealthCheckProtocol")
  valid_612229 = validateParameter(valid_612229, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_612229 != nil:
    section.add "HealthCheckProtocol", valid_612229
  var valid_612230 = formData.getOrDefault("HealthCheckPort")
  valid_612230 = validateParameter(valid_612230, JString, required = false,
                                 default = nil)
  if valid_612230 != nil:
    section.add "HealthCheckPort", valid_612230
  var valid_612231 = formData.getOrDefault("HealthCheckEnabled")
  valid_612231 = validateParameter(valid_612231, JBool, required = false, default = nil)
  if valid_612231 != nil:
    section.add "HealthCheckEnabled", valid_612231
  var valid_612232 = formData.getOrDefault("HealthCheckPath")
  valid_612232 = validateParameter(valid_612232, JString, required = false,
                                 default = nil)
  if valid_612232 != nil:
    section.add "HealthCheckPath", valid_612232
  var valid_612233 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_612233 = validateParameter(valid_612233, JInt, required = false, default = nil)
  if valid_612233 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_612233
  var valid_612234 = formData.getOrDefault("HealthyThresholdCount")
  valid_612234 = validateParameter(valid_612234, JInt, required = false, default = nil)
  if valid_612234 != nil:
    section.add "HealthyThresholdCount", valid_612234
  var valid_612235 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_612235 = validateParameter(valid_612235, JInt, required = false, default = nil)
  if valid_612235 != nil:
    section.add "HealthCheckIntervalSeconds", valid_612235
  var valid_612236 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_612236 = validateParameter(valid_612236, JInt, required = false, default = nil)
  if valid_612236 != nil:
    section.add "UnhealthyThresholdCount", valid_612236
  var valid_612237 = formData.getOrDefault("Matcher.HttpCode")
  valid_612237 = validateParameter(valid_612237, JString, required = false,
                                 default = nil)
  if valid_612237 != nil:
    section.add "Matcher.HttpCode", valid_612237
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_612238 = formData.getOrDefault("TargetGroupArn")
  valid_612238 = validateParameter(valid_612238, JString, required = true,
                                 default = nil)
  if valid_612238 != nil:
    section.add "TargetGroupArn", valid_612238
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612239: Call_PostModifyTargetGroup_612217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_612239.validator(path, query, header, formData, body)
  let scheme = call_612239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612239.url(scheme.get, call_612239.host, call_612239.base,
                         call_612239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612239, url, valid)

proc call*(call_612240: Call_PostModifyTargetGroup_612217; TargetGroupArn: string;
          HealthCheckProtocol: string = "HTTP"; HealthCheckPort: string = "";
          HealthCheckEnabled: bool = false; HealthCheckPath: string = "";
          HealthCheckTimeoutSeconds: int = 0; HealthyThresholdCount: int = 0;
          HealthCheckIntervalSeconds: int = 0; UnhealthyThresholdCount: int = 0;
          MatcherHttpCode: string = ""; Action: string = "ModifyTargetGroup";
          Version: string = "2015-12-01"): Recallable =
  ## postModifyTargetGroup
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ##   HealthCheckProtocol: string
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   HealthCheckPort: string
  ##                  : The port the load balancer uses when performing health checks on targets.
  ##   HealthCheckEnabled: bool
  ##                     : Indicates whether health checks are enabled.
  ##   HealthCheckPath: string
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination for the health check request.
  ##   HealthCheckTimeoutSeconds: int
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   HealthyThresholdCount: int
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   HealthCheckIntervalSeconds: int
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   UnhealthyThresholdCount: int
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   MatcherHttpCode: string
  ##                  : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_612241 = newJObject()
  var formData_612242 = newJObject()
  add(formData_612242, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_612242, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_612242, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_612242, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_612242, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_612242, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_612242, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_612242, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_612242, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_612241, "Action", newJString(Action))
  add(formData_612242, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_612241, "Version", newJString(Version))
  result = call_612240.call(nil, query_612241, nil, formData_612242, nil)

var postModifyTargetGroup* = Call_PostModifyTargetGroup_612217(
    name: "postModifyTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup",
    validator: validate_PostModifyTargetGroup_612218, base: "/",
    url: url_PostModifyTargetGroup_612219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroup_612192 = ref object of OpenApiRestCall_610658
proc url_GetModifyTargetGroup_612194(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyTargetGroup_612193(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   HealthCheckPort: JString
  ##                  : The port the load balancer uses when performing health checks on targets.
  ##   HealthCheckPath: JString
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination for the health check request.
  ##   HealthCheckProtocol: JString
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   Matcher.HttpCode: JString
  ##                   : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   HealthCheckIntervalSeconds: JInt
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   HealthCheckEnabled: JBool
  ##                     : Indicates whether health checks are enabled.
  ##   HealthyThresholdCount: JInt
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   UnhealthyThresholdCount: JInt
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   Action: JString (required)
  ##   HealthCheckTimeoutSeconds: JInt
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_612195 = query.getOrDefault("HealthCheckPort")
  valid_612195 = validateParameter(valid_612195, JString, required = false,
                                 default = nil)
  if valid_612195 != nil:
    section.add "HealthCheckPort", valid_612195
  var valid_612196 = query.getOrDefault("HealthCheckPath")
  valid_612196 = validateParameter(valid_612196, JString, required = false,
                                 default = nil)
  if valid_612196 != nil:
    section.add "HealthCheckPath", valid_612196
  var valid_612197 = query.getOrDefault("HealthCheckProtocol")
  valid_612197 = validateParameter(valid_612197, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_612197 != nil:
    section.add "HealthCheckProtocol", valid_612197
  var valid_612198 = query.getOrDefault("Matcher.HttpCode")
  valid_612198 = validateParameter(valid_612198, JString, required = false,
                                 default = nil)
  if valid_612198 != nil:
    section.add "Matcher.HttpCode", valid_612198
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_612199 = query.getOrDefault("TargetGroupArn")
  valid_612199 = validateParameter(valid_612199, JString, required = true,
                                 default = nil)
  if valid_612199 != nil:
    section.add "TargetGroupArn", valid_612199
  var valid_612200 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_612200 = validateParameter(valid_612200, JInt, required = false, default = nil)
  if valid_612200 != nil:
    section.add "HealthCheckIntervalSeconds", valid_612200
  var valid_612201 = query.getOrDefault("HealthCheckEnabled")
  valid_612201 = validateParameter(valid_612201, JBool, required = false, default = nil)
  if valid_612201 != nil:
    section.add "HealthCheckEnabled", valid_612201
  var valid_612202 = query.getOrDefault("HealthyThresholdCount")
  valid_612202 = validateParameter(valid_612202, JInt, required = false, default = nil)
  if valid_612202 != nil:
    section.add "HealthyThresholdCount", valid_612202
  var valid_612203 = query.getOrDefault("UnhealthyThresholdCount")
  valid_612203 = validateParameter(valid_612203, JInt, required = false, default = nil)
  if valid_612203 != nil:
    section.add "UnhealthyThresholdCount", valid_612203
  var valid_612204 = query.getOrDefault("Action")
  valid_612204 = validateParameter(valid_612204, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_612204 != nil:
    section.add "Action", valid_612204
  var valid_612205 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_612205 = validateParameter(valid_612205, JInt, required = false, default = nil)
  if valid_612205 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_612205
  var valid_612206 = query.getOrDefault("Version")
  valid_612206 = validateParameter(valid_612206, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612206 != nil:
    section.add "Version", valid_612206
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612207 = header.getOrDefault("X-Amz-Signature")
  valid_612207 = validateParameter(valid_612207, JString, required = false,
                                 default = nil)
  if valid_612207 != nil:
    section.add "X-Amz-Signature", valid_612207
  var valid_612208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612208 = validateParameter(valid_612208, JString, required = false,
                                 default = nil)
  if valid_612208 != nil:
    section.add "X-Amz-Content-Sha256", valid_612208
  var valid_612209 = header.getOrDefault("X-Amz-Date")
  valid_612209 = validateParameter(valid_612209, JString, required = false,
                                 default = nil)
  if valid_612209 != nil:
    section.add "X-Amz-Date", valid_612209
  var valid_612210 = header.getOrDefault("X-Amz-Credential")
  valid_612210 = validateParameter(valid_612210, JString, required = false,
                                 default = nil)
  if valid_612210 != nil:
    section.add "X-Amz-Credential", valid_612210
  var valid_612211 = header.getOrDefault("X-Amz-Security-Token")
  valid_612211 = validateParameter(valid_612211, JString, required = false,
                                 default = nil)
  if valid_612211 != nil:
    section.add "X-Amz-Security-Token", valid_612211
  var valid_612212 = header.getOrDefault("X-Amz-Algorithm")
  valid_612212 = validateParameter(valid_612212, JString, required = false,
                                 default = nil)
  if valid_612212 != nil:
    section.add "X-Amz-Algorithm", valid_612212
  var valid_612213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612213 = validateParameter(valid_612213, JString, required = false,
                                 default = nil)
  if valid_612213 != nil:
    section.add "X-Amz-SignedHeaders", valid_612213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612214: Call_GetModifyTargetGroup_612192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_612214.validator(path, query, header, formData, body)
  let scheme = call_612214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612214.url(scheme.get, call_612214.host, call_612214.base,
                         call_612214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612214, url, valid)

proc call*(call_612215: Call_GetModifyTargetGroup_612192; TargetGroupArn: string;
          HealthCheckPort: string = ""; HealthCheckPath: string = "";
          HealthCheckProtocol: string = "HTTP"; MatcherHttpCode: string = "";
          HealthCheckIntervalSeconds: int = 0; HealthCheckEnabled: bool = false;
          HealthyThresholdCount: int = 0; UnhealthyThresholdCount: int = 0;
          Action: string = "ModifyTargetGroup"; HealthCheckTimeoutSeconds: int = 0;
          Version: string = "2015-12-01"): Recallable =
  ## getModifyTargetGroup
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ##   HealthCheckPort: string
  ##                  : The port the load balancer uses when performing health checks on targets.
  ##   HealthCheckPath: string
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination for the health check request.
  ##   HealthCheckProtocol: string
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   MatcherHttpCode: string
  ##                  : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   HealthCheckIntervalSeconds: int
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   HealthCheckEnabled: bool
  ##                     : Indicates whether health checks are enabled.
  ##   HealthyThresholdCount: int
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   UnhealthyThresholdCount: int
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   Action: string (required)
  ##   HealthCheckTimeoutSeconds: int
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   Version: string (required)
  var query_612216 = newJObject()
  add(query_612216, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_612216, "HealthCheckPath", newJString(HealthCheckPath))
  add(query_612216, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_612216, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_612216, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_612216, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_612216, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_612216, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_612216, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_612216, "Action", newJString(Action))
  add(query_612216, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_612216, "Version", newJString(Version))
  result = call_612215.call(nil, query_612216, nil, nil, nil)

var getModifyTargetGroup* = Call_GetModifyTargetGroup_612192(
    name: "getModifyTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup", validator: validate_GetModifyTargetGroup_612193,
    base: "/", url: url_GetModifyTargetGroup_612194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroupAttributes_612260 = ref object of OpenApiRestCall_610658
proc url_PostModifyTargetGroupAttributes_612262(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyTargetGroupAttributes_612261(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the specified attributes of the specified target group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612263 = query.getOrDefault("Action")
  valid_612263 = validateParameter(valid_612263, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_612263 != nil:
    section.add "Action", valid_612263
  var valid_612264 = query.getOrDefault("Version")
  valid_612264 = validateParameter(valid_612264, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612264 != nil:
    section.add "Version", valid_612264
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612265 = header.getOrDefault("X-Amz-Signature")
  valid_612265 = validateParameter(valid_612265, JString, required = false,
                                 default = nil)
  if valid_612265 != nil:
    section.add "X-Amz-Signature", valid_612265
  var valid_612266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612266 = validateParameter(valid_612266, JString, required = false,
                                 default = nil)
  if valid_612266 != nil:
    section.add "X-Amz-Content-Sha256", valid_612266
  var valid_612267 = header.getOrDefault("X-Amz-Date")
  valid_612267 = validateParameter(valid_612267, JString, required = false,
                                 default = nil)
  if valid_612267 != nil:
    section.add "X-Amz-Date", valid_612267
  var valid_612268 = header.getOrDefault("X-Amz-Credential")
  valid_612268 = validateParameter(valid_612268, JString, required = false,
                                 default = nil)
  if valid_612268 != nil:
    section.add "X-Amz-Credential", valid_612268
  var valid_612269 = header.getOrDefault("X-Amz-Security-Token")
  valid_612269 = validateParameter(valid_612269, JString, required = false,
                                 default = nil)
  if valid_612269 != nil:
    section.add "X-Amz-Security-Token", valid_612269
  var valid_612270 = header.getOrDefault("X-Amz-Algorithm")
  valid_612270 = validateParameter(valid_612270, JString, required = false,
                                 default = nil)
  if valid_612270 != nil:
    section.add "X-Amz-Algorithm", valid_612270
  var valid_612271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612271 = validateParameter(valid_612271, JString, required = false,
                                 default = nil)
  if valid_612271 != nil:
    section.add "X-Amz-SignedHeaders", valid_612271
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_612272 = formData.getOrDefault("Attributes")
  valid_612272 = validateParameter(valid_612272, JArray, required = true, default = nil)
  if valid_612272 != nil:
    section.add "Attributes", valid_612272
  var valid_612273 = formData.getOrDefault("TargetGroupArn")
  valid_612273 = validateParameter(valid_612273, JString, required = true,
                                 default = nil)
  if valid_612273 != nil:
    section.add "TargetGroupArn", valid_612273
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612274: Call_PostModifyTargetGroupAttributes_612260;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_612274.validator(path, query, header, formData, body)
  let scheme = call_612274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612274.url(scheme.get, call_612274.host, call_612274.base,
                         call_612274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612274, url, valid)

proc call*(call_612275: Call_PostModifyTargetGroupAttributes_612260;
          Attributes: JsonNode; TargetGroupArn: string;
          Action: string = "ModifyTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postModifyTargetGroupAttributes
  ## Modifies the specified attributes of the specified target group.
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_612276 = newJObject()
  var formData_612277 = newJObject()
  if Attributes != nil:
    formData_612277.add "Attributes", Attributes
  add(query_612276, "Action", newJString(Action))
  add(formData_612277, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_612276, "Version", newJString(Version))
  result = call_612275.call(nil, query_612276, nil, formData_612277, nil)

var postModifyTargetGroupAttributes* = Call_PostModifyTargetGroupAttributes_612260(
    name: "postModifyTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_PostModifyTargetGroupAttributes_612261, base: "/",
    url: url_PostModifyTargetGroupAttributes_612262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroupAttributes_612243 = ref object of OpenApiRestCall_610658
proc url_GetModifyTargetGroupAttributes_612245(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyTargetGroupAttributes_612244(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the specified attributes of the specified target group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_612246 = query.getOrDefault("TargetGroupArn")
  valid_612246 = validateParameter(valid_612246, JString, required = true,
                                 default = nil)
  if valid_612246 != nil:
    section.add "TargetGroupArn", valid_612246
  var valid_612247 = query.getOrDefault("Attributes")
  valid_612247 = validateParameter(valid_612247, JArray, required = true, default = nil)
  if valid_612247 != nil:
    section.add "Attributes", valid_612247
  var valid_612248 = query.getOrDefault("Action")
  valid_612248 = validateParameter(valid_612248, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_612248 != nil:
    section.add "Action", valid_612248
  var valid_612249 = query.getOrDefault("Version")
  valid_612249 = validateParameter(valid_612249, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612249 != nil:
    section.add "Version", valid_612249
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612250 = header.getOrDefault("X-Amz-Signature")
  valid_612250 = validateParameter(valid_612250, JString, required = false,
                                 default = nil)
  if valid_612250 != nil:
    section.add "X-Amz-Signature", valid_612250
  var valid_612251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612251 = validateParameter(valid_612251, JString, required = false,
                                 default = nil)
  if valid_612251 != nil:
    section.add "X-Amz-Content-Sha256", valid_612251
  var valid_612252 = header.getOrDefault("X-Amz-Date")
  valid_612252 = validateParameter(valid_612252, JString, required = false,
                                 default = nil)
  if valid_612252 != nil:
    section.add "X-Amz-Date", valid_612252
  var valid_612253 = header.getOrDefault("X-Amz-Credential")
  valid_612253 = validateParameter(valid_612253, JString, required = false,
                                 default = nil)
  if valid_612253 != nil:
    section.add "X-Amz-Credential", valid_612253
  var valid_612254 = header.getOrDefault("X-Amz-Security-Token")
  valid_612254 = validateParameter(valid_612254, JString, required = false,
                                 default = nil)
  if valid_612254 != nil:
    section.add "X-Amz-Security-Token", valid_612254
  var valid_612255 = header.getOrDefault("X-Amz-Algorithm")
  valid_612255 = validateParameter(valid_612255, JString, required = false,
                                 default = nil)
  if valid_612255 != nil:
    section.add "X-Amz-Algorithm", valid_612255
  var valid_612256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612256 = validateParameter(valid_612256, JString, required = false,
                                 default = nil)
  if valid_612256 != nil:
    section.add "X-Amz-SignedHeaders", valid_612256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612257: Call_GetModifyTargetGroupAttributes_612243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_612257.validator(path, query, header, formData, body)
  let scheme = call_612257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612257.url(scheme.get, call_612257.host, call_612257.base,
                         call_612257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612257, url, valid)

proc call*(call_612258: Call_GetModifyTargetGroupAttributes_612243;
          TargetGroupArn: string; Attributes: JsonNode;
          Action: string = "ModifyTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getModifyTargetGroupAttributes
  ## Modifies the specified attributes of the specified target group.
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612259 = newJObject()
  add(query_612259, "TargetGroupArn", newJString(TargetGroupArn))
  if Attributes != nil:
    query_612259.add "Attributes", Attributes
  add(query_612259, "Action", newJString(Action))
  add(query_612259, "Version", newJString(Version))
  result = call_612258.call(nil, query_612259, nil, nil, nil)

var getModifyTargetGroupAttributes* = Call_GetModifyTargetGroupAttributes_612243(
    name: "getModifyTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_GetModifyTargetGroupAttributes_612244, base: "/",
    url: url_GetModifyTargetGroupAttributes_612245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterTargets_612295 = ref object of OpenApiRestCall_610658
proc url_PostRegisterTargets_612297(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRegisterTargets_612296(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612298 = query.getOrDefault("Action")
  valid_612298 = validateParameter(valid_612298, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_612298 != nil:
    section.add "Action", valid_612298
  var valid_612299 = query.getOrDefault("Version")
  valid_612299 = validateParameter(valid_612299, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612299 != nil:
    section.add "Version", valid_612299
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612300 = header.getOrDefault("X-Amz-Signature")
  valid_612300 = validateParameter(valid_612300, JString, required = false,
                                 default = nil)
  if valid_612300 != nil:
    section.add "X-Amz-Signature", valid_612300
  var valid_612301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612301 = validateParameter(valid_612301, JString, required = false,
                                 default = nil)
  if valid_612301 != nil:
    section.add "X-Amz-Content-Sha256", valid_612301
  var valid_612302 = header.getOrDefault("X-Amz-Date")
  valid_612302 = validateParameter(valid_612302, JString, required = false,
                                 default = nil)
  if valid_612302 != nil:
    section.add "X-Amz-Date", valid_612302
  var valid_612303 = header.getOrDefault("X-Amz-Credential")
  valid_612303 = validateParameter(valid_612303, JString, required = false,
                                 default = nil)
  if valid_612303 != nil:
    section.add "X-Amz-Credential", valid_612303
  var valid_612304 = header.getOrDefault("X-Amz-Security-Token")
  valid_612304 = validateParameter(valid_612304, JString, required = false,
                                 default = nil)
  if valid_612304 != nil:
    section.add "X-Amz-Security-Token", valid_612304
  var valid_612305 = header.getOrDefault("X-Amz-Algorithm")
  valid_612305 = validateParameter(valid_612305, JString, required = false,
                                 default = nil)
  if valid_612305 != nil:
    section.add "X-Amz-Algorithm", valid_612305
  var valid_612306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612306 = validateParameter(valid_612306, JString, required = false,
                                 default = nil)
  if valid_612306 != nil:
    section.add "X-Amz-SignedHeaders", valid_612306
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_612307 = formData.getOrDefault("Targets")
  valid_612307 = validateParameter(valid_612307, JArray, required = true, default = nil)
  if valid_612307 != nil:
    section.add "Targets", valid_612307
  var valid_612308 = formData.getOrDefault("TargetGroupArn")
  valid_612308 = validateParameter(valid_612308, JString, required = true,
                                 default = nil)
  if valid_612308 != nil:
    section.add "TargetGroupArn", valid_612308
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612309: Call_PostRegisterTargets_612295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_612309.validator(path, query, header, formData, body)
  let scheme = call_612309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612309.url(scheme.get, call_612309.host, call_612309.base,
                         call_612309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612309, url, valid)

proc call*(call_612310: Call_PostRegisterTargets_612295; Targets: JsonNode;
          TargetGroupArn: string; Action: string = "RegisterTargets";
          Version: string = "2015-12-01"): Recallable =
  ## postRegisterTargets
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_612311 = newJObject()
  var formData_612312 = newJObject()
  if Targets != nil:
    formData_612312.add "Targets", Targets
  add(query_612311, "Action", newJString(Action))
  add(formData_612312, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_612311, "Version", newJString(Version))
  result = call_612310.call(nil, query_612311, nil, formData_612312, nil)

var postRegisterTargets* = Call_PostRegisterTargets_612295(
    name: "postRegisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_PostRegisterTargets_612296, base: "/",
    url: url_PostRegisterTargets_612297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterTargets_612278 = ref object of OpenApiRestCall_610658
proc url_GetRegisterTargets_612280(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRegisterTargets_612279(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Targets` field"
  var valid_612281 = query.getOrDefault("Targets")
  valid_612281 = validateParameter(valid_612281, JArray, required = true, default = nil)
  if valid_612281 != nil:
    section.add "Targets", valid_612281
  var valid_612282 = query.getOrDefault("TargetGroupArn")
  valid_612282 = validateParameter(valid_612282, JString, required = true,
                                 default = nil)
  if valid_612282 != nil:
    section.add "TargetGroupArn", valid_612282
  var valid_612283 = query.getOrDefault("Action")
  valid_612283 = validateParameter(valid_612283, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_612283 != nil:
    section.add "Action", valid_612283
  var valid_612284 = query.getOrDefault("Version")
  valid_612284 = validateParameter(valid_612284, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612284 != nil:
    section.add "Version", valid_612284
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612285 = header.getOrDefault("X-Amz-Signature")
  valid_612285 = validateParameter(valid_612285, JString, required = false,
                                 default = nil)
  if valid_612285 != nil:
    section.add "X-Amz-Signature", valid_612285
  var valid_612286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612286 = validateParameter(valid_612286, JString, required = false,
                                 default = nil)
  if valid_612286 != nil:
    section.add "X-Amz-Content-Sha256", valid_612286
  var valid_612287 = header.getOrDefault("X-Amz-Date")
  valid_612287 = validateParameter(valid_612287, JString, required = false,
                                 default = nil)
  if valid_612287 != nil:
    section.add "X-Amz-Date", valid_612287
  var valid_612288 = header.getOrDefault("X-Amz-Credential")
  valid_612288 = validateParameter(valid_612288, JString, required = false,
                                 default = nil)
  if valid_612288 != nil:
    section.add "X-Amz-Credential", valid_612288
  var valid_612289 = header.getOrDefault("X-Amz-Security-Token")
  valid_612289 = validateParameter(valid_612289, JString, required = false,
                                 default = nil)
  if valid_612289 != nil:
    section.add "X-Amz-Security-Token", valid_612289
  var valid_612290 = header.getOrDefault("X-Amz-Algorithm")
  valid_612290 = validateParameter(valid_612290, JString, required = false,
                                 default = nil)
  if valid_612290 != nil:
    section.add "X-Amz-Algorithm", valid_612290
  var valid_612291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612291 = validateParameter(valid_612291, JString, required = false,
                                 default = nil)
  if valid_612291 != nil:
    section.add "X-Amz-SignedHeaders", valid_612291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612292: Call_GetRegisterTargets_612278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_612292.validator(path, query, header, formData, body)
  let scheme = call_612292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612292.url(scheme.get, call_612292.host, call_612292.base,
                         call_612292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612292, url, valid)

proc call*(call_612293: Call_GetRegisterTargets_612278; Targets: JsonNode;
          TargetGroupArn: string; Action: string = "RegisterTargets";
          Version: string = "2015-12-01"): Recallable =
  ## getRegisterTargets
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612294 = newJObject()
  if Targets != nil:
    query_612294.add "Targets", Targets
  add(query_612294, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_612294, "Action", newJString(Action))
  add(query_612294, "Version", newJString(Version))
  result = call_612293.call(nil, query_612294, nil, nil, nil)

var getRegisterTargets* = Call_GetRegisterTargets_612278(
    name: "getRegisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_GetRegisterTargets_612279, base: "/",
    url: url_GetRegisterTargets_612280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveListenerCertificates_612330 = ref object of OpenApiRestCall_610658
proc url_PostRemoveListenerCertificates_612332(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveListenerCertificates_612331(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612333 = query.getOrDefault("Action")
  valid_612333 = validateParameter(valid_612333, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_612333 != nil:
    section.add "Action", valid_612333
  var valid_612334 = query.getOrDefault("Version")
  valid_612334 = validateParameter(valid_612334, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612334 != nil:
    section.add "Version", valid_612334
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612335 = header.getOrDefault("X-Amz-Signature")
  valid_612335 = validateParameter(valid_612335, JString, required = false,
                                 default = nil)
  if valid_612335 != nil:
    section.add "X-Amz-Signature", valid_612335
  var valid_612336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612336 = validateParameter(valid_612336, JString, required = false,
                                 default = nil)
  if valid_612336 != nil:
    section.add "X-Amz-Content-Sha256", valid_612336
  var valid_612337 = header.getOrDefault("X-Amz-Date")
  valid_612337 = validateParameter(valid_612337, JString, required = false,
                                 default = nil)
  if valid_612337 != nil:
    section.add "X-Amz-Date", valid_612337
  var valid_612338 = header.getOrDefault("X-Amz-Credential")
  valid_612338 = validateParameter(valid_612338, JString, required = false,
                                 default = nil)
  if valid_612338 != nil:
    section.add "X-Amz-Credential", valid_612338
  var valid_612339 = header.getOrDefault("X-Amz-Security-Token")
  valid_612339 = validateParameter(valid_612339, JString, required = false,
                                 default = nil)
  if valid_612339 != nil:
    section.add "X-Amz-Security-Token", valid_612339
  var valid_612340 = header.getOrDefault("X-Amz-Algorithm")
  valid_612340 = validateParameter(valid_612340, JString, required = false,
                                 default = nil)
  if valid_612340 != nil:
    section.add "X-Amz-Algorithm", valid_612340
  var valid_612341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612341 = validateParameter(valid_612341, JString, required = false,
                                 default = nil)
  if valid_612341 != nil:
    section.add "X-Amz-SignedHeaders", valid_612341
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_612342 = formData.getOrDefault("Certificates")
  valid_612342 = validateParameter(valid_612342, JArray, required = true, default = nil)
  if valid_612342 != nil:
    section.add "Certificates", valid_612342
  var valid_612343 = formData.getOrDefault("ListenerArn")
  valid_612343 = validateParameter(valid_612343, JString, required = true,
                                 default = nil)
  if valid_612343 != nil:
    section.add "ListenerArn", valid_612343
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612344: Call_PostRemoveListenerCertificates_612330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_612344.validator(path, query, header, formData, body)
  let scheme = call_612344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612344.url(scheme.get, call_612344.host, call_612344.base,
                         call_612344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612344, url, valid)

proc call*(call_612345: Call_PostRemoveListenerCertificates_612330;
          Certificates: JsonNode; ListenerArn: string;
          Action: string = "RemoveListenerCertificates";
          Version: string = "2015-12-01"): Recallable =
  ## postRemoveListenerCertificates
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612346 = newJObject()
  var formData_612347 = newJObject()
  if Certificates != nil:
    formData_612347.add "Certificates", Certificates
  add(formData_612347, "ListenerArn", newJString(ListenerArn))
  add(query_612346, "Action", newJString(Action))
  add(query_612346, "Version", newJString(Version))
  result = call_612345.call(nil, query_612346, nil, formData_612347, nil)

var postRemoveListenerCertificates* = Call_PostRemoveListenerCertificates_612330(
    name: "postRemoveListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_PostRemoveListenerCertificates_612331, base: "/",
    url: url_PostRemoveListenerCertificates_612332,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveListenerCertificates_612313 = ref object of OpenApiRestCall_610658
proc url_GetRemoveListenerCertificates_612315(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveListenerCertificates_612314(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ListenerArn` field"
  var valid_612316 = query.getOrDefault("ListenerArn")
  valid_612316 = validateParameter(valid_612316, JString, required = true,
                                 default = nil)
  if valid_612316 != nil:
    section.add "ListenerArn", valid_612316
  var valid_612317 = query.getOrDefault("Certificates")
  valid_612317 = validateParameter(valid_612317, JArray, required = true, default = nil)
  if valid_612317 != nil:
    section.add "Certificates", valid_612317
  var valid_612318 = query.getOrDefault("Action")
  valid_612318 = validateParameter(valid_612318, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_612318 != nil:
    section.add "Action", valid_612318
  var valid_612319 = query.getOrDefault("Version")
  valid_612319 = validateParameter(valid_612319, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612319 != nil:
    section.add "Version", valid_612319
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612320 = header.getOrDefault("X-Amz-Signature")
  valid_612320 = validateParameter(valid_612320, JString, required = false,
                                 default = nil)
  if valid_612320 != nil:
    section.add "X-Amz-Signature", valid_612320
  var valid_612321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612321 = validateParameter(valid_612321, JString, required = false,
                                 default = nil)
  if valid_612321 != nil:
    section.add "X-Amz-Content-Sha256", valid_612321
  var valid_612322 = header.getOrDefault("X-Amz-Date")
  valid_612322 = validateParameter(valid_612322, JString, required = false,
                                 default = nil)
  if valid_612322 != nil:
    section.add "X-Amz-Date", valid_612322
  var valid_612323 = header.getOrDefault("X-Amz-Credential")
  valid_612323 = validateParameter(valid_612323, JString, required = false,
                                 default = nil)
  if valid_612323 != nil:
    section.add "X-Amz-Credential", valid_612323
  var valid_612324 = header.getOrDefault("X-Amz-Security-Token")
  valid_612324 = validateParameter(valid_612324, JString, required = false,
                                 default = nil)
  if valid_612324 != nil:
    section.add "X-Amz-Security-Token", valid_612324
  var valid_612325 = header.getOrDefault("X-Amz-Algorithm")
  valid_612325 = validateParameter(valid_612325, JString, required = false,
                                 default = nil)
  if valid_612325 != nil:
    section.add "X-Amz-Algorithm", valid_612325
  var valid_612326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612326 = validateParameter(valid_612326, JString, required = false,
                                 default = nil)
  if valid_612326 != nil:
    section.add "X-Amz-SignedHeaders", valid_612326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612327: Call_GetRemoveListenerCertificates_612313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_612327.validator(path, query, header, formData, body)
  let scheme = call_612327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612327.url(scheme.get, call_612327.host, call_612327.base,
                         call_612327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612327, url, valid)

proc call*(call_612328: Call_GetRemoveListenerCertificates_612313;
          ListenerArn: string; Certificates: JsonNode;
          Action: string = "RemoveListenerCertificates";
          Version: string = "2015-12-01"): Recallable =
  ## getRemoveListenerCertificates
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612329 = newJObject()
  add(query_612329, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_612329.add "Certificates", Certificates
  add(query_612329, "Action", newJString(Action))
  add(query_612329, "Version", newJString(Version))
  result = call_612328.call(nil, query_612329, nil, nil, nil)

var getRemoveListenerCertificates* = Call_GetRemoveListenerCertificates_612313(
    name: "getRemoveListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_GetRemoveListenerCertificates_612314, base: "/",
    url: url_GetRemoveListenerCertificates_612315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_612365 = ref object of OpenApiRestCall_610658
proc url_PostRemoveTags_612367(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTags_612366(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612368 = query.getOrDefault("Action")
  valid_612368 = validateParameter(valid_612368, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_612368 != nil:
    section.add "Action", valid_612368
  var valid_612369 = query.getOrDefault("Version")
  valid_612369 = validateParameter(valid_612369, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612369 != nil:
    section.add "Version", valid_612369
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612370 = header.getOrDefault("X-Amz-Signature")
  valid_612370 = validateParameter(valid_612370, JString, required = false,
                                 default = nil)
  if valid_612370 != nil:
    section.add "X-Amz-Signature", valid_612370
  var valid_612371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612371 = validateParameter(valid_612371, JString, required = false,
                                 default = nil)
  if valid_612371 != nil:
    section.add "X-Amz-Content-Sha256", valid_612371
  var valid_612372 = header.getOrDefault("X-Amz-Date")
  valid_612372 = validateParameter(valid_612372, JString, required = false,
                                 default = nil)
  if valid_612372 != nil:
    section.add "X-Amz-Date", valid_612372
  var valid_612373 = header.getOrDefault("X-Amz-Credential")
  valid_612373 = validateParameter(valid_612373, JString, required = false,
                                 default = nil)
  if valid_612373 != nil:
    section.add "X-Amz-Credential", valid_612373
  var valid_612374 = header.getOrDefault("X-Amz-Security-Token")
  valid_612374 = validateParameter(valid_612374, JString, required = false,
                                 default = nil)
  if valid_612374 != nil:
    section.add "X-Amz-Security-Token", valid_612374
  var valid_612375 = header.getOrDefault("X-Amz-Algorithm")
  valid_612375 = validateParameter(valid_612375, JString, required = false,
                                 default = nil)
  if valid_612375 != nil:
    section.add "X-Amz-Algorithm", valid_612375
  var valid_612376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612376 = validateParameter(valid_612376, JString, required = false,
                                 default = nil)
  if valid_612376 != nil:
    section.add "X-Amz-SignedHeaders", valid_612376
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_612377 = formData.getOrDefault("TagKeys")
  valid_612377 = validateParameter(valid_612377, JArray, required = true, default = nil)
  if valid_612377 != nil:
    section.add "TagKeys", valid_612377
  var valid_612378 = formData.getOrDefault("ResourceArns")
  valid_612378 = validateParameter(valid_612378, JArray, required = true, default = nil)
  if valid_612378 != nil:
    section.add "ResourceArns", valid_612378
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612379: Call_PostRemoveTags_612365; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_612379.validator(path, query, header, formData, body)
  let scheme = call_612379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612379.url(scheme.get, call_612379.host, call_612379.base,
                         call_612379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612379, url, valid)

proc call*(call_612380: Call_PostRemoveTags_612365; TagKeys: JsonNode;
          ResourceArns: JsonNode; Action: string = "RemoveTags";
          Version: string = "2015-12-01"): Recallable =
  ## postRemoveTags
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612381 = newJObject()
  var formData_612382 = newJObject()
  if TagKeys != nil:
    formData_612382.add "TagKeys", TagKeys
  if ResourceArns != nil:
    formData_612382.add "ResourceArns", ResourceArns
  add(query_612381, "Action", newJString(Action))
  add(query_612381, "Version", newJString(Version))
  result = call_612380.call(nil, query_612381, nil, formData_612382, nil)

var postRemoveTags* = Call_PostRemoveTags_612365(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_612366,
    base: "/", url: url_PostRemoveTags_612367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_612348 = ref object of OpenApiRestCall_610658
proc url_GetRemoveTags_612350(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTags_612349(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArns` field"
  var valid_612351 = query.getOrDefault("ResourceArns")
  valid_612351 = validateParameter(valid_612351, JArray, required = true, default = nil)
  if valid_612351 != nil:
    section.add "ResourceArns", valid_612351
  var valid_612352 = query.getOrDefault("TagKeys")
  valid_612352 = validateParameter(valid_612352, JArray, required = true, default = nil)
  if valid_612352 != nil:
    section.add "TagKeys", valid_612352
  var valid_612353 = query.getOrDefault("Action")
  valid_612353 = validateParameter(valid_612353, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_612353 != nil:
    section.add "Action", valid_612353
  var valid_612354 = query.getOrDefault("Version")
  valid_612354 = validateParameter(valid_612354, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612354 != nil:
    section.add "Version", valid_612354
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612355 = header.getOrDefault("X-Amz-Signature")
  valid_612355 = validateParameter(valid_612355, JString, required = false,
                                 default = nil)
  if valid_612355 != nil:
    section.add "X-Amz-Signature", valid_612355
  var valid_612356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612356 = validateParameter(valid_612356, JString, required = false,
                                 default = nil)
  if valid_612356 != nil:
    section.add "X-Amz-Content-Sha256", valid_612356
  var valid_612357 = header.getOrDefault("X-Amz-Date")
  valid_612357 = validateParameter(valid_612357, JString, required = false,
                                 default = nil)
  if valid_612357 != nil:
    section.add "X-Amz-Date", valid_612357
  var valid_612358 = header.getOrDefault("X-Amz-Credential")
  valid_612358 = validateParameter(valid_612358, JString, required = false,
                                 default = nil)
  if valid_612358 != nil:
    section.add "X-Amz-Credential", valid_612358
  var valid_612359 = header.getOrDefault("X-Amz-Security-Token")
  valid_612359 = validateParameter(valid_612359, JString, required = false,
                                 default = nil)
  if valid_612359 != nil:
    section.add "X-Amz-Security-Token", valid_612359
  var valid_612360 = header.getOrDefault("X-Amz-Algorithm")
  valid_612360 = validateParameter(valid_612360, JString, required = false,
                                 default = nil)
  if valid_612360 != nil:
    section.add "X-Amz-Algorithm", valid_612360
  var valid_612361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612361 = validateParameter(valid_612361, JString, required = false,
                                 default = nil)
  if valid_612361 != nil:
    section.add "X-Amz-SignedHeaders", valid_612361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612362: Call_GetRemoveTags_612348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_612362.validator(path, query, header, formData, body)
  let scheme = call_612362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612362.url(scheme.get, call_612362.host, call_612362.base,
                         call_612362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612362, url, valid)

proc call*(call_612363: Call_GetRemoveTags_612348; ResourceArns: JsonNode;
          TagKeys: JsonNode; Action: string = "RemoveTags";
          Version: string = "2015-12-01"): Recallable =
  ## getRemoveTags
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612364 = newJObject()
  if ResourceArns != nil:
    query_612364.add "ResourceArns", ResourceArns
  if TagKeys != nil:
    query_612364.add "TagKeys", TagKeys
  add(query_612364, "Action", newJString(Action))
  add(query_612364, "Version", newJString(Version))
  result = call_612363.call(nil, query_612364, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_612348(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_612349,
    base: "/", url: url_GetRemoveTags_612350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetIpAddressType_612400 = ref object of OpenApiRestCall_610658
proc url_PostSetIpAddressType_612402(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetIpAddressType_612401(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612403 = query.getOrDefault("Action")
  valid_612403 = validateParameter(valid_612403, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_612403 != nil:
    section.add "Action", valid_612403
  var valid_612404 = query.getOrDefault("Version")
  valid_612404 = validateParameter(valid_612404, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612404 != nil:
    section.add "Version", valid_612404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612405 = header.getOrDefault("X-Amz-Signature")
  valid_612405 = validateParameter(valid_612405, JString, required = false,
                                 default = nil)
  if valid_612405 != nil:
    section.add "X-Amz-Signature", valid_612405
  var valid_612406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612406 = validateParameter(valid_612406, JString, required = false,
                                 default = nil)
  if valid_612406 != nil:
    section.add "X-Amz-Content-Sha256", valid_612406
  var valid_612407 = header.getOrDefault("X-Amz-Date")
  valid_612407 = validateParameter(valid_612407, JString, required = false,
                                 default = nil)
  if valid_612407 != nil:
    section.add "X-Amz-Date", valid_612407
  var valid_612408 = header.getOrDefault("X-Amz-Credential")
  valid_612408 = validateParameter(valid_612408, JString, required = false,
                                 default = nil)
  if valid_612408 != nil:
    section.add "X-Amz-Credential", valid_612408
  var valid_612409 = header.getOrDefault("X-Amz-Security-Token")
  valid_612409 = validateParameter(valid_612409, JString, required = false,
                                 default = nil)
  if valid_612409 != nil:
    section.add "X-Amz-Security-Token", valid_612409
  var valid_612410 = header.getOrDefault("X-Amz-Algorithm")
  valid_612410 = validateParameter(valid_612410, JString, required = false,
                                 default = nil)
  if valid_612410 != nil:
    section.add "X-Amz-Algorithm", valid_612410
  var valid_612411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612411 = validateParameter(valid_612411, JString, required = false,
                                 default = nil)
  if valid_612411 != nil:
    section.add "X-Amz-SignedHeaders", valid_612411
  result.add "header", section
  ## parameters in `formData` object:
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  var valid_612412 = formData.getOrDefault("IpAddressType")
  valid_612412 = validateParameter(valid_612412, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_612412 != nil:
    section.add "IpAddressType", valid_612412
  var valid_612413 = formData.getOrDefault("LoadBalancerArn")
  valid_612413 = validateParameter(valid_612413, JString, required = true,
                                 default = nil)
  if valid_612413 != nil:
    section.add "LoadBalancerArn", valid_612413
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612414: Call_PostSetIpAddressType_612400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_612414.validator(path, query, header, formData, body)
  let scheme = call_612414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612414.url(scheme.get, call_612414.host, call_612414.base,
                         call_612414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612414, url, valid)

proc call*(call_612415: Call_PostSetIpAddressType_612400; LoadBalancerArn: string;
          IpAddressType: string = "ipv4"; Action: string = "SetIpAddressType";
          Version: string = "2015-12-01"): Recallable =
  ## postSetIpAddressType
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ##   IpAddressType: string (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_612416 = newJObject()
  var formData_612417 = newJObject()
  add(formData_612417, "IpAddressType", newJString(IpAddressType))
  add(query_612416, "Action", newJString(Action))
  add(query_612416, "Version", newJString(Version))
  add(formData_612417, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_612415.call(nil, query_612416, nil, formData_612417, nil)

var postSetIpAddressType* = Call_PostSetIpAddressType_612400(
    name: "postSetIpAddressType", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_PostSetIpAddressType_612401,
    base: "/", url: url_PostSetIpAddressType_612402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetIpAddressType_612383 = ref object of OpenApiRestCall_610658
proc url_GetSetIpAddressType_612385(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetIpAddressType_612384(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612386 = query.getOrDefault("IpAddressType")
  valid_612386 = validateParameter(valid_612386, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_612386 != nil:
    section.add "IpAddressType", valid_612386
  var valid_612387 = query.getOrDefault("LoadBalancerArn")
  valid_612387 = validateParameter(valid_612387, JString, required = true,
                                 default = nil)
  if valid_612387 != nil:
    section.add "LoadBalancerArn", valid_612387
  var valid_612388 = query.getOrDefault("Action")
  valid_612388 = validateParameter(valid_612388, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_612388 != nil:
    section.add "Action", valid_612388
  var valid_612389 = query.getOrDefault("Version")
  valid_612389 = validateParameter(valid_612389, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612389 != nil:
    section.add "Version", valid_612389
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612390 = header.getOrDefault("X-Amz-Signature")
  valid_612390 = validateParameter(valid_612390, JString, required = false,
                                 default = nil)
  if valid_612390 != nil:
    section.add "X-Amz-Signature", valid_612390
  var valid_612391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612391 = validateParameter(valid_612391, JString, required = false,
                                 default = nil)
  if valid_612391 != nil:
    section.add "X-Amz-Content-Sha256", valid_612391
  var valid_612392 = header.getOrDefault("X-Amz-Date")
  valid_612392 = validateParameter(valid_612392, JString, required = false,
                                 default = nil)
  if valid_612392 != nil:
    section.add "X-Amz-Date", valid_612392
  var valid_612393 = header.getOrDefault("X-Amz-Credential")
  valid_612393 = validateParameter(valid_612393, JString, required = false,
                                 default = nil)
  if valid_612393 != nil:
    section.add "X-Amz-Credential", valid_612393
  var valid_612394 = header.getOrDefault("X-Amz-Security-Token")
  valid_612394 = validateParameter(valid_612394, JString, required = false,
                                 default = nil)
  if valid_612394 != nil:
    section.add "X-Amz-Security-Token", valid_612394
  var valid_612395 = header.getOrDefault("X-Amz-Algorithm")
  valid_612395 = validateParameter(valid_612395, JString, required = false,
                                 default = nil)
  if valid_612395 != nil:
    section.add "X-Amz-Algorithm", valid_612395
  var valid_612396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612396 = validateParameter(valid_612396, JString, required = false,
                                 default = nil)
  if valid_612396 != nil:
    section.add "X-Amz-SignedHeaders", valid_612396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612397: Call_GetSetIpAddressType_612383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_612397.validator(path, query, header, formData, body)
  let scheme = call_612397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612397.url(scheme.get, call_612397.host, call_612397.base,
                         call_612397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612397, url, valid)

proc call*(call_612398: Call_GetSetIpAddressType_612383; LoadBalancerArn: string;
          IpAddressType: string = "ipv4"; Action: string = "SetIpAddressType";
          Version: string = "2015-12-01"): Recallable =
  ## getSetIpAddressType
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ##   IpAddressType: string (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612399 = newJObject()
  add(query_612399, "IpAddressType", newJString(IpAddressType))
  add(query_612399, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_612399, "Action", newJString(Action))
  add(query_612399, "Version", newJString(Version))
  result = call_612398.call(nil, query_612399, nil, nil, nil)

var getSetIpAddressType* = Call_GetSetIpAddressType_612383(
    name: "getSetIpAddressType", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_GetSetIpAddressType_612384,
    base: "/", url: url_GetSetIpAddressType_612385,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetRulePriorities_612434 = ref object of OpenApiRestCall_610658
proc url_PostSetRulePriorities_612436(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetRulePriorities_612435(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612437 = query.getOrDefault("Action")
  valid_612437 = validateParameter(valid_612437, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_612437 != nil:
    section.add "Action", valid_612437
  var valid_612438 = query.getOrDefault("Version")
  valid_612438 = validateParameter(valid_612438, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612438 != nil:
    section.add "Version", valid_612438
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612439 = header.getOrDefault("X-Amz-Signature")
  valid_612439 = validateParameter(valid_612439, JString, required = false,
                                 default = nil)
  if valid_612439 != nil:
    section.add "X-Amz-Signature", valid_612439
  var valid_612440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612440 = validateParameter(valid_612440, JString, required = false,
                                 default = nil)
  if valid_612440 != nil:
    section.add "X-Amz-Content-Sha256", valid_612440
  var valid_612441 = header.getOrDefault("X-Amz-Date")
  valid_612441 = validateParameter(valid_612441, JString, required = false,
                                 default = nil)
  if valid_612441 != nil:
    section.add "X-Amz-Date", valid_612441
  var valid_612442 = header.getOrDefault("X-Amz-Credential")
  valid_612442 = validateParameter(valid_612442, JString, required = false,
                                 default = nil)
  if valid_612442 != nil:
    section.add "X-Amz-Credential", valid_612442
  var valid_612443 = header.getOrDefault("X-Amz-Security-Token")
  valid_612443 = validateParameter(valid_612443, JString, required = false,
                                 default = nil)
  if valid_612443 != nil:
    section.add "X-Amz-Security-Token", valid_612443
  var valid_612444 = header.getOrDefault("X-Amz-Algorithm")
  valid_612444 = validateParameter(valid_612444, JString, required = false,
                                 default = nil)
  if valid_612444 != nil:
    section.add "X-Amz-Algorithm", valid_612444
  var valid_612445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612445 = validateParameter(valid_612445, JString, required = false,
                                 default = nil)
  if valid_612445 != nil:
    section.add "X-Amz-SignedHeaders", valid_612445
  result.add "header", section
  ## parameters in `formData` object:
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RulePriorities` field"
  var valid_612446 = formData.getOrDefault("RulePriorities")
  valid_612446 = validateParameter(valid_612446, JArray, required = true, default = nil)
  if valid_612446 != nil:
    section.add "RulePriorities", valid_612446
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612447: Call_PostSetRulePriorities_612434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_612447.validator(path, query, header, formData, body)
  let scheme = call_612447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612447.url(scheme.get, call_612447.host, call_612447.base,
                         call_612447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612447, url, valid)

proc call*(call_612448: Call_PostSetRulePriorities_612434;
          RulePriorities: JsonNode; Action: string = "SetRulePriorities";
          Version: string = "2015-12-01"): Recallable =
  ## postSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612449 = newJObject()
  var formData_612450 = newJObject()
  if RulePriorities != nil:
    formData_612450.add "RulePriorities", RulePriorities
  add(query_612449, "Action", newJString(Action))
  add(query_612449, "Version", newJString(Version))
  result = call_612448.call(nil, query_612449, nil, formData_612450, nil)

var postSetRulePriorities* = Call_PostSetRulePriorities_612434(
    name: "postSetRulePriorities", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities",
    validator: validate_PostSetRulePriorities_612435, base: "/",
    url: url_PostSetRulePriorities_612436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetRulePriorities_612418 = ref object of OpenApiRestCall_610658
proc url_GetSetRulePriorities_612420(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetRulePriorities_612419(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `RulePriorities` field"
  var valid_612421 = query.getOrDefault("RulePriorities")
  valid_612421 = validateParameter(valid_612421, JArray, required = true, default = nil)
  if valid_612421 != nil:
    section.add "RulePriorities", valid_612421
  var valid_612422 = query.getOrDefault("Action")
  valid_612422 = validateParameter(valid_612422, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_612422 != nil:
    section.add "Action", valid_612422
  var valid_612423 = query.getOrDefault("Version")
  valid_612423 = validateParameter(valid_612423, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612423 != nil:
    section.add "Version", valid_612423
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612424 = header.getOrDefault("X-Amz-Signature")
  valid_612424 = validateParameter(valid_612424, JString, required = false,
                                 default = nil)
  if valid_612424 != nil:
    section.add "X-Amz-Signature", valid_612424
  var valid_612425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612425 = validateParameter(valid_612425, JString, required = false,
                                 default = nil)
  if valid_612425 != nil:
    section.add "X-Amz-Content-Sha256", valid_612425
  var valid_612426 = header.getOrDefault("X-Amz-Date")
  valid_612426 = validateParameter(valid_612426, JString, required = false,
                                 default = nil)
  if valid_612426 != nil:
    section.add "X-Amz-Date", valid_612426
  var valid_612427 = header.getOrDefault("X-Amz-Credential")
  valid_612427 = validateParameter(valid_612427, JString, required = false,
                                 default = nil)
  if valid_612427 != nil:
    section.add "X-Amz-Credential", valid_612427
  var valid_612428 = header.getOrDefault("X-Amz-Security-Token")
  valid_612428 = validateParameter(valid_612428, JString, required = false,
                                 default = nil)
  if valid_612428 != nil:
    section.add "X-Amz-Security-Token", valid_612428
  var valid_612429 = header.getOrDefault("X-Amz-Algorithm")
  valid_612429 = validateParameter(valid_612429, JString, required = false,
                                 default = nil)
  if valid_612429 != nil:
    section.add "X-Amz-Algorithm", valid_612429
  var valid_612430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612430 = validateParameter(valid_612430, JString, required = false,
                                 default = nil)
  if valid_612430 != nil:
    section.add "X-Amz-SignedHeaders", valid_612430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612431: Call_GetSetRulePriorities_612418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_612431.validator(path, query, header, formData, body)
  let scheme = call_612431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612431.url(scheme.get, call_612431.host, call_612431.base,
                         call_612431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612431, url, valid)

proc call*(call_612432: Call_GetSetRulePriorities_612418; RulePriorities: JsonNode;
          Action: string = "SetRulePriorities"; Version: string = "2015-12-01"): Recallable =
  ## getSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612433 = newJObject()
  if RulePriorities != nil:
    query_612433.add "RulePriorities", RulePriorities
  add(query_612433, "Action", newJString(Action))
  add(query_612433, "Version", newJString(Version))
  result = call_612432.call(nil, query_612433, nil, nil, nil)

var getSetRulePriorities* = Call_GetSetRulePriorities_612418(
    name: "getSetRulePriorities", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities", validator: validate_GetSetRulePriorities_612419,
    base: "/", url: url_GetSetRulePriorities_612420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSecurityGroups_612468 = ref object of OpenApiRestCall_610658
proc url_PostSetSecurityGroups_612470(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetSecurityGroups_612469(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612471 = query.getOrDefault("Action")
  valid_612471 = validateParameter(valid_612471, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_612471 != nil:
    section.add "Action", valid_612471
  var valid_612472 = query.getOrDefault("Version")
  valid_612472 = validateParameter(valid_612472, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612472 != nil:
    section.add "Version", valid_612472
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612473 = header.getOrDefault("X-Amz-Signature")
  valid_612473 = validateParameter(valid_612473, JString, required = false,
                                 default = nil)
  if valid_612473 != nil:
    section.add "X-Amz-Signature", valid_612473
  var valid_612474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612474 = validateParameter(valid_612474, JString, required = false,
                                 default = nil)
  if valid_612474 != nil:
    section.add "X-Amz-Content-Sha256", valid_612474
  var valid_612475 = header.getOrDefault("X-Amz-Date")
  valid_612475 = validateParameter(valid_612475, JString, required = false,
                                 default = nil)
  if valid_612475 != nil:
    section.add "X-Amz-Date", valid_612475
  var valid_612476 = header.getOrDefault("X-Amz-Credential")
  valid_612476 = validateParameter(valid_612476, JString, required = false,
                                 default = nil)
  if valid_612476 != nil:
    section.add "X-Amz-Credential", valid_612476
  var valid_612477 = header.getOrDefault("X-Amz-Security-Token")
  valid_612477 = validateParameter(valid_612477, JString, required = false,
                                 default = nil)
  if valid_612477 != nil:
    section.add "X-Amz-Security-Token", valid_612477
  var valid_612478 = header.getOrDefault("X-Amz-Algorithm")
  valid_612478 = validateParameter(valid_612478, JString, required = false,
                                 default = nil)
  if valid_612478 != nil:
    section.add "X-Amz-Algorithm", valid_612478
  var valid_612479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612479 = validateParameter(valid_612479, JString, required = false,
                                 default = nil)
  if valid_612479 != nil:
    section.add "X-Amz-SignedHeaders", valid_612479
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_612480 = formData.getOrDefault("SecurityGroups")
  valid_612480 = validateParameter(valid_612480, JArray, required = true, default = nil)
  if valid_612480 != nil:
    section.add "SecurityGroups", valid_612480
  var valid_612481 = formData.getOrDefault("LoadBalancerArn")
  valid_612481 = validateParameter(valid_612481, JString, required = true,
                                 default = nil)
  if valid_612481 != nil:
    section.add "LoadBalancerArn", valid_612481
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612482: Call_PostSetSecurityGroups_612468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_612482.validator(path, query, header, formData, body)
  let scheme = call_612482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612482.url(scheme.get, call_612482.host, call_612482.base,
                         call_612482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612482, url, valid)

proc call*(call_612483: Call_PostSetSecurityGroups_612468;
          SecurityGroups: JsonNode; LoadBalancerArn: string;
          Action: string = "SetSecurityGroups"; Version: string = "2015-12-01"): Recallable =
  ## postSetSecurityGroups
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_612484 = newJObject()
  var formData_612485 = newJObject()
  if SecurityGroups != nil:
    formData_612485.add "SecurityGroups", SecurityGroups
  add(query_612484, "Action", newJString(Action))
  add(query_612484, "Version", newJString(Version))
  add(formData_612485, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_612483.call(nil, query_612484, nil, formData_612485, nil)

var postSetSecurityGroups* = Call_PostSetSecurityGroups_612468(
    name: "postSetSecurityGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups",
    validator: validate_PostSetSecurityGroups_612469, base: "/",
    url: url_PostSetSecurityGroups_612470, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSecurityGroups_612451 = ref object of OpenApiRestCall_610658
proc url_GetSetSecurityGroups_612453(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetSecurityGroups_612452(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_612454 = query.getOrDefault("LoadBalancerArn")
  valid_612454 = validateParameter(valid_612454, JString, required = true,
                                 default = nil)
  if valid_612454 != nil:
    section.add "LoadBalancerArn", valid_612454
  var valid_612455 = query.getOrDefault("SecurityGroups")
  valid_612455 = validateParameter(valid_612455, JArray, required = true, default = nil)
  if valid_612455 != nil:
    section.add "SecurityGroups", valid_612455
  var valid_612456 = query.getOrDefault("Action")
  valid_612456 = validateParameter(valid_612456, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_612456 != nil:
    section.add "Action", valid_612456
  var valid_612457 = query.getOrDefault("Version")
  valid_612457 = validateParameter(valid_612457, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612457 != nil:
    section.add "Version", valid_612457
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612458 = header.getOrDefault("X-Amz-Signature")
  valid_612458 = validateParameter(valid_612458, JString, required = false,
                                 default = nil)
  if valid_612458 != nil:
    section.add "X-Amz-Signature", valid_612458
  var valid_612459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612459 = validateParameter(valid_612459, JString, required = false,
                                 default = nil)
  if valid_612459 != nil:
    section.add "X-Amz-Content-Sha256", valid_612459
  var valid_612460 = header.getOrDefault("X-Amz-Date")
  valid_612460 = validateParameter(valid_612460, JString, required = false,
                                 default = nil)
  if valid_612460 != nil:
    section.add "X-Amz-Date", valid_612460
  var valid_612461 = header.getOrDefault("X-Amz-Credential")
  valid_612461 = validateParameter(valid_612461, JString, required = false,
                                 default = nil)
  if valid_612461 != nil:
    section.add "X-Amz-Credential", valid_612461
  var valid_612462 = header.getOrDefault("X-Amz-Security-Token")
  valid_612462 = validateParameter(valid_612462, JString, required = false,
                                 default = nil)
  if valid_612462 != nil:
    section.add "X-Amz-Security-Token", valid_612462
  var valid_612463 = header.getOrDefault("X-Amz-Algorithm")
  valid_612463 = validateParameter(valid_612463, JString, required = false,
                                 default = nil)
  if valid_612463 != nil:
    section.add "X-Amz-Algorithm", valid_612463
  var valid_612464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612464 = validateParameter(valid_612464, JString, required = false,
                                 default = nil)
  if valid_612464 != nil:
    section.add "X-Amz-SignedHeaders", valid_612464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612465: Call_GetSetSecurityGroups_612451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_612465.validator(path, query, header, formData, body)
  let scheme = call_612465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612465.url(scheme.get, call_612465.host, call_612465.base,
                         call_612465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612465, url, valid)

proc call*(call_612466: Call_GetSetSecurityGroups_612451; LoadBalancerArn: string;
          SecurityGroups: JsonNode; Action: string = "SetSecurityGroups";
          Version: string = "2015-12-01"): Recallable =
  ## getSetSecurityGroups
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612467 = newJObject()
  add(query_612467, "LoadBalancerArn", newJString(LoadBalancerArn))
  if SecurityGroups != nil:
    query_612467.add "SecurityGroups", SecurityGroups
  add(query_612467, "Action", newJString(Action))
  add(query_612467, "Version", newJString(Version))
  result = call_612466.call(nil, query_612467, nil, nil, nil)

var getSetSecurityGroups* = Call_GetSetSecurityGroups_612451(
    name: "getSetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups", validator: validate_GetSetSecurityGroups_612452,
    base: "/", url: url_GetSetSecurityGroups_612453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubnets_612504 = ref object of OpenApiRestCall_610658
proc url_PostSetSubnets_612506(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetSubnets_612505(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612507 = query.getOrDefault("Action")
  valid_612507 = validateParameter(valid_612507, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_612507 != nil:
    section.add "Action", valid_612507
  var valid_612508 = query.getOrDefault("Version")
  valid_612508 = validateParameter(valid_612508, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612508 != nil:
    section.add "Version", valid_612508
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612509 = header.getOrDefault("X-Amz-Signature")
  valid_612509 = validateParameter(valid_612509, JString, required = false,
                                 default = nil)
  if valid_612509 != nil:
    section.add "X-Amz-Signature", valid_612509
  var valid_612510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612510 = validateParameter(valid_612510, JString, required = false,
                                 default = nil)
  if valid_612510 != nil:
    section.add "X-Amz-Content-Sha256", valid_612510
  var valid_612511 = header.getOrDefault("X-Amz-Date")
  valid_612511 = validateParameter(valid_612511, JString, required = false,
                                 default = nil)
  if valid_612511 != nil:
    section.add "X-Amz-Date", valid_612511
  var valid_612512 = header.getOrDefault("X-Amz-Credential")
  valid_612512 = validateParameter(valid_612512, JString, required = false,
                                 default = nil)
  if valid_612512 != nil:
    section.add "X-Amz-Credential", valid_612512
  var valid_612513 = header.getOrDefault("X-Amz-Security-Token")
  valid_612513 = validateParameter(valid_612513, JString, required = false,
                                 default = nil)
  if valid_612513 != nil:
    section.add "X-Amz-Security-Token", valid_612513
  var valid_612514 = header.getOrDefault("X-Amz-Algorithm")
  valid_612514 = validateParameter(valid_612514, JString, required = false,
                                 default = nil)
  if valid_612514 != nil:
    section.add "X-Amz-Algorithm", valid_612514
  var valid_612515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612515 = validateParameter(valid_612515, JString, required = false,
                                 default = nil)
  if valid_612515 != nil:
    section.add "X-Amz-SignedHeaders", valid_612515
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. If you need static IP addresses for your internet-facing load balancer, you can specify one Elastic IP address per subnet. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  var valid_612516 = formData.getOrDefault("Subnets")
  valid_612516 = validateParameter(valid_612516, JArray, required = false,
                                 default = nil)
  if valid_612516 != nil:
    section.add "Subnets", valid_612516
  var valid_612517 = formData.getOrDefault("SubnetMappings")
  valid_612517 = validateParameter(valid_612517, JArray, required = false,
                                 default = nil)
  if valid_612517 != nil:
    section.add "SubnetMappings", valid_612517
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_612518 = formData.getOrDefault("LoadBalancerArn")
  valid_612518 = validateParameter(valid_612518, JString, required = true,
                                 default = nil)
  if valid_612518 != nil:
    section.add "LoadBalancerArn", valid_612518
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612519: Call_PostSetSubnets_612504; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ## 
  let valid = call_612519.validator(path, query, header, formData, body)
  let scheme = call_612519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612519.url(scheme.get, call_612519.host, call_612519.base,
                         call_612519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612519, url, valid)

proc call*(call_612520: Call_PostSetSubnets_612504; LoadBalancerArn: string;
          Subnets: JsonNode = nil; Action: string = "SetSubnets";
          SubnetMappings: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
  ## postSetSubnets
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   Action: string (required)
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. If you need static IP addresses for your internet-facing load balancer, you can specify one Elastic IP address per subnet. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_612521 = newJObject()
  var formData_612522 = newJObject()
  if Subnets != nil:
    formData_612522.add "Subnets", Subnets
  add(query_612521, "Action", newJString(Action))
  if SubnetMappings != nil:
    formData_612522.add "SubnetMappings", SubnetMappings
  add(query_612521, "Version", newJString(Version))
  add(formData_612522, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_612520.call(nil, query_612521, nil, formData_612522, nil)

var postSetSubnets* = Call_PostSetSubnets_612504(name: "postSetSubnets",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_PostSetSubnets_612505,
    base: "/", url: url_PostSetSubnets_612506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubnets_612486 = ref object of OpenApiRestCall_610658
proc url_GetSetSubnets_612488(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetSubnets_612487(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. If you need static IP addresses for your internet-facing load balancer, you can specify one Elastic IP address per subnet. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: JString (required)
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   Version: JString (required)
  section = newJObject()
  var valid_612489 = query.getOrDefault("SubnetMappings")
  valid_612489 = validateParameter(valid_612489, JArray, required = false,
                                 default = nil)
  if valid_612489 != nil:
    section.add "SubnetMappings", valid_612489
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_612490 = query.getOrDefault("LoadBalancerArn")
  valid_612490 = validateParameter(valid_612490, JString, required = true,
                                 default = nil)
  if valid_612490 != nil:
    section.add "LoadBalancerArn", valid_612490
  var valid_612491 = query.getOrDefault("Action")
  valid_612491 = validateParameter(valid_612491, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_612491 != nil:
    section.add "Action", valid_612491
  var valid_612492 = query.getOrDefault("Subnets")
  valid_612492 = validateParameter(valid_612492, JArray, required = false,
                                 default = nil)
  if valid_612492 != nil:
    section.add "Subnets", valid_612492
  var valid_612493 = query.getOrDefault("Version")
  valid_612493 = validateParameter(valid_612493, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_612493 != nil:
    section.add "Version", valid_612493
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612494 = header.getOrDefault("X-Amz-Signature")
  valid_612494 = validateParameter(valid_612494, JString, required = false,
                                 default = nil)
  if valid_612494 != nil:
    section.add "X-Amz-Signature", valid_612494
  var valid_612495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612495 = validateParameter(valid_612495, JString, required = false,
                                 default = nil)
  if valid_612495 != nil:
    section.add "X-Amz-Content-Sha256", valid_612495
  var valid_612496 = header.getOrDefault("X-Amz-Date")
  valid_612496 = validateParameter(valid_612496, JString, required = false,
                                 default = nil)
  if valid_612496 != nil:
    section.add "X-Amz-Date", valid_612496
  var valid_612497 = header.getOrDefault("X-Amz-Credential")
  valid_612497 = validateParameter(valid_612497, JString, required = false,
                                 default = nil)
  if valid_612497 != nil:
    section.add "X-Amz-Credential", valid_612497
  var valid_612498 = header.getOrDefault("X-Amz-Security-Token")
  valid_612498 = validateParameter(valid_612498, JString, required = false,
                                 default = nil)
  if valid_612498 != nil:
    section.add "X-Amz-Security-Token", valid_612498
  var valid_612499 = header.getOrDefault("X-Amz-Algorithm")
  valid_612499 = validateParameter(valid_612499, JString, required = false,
                                 default = nil)
  if valid_612499 != nil:
    section.add "X-Amz-Algorithm", valid_612499
  var valid_612500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612500 = validateParameter(valid_612500, JString, required = false,
                                 default = nil)
  if valid_612500 != nil:
    section.add "X-Amz-SignedHeaders", valid_612500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612501: Call_GetSetSubnets_612486; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ## 
  let valid = call_612501.validator(path, query, header, formData, body)
  let scheme = call_612501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612501.url(scheme.get, call_612501.host, call_612501.base,
                         call_612501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612501, url, valid)

proc call*(call_612502: Call_GetSetSubnets_612486; LoadBalancerArn: string;
          SubnetMappings: JsonNode = nil; Action: string = "SetSubnets";
          Subnets: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
  ## getSetSubnets
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. If you need static IP addresses for your internet-facing load balancer, you can specify one Elastic IP address per subnet. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   Version: string (required)
  var query_612503 = newJObject()
  if SubnetMappings != nil:
    query_612503.add "SubnetMappings", SubnetMappings
  add(query_612503, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_612503, "Action", newJString(Action))
  if Subnets != nil:
    query_612503.add "Subnets", Subnets
  add(query_612503, "Version", newJString(Version))
  result = call_612502.call(nil, query_612503, nil, nil, nil)

var getSetSubnets* = Call_GetSetSubnets_612486(name: "getSetSubnets",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_GetSetSubnets_612487,
    base: "/", url: url_GetSetSubnets_612488, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
