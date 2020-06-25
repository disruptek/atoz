
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_PostAddListenerCertificates_21626035 = ref object of OpenApiRestCall_21625435
proc url_PostAddListenerCertificates_21626037(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddListenerCertificates_21626036(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626038 = query.getOrDefault("Action")
  valid_21626038 = validateParameter(valid_21626038, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_21626038 != nil:
    section.add "Action", valid_21626038
  var valid_21626039 = query.getOrDefault("Version")
  valid_21626039 = validateParameter(valid_21626039, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626039 != nil:
    section.add "Version", valid_21626039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626040 = header.getOrDefault("X-Amz-Date")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Date", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Security-Token", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Algorithm", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Signature")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Signature", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Credential")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Credential", valid_21626046
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_21626047 = formData.getOrDefault("Certificates")
  valid_21626047 = validateParameter(valid_21626047, JArray, required = true,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "Certificates", valid_21626047
  var valid_21626048 = formData.getOrDefault("ListenerArn")
  valid_21626048 = validateParameter(valid_21626048, JString, required = true,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "ListenerArn", valid_21626048
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626049: Call_PostAddListenerCertificates_21626035;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626049.validator(path, query, header, formData, body, _)
  let scheme = call_21626049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626049.makeUrl(scheme.get, call_21626049.host, call_21626049.base,
                               call_21626049.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626049, uri, valid, _)

proc call*(call_21626050: Call_PostAddListenerCertificates_21626035;
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
  var query_21626051 = newJObject()
  var formData_21626052 = newJObject()
  if Certificates != nil:
    formData_21626052.add "Certificates", Certificates
  add(formData_21626052, "ListenerArn", newJString(ListenerArn))
  add(query_21626051, "Action", newJString(Action))
  add(query_21626051, "Version", newJString(Version))
  result = call_21626050.call(nil, query_21626051, nil, formData_21626052, nil)

var postAddListenerCertificates* = Call_PostAddListenerCertificates_21626035(
    name: "postAddListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_PostAddListenerCertificates_21626036, base: "/",
    makeUrl: url_PostAddListenerCertificates_21626037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddListenerCertificates_21625779 = ref object of OpenApiRestCall_21625435
proc url_GetAddListenerCertificates_21625781(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddListenerCertificates_21625780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   Action: JString (required)
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Certificates` field"
  var valid_21625882 = query.getOrDefault("Certificates")
  valid_21625882 = validateParameter(valid_21625882, JArray, required = true,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "Certificates", valid_21625882
  var valid_21625897 = query.getOrDefault("Action")
  valid_21625897 = validateParameter(valid_21625897, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_21625897 != nil:
    section.add "Action", valid_21625897
  var valid_21625898 = query.getOrDefault("ListenerArn")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "ListenerArn", valid_21625898
  var valid_21625899 = query.getOrDefault("Version")
  valid_21625899 = validateParameter(valid_21625899, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21625899 != nil:
    section.add "Version", valid_21625899
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625900 = header.getOrDefault("X-Amz-Date")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Date", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Security-Token", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Algorithm", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-Signature")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-Signature", valid_21625904
  var valid_21625905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625905 = validateParameter(valid_21625905, JString, required = false,
                                   default = nil)
  if valid_21625905 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625905
  var valid_21625906 = header.getOrDefault("X-Amz-Credential")
  valid_21625906 = validateParameter(valid_21625906, JString, required = false,
                                   default = nil)
  if valid_21625906 != nil:
    section.add "X-Amz-Credential", valid_21625906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625931: Call_GetAddListenerCertificates_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21625931.validator(path, query, header, formData, body, _)
  let scheme = call_21625931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625931.makeUrl(scheme.get, call_21625931.host, call_21625931.base,
                               call_21625931.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625931, uri, valid, _)

proc call*(call_21625994: Call_GetAddListenerCertificates_21625779;
          Certificates: JsonNode; ListenerArn: string;
          Action: string = "AddListenerCertificates"; Version: string = "2015-12-01"): Recallable =
  ## getAddListenerCertificates
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   Action: string (required)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: string (required)
  var query_21625996 = newJObject()
  if Certificates != nil:
    query_21625996.add "Certificates", Certificates
  add(query_21625996, "Action", newJString(Action))
  add(query_21625996, "ListenerArn", newJString(ListenerArn))
  add(query_21625996, "Version", newJString(Version))
  result = call_21625994.call(nil, query_21625996, nil, nil, nil)

var getAddListenerCertificates* = Call_GetAddListenerCertificates_21625779(
    name: "getAddListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_GetAddListenerCertificates_21625780, base: "/",
    makeUrl: url_GetAddListenerCertificates_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTags_21626070 = ref object of OpenApiRestCall_21625435
proc url_PostAddTags_21626072(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddTags_21626071(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626073 = query.getOrDefault("Action")
  valid_21626073 = validateParameter(valid_21626073, JString, required = true,
                                   default = newJString("AddTags"))
  if valid_21626073 != nil:
    section.add "Action", valid_21626073
  var valid_21626074 = query.getOrDefault("Version")
  valid_21626074 = validateParameter(valid_21626074, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626074 != nil:
    section.add "Version", valid_21626074
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626075 = header.getOrDefault("X-Amz-Date")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Date", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Security-Token", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Algorithm", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Signature")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Signature", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Credential")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Credential", valid_21626081
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_21626082 = formData.getOrDefault("ResourceArns")
  valid_21626082 = validateParameter(valid_21626082, JArray, required = true,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "ResourceArns", valid_21626082
  var valid_21626083 = formData.getOrDefault("Tags")
  valid_21626083 = validateParameter(valid_21626083, JArray, required = true,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "Tags", valid_21626083
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626084: Call_PostAddTags_21626070; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_21626084.validator(path, query, header, formData, body, _)
  let scheme = call_21626084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626084.makeUrl(scheme.get, call_21626084.host, call_21626084.base,
                               call_21626084.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626084, uri, valid, _)

proc call*(call_21626085: Call_PostAddTags_21626070; ResourceArns: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2015-12-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626086 = newJObject()
  var formData_21626087 = newJObject()
  if ResourceArns != nil:
    formData_21626087.add "ResourceArns", ResourceArns
  if Tags != nil:
    formData_21626087.add "Tags", Tags
  add(query_21626086, "Action", newJString(Action))
  add(query_21626086, "Version", newJString(Version))
  result = call_21626085.call(nil, query_21626086, nil, formData_21626087, nil)

var postAddTags* = Call_PostAddTags_21626070(name: "postAddTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddTags", validator: validate_PostAddTags_21626071, base: "/",
    makeUrl: url_PostAddTags_21626072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_21626053 = ref object of OpenApiRestCall_21625435
proc url_GetAddTags_21626055(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTags_21626054(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Action: JString (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_21626056 = query.getOrDefault("Tags")
  valid_21626056 = validateParameter(valid_21626056, JArray, required = true,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "Tags", valid_21626056
  var valid_21626057 = query.getOrDefault("Action")
  valid_21626057 = validateParameter(valid_21626057, JString, required = true,
                                   default = newJString("AddTags"))
  if valid_21626057 != nil:
    section.add "Action", valid_21626057
  var valid_21626058 = query.getOrDefault("ResourceArns")
  valid_21626058 = validateParameter(valid_21626058, JArray, required = true,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "ResourceArns", valid_21626058
  var valid_21626059 = query.getOrDefault("Version")
  valid_21626059 = validateParameter(valid_21626059, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626059 != nil:
    section.add "Version", valid_21626059
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626060 = header.getOrDefault("X-Amz-Date")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Date", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Security-Token", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Algorithm", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Signature")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Signature", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Credential")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Credential", valid_21626066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626067: Call_GetAddTags_21626053; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_21626067.validator(path, query, header, formData, body, _)
  let scheme = call_21626067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626067.makeUrl(scheme.get, call_21626067.host, call_21626067.base,
                               call_21626067.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626067, uri, valid, _)

proc call*(call_21626068: Call_GetAddTags_21626053; Tags: JsonNode;
          ResourceArns: JsonNode; Action: string = "AddTags";
          Version: string = "2015-12-01"): Recallable =
  ## getAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Action: string (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Version: string (required)
  var query_21626069 = newJObject()
  if Tags != nil:
    query_21626069.add "Tags", Tags
  add(query_21626069, "Action", newJString(Action))
  if ResourceArns != nil:
    query_21626069.add "ResourceArns", ResourceArns
  add(query_21626069, "Version", newJString(Version))
  result = call_21626068.call(nil, query_21626069, nil, nil, nil)

var getAddTags* = Call_GetAddTags_21626053(name: "getAddTags",
                                        meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_GetAddTags_21626054,
                                        base: "/", makeUrl: url_GetAddTags_21626055,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateListener_21626110 = ref object of OpenApiRestCall_21625435
proc url_PostCreateListener_21626112(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateListener_21626111(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626113 = query.getOrDefault("Action")
  valid_21626113 = validateParameter(valid_21626113, JString, required = true,
                                   default = newJString("CreateListener"))
  if valid_21626113 != nil:
    section.add "Action", valid_21626113
  var valid_21626114 = query.getOrDefault("Version")
  valid_21626114 = validateParameter(valid_21626114, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626114 != nil:
    section.add "Version", valid_21626114
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626115 = header.getOrDefault("X-Amz-Date")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Date", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Security-Token", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Algorithm", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Signature")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Signature", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Credential")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Credential", valid_21626121
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list for the listener, use <a>AddListenerCertificates</a>.</p>
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Port: JInt (required)
  ##       : The port on which the load balancer is listening.
  ##   Protocol: JString (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   SslPolicy: JString
  ##            : [HTTPS and TLS listeners] The security policy that defines which ciphers and protocols are supported. The default is the current predefined security policy.
  ##   DefaultActions: JArray (required)
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  section = newJObject()
  var valid_21626122 = formData.getOrDefault("Certificates")
  valid_21626122 = validateParameter(valid_21626122, JArray, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "Certificates", valid_21626122
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_21626123 = formData.getOrDefault("LoadBalancerArn")
  valid_21626123 = validateParameter(valid_21626123, JString, required = true,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "LoadBalancerArn", valid_21626123
  var valid_21626124 = formData.getOrDefault("Port")
  valid_21626124 = validateParameter(valid_21626124, JInt, required = true,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "Port", valid_21626124
  var valid_21626125 = formData.getOrDefault("Protocol")
  valid_21626125 = validateParameter(valid_21626125, JString, required = true,
                                   default = newJString("HTTP"))
  if valid_21626125 != nil:
    section.add "Protocol", valid_21626125
  var valid_21626126 = formData.getOrDefault("SslPolicy")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "SslPolicy", valid_21626126
  var valid_21626127 = formData.getOrDefault("DefaultActions")
  valid_21626127 = validateParameter(valid_21626127, JArray, required = true,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "DefaultActions", valid_21626127
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626128: Call_PostCreateListener_21626110; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626128.validator(path, query, header, formData, body, _)
  let scheme = call_21626128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626128.makeUrl(scheme.get, call_21626128.host, call_21626128.base,
                               call_21626128.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626128, uri, valid, _)

proc call*(call_21626129: Call_PostCreateListener_21626110;
          LoadBalancerArn: string; Port: int; DefaultActions: JsonNode;
          Certificates: JsonNode = nil; Protocol: string = "HTTP";
          Action: string = "CreateListener"; SslPolicy: string = "";
          Version: string = "2015-12-01"): Recallable =
  ## postCreateListener
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list for the listener, use <a>AddListenerCertificates</a>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Port: int (required)
  ##       : The port on which the load balancer is listening.
  ##   Protocol: string (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   Action: string (required)
  ##   SslPolicy: string
  ##            : [HTTPS and TLS listeners] The security policy that defines which ciphers and protocols are supported. The default is the current predefined security policy.
  ##   DefaultActions: JArray (required)
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Version: string (required)
  var query_21626130 = newJObject()
  var formData_21626131 = newJObject()
  if Certificates != nil:
    formData_21626131.add "Certificates", Certificates
  add(formData_21626131, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_21626131, "Port", newJInt(Port))
  add(formData_21626131, "Protocol", newJString(Protocol))
  add(query_21626130, "Action", newJString(Action))
  add(formData_21626131, "SslPolicy", newJString(SslPolicy))
  if DefaultActions != nil:
    formData_21626131.add "DefaultActions", DefaultActions
  add(query_21626130, "Version", newJString(Version))
  result = call_21626129.call(nil, query_21626130, nil, formData_21626131, nil)

var postCreateListener* = Call_PostCreateListener_21626110(
    name: "postCreateListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=CreateListener",
    validator: validate_PostCreateListener_21626111, base: "/",
    makeUrl: url_PostCreateListener_21626112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateListener_21626088 = ref object of OpenApiRestCall_21625435
proc url_GetCreateListener_21626090(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateListener_21626089(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DefaultActions: JArray (required)
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   SslPolicy: JString
  ##            : [HTTPS and TLS listeners] The security policy that defines which ciphers and protocols are supported. The default is the current predefined security policy.
  ##   Protocol: JString (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list for the listener, use <a>AddListenerCertificates</a>.</p>
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Port: JInt (required)
  ##       : The port on which the load balancer is listening.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DefaultActions` field"
  var valid_21626091 = query.getOrDefault("DefaultActions")
  valid_21626091 = validateParameter(valid_21626091, JArray, required = true,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "DefaultActions", valid_21626091
  var valid_21626092 = query.getOrDefault("SslPolicy")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "SslPolicy", valid_21626092
  var valid_21626093 = query.getOrDefault("Protocol")
  valid_21626093 = validateParameter(valid_21626093, JString, required = true,
                                   default = newJString("HTTP"))
  if valid_21626093 != nil:
    section.add "Protocol", valid_21626093
  var valid_21626094 = query.getOrDefault("Certificates")
  valid_21626094 = validateParameter(valid_21626094, JArray, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "Certificates", valid_21626094
  var valid_21626095 = query.getOrDefault("Action")
  valid_21626095 = validateParameter(valid_21626095, JString, required = true,
                                   default = newJString("CreateListener"))
  if valid_21626095 != nil:
    section.add "Action", valid_21626095
  var valid_21626096 = query.getOrDefault("LoadBalancerArn")
  valid_21626096 = validateParameter(valid_21626096, JString, required = true,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "LoadBalancerArn", valid_21626096
  var valid_21626097 = query.getOrDefault("Port")
  valid_21626097 = validateParameter(valid_21626097, JInt, required = true,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "Port", valid_21626097
  var valid_21626098 = query.getOrDefault("Version")
  valid_21626098 = validateParameter(valid_21626098, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626098 != nil:
    section.add "Version", valid_21626098
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626099 = header.getOrDefault("X-Amz-Date")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Date", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Security-Token", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Algorithm", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Signature")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Signature", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Credential")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Credential", valid_21626105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626106: Call_GetCreateListener_21626088; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626106.validator(path, query, header, formData, body, _)
  let scheme = call_21626106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626106.makeUrl(scheme.get, call_21626106.host, call_21626106.base,
                               call_21626106.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626106, uri, valid, _)

proc call*(call_21626107: Call_GetCreateListener_21626088;
          DefaultActions: JsonNode; LoadBalancerArn: string; Port: int;
          SslPolicy: string = ""; Protocol: string = "HTTP";
          Certificates: JsonNode = nil; Action: string = "CreateListener";
          Version: string = "2015-12-01"): Recallable =
  ## getCreateListener
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   DefaultActions: JArray (required)
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   SslPolicy: string
  ##            : [HTTPS and TLS listeners] The security policy that defines which ciphers and protocols are supported. The default is the current predefined security policy.
  ##   Protocol: string (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list for the listener, use <a>AddListenerCertificates</a>.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Port: int (required)
  ##       : The port on which the load balancer is listening.
  ##   Version: string (required)
  var query_21626108 = newJObject()
  if DefaultActions != nil:
    query_21626108.add "DefaultActions", DefaultActions
  add(query_21626108, "SslPolicy", newJString(SslPolicy))
  add(query_21626108, "Protocol", newJString(Protocol))
  if Certificates != nil:
    query_21626108.add "Certificates", Certificates
  add(query_21626108, "Action", newJString(Action))
  add(query_21626108, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_21626108, "Port", newJInt(Port))
  add(query_21626108, "Version", newJString(Version))
  result = call_21626107.call(nil, query_21626108, nil, nil, nil)

var getCreateListener* = Call_GetCreateListener_21626088(name: "getCreateListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateListener", validator: validate_GetCreateListener_21626089,
    base: "/", makeUrl: url_GetCreateListener_21626090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_21626155 = ref object of OpenApiRestCall_21625435
proc url_PostCreateLoadBalancer_21626157(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateLoadBalancer_21626156(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626158 = query.getOrDefault("Action")
  valid_21626158 = validateParameter(valid_21626158, JString, required = true,
                                   default = newJString("CreateLoadBalancer"))
  if valid_21626158 != nil:
    section.add "Action", valid_21626158
  var valid_21626159 = query.getOrDefault("Version")
  valid_21626159 = validateParameter(valid_21626159, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626159 != nil:
    section.add "Version", valid_21626159
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626160 = header.getOrDefault("X-Amz-Date")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-Date", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Security-Token", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Algorithm", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-Signature")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Signature", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Credential")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Credential", valid_21626166
  result.add "header", section
  ## parameters in `formData` object:
  ##   Name: JString (required)
  ##       : <p>The name of the load balancer.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, must not begin or end with a hyphen, and must not begin with "internal-".</p>
  ##   IpAddressType: JString
  ##                : [Application Load Balancers] The type of IP addresses used by the subnets for your load balancer. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>.
  ##   Tags: JArray
  ##       : One or more tags to assign to the load balancer.
  ##   Type: JString
  ##       : The type of load balancer. The default is <code>application</code>.
  ##   Subnets: JArray
  ##          : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones.</p>
  ##   SecurityGroups: JArray
  ##                 : [Application Load Balancers] The IDs of the security groups for the load balancer.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your internet-facing load balancer. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   Scheme: JString
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can route requests only from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_21626167 = formData.getOrDefault("Name")
  valid_21626167 = validateParameter(valid_21626167, JString, required = true,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "Name", valid_21626167
  var valid_21626168 = formData.getOrDefault("IpAddressType")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = newJString("ipv4"))
  if valid_21626168 != nil:
    section.add "IpAddressType", valid_21626168
  var valid_21626169 = formData.getOrDefault("Tags")
  valid_21626169 = validateParameter(valid_21626169, JArray, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "Tags", valid_21626169
  var valid_21626170 = formData.getOrDefault("Type")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = newJString("application"))
  if valid_21626170 != nil:
    section.add "Type", valid_21626170
  var valid_21626171 = formData.getOrDefault("Subnets")
  valid_21626171 = validateParameter(valid_21626171, JArray, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "Subnets", valid_21626171
  var valid_21626172 = formData.getOrDefault("SecurityGroups")
  valid_21626172 = validateParameter(valid_21626172, JArray, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "SecurityGroups", valid_21626172
  var valid_21626173 = formData.getOrDefault("SubnetMappings")
  valid_21626173 = validateParameter(valid_21626173, JArray, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "SubnetMappings", valid_21626173
  var valid_21626174 = formData.getOrDefault("Scheme")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = newJString("internet-facing"))
  if valid_21626174 != nil:
    section.add "Scheme", valid_21626174
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626175: Call_PostCreateLoadBalancer_21626155;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626175.validator(path, query, header, formData, body, _)
  let scheme = call_21626175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626175.makeUrl(scheme.get, call_21626175.host, call_21626175.base,
                               call_21626175.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626175, uri, valid, _)

proc call*(call_21626176: Call_PostCreateLoadBalancer_21626155; Name: string;
          IpAddressType: string = "ipv4"; Tags: JsonNode = nil;
          Type: string = "application"; Action: string = "CreateLoadBalancer";
          Subnets: JsonNode = nil; SecurityGroups: JsonNode = nil;
          SubnetMappings: JsonNode = nil; Scheme: string = "internet-facing";
          Version: string = "2015-12-01"): Recallable =
  ## postCreateLoadBalancer
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Name: string (required)
  ##       : <p>The name of the load balancer.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, must not begin or end with a hyphen, and must not begin with "internal-".</p>
  ##   IpAddressType: string
  ##                : [Application Load Balancers] The type of IP addresses used by the subnets for your load balancer. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>.
  ##   Tags: JArray
  ##       : One or more tags to assign to the load balancer.
  ##   Type: string
  ##       : The type of load balancer. The default is <code>application</code>.
  ##   Action: string (required)
  ##   Subnets: JArray
  ##          : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones.</p>
  ##   SecurityGroups: JArray
  ##                 : [Application Load Balancers] The IDs of the security groups for the load balancer.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your internet-facing load balancer. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   Scheme: string
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can route requests only from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
  ##   Version: string (required)
  var query_21626177 = newJObject()
  var formData_21626178 = newJObject()
  add(formData_21626178, "Name", newJString(Name))
  add(formData_21626178, "IpAddressType", newJString(IpAddressType))
  if Tags != nil:
    formData_21626178.add "Tags", Tags
  add(formData_21626178, "Type", newJString(Type))
  add(query_21626177, "Action", newJString(Action))
  if Subnets != nil:
    formData_21626178.add "Subnets", Subnets
  if SecurityGroups != nil:
    formData_21626178.add "SecurityGroups", SecurityGroups
  if SubnetMappings != nil:
    formData_21626178.add "SubnetMappings", SubnetMappings
  add(formData_21626178, "Scheme", newJString(Scheme))
  add(query_21626177, "Version", newJString(Version))
  result = call_21626176.call(nil, query_21626177, nil, formData_21626178, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_21626155(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_21626156, base: "/",
    makeUrl: url_PostCreateLoadBalancer_21626157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_21626132 = ref object of OpenApiRestCall_21625435
proc url_GetCreateLoadBalancer_21626134(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateLoadBalancer_21626133(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Name: JString (required)
  ##       : <p>The name of the load balancer.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, must not begin or end with a hyphen, and must not begin with "internal-".</p>
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your internet-facing load balancer. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   IpAddressType: JString
  ##                : [Application Load Balancers] The type of IP addresses used by the subnets for your load balancer. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>.
  ##   Scheme: JString
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can route requests only from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
  ##   Tags: JArray
  ##       : One or more tags to assign to the load balancer.
  ##   Type: JString
  ##       : The type of load balancer. The default is <code>application</code>.
  ##   Action: JString (required)
  ##   Subnets: JArray
  ##          : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones.</p>
  ##   Version: JString (required)
  ##   SecurityGroups: JArray
  ##                 : [Application Load Balancers] The IDs of the security groups for the load balancer.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_21626135 = query.getOrDefault("Name")
  valid_21626135 = validateParameter(valid_21626135, JString, required = true,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "Name", valid_21626135
  var valid_21626136 = query.getOrDefault("SubnetMappings")
  valid_21626136 = validateParameter(valid_21626136, JArray, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "SubnetMappings", valid_21626136
  var valid_21626137 = query.getOrDefault("IpAddressType")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = newJString("ipv4"))
  if valid_21626137 != nil:
    section.add "IpAddressType", valid_21626137
  var valid_21626138 = query.getOrDefault("Scheme")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = newJString("internet-facing"))
  if valid_21626138 != nil:
    section.add "Scheme", valid_21626138
  var valid_21626139 = query.getOrDefault("Tags")
  valid_21626139 = validateParameter(valid_21626139, JArray, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "Tags", valid_21626139
  var valid_21626140 = query.getOrDefault("Type")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = newJString("application"))
  if valid_21626140 != nil:
    section.add "Type", valid_21626140
  var valid_21626141 = query.getOrDefault("Action")
  valid_21626141 = validateParameter(valid_21626141, JString, required = true,
                                   default = newJString("CreateLoadBalancer"))
  if valid_21626141 != nil:
    section.add "Action", valid_21626141
  var valid_21626142 = query.getOrDefault("Subnets")
  valid_21626142 = validateParameter(valid_21626142, JArray, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "Subnets", valid_21626142
  var valid_21626143 = query.getOrDefault("Version")
  valid_21626143 = validateParameter(valid_21626143, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626143 != nil:
    section.add "Version", valid_21626143
  var valid_21626144 = query.getOrDefault("SecurityGroups")
  valid_21626144 = validateParameter(valid_21626144, JArray, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "SecurityGroups", valid_21626144
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626145 = header.getOrDefault("X-Amz-Date")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Date", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Security-Token", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Algorithm", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Signature")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Signature", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Credential")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Credential", valid_21626151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626152: Call_GetCreateLoadBalancer_21626132;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626152.validator(path, query, header, formData, body, _)
  let scheme = call_21626152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626152.makeUrl(scheme.get, call_21626152.host, call_21626152.base,
                               call_21626152.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626152, uri, valid, _)

proc call*(call_21626153: Call_GetCreateLoadBalancer_21626132; Name: string;
          SubnetMappings: JsonNode = nil; IpAddressType: string = "ipv4";
          Scheme: string = "internet-facing"; Tags: JsonNode = nil;
          Type: string = "application"; Action: string = "CreateLoadBalancer";
          Subnets: JsonNode = nil; Version: string = "2015-12-01";
          SecurityGroups: JsonNode = nil): Recallable =
  ## getCreateLoadBalancer
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Name: string (required)
  ##       : <p>The name of the load balancer.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, must not begin or end with a hyphen, and must not begin with "internal-".</p>
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your internet-facing load balancer. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   IpAddressType: string
  ##                : [Application Load Balancers] The type of IP addresses used by the subnets for your load balancer. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>.
  ##   Scheme: string
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can route requests only from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
  ##   Tags: JArray
  ##       : One or more tags to assign to the load balancer.
  ##   Type: string
  ##       : The type of load balancer. The default is <code>application</code>.
  ##   Action: string (required)
  ##   Subnets: JArray
  ##          : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones.</p>
  ##   Version: string (required)
  ##   SecurityGroups: JArray
  ##                 : [Application Load Balancers] The IDs of the security groups for the load balancer.
  var query_21626154 = newJObject()
  add(query_21626154, "Name", newJString(Name))
  if SubnetMappings != nil:
    query_21626154.add "SubnetMappings", SubnetMappings
  add(query_21626154, "IpAddressType", newJString(IpAddressType))
  add(query_21626154, "Scheme", newJString(Scheme))
  if Tags != nil:
    query_21626154.add "Tags", Tags
  add(query_21626154, "Type", newJString(Type))
  add(query_21626154, "Action", newJString(Action))
  if Subnets != nil:
    query_21626154.add "Subnets", Subnets
  add(query_21626154, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_21626154.add "SecurityGroups", SecurityGroups
  result = call_21626153.call(nil, query_21626154, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_21626132(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_21626133, base: "/",
    makeUrl: url_GetCreateLoadBalancer_21626134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateRule_21626198 = ref object of OpenApiRestCall_21625435
proc url_PostCreateRule_21626200(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateRule_21626199(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626201 = query.getOrDefault("Action")
  valid_21626201 = validateParameter(valid_21626201, JString, required = true,
                                   default = newJString("CreateRule"))
  if valid_21626201 != nil:
    section.add "Action", valid_21626201
  var valid_21626202 = query.getOrDefault("Version")
  valid_21626202 = validateParameter(valid_21626202, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626202 != nil:
    section.add "Version", valid_21626202
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626203 = header.getOrDefault("X-Amz-Date")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-Date", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Security-Token", valid_21626204
  var valid_21626205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626205
  var valid_21626206 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "X-Amz-Algorithm", valid_21626206
  var valid_21626207 = header.getOrDefault("X-Amz-Signature")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "X-Amz-Signature", valid_21626207
  var valid_21626208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626208
  var valid_21626209 = header.getOrDefault("X-Amz-Credential")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "X-Amz-Credential", valid_21626209
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   Priority: JInt (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_21626210 = formData.getOrDefault("ListenerArn")
  valid_21626210 = validateParameter(valid_21626210, JString, required = true,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "ListenerArn", valid_21626210
  var valid_21626211 = formData.getOrDefault("Actions")
  valid_21626211 = validateParameter(valid_21626211, JArray, required = true,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "Actions", valid_21626211
  var valid_21626212 = formData.getOrDefault("Conditions")
  valid_21626212 = validateParameter(valid_21626212, JArray, required = true,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "Conditions", valid_21626212
  var valid_21626213 = formData.getOrDefault("Priority")
  valid_21626213 = validateParameter(valid_21626213, JInt, required = true,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "Priority", valid_21626213
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626214: Call_PostCreateRule_21626198; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_21626214.validator(path, query, header, formData, body, _)
  let scheme = call_21626214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626214.makeUrl(scheme.get, call_21626214.host, call_21626214.base,
                               call_21626214.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626214, uri, valid, _)

proc call*(call_21626215: Call_PostCreateRule_21626198; ListenerArn: string;
          Actions: JsonNode; Conditions: JsonNode; Priority: int;
          Action: string = "CreateRule"; Version: string = "2015-12-01"): Recallable =
  ## postCreateRule
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   Action: string (required)
  ##   Priority: int (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  ##   Version: string (required)
  var query_21626216 = newJObject()
  var formData_21626217 = newJObject()
  add(formData_21626217, "ListenerArn", newJString(ListenerArn))
  if Actions != nil:
    formData_21626217.add "Actions", Actions
  if Conditions != nil:
    formData_21626217.add "Conditions", Conditions
  add(query_21626216, "Action", newJString(Action))
  add(formData_21626217, "Priority", newJInt(Priority))
  add(query_21626216, "Version", newJString(Version))
  result = call_21626215.call(nil, query_21626216, nil, formData_21626217, nil)

var postCreateRule* = Call_PostCreateRule_21626198(name: "postCreateRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_PostCreateRule_21626199,
    base: "/", makeUrl: url_PostCreateRule_21626200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateRule_21626179 = ref object of OpenApiRestCall_21625435
proc url_GetCreateRule_21626181(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateRule_21626180(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   Action: JString (required)
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Priority: JInt (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Conditions` field"
  var valid_21626182 = query.getOrDefault("Conditions")
  valid_21626182 = validateParameter(valid_21626182, JArray, required = true,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "Conditions", valid_21626182
  var valid_21626183 = query.getOrDefault("Action")
  valid_21626183 = validateParameter(valid_21626183, JString, required = true,
                                   default = newJString("CreateRule"))
  if valid_21626183 != nil:
    section.add "Action", valid_21626183
  var valid_21626184 = query.getOrDefault("ListenerArn")
  valid_21626184 = validateParameter(valid_21626184, JString, required = true,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "ListenerArn", valid_21626184
  var valid_21626185 = query.getOrDefault("Actions")
  valid_21626185 = validateParameter(valid_21626185, JArray, required = true,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "Actions", valid_21626185
  var valid_21626186 = query.getOrDefault("Priority")
  valid_21626186 = validateParameter(valid_21626186, JInt, required = true,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "Priority", valid_21626186
  var valid_21626187 = query.getOrDefault("Version")
  valid_21626187 = validateParameter(valid_21626187, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626187 != nil:
    section.add "Version", valid_21626187
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626188 = header.getOrDefault("X-Amz-Date")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Date", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Security-Token", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Algorithm", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-Signature")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Signature", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Credential")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Credential", valid_21626194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626195: Call_GetCreateRule_21626179; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_21626195.validator(path, query, header, formData, body, _)
  let scheme = call_21626195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626195.makeUrl(scheme.get, call_21626195.host, call_21626195.base,
                               call_21626195.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626195, uri, valid, _)

proc call*(call_21626196: Call_GetCreateRule_21626179; Conditions: JsonNode;
          ListenerArn: string; Actions: JsonNode; Priority: int;
          Action: string = "CreateRule"; Version: string = "2015-12-01"): Recallable =
  ## getCreateRule
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   Action: string (required)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Priority: int (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  ##   Version: string (required)
  var query_21626197 = newJObject()
  if Conditions != nil:
    query_21626197.add "Conditions", Conditions
  add(query_21626197, "Action", newJString(Action))
  add(query_21626197, "ListenerArn", newJString(ListenerArn))
  if Actions != nil:
    query_21626197.add "Actions", Actions
  add(query_21626197, "Priority", newJInt(Priority))
  add(query_21626197, "Version", newJString(Version))
  result = call_21626196.call(nil, query_21626197, nil, nil, nil)

var getCreateRule* = Call_GetCreateRule_21626179(name: "getCreateRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_GetCreateRule_21626180,
    base: "/", makeUrl: url_GetCreateRule_21626181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTargetGroup_21626247 = ref object of OpenApiRestCall_21625435
proc url_PostCreateTargetGroup_21626249(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateTargetGroup_21626248(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626250 = query.getOrDefault("Action")
  valid_21626250 = validateParameter(valid_21626250, JString, required = true,
                                   default = newJString("CreateTargetGroup"))
  if valid_21626250 != nil:
    section.add "Action", valid_21626250
  var valid_21626251 = query.getOrDefault("Version")
  valid_21626251 = validateParameter(valid_21626251, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626251 != nil:
    section.add "Version", valid_21626251
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626252 = header.getOrDefault("X-Amz-Date")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-Date", valid_21626252
  var valid_21626253 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Security-Token", valid_21626253
  var valid_21626254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626254
  var valid_21626255 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-Algorithm", valid_21626255
  var valid_21626256 = header.getOrDefault("X-Amz-Signature")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Signature", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Credential")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Credential", valid_21626258
  result.add "header", section
  ## parameters in `formData` object:
  ##   Name: JString (required)
  ##       : <p>The name of the target group.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen.</p>
  ##   HealthCheckTimeoutSeconds: JInt
  ##                            : The amount of time, in seconds, during which no response from a target means a failed health check. For target groups with a protocol of HTTP or HTTPS, the default is 5 seconds. For target groups with a protocol of TCP or TLS, this value must be 6 seconds for HTTP health checks and 10 seconds for TCP and HTTPS health checks. If the target type is <code>lambda</code>, the default is 30 seconds.
  ##   Port: JInt
  ##       : The port on which the targets receive traffic. This port is used unless you specify a port override when registering the target. If the target is a Lambda function, this parameter does not apply.
  ##   Protocol: JString
  ##           : The protocol to use for routing traffic to the targets. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, or TCP_UDP. A TCP_UDP listener must be associated with a TCP_UDP target group. If the target is a Lambda function, this parameter does not apply.
  ##   HealthCheckPort: JString
  ##                  : The port the load balancer uses when performing health checks on targets. The default is <code>traffic-port</code>, which is the port on which each target receives traffic from the load balancer.
  ##   UnhealthyThresholdCount: JInt
  ##                          : The number of consecutive health check failures required before considering a target unhealthy. For target groups with a protocol of HTTP or HTTPS, the default is 2. For target groups with a protocol of TCP or TLS, this value must be the same as the healthy threshold count. If the target type is <code>lambda</code>, the default is 2.
  ##   HealthCheckEnabled: JBool
  ##                     : Indicates whether health checks are enabled. If the target type is <code>lambda</code>, health checks are disabled by default but can be enabled. If the target type is <code>instance</code> or <code>ip</code>, health checks are always enabled and cannot be disabled.
  ##   HealthCheckPath: JString
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination on the targets for health checks. The default is /.
  ##   TargetType: JString
  ##             : <p>The type of target that you must specify when registering targets with this target group. You can't specify targets for a target group using more than one target type.</p> <ul> <li> <p> <code>instance</code> - Targets are specified by instance ID. This is the default value. If the target group protocol is UDP or TCP_UDP, the target type must be <code>instance</code>.</p> </li> <li> <p> <code>ip</code> - Targets are specified by IP address. You can specify IP addresses from the subnets of the virtual private cloud (VPC) for the target group, the RFC 1918 range (10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16), and the RFC 6598 range (100.64.0.0/10). You can't specify publicly routable IP addresses.</p> </li> <li> <p> <code>lambda</code> - The target groups contains a single Lambda function.</p> </li> </ul>
  ##   VpcId: JString
  ##        : The identifier of the virtual private cloud (VPC). If the target is a Lambda function, this parameter does not apply. Otherwise, this parameter is required.
  ##   HealthCheckIntervalSeconds: JInt
  ##                             : The approximate amount of time, in seconds, between health checks of an individual target. For HTTP and HTTPS health checks, the range is 5–300 seconds. For TCP health checks, the supported values are 10 and 30 seconds. If the target type is <code>instance</code> or <code>ip</code>, the default is 30 seconds. If the target type is <code>lambda</code>, the default is 35 seconds.
  ##   HealthyThresholdCount: JInt
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy. For target groups with a protocol of HTTP or HTTPS, the default is 5. For target groups with a protocol of TCP or TLS, the default is 3. If the target type is <code>lambda</code>, the default is 5.
  ##   HealthCheckProtocol: JString
  ##                      : The protocol the load balancer uses when performing health checks on targets. For Application Load Balancers, the default is HTTP. For Network Load Balancers, the default is TCP. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.
  ##   Matcher.HttpCode: JString
  ##                   : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_21626259 = formData.getOrDefault("Name")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "Name", valid_21626259
  var valid_21626260 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_21626260 = validateParameter(valid_21626260, JInt, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_21626260
  var valid_21626261 = formData.getOrDefault("Port")
  valid_21626261 = validateParameter(valid_21626261, JInt, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "Port", valid_21626261
  var valid_21626262 = formData.getOrDefault("Protocol")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = newJString("HTTP"))
  if valid_21626262 != nil:
    section.add "Protocol", valid_21626262
  var valid_21626263 = formData.getOrDefault("HealthCheckPort")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "HealthCheckPort", valid_21626263
  var valid_21626264 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_21626264 = validateParameter(valid_21626264, JInt, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "UnhealthyThresholdCount", valid_21626264
  var valid_21626265 = formData.getOrDefault("HealthCheckEnabled")
  valid_21626265 = validateParameter(valid_21626265, JBool, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "HealthCheckEnabled", valid_21626265
  var valid_21626266 = formData.getOrDefault("HealthCheckPath")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "HealthCheckPath", valid_21626266
  var valid_21626267 = formData.getOrDefault("TargetType")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = newJString("instance"))
  if valid_21626267 != nil:
    section.add "TargetType", valid_21626267
  var valid_21626268 = formData.getOrDefault("VpcId")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "VpcId", valid_21626268
  var valid_21626269 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_21626269 = validateParameter(valid_21626269, JInt, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "HealthCheckIntervalSeconds", valid_21626269
  var valid_21626270 = formData.getOrDefault("HealthyThresholdCount")
  valid_21626270 = validateParameter(valid_21626270, JInt, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "HealthyThresholdCount", valid_21626270
  var valid_21626271 = formData.getOrDefault("HealthCheckProtocol")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = newJString("HTTP"))
  if valid_21626271 != nil:
    section.add "HealthCheckProtocol", valid_21626271
  var valid_21626272 = formData.getOrDefault("Matcher.HttpCode")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "Matcher.HttpCode", valid_21626272
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626273: Call_PostCreateTargetGroup_21626247;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626273.validator(path, query, header, formData, body, _)
  let scheme = call_21626273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626273.makeUrl(scheme.get, call_21626273.host, call_21626273.base,
                               call_21626273.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626273, uri, valid, _)

proc call*(call_21626274: Call_PostCreateTargetGroup_21626247; Name: string;
          HealthCheckTimeoutSeconds: int = 0; Port: int = 0; Protocol: string = "HTTP";
          HealthCheckPort: string = ""; UnhealthyThresholdCount: int = 0;
          HealthCheckEnabled: bool = false; HealthCheckPath: string = "";
          TargetType: string = "instance"; Action: string = "CreateTargetGroup";
          VpcId: string = ""; HealthCheckIntervalSeconds: int = 0;
          HealthyThresholdCount: int = 0; HealthCheckProtocol: string = "HTTP";
          MatcherHttpCode: string = ""; Version: string = "2015-12-01"): Recallable =
  ## postCreateTargetGroup
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Name: string (required)
  ##       : <p>The name of the target group.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen.</p>
  ##   HealthCheckTimeoutSeconds: int
  ##                            : The amount of time, in seconds, during which no response from a target means a failed health check. For target groups with a protocol of HTTP or HTTPS, the default is 5 seconds. For target groups with a protocol of TCP or TLS, this value must be 6 seconds for HTTP health checks and 10 seconds for TCP and HTTPS health checks. If the target type is <code>lambda</code>, the default is 30 seconds.
  ##   Port: int
  ##       : The port on which the targets receive traffic. This port is used unless you specify a port override when registering the target. If the target is a Lambda function, this parameter does not apply.
  ##   Protocol: string
  ##           : The protocol to use for routing traffic to the targets. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, or TCP_UDP. A TCP_UDP listener must be associated with a TCP_UDP target group. If the target is a Lambda function, this parameter does not apply.
  ##   HealthCheckPort: string
  ##                  : The port the load balancer uses when performing health checks on targets. The default is <code>traffic-port</code>, which is the port on which each target receives traffic from the load balancer.
  ##   UnhealthyThresholdCount: int
  ##                          : The number of consecutive health check failures required before considering a target unhealthy. For target groups with a protocol of HTTP or HTTPS, the default is 2. For target groups with a protocol of TCP or TLS, this value must be the same as the healthy threshold count. If the target type is <code>lambda</code>, the default is 2.
  ##   HealthCheckEnabled: bool
  ##                     : Indicates whether health checks are enabled. If the target type is <code>lambda</code>, health checks are disabled by default but can be enabled. If the target type is <code>instance</code> or <code>ip</code>, health checks are always enabled and cannot be disabled.
  ##   HealthCheckPath: string
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination on the targets for health checks. The default is /.
  ##   TargetType: string
  ##             : <p>The type of target that you must specify when registering targets with this target group. You can't specify targets for a target group using more than one target type.</p> <ul> <li> <p> <code>instance</code> - Targets are specified by instance ID. This is the default value. If the target group protocol is UDP or TCP_UDP, the target type must be <code>instance</code>.</p> </li> <li> <p> <code>ip</code> - Targets are specified by IP address. You can specify IP addresses from the subnets of the virtual private cloud (VPC) for the target group, the RFC 1918 range (10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16), and the RFC 6598 range (100.64.0.0/10). You can't specify publicly routable IP addresses.</p> </li> <li> <p> <code>lambda</code> - The target groups contains a single Lambda function.</p> </li> </ul>
  ##   Action: string (required)
  ##   VpcId: string
  ##        : The identifier of the virtual private cloud (VPC). If the target is a Lambda function, this parameter does not apply. Otherwise, this parameter is required.
  ##   HealthCheckIntervalSeconds: int
  ##                             : The approximate amount of time, in seconds, between health checks of an individual target. For HTTP and HTTPS health checks, the range is 5–300 seconds. For TCP health checks, the supported values are 10 and 30 seconds. If the target type is <code>instance</code> or <code>ip</code>, the default is 30 seconds. If the target type is <code>lambda</code>, the default is 35 seconds.
  ##   HealthyThresholdCount: int
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy. For target groups with a protocol of HTTP or HTTPS, the default is 5. For target groups with a protocol of TCP or TLS, the default is 3. If the target type is <code>lambda</code>, the default is 5.
  ##   HealthCheckProtocol: string
  ##                      : The protocol the load balancer uses when performing health checks on targets. For Application Load Balancers, the default is HTTP. For Network Load Balancers, the default is TCP. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.
  ##   MatcherHttpCode: string
  ##                  : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   Version: string (required)
  var query_21626275 = newJObject()
  var formData_21626276 = newJObject()
  add(formData_21626276, "Name", newJString(Name))
  add(formData_21626276, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_21626276, "Port", newJInt(Port))
  add(formData_21626276, "Protocol", newJString(Protocol))
  add(formData_21626276, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_21626276, "UnhealthyThresholdCount",
      newJInt(UnhealthyThresholdCount))
  add(formData_21626276, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_21626276, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_21626276, "TargetType", newJString(TargetType))
  add(query_21626275, "Action", newJString(Action))
  add(formData_21626276, "VpcId", newJString(VpcId))
  add(formData_21626276, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_21626276, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_21626276, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_21626276, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_21626275, "Version", newJString(Version))
  result = call_21626274.call(nil, query_21626275, nil, formData_21626276, nil)

var postCreateTargetGroup* = Call_PostCreateTargetGroup_21626247(
    name: "postCreateTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup",
    validator: validate_PostCreateTargetGroup_21626248, base: "/",
    makeUrl: url_PostCreateTargetGroup_21626249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTargetGroup_21626218 = ref object of OpenApiRestCall_21625435
proc url_GetCreateTargetGroup_21626220(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateTargetGroup_21626219(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   HealthCheckEnabled: JBool
  ##                     : Indicates whether health checks are enabled. If the target type is <code>lambda</code>, health checks are disabled by default but can be enabled. If the target type is <code>instance</code> or <code>ip</code>, health checks are always enabled and cannot be disabled.
  ##   HealthCheckIntervalSeconds: JInt
  ##                             : The approximate amount of time, in seconds, between health checks of an individual target. For HTTP and HTTPS health checks, the range is 5–300 seconds. For TCP health checks, the supported values are 10 and 30 seconds. If the target type is <code>instance</code> or <code>ip</code>, the default is 30 seconds. If the target type is <code>lambda</code>, the default is 35 seconds.
  ##   Name: JString (required)
  ##       : <p>The name of the target group.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen.</p>
  ##   HealthCheckPort: JString
  ##                  : The port the load balancer uses when performing health checks on targets. The default is <code>traffic-port</code>, which is the port on which each target receives traffic from the load balancer.
  ##   Protocol: JString
  ##           : The protocol to use for routing traffic to the targets. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, or TCP_UDP. A TCP_UDP listener must be associated with a TCP_UDP target group. If the target is a Lambda function, this parameter does not apply.
  ##   VpcId: JString
  ##        : The identifier of the virtual private cloud (VPC). If the target is a Lambda function, this parameter does not apply. Otherwise, this parameter is required.
  ##   Action: JString (required)
  ##   HealthCheckTimeoutSeconds: JInt
  ##                            : The amount of time, in seconds, during which no response from a target means a failed health check. For target groups with a protocol of HTTP or HTTPS, the default is 5 seconds. For target groups with a protocol of TCP or TLS, this value must be 6 seconds for HTTP health checks and 10 seconds for TCP and HTTPS health checks. If the target type is <code>lambda</code>, the default is 30 seconds.
  ##   Matcher.HttpCode: JString
  ##                   : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   UnhealthyThresholdCount: JInt
  ##                          : The number of consecutive health check failures required before considering a target unhealthy. For target groups with a protocol of HTTP or HTTPS, the default is 2. For target groups with a protocol of TCP or TLS, this value must be the same as the healthy threshold count. If the target type is <code>lambda</code>, the default is 2.
  ##   TargetType: JString
  ##             : <p>The type of target that you must specify when registering targets with this target group. You can't specify targets for a target group using more than one target type.</p> <ul> <li> <p> <code>instance</code> - Targets are specified by instance ID. This is the default value. If the target group protocol is UDP or TCP_UDP, the target type must be <code>instance</code>.</p> </li> <li> <p> <code>ip</code> - Targets are specified by IP address. You can specify IP addresses from the subnets of the virtual private cloud (VPC) for the target group, the RFC 1918 range (10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16), and the RFC 6598 range (100.64.0.0/10). You can't specify publicly routable IP addresses.</p> </li> <li> <p> <code>lambda</code> - The target groups contains a single Lambda function.</p> </li> </ul>
  ##   Port: JInt
  ##       : The port on which the targets receive traffic. This port is used unless you specify a port override when registering the target. If the target is a Lambda function, this parameter does not apply.
  ##   HealthCheckProtocol: JString
  ##                      : The protocol the load balancer uses when performing health checks on targets. For Application Load Balancers, the default is HTTP. For Network Load Balancers, the default is TCP. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.
  ##   HealthyThresholdCount: JInt
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy. For target groups with a protocol of HTTP or HTTPS, the default is 5. For target groups with a protocol of TCP or TLS, the default is 3. If the target type is <code>lambda</code>, the default is 5.
  ##   Version: JString (required)
  ##   HealthCheckPath: JString
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination on the targets for health checks. The default is /.
  section = newJObject()
  var valid_21626221 = query.getOrDefault("HealthCheckEnabled")
  valid_21626221 = validateParameter(valid_21626221, JBool, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "HealthCheckEnabled", valid_21626221
  var valid_21626222 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_21626222 = validateParameter(valid_21626222, JInt, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "HealthCheckIntervalSeconds", valid_21626222
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_21626223 = query.getOrDefault("Name")
  valid_21626223 = validateParameter(valid_21626223, JString, required = true,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "Name", valid_21626223
  var valid_21626224 = query.getOrDefault("HealthCheckPort")
  valid_21626224 = validateParameter(valid_21626224, JString, required = false,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "HealthCheckPort", valid_21626224
  var valid_21626225 = query.getOrDefault("Protocol")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = newJString("HTTP"))
  if valid_21626225 != nil:
    section.add "Protocol", valid_21626225
  var valid_21626226 = query.getOrDefault("VpcId")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "VpcId", valid_21626226
  var valid_21626227 = query.getOrDefault("Action")
  valid_21626227 = validateParameter(valid_21626227, JString, required = true,
                                   default = newJString("CreateTargetGroup"))
  if valid_21626227 != nil:
    section.add "Action", valid_21626227
  var valid_21626228 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_21626228 = validateParameter(valid_21626228, JInt, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_21626228
  var valid_21626229 = query.getOrDefault("Matcher.HttpCode")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "Matcher.HttpCode", valid_21626229
  var valid_21626230 = query.getOrDefault("UnhealthyThresholdCount")
  valid_21626230 = validateParameter(valid_21626230, JInt, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "UnhealthyThresholdCount", valid_21626230
  var valid_21626231 = query.getOrDefault("TargetType")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = newJString("instance"))
  if valid_21626231 != nil:
    section.add "TargetType", valid_21626231
  var valid_21626232 = query.getOrDefault("Port")
  valid_21626232 = validateParameter(valid_21626232, JInt, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "Port", valid_21626232
  var valid_21626233 = query.getOrDefault("HealthCheckProtocol")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = newJString("HTTP"))
  if valid_21626233 != nil:
    section.add "HealthCheckProtocol", valid_21626233
  var valid_21626234 = query.getOrDefault("HealthyThresholdCount")
  valid_21626234 = validateParameter(valid_21626234, JInt, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "HealthyThresholdCount", valid_21626234
  var valid_21626235 = query.getOrDefault("Version")
  valid_21626235 = validateParameter(valid_21626235, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626235 != nil:
    section.add "Version", valid_21626235
  var valid_21626236 = query.getOrDefault("HealthCheckPath")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "HealthCheckPath", valid_21626236
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626237 = header.getOrDefault("X-Amz-Date")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-Date", valid_21626237
  var valid_21626238 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "X-Amz-Security-Token", valid_21626238
  var valid_21626239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626239 = validateParameter(valid_21626239, JString, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626239
  var valid_21626240 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "X-Amz-Algorithm", valid_21626240
  var valid_21626241 = header.getOrDefault("X-Amz-Signature")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "X-Amz-Signature", valid_21626241
  var valid_21626242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Credential")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Credential", valid_21626243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626244: Call_GetCreateTargetGroup_21626218; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626244.validator(path, query, header, formData, body, _)
  let scheme = call_21626244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626244.makeUrl(scheme.get, call_21626244.host, call_21626244.base,
                               call_21626244.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626244, uri, valid, _)

proc call*(call_21626245: Call_GetCreateTargetGroup_21626218; Name: string;
          HealthCheckEnabled: bool = false; HealthCheckIntervalSeconds: int = 0;
          HealthCheckPort: string = ""; Protocol: string = "HTTP"; VpcId: string = "";
          Action: string = "CreateTargetGroup"; HealthCheckTimeoutSeconds: int = 0;
          MatcherHttpCode: string = ""; UnhealthyThresholdCount: int = 0;
          TargetType: string = "instance"; Port: int = 0;
          HealthCheckProtocol: string = "HTTP"; HealthyThresholdCount: int = 0;
          Version: string = "2015-12-01"; HealthCheckPath: string = ""): Recallable =
  ## getCreateTargetGroup
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   HealthCheckEnabled: bool
  ##                     : Indicates whether health checks are enabled. If the target type is <code>lambda</code>, health checks are disabled by default but can be enabled. If the target type is <code>instance</code> or <code>ip</code>, health checks are always enabled and cannot be disabled.
  ##   HealthCheckIntervalSeconds: int
  ##                             : The approximate amount of time, in seconds, between health checks of an individual target. For HTTP and HTTPS health checks, the range is 5–300 seconds. For TCP health checks, the supported values are 10 and 30 seconds. If the target type is <code>instance</code> or <code>ip</code>, the default is 30 seconds. If the target type is <code>lambda</code>, the default is 35 seconds.
  ##   Name: string (required)
  ##       : <p>The name of the target group.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen.</p>
  ##   HealthCheckPort: string
  ##                  : The port the load balancer uses when performing health checks on targets. The default is <code>traffic-port</code>, which is the port on which each target receives traffic from the load balancer.
  ##   Protocol: string
  ##           : The protocol to use for routing traffic to the targets. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, or TCP_UDP. A TCP_UDP listener must be associated with a TCP_UDP target group. If the target is a Lambda function, this parameter does not apply.
  ##   VpcId: string
  ##        : The identifier of the virtual private cloud (VPC). If the target is a Lambda function, this parameter does not apply. Otherwise, this parameter is required.
  ##   Action: string (required)
  ##   HealthCheckTimeoutSeconds: int
  ##                            : The amount of time, in seconds, during which no response from a target means a failed health check. For target groups with a protocol of HTTP or HTTPS, the default is 5 seconds. For target groups with a protocol of TCP or TLS, this value must be 6 seconds for HTTP health checks and 10 seconds for TCP and HTTPS health checks. If the target type is <code>lambda</code>, the default is 30 seconds.
  ##   MatcherHttpCode: string
  ##                  : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   UnhealthyThresholdCount: int
  ##                          : The number of consecutive health check failures required before considering a target unhealthy. For target groups with a protocol of HTTP or HTTPS, the default is 2. For target groups with a protocol of TCP or TLS, this value must be the same as the healthy threshold count. If the target type is <code>lambda</code>, the default is 2.
  ##   TargetType: string
  ##             : <p>The type of target that you must specify when registering targets with this target group. You can't specify targets for a target group using more than one target type.</p> <ul> <li> <p> <code>instance</code> - Targets are specified by instance ID. This is the default value. If the target group protocol is UDP or TCP_UDP, the target type must be <code>instance</code>.</p> </li> <li> <p> <code>ip</code> - Targets are specified by IP address. You can specify IP addresses from the subnets of the virtual private cloud (VPC) for the target group, the RFC 1918 range (10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16), and the RFC 6598 range (100.64.0.0/10). You can't specify publicly routable IP addresses.</p> </li> <li> <p> <code>lambda</code> - The target groups contains a single Lambda function.</p> </li> </ul>
  ##   Port: int
  ##       : The port on which the targets receive traffic. This port is used unless you specify a port override when registering the target. If the target is a Lambda function, this parameter does not apply.
  ##   HealthCheckProtocol: string
  ##                      : The protocol the load balancer uses when performing health checks on targets. For Application Load Balancers, the default is HTTP. For Network Load Balancers, the default is TCP. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.
  ##   HealthyThresholdCount: int
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy. For target groups with a protocol of HTTP or HTTPS, the default is 5. For target groups with a protocol of TCP or TLS, the default is 3. If the target type is <code>lambda</code>, the default is 5.
  ##   Version: string (required)
  ##   HealthCheckPath: string
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination on the targets for health checks. The default is /.
  var query_21626246 = newJObject()
  add(query_21626246, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_21626246, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_21626246, "Name", newJString(Name))
  add(query_21626246, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_21626246, "Protocol", newJString(Protocol))
  add(query_21626246, "VpcId", newJString(VpcId))
  add(query_21626246, "Action", newJString(Action))
  add(query_21626246, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_21626246, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_21626246, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_21626246, "TargetType", newJString(TargetType))
  add(query_21626246, "Port", newJInt(Port))
  add(query_21626246, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_21626246, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_21626246, "Version", newJString(Version))
  add(query_21626246, "HealthCheckPath", newJString(HealthCheckPath))
  result = call_21626245.call(nil, query_21626246, nil, nil, nil)

var getCreateTargetGroup* = Call_GetCreateTargetGroup_21626218(
    name: "getCreateTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup", validator: validate_GetCreateTargetGroup_21626219,
    base: "/", makeUrl: url_GetCreateTargetGroup_21626220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteListener_21626293 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteListener_21626295(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteListener_21626294(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626296 = query.getOrDefault("Action")
  valid_21626296 = validateParameter(valid_21626296, JString, required = true,
                                   default = newJString("DeleteListener"))
  if valid_21626296 != nil:
    section.add "Action", valid_21626296
  var valid_21626297 = query.getOrDefault("Version")
  valid_21626297 = validateParameter(valid_21626297, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626297 != nil:
    section.add "Version", valid_21626297
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626298 = header.getOrDefault("X-Amz-Date")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Date", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Security-Token", valid_21626299
  var valid_21626300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626300
  var valid_21626301 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Algorithm", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-Signature")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Signature", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Credential")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Credential", valid_21626304
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_21626305 = formData.getOrDefault("ListenerArn")
  valid_21626305 = validateParameter(valid_21626305, JString, required = true,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "ListenerArn", valid_21626305
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626306: Call_PostDeleteListener_21626293; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_21626306.validator(path, query, header, formData, body, _)
  let scheme = call_21626306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626306.makeUrl(scheme.get, call_21626306.host, call_21626306.base,
                               call_21626306.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626306, uri, valid, _)

proc call*(call_21626307: Call_PostDeleteListener_21626293; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626308 = newJObject()
  var formData_21626309 = newJObject()
  add(formData_21626309, "ListenerArn", newJString(ListenerArn))
  add(query_21626308, "Action", newJString(Action))
  add(query_21626308, "Version", newJString(Version))
  result = call_21626307.call(nil, query_21626308, nil, formData_21626309, nil)

var postDeleteListener* = Call_PostDeleteListener_21626293(
    name: "postDeleteListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=DeleteListener",
    validator: validate_PostDeleteListener_21626294, base: "/",
    makeUrl: url_PostDeleteListener_21626295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteListener_21626277 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteListener_21626279(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteListener_21626278(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626280 = query.getOrDefault("Action")
  valid_21626280 = validateParameter(valid_21626280, JString, required = true,
                                   default = newJString("DeleteListener"))
  if valid_21626280 != nil:
    section.add "Action", valid_21626280
  var valid_21626281 = query.getOrDefault("ListenerArn")
  valid_21626281 = validateParameter(valid_21626281, JString, required = true,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "ListenerArn", valid_21626281
  var valid_21626282 = query.getOrDefault("Version")
  valid_21626282 = validateParameter(valid_21626282, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626282 != nil:
    section.add "Version", valid_21626282
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626283 = header.getOrDefault("X-Amz-Date")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Date", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Security-Token", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Algorithm", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-Signature")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Signature", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Credential")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Credential", valid_21626289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626290: Call_GetDeleteListener_21626277; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_21626290.validator(path, query, header, formData, body, _)
  let scheme = call_21626290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626290.makeUrl(scheme.get, call_21626290.host, call_21626290.base,
                               call_21626290.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626290, uri, valid, _)

proc call*(call_21626291: Call_GetDeleteListener_21626277; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   Action: string (required)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: string (required)
  var query_21626292 = newJObject()
  add(query_21626292, "Action", newJString(Action))
  add(query_21626292, "ListenerArn", newJString(ListenerArn))
  add(query_21626292, "Version", newJString(Version))
  result = call_21626291.call(nil, query_21626292, nil, nil, nil)

var getDeleteListener* = Call_GetDeleteListener_21626277(name: "getDeleteListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteListener", validator: validate_GetDeleteListener_21626278,
    base: "/", makeUrl: url_GetDeleteListener_21626279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_21626326 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteLoadBalancer_21626328(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteLoadBalancer_21626327(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626329 = query.getOrDefault("Action")
  valid_21626329 = validateParameter(valid_21626329, JString, required = true,
                                   default = newJString("DeleteLoadBalancer"))
  if valid_21626329 != nil:
    section.add "Action", valid_21626329
  var valid_21626330 = query.getOrDefault("Version")
  valid_21626330 = validateParameter(valid_21626330, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626330 != nil:
    section.add "Version", valid_21626330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626331 = header.getOrDefault("X-Amz-Date")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "X-Amz-Date", valid_21626331
  var valid_21626332 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Security-Token", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Algorithm", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Signature")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Signature", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Credential")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Credential", valid_21626337
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_21626338 = formData.getOrDefault("LoadBalancerArn")
  valid_21626338 = validateParameter(valid_21626338, JString, required = true,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "LoadBalancerArn", valid_21626338
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626339: Call_PostDeleteLoadBalancer_21626326;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_21626339.validator(path, query, header, formData, body, _)
  let scheme = call_21626339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626339.makeUrl(scheme.get, call_21626339.host, call_21626339.base,
                               call_21626339.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626339, uri, valid, _)

proc call*(call_21626340: Call_PostDeleteLoadBalancer_21626326;
          LoadBalancerArn: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2015-12-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626341 = newJObject()
  var formData_21626342 = newJObject()
  add(formData_21626342, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_21626341, "Action", newJString(Action))
  add(query_21626341, "Version", newJString(Version))
  result = call_21626340.call(nil, query_21626341, nil, formData_21626342, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_21626326(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_21626327, base: "/",
    makeUrl: url_PostDeleteLoadBalancer_21626328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_21626310 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteLoadBalancer_21626312(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteLoadBalancer_21626311(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626313 = query.getOrDefault("Action")
  valid_21626313 = validateParameter(valid_21626313, JString, required = true,
                                   default = newJString("DeleteLoadBalancer"))
  if valid_21626313 != nil:
    section.add "Action", valid_21626313
  var valid_21626314 = query.getOrDefault("LoadBalancerArn")
  valid_21626314 = validateParameter(valid_21626314, JString, required = true,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "LoadBalancerArn", valid_21626314
  var valid_21626315 = query.getOrDefault("Version")
  valid_21626315 = validateParameter(valid_21626315, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626315 != nil:
    section.add "Version", valid_21626315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626316 = header.getOrDefault("X-Amz-Date")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Date", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Security-Token", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Algorithm", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Signature")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Signature", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Credential")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Credential", valid_21626322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626323: Call_GetDeleteLoadBalancer_21626310;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_21626323.validator(path, query, header, formData, body, _)
  let scheme = call_21626323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626323.makeUrl(scheme.get, call_21626323.host, call_21626323.base,
                               call_21626323.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626323, uri, valid, _)

proc call*(call_21626324: Call_GetDeleteLoadBalancer_21626310;
          LoadBalancerArn: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2015-12-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_21626325 = newJObject()
  add(query_21626325, "Action", newJString(Action))
  add(query_21626325, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_21626325, "Version", newJString(Version))
  result = call_21626324.call(nil, query_21626325, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_21626310(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_21626311, base: "/",
    makeUrl: url_GetDeleteLoadBalancer_21626312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRule_21626359 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteRule_21626361(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteRule_21626360(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626362 = query.getOrDefault("Action")
  valid_21626362 = validateParameter(valid_21626362, JString, required = true,
                                   default = newJString("DeleteRule"))
  if valid_21626362 != nil:
    section.add "Action", valid_21626362
  var valid_21626363 = query.getOrDefault("Version")
  valid_21626363 = validateParameter(valid_21626363, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626363 != nil:
    section.add "Version", valid_21626363
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626364 = header.getOrDefault("X-Amz-Date")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Date", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Security-Token", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Algorithm", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Signature")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Signature", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-Credential")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Credential", valid_21626370
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_21626371 = formData.getOrDefault("RuleArn")
  valid_21626371 = validateParameter(valid_21626371, JString, required = true,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "RuleArn", valid_21626371
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626372: Call_PostDeleteRule_21626359; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_21626372.validator(path, query, header, formData, body, _)
  let scheme = call_21626372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626372.makeUrl(scheme.get, call_21626372.host, call_21626372.base,
                               call_21626372.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626372, uri, valid, _)

proc call*(call_21626373: Call_PostDeleteRule_21626359; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626374 = newJObject()
  var formData_21626375 = newJObject()
  add(formData_21626375, "RuleArn", newJString(RuleArn))
  add(query_21626374, "Action", newJString(Action))
  add(query_21626374, "Version", newJString(Version))
  result = call_21626373.call(nil, query_21626374, nil, formData_21626375, nil)

var postDeleteRule* = Call_PostDeleteRule_21626359(name: "postDeleteRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_PostDeleteRule_21626360,
    base: "/", makeUrl: url_PostDeleteRule_21626361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRule_21626343 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteRule_21626345(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteRule_21626344(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the specified rule.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626346 = query.getOrDefault("Action")
  valid_21626346 = validateParameter(valid_21626346, JString, required = true,
                                   default = newJString("DeleteRule"))
  if valid_21626346 != nil:
    section.add "Action", valid_21626346
  var valid_21626347 = query.getOrDefault("RuleArn")
  valid_21626347 = validateParameter(valid_21626347, JString, required = true,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "RuleArn", valid_21626347
  var valid_21626348 = query.getOrDefault("Version")
  valid_21626348 = validateParameter(valid_21626348, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626348 != nil:
    section.add "Version", valid_21626348
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626349 = header.getOrDefault("X-Amz-Date")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Date", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Security-Token", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Algorithm", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Signature")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Signature", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-Credential")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-Credential", valid_21626355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626356: Call_GetDeleteRule_21626343; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_21626356.validator(path, query, header, formData, body, _)
  let scheme = call_21626356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626356.makeUrl(scheme.get, call_21626356.host, call_21626356.base,
                               call_21626356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626356, uri, valid, _)

proc call*(call_21626357: Call_GetDeleteRule_21626343; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteRule
  ## Deletes the specified rule.
  ##   Action: string (required)
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Version: string (required)
  var query_21626358 = newJObject()
  add(query_21626358, "Action", newJString(Action))
  add(query_21626358, "RuleArn", newJString(RuleArn))
  add(query_21626358, "Version", newJString(Version))
  result = call_21626357.call(nil, query_21626358, nil, nil, nil)

var getDeleteRule* = Call_GetDeleteRule_21626343(name: "getDeleteRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_GetDeleteRule_21626344,
    base: "/", makeUrl: url_GetDeleteRule_21626345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTargetGroup_21626392 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteTargetGroup_21626394(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteTargetGroup_21626393(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626395 = query.getOrDefault("Action")
  valid_21626395 = validateParameter(valid_21626395, JString, required = true,
                                   default = newJString("DeleteTargetGroup"))
  if valid_21626395 != nil:
    section.add "Action", valid_21626395
  var valid_21626396 = query.getOrDefault("Version")
  valid_21626396 = validateParameter(valid_21626396, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626396 != nil:
    section.add "Version", valid_21626396
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626397 = header.getOrDefault("X-Amz-Date")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Date", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Security-Token", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Algorithm", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-Signature")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Signature", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-Credential")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Credential", valid_21626403
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_21626404 = formData.getOrDefault("TargetGroupArn")
  valid_21626404 = validateParameter(valid_21626404, JString, required = true,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "TargetGroupArn", valid_21626404
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626405: Call_PostDeleteTargetGroup_21626392;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_21626405.validator(path, query, header, formData, body, _)
  let scheme = call_21626405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626405.makeUrl(scheme.get, call_21626405.host, call_21626405.base,
                               call_21626405.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626405, uri, valid, _)

proc call*(call_21626406: Call_PostDeleteTargetGroup_21626392;
          TargetGroupArn: string; Action: string = "DeleteTargetGroup";
          Version: string = "2015-12-01"): Recallable =
  ## postDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_21626407 = newJObject()
  var formData_21626408 = newJObject()
  add(query_21626407, "Action", newJString(Action))
  add(formData_21626408, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_21626407, "Version", newJString(Version))
  result = call_21626406.call(nil, query_21626407, nil, formData_21626408, nil)

var postDeleteTargetGroup* = Call_PostDeleteTargetGroup_21626392(
    name: "postDeleteTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup",
    validator: validate_PostDeleteTargetGroup_21626393, base: "/",
    makeUrl: url_PostDeleteTargetGroup_21626394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTargetGroup_21626376 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteTargetGroup_21626378(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteTargetGroup_21626377(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626379 = query.getOrDefault("TargetGroupArn")
  valid_21626379 = validateParameter(valid_21626379, JString, required = true,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "TargetGroupArn", valid_21626379
  var valid_21626380 = query.getOrDefault("Action")
  valid_21626380 = validateParameter(valid_21626380, JString, required = true,
                                   default = newJString("DeleteTargetGroup"))
  if valid_21626380 != nil:
    section.add "Action", valid_21626380
  var valid_21626381 = query.getOrDefault("Version")
  valid_21626381 = validateParameter(valid_21626381, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626381 != nil:
    section.add "Version", valid_21626381
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626382 = header.getOrDefault("X-Amz-Date")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Date", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Security-Token", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Algorithm", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Signature")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Signature", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626387
  var valid_21626388 = header.getOrDefault("X-Amz-Credential")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-Credential", valid_21626388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626389: Call_GetDeleteTargetGroup_21626376; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_21626389.validator(path, query, header, formData, body, _)
  let scheme = call_21626389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626389.makeUrl(scheme.get, call_21626389.host, call_21626389.base,
                               call_21626389.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626389, uri, valid, _)

proc call*(call_21626390: Call_GetDeleteTargetGroup_21626376;
          TargetGroupArn: string; Action: string = "DeleteTargetGroup";
          Version: string = "2015-12-01"): Recallable =
  ## getDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626391 = newJObject()
  add(query_21626391, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_21626391, "Action", newJString(Action))
  add(query_21626391, "Version", newJString(Version))
  result = call_21626390.call(nil, query_21626391, nil, nil, nil)

var getDeleteTargetGroup* = Call_GetDeleteTargetGroup_21626376(
    name: "getDeleteTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup", validator: validate_GetDeleteTargetGroup_21626377,
    base: "/", makeUrl: url_GetDeleteTargetGroup_21626378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterTargets_21626426 = ref object of OpenApiRestCall_21625435
proc url_PostDeregisterTargets_21626428(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeregisterTargets_21626427(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626429 = query.getOrDefault("Action")
  valid_21626429 = validateParameter(valid_21626429, JString, required = true,
                                   default = newJString("DeregisterTargets"))
  if valid_21626429 != nil:
    section.add "Action", valid_21626429
  var valid_21626430 = query.getOrDefault("Version")
  valid_21626430 = validateParameter(valid_21626430, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626430 != nil:
    section.add "Version", valid_21626430
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626431 = header.getOrDefault("X-Amz-Date")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Date", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Security-Token", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Algorithm", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-Signature")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Signature", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-Credential")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Credential", valid_21626437
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_21626438 = formData.getOrDefault("Targets")
  valid_21626438 = validateParameter(valid_21626438, JArray, required = true,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "Targets", valid_21626438
  var valid_21626439 = formData.getOrDefault("TargetGroupArn")
  valid_21626439 = validateParameter(valid_21626439, JString, required = true,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "TargetGroupArn", valid_21626439
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626440: Call_PostDeregisterTargets_21626426;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_21626440.validator(path, query, header, formData, body, _)
  let scheme = call_21626440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626440.makeUrl(scheme.get, call_21626440.host, call_21626440.base,
                               call_21626440.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626440, uri, valid, _)

proc call*(call_21626441: Call_PostDeregisterTargets_21626426; Targets: JsonNode;
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
  var query_21626442 = newJObject()
  var formData_21626443 = newJObject()
  if Targets != nil:
    formData_21626443.add "Targets", Targets
  add(query_21626442, "Action", newJString(Action))
  add(formData_21626443, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_21626442, "Version", newJString(Version))
  result = call_21626441.call(nil, query_21626442, nil, formData_21626443, nil)

var postDeregisterTargets* = Call_PostDeregisterTargets_21626426(
    name: "postDeregisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets",
    validator: validate_PostDeregisterTargets_21626427, base: "/",
    makeUrl: url_PostDeregisterTargets_21626428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterTargets_21626409 = ref object of OpenApiRestCall_21625435
proc url_GetDeregisterTargets_21626411(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeregisterTargets_21626410(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626412 = query.getOrDefault("Targets")
  valid_21626412 = validateParameter(valid_21626412, JArray, required = true,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "Targets", valid_21626412
  var valid_21626413 = query.getOrDefault("TargetGroupArn")
  valid_21626413 = validateParameter(valid_21626413, JString, required = true,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "TargetGroupArn", valid_21626413
  var valid_21626414 = query.getOrDefault("Action")
  valid_21626414 = validateParameter(valid_21626414, JString, required = true,
                                   default = newJString("DeregisterTargets"))
  if valid_21626414 != nil:
    section.add "Action", valid_21626414
  var valid_21626415 = query.getOrDefault("Version")
  valid_21626415 = validateParameter(valid_21626415, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626415 != nil:
    section.add "Version", valid_21626415
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626416 = header.getOrDefault("X-Amz-Date")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-Date", valid_21626416
  var valid_21626417 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Security-Token", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "X-Amz-Algorithm", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-Signature")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Signature", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-Credential")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Credential", valid_21626422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626423: Call_GetDeregisterTargets_21626409; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_21626423.validator(path, query, header, formData, body, _)
  let scheme = call_21626423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626423.makeUrl(scheme.get, call_21626423.host, call_21626423.base,
                               call_21626423.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626423, uri, valid, _)

proc call*(call_21626424: Call_GetDeregisterTargets_21626409; Targets: JsonNode;
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
  var query_21626425 = newJObject()
  if Targets != nil:
    query_21626425.add "Targets", Targets
  add(query_21626425, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_21626425, "Action", newJString(Action))
  add(query_21626425, "Version", newJString(Version))
  result = call_21626424.call(nil, query_21626425, nil, nil, nil)

var getDeregisterTargets* = Call_GetDeregisterTargets_21626409(
    name: "getDeregisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets", validator: validate_GetDeregisterTargets_21626410,
    base: "/", makeUrl: url_GetDeregisterTargets_21626411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_21626461 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeAccountLimits_21626463(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAccountLimits_21626462(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626464 = query.getOrDefault("Action")
  valid_21626464 = validateParameter(valid_21626464, JString, required = true, default = newJString(
      "DescribeAccountLimits"))
  if valid_21626464 != nil:
    section.add "Action", valid_21626464
  var valid_21626465 = query.getOrDefault("Version")
  valid_21626465 = validateParameter(valid_21626465, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626465 != nil:
    section.add "Version", valid_21626465
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626466 = header.getOrDefault("X-Amz-Date")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-Date", valid_21626466
  var valid_21626467 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Security-Token", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Algorithm", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Signature")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Signature", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Credential")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Credential", valid_21626472
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_21626473 = formData.getOrDefault("Marker")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "Marker", valid_21626473
  var valid_21626474 = formData.getOrDefault("PageSize")
  valid_21626474 = validateParameter(valid_21626474, JInt, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "PageSize", valid_21626474
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626475: Call_PostDescribeAccountLimits_21626461;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626475.validator(path, query, header, formData, body, _)
  let scheme = call_21626475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626475.makeUrl(scheme.get, call_21626475.host, call_21626475.base,
                               call_21626475.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626475, uri, valid, _)

proc call*(call_21626476: Call_PostDescribeAccountLimits_21626461;
          Marker: string = ""; Action: string = "DescribeAccountLimits";
          PageSize: int = 0; Version: string = "2015-12-01"): Recallable =
  ## postDescribeAccountLimits
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_21626477 = newJObject()
  var formData_21626478 = newJObject()
  add(formData_21626478, "Marker", newJString(Marker))
  add(query_21626477, "Action", newJString(Action))
  add(formData_21626478, "PageSize", newJInt(PageSize))
  add(query_21626477, "Version", newJString(Version))
  result = call_21626476.call(nil, query_21626477, nil, formData_21626478, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_21626461(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_21626462, base: "/",
    makeUrl: url_PostDescribeAccountLimits_21626463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_21626444 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeAccountLimits_21626446(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAccountLimits_21626445(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626447 = query.getOrDefault("PageSize")
  valid_21626447 = validateParameter(valid_21626447, JInt, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "PageSize", valid_21626447
  var valid_21626448 = query.getOrDefault("Action")
  valid_21626448 = validateParameter(valid_21626448, JString, required = true, default = newJString(
      "DescribeAccountLimits"))
  if valid_21626448 != nil:
    section.add "Action", valid_21626448
  var valid_21626449 = query.getOrDefault("Marker")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "Marker", valid_21626449
  var valid_21626450 = query.getOrDefault("Version")
  valid_21626450 = validateParameter(valid_21626450, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626450 != nil:
    section.add "Version", valid_21626450
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626451 = header.getOrDefault("X-Amz-Date")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Date", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Security-Token", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Algorithm", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Signature")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Signature", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Credential")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Credential", valid_21626457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626458: Call_GetDescribeAccountLimits_21626444;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626458.validator(path, query, header, formData, body, _)
  let scheme = call_21626458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626458.makeUrl(scheme.get, call_21626458.host, call_21626458.base,
                               call_21626458.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626458, uri, valid, _)

proc call*(call_21626459: Call_GetDescribeAccountLimits_21626444;
          PageSize: int = 0; Action: string = "DescribeAccountLimits";
          Marker: string = ""; Version: string = "2015-12-01"): Recallable =
  ## getDescribeAccountLimits
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: string (required)
  var query_21626460 = newJObject()
  add(query_21626460, "PageSize", newJInt(PageSize))
  add(query_21626460, "Action", newJString(Action))
  add(query_21626460, "Marker", newJString(Marker))
  add(query_21626460, "Version", newJString(Version))
  result = call_21626459.call(nil, query_21626460, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_21626444(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_21626445, base: "/",
    makeUrl: url_GetDescribeAccountLimits_21626446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListenerCertificates_21626497 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeListenerCertificates_21626499(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeListenerCertificates_21626498(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626500 = query.getOrDefault("Action")
  valid_21626500 = validateParameter(valid_21626500, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_21626500 != nil:
    section.add "Action", valid_21626500
  var valid_21626501 = query.getOrDefault("Version")
  valid_21626501 = validateParameter(valid_21626501, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626501 != nil:
    section.add "Version", valid_21626501
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626502 = header.getOrDefault("X-Amz-Date")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Date", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-Security-Token", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626504
  var valid_21626505 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-Algorithm", valid_21626505
  var valid_21626506 = header.getOrDefault("X-Amz-Signature")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-Signature", valid_21626506
  var valid_21626507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626507 = validateParameter(valid_21626507, JString, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626507
  var valid_21626508 = header.getOrDefault("X-Amz-Credential")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-Credential", valid_21626508
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
  var valid_21626509 = formData.getOrDefault("ListenerArn")
  valid_21626509 = validateParameter(valid_21626509, JString, required = true,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "ListenerArn", valid_21626509
  var valid_21626510 = formData.getOrDefault("Marker")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "Marker", valid_21626510
  var valid_21626511 = formData.getOrDefault("PageSize")
  valid_21626511 = validateParameter(valid_21626511, JInt, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "PageSize", valid_21626511
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626512: Call_PostDescribeListenerCertificates_21626497;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626512.validator(path, query, header, formData, body, _)
  let scheme = call_21626512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626512.makeUrl(scheme.get, call_21626512.host, call_21626512.base,
                               call_21626512.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626512, uri, valid, _)

proc call*(call_21626513: Call_PostDescribeListenerCertificates_21626497;
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
  var query_21626514 = newJObject()
  var formData_21626515 = newJObject()
  add(formData_21626515, "ListenerArn", newJString(ListenerArn))
  add(formData_21626515, "Marker", newJString(Marker))
  add(query_21626514, "Action", newJString(Action))
  add(formData_21626515, "PageSize", newJInt(PageSize))
  add(query_21626514, "Version", newJString(Version))
  result = call_21626513.call(nil, query_21626514, nil, formData_21626515, nil)

var postDescribeListenerCertificates* = Call_PostDescribeListenerCertificates_21626497(
    name: "postDescribeListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_PostDescribeListenerCertificates_21626498, base: "/",
    makeUrl: url_PostDescribeListenerCertificates_21626499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListenerCertificates_21626479 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeListenerCertificates_21626481(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeListenerCertificates_21626480(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Names (ARN) of the listener.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626482 = query.getOrDefault("PageSize")
  valid_21626482 = validateParameter(valid_21626482, JInt, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "PageSize", valid_21626482
  var valid_21626483 = query.getOrDefault("Action")
  valid_21626483 = validateParameter(valid_21626483, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_21626483 != nil:
    section.add "Action", valid_21626483
  var valid_21626484 = query.getOrDefault("Marker")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "Marker", valid_21626484
  var valid_21626485 = query.getOrDefault("ListenerArn")
  valid_21626485 = validateParameter(valid_21626485, JString, required = true,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "ListenerArn", valid_21626485
  var valid_21626486 = query.getOrDefault("Version")
  valid_21626486 = validateParameter(valid_21626486, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626486 != nil:
    section.add "Version", valid_21626486
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626487 = header.getOrDefault("X-Amz-Date")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Date", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Security-Token", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Algorithm", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-Signature")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Signature", valid_21626491
  var valid_21626492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-Credential")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-Credential", valid_21626493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626494: Call_GetDescribeListenerCertificates_21626479;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626494.validator(path, query, header, formData, body, _)
  let scheme = call_21626494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626494.makeUrl(scheme.get, call_21626494.host, call_21626494.base,
                               call_21626494.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626494, uri, valid, _)

proc call*(call_21626495: Call_GetDescribeListenerCertificates_21626479;
          ListenerArn: string; PageSize: int = 0;
          Action: string = "DescribeListenerCertificates"; Marker: string = "";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeListenerCertificates
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Names (ARN) of the listener.
  ##   Version: string (required)
  var query_21626496 = newJObject()
  add(query_21626496, "PageSize", newJInt(PageSize))
  add(query_21626496, "Action", newJString(Action))
  add(query_21626496, "Marker", newJString(Marker))
  add(query_21626496, "ListenerArn", newJString(ListenerArn))
  add(query_21626496, "Version", newJString(Version))
  result = call_21626495.call(nil, query_21626496, nil, nil, nil)

var getDescribeListenerCertificates* = Call_GetDescribeListenerCertificates_21626479(
    name: "getDescribeListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_GetDescribeListenerCertificates_21626480, base: "/",
    makeUrl: url_GetDescribeListenerCertificates_21626481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListeners_21626535 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeListeners_21626537(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeListeners_21626536(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626538 = query.getOrDefault("Action")
  valid_21626538 = validateParameter(valid_21626538, JString, required = true,
                                   default = newJString("DescribeListeners"))
  if valid_21626538 != nil:
    section.add "Action", valid_21626538
  var valid_21626539 = query.getOrDefault("Version")
  valid_21626539 = validateParameter(valid_21626539, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626539 != nil:
    section.add "Version", valid_21626539
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626540 = header.getOrDefault("X-Amz-Date")
  valid_21626540 = validateParameter(valid_21626540, JString, required = false,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "X-Amz-Date", valid_21626540
  var valid_21626541 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626541 = validateParameter(valid_21626541, JString, required = false,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "X-Amz-Security-Token", valid_21626541
  var valid_21626542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Algorithm", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Signature")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Signature", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Credential")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Credential", valid_21626546
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   ListenerArns: JArray
  ##               : The Amazon Resource Names (ARN) of the listeners.
  section = newJObject()
  var valid_21626547 = formData.getOrDefault("LoadBalancerArn")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "LoadBalancerArn", valid_21626547
  var valid_21626548 = formData.getOrDefault("Marker")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "Marker", valid_21626548
  var valid_21626549 = formData.getOrDefault("PageSize")
  valid_21626549 = validateParameter(valid_21626549, JInt, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "PageSize", valid_21626549
  var valid_21626550 = formData.getOrDefault("ListenerArns")
  valid_21626550 = validateParameter(valid_21626550, JArray, required = false,
                                   default = nil)
  if valid_21626550 != nil:
    section.add "ListenerArns", valid_21626550
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626551: Call_PostDescribeListeners_21626535;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_21626551.validator(path, query, header, formData, body, _)
  let scheme = call_21626551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626551.makeUrl(scheme.get, call_21626551.host, call_21626551.base,
                               call_21626551.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626551, uri, valid, _)

proc call*(call_21626552: Call_PostDescribeListeners_21626535;
          LoadBalancerArn: string = ""; Marker: string = "";
          Action: string = "DescribeListeners"; PageSize: int = 0;
          ListenerArns: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
  ## postDescribeListeners
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ##   LoadBalancerArn: string
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   ListenerArns: JArray
  ##               : The Amazon Resource Names (ARN) of the listeners.
  ##   Version: string (required)
  var query_21626553 = newJObject()
  var formData_21626554 = newJObject()
  add(formData_21626554, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_21626554, "Marker", newJString(Marker))
  add(query_21626553, "Action", newJString(Action))
  add(formData_21626554, "PageSize", newJInt(PageSize))
  if ListenerArns != nil:
    formData_21626554.add "ListenerArns", ListenerArns
  add(query_21626553, "Version", newJString(Version))
  result = call_21626552.call(nil, query_21626553, nil, formData_21626554, nil)

var postDescribeListeners* = Call_PostDescribeListeners_21626535(
    name: "postDescribeListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners",
    validator: validate_PostDescribeListeners_21626536, base: "/",
    makeUrl: url_PostDescribeListeners_21626537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListeners_21626516 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeListeners_21626518(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeListeners_21626517(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ListenerArns: JArray
  ##               : The Amazon Resource Names (ARN) of the listeners.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerArn: JString
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626519 = query.getOrDefault("ListenerArns")
  valid_21626519 = validateParameter(valid_21626519, JArray, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "ListenerArns", valid_21626519
  var valid_21626520 = query.getOrDefault("PageSize")
  valid_21626520 = validateParameter(valid_21626520, JInt, required = false,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "PageSize", valid_21626520
  var valid_21626521 = query.getOrDefault("Action")
  valid_21626521 = validateParameter(valid_21626521, JString, required = true,
                                   default = newJString("DescribeListeners"))
  if valid_21626521 != nil:
    section.add "Action", valid_21626521
  var valid_21626522 = query.getOrDefault("Marker")
  valid_21626522 = validateParameter(valid_21626522, JString, required = false,
                                   default = nil)
  if valid_21626522 != nil:
    section.add "Marker", valid_21626522
  var valid_21626523 = query.getOrDefault("LoadBalancerArn")
  valid_21626523 = validateParameter(valid_21626523, JString, required = false,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "LoadBalancerArn", valid_21626523
  var valid_21626524 = query.getOrDefault("Version")
  valid_21626524 = validateParameter(valid_21626524, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626524 != nil:
    section.add "Version", valid_21626524
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626525 = header.getOrDefault("X-Amz-Date")
  valid_21626525 = validateParameter(valid_21626525, JString, required = false,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "X-Amz-Date", valid_21626525
  var valid_21626526 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626526 = validateParameter(valid_21626526, JString, required = false,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "X-Amz-Security-Token", valid_21626526
  var valid_21626527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Algorithm", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Signature")
  valid_21626529 = validateParameter(valid_21626529, JString, required = false,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "X-Amz-Signature", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-Credential")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Credential", valid_21626531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626532: Call_GetDescribeListeners_21626516; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_21626532.validator(path, query, header, formData, body, _)
  let scheme = call_21626532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626532.makeUrl(scheme.get, call_21626532.host, call_21626532.base,
                               call_21626532.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626532, uri, valid, _)

proc call*(call_21626533: Call_GetDescribeListeners_21626516;
          ListenerArns: JsonNode = nil; PageSize: int = 0;
          Action: string = "DescribeListeners"; Marker: string = "";
          LoadBalancerArn: string = ""; Version: string = "2015-12-01"): Recallable =
  ## getDescribeListeners
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ##   ListenerArns: JArray
  ##               : The Amazon Resource Names (ARN) of the listeners.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerArn: string
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_21626534 = newJObject()
  if ListenerArns != nil:
    query_21626534.add "ListenerArns", ListenerArns
  add(query_21626534, "PageSize", newJInt(PageSize))
  add(query_21626534, "Action", newJString(Action))
  add(query_21626534, "Marker", newJString(Marker))
  add(query_21626534, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_21626534, "Version", newJString(Version))
  result = call_21626533.call(nil, query_21626534, nil, nil, nil)

var getDescribeListeners* = Call_GetDescribeListeners_21626516(
    name: "getDescribeListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners", validator: validate_GetDescribeListeners_21626517,
    base: "/", makeUrl: url_GetDescribeListeners_21626518,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_21626571 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeLoadBalancerAttributes_21626573(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancerAttributes_21626572(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626574 = query.getOrDefault("Action")
  valid_21626574 = validateParameter(valid_21626574, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_21626574 != nil:
    section.add "Action", valid_21626574
  var valid_21626575 = query.getOrDefault("Version")
  valid_21626575 = validateParameter(valid_21626575, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626575 != nil:
    section.add "Version", valid_21626575
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626576 = header.getOrDefault("X-Amz-Date")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Date", valid_21626576
  var valid_21626577 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Security-Token", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Algorithm", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Signature")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Signature", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-Credential")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-Credential", valid_21626582
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_21626583 = formData.getOrDefault("LoadBalancerArn")
  valid_21626583 = validateParameter(valid_21626583, JString, required = true,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "LoadBalancerArn", valid_21626583
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626584: Call_PostDescribeLoadBalancerAttributes_21626571;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626584.validator(path, query, header, formData, body, _)
  let scheme = call_21626584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626584.makeUrl(scheme.get, call_21626584.host, call_21626584.base,
                               call_21626584.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626584, uri, valid, _)

proc call*(call_21626585: Call_PostDescribeLoadBalancerAttributes_21626571;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626586 = newJObject()
  var formData_21626587 = newJObject()
  add(formData_21626587, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_21626586, "Action", newJString(Action))
  add(query_21626586, "Version", newJString(Version))
  result = call_21626585.call(nil, query_21626586, nil, formData_21626587, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_21626571(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_21626572, base: "/",
    makeUrl: url_PostDescribeLoadBalancerAttributes_21626573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_21626555 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeLoadBalancerAttributes_21626557(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancerAttributes_21626556(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626558 = query.getOrDefault("Action")
  valid_21626558 = validateParameter(valid_21626558, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_21626558 != nil:
    section.add "Action", valid_21626558
  var valid_21626559 = query.getOrDefault("LoadBalancerArn")
  valid_21626559 = validateParameter(valid_21626559, JString, required = true,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "LoadBalancerArn", valid_21626559
  var valid_21626560 = query.getOrDefault("Version")
  valid_21626560 = validateParameter(valid_21626560, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626560 != nil:
    section.add "Version", valid_21626560
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626561 = header.getOrDefault("X-Amz-Date")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Date", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Security-Token", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-Algorithm", valid_21626564
  var valid_21626565 = header.getOrDefault("X-Amz-Signature")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-Signature", valid_21626565
  var valid_21626566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626566 = validateParameter(valid_21626566, JString, required = false,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626566
  var valid_21626567 = header.getOrDefault("X-Amz-Credential")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "X-Amz-Credential", valid_21626567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626568: Call_GetDescribeLoadBalancerAttributes_21626555;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626568.validator(path, query, header, formData, body, _)
  let scheme = call_21626568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626568.makeUrl(scheme.get, call_21626568.host, call_21626568.base,
                               call_21626568.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626568, uri, valid, _)

proc call*(call_21626569: Call_GetDescribeLoadBalancerAttributes_21626555;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_21626570 = newJObject()
  add(query_21626570, "Action", newJString(Action))
  add(query_21626570, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_21626570, "Version", newJString(Version))
  result = call_21626569.call(nil, query_21626570, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_21626555(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_21626556, base: "/",
    makeUrl: url_GetDescribeLoadBalancerAttributes_21626557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_21626607 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeLoadBalancers_21626609(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancers_21626608(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626610 = query.getOrDefault("Action")
  valid_21626610 = validateParameter(valid_21626610, JString, required = true, default = newJString(
      "DescribeLoadBalancers"))
  if valid_21626610 != nil:
    section.add "Action", valid_21626610
  var valid_21626611 = query.getOrDefault("Version")
  valid_21626611 = validateParameter(valid_21626611, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626611 != nil:
    section.add "Version", valid_21626611
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626612 = header.getOrDefault("X-Amz-Date")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "X-Amz-Date", valid_21626612
  var valid_21626613 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-Security-Token", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Algorithm", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-Signature")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Signature", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Credential")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Credential", valid_21626618
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the load balancers.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerArns: JArray
  ##                   : The Amazon Resource Names (ARN) of the load balancers. You can specify up to 20 load balancers in a single call.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_21626619 = formData.getOrDefault("Names")
  valid_21626619 = validateParameter(valid_21626619, JArray, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "Names", valid_21626619
  var valid_21626620 = formData.getOrDefault("Marker")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "Marker", valid_21626620
  var valid_21626621 = formData.getOrDefault("LoadBalancerArns")
  valid_21626621 = validateParameter(valid_21626621, JArray, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "LoadBalancerArns", valid_21626621
  var valid_21626622 = formData.getOrDefault("PageSize")
  valid_21626622 = validateParameter(valid_21626622, JInt, required = false,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "PageSize", valid_21626622
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626623: Call_PostDescribeLoadBalancers_21626607;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_21626623.validator(path, query, header, formData, body, _)
  let scheme = call_21626623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626623.makeUrl(scheme.get, call_21626623.host, call_21626623.base,
                               call_21626623.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626623, uri, valid, _)

proc call*(call_21626624: Call_PostDescribeLoadBalancers_21626607;
          Names: JsonNode = nil; Marker: string = "";
          Action: string = "DescribeLoadBalancers";
          LoadBalancerArns: JsonNode = nil; PageSize: int = 0;
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeLoadBalancers
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ##   Names: JArray
  ##        : The names of the load balancers.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   LoadBalancerArns: JArray
  ##                   : The Amazon Resource Names (ARN) of the load balancers. You can specify up to 20 load balancers in a single call.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_21626625 = newJObject()
  var formData_21626626 = newJObject()
  if Names != nil:
    formData_21626626.add "Names", Names
  add(formData_21626626, "Marker", newJString(Marker))
  add(query_21626625, "Action", newJString(Action))
  if LoadBalancerArns != nil:
    formData_21626626.add "LoadBalancerArns", LoadBalancerArns
  add(formData_21626626, "PageSize", newJInt(PageSize))
  add(query_21626625, "Version", newJString(Version))
  result = call_21626624.call(nil, query_21626625, nil, formData_21626626, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_21626607(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_21626608, base: "/",
    makeUrl: url_PostDescribeLoadBalancers_21626609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_21626588 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeLoadBalancers_21626590(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancers_21626589(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Names: JArray
  ##        : The names of the load balancers.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   LoadBalancerArns: JArray
  ##                   : The Amazon Resource Names (ARN) of the load balancers. You can specify up to 20 load balancers in a single call.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626591 = query.getOrDefault("Names")
  valid_21626591 = validateParameter(valid_21626591, JArray, required = false,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "Names", valid_21626591
  var valid_21626592 = query.getOrDefault("PageSize")
  valid_21626592 = validateParameter(valid_21626592, JInt, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "PageSize", valid_21626592
  var valid_21626593 = query.getOrDefault("LoadBalancerArns")
  valid_21626593 = validateParameter(valid_21626593, JArray, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "LoadBalancerArns", valid_21626593
  var valid_21626594 = query.getOrDefault("Action")
  valid_21626594 = validateParameter(valid_21626594, JString, required = true, default = newJString(
      "DescribeLoadBalancers"))
  if valid_21626594 != nil:
    section.add "Action", valid_21626594
  var valid_21626595 = query.getOrDefault("Marker")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "Marker", valid_21626595
  var valid_21626596 = query.getOrDefault("Version")
  valid_21626596 = validateParameter(valid_21626596, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626596 != nil:
    section.add "Version", valid_21626596
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626597 = header.getOrDefault("X-Amz-Date")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-Date", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Security-Token", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626599
  var valid_21626600 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amz-Algorithm", valid_21626600
  var valid_21626601 = header.getOrDefault("X-Amz-Signature")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "X-Amz-Signature", valid_21626601
  var valid_21626602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-Credential")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-Credential", valid_21626603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626604: Call_GetDescribeLoadBalancers_21626588;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_21626604.validator(path, query, header, formData, body, _)
  let scheme = call_21626604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626604.makeUrl(scheme.get, call_21626604.host, call_21626604.base,
                               call_21626604.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626604, uri, valid, _)

proc call*(call_21626605: Call_GetDescribeLoadBalancers_21626588;
          Names: JsonNode = nil; PageSize: int = 0; LoadBalancerArns: JsonNode = nil;
          Action: string = "DescribeLoadBalancers"; Marker: string = "";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeLoadBalancers
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ##   Names: JArray
  ##        : The names of the load balancers.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   LoadBalancerArns: JArray
  ##                   : The Amazon Resource Names (ARN) of the load balancers. You can specify up to 20 load balancers in a single call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: string (required)
  var query_21626606 = newJObject()
  if Names != nil:
    query_21626606.add "Names", Names
  add(query_21626606, "PageSize", newJInt(PageSize))
  if LoadBalancerArns != nil:
    query_21626606.add "LoadBalancerArns", LoadBalancerArns
  add(query_21626606, "Action", newJString(Action))
  add(query_21626606, "Marker", newJString(Marker))
  add(query_21626606, "Version", newJString(Version))
  result = call_21626605.call(nil, query_21626606, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_21626588(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_21626589, base: "/",
    makeUrl: url_GetDescribeLoadBalancers_21626590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRules_21626646 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeRules_21626648(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeRules_21626647(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626649 = query.getOrDefault("Action")
  valid_21626649 = validateParameter(valid_21626649, JString, required = true,
                                   default = newJString("DescribeRules"))
  if valid_21626649 != nil:
    section.add "Action", valid_21626649
  var valid_21626650 = query.getOrDefault("Version")
  valid_21626650 = validateParameter(valid_21626650, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626650 != nil:
    section.add "Version", valid_21626650
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626651 = header.getOrDefault("X-Amz-Date")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-Date", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Security-Token", valid_21626652
  var valid_21626653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626653 = validateParameter(valid_21626653, JString, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626653
  var valid_21626654 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626654 = validateParameter(valid_21626654, JString, required = false,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "X-Amz-Algorithm", valid_21626654
  var valid_21626655 = header.getOrDefault("X-Amz-Signature")
  valid_21626655 = validateParameter(valid_21626655, JString, required = false,
                                   default = nil)
  if valid_21626655 != nil:
    section.add "X-Amz-Signature", valid_21626655
  var valid_21626656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626656 = validateParameter(valid_21626656, JString, required = false,
                                   default = nil)
  if valid_21626656 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626656
  var valid_21626657 = header.getOrDefault("X-Amz-Credential")
  valid_21626657 = validateParameter(valid_21626657, JString, required = false,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "X-Amz-Credential", valid_21626657
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   RuleArns: JArray
  ##           : The Amazon Resource Names (ARN) of the rules.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_21626658 = formData.getOrDefault("ListenerArn")
  valid_21626658 = validateParameter(valid_21626658, JString, required = false,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "ListenerArn", valid_21626658
  var valid_21626659 = formData.getOrDefault("RuleArns")
  valid_21626659 = validateParameter(valid_21626659, JArray, required = false,
                                   default = nil)
  if valid_21626659 != nil:
    section.add "RuleArns", valid_21626659
  var valid_21626660 = formData.getOrDefault("Marker")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "Marker", valid_21626660
  var valid_21626661 = formData.getOrDefault("PageSize")
  valid_21626661 = validateParameter(valid_21626661, JInt, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "PageSize", valid_21626661
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626662: Call_PostDescribeRules_21626646; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_21626662.validator(path, query, header, formData, body, _)
  let scheme = call_21626662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626662.makeUrl(scheme.get, call_21626662.host, call_21626662.base,
                               call_21626662.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626662, uri, valid, _)

proc call*(call_21626663: Call_PostDescribeRules_21626646;
          ListenerArn: string = ""; RuleArns: JsonNode = nil; Marker: string = "";
          Action: string = "DescribeRules"; PageSize: int = 0;
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeRules
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ##   ListenerArn: string
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   RuleArns: JArray
  ##           : The Amazon Resource Names (ARN) of the rules.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_21626664 = newJObject()
  var formData_21626665 = newJObject()
  add(formData_21626665, "ListenerArn", newJString(ListenerArn))
  if RuleArns != nil:
    formData_21626665.add "RuleArns", RuleArns
  add(formData_21626665, "Marker", newJString(Marker))
  add(query_21626664, "Action", newJString(Action))
  add(formData_21626665, "PageSize", newJInt(PageSize))
  add(query_21626664, "Version", newJString(Version))
  result = call_21626663.call(nil, query_21626664, nil, formData_21626665, nil)

var postDescribeRules* = Call_PostDescribeRules_21626646(name: "postDescribeRules",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_PostDescribeRules_21626647,
    base: "/", makeUrl: url_PostDescribeRules_21626648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRules_21626627 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeRules_21626629(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeRules_21626628(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   ListenerArn: JString
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: JString (required)
  ##   RuleArns: JArray
  ##           : The Amazon Resource Names (ARN) of the rules.
  section = newJObject()
  var valid_21626630 = query.getOrDefault("PageSize")
  valid_21626630 = validateParameter(valid_21626630, JInt, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "PageSize", valid_21626630
  var valid_21626631 = query.getOrDefault("Action")
  valid_21626631 = validateParameter(valid_21626631, JString, required = true,
                                   default = newJString("DescribeRules"))
  if valid_21626631 != nil:
    section.add "Action", valid_21626631
  var valid_21626632 = query.getOrDefault("Marker")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "Marker", valid_21626632
  var valid_21626633 = query.getOrDefault("ListenerArn")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "ListenerArn", valid_21626633
  var valid_21626634 = query.getOrDefault("Version")
  valid_21626634 = validateParameter(valid_21626634, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626634 != nil:
    section.add "Version", valid_21626634
  var valid_21626635 = query.getOrDefault("RuleArns")
  valid_21626635 = validateParameter(valid_21626635, JArray, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "RuleArns", valid_21626635
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626636 = header.getOrDefault("X-Amz-Date")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "X-Amz-Date", valid_21626636
  var valid_21626637 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Security-Token", valid_21626637
  var valid_21626638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626638 = validateParameter(valid_21626638, JString, required = false,
                                   default = nil)
  if valid_21626638 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626638
  var valid_21626639 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626639 = validateParameter(valid_21626639, JString, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "X-Amz-Algorithm", valid_21626639
  var valid_21626640 = header.getOrDefault("X-Amz-Signature")
  valid_21626640 = validateParameter(valid_21626640, JString, required = false,
                                   default = nil)
  if valid_21626640 != nil:
    section.add "X-Amz-Signature", valid_21626640
  var valid_21626641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626641 = validateParameter(valid_21626641, JString, required = false,
                                   default = nil)
  if valid_21626641 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626641
  var valid_21626642 = header.getOrDefault("X-Amz-Credential")
  valid_21626642 = validateParameter(valid_21626642, JString, required = false,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "X-Amz-Credential", valid_21626642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626643: Call_GetDescribeRules_21626627; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_21626643.validator(path, query, header, formData, body, _)
  let scheme = call_21626643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626643.makeUrl(scheme.get, call_21626643.host, call_21626643.base,
                               call_21626643.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626643, uri, valid, _)

proc call*(call_21626644: Call_GetDescribeRules_21626627; PageSize: int = 0;
          Action: string = "DescribeRules"; Marker: string = "";
          ListenerArn: string = ""; Version: string = "2015-12-01";
          RuleArns: JsonNode = nil): Recallable =
  ## getDescribeRules
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   ListenerArn: string
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: string (required)
  ##   RuleArns: JArray
  ##           : The Amazon Resource Names (ARN) of the rules.
  var query_21626645 = newJObject()
  add(query_21626645, "PageSize", newJInt(PageSize))
  add(query_21626645, "Action", newJString(Action))
  add(query_21626645, "Marker", newJString(Marker))
  add(query_21626645, "ListenerArn", newJString(ListenerArn))
  add(query_21626645, "Version", newJString(Version))
  if RuleArns != nil:
    query_21626645.add "RuleArns", RuleArns
  result = call_21626644.call(nil, query_21626645, nil, nil, nil)

var getDescribeRules* = Call_GetDescribeRules_21626627(name: "getDescribeRules",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_GetDescribeRules_21626628,
    base: "/", makeUrl: url_GetDescribeRules_21626629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSSLPolicies_21626684 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeSSLPolicies_21626686(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeSSLPolicies_21626685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626687 = query.getOrDefault("Action")
  valid_21626687 = validateParameter(valid_21626687, JString, required = true,
                                   default = newJString("DescribeSSLPolicies"))
  if valid_21626687 != nil:
    section.add "Action", valid_21626687
  var valid_21626688 = query.getOrDefault("Version")
  valid_21626688 = validateParameter(valid_21626688, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626688 != nil:
    section.add "Version", valid_21626688
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626689 = header.getOrDefault("X-Amz-Date")
  valid_21626689 = validateParameter(valid_21626689, JString, required = false,
                                   default = nil)
  if valid_21626689 != nil:
    section.add "X-Amz-Date", valid_21626689
  var valid_21626690 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "X-Amz-Security-Token", valid_21626690
  var valid_21626691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626691 = validateParameter(valid_21626691, JString, required = false,
                                   default = nil)
  if valid_21626691 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626691
  var valid_21626692 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Algorithm", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-Signature")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-Signature", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-Credential")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-Credential", valid_21626695
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the policies.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_21626696 = formData.getOrDefault("Names")
  valid_21626696 = validateParameter(valid_21626696, JArray, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "Names", valid_21626696
  var valid_21626697 = formData.getOrDefault("Marker")
  valid_21626697 = validateParameter(valid_21626697, JString, required = false,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "Marker", valid_21626697
  var valid_21626698 = formData.getOrDefault("PageSize")
  valid_21626698 = validateParameter(valid_21626698, JInt, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "PageSize", valid_21626698
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626699: Call_PostDescribeSSLPolicies_21626684;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626699.validator(path, query, header, formData, body, _)
  let scheme = call_21626699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626699.makeUrl(scheme.get, call_21626699.host, call_21626699.base,
                               call_21626699.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626699, uri, valid, _)

proc call*(call_21626700: Call_PostDescribeSSLPolicies_21626684;
          Names: JsonNode = nil; Marker: string = "";
          Action: string = "DescribeSSLPolicies"; PageSize: int = 0;
          Version: string = "2015-12-01"): Recallable =
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
  var query_21626701 = newJObject()
  var formData_21626702 = newJObject()
  if Names != nil:
    formData_21626702.add "Names", Names
  add(formData_21626702, "Marker", newJString(Marker))
  add(query_21626701, "Action", newJString(Action))
  add(formData_21626702, "PageSize", newJInt(PageSize))
  add(query_21626701, "Version", newJString(Version))
  result = call_21626700.call(nil, query_21626701, nil, formData_21626702, nil)

var postDescribeSSLPolicies* = Call_PostDescribeSSLPolicies_21626684(
    name: "postDescribeSSLPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_PostDescribeSSLPolicies_21626685, base: "/",
    makeUrl: url_PostDescribeSSLPolicies_21626686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSSLPolicies_21626666 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeSSLPolicies_21626668(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeSSLPolicies_21626667(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Names: JArray
  ##        : The names of the policies.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626669 = query.getOrDefault("Names")
  valid_21626669 = validateParameter(valid_21626669, JArray, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "Names", valid_21626669
  var valid_21626670 = query.getOrDefault("PageSize")
  valid_21626670 = validateParameter(valid_21626670, JInt, required = false,
                                   default = nil)
  if valid_21626670 != nil:
    section.add "PageSize", valid_21626670
  var valid_21626671 = query.getOrDefault("Action")
  valid_21626671 = validateParameter(valid_21626671, JString, required = true,
                                   default = newJString("DescribeSSLPolicies"))
  if valid_21626671 != nil:
    section.add "Action", valid_21626671
  var valid_21626672 = query.getOrDefault("Marker")
  valid_21626672 = validateParameter(valid_21626672, JString, required = false,
                                   default = nil)
  if valid_21626672 != nil:
    section.add "Marker", valid_21626672
  var valid_21626673 = query.getOrDefault("Version")
  valid_21626673 = validateParameter(valid_21626673, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626673 != nil:
    section.add "Version", valid_21626673
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626674 = header.getOrDefault("X-Amz-Date")
  valid_21626674 = validateParameter(valid_21626674, JString, required = false,
                                   default = nil)
  if valid_21626674 != nil:
    section.add "X-Amz-Date", valid_21626674
  var valid_21626675 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626675 = validateParameter(valid_21626675, JString, required = false,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "X-Amz-Security-Token", valid_21626675
  var valid_21626676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626676 = validateParameter(valid_21626676, JString, required = false,
                                   default = nil)
  if valid_21626676 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626676
  var valid_21626677 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Algorithm", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Signature")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Signature", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-Credential")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Credential", valid_21626680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626681: Call_GetDescribeSSLPolicies_21626666;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626681.validator(path, query, header, formData, body, _)
  let scheme = call_21626681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626681.makeUrl(scheme.get, call_21626681.host, call_21626681.base,
                               call_21626681.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626681, uri, valid, _)

proc call*(call_21626682: Call_GetDescribeSSLPolicies_21626666;
          Names: JsonNode = nil; PageSize: int = 0;
          Action: string = "DescribeSSLPolicies"; Marker: string = "";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeSSLPolicies
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ##   Names: JArray
  ##        : The names of the policies.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: string (required)
  var query_21626683 = newJObject()
  if Names != nil:
    query_21626683.add "Names", Names
  add(query_21626683, "PageSize", newJInt(PageSize))
  add(query_21626683, "Action", newJString(Action))
  add(query_21626683, "Marker", newJString(Marker))
  add(query_21626683, "Version", newJString(Version))
  result = call_21626682.call(nil, query_21626683, nil, nil, nil)

var getDescribeSSLPolicies* = Call_GetDescribeSSLPolicies_21626666(
    name: "getDescribeSSLPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_GetDescribeSSLPolicies_21626667, base: "/",
    makeUrl: url_GetDescribeSSLPolicies_21626668,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_21626719 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeTags_21626721(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTags_21626720(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626722 = query.getOrDefault("Action")
  valid_21626722 = validateParameter(valid_21626722, JString, required = true,
                                   default = newJString("DescribeTags"))
  if valid_21626722 != nil:
    section.add "Action", valid_21626722
  var valid_21626723 = query.getOrDefault("Version")
  valid_21626723 = validateParameter(valid_21626723, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626723 != nil:
    section.add "Version", valid_21626723
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626724 = header.getOrDefault("X-Amz-Date")
  valid_21626724 = validateParameter(valid_21626724, JString, required = false,
                                   default = nil)
  if valid_21626724 != nil:
    section.add "X-Amz-Date", valid_21626724
  var valid_21626725 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-Security-Token", valid_21626725
  var valid_21626726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626726
  var valid_21626727 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-Algorithm", valid_21626727
  var valid_21626728 = header.getOrDefault("X-Amz-Signature")
  valid_21626728 = validateParameter(valid_21626728, JString, required = false,
                                   default = nil)
  if valid_21626728 != nil:
    section.add "X-Amz-Signature", valid_21626728
  var valid_21626729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626729 = validateParameter(valid_21626729, JString, required = false,
                                   default = nil)
  if valid_21626729 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626729
  var valid_21626730 = header.getOrDefault("X-Amz-Credential")
  valid_21626730 = validateParameter(valid_21626730, JString, required = false,
                                   default = nil)
  if valid_21626730 != nil:
    section.add "X-Amz-Credential", valid_21626730
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_21626731 = formData.getOrDefault("ResourceArns")
  valid_21626731 = validateParameter(valid_21626731, JArray, required = true,
                                   default = nil)
  if valid_21626731 != nil:
    section.add "ResourceArns", valid_21626731
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626732: Call_PostDescribeTags_21626719; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_21626732.validator(path, query, header, formData, body, _)
  let scheme = call_21626732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626732.makeUrl(scheme.get, call_21626732.host, call_21626732.base,
                               call_21626732.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626732, uri, valid, _)

proc call*(call_21626733: Call_PostDescribeTags_21626719; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626734 = newJObject()
  var formData_21626735 = newJObject()
  if ResourceArns != nil:
    formData_21626735.add "ResourceArns", ResourceArns
  add(query_21626734, "Action", newJString(Action))
  add(query_21626734, "Version", newJString(Version))
  result = call_21626733.call(nil, query_21626734, nil, formData_21626735, nil)

var postDescribeTags* = Call_PostDescribeTags_21626719(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_21626720,
    base: "/", makeUrl: url_PostDescribeTags_21626721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_21626703 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeTags_21626705(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTags_21626704(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626706 = query.getOrDefault("Action")
  valid_21626706 = validateParameter(valid_21626706, JString, required = true,
                                   default = newJString("DescribeTags"))
  if valid_21626706 != nil:
    section.add "Action", valid_21626706
  var valid_21626707 = query.getOrDefault("ResourceArns")
  valid_21626707 = validateParameter(valid_21626707, JArray, required = true,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "ResourceArns", valid_21626707
  var valid_21626708 = query.getOrDefault("Version")
  valid_21626708 = validateParameter(valid_21626708, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626708 != nil:
    section.add "Version", valid_21626708
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626709 = header.getOrDefault("X-Amz-Date")
  valid_21626709 = validateParameter(valid_21626709, JString, required = false,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "X-Amz-Date", valid_21626709
  var valid_21626710 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Security-Token", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Algorithm", valid_21626712
  var valid_21626713 = header.getOrDefault("X-Amz-Signature")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-Signature", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626714
  var valid_21626715 = header.getOrDefault("X-Amz-Credential")
  valid_21626715 = validateParameter(valid_21626715, JString, required = false,
                                   default = nil)
  if valid_21626715 != nil:
    section.add "X-Amz-Credential", valid_21626715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626716: Call_GetDescribeTags_21626703; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_21626716.validator(path, query, header, formData, body, _)
  let scheme = call_21626716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626716.makeUrl(scheme.get, call_21626716.host, call_21626716.base,
                               call_21626716.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626716, uri, valid, _)

proc call*(call_21626717: Call_GetDescribeTags_21626703; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   Action: string (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Version: string (required)
  var query_21626718 = newJObject()
  add(query_21626718, "Action", newJString(Action))
  if ResourceArns != nil:
    query_21626718.add "ResourceArns", ResourceArns
  add(query_21626718, "Version", newJString(Version))
  result = call_21626717.call(nil, query_21626718, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_21626703(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_21626704,
    base: "/", makeUrl: url_GetDescribeTags_21626705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroupAttributes_21626752 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeTargetGroupAttributes_21626754(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTargetGroupAttributes_21626753(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626755 = query.getOrDefault("Action")
  valid_21626755 = validateParameter(valid_21626755, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_21626755 != nil:
    section.add "Action", valid_21626755
  var valid_21626756 = query.getOrDefault("Version")
  valid_21626756 = validateParameter(valid_21626756, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626756 != nil:
    section.add "Version", valid_21626756
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626757 = header.getOrDefault("X-Amz-Date")
  valid_21626757 = validateParameter(valid_21626757, JString, required = false,
                                   default = nil)
  if valid_21626757 != nil:
    section.add "X-Amz-Date", valid_21626757
  var valid_21626758 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626758 = validateParameter(valid_21626758, JString, required = false,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "X-Amz-Security-Token", valid_21626758
  var valid_21626759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626759 = validateParameter(valid_21626759, JString, required = false,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626759
  var valid_21626760 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626760 = validateParameter(valid_21626760, JString, required = false,
                                   default = nil)
  if valid_21626760 != nil:
    section.add "X-Amz-Algorithm", valid_21626760
  var valid_21626761 = header.getOrDefault("X-Amz-Signature")
  valid_21626761 = validateParameter(valid_21626761, JString, required = false,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "X-Amz-Signature", valid_21626761
  var valid_21626762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626762 = validateParameter(valid_21626762, JString, required = false,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626762
  var valid_21626763 = header.getOrDefault("X-Amz-Credential")
  valid_21626763 = validateParameter(valid_21626763, JString, required = false,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "X-Amz-Credential", valid_21626763
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_21626764 = formData.getOrDefault("TargetGroupArn")
  valid_21626764 = validateParameter(valid_21626764, JString, required = true,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "TargetGroupArn", valid_21626764
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626765: Call_PostDescribeTargetGroupAttributes_21626752;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626765.validator(path, query, header, formData, body, _)
  let scheme = call_21626765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626765.makeUrl(scheme.get, call_21626765.host, call_21626765.base,
                               call_21626765.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626765, uri, valid, _)

proc call*(call_21626766: Call_PostDescribeTargetGroupAttributes_21626752;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_21626767 = newJObject()
  var formData_21626768 = newJObject()
  add(query_21626767, "Action", newJString(Action))
  add(formData_21626768, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_21626767, "Version", newJString(Version))
  result = call_21626766.call(nil, query_21626767, nil, formData_21626768, nil)

var postDescribeTargetGroupAttributes* = Call_PostDescribeTargetGroupAttributes_21626752(
    name: "postDescribeTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_PostDescribeTargetGroupAttributes_21626753, base: "/",
    makeUrl: url_PostDescribeTargetGroupAttributes_21626754,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroupAttributes_21626736 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeTargetGroupAttributes_21626738(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTargetGroupAttributes_21626737(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626739 = query.getOrDefault("TargetGroupArn")
  valid_21626739 = validateParameter(valid_21626739, JString, required = true,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "TargetGroupArn", valid_21626739
  var valid_21626740 = query.getOrDefault("Action")
  valid_21626740 = validateParameter(valid_21626740, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_21626740 != nil:
    section.add "Action", valid_21626740
  var valid_21626741 = query.getOrDefault("Version")
  valid_21626741 = validateParameter(valid_21626741, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626741 != nil:
    section.add "Version", valid_21626741
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626742 = header.getOrDefault("X-Amz-Date")
  valid_21626742 = validateParameter(valid_21626742, JString, required = false,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "X-Amz-Date", valid_21626742
  var valid_21626743 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "X-Amz-Security-Token", valid_21626743
  var valid_21626744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626744 = validateParameter(valid_21626744, JString, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626744
  var valid_21626745 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626745 = validateParameter(valid_21626745, JString, required = false,
                                   default = nil)
  if valid_21626745 != nil:
    section.add "X-Amz-Algorithm", valid_21626745
  var valid_21626746 = header.getOrDefault("X-Amz-Signature")
  valid_21626746 = validateParameter(valid_21626746, JString, required = false,
                                   default = nil)
  if valid_21626746 != nil:
    section.add "X-Amz-Signature", valid_21626746
  var valid_21626747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626747 = validateParameter(valid_21626747, JString, required = false,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626747
  var valid_21626748 = header.getOrDefault("X-Amz-Credential")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "X-Amz-Credential", valid_21626748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626749: Call_GetDescribeTargetGroupAttributes_21626736;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626749.validator(path, query, header, formData, body, _)
  let scheme = call_21626749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626749.makeUrl(scheme.get, call_21626749.host, call_21626749.base,
                               call_21626749.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626749, uri, valid, _)

proc call*(call_21626750: Call_GetDescribeTargetGroupAttributes_21626736;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626751 = newJObject()
  add(query_21626751, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_21626751, "Action", newJString(Action))
  add(query_21626751, "Version", newJString(Version))
  result = call_21626750.call(nil, query_21626751, nil, nil, nil)

var getDescribeTargetGroupAttributes* = Call_GetDescribeTargetGroupAttributes_21626736(
    name: "getDescribeTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_GetDescribeTargetGroupAttributes_21626737, base: "/",
    makeUrl: url_GetDescribeTargetGroupAttributes_21626738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroups_21626789 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeTargetGroups_21626791(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTargetGroups_21626790(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626792 = query.getOrDefault("Action")
  valid_21626792 = validateParameter(valid_21626792, JString, required = true,
                                   default = newJString("DescribeTargetGroups"))
  if valid_21626792 != nil:
    section.add "Action", valid_21626792
  var valid_21626793 = query.getOrDefault("Version")
  valid_21626793 = validateParameter(valid_21626793, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626793 != nil:
    section.add "Version", valid_21626793
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626794 = header.getOrDefault("X-Amz-Date")
  valid_21626794 = validateParameter(valid_21626794, JString, required = false,
                                   default = nil)
  if valid_21626794 != nil:
    section.add "X-Amz-Date", valid_21626794
  var valid_21626795 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "X-Amz-Security-Token", valid_21626795
  var valid_21626796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Algorithm", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-Signature")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-Signature", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626799 = validateParameter(valid_21626799, JString, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626799
  var valid_21626800 = header.getOrDefault("X-Amz-Credential")
  valid_21626800 = validateParameter(valid_21626800, JString, required = false,
                                   default = nil)
  if valid_21626800 != nil:
    section.add "X-Amz-Credential", valid_21626800
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   TargetGroupArns: JArray
  ##                  : The Amazon Resource Names (ARN) of the target groups.
  ##   Names: JArray
  ##        : The names of the target groups.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_21626801 = formData.getOrDefault("LoadBalancerArn")
  valid_21626801 = validateParameter(valid_21626801, JString, required = false,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "LoadBalancerArn", valid_21626801
  var valid_21626802 = formData.getOrDefault("TargetGroupArns")
  valid_21626802 = validateParameter(valid_21626802, JArray, required = false,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "TargetGroupArns", valid_21626802
  var valid_21626803 = formData.getOrDefault("Names")
  valid_21626803 = validateParameter(valid_21626803, JArray, required = false,
                                   default = nil)
  if valid_21626803 != nil:
    section.add "Names", valid_21626803
  var valid_21626804 = formData.getOrDefault("Marker")
  valid_21626804 = validateParameter(valid_21626804, JString, required = false,
                                   default = nil)
  if valid_21626804 != nil:
    section.add "Marker", valid_21626804
  var valid_21626805 = formData.getOrDefault("PageSize")
  valid_21626805 = validateParameter(valid_21626805, JInt, required = false,
                                   default = nil)
  if valid_21626805 != nil:
    section.add "PageSize", valid_21626805
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626806: Call_PostDescribeTargetGroups_21626789;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_21626806.validator(path, query, header, formData, body, _)
  let scheme = call_21626806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626806.makeUrl(scheme.get, call_21626806.host, call_21626806.base,
                               call_21626806.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626806, uri, valid, _)

proc call*(call_21626807: Call_PostDescribeTargetGroups_21626789;
          LoadBalancerArn: string = ""; TargetGroupArns: JsonNode = nil;
          Names: JsonNode = nil; Marker: string = "";
          Action: string = "DescribeTargetGroups"; PageSize: int = 0;
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetGroups
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ##   LoadBalancerArn: string
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   TargetGroupArns: JArray
  ##                  : The Amazon Resource Names (ARN) of the target groups.
  ##   Names: JArray
  ##        : The names of the target groups.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_21626808 = newJObject()
  var formData_21626809 = newJObject()
  add(formData_21626809, "LoadBalancerArn", newJString(LoadBalancerArn))
  if TargetGroupArns != nil:
    formData_21626809.add "TargetGroupArns", TargetGroupArns
  if Names != nil:
    formData_21626809.add "Names", Names
  add(formData_21626809, "Marker", newJString(Marker))
  add(query_21626808, "Action", newJString(Action))
  add(formData_21626809, "PageSize", newJInt(PageSize))
  add(query_21626808, "Version", newJString(Version))
  result = call_21626807.call(nil, query_21626808, nil, formData_21626809, nil)

var postDescribeTargetGroups* = Call_PostDescribeTargetGroups_21626789(
    name: "postDescribeTargetGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_PostDescribeTargetGroups_21626790, base: "/",
    makeUrl: url_PostDescribeTargetGroups_21626791,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroups_21626769 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeTargetGroups_21626771(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTargetGroups_21626770(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Names: JArray
  ##        : The names of the target groups.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerArn: JString
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   TargetGroupArns: JArray
  ##                  : The Amazon Resource Names (ARN) of the target groups.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626772 = query.getOrDefault("Names")
  valid_21626772 = validateParameter(valid_21626772, JArray, required = false,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "Names", valid_21626772
  var valid_21626773 = query.getOrDefault("PageSize")
  valid_21626773 = validateParameter(valid_21626773, JInt, required = false,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "PageSize", valid_21626773
  var valid_21626774 = query.getOrDefault("Action")
  valid_21626774 = validateParameter(valid_21626774, JString, required = true,
                                   default = newJString("DescribeTargetGroups"))
  if valid_21626774 != nil:
    section.add "Action", valid_21626774
  var valid_21626775 = query.getOrDefault("Marker")
  valid_21626775 = validateParameter(valid_21626775, JString, required = false,
                                   default = nil)
  if valid_21626775 != nil:
    section.add "Marker", valid_21626775
  var valid_21626776 = query.getOrDefault("LoadBalancerArn")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "LoadBalancerArn", valid_21626776
  var valid_21626777 = query.getOrDefault("TargetGroupArns")
  valid_21626777 = validateParameter(valid_21626777, JArray, required = false,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "TargetGroupArns", valid_21626777
  var valid_21626778 = query.getOrDefault("Version")
  valid_21626778 = validateParameter(valid_21626778, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626778 != nil:
    section.add "Version", valid_21626778
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626779 = header.getOrDefault("X-Amz-Date")
  valid_21626779 = validateParameter(valid_21626779, JString, required = false,
                                   default = nil)
  if valid_21626779 != nil:
    section.add "X-Amz-Date", valid_21626779
  var valid_21626780 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626780 = validateParameter(valid_21626780, JString, required = false,
                                   default = nil)
  if valid_21626780 != nil:
    section.add "X-Amz-Security-Token", valid_21626780
  var valid_21626781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626781 = validateParameter(valid_21626781, JString, required = false,
                                   default = nil)
  if valid_21626781 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626781
  var valid_21626782 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Algorithm", valid_21626782
  var valid_21626783 = header.getOrDefault("X-Amz-Signature")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-Signature", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626784 = validateParameter(valid_21626784, JString, required = false,
                                   default = nil)
  if valid_21626784 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626784
  var valid_21626785 = header.getOrDefault("X-Amz-Credential")
  valid_21626785 = validateParameter(valid_21626785, JString, required = false,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "X-Amz-Credential", valid_21626785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626786: Call_GetDescribeTargetGroups_21626769;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_21626786.validator(path, query, header, formData, body, _)
  let scheme = call_21626786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626786.makeUrl(scheme.get, call_21626786.host, call_21626786.base,
                               call_21626786.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626786, uri, valid, _)

proc call*(call_21626787: Call_GetDescribeTargetGroups_21626769;
          Names: JsonNode = nil; PageSize: int = 0;
          Action: string = "DescribeTargetGroups"; Marker: string = "";
          LoadBalancerArn: string = ""; TargetGroupArns: JsonNode = nil;
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetGroups
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ##   Names: JArray
  ##        : The names of the target groups.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerArn: string
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   TargetGroupArns: JArray
  ##                  : The Amazon Resource Names (ARN) of the target groups.
  ##   Version: string (required)
  var query_21626788 = newJObject()
  if Names != nil:
    query_21626788.add "Names", Names
  add(query_21626788, "PageSize", newJInt(PageSize))
  add(query_21626788, "Action", newJString(Action))
  add(query_21626788, "Marker", newJString(Marker))
  add(query_21626788, "LoadBalancerArn", newJString(LoadBalancerArn))
  if TargetGroupArns != nil:
    query_21626788.add "TargetGroupArns", TargetGroupArns
  add(query_21626788, "Version", newJString(Version))
  result = call_21626787.call(nil, query_21626788, nil, nil, nil)

var getDescribeTargetGroups* = Call_GetDescribeTargetGroups_21626769(
    name: "getDescribeTargetGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_GetDescribeTargetGroups_21626770, base: "/",
    makeUrl: url_GetDescribeTargetGroups_21626771,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetHealth_21626827 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeTargetHealth_21626829(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTargetHealth_21626828(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626830 = query.getOrDefault("Action")
  valid_21626830 = validateParameter(valid_21626830, JString, required = true,
                                   default = newJString("DescribeTargetHealth"))
  if valid_21626830 != nil:
    section.add "Action", valid_21626830
  var valid_21626831 = query.getOrDefault("Version")
  valid_21626831 = validateParameter(valid_21626831, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626831 != nil:
    section.add "Version", valid_21626831
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626832 = header.getOrDefault("X-Amz-Date")
  valid_21626832 = validateParameter(valid_21626832, JString, required = false,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "X-Amz-Date", valid_21626832
  var valid_21626833 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626833 = validateParameter(valid_21626833, JString, required = false,
                                   default = nil)
  if valid_21626833 != nil:
    section.add "X-Amz-Security-Token", valid_21626833
  var valid_21626834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626834
  var valid_21626835 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626835 = validateParameter(valid_21626835, JString, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "X-Amz-Algorithm", valid_21626835
  var valid_21626836 = header.getOrDefault("X-Amz-Signature")
  valid_21626836 = validateParameter(valid_21626836, JString, required = false,
                                   default = nil)
  if valid_21626836 != nil:
    section.add "X-Amz-Signature", valid_21626836
  var valid_21626837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626837 = validateParameter(valid_21626837, JString, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626837
  var valid_21626838 = header.getOrDefault("X-Amz-Credential")
  valid_21626838 = validateParameter(valid_21626838, JString, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "X-Amz-Credential", valid_21626838
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_21626839 = formData.getOrDefault("Targets")
  valid_21626839 = validateParameter(valid_21626839, JArray, required = false,
                                   default = nil)
  if valid_21626839 != nil:
    section.add "Targets", valid_21626839
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_21626840 = formData.getOrDefault("TargetGroupArn")
  valid_21626840 = validateParameter(valid_21626840, JString, required = true,
                                   default = nil)
  if valid_21626840 != nil:
    section.add "TargetGroupArn", valid_21626840
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626841: Call_PostDescribeTargetHealth_21626827;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_21626841.validator(path, query, header, formData, body, _)
  let scheme = call_21626841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626841.makeUrl(scheme.get, call_21626841.host, call_21626841.base,
                               call_21626841.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626841, uri, valid, _)

proc call*(call_21626842: Call_PostDescribeTargetHealth_21626827;
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
  var query_21626843 = newJObject()
  var formData_21626844 = newJObject()
  if Targets != nil:
    formData_21626844.add "Targets", Targets
  add(query_21626843, "Action", newJString(Action))
  add(formData_21626844, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_21626843, "Version", newJString(Version))
  result = call_21626842.call(nil, query_21626843, nil, formData_21626844, nil)

var postDescribeTargetHealth* = Call_PostDescribeTargetHealth_21626827(
    name: "postDescribeTargetHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_PostDescribeTargetHealth_21626828, base: "/",
    makeUrl: url_PostDescribeTargetHealth_21626829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetHealth_21626810 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeTargetHealth_21626812(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTargetHealth_21626811(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626813 = query.getOrDefault("Targets")
  valid_21626813 = validateParameter(valid_21626813, JArray, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "Targets", valid_21626813
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_21626814 = query.getOrDefault("TargetGroupArn")
  valid_21626814 = validateParameter(valid_21626814, JString, required = true,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "TargetGroupArn", valid_21626814
  var valid_21626815 = query.getOrDefault("Action")
  valid_21626815 = validateParameter(valid_21626815, JString, required = true,
                                   default = newJString("DescribeTargetHealth"))
  if valid_21626815 != nil:
    section.add "Action", valid_21626815
  var valid_21626816 = query.getOrDefault("Version")
  valid_21626816 = validateParameter(valid_21626816, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626816 != nil:
    section.add "Version", valid_21626816
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626817 = header.getOrDefault("X-Amz-Date")
  valid_21626817 = validateParameter(valid_21626817, JString, required = false,
                                   default = nil)
  if valid_21626817 != nil:
    section.add "X-Amz-Date", valid_21626817
  var valid_21626818 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626818 = validateParameter(valid_21626818, JString, required = false,
                                   default = nil)
  if valid_21626818 != nil:
    section.add "X-Amz-Security-Token", valid_21626818
  var valid_21626819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626819 = validateParameter(valid_21626819, JString, required = false,
                                   default = nil)
  if valid_21626819 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626819
  var valid_21626820 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626820 = validateParameter(valid_21626820, JString, required = false,
                                   default = nil)
  if valid_21626820 != nil:
    section.add "X-Amz-Algorithm", valid_21626820
  var valid_21626821 = header.getOrDefault("X-Amz-Signature")
  valid_21626821 = validateParameter(valid_21626821, JString, required = false,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "X-Amz-Signature", valid_21626821
  var valid_21626822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626822 = validateParameter(valid_21626822, JString, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626822
  var valid_21626823 = header.getOrDefault("X-Amz-Credential")
  valid_21626823 = validateParameter(valid_21626823, JString, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "X-Amz-Credential", valid_21626823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626824: Call_GetDescribeTargetHealth_21626810;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_21626824.validator(path, query, header, formData, body, _)
  let scheme = call_21626824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626824.makeUrl(scheme.get, call_21626824.host, call_21626824.base,
                               call_21626824.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626824, uri, valid, _)

proc call*(call_21626825: Call_GetDescribeTargetHealth_21626810;
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
  var query_21626826 = newJObject()
  if Targets != nil:
    query_21626826.add "Targets", Targets
  add(query_21626826, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_21626826, "Action", newJString(Action))
  add(query_21626826, "Version", newJString(Version))
  result = call_21626825.call(nil, query_21626826, nil, nil, nil)

var getDescribeTargetHealth* = Call_GetDescribeTargetHealth_21626810(
    name: "getDescribeTargetHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_GetDescribeTargetHealth_21626811, base: "/",
    makeUrl: url_GetDescribeTargetHealth_21626812,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyListener_21626866 = ref object of OpenApiRestCall_21625435
proc url_PostModifyListener_21626868(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyListener_21626867(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626869 = query.getOrDefault("Action")
  valid_21626869 = validateParameter(valid_21626869, JString, required = true,
                                   default = newJString("ModifyListener"))
  if valid_21626869 != nil:
    section.add "Action", valid_21626869
  var valid_21626870 = query.getOrDefault("Version")
  valid_21626870 = validateParameter(valid_21626870, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626870 != nil:
    section.add "Version", valid_21626870
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626871 = header.getOrDefault("X-Amz-Date")
  valid_21626871 = validateParameter(valid_21626871, JString, required = false,
                                   default = nil)
  if valid_21626871 != nil:
    section.add "X-Amz-Date", valid_21626871
  var valid_21626872 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626872 = validateParameter(valid_21626872, JString, required = false,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "X-Amz-Security-Token", valid_21626872
  var valid_21626873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626873
  var valid_21626874 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626874 = validateParameter(valid_21626874, JString, required = false,
                                   default = nil)
  if valid_21626874 != nil:
    section.add "X-Amz-Algorithm", valid_21626874
  var valid_21626875 = header.getOrDefault("X-Amz-Signature")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "X-Amz-Signature", valid_21626875
  var valid_21626876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626876 = validateParameter(valid_21626876, JString, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626876
  var valid_21626877 = header.getOrDefault("X-Amz-Credential")
  valid_21626877 = validateParameter(valid_21626877, JString, required = false,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "X-Amz-Credential", valid_21626877
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list, use <a>AddListenerCertificates</a>.</p>
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Port: JInt
  ##       : The port for connections from clients to the load balancer.
  ##   Protocol: JString
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   SslPolicy: JString
  ##            : [HTTPS and TLS listeners] The security policy that defines which protocols and ciphers are supported. For more information, see <a 
  ## href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.
  ##   DefaultActions: JArray
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  section = newJObject()
  var valid_21626878 = formData.getOrDefault("Certificates")
  valid_21626878 = validateParameter(valid_21626878, JArray, required = false,
                                   default = nil)
  if valid_21626878 != nil:
    section.add "Certificates", valid_21626878
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_21626879 = formData.getOrDefault("ListenerArn")
  valid_21626879 = validateParameter(valid_21626879, JString, required = true,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "ListenerArn", valid_21626879
  var valid_21626880 = formData.getOrDefault("Port")
  valid_21626880 = validateParameter(valid_21626880, JInt, required = false,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "Port", valid_21626880
  var valid_21626881 = formData.getOrDefault("Protocol")
  valid_21626881 = validateParameter(valid_21626881, JString, required = false,
                                   default = newJString("HTTP"))
  if valid_21626881 != nil:
    section.add "Protocol", valid_21626881
  var valid_21626882 = formData.getOrDefault("SslPolicy")
  valid_21626882 = validateParameter(valid_21626882, JString, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "SslPolicy", valid_21626882
  var valid_21626883 = formData.getOrDefault("DefaultActions")
  valid_21626883 = validateParameter(valid_21626883, JArray, required = false,
                                   default = nil)
  if valid_21626883 != nil:
    section.add "DefaultActions", valid_21626883
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626884: Call_PostModifyListener_21626866; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ## 
  let valid = call_21626884.validator(path, query, header, formData, body, _)
  let scheme = call_21626884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626884.makeUrl(scheme.get, call_21626884.host, call_21626884.base,
                               call_21626884.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626884, uri, valid, _)

proc call*(call_21626885: Call_PostModifyListener_21626866; ListenerArn: string;
          Certificates: JsonNode = nil; Port: int = 0; Protocol: string = "HTTP";
          Action: string = "ModifyListener"; SslPolicy: string = "";
          DefaultActions: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
  ## postModifyListener
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list, use <a>AddListenerCertificates</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Port: int
  ##       : The port for connections from clients to the load balancer.
  ##   Protocol: string
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   Action: string (required)
  ##   SslPolicy: string
  ##            : [HTTPS and TLS listeners] The security policy that defines which protocols and ciphers are supported. For more information, see <a 
  ## href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.
  ##   DefaultActions: JArray
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Version: string (required)
  var query_21626886 = newJObject()
  var formData_21626887 = newJObject()
  if Certificates != nil:
    formData_21626887.add "Certificates", Certificates
  add(formData_21626887, "ListenerArn", newJString(ListenerArn))
  add(formData_21626887, "Port", newJInt(Port))
  add(formData_21626887, "Protocol", newJString(Protocol))
  add(query_21626886, "Action", newJString(Action))
  add(formData_21626887, "SslPolicy", newJString(SslPolicy))
  if DefaultActions != nil:
    formData_21626887.add "DefaultActions", DefaultActions
  add(query_21626886, "Version", newJString(Version))
  result = call_21626885.call(nil, query_21626886, nil, formData_21626887, nil)

var postModifyListener* = Call_PostModifyListener_21626866(
    name: "postModifyListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=ModifyListener",
    validator: validate_PostModifyListener_21626867, base: "/",
    makeUrl: url_PostModifyListener_21626868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyListener_21626845 = ref object of OpenApiRestCall_21625435
proc url_GetModifyListener_21626847(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyListener_21626846(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DefaultActions: JArray
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   SslPolicy: JString
  ##            : [HTTPS and TLS listeners] The security policy that defines which protocols and ciphers are supported. For more information, see <a 
  ## href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.
  ##   Protocol: JString
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list, use <a>AddListenerCertificates</a>.</p>
  ##   Action: JString (required)
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Port: JInt
  ##       : The port for connections from clients to the load balancer.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626848 = query.getOrDefault("DefaultActions")
  valid_21626848 = validateParameter(valid_21626848, JArray, required = false,
                                   default = nil)
  if valid_21626848 != nil:
    section.add "DefaultActions", valid_21626848
  var valid_21626849 = query.getOrDefault("SslPolicy")
  valid_21626849 = validateParameter(valid_21626849, JString, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "SslPolicy", valid_21626849
  var valid_21626850 = query.getOrDefault("Protocol")
  valid_21626850 = validateParameter(valid_21626850, JString, required = false,
                                   default = newJString("HTTP"))
  if valid_21626850 != nil:
    section.add "Protocol", valid_21626850
  var valid_21626851 = query.getOrDefault("Certificates")
  valid_21626851 = validateParameter(valid_21626851, JArray, required = false,
                                   default = nil)
  if valid_21626851 != nil:
    section.add "Certificates", valid_21626851
  var valid_21626852 = query.getOrDefault("Action")
  valid_21626852 = validateParameter(valid_21626852, JString, required = true,
                                   default = newJString("ModifyListener"))
  if valid_21626852 != nil:
    section.add "Action", valid_21626852
  var valid_21626853 = query.getOrDefault("ListenerArn")
  valid_21626853 = validateParameter(valid_21626853, JString, required = true,
                                   default = nil)
  if valid_21626853 != nil:
    section.add "ListenerArn", valid_21626853
  var valid_21626854 = query.getOrDefault("Port")
  valid_21626854 = validateParameter(valid_21626854, JInt, required = false,
                                   default = nil)
  if valid_21626854 != nil:
    section.add "Port", valid_21626854
  var valid_21626855 = query.getOrDefault("Version")
  valid_21626855 = validateParameter(valid_21626855, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626855 != nil:
    section.add "Version", valid_21626855
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626856 = header.getOrDefault("X-Amz-Date")
  valid_21626856 = validateParameter(valid_21626856, JString, required = false,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "X-Amz-Date", valid_21626856
  var valid_21626857 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-Security-Token", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626858
  var valid_21626859 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626859 = validateParameter(valid_21626859, JString, required = false,
                                   default = nil)
  if valid_21626859 != nil:
    section.add "X-Amz-Algorithm", valid_21626859
  var valid_21626860 = header.getOrDefault("X-Amz-Signature")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-Signature", valid_21626860
  var valid_21626861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626861
  var valid_21626862 = header.getOrDefault("X-Amz-Credential")
  valid_21626862 = validateParameter(valid_21626862, JString, required = false,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "X-Amz-Credential", valid_21626862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626863: Call_GetModifyListener_21626845; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ## 
  let valid = call_21626863.validator(path, query, header, formData, body, _)
  let scheme = call_21626863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626863.makeUrl(scheme.get, call_21626863.host, call_21626863.base,
                               call_21626863.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626863, uri, valid, _)

proc call*(call_21626864: Call_GetModifyListener_21626845; ListenerArn: string;
          DefaultActions: JsonNode = nil; SslPolicy: string = "";
          Protocol: string = "HTTP"; Certificates: JsonNode = nil;
          Action: string = "ModifyListener"; Port: int = 0;
          Version: string = "2015-12-01"): Recallable =
  ## getModifyListener
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ##   DefaultActions: JArray
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   SslPolicy: string
  ##            : [HTTPS and TLS listeners] The security policy that defines which protocols and ciphers are supported. For more information, see <a 
  ## href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.
  ##   Protocol: string
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list, use <a>AddListenerCertificates</a>.</p>
  ##   Action: string (required)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Port: int
  ##       : The port for connections from clients to the load balancer.
  ##   Version: string (required)
  var query_21626865 = newJObject()
  if DefaultActions != nil:
    query_21626865.add "DefaultActions", DefaultActions
  add(query_21626865, "SslPolicy", newJString(SslPolicy))
  add(query_21626865, "Protocol", newJString(Protocol))
  if Certificates != nil:
    query_21626865.add "Certificates", Certificates
  add(query_21626865, "Action", newJString(Action))
  add(query_21626865, "ListenerArn", newJString(ListenerArn))
  add(query_21626865, "Port", newJInt(Port))
  add(query_21626865, "Version", newJString(Version))
  result = call_21626864.call(nil, query_21626865, nil, nil, nil)

var getModifyListener* = Call_GetModifyListener_21626845(name: "getModifyListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyListener", validator: validate_GetModifyListener_21626846,
    base: "/", makeUrl: url_GetModifyListener_21626847,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_21626905 = ref object of OpenApiRestCall_21625435
proc url_PostModifyLoadBalancerAttributes_21626907(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyLoadBalancerAttributes_21626906(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626908 = query.getOrDefault("Action")
  valid_21626908 = validateParameter(valid_21626908, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_21626908 != nil:
    section.add "Action", valid_21626908
  var valid_21626909 = query.getOrDefault("Version")
  valid_21626909 = validateParameter(valid_21626909, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626909 != nil:
    section.add "Version", valid_21626909
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626910 = header.getOrDefault("X-Amz-Date")
  valid_21626910 = validateParameter(valid_21626910, JString, required = false,
                                   default = nil)
  if valid_21626910 != nil:
    section.add "X-Amz-Date", valid_21626910
  var valid_21626911 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626911 = validateParameter(valid_21626911, JString, required = false,
                                   default = nil)
  if valid_21626911 != nil:
    section.add "X-Amz-Security-Token", valid_21626911
  var valid_21626912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626912 = validateParameter(valid_21626912, JString, required = false,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626912
  var valid_21626913 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "X-Amz-Algorithm", valid_21626913
  var valid_21626914 = header.getOrDefault("X-Amz-Signature")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "X-Amz-Signature", valid_21626914
  var valid_21626915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626915
  var valid_21626916 = header.getOrDefault("X-Amz-Credential")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "X-Amz-Credential", valid_21626916
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_21626917 = formData.getOrDefault("LoadBalancerArn")
  valid_21626917 = validateParameter(valid_21626917, JString, required = true,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "LoadBalancerArn", valid_21626917
  var valid_21626918 = formData.getOrDefault("Attributes")
  valid_21626918 = validateParameter(valid_21626918, JArray, required = true,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "Attributes", valid_21626918
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626919: Call_PostModifyLoadBalancerAttributes_21626905;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_21626919.validator(path, query, header, formData, body, _)
  let scheme = call_21626919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626919.makeUrl(scheme.get, call_21626919.host, call_21626919.base,
                               call_21626919.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626919, uri, valid, _)

proc call*(call_21626920: Call_PostModifyLoadBalancerAttributes_21626905;
          LoadBalancerArn: string; Attributes: JsonNode;
          Action: string = "ModifyLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postModifyLoadBalancerAttributes
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626921 = newJObject()
  var formData_21626922 = newJObject()
  add(formData_21626922, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Attributes != nil:
    formData_21626922.add "Attributes", Attributes
  add(query_21626921, "Action", newJString(Action))
  add(query_21626921, "Version", newJString(Version))
  result = call_21626920.call(nil, query_21626921, nil, formData_21626922, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_21626905(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_21626906, base: "/",
    makeUrl: url_PostModifyLoadBalancerAttributes_21626907,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_21626888 = ref object of OpenApiRestCall_21625435
proc url_GetModifyLoadBalancerAttributes_21626890(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyLoadBalancerAttributes_21626889(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Attributes` field"
  var valid_21626891 = query.getOrDefault("Attributes")
  valid_21626891 = validateParameter(valid_21626891, JArray, required = true,
                                   default = nil)
  if valid_21626891 != nil:
    section.add "Attributes", valid_21626891
  var valid_21626892 = query.getOrDefault("Action")
  valid_21626892 = validateParameter(valid_21626892, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_21626892 != nil:
    section.add "Action", valid_21626892
  var valid_21626893 = query.getOrDefault("LoadBalancerArn")
  valid_21626893 = validateParameter(valid_21626893, JString, required = true,
                                   default = nil)
  if valid_21626893 != nil:
    section.add "LoadBalancerArn", valid_21626893
  var valid_21626894 = query.getOrDefault("Version")
  valid_21626894 = validateParameter(valid_21626894, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626894 != nil:
    section.add "Version", valid_21626894
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626895 = header.getOrDefault("X-Amz-Date")
  valid_21626895 = validateParameter(valid_21626895, JString, required = false,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "X-Amz-Date", valid_21626895
  var valid_21626896 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626896 = validateParameter(valid_21626896, JString, required = false,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "X-Amz-Security-Token", valid_21626896
  var valid_21626897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626897
  var valid_21626898 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "X-Amz-Algorithm", valid_21626898
  var valid_21626899 = header.getOrDefault("X-Amz-Signature")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-Signature", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626900
  var valid_21626901 = header.getOrDefault("X-Amz-Credential")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "X-Amz-Credential", valid_21626901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626902: Call_GetModifyLoadBalancerAttributes_21626888;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_21626902.validator(path, query, header, formData, body, _)
  let scheme = call_21626902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626902.makeUrl(scheme.get, call_21626902.host, call_21626902.base,
                               call_21626902.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626902, uri, valid, _)

proc call*(call_21626903: Call_GetModifyLoadBalancerAttributes_21626888;
          Attributes: JsonNode; LoadBalancerArn: string;
          Action: string = "ModifyLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getModifyLoadBalancerAttributes
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_21626904 = newJObject()
  if Attributes != nil:
    query_21626904.add "Attributes", Attributes
  add(query_21626904, "Action", newJString(Action))
  add(query_21626904, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_21626904, "Version", newJString(Version))
  result = call_21626903.call(nil, query_21626904, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_21626888(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_21626889, base: "/",
    makeUrl: url_GetModifyLoadBalancerAttributes_21626890,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyRule_21626941 = ref object of OpenApiRestCall_21625435
proc url_PostModifyRule_21626943(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyRule_21626942(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626944 = query.getOrDefault("Action")
  valid_21626944 = validateParameter(valid_21626944, JString, required = true,
                                   default = newJString("ModifyRule"))
  if valid_21626944 != nil:
    section.add "Action", valid_21626944
  var valid_21626945 = query.getOrDefault("Version")
  valid_21626945 = validateParameter(valid_21626945, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626945 != nil:
    section.add "Version", valid_21626945
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626946 = header.getOrDefault("X-Amz-Date")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "X-Amz-Date", valid_21626946
  var valid_21626947 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Security-Token", valid_21626947
  var valid_21626948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626948
  var valid_21626949 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626949 = validateParameter(valid_21626949, JString, required = false,
                                   default = nil)
  if valid_21626949 != nil:
    section.add "X-Amz-Algorithm", valid_21626949
  var valid_21626950 = header.getOrDefault("X-Amz-Signature")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-Signature", valid_21626950
  var valid_21626951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626951
  var valid_21626952 = header.getOrDefault("X-Amz-Credential")
  valid_21626952 = validateParameter(valid_21626952, JString, required = false,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "X-Amz-Credential", valid_21626952
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_21626953 = formData.getOrDefault("RuleArn")
  valid_21626953 = validateParameter(valid_21626953, JString, required = true,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "RuleArn", valid_21626953
  var valid_21626954 = formData.getOrDefault("Actions")
  valid_21626954 = validateParameter(valid_21626954, JArray, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "Actions", valid_21626954
  var valid_21626955 = formData.getOrDefault("Conditions")
  valid_21626955 = validateParameter(valid_21626955, JArray, required = false,
                                   default = nil)
  if valid_21626955 != nil:
    section.add "Conditions", valid_21626955
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626956: Call_PostModifyRule_21626941; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_21626956.validator(path, query, header, formData, body, _)
  let scheme = call_21626956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626956.makeUrl(scheme.get, call_21626956.host, call_21626956.base,
                               call_21626956.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626956, uri, valid, _)

proc call*(call_21626957: Call_PostModifyRule_21626941; RuleArn: string;
          Actions: JsonNode = nil; Conditions: JsonNode = nil;
          Action: string = "ModifyRule"; Version: string = "2015-12-01"): Recallable =
  ## postModifyRule
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626958 = newJObject()
  var formData_21626959 = newJObject()
  add(formData_21626959, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    formData_21626959.add "Actions", Actions
  if Conditions != nil:
    formData_21626959.add "Conditions", Conditions
  add(query_21626958, "Action", newJString(Action))
  add(query_21626958, "Version", newJString(Version))
  result = call_21626957.call(nil, query_21626958, nil, formData_21626959, nil)

var postModifyRule* = Call_PostModifyRule_21626941(name: "postModifyRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_PostModifyRule_21626942,
    base: "/", makeUrl: url_PostModifyRule_21626943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyRule_21626923 = ref object of OpenApiRestCall_21625435
proc url_GetModifyRule_21626925(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyRule_21626924(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   Action: JString (required)
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626926 = query.getOrDefault("Conditions")
  valid_21626926 = validateParameter(valid_21626926, JArray, required = false,
                                   default = nil)
  if valid_21626926 != nil:
    section.add "Conditions", valid_21626926
  var valid_21626927 = query.getOrDefault("Action")
  valid_21626927 = validateParameter(valid_21626927, JString, required = true,
                                   default = newJString("ModifyRule"))
  if valid_21626927 != nil:
    section.add "Action", valid_21626927
  var valid_21626928 = query.getOrDefault("RuleArn")
  valid_21626928 = validateParameter(valid_21626928, JString, required = true,
                                   default = nil)
  if valid_21626928 != nil:
    section.add "RuleArn", valid_21626928
  var valid_21626929 = query.getOrDefault("Actions")
  valid_21626929 = validateParameter(valid_21626929, JArray, required = false,
                                   default = nil)
  if valid_21626929 != nil:
    section.add "Actions", valid_21626929
  var valid_21626930 = query.getOrDefault("Version")
  valid_21626930 = validateParameter(valid_21626930, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626930 != nil:
    section.add "Version", valid_21626930
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626931 = header.getOrDefault("X-Amz-Date")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "X-Amz-Date", valid_21626931
  var valid_21626932 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-Security-Token", valid_21626932
  var valid_21626933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626933
  var valid_21626934 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626934 = validateParameter(valid_21626934, JString, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "X-Amz-Algorithm", valid_21626934
  var valid_21626935 = header.getOrDefault("X-Amz-Signature")
  valid_21626935 = validateParameter(valid_21626935, JString, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "X-Amz-Signature", valid_21626935
  var valid_21626936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626936 = validateParameter(valid_21626936, JString, required = false,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626936
  var valid_21626937 = header.getOrDefault("X-Amz-Credential")
  valid_21626937 = validateParameter(valid_21626937, JString, required = false,
                                   default = nil)
  if valid_21626937 != nil:
    section.add "X-Amz-Credential", valid_21626937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626938: Call_GetModifyRule_21626923; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_21626938.validator(path, query, header, formData, body, _)
  let scheme = call_21626938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626938.makeUrl(scheme.get, call_21626938.host, call_21626938.base,
                               call_21626938.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626938, uri, valid, _)

proc call*(call_21626939: Call_GetModifyRule_21626923; RuleArn: string;
          Conditions: JsonNode = nil; Action: string = "ModifyRule";
          Actions: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
  ## getModifyRule
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   Action: string (required)
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Version: string (required)
  var query_21626940 = newJObject()
  if Conditions != nil:
    query_21626940.add "Conditions", Conditions
  add(query_21626940, "Action", newJString(Action))
  add(query_21626940, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    query_21626940.add "Actions", Actions
  add(query_21626940, "Version", newJString(Version))
  result = call_21626939.call(nil, query_21626940, nil, nil, nil)

var getModifyRule* = Call_GetModifyRule_21626923(name: "getModifyRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_GetModifyRule_21626924,
    base: "/", makeUrl: url_GetModifyRule_21626925,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroup_21626985 = ref object of OpenApiRestCall_21625435
proc url_PostModifyTargetGroup_21626987(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyTargetGroup_21626986(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626988 = query.getOrDefault("Action")
  valid_21626988 = validateParameter(valid_21626988, JString, required = true,
                                   default = newJString("ModifyTargetGroup"))
  if valid_21626988 != nil:
    section.add "Action", valid_21626988
  var valid_21626989 = query.getOrDefault("Version")
  valid_21626989 = validateParameter(valid_21626989, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626989 != nil:
    section.add "Version", valid_21626989
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626990 = header.getOrDefault("X-Amz-Date")
  valid_21626990 = validateParameter(valid_21626990, JString, required = false,
                                   default = nil)
  if valid_21626990 != nil:
    section.add "X-Amz-Date", valid_21626990
  var valid_21626991 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626991 = validateParameter(valid_21626991, JString, required = false,
                                   default = nil)
  if valid_21626991 != nil:
    section.add "X-Amz-Security-Token", valid_21626991
  var valid_21626992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626992 = validateParameter(valid_21626992, JString, required = false,
                                   default = nil)
  if valid_21626992 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626992
  var valid_21626993 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626993 = validateParameter(valid_21626993, JString, required = false,
                                   default = nil)
  if valid_21626993 != nil:
    section.add "X-Amz-Algorithm", valid_21626993
  var valid_21626994 = header.getOrDefault("X-Amz-Signature")
  valid_21626994 = validateParameter(valid_21626994, JString, required = false,
                                   default = nil)
  if valid_21626994 != nil:
    section.add "X-Amz-Signature", valid_21626994
  var valid_21626995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626995 = validateParameter(valid_21626995, JString, required = false,
                                   default = nil)
  if valid_21626995 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626995
  var valid_21626996 = header.getOrDefault("X-Amz-Credential")
  valid_21626996 = validateParameter(valid_21626996, JString, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "X-Amz-Credential", valid_21626996
  result.add "header", section
  ## parameters in `formData` object:
  ##   HealthCheckTimeoutSeconds: JInt
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   HealthCheckPort: JString
  ##                  : The port the load balancer uses when performing health checks on targets.
  ##   UnhealthyThresholdCount: JInt
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   HealthCheckPath: JString
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination for the health check request.
  ##   HealthCheckEnabled: JBool
  ##                     : Indicates whether health checks are enabled.
  ##   HealthCheckIntervalSeconds: JInt
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   HealthyThresholdCount: JInt
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   HealthCheckProtocol: JString
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   Matcher.HttpCode: JString
  ##                   : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_21626997 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_21626997 = validateParameter(valid_21626997, JInt, required = false,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_21626997
  var valid_21626998 = formData.getOrDefault("HealthCheckPort")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "HealthCheckPort", valid_21626998
  var valid_21626999 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_21626999 = validateParameter(valid_21626999, JInt, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "UnhealthyThresholdCount", valid_21626999
  var valid_21627000 = formData.getOrDefault("HealthCheckPath")
  valid_21627000 = validateParameter(valid_21627000, JString, required = false,
                                   default = nil)
  if valid_21627000 != nil:
    section.add "HealthCheckPath", valid_21627000
  var valid_21627001 = formData.getOrDefault("HealthCheckEnabled")
  valid_21627001 = validateParameter(valid_21627001, JBool, required = false,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "HealthCheckEnabled", valid_21627001
  var valid_21627002 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_21627002 = validateParameter(valid_21627002, JInt, required = false,
                                   default = nil)
  if valid_21627002 != nil:
    section.add "HealthCheckIntervalSeconds", valid_21627002
  var valid_21627003 = formData.getOrDefault("HealthyThresholdCount")
  valid_21627003 = validateParameter(valid_21627003, JInt, required = false,
                                   default = nil)
  if valid_21627003 != nil:
    section.add "HealthyThresholdCount", valid_21627003
  var valid_21627004 = formData.getOrDefault("HealthCheckProtocol")
  valid_21627004 = validateParameter(valid_21627004, JString, required = false,
                                   default = newJString("HTTP"))
  if valid_21627004 != nil:
    section.add "HealthCheckProtocol", valid_21627004
  var valid_21627005 = formData.getOrDefault("Matcher.HttpCode")
  valid_21627005 = validateParameter(valid_21627005, JString, required = false,
                                   default = nil)
  if valid_21627005 != nil:
    section.add "Matcher.HttpCode", valid_21627005
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_21627006 = formData.getOrDefault("TargetGroupArn")
  valid_21627006 = validateParameter(valid_21627006, JString, required = true,
                                   default = nil)
  if valid_21627006 != nil:
    section.add "TargetGroupArn", valid_21627006
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627007: Call_PostModifyTargetGroup_21626985;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_21627007.validator(path, query, header, formData, body, _)
  let scheme = call_21627007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627007.makeUrl(scheme.get, call_21627007.host, call_21627007.base,
                               call_21627007.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627007, uri, valid, _)

proc call*(call_21627008: Call_PostModifyTargetGroup_21626985;
          TargetGroupArn: string; HealthCheckTimeoutSeconds: int = 0;
          HealthCheckPort: string = ""; UnhealthyThresholdCount: int = 0;
          HealthCheckPath: string = ""; HealthCheckEnabled: bool = false;
          Action: string = "ModifyTargetGroup"; HealthCheckIntervalSeconds: int = 0;
          HealthyThresholdCount: int = 0; HealthCheckProtocol: string = "HTTP";
          MatcherHttpCode: string = ""; Version: string = "2015-12-01"): Recallable =
  ## postModifyTargetGroup
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ##   HealthCheckTimeoutSeconds: int
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   HealthCheckPort: string
  ##                  : The port the load balancer uses when performing health checks on targets.
  ##   UnhealthyThresholdCount: int
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   HealthCheckPath: string
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination for the health check request.
  ##   HealthCheckEnabled: bool
  ##                     : Indicates whether health checks are enabled.
  ##   Action: string (required)
  ##   HealthCheckIntervalSeconds: int
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   HealthyThresholdCount: int
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   HealthCheckProtocol: string
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   MatcherHttpCode: string
  ##                  : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_21627009 = newJObject()
  var formData_21627010 = newJObject()
  add(formData_21627010, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_21627010, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_21627010, "UnhealthyThresholdCount",
      newJInt(UnhealthyThresholdCount))
  add(formData_21627010, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_21627010, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_21627009, "Action", newJString(Action))
  add(formData_21627010, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_21627010, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_21627010, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_21627010, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(formData_21627010, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_21627009, "Version", newJString(Version))
  result = call_21627008.call(nil, query_21627009, nil, formData_21627010, nil)

var postModifyTargetGroup* = Call_PostModifyTargetGroup_21626985(
    name: "postModifyTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup",
    validator: validate_PostModifyTargetGroup_21626986, base: "/",
    makeUrl: url_PostModifyTargetGroup_21626987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroup_21626960 = ref object of OpenApiRestCall_21625435
proc url_GetModifyTargetGroup_21626962(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyTargetGroup_21626961(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   HealthCheckEnabled: JBool
  ##                     : Indicates whether health checks are enabled.
  ##   HealthCheckIntervalSeconds: JInt
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   HealthCheckPort: JString
  ##                  : The port the load balancer uses when performing health checks on targets.
  ##   Action: JString (required)
  ##   HealthCheckTimeoutSeconds: JInt
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   Matcher.HttpCode: JString
  ##                   : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   UnhealthyThresholdCount: JInt
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   HealthCheckProtocol: JString
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   HealthyThresholdCount: JInt
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   Version: JString (required)
  ##   HealthCheckPath: JString
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination for the health check request.
  section = newJObject()
  var valid_21626963 = query.getOrDefault("HealthCheckEnabled")
  valid_21626963 = validateParameter(valid_21626963, JBool, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "HealthCheckEnabled", valid_21626963
  var valid_21626964 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_21626964 = validateParameter(valid_21626964, JInt, required = false,
                                   default = nil)
  if valid_21626964 != nil:
    section.add "HealthCheckIntervalSeconds", valid_21626964
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_21626965 = query.getOrDefault("TargetGroupArn")
  valid_21626965 = validateParameter(valid_21626965, JString, required = true,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "TargetGroupArn", valid_21626965
  var valid_21626966 = query.getOrDefault("HealthCheckPort")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "HealthCheckPort", valid_21626966
  var valid_21626967 = query.getOrDefault("Action")
  valid_21626967 = validateParameter(valid_21626967, JString, required = true,
                                   default = newJString("ModifyTargetGroup"))
  if valid_21626967 != nil:
    section.add "Action", valid_21626967
  var valid_21626968 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_21626968 = validateParameter(valid_21626968, JInt, required = false,
                                   default = nil)
  if valid_21626968 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_21626968
  var valid_21626969 = query.getOrDefault("Matcher.HttpCode")
  valid_21626969 = validateParameter(valid_21626969, JString, required = false,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "Matcher.HttpCode", valid_21626969
  var valid_21626970 = query.getOrDefault("UnhealthyThresholdCount")
  valid_21626970 = validateParameter(valid_21626970, JInt, required = false,
                                   default = nil)
  if valid_21626970 != nil:
    section.add "UnhealthyThresholdCount", valid_21626970
  var valid_21626971 = query.getOrDefault("HealthCheckProtocol")
  valid_21626971 = validateParameter(valid_21626971, JString, required = false,
                                   default = newJString("HTTP"))
  if valid_21626971 != nil:
    section.add "HealthCheckProtocol", valid_21626971
  var valid_21626972 = query.getOrDefault("HealthyThresholdCount")
  valid_21626972 = validateParameter(valid_21626972, JInt, required = false,
                                   default = nil)
  if valid_21626972 != nil:
    section.add "HealthyThresholdCount", valid_21626972
  var valid_21626973 = query.getOrDefault("Version")
  valid_21626973 = validateParameter(valid_21626973, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21626973 != nil:
    section.add "Version", valid_21626973
  var valid_21626974 = query.getOrDefault("HealthCheckPath")
  valid_21626974 = validateParameter(valid_21626974, JString, required = false,
                                   default = nil)
  if valid_21626974 != nil:
    section.add "HealthCheckPath", valid_21626974
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626975 = header.getOrDefault("X-Amz-Date")
  valid_21626975 = validateParameter(valid_21626975, JString, required = false,
                                   default = nil)
  if valid_21626975 != nil:
    section.add "X-Amz-Date", valid_21626975
  var valid_21626976 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626976 = validateParameter(valid_21626976, JString, required = false,
                                   default = nil)
  if valid_21626976 != nil:
    section.add "X-Amz-Security-Token", valid_21626976
  var valid_21626977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626977 = validateParameter(valid_21626977, JString, required = false,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626977
  var valid_21626978 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "X-Amz-Algorithm", valid_21626978
  var valid_21626979 = header.getOrDefault("X-Amz-Signature")
  valid_21626979 = validateParameter(valid_21626979, JString, required = false,
                                   default = nil)
  if valid_21626979 != nil:
    section.add "X-Amz-Signature", valid_21626979
  var valid_21626980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626980 = validateParameter(valid_21626980, JString, required = false,
                                   default = nil)
  if valid_21626980 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626980
  var valid_21626981 = header.getOrDefault("X-Amz-Credential")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-Credential", valid_21626981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626982: Call_GetModifyTargetGroup_21626960; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_21626982.validator(path, query, header, formData, body, _)
  let scheme = call_21626982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626982.makeUrl(scheme.get, call_21626982.host, call_21626982.base,
                               call_21626982.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626982, uri, valid, _)

proc call*(call_21626983: Call_GetModifyTargetGroup_21626960;
          TargetGroupArn: string; HealthCheckEnabled: bool = false;
          HealthCheckIntervalSeconds: int = 0; HealthCheckPort: string = "";
          Action: string = "ModifyTargetGroup"; HealthCheckTimeoutSeconds: int = 0;
          MatcherHttpCode: string = ""; UnhealthyThresholdCount: int = 0;
          HealthCheckProtocol: string = "HTTP"; HealthyThresholdCount: int = 0;
          Version: string = "2015-12-01"; HealthCheckPath: string = ""): Recallable =
  ## getModifyTargetGroup
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ##   HealthCheckEnabled: bool
  ##                     : Indicates whether health checks are enabled.
  ##   HealthCheckIntervalSeconds: int
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   HealthCheckPort: string
  ##                  : The port the load balancer uses when performing health checks on targets.
  ##   Action: string (required)
  ##   HealthCheckTimeoutSeconds: int
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   MatcherHttpCode: string
  ##                  : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   UnhealthyThresholdCount: int
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   HealthCheckProtocol: string
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>With Network Load Balancers, you can't modify this setting.</p>
  ##   HealthyThresholdCount: int
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   Version: string (required)
  ##   HealthCheckPath: string
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination for the health check request.
  var query_21626984 = newJObject()
  add(query_21626984, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_21626984, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_21626984, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_21626984, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_21626984, "Action", newJString(Action))
  add(query_21626984, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_21626984, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_21626984, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_21626984, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_21626984, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_21626984, "Version", newJString(Version))
  add(query_21626984, "HealthCheckPath", newJString(HealthCheckPath))
  result = call_21626983.call(nil, query_21626984, nil, nil, nil)

var getModifyTargetGroup* = Call_GetModifyTargetGroup_21626960(
    name: "getModifyTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup", validator: validate_GetModifyTargetGroup_21626961,
    base: "/", makeUrl: url_GetModifyTargetGroup_21626962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroupAttributes_21627028 = ref object of OpenApiRestCall_21625435
proc url_PostModifyTargetGroupAttributes_21627030(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyTargetGroupAttributes_21627029(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627031 = query.getOrDefault("Action")
  valid_21627031 = validateParameter(valid_21627031, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_21627031 != nil:
    section.add "Action", valid_21627031
  var valid_21627032 = query.getOrDefault("Version")
  valid_21627032 = validateParameter(valid_21627032, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627032 != nil:
    section.add "Version", valid_21627032
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627033 = header.getOrDefault("X-Amz-Date")
  valid_21627033 = validateParameter(valid_21627033, JString, required = false,
                                   default = nil)
  if valid_21627033 != nil:
    section.add "X-Amz-Date", valid_21627033
  var valid_21627034 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627034 = validateParameter(valid_21627034, JString, required = false,
                                   default = nil)
  if valid_21627034 != nil:
    section.add "X-Amz-Security-Token", valid_21627034
  var valid_21627035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627035 = validateParameter(valid_21627035, JString, required = false,
                                   default = nil)
  if valid_21627035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627035
  var valid_21627036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627036 = validateParameter(valid_21627036, JString, required = false,
                                   default = nil)
  if valid_21627036 != nil:
    section.add "X-Amz-Algorithm", valid_21627036
  var valid_21627037 = header.getOrDefault("X-Amz-Signature")
  valid_21627037 = validateParameter(valid_21627037, JString, required = false,
                                   default = nil)
  if valid_21627037 != nil:
    section.add "X-Amz-Signature", valid_21627037
  var valid_21627038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627038 = validateParameter(valid_21627038, JString, required = false,
                                   default = nil)
  if valid_21627038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627038
  var valid_21627039 = header.getOrDefault("X-Amz-Credential")
  valid_21627039 = validateParameter(valid_21627039, JString, required = false,
                                   default = nil)
  if valid_21627039 != nil:
    section.add "X-Amz-Credential", valid_21627039
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_21627040 = formData.getOrDefault("Attributes")
  valid_21627040 = validateParameter(valid_21627040, JArray, required = true,
                                   default = nil)
  if valid_21627040 != nil:
    section.add "Attributes", valid_21627040
  var valid_21627041 = formData.getOrDefault("TargetGroupArn")
  valid_21627041 = validateParameter(valid_21627041, JString, required = true,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "TargetGroupArn", valid_21627041
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627042: Call_PostModifyTargetGroupAttributes_21627028;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_21627042.validator(path, query, header, formData, body, _)
  let scheme = call_21627042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627042.makeUrl(scheme.get, call_21627042.host, call_21627042.base,
                               call_21627042.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627042, uri, valid, _)

proc call*(call_21627043: Call_PostModifyTargetGroupAttributes_21627028;
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
  var query_21627044 = newJObject()
  var formData_21627045 = newJObject()
  if Attributes != nil:
    formData_21627045.add "Attributes", Attributes
  add(query_21627044, "Action", newJString(Action))
  add(formData_21627045, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_21627044, "Version", newJString(Version))
  result = call_21627043.call(nil, query_21627044, nil, formData_21627045, nil)

var postModifyTargetGroupAttributes* = Call_PostModifyTargetGroupAttributes_21627028(
    name: "postModifyTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_PostModifyTargetGroupAttributes_21627029, base: "/",
    makeUrl: url_PostModifyTargetGroupAttributes_21627030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroupAttributes_21627011 = ref object of OpenApiRestCall_21625435
proc url_GetModifyTargetGroupAttributes_21627013(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyTargetGroupAttributes_21627012(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627014 = query.getOrDefault("TargetGroupArn")
  valid_21627014 = validateParameter(valid_21627014, JString, required = true,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "TargetGroupArn", valid_21627014
  var valid_21627015 = query.getOrDefault("Attributes")
  valid_21627015 = validateParameter(valid_21627015, JArray, required = true,
                                   default = nil)
  if valid_21627015 != nil:
    section.add "Attributes", valid_21627015
  var valid_21627016 = query.getOrDefault("Action")
  valid_21627016 = validateParameter(valid_21627016, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_21627016 != nil:
    section.add "Action", valid_21627016
  var valid_21627017 = query.getOrDefault("Version")
  valid_21627017 = validateParameter(valid_21627017, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627017 != nil:
    section.add "Version", valid_21627017
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627018 = header.getOrDefault("X-Amz-Date")
  valid_21627018 = validateParameter(valid_21627018, JString, required = false,
                                   default = nil)
  if valid_21627018 != nil:
    section.add "X-Amz-Date", valid_21627018
  var valid_21627019 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627019 = validateParameter(valid_21627019, JString, required = false,
                                   default = nil)
  if valid_21627019 != nil:
    section.add "X-Amz-Security-Token", valid_21627019
  var valid_21627020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627020 = validateParameter(valid_21627020, JString, required = false,
                                   default = nil)
  if valid_21627020 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627020
  var valid_21627021 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627021 = validateParameter(valid_21627021, JString, required = false,
                                   default = nil)
  if valid_21627021 != nil:
    section.add "X-Amz-Algorithm", valid_21627021
  var valid_21627022 = header.getOrDefault("X-Amz-Signature")
  valid_21627022 = validateParameter(valid_21627022, JString, required = false,
                                   default = nil)
  if valid_21627022 != nil:
    section.add "X-Amz-Signature", valid_21627022
  var valid_21627023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627023
  var valid_21627024 = header.getOrDefault("X-Amz-Credential")
  valid_21627024 = validateParameter(valid_21627024, JString, required = false,
                                   default = nil)
  if valid_21627024 != nil:
    section.add "X-Amz-Credential", valid_21627024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627025: Call_GetModifyTargetGroupAttributes_21627011;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_21627025.validator(path, query, header, formData, body, _)
  let scheme = call_21627025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627025.makeUrl(scheme.get, call_21627025.host, call_21627025.base,
                               call_21627025.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627025, uri, valid, _)

proc call*(call_21627026: Call_GetModifyTargetGroupAttributes_21627011;
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
  var query_21627027 = newJObject()
  add(query_21627027, "TargetGroupArn", newJString(TargetGroupArn))
  if Attributes != nil:
    query_21627027.add "Attributes", Attributes
  add(query_21627027, "Action", newJString(Action))
  add(query_21627027, "Version", newJString(Version))
  result = call_21627026.call(nil, query_21627027, nil, nil, nil)

var getModifyTargetGroupAttributes* = Call_GetModifyTargetGroupAttributes_21627011(
    name: "getModifyTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_GetModifyTargetGroupAttributes_21627012, base: "/",
    makeUrl: url_GetModifyTargetGroupAttributes_21627013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterTargets_21627063 = ref object of OpenApiRestCall_21625435
proc url_PostRegisterTargets_21627065(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRegisterTargets_21627064(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627066 = query.getOrDefault("Action")
  valid_21627066 = validateParameter(valid_21627066, JString, required = true,
                                   default = newJString("RegisterTargets"))
  if valid_21627066 != nil:
    section.add "Action", valid_21627066
  var valid_21627067 = query.getOrDefault("Version")
  valid_21627067 = validateParameter(valid_21627067, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627067 != nil:
    section.add "Version", valid_21627067
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627068 = header.getOrDefault("X-Amz-Date")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "X-Amz-Date", valid_21627068
  var valid_21627069 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627069 = validateParameter(valid_21627069, JString, required = false,
                                   default = nil)
  if valid_21627069 != nil:
    section.add "X-Amz-Security-Token", valid_21627069
  var valid_21627070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627070 = validateParameter(valid_21627070, JString, required = false,
                                   default = nil)
  if valid_21627070 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627070
  var valid_21627071 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627071 = validateParameter(valid_21627071, JString, required = false,
                                   default = nil)
  if valid_21627071 != nil:
    section.add "X-Amz-Algorithm", valid_21627071
  var valid_21627072 = header.getOrDefault("X-Amz-Signature")
  valid_21627072 = validateParameter(valid_21627072, JString, required = false,
                                   default = nil)
  if valid_21627072 != nil:
    section.add "X-Amz-Signature", valid_21627072
  var valid_21627073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627073 = validateParameter(valid_21627073, JString, required = false,
                                   default = nil)
  if valid_21627073 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627073
  var valid_21627074 = header.getOrDefault("X-Amz-Credential")
  valid_21627074 = validateParameter(valid_21627074, JString, required = false,
                                   default = nil)
  if valid_21627074 != nil:
    section.add "X-Amz-Credential", valid_21627074
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_21627075 = formData.getOrDefault("Targets")
  valid_21627075 = validateParameter(valid_21627075, JArray, required = true,
                                   default = nil)
  if valid_21627075 != nil:
    section.add "Targets", valid_21627075
  var valid_21627076 = formData.getOrDefault("TargetGroupArn")
  valid_21627076 = validateParameter(valid_21627076, JString, required = true,
                                   default = nil)
  if valid_21627076 != nil:
    section.add "TargetGroupArn", valid_21627076
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627077: Call_PostRegisterTargets_21627063; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_21627077.validator(path, query, header, formData, body, _)
  let scheme = call_21627077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627077.makeUrl(scheme.get, call_21627077.host, call_21627077.base,
                               call_21627077.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627077, uri, valid, _)

proc call*(call_21627078: Call_PostRegisterTargets_21627063; Targets: JsonNode;
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
  var query_21627079 = newJObject()
  var formData_21627080 = newJObject()
  if Targets != nil:
    formData_21627080.add "Targets", Targets
  add(query_21627079, "Action", newJString(Action))
  add(formData_21627080, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_21627079, "Version", newJString(Version))
  result = call_21627078.call(nil, query_21627079, nil, formData_21627080, nil)

var postRegisterTargets* = Call_PostRegisterTargets_21627063(
    name: "postRegisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_PostRegisterTargets_21627064, base: "/",
    makeUrl: url_PostRegisterTargets_21627065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterTargets_21627046 = ref object of OpenApiRestCall_21625435
proc url_GetRegisterTargets_21627048(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRegisterTargets_21627047(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627049 = query.getOrDefault("Targets")
  valid_21627049 = validateParameter(valid_21627049, JArray, required = true,
                                   default = nil)
  if valid_21627049 != nil:
    section.add "Targets", valid_21627049
  var valid_21627050 = query.getOrDefault("TargetGroupArn")
  valid_21627050 = validateParameter(valid_21627050, JString, required = true,
                                   default = nil)
  if valid_21627050 != nil:
    section.add "TargetGroupArn", valid_21627050
  var valid_21627051 = query.getOrDefault("Action")
  valid_21627051 = validateParameter(valid_21627051, JString, required = true,
                                   default = newJString("RegisterTargets"))
  if valid_21627051 != nil:
    section.add "Action", valid_21627051
  var valid_21627052 = query.getOrDefault("Version")
  valid_21627052 = validateParameter(valid_21627052, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627052 != nil:
    section.add "Version", valid_21627052
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627053 = header.getOrDefault("X-Amz-Date")
  valid_21627053 = validateParameter(valid_21627053, JString, required = false,
                                   default = nil)
  if valid_21627053 != nil:
    section.add "X-Amz-Date", valid_21627053
  var valid_21627054 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627054 = validateParameter(valid_21627054, JString, required = false,
                                   default = nil)
  if valid_21627054 != nil:
    section.add "X-Amz-Security-Token", valid_21627054
  var valid_21627055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627055 = validateParameter(valid_21627055, JString, required = false,
                                   default = nil)
  if valid_21627055 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627055
  var valid_21627056 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627056 = validateParameter(valid_21627056, JString, required = false,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "X-Amz-Algorithm", valid_21627056
  var valid_21627057 = header.getOrDefault("X-Amz-Signature")
  valid_21627057 = validateParameter(valid_21627057, JString, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "X-Amz-Signature", valid_21627057
  var valid_21627058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627058 = validateParameter(valid_21627058, JString, required = false,
                                   default = nil)
  if valid_21627058 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627058
  var valid_21627059 = header.getOrDefault("X-Amz-Credential")
  valid_21627059 = validateParameter(valid_21627059, JString, required = false,
                                   default = nil)
  if valid_21627059 != nil:
    section.add "X-Amz-Credential", valid_21627059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627060: Call_GetRegisterTargets_21627046; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_21627060.validator(path, query, header, formData, body, _)
  let scheme = call_21627060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627060.makeUrl(scheme.get, call_21627060.host, call_21627060.base,
                               call_21627060.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627060, uri, valid, _)

proc call*(call_21627061: Call_GetRegisterTargets_21627046; Targets: JsonNode;
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
  var query_21627062 = newJObject()
  if Targets != nil:
    query_21627062.add "Targets", Targets
  add(query_21627062, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_21627062, "Action", newJString(Action))
  add(query_21627062, "Version", newJString(Version))
  result = call_21627061.call(nil, query_21627062, nil, nil, nil)

var getRegisterTargets* = Call_GetRegisterTargets_21627046(
    name: "getRegisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_GetRegisterTargets_21627047, base: "/",
    makeUrl: url_GetRegisterTargets_21627048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveListenerCertificates_21627098 = ref object of OpenApiRestCall_21625435
proc url_PostRemoveListenerCertificates_21627100(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveListenerCertificates_21627099(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627101 = query.getOrDefault("Action")
  valid_21627101 = validateParameter(valid_21627101, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_21627101 != nil:
    section.add "Action", valid_21627101
  var valid_21627102 = query.getOrDefault("Version")
  valid_21627102 = validateParameter(valid_21627102, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627102 != nil:
    section.add "Version", valid_21627102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627103 = header.getOrDefault("X-Amz-Date")
  valid_21627103 = validateParameter(valid_21627103, JString, required = false,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "X-Amz-Date", valid_21627103
  var valid_21627104 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "X-Amz-Security-Token", valid_21627104
  var valid_21627105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627105 = validateParameter(valid_21627105, JString, required = false,
                                   default = nil)
  if valid_21627105 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627105
  var valid_21627106 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627106 = validateParameter(valid_21627106, JString, required = false,
                                   default = nil)
  if valid_21627106 != nil:
    section.add "X-Amz-Algorithm", valid_21627106
  var valid_21627107 = header.getOrDefault("X-Amz-Signature")
  valid_21627107 = validateParameter(valid_21627107, JString, required = false,
                                   default = nil)
  if valid_21627107 != nil:
    section.add "X-Amz-Signature", valid_21627107
  var valid_21627108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627108 = validateParameter(valid_21627108, JString, required = false,
                                   default = nil)
  if valid_21627108 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627108
  var valid_21627109 = header.getOrDefault("X-Amz-Credential")
  valid_21627109 = validateParameter(valid_21627109, JString, required = false,
                                   default = nil)
  if valid_21627109 != nil:
    section.add "X-Amz-Credential", valid_21627109
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_21627110 = formData.getOrDefault("Certificates")
  valid_21627110 = validateParameter(valid_21627110, JArray, required = true,
                                   default = nil)
  if valid_21627110 != nil:
    section.add "Certificates", valid_21627110
  var valid_21627111 = formData.getOrDefault("ListenerArn")
  valid_21627111 = validateParameter(valid_21627111, JString, required = true,
                                   default = nil)
  if valid_21627111 != nil:
    section.add "ListenerArn", valid_21627111
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627112: Call_PostRemoveListenerCertificates_21627098;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_21627112.validator(path, query, header, formData, body, _)
  let scheme = call_21627112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627112.makeUrl(scheme.get, call_21627112.host, call_21627112.base,
                               call_21627112.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627112, uri, valid, _)

proc call*(call_21627113: Call_PostRemoveListenerCertificates_21627098;
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
  var query_21627114 = newJObject()
  var formData_21627115 = newJObject()
  if Certificates != nil:
    formData_21627115.add "Certificates", Certificates
  add(formData_21627115, "ListenerArn", newJString(ListenerArn))
  add(query_21627114, "Action", newJString(Action))
  add(query_21627114, "Version", newJString(Version))
  result = call_21627113.call(nil, query_21627114, nil, formData_21627115, nil)

var postRemoveListenerCertificates* = Call_PostRemoveListenerCertificates_21627098(
    name: "postRemoveListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_PostRemoveListenerCertificates_21627099, base: "/",
    makeUrl: url_PostRemoveListenerCertificates_21627100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveListenerCertificates_21627081 = ref object of OpenApiRestCall_21625435
proc url_GetRemoveListenerCertificates_21627083(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveListenerCertificates_21627082(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   Action: JString (required)
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Certificates` field"
  var valid_21627084 = query.getOrDefault("Certificates")
  valid_21627084 = validateParameter(valid_21627084, JArray, required = true,
                                   default = nil)
  if valid_21627084 != nil:
    section.add "Certificates", valid_21627084
  var valid_21627085 = query.getOrDefault("Action")
  valid_21627085 = validateParameter(valid_21627085, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_21627085 != nil:
    section.add "Action", valid_21627085
  var valid_21627086 = query.getOrDefault("ListenerArn")
  valid_21627086 = validateParameter(valid_21627086, JString, required = true,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "ListenerArn", valid_21627086
  var valid_21627087 = query.getOrDefault("Version")
  valid_21627087 = validateParameter(valid_21627087, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627087 != nil:
    section.add "Version", valid_21627087
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627088 = header.getOrDefault("X-Amz-Date")
  valid_21627088 = validateParameter(valid_21627088, JString, required = false,
                                   default = nil)
  if valid_21627088 != nil:
    section.add "X-Amz-Date", valid_21627088
  var valid_21627089 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627089 = validateParameter(valid_21627089, JString, required = false,
                                   default = nil)
  if valid_21627089 != nil:
    section.add "X-Amz-Security-Token", valid_21627089
  var valid_21627090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627090 = validateParameter(valid_21627090, JString, required = false,
                                   default = nil)
  if valid_21627090 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627090
  var valid_21627091 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627091 = validateParameter(valid_21627091, JString, required = false,
                                   default = nil)
  if valid_21627091 != nil:
    section.add "X-Amz-Algorithm", valid_21627091
  var valid_21627092 = header.getOrDefault("X-Amz-Signature")
  valid_21627092 = validateParameter(valid_21627092, JString, required = false,
                                   default = nil)
  if valid_21627092 != nil:
    section.add "X-Amz-Signature", valid_21627092
  var valid_21627093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627093 = validateParameter(valid_21627093, JString, required = false,
                                   default = nil)
  if valid_21627093 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627093
  var valid_21627094 = header.getOrDefault("X-Amz-Credential")
  valid_21627094 = validateParameter(valid_21627094, JString, required = false,
                                   default = nil)
  if valid_21627094 != nil:
    section.add "X-Amz-Credential", valid_21627094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627095: Call_GetRemoveListenerCertificates_21627081;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_21627095.validator(path, query, header, formData, body, _)
  let scheme = call_21627095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627095.makeUrl(scheme.get, call_21627095.host, call_21627095.base,
                               call_21627095.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627095, uri, valid, _)

proc call*(call_21627096: Call_GetRemoveListenerCertificates_21627081;
          Certificates: JsonNode; ListenerArn: string;
          Action: string = "RemoveListenerCertificates";
          Version: string = "2015-12-01"): Recallable =
  ## getRemoveListenerCertificates
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   Action: string (required)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: string (required)
  var query_21627097 = newJObject()
  if Certificates != nil:
    query_21627097.add "Certificates", Certificates
  add(query_21627097, "Action", newJString(Action))
  add(query_21627097, "ListenerArn", newJString(ListenerArn))
  add(query_21627097, "Version", newJString(Version))
  result = call_21627096.call(nil, query_21627097, nil, nil, nil)

var getRemoveListenerCertificates* = Call_GetRemoveListenerCertificates_21627081(
    name: "getRemoveListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_GetRemoveListenerCertificates_21627082, base: "/",
    makeUrl: url_GetRemoveListenerCertificates_21627083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_21627133 = ref object of OpenApiRestCall_21625435
proc url_PostRemoveTags_21627135(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTags_21627134(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627136 = query.getOrDefault("Action")
  valid_21627136 = validateParameter(valid_21627136, JString, required = true,
                                   default = newJString("RemoveTags"))
  if valid_21627136 != nil:
    section.add "Action", valid_21627136
  var valid_21627137 = query.getOrDefault("Version")
  valid_21627137 = validateParameter(valid_21627137, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627137 != nil:
    section.add "Version", valid_21627137
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627138 = header.getOrDefault("X-Amz-Date")
  valid_21627138 = validateParameter(valid_21627138, JString, required = false,
                                   default = nil)
  if valid_21627138 != nil:
    section.add "X-Amz-Date", valid_21627138
  var valid_21627139 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627139 = validateParameter(valid_21627139, JString, required = false,
                                   default = nil)
  if valid_21627139 != nil:
    section.add "X-Amz-Security-Token", valid_21627139
  var valid_21627140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627140 = validateParameter(valid_21627140, JString, required = false,
                                   default = nil)
  if valid_21627140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627140
  var valid_21627141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627141 = validateParameter(valid_21627141, JString, required = false,
                                   default = nil)
  if valid_21627141 != nil:
    section.add "X-Amz-Algorithm", valid_21627141
  var valid_21627142 = header.getOrDefault("X-Amz-Signature")
  valid_21627142 = validateParameter(valid_21627142, JString, required = false,
                                   default = nil)
  if valid_21627142 != nil:
    section.add "X-Amz-Signature", valid_21627142
  var valid_21627143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627143 = validateParameter(valid_21627143, JString, required = false,
                                   default = nil)
  if valid_21627143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627143
  var valid_21627144 = header.getOrDefault("X-Amz-Credential")
  valid_21627144 = validateParameter(valid_21627144, JString, required = false,
                                   default = nil)
  if valid_21627144 != nil:
    section.add "X-Amz-Credential", valid_21627144
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_21627145 = formData.getOrDefault("ResourceArns")
  valid_21627145 = validateParameter(valid_21627145, JArray, required = true,
                                   default = nil)
  if valid_21627145 != nil:
    section.add "ResourceArns", valid_21627145
  var valid_21627146 = formData.getOrDefault("TagKeys")
  valid_21627146 = validateParameter(valid_21627146, JArray, required = true,
                                   default = nil)
  if valid_21627146 != nil:
    section.add "TagKeys", valid_21627146
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627147: Call_PostRemoveTags_21627133; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_21627147.validator(path, query, header, formData, body, _)
  let scheme = call_21627147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627147.makeUrl(scheme.get, call_21627147.host, call_21627147.base,
                               call_21627147.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627147, uri, valid, _)

proc call*(call_21627148: Call_PostRemoveTags_21627133; ResourceArns: JsonNode;
          TagKeys: JsonNode; Action: string = "RemoveTags";
          Version: string = "2015-12-01"): Recallable =
  ## postRemoveTags
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  ##   Version: string (required)
  var query_21627149 = newJObject()
  var formData_21627150 = newJObject()
  if ResourceArns != nil:
    formData_21627150.add "ResourceArns", ResourceArns
  add(query_21627149, "Action", newJString(Action))
  if TagKeys != nil:
    formData_21627150.add "TagKeys", TagKeys
  add(query_21627149, "Version", newJString(Version))
  result = call_21627148.call(nil, query_21627149, nil, formData_21627150, nil)

var postRemoveTags* = Call_PostRemoveTags_21627133(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_21627134,
    base: "/", makeUrl: url_PostRemoveTags_21627135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_21627116 = ref object of OpenApiRestCall_21625435
proc url_GetRemoveTags_21627118(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTags_21627117(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627119 = query.getOrDefault("Action")
  valid_21627119 = validateParameter(valid_21627119, JString, required = true,
                                   default = newJString("RemoveTags"))
  if valid_21627119 != nil:
    section.add "Action", valid_21627119
  var valid_21627120 = query.getOrDefault("ResourceArns")
  valid_21627120 = validateParameter(valid_21627120, JArray, required = true,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "ResourceArns", valid_21627120
  var valid_21627121 = query.getOrDefault("TagKeys")
  valid_21627121 = validateParameter(valid_21627121, JArray, required = true,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "TagKeys", valid_21627121
  var valid_21627122 = query.getOrDefault("Version")
  valid_21627122 = validateParameter(valid_21627122, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627122 != nil:
    section.add "Version", valid_21627122
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627123 = header.getOrDefault("X-Amz-Date")
  valid_21627123 = validateParameter(valid_21627123, JString, required = false,
                                   default = nil)
  if valid_21627123 != nil:
    section.add "X-Amz-Date", valid_21627123
  var valid_21627124 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627124 = validateParameter(valid_21627124, JString, required = false,
                                   default = nil)
  if valid_21627124 != nil:
    section.add "X-Amz-Security-Token", valid_21627124
  var valid_21627125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627125 = validateParameter(valid_21627125, JString, required = false,
                                   default = nil)
  if valid_21627125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627125
  var valid_21627126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627126 = validateParameter(valid_21627126, JString, required = false,
                                   default = nil)
  if valid_21627126 != nil:
    section.add "X-Amz-Algorithm", valid_21627126
  var valid_21627127 = header.getOrDefault("X-Amz-Signature")
  valid_21627127 = validateParameter(valid_21627127, JString, required = false,
                                   default = nil)
  if valid_21627127 != nil:
    section.add "X-Amz-Signature", valid_21627127
  var valid_21627128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627128 = validateParameter(valid_21627128, JString, required = false,
                                   default = nil)
  if valid_21627128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627128
  var valid_21627129 = header.getOrDefault("X-Amz-Credential")
  valid_21627129 = validateParameter(valid_21627129, JString, required = false,
                                   default = nil)
  if valid_21627129 != nil:
    section.add "X-Amz-Credential", valid_21627129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627130: Call_GetRemoveTags_21627116; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_21627130.validator(path, query, header, formData, body, _)
  let scheme = call_21627130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627130.makeUrl(scheme.get, call_21627130.host, call_21627130.base,
                               call_21627130.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627130, uri, valid, _)

proc call*(call_21627131: Call_GetRemoveTags_21627116; ResourceArns: JsonNode;
          TagKeys: JsonNode; Action: string = "RemoveTags";
          Version: string = "2015-12-01"): Recallable =
  ## getRemoveTags
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ##   Action: string (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  ##   Version: string (required)
  var query_21627132 = newJObject()
  add(query_21627132, "Action", newJString(Action))
  if ResourceArns != nil:
    query_21627132.add "ResourceArns", ResourceArns
  if TagKeys != nil:
    query_21627132.add "TagKeys", TagKeys
  add(query_21627132, "Version", newJString(Version))
  result = call_21627131.call(nil, query_21627132, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_21627116(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_21627117,
    base: "/", makeUrl: url_GetRemoveTags_21627118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetIpAddressType_21627168 = ref object of OpenApiRestCall_21625435
proc url_PostSetIpAddressType_21627170(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetIpAddressType_21627169(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627171 = query.getOrDefault("Action")
  valid_21627171 = validateParameter(valid_21627171, JString, required = true,
                                   default = newJString("SetIpAddressType"))
  if valid_21627171 != nil:
    section.add "Action", valid_21627171
  var valid_21627172 = query.getOrDefault("Version")
  valid_21627172 = validateParameter(valid_21627172, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627172 != nil:
    section.add "Version", valid_21627172
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627173 = header.getOrDefault("X-Amz-Date")
  valid_21627173 = validateParameter(valid_21627173, JString, required = false,
                                   default = nil)
  if valid_21627173 != nil:
    section.add "X-Amz-Date", valid_21627173
  var valid_21627174 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627174 = validateParameter(valid_21627174, JString, required = false,
                                   default = nil)
  if valid_21627174 != nil:
    section.add "X-Amz-Security-Token", valid_21627174
  var valid_21627175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627175 = validateParameter(valid_21627175, JString, required = false,
                                   default = nil)
  if valid_21627175 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627175
  var valid_21627176 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627176 = validateParameter(valid_21627176, JString, required = false,
                                   default = nil)
  if valid_21627176 != nil:
    section.add "X-Amz-Algorithm", valid_21627176
  var valid_21627177 = header.getOrDefault("X-Amz-Signature")
  valid_21627177 = validateParameter(valid_21627177, JString, required = false,
                                   default = nil)
  if valid_21627177 != nil:
    section.add "X-Amz-Signature", valid_21627177
  var valid_21627178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627178 = validateParameter(valid_21627178, JString, required = false,
                                   default = nil)
  if valid_21627178 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627178
  var valid_21627179 = header.getOrDefault("X-Amz-Credential")
  valid_21627179 = validateParameter(valid_21627179, JString, required = false,
                                   default = nil)
  if valid_21627179 != nil:
    section.add "X-Amz-Credential", valid_21627179
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_21627180 = formData.getOrDefault("LoadBalancerArn")
  valid_21627180 = validateParameter(valid_21627180, JString, required = true,
                                   default = nil)
  if valid_21627180 != nil:
    section.add "LoadBalancerArn", valid_21627180
  var valid_21627181 = formData.getOrDefault("IpAddressType")
  valid_21627181 = validateParameter(valid_21627181, JString, required = true,
                                   default = newJString("ipv4"))
  if valid_21627181 != nil:
    section.add "IpAddressType", valid_21627181
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627182: Call_PostSetIpAddressType_21627168; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_21627182.validator(path, query, header, formData, body, _)
  let scheme = call_21627182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627182.makeUrl(scheme.get, call_21627182.host, call_21627182.base,
                               call_21627182.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627182, uri, valid, _)

proc call*(call_21627183: Call_PostSetIpAddressType_21627168;
          LoadBalancerArn: string; IpAddressType: string = "ipv4";
          Action: string = "SetIpAddressType"; Version: string = "2015-12-01"): Recallable =
  ## postSetIpAddressType
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   IpAddressType: string (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627184 = newJObject()
  var formData_21627185 = newJObject()
  add(formData_21627185, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_21627185, "IpAddressType", newJString(IpAddressType))
  add(query_21627184, "Action", newJString(Action))
  add(query_21627184, "Version", newJString(Version))
  result = call_21627183.call(nil, query_21627184, nil, formData_21627185, nil)

var postSetIpAddressType* = Call_PostSetIpAddressType_21627168(
    name: "postSetIpAddressType", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_PostSetIpAddressType_21627169,
    base: "/", makeUrl: url_PostSetIpAddressType_21627170,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetIpAddressType_21627151 = ref object of OpenApiRestCall_21625435
proc url_GetSetIpAddressType_21627153(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetIpAddressType_21627152(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627154 = query.getOrDefault("IpAddressType")
  valid_21627154 = validateParameter(valid_21627154, JString, required = true,
                                   default = newJString("ipv4"))
  if valid_21627154 != nil:
    section.add "IpAddressType", valid_21627154
  var valid_21627155 = query.getOrDefault("Action")
  valid_21627155 = validateParameter(valid_21627155, JString, required = true,
                                   default = newJString("SetIpAddressType"))
  if valid_21627155 != nil:
    section.add "Action", valid_21627155
  var valid_21627156 = query.getOrDefault("LoadBalancerArn")
  valid_21627156 = validateParameter(valid_21627156, JString, required = true,
                                   default = nil)
  if valid_21627156 != nil:
    section.add "LoadBalancerArn", valid_21627156
  var valid_21627157 = query.getOrDefault("Version")
  valid_21627157 = validateParameter(valid_21627157, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627157 != nil:
    section.add "Version", valid_21627157
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627158 = header.getOrDefault("X-Amz-Date")
  valid_21627158 = validateParameter(valid_21627158, JString, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "X-Amz-Date", valid_21627158
  var valid_21627159 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627159 = validateParameter(valid_21627159, JString, required = false,
                                   default = nil)
  if valid_21627159 != nil:
    section.add "X-Amz-Security-Token", valid_21627159
  var valid_21627160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627160 = validateParameter(valid_21627160, JString, required = false,
                                   default = nil)
  if valid_21627160 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627160
  var valid_21627161 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627161 = validateParameter(valid_21627161, JString, required = false,
                                   default = nil)
  if valid_21627161 != nil:
    section.add "X-Amz-Algorithm", valid_21627161
  var valid_21627162 = header.getOrDefault("X-Amz-Signature")
  valid_21627162 = validateParameter(valid_21627162, JString, required = false,
                                   default = nil)
  if valid_21627162 != nil:
    section.add "X-Amz-Signature", valid_21627162
  var valid_21627163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627163 = validateParameter(valid_21627163, JString, required = false,
                                   default = nil)
  if valid_21627163 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627163
  var valid_21627164 = header.getOrDefault("X-Amz-Credential")
  valid_21627164 = validateParameter(valid_21627164, JString, required = false,
                                   default = nil)
  if valid_21627164 != nil:
    section.add "X-Amz-Credential", valid_21627164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627165: Call_GetSetIpAddressType_21627151; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_21627165.validator(path, query, header, formData, body, _)
  let scheme = call_21627165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627165.makeUrl(scheme.get, call_21627165.host, call_21627165.base,
                               call_21627165.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627165, uri, valid, _)

proc call*(call_21627166: Call_GetSetIpAddressType_21627151;
          LoadBalancerArn: string; IpAddressType: string = "ipv4";
          Action: string = "SetIpAddressType"; Version: string = "2015-12-01"): Recallable =
  ## getSetIpAddressType
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ##   IpAddressType: string (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_21627167 = newJObject()
  add(query_21627167, "IpAddressType", newJString(IpAddressType))
  add(query_21627167, "Action", newJString(Action))
  add(query_21627167, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_21627167, "Version", newJString(Version))
  result = call_21627166.call(nil, query_21627167, nil, nil, nil)

var getSetIpAddressType* = Call_GetSetIpAddressType_21627151(
    name: "getSetIpAddressType", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_GetSetIpAddressType_21627152,
    base: "/", makeUrl: url_GetSetIpAddressType_21627153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetRulePriorities_21627202 = ref object of OpenApiRestCall_21625435
proc url_PostSetRulePriorities_21627204(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetRulePriorities_21627203(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627205 = query.getOrDefault("Action")
  valid_21627205 = validateParameter(valid_21627205, JString, required = true,
                                   default = newJString("SetRulePriorities"))
  if valid_21627205 != nil:
    section.add "Action", valid_21627205
  var valid_21627206 = query.getOrDefault("Version")
  valid_21627206 = validateParameter(valid_21627206, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627206 != nil:
    section.add "Version", valid_21627206
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627207 = header.getOrDefault("X-Amz-Date")
  valid_21627207 = validateParameter(valid_21627207, JString, required = false,
                                   default = nil)
  if valid_21627207 != nil:
    section.add "X-Amz-Date", valid_21627207
  var valid_21627208 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627208 = validateParameter(valid_21627208, JString, required = false,
                                   default = nil)
  if valid_21627208 != nil:
    section.add "X-Amz-Security-Token", valid_21627208
  var valid_21627209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627209 = validateParameter(valid_21627209, JString, required = false,
                                   default = nil)
  if valid_21627209 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627209
  var valid_21627210 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627210 = validateParameter(valid_21627210, JString, required = false,
                                   default = nil)
  if valid_21627210 != nil:
    section.add "X-Amz-Algorithm", valid_21627210
  var valid_21627211 = header.getOrDefault("X-Amz-Signature")
  valid_21627211 = validateParameter(valid_21627211, JString, required = false,
                                   default = nil)
  if valid_21627211 != nil:
    section.add "X-Amz-Signature", valid_21627211
  var valid_21627212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627212 = validateParameter(valid_21627212, JString, required = false,
                                   default = nil)
  if valid_21627212 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627212
  var valid_21627213 = header.getOrDefault("X-Amz-Credential")
  valid_21627213 = validateParameter(valid_21627213, JString, required = false,
                                   default = nil)
  if valid_21627213 != nil:
    section.add "X-Amz-Credential", valid_21627213
  result.add "header", section
  ## parameters in `formData` object:
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RulePriorities` field"
  var valid_21627214 = formData.getOrDefault("RulePriorities")
  valid_21627214 = validateParameter(valid_21627214, JArray, required = true,
                                   default = nil)
  if valid_21627214 != nil:
    section.add "RulePriorities", valid_21627214
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627215: Call_PostSetRulePriorities_21627202;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_21627215.validator(path, query, header, formData, body, _)
  let scheme = call_21627215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627215.makeUrl(scheme.get, call_21627215.host, call_21627215.base,
                               call_21627215.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627215, uri, valid, _)

proc call*(call_21627216: Call_PostSetRulePriorities_21627202;
          RulePriorities: JsonNode; Action: string = "SetRulePriorities";
          Version: string = "2015-12-01"): Recallable =
  ## postSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627217 = newJObject()
  var formData_21627218 = newJObject()
  if RulePriorities != nil:
    formData_21627218.add "RulePriorities", RulePriorities
  add(query_21627217, "Action", newJString(Action))
  add(query_21627217, "Version", newJString(Version))
  result = call_21627216.call(nil, query_21627217, nil, formData_21627218, nil)

var postSetRulePriorities* = Call_PostSetRulePriorities_21627202(
    name: "postSetRulePriorities", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities",
    validator: validate_PostSetRulePriorities_21627203, base: "/",
    makeUrl: url_PostSetRulePriorities_21627204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetRulePriorities_21627186 = ref object of OpenApiRestCall_21625435
proc url_GetSetRulePriorities_21627188(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetRulePriorities_21627187(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627189 = query.getOrDefault("RulePriorities")
  valid_21627189 = validateParameter(valid_21627189, JArray, required = true,
                                   default = nil)
  if valid_21627189 != nil:
    section.add "RulePriorities", valid_21627189
  var valid_21627190 = query.getOrDefault("Action")
  valid_21627190 = validateParameter(valid_21627190, JString, required = true,
                                   default = newJString("SetRulePriorities"))
  if valid_21627190 != nil:
    section.add "Action", valid_21627190
  var valid_21627191 = query.getOrDefault("Version")
  valid_21627191 = validateParameter(valid_21627191, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627191 != nil:
    section.add "Version", valid_21627191
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627192 = header.getOrDefault("X-Amz-Date")
  valid_21627192 = validateParameter(valid_21627192, JString, required = false,
                                   default = nil)
  if valid_21627192 != nil:
    section.add "X-Amz-Date", valid_21627192
  var valid_21627193 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627193 = validateParameter(valid_21627193, JString, required = false,
                                   default = nil)
  if valid_21627193 != nil:
    section.add "X-Amz-Security-Token", valid_21627193
  var valid_21627194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627194 = validateParameter(valid_21627194, JString, required = false,
                                   default = nil)
  if valid_21627194 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627194
  var valid_21627195 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627195 = validateParameter(valid_21627195, JString, required = false,
                                   default = nil)
  if valid_21627195 != nil:
    section.add "X-Amz-Algorithm", valid_21627195
  var valid_21627196 = header.getOrDefault("X-Amz-Signature")
  valid_21627196 = validateParameter(valid_21627196, JString, required = false,
                                   default = nil)
  if valid_21627196 != nil:
    section.add "X-Amz-Signature", valid_21627196
  var valid_21627197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627197 = validateParameter(valid_21627197, JString, required = false,
                                   default = nil)
  if valid_21627197 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627197
  var valid_21627198 = header.getOrDefault("X-Amz-Credential")
  valid_21627198 = validateParameter(valid_21627198, JString, required = false,
                                   default = nil)
  if valid_21627198 != nil:
    section.add "X-Amz-Credential", valid_21627198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627199: Call_GetSetRulePriorities_21627186; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_21627199.validator(path, query, header, formData, body, _)
  let scheme = call_21627199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627199.makeUrl(scheme.get, call_21627199.host, call_21627199.base,
                               call_21627199.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627199, uri, valid, _)

proc call*(call_21627200: Call_GetSetRulePriorities_21627186;
          RulePriorities: JsonNode; Action: string = "SetRulePriorities";
          Version: string = "2015-12-01"): Recallable =
  ## getSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627201 = newJObject()
  if RulePriorities != nil:
    query_21627201.add "RulePriorities", RulePriorities
  add(query_21627201, "Action", newJString(Action))
  add(query_21627201, "Version", newJString(Version))
  result = call_21627200.call(nil, query_21627201, nil, nil, nil)

var getSetRulePriorities* = Call_GetSetRulePriorities_21627186(
    name: "getSetRulePriorities", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities", validator: validate_GetSetRulePriorities_21627187,
    base: "/", makeUrl: url_GetSetRulePriorities_21627188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSecurityGroups_21627236 = ref object of OpenApiRestCall_21625435
proc url_PostSetSecurityGroups_21627238(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetSecurityGroups_21627237(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627239 = query.getOrDefault("Action")
  valid_21627239 = validateParameter(valid_21627239, JString, required = true,
                                   default = newJString("SetSecurityGroups"))
  if valid_21627239 != nil:
    section.add "Action", valid_21627239
  var valid_21627240 = query.getOrDefault("Version")
  valid_21627240 = validateParameter(valid_21627240, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627240 != nil:
    section.add "Version", valid_21627240
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627241 = header.getOrDefault("X-Amz-Date")
  valid_21627241 = validateParameter(valid_21627241, JString, required = false,
                                   default = nil)
  if valid_21627241 != nil:
    section.add "X-Amz-Date", valid_21627241
  var valid_21627242 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627242 = validateParameter(valid_21627242, JString, required = false,
                                   default = nil)
  if valid_21627242 != nil:
    section.add "X-Amz-Security-Token", valid_21627242
  var valid_21627243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627243 = validateParameter(valid_21627243, JString, required = false,
                                   default = nil)
  if valid_21627243 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627243
  var valid_21627244 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627244 = validateParameter(valid_21627244, JString, required = false,
                                   default = nil)
  if valid_21627244 != nil:
    section.add "X-Amz-Algorithm", valid_21627244
  var valid_21627245 = header.getOrDefault("X-Amz-Signature")
  valid_21627245 = validateParameter(valid_21627245, JString, required = false,
                                   default = nil)
  if valid_21627245 != nil:
    section.add "X-Amz-Signature", valid_21627245
  var valid_21627246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627246 = validateParameter(valid_21627246, JString, required = false,
                                   default = nil)
  if valid_21627246 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627246
  var valid_21627247 = header.getOrDefault("X-Amz-Credential")
  valid_21627247 = validateParameter(valid_21627247, JString, required = false,
                                   default = nil)
  if valid_21627247 != nil:
    section.add "X-Amz-Credential", valid_21627247
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_21627248 = formData.getOrDefault("LoadBalancerArn")
  valid_21627248 = validateParameter(valid_21627248, JString, required = true,
                                   default = nil)
  if valid_21627248 != nil:
    section.add "LoadBalancerArn", valid_21627248
  var valid_21627249 = formData.getOrDefault("SecurityGroups")
  valid_21627249 = validateParameter(valid_21627249, JArray, required = true,
                                   default = nil)
  if valid_21627249 != nil:
    section.add "SecurityGroups", valid_21627249
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627250: Call_PostSetSecurityGroups_21627236;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_21627250.validator(path, query, header, formData, body, _)
  let scheme = call_21627250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627250.makeUrl(scheme.get, call_21627250.host, call_21627250.base,
                               call_21627250.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627250, uri, valid, _)

proc call*(call_21627251: Call_PostSetSecurityGroups_21627236;
          LoadBalancerArn: string; SecurityGroups: JsonNode;
          Action: string = "SetSecurityGroups"; Version: string = "2015-12-01"): Recallable =
  ## postSetSecurityGroups
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  ##   Version: string (required)
  var query_21627252 = newJObject()
  var formData_21627253 = newJObject()
  add(formData_21627253, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_21627252, "Action", newJString(Action))
  if SecurityGroups != nil:
    formData_21627253.add "SecurityGroups", SecurityGroups
  add(query_21627252, "Version", newJString(Version))
  result = call_21627251.call(nil, query_21627252, nil, formData_21627253, nil)

var postSetSecurityGroups* = Call_PostSetSecurityGroups_21627236(
    name: "postSetSecurityGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups",
    validator: validate_PostSetSecurityGroups_21627237, base: "/",
    makeUrl: url_PostSetSecurityGroups_21627238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSecurityGroups_21627219 = ref object of OpenApiRestCall_21625435
proc url_GetSetSecurityGroups_21627221(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetSecurityGroups_21627220(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: JString (required)
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  section = newJObject()
  var valid_21627222 = query.getOrDefault("Action")
  valid_21627222 = validateParameter(valid_21627222, JString, required = true,
                                   default = newJString("SetSecurityGroups"))
  if valid_21627222 != nil:
    section.add "Action", valid_21627222
  var valid_21627223 = query.getOrDefault("LoadBalancerArn")
  valid_21627223 = validateParameter(valid_21627223, JString, required = true,
                                   default = nil)
  if valid_21627223 != nil:
    section.add "LoadBalancerArn", valid_21627223
  var valid_21627224 = query.getOrDefault("Version")
  valid_21627224 = validateParameter(valid_21627224, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627224 != nil:
    section.add "Version", valid_21627224
  var valid_21627225 = query.getOrDefault("SecurityGroups")
  valid_21627225 = validateParameter(valid_21627225, JArray, required = true,
                                   default = nil)
  if valid_21627225 != nil:
    section.add "SecurityGroups", valid_21627225
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627226 = header.getOrDefault("X-Amz-Date")
  valid_21627226 = validateParameter(valid_21627226, JString, required = false,
                                   default = nil)
  if valid_21627226 != nil:
    section.add "X-Amz-Date", valid_21627226
  var valid_21627227 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627227 = validateParameter(valid_21627227, JString, required = false,
                                   default = nil)
  if valid_21627227 != nil:
    section.add "X-Amz-Security-Token", valid_21627227
  var valid_21627228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627228 = validateParameter(valid_21627228, JString, required = false,
                                   default = nil)
  if valid_21627228 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627228
  var valid_21627229 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627229 = validateParameter(valid_21627229, JString, required = false,
                                   default = nil)
  if valid_21627229 != nil:
    section.add "X-Amz-Algorithm", valid_21627229
  var valid_21627230 = header.getOrDefault("X-Amz-Signature")
  valid_21627230 = validateParameter(valid_21627230, JString, required = false,
                                   default = nil)
  if valid_21627230 != nil:
    section.add "X-Amz-Signature", valid_21627230
  var valid_21627231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627231 = validateParameter(valid_21627231, JString, required = false,
                                   default = nil)
  if valid_21627231 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627231
  var valid_21627232 = header.getOrDefault("X-Amz-Credential")
  valid_21627232 = validateParameter(valid_21627232, JString, required = false,
                                   default = nil)
  if valid_21627232 != nil:
    section.add "X-Amz-Credential", valid_21627232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627233: Call_GetSetSecurityGroups_21627219; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_21627233.validator(path, query, header, formData, body, _)
  let scheme = call_21627233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627233.makeUrl(scheme.get, call_21627233.host, call_21627233.base,
                               call_21627233.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627233, uri, valid, _)

proc call*(call_21627234: Call_GetSetSecurityGroups_21627219;
          LoadBalancerArn: string; SecurityGroups: JsonNode;
          Action: string = "SetSecurityGroups"; Version: string = "2015-12-01"): Recallable =
  ## getSetSecurityGroups
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  var query_21627235 = newJObject()
  add(query_21627235, "Action", newJString(Action))
  add(query_21627235, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_21627235, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_21627235.add "SecurityGroups", SecurityGroups
  result = call_21627234.call(nil, query_21627235, nil, nil, nil)

var getSetSecurityGroups* = Call_GetSetSecurityGroups_21627219(
    name: "getSetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups", validator: validate_GetSetSecurityGroups_21627220,
    base: "/", makeUrl: url_GetSetSecurityGroups_21627221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubnets_21627272 = ref object of OpenApiRestCall_21625435
proc url_PostSetSubnets_21627274(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetSubnets_21627273(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627275 = query.getOrDefault("Action")
  valid_21627275 = validateParameter(valid_21627275, JString, required = true,
                                   default = newJString("SetSubnets"))
  if valid_21627275 != nil:
    section.add "Action", valid_21627275
  var valid_21627276 = query.getOrDefault("Version")
  valid_21627276 = validateParameter(valid_21627276, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627276 != nil:
    section.add "Version", valid_21627276
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627277 = header.getOrDefault("X-Amz-Date")
  valid_21627277 = validateParameter(valid_21627277, JString, required = false,
                                   default = nil)
  if valid_21627277 != nil:
    section.add "X-Amz-Date", valid_21627277
  var valid_21627278 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627278 = validateParameter(valid_21627278, JString, required = false,
                                   default = nil)
  if valid_21627278 != nil:
    section.add "X-Amz-Security-Token", valid_21627278
  var valid_21627279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627279 = validateParameter(valid_21627279, JString, required = false,
                                   default = nil)
  if valid_21627279 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627279
  var valid_21627280 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627280 = validateParameter(valid_21627280, JString, required = false,
                                   default = nil)
  if valid_21627280 != nil:
    section.add "X-Amz-Algorithm", valid_21627280
  var valid_21627281 = header.getOrDefault("X-Amz-Signature")
  valid_21627281 = validateParameter(valid_21627281, JString, required = false,
                                   default = nil)
  if valid_21627281 != nil:
    section.add "X-Amz-Signature", valid_21627281
  var valid_21627282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627282 = validateParameter(valid_21627282, JString, required = false,
                                   default = nil)
  if valid_21627282 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627282
  var valid_21627283 = header.getOrDefault("X-Amz-Credential")
  valid_21627283 = validateParameter(valid_21627283, JString, required = false,
                                   default = nil)
  if valid_21627283 != nil:
    section.add "X-Amz-Credential", valid_21627283
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. If you need static IP addresses for your internet-facing load balancer, you can specify one Elastic IP address per subnet. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_21627284 = formData.getOrDefault("LoadBalancerArn")
  valid_21627284 = validateParameter(valid_21627284, JString, required = true,
                                   default = nil)
  if valid_21627284 != nil:
    section.add "LoadBalancerArn", valid_21627284
  var valid_21627285 = formData.getOrDefault("Subnets")
  valid_21627285 = validateParameter(valid_21627285, JArray, required = false,
                                   default = nil)
  if valid_21627285 != nil:
    section.add "Subnets", valid_21627285
  var valid_21627286 = formData.getOrDefault("SubnetMappings")
  valid_21627286 = validateParameter(valid_21627286, JArray, required = false,
                                   default = nil)
  if valid_21627286 != nil:
    section.add "SubnetMappings", valid_21627286
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627287: Call_PostSetSubnets_21627272; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ## 
  let valid = call_21627287.validator(path, query, header, formData, body, _)
  let scheme = call_21627287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627287.makeUrl(scheme.get, call_21627287.host, call_21627287.base,
                               call_21627287.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627287, uri, valid, _)

proc call*(call_21627288: Call_PostSetSubnets_21627272; LoadBalancerArn: string;
          Action: string = "SetSubnets"; Subnets: JsonNode = nil;
          SubnetMappings: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
  ## postSetSubnets
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. If you need static IP addresses for your internet-facing load balancer, you can specify one Elastic IP address per subnet. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   Version: string (required)
  var query_21627289 = newJObject()
  var formData_21627290 = newJObject()
  add(formData_21627290, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_21627289, "Action", newJString(Action))
  if Subnets != nil:
    formData_21627290.add "Subnets", Subnets
  if SubnetMappings != nil:
    formData_21627290.add "SubnetMappings", SubnetMappings
  add(query_21627289, "Version", newJString(Version))
  result = call_21627288.call(nil, query_21627289, nil, formData_21627290, nil)

var postSetSubnets* = Call_PostSetSubnets_21627272(name: "postSetSubnets",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_PostSetSubnets_21627273,
    base: "/", makeUrl: url_PostSetSubnets_21627274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubnets_21627254 = ref object of OpenApiRestCall_21625435
proc url_GetSetSubnets_21627256(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetSubnets_21627255(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. If you need static IP addresses for your internet-facing load balancer, you can specify one Elastic IP address per subnet. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627257 = query.getOrDefault("SubnetMappings")
  valid_21627257 = validateParameter(valid_21627257, JArray, required = false,
                                   default = nil)
  if valid_21627257 != nil:
    section.add "SubnetMappings", valid_21627257
  var valid_21627258 = query.getOrDefault("Action")
  valid_21627258 = validateParameter(valid_21627258, JString, required = true,
                                   default = newJString("SetSubnets"))
  if valid_21627258 != nil:
    section.add "Action", valid_21627258
  var valid_21627259 = query.getOrDefault("LoadBalancerArn")
  valid_21627259 = validateParameter(valid_21627259, JString, required = true,
                                   default = nil)
  if valid_21627259 != nil:
    section.add "LoadBalancerArn", valid_21627259
  var valid_21627260 = query.getOrDefault("Subnets")
  valid_21627260 = validateParameter(valid_21627260, JArray, required = false,
                                   default = nil)
  if valid_21627260 != nil:
    section.add "Subnets", valid_21627260
  var valid_21627261 = query.getOrDefault("Version")
  valid_21627261 = validateParameter(valid_21627261, JString, required = true,
                                   default = newJString("2015-12-01"))
  if valid_21627261 != nil:
    section.add "Version", valid_21627261
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627262 = header.getOrDefault("X-Amz-Date")
  valid_21627262 = validateParameter(valid_21627262, JString, required = false,
                                   default = nil)
  if valid_21627262 != nil:
    section.add "X-Amz-Date", valid_21627262
  var valid_21627263 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627263 = validateParameter(valid_21627263, JString, required = false,
                                   default = nil)
  if valid_21627263 != nil:
    section.add "X-Amz-Security-Token", valid_21627263
  var valid_21627264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627264 = validateParameter(valid_21627264, JString, required = false,
                                   default = nil)
  if valid_21627264 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627264
  var valid_21627265 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627265 = validateParameter(valid_21627265, JString, required = false,
                                   default = nil)
  if valid_21627265 != nil:
    section.add "X-Amz-Algorithm", valid_21627265
  var valid_21627266 = header.getOrDefault("X-Amz-Signature")
  valid_21627266 = validateParameter(valid_21627266, JString, required = false,
                                   default = nil)
  if valid_21627266 != nil:
    section.add "X-Amz-Signature", valid_21627266
  var valid_21627267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627267 = validateParameter(valid_21627267, JString, required = false,
                                   default = nil)
  if valid_21627267 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627267
  var valid_21627268 = header.getOrDefault("X-Amz-Credential")
  valid_21627268 = validateParameter(valid_21627268, JString, required = false,
                                   default = nil)
  if valid_21627268 != nil:
    section.add "X-Amz-Credential", valid_21627268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627269: Call_GetSetSubnets_21627254; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ## 
  let valid = call_21627269.validator(path, query, header, formData, body, _)
  let scheme = call_21627269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627269.makeUrl(scheme.get, call_21627269.host, call_21627269.base,
                               call_21627269.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627269, uri, valid, _)

proc call*(call_21627270: Call_GetSetSubnets_21627254; LoadBalancerArn: string;
          SubnetMappings: JsonNode = nil; Action: string = "SetSubnets";
          Subnets: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
  ## getSetSubnets
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. If you need static IP addresses for your internet-facing load balancer, you can specify one Elastic IP address per subnet. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   Version: string (required)
  var query_21627271 = newJObject()
  if SubnetMappings != nil:
    query_21627271.add "SubnetMappings", SubnetMappings
  add(query_21627271, "Action", newJString(Action))
  add(query_21627271, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Subnets != nil:
    query_21627271.add "Subnets", Subnets
  add(query_21627271, "Version", newJString(Version))
  result = call_21627270.call(nil, query_21627271, nil, nil, nil)

var getSetSubnets* = Call_GetSetSubnets_21627254(name: "getSetSubnets",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_GetSetSubnets_21627255,
    base: "/", makeUrl: url_GetSetSubnets_21627256,
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