
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
  Call_PostAddListenerCertificates_606199 = ref object of OpenApiRestCall_605589
proc url_PostAddListenerCertificates_606201(protocol: Scheme; host: string;
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

proc validate_PostAddListenerCertificates_606200(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606202 = query.getOrDefault("Action")
  valid_606202 = validateParameter(valid_606202, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_606202 != nil:
    section.add "Action", valid_606202
  var valid_606203 = query.getOrDefault("Version")
  valid_606203 = validateParameter(valid_606203, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606203 != nil:
    section.add "Version", valid_606203
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
  var valid_606204 = header.getOrDefault("X-Amz-Signature")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Signature", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Content-Sha256", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Date")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Date", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Credential")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Credential", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Security-Token")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Security-Token", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Algorithm")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Algorithm", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-SignedHeaders", valid_606210
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_606211 = formData.getOrDefault("Certificates")
  valid_606211 = validateParameter(valid_606211, JArray, required = true, default = nil)
  if valid_606211 != nil:
    section.add "Certificates", valid_606211
  var valid_606212 = formData.getOrDefault("ListenerArn")
  valid_606212 = validateParameter(valid_606212, JString, required = true,
                                 default = nil)
  if valid_606212 != nil:
    section.add "ListenerArn", valid_606212
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606213: Call_PostAddListenerCertificates_606199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606213.validator(path, query, header, formData, body)
  let scheme = call_606213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606213.url(scheme.get, call_606213.host, call_606213.base,
                         call_606213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606213, url, valid)

proc call*(call_606214: Call_PostAddListenerCertificates_606199;
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
  var query_606215 = newJObject()
  var formData_606216 = newJObject()
  if Certificates != nil:
    formData_606216.add "Certificates", Certificates
  add(formData_606216, "ListenerArn", newJString(ListenerArn))
  add(query_606215, "Action", newJString(Action))
  add(query_606215, "Version", newJString(Version))
  result = call_606214.call(nil, query_606215, nil, formData_606216, nil)

var postAddListenerCertificates* = Call_PostAddListenerCertificates_606199(
    name: "postAddListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_PostAddListenerCertificates_606200, base: "/",
    url: url_PostAddListenerCertificates_606201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddListenerCertificates_605927 = ref object of OpenApiRestCall_605589
proc url_GetAddListenerCertificates_605929(protocol: Scheme; host: string;
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

proc validate_GetAddListenerCertificates_605928(path: JsonNode; query: JsonNode;
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
  var valid_606041 = query.getOrDefault("ListenerArn")
  valid_606041 = validateParameter(valid_606041, JString, required = true,
                                 default = nil)
  if valid_606041 != nil:
    section.add "ListenerArn", valid_606041
  var valid_606042 = query.getOrDefault("Certificates")
  valid_606042 = validateParameter(valid_606042, JArray, required = true, default = nil)
  if valid_606042 != nil:
    section.add "Certificates", valid_606042
  var valid_606056 = query.getOrDefault("Action")
  valid_606056 = validateParameter(valid_606056, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_606056 != nil:
    section.add "Action", valid_606056
  var valid_606057 = query.getOrDefault("Version")
  valid_606057 = validateParameter(valid_606057, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606057 != nil:
    section.add "Version", valid_606057
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
  var valid_606058 = header.getOrDefault("X-Amz-Signature")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Signature", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Content-Sha256", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Date")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Date", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Credential")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Credential", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Security-Token")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Security-Token", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-Algorithm")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-Algorithm", valid_606063
  var valid_606064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606064 = validateParameter(valid_606064, JString, required = false,
                                 default = nil)
  if valid_606064 != nil:
    section.add "X-Amz-SignedHeaders", valid_606064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606087: Call_GetAddListenerCertificates_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606087.validator(path, query, header, formData, body)
  let scheme = call_606087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606087.url(scheme.get, call_606087.host, call_606087.base,
                         call_606087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606087, url, valid)

proc call*(call_606158: Call_GetAddListenerCertificates_605927;
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
  var query_606159 = newJObject()
  add(query_606159, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_606159.add "Certificates", Certificates
  add(query_606159, "Action", newJString(Action))
  add(query_606159, "Version", newJString(Version))
  result = call_606158.call(nil, query_606159, nil, nil, nil)

var getAddListenerCertificates* = Call_GetAddListenerCertificates_605927(
    name: "getAddListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_GetAddListenerCertificates_605928, base: "/",
    url: url_GetAddListenerCertificates_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTags_606234 = ref object of OpenApiRestCall_605589
proc url_PostAddTags_606236(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddTags_606235(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606237 = query.getOrDefault("Action")
  valid_606237 = validateParameter(valid_606237, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_606237 != nil:
    section.add "Action", valid_606237
  var valid_606238 = query.getOrDefault("Version")
  valid_606238 = validateParameter(valid_606238, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606238 != nil:
    section.add "Version", valid_606238
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
  var valid_606239 = header.getOrDefault("X-Amz-Signature")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Signature", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Content-Sha256", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Date")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Date", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Credential")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Credential", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Security-Token")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Security-Token", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-Algorithm")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Algorithm", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-SignedHeaders", valid_606245
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_606246 = formData.getOrDefault("ResourceArns")
  valid_606246 = validateParameter(valid_606246, JArray, required = true, default = nil)
  if valid_606246 != nil:
    section.add "ResourceArns", valid_606246
  var valid_606247 = formData.getOrDefault("Tags")
  valid_606247 = validateParameter(valid_606247, JArray, required = true, default = nil)
  if valid_606247 != nil:
    section.add "Tags", valid_606247
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606248: Call_PostAddTags_606234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_606248.validator(path, query, header, formData, body)
  let scheme = call_606248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606248.url(scheme.get, call_606248.host, call_606248.base,
                         call_606248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606248, url, valid)

proc call*(call_606249: Call_PostAddTags_606234; ResourceArns: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2015-12-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Version: string (required)
  var query_606250 = newJObject()
  var formData_606251 = newJObject()
  if ResourceArns != nil:
    formData_606251.add "ResourceArns", ResourceArns
  add(query_606250, "Action", newJString(Action))
  if Tags != nil:
    formData_606251.add "Tags", Tags
  add(query_606250, "Version", newJString(Version))
  result = call_606249.call(nil, query_606250, nil, formData_606251, nil)

var postAddTags* = Call_PostAddTags_606234(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_606235,
                                        base: "/", url: url_PostAddTags_606236,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_606217 = ref object of OpenApiRestCall_605589
proc url_GetAddTags_606219(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTags_606218(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606220 = query.getOrDefault("Tags")
  valid_606220 = validateParameter(valid_606220, JArray, required = true, default = nil)
  if valid_606220 != nil:
    section.add "Tags", valid_606220
  var valid_606221 = query.getOrDefault("ResourceArns")
  valid_606221 = validateParameter(valid_606221, JArray, required = true, default = nil)
  if valid_606221 != nil:
    section.add "ResourceArns", valid_606221
  var valid_606222 = query.getOrDefault("Action")
  valid_606222 = validateParameter(valid_606222, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_606222 != nil:
    section.add "Action", valid_606222
  var valid_606223 = query.getOrDefault("Version")
  valid_606223 = validateParameter(valid_606223, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606223 != nil:
    section.add "Version", valid_606223
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
  var valid_606224 = header.getOrDefault("X-Amz-Signature")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Signature", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Content-Sha256", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Date")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Date", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Credential")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Credential", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Security-Token")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Security-Token", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-Algorithm")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Algorithm", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-SignedHeaders", valid_606230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606231: Call_GetAddTags_606217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_606231.validator(path, query, header, formData, body)
  let scheme = call_606231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606231.url(scheme.get, call_606231.host, call_606231.base,
                         call_606231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606231, url, valid)

proc call*(call_606232: Call_GetAddTags_606217; Tags: JsonNode;
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
  var query_606233 = newJObject()
  if Tags != nil:
    query_606233.add "Tags", Tags
  if ResourceArns != nil:
    query_606233.add "ResourceArns", ResourceArns
  add(query_606233, "Action", newJString(Action))
  add(query_606233, "Version", newJString(Version))
  result = call_606232.call(nil, query_606233, nil, nil, nil)

var getAddTags* = Call_GetAddTags_606217(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_606218,
                                      base: "/", url: url_GetAddTags_606219,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateListener_606273 = ref object of OpenApiRestCall_605589
proc url_PostCreateListener_606275(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateListener_606274(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606276 = query.getOrDefault("Action")
  valid_606276 = validateParameter(valid_606276, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_606276 != nil:
    section.add "Action", valid_606276
  var valid_606277 = query.getOrDefault("Version")
  valid_606277 = validateParameter(valid_606277, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606277 != nil:
    section.add "Version", valid_606277
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
  var valid_606278 = header.getOrDefault("X-Amz-Signature")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Signature", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Content-Sha256", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Date")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Date", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Credential")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Credential", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Security-Token")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Security-Token", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Algorithm")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Algorithm", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-SignedHeaders", valid_606284
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
  var valid_606285 = formData.getOrDefault("Port")
  valid_606285 = validateParameter(valid_606285, JInt, required = true, default = nil)
  if valid_606285 != nil:
    section.add "Port", valid_606285
  var valid_606286 = formData.getOrDefault("Certificates")
  valid_606286 = validateParameter(valid_606286, JArray, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "Certificates", valid_606286
  var valid_606287 = formData.getOrDefault("DefaultActions")
  valid_606287 = validateParameter(valid_606287, JArray, required = true, default = nil)
  if valid_606287 != nil:
    section.add "DefaultActions", valid_606287
  var valid_606288 = formData.getOrDefault("Protocol")
  valid_606288 = validateParameter(valid_606288, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_606288 != nil:
    section.add "Protocol", valid_606288
  var valid_606289 = formData.getOrDefault("SslPolicy")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "SslPolicy", valid_606289
  var valid_606290 = formData.getOrDefault("LoadBalancerArn")
  valid_606290 = validateParameter(valid_606290, JString, required = true,
                                 default = nil)
  if valid_606290 != nil:
    section.add "LoadBalancerArn", valid_606290
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606291: Call_PostCreateListener_606273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606291.validator(path, query, header, formData, body)
  let scheme = call_606291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606291.url(scheme.get, call_606291.host, call_606291.base,
                         call_606291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606291, url, valid)

proc call*(call_606292: Call_PostCreateListener_606273; Port: int;
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
  var query_606293 = newJObject()
  var formData_606294 = newJObject()
  add(formData_606294, "Port", newJInt(Port))
  if Certificates != nil:
    formData_606294.add "Certificates", Certificates
  if DefaultActions != nil:
    formData_606294.add "DefaultActions", DefaultActions
  add(formData_606294, "Protocol", newJString(Protocol))
  add(query_606293, "Action", newJString(Action))
  add(formData_606294, "SslPolicy", newJString(SslPolicy))
  add(query_606293, "Version", newJString(Version))
  add(formData_606294, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_606292.call(nil, query_606293, nil, formData_606294, nil)

var postCreateListener* = Call_PostCreateListener_606273(
    name: "postCreateListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=CreateListener",
    validator: validate_PostCreateListener_606274, base: "/",
    url: url_PostCreateListener_606275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateListener_606252 = ref object of OpenApiRestCall_605589
proc url_GetCreateListener_606254(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateListener_606253(path: JsonNode; query: JsonNode;
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
  var valid_606255 = query.getOrDefault("SslPolicy")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "SslPolicy", valid_606255
  var valid_606256 = query.getOrDefault("Certificates")
  valid_606256 = validateParameter(valid_606256, JArray, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "Certificates", valid_606256
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_606257 = query.getOrDefault("LoadBalancerArn")
  valid_606257 = validateParameter(valid_606257, JString, required = true,
                                 default = nil)
  if valid_606257 != nil:
    section.add "LoadBalancerArn", valid_606257
  var valid_606258 = query.getOrDefault("DefaultActions")
  valid_606258 = validateParameter(valid_606258, JArray, required = true, default = nil)
  if valid_606258 != nil:
    section.add "DefaultActions", valid_606258
  var valid_606259 = query.getOrDefault("Action")
  valid_606259 = validateParameter(valid_606259, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_606259 != nil:
    section.add "Action", valid_606259
  var valid_606260 = query.getOrDefault("Protocol")
  valid_606260 = validateParameter(valid_606260, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_606260 != nil:
    section.add "Protocol", valid_606260
  var valid_606261 = query.getOrDefault("Port")
  valid_606261 = validateParameter(valid_606261, JInt, required = true, default = nil)
  if valid_606261 != nil:
    section.add "Port", valid_606261
  var valid_606262 = query.getOrDefault("Version")
  valid_606262 = validateParameter(valid_606262, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606262 != nil:
    section.add "Version", valid_606262
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
  var valid_606263 = header.getOrDefault("X-Amz-Signature")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Signature", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Content-Sha256", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Date")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Date", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Credential")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Credential", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-Security-Token")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Security-Token", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-Algorithm")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Algorithm", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-SignedHeaders", valid_606269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606270: Call_GetCreateListener_606252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606270.validator(path, query, header, formData, body)
  let scheme = call_606270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606270.url(scheme.get, call_606270.host, call_606270.base,
                         call_606270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606270, url, valid)

proc call*(call_606271: Call_GetCreateListener_606252; LoadBalancerArn: string;
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
  var query_606272 = newJObject()
  add(query_606272, "SslPolicy", newJString(SslPolicy))
  if Certificates != nil:
    query_606272.add "Certificates", Certificates
  add(query_606272, "LoadBalancerArn", newJString(LoadBalancerArn))
  if DefaultActions != nil:
    query_606272.add "DefaultActions", DefaultActions
  add(query_606272, "Action", newJString(Action))
  add(query_606272, "Protocol", newJString(Protocol))
  add(query_606272, "Port", newJInt(Port))
  add(query_606272, "Version", newJString(Version))
  result = call_606271.call(nil, query_606272, nil, nil, nil)

var getCreateListener* = Call_GetCreateListener_606252(name: "getCreateListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateListener", validator: validate_GetCreateListener_606253,
    base: "/", url: url_GetCreateListener_606254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_606318 = ref object of OpenApiRestCall_605589
proc url_PostCreateLoadBalancer_606320(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateLoadBalancer_606319(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606321 = query.getOrDefault("Action")
  valid_606321 = validateParameter(valid_606321, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_606321 != nil:
    section.add "Action", valid_606321
  var valid_606322 = query.getOrDefault("Version")
  valid_606322 = validateParameter(valid_606322, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606322 != nil:
    section.add "Version", valid_606322
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
  var valid_606323 = header.getOrDefault("X-Amz-Signature")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Signature", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Content-Sha256", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Date")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Date", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Credential")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Credential", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-Security-Token")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Security-Token", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Algorithm")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Algorithm", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-SignedHeaders", valid_606329
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
  var valid_606330 = formData.getOrDefault("IpAddressType")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_606330 != nil:
    section.add "IpAddressType", valid_606330
  var valid_606331 = formData.getOrDefault("Scheme")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_606331 != nil:
    section.add "Scheme", valid_606331
  var valid_606332 = formData.getOrDefault("SecurityGroups")
  valid_606332 = validateParameter(valid_606332, JArray, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "SecurityGroups", valid_606332
  var valid_606333 = formData.getOrDefault("Subnets")
  valid_606333 = validateParameter(valid_606333, JArray, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "Subnets", valid_606333
  var valid_606334 = formData.getOrDefault("Type")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = newJString("application"))
  if valid_606334 != nil:
    section.add "Type", valid_606334
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_606335 = formData.getOrDefault("Name")
  valid_606335 = validateParameter(valid_606335, JString, required = true,
                                 default = nil)
  if valid_606335 != nil:
    section.add "Name", valid_606335
  var valid_606336 = formData.getOrDefault("Tags")
  valid_606336 = validateParameter(valid_606336, JArray, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "Tags", valid_606336
  var valid_606337 = formData.getOrDefault("SubnetMappings")
  valid_606337 = validateParameter(valid_606337, JArray, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "SubnetMappings", valid_606337
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606338: Call_PostCreateLoadBalancer_606318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606338.validator(path, query, header, formData, body)
  let scheme = call_606338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606338.url(scheme.get, call_606338.host, call_606338.base,
                         call_606338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606338, url, valid)

proc call*(call_606339: Call_PostCreateLoadBalancer_606318; Name: string;
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
  var query_606340 = newJObject()
  var formData_606341 = newJObject()
  add(formData_606341, "IpAddressType", newJString(IpAddressType))
  add(formData_606341, "Scheme", newJString(Scheme))
  if SecurityGroups != nil:
    formData_606341.add "SecurityGroups", SecurityGroups
  if Subnets != nil:
    formData_606341.add "Subnets", Subnets
  add(formData_606341, "Type", newJString(Type))
  add(query_606340, "Action", newJString(Action))
  add(formData_606341, "Name", newJString(Name))
  if Tags != nil:
    formData_606341.add "Tags", Tags
  if SubnetMappings != nil:
    formData_606341.add "SubnetMappings", SubnetMappings
  add(query_606340, "Version", newJString(Version))
  result = call_606339.call(nil, query_606340, nil, formData_606341, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_606318(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_606319, base: "/",
    url: url_PostCreateLoadBalancer_606320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_606295 = ref object of OpenApiRestCall_605589
proc url_GetCreateLoadBalancer_606297(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateLoadBalancer_606296(path: JsonNode; query: JsonNode;
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
  var valid_606298 = query.getOrDefault("SubnetMappings")
  valid_606298 = validateParameter(valid_606298, JArray, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "SubnetMappings", valid_606298
  var valid_606299 = query.getOrDefault("Type")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = newJString("application"))
  if valid_606299 != nil:
    section.add "Type", valid_606299
  var valid_606300 = query.getOrDefault("Tags")
  valid_606300 = validateParameter(valid_606300, JArray, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "Tags", valid_606300
  var valid_606301 = query.getOrDefault("Scheme")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_606301 != nil:
    section.add "Scheme", valid_606301
  var valid_606302 = query.getOrDefault("IpAddressType")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_606302 != nil:
    section.add "IpAddressType", valid_606302
  var valid_606303 = query.getOrDefault("SecurityGroups")
  valid_606303 = validateParameter(valid_606303, JArray, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "SecurityGroups", valid_606303
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_606304 = query.getOrDefault("Name")
  valid_606304 = validateParameter(valid_606304, JString, required = true,
                                 default = nil)
  if valid_606304 != nil:
    section.add "Name", valid_606304
  var valid_606305 = query.getOrDefault("Action")
  valid_606305 = validateParameter(valid_606305, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_606305 != nil:
    section.add "Action", valid_606305
  var valid_606306 = query.getOrDefault("Subnets")
  valid_606306 = validateParameter(valid_606306, JArray, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "Subnets", valid_606306
  var valid_606307 = query.getOrDefault("Version")
  valid_606307 = validateParameter(valid_606307, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606307 != nil:
    section.add "Version", valid_606307
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
  var valid_606308 = header.getOrDefault("X-Amz-Signature")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Signature", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Content-Sha256", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Date")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Date", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Credential")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Credential", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Security-Token")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Security-Token", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Algorithm")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Algorithm", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-SignedHeaders", valid_606314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606315: Call_GetCreateLoadBalancer_606295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606315.validator(path, query, header, formData, body)
  let scheme = call_606315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606315.url(scheme.get, call_606315.host, call_606315.base,
                         call_606315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606315, url, valid)

proc call*(call_606316: Call_GetCreateLoadBalancer_606295; Name: string;
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
  var query_606317 = newJObject()
  if SubnetMappings != nil:
    query_606317.add "SubnetMappings", SubnetMappings
  add(query_606317, "Type", newJString(Type))
  if Tags != nil:
    query_606317.add "Tags", Tags
  add(query_606317, "Scheme", newJString(Scheme))
  add(query_606317, "IpAddressType", newJString(IpAddressType))
  if SecurityGroups != nil:
    query_606317.add "SecurityGroups", SecurityGroups
  add(query_606317, "Name", newJString(Name))
  add(query_606317, "Action", newJString(Action))
  if Subnets != nil:
    query_606317.add "Subnets", Subnets
  add(query_606317, "Version", newJString(Version))
  result = call_606316.call(nil, query_606317, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_606295(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_606296, base: "/",
    url: url_GetCreateLoadBalancer_606297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateRule_606361 = ref object of OpenApiRestCall_605589
proc url_PostCreateRule_606363(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateRule_606362(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606364 = query.getOrDefault("Action")
  valid_606364 = validateParameter(valid_606364, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_606364 != nil:
    section.add "Action", valid_606364
  var valid_606365 = query.getOrDefault("Version")
  valid_606365 = validateParameter(valid_606365, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606365 != nil:
    section.add "Version", valid_606365
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
  var valid_606366 = header.getOrDefault("X-Amz-Signature")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Signature", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Content-Sha256", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Date")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Date", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Credential")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Credential", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Security-Token")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Security-Token", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-Algorithm")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Algorithm", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-SignedHeaders", valid_606372
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
  var valid_606373 = formData.getOrDefault("Actions")
  valid_606373 = validateParameter(valid_606373, JArray, required = true, default = nil)
  if valid_606373 != nil:
    section.add "Actions", valid_606373
  var valid_606374 = formData.getOrDefault("Conditions")
  valid_606374 = validateParameter(valid_606374, JArray, required = true, default = nil)
  if valid_606374 != nil:
    section.add "Conditions", valid_606374
  var valid_606375 = formData.getOrDefault("ListenerArn")
  valid_606375 = validateParameter(valid_606375, JString, required = true,
                                 default = nil)
  if valid_606375 != nil:
    section.add "ListenerArn", valid_606375
  var valid_606376 = formData.getOrDefault("Priority")
  valid_606376 = validateParameter(valid_606376, JInt, required = true, default = nil)
  if valid_606376 != nil:
    section.add "Priority", valid_606376
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606377: Call_PostCreateRule_606361; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_606377.validator(path, query, header, formData, body)
  let scheme = call_606377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606377.url(scheme.get, call_606377.host, call_606377.base,
                         call_606377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606377, url, valid)

proc call*(call_606378: Call_PostCreateRule_606361; Actions: JsonNode;
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
  var query_606379 = newJObject()
  var formData_606380 = newJObject()
  if Actions != nil:
    formData_606380.add "Actions", Actions
  if Conditions != nil:
    formData_606380.add "Conditions", Conditions
  add(formData_606380, "ListenerArn", newJString(ListenerArn))
  add(formData_606380, "Priority", newJInt(Priority))
  add(query_606379, "Action", newJString(Action))
  add(query_606379, "Version", newJString(Version))
  result = call_606378.call(nil, query_606379, nil, formData_606380, nil)

var postCreateRule* = Call_PostCreateRule_606361(name: "postCreateRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_PostCreateRule_606362,
    base: "/", url: url_PostCreateRule_606363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateRule_606342 = ref object of OpenApiRestCall_605589
proc url_GetCreateRule_606344(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateRule_606343(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606345 = query.getOrDefault("Actions")
  valid_606345 = validateParameter(valid_606345, JArray, required = true, default = nil)
  if valid_606345 != nil:
    section.add "Actions", valid_606345
  var valid_606346 = query.getOrDefault("ListenerArn")
  valid_606346 = validateParameter(valid_606346, JString, required = true,
                                 default = nil)
  if valid_606346 != nil:
    section.add "ListenerArn", valid_606346
  var valid_606347 = query.getOrDefault("Priority")
  valid_606347 = validateParameter(valid_606347, JInt, required = true, default = nil)
  if valid_606347 != nil:
    section.add "Priority", valid_606347
  var valid_606348 = query.getOrDefault("Action")
  valid_606348 = validateParameter(valid_606348, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_606348 != nil:
    section.add "Action", valid_606348
  var valid_606349 = query.getOrDefault("Version")
  valid_606349 = validateParameter(valid_606349, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606349 != nil:
    section.add "Version", valid_606349
  var valid_606350 = query.getOrDefault("Conditions")
  valid_606350 = validateParameter(valid_606350, JArray, required = true, default = nil)
  if valid_606350 != nil:
    section.add "Conditions", valid_606350
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
  var valid_606351 = header.getOrDefault("X-Amz-Signature")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Signature", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Content-Sha256", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Date")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Date", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Credential")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Credential", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Security-Token")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Security-Token", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Algorithm")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Algorithm", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-SignedHeaders", valid_606357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606358: Call_GetCreateRule_606342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_GetCreateRule_606342; Actions: JsonNode;
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
  var query_606360 = newJObject()
  if Actions != nil:
    query_606360.add "Actions", Actions
  add(query_606360, "ListenerArn", newJString(ListenerArn))
  add(query_606360, "Priority", newJInt(Priority))
  add(query_606360, "Action", newJString(Action))
  add(query_606360, "Version", newJString(Version))
  if Conditions != nil:
    query_606360.add "Conditions", Conditions
  result = call_606359.call(nil, query_606360, nil, nil, nil)

var getCreateRule* = Call_GetCreateRule_606342(name: "getCreateRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_GetCreateRule_606343,
    base: "/", url: url_GetCreateRule_606344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTargetGroup_606410 = ref object of OpenApiRestCall_605589
proc url_PostCreateTargetGroup_606412(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateTargetGroup_606411(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606413 = query.getOrDefault("Action")
  valid_606413 = validateParameter(valid_606413, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_606413 != nil:
    section.add "Action", valid_606413
  var valid_606414 = query.getOrDefault("Version")
  valid_606414 = validateParameter(valid_606414, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606414 != nil:
    section.add "Version", valid_606414
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
  var valid_606415 = header.getOrDefault("X-Amz-Signature")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Signature", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Content-Sha256", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Date")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Date", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Credential")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Credential", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Security-Token")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Security-Token", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Algorithm")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Algorithm", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-SignedHeaders", valid_606421
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
  var valid_606422 = formData.getOrDefault("HealthCheckProtocol")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_606422 != nil:
    section.add "HealthCheckProtocol", valid_606422
  var valid_606423 = formData.getOrDefault("Port")
  valid_606423 = validateParameter(valid_606423, JInt, required = false, default = nil)
  if valid_606423 != nil:
    section.add "Port", valid_606423
  var valid_606424 = formData.getOrDefault("HealthCheckPort")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "HealthCheckPort", valid_606424
  var valid_606425 = formData.getOrDefault("VpcId")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "VpcId", valid_606425
  var valid_606426 = formData.getOrDefault("HealthCheckEnabled")
  valid_606426 = validateParameter(valid_606426, JBool, required = false, default = nil)
  if valid_606426 != nil:
    section.add "HealthCheckEnabled", valid_606426
  var valid_606427 = formData.getOrDefault("HealthCheckPath")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "HealthCheckPath", valid_606427
  var valid_606428 = formData.getOrDefault("TargetType")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = newJString("instance"))
  if valid_606428 != nil:
    section.add "TargetType", valid_606428
  var valid_606429 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_606429 = validateParameter(valid_606429, JInt, required = false, default = nil)
  if valid_606429 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_606429
  var valid_606430 = formData.getOrDefault("HealthyThresholdCount")
  valid_606430 = validateParameter(valid_606430, JInt, required = false, default = nil)
  if valid_606430 != nil:
    section.add "HealthyThresholdCount", valid_606430
  var valid_606431 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_606431 = validateParameter(valid_606431, JInt, required = false, default = nil)
  if valid_606431 != nil:
    section.add "HealthCheckIntervalSeconds", valid_606431
  var valid_606432 = formData.getOrDefault("Protocol")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_606432 != nil:
    section.add "Protocol", valid_606432
  var valid_606433 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_606433 = validateParameter(valid_606433, JInt, required = false, default = nil)
  if valid_606433 != nil:
    section.add "UnhealthyThresholdCount", valid_606433
  var valid_606434 = formData.getOrDefault("Matcher.HttpCode")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "Matcher.HttpCode", valid_606434
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_606435 = formData.getOrDefault("Name")
  valid_606435 = validateParameter(valid_606435, JString, required = true,
                                 default = nil)
  if valid_606435 != nil:
    section.add "Name", valid_606435
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606436: Call_PostCreateTargetGroup_606410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606436.validator(path, query, header, formData, body)
  let scheme = call_606436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606436.url(scheme.get, call_606436.host, call_606436.base,
                         call_606436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606436, url, valid)

proc call*(call_606437: Call_PostCreateTargetGroup_606410; Name: string;
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
  var query_606438 = newJObject()
  var formData_606439 = newJObject()
  add(formData_606439, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_606439, "Port", newJInt(Port))
  add(formData_606439, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_606439, "VpcId", newJString(VpcId))
  add(formData_606439, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_606439, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_606439, "TargetType", newJString(TargetType))
  add(formData_606439, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_606439, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_606439, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_606439, "Protocol", newJString(Protocol))
  add(formData_606439, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_606439, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_606438, "Action", newJString(Action))
  add(formData_606439, "Name", newJString(Name))
  add(query_606438, "Version", newJString(Version))
  result = call_606437.call(nil, query_606438, nil, formData_606439, nil)

var postCreateTargetGroup* = Call_PostCreateTargetGroup_606410(
    name: "postCreateTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup",
    validator: validate_PostCreateTargetGroup_606411, base: "/",
    url: url_PostCreateTargetGroup_606412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTargetGroup_606381 = ref object of OpenApiRestCall_605589
proc url_GetCreateTargetGroup_606383(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateTargetGroup_606382(path: JsonNode; query: JsonNode;
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
  var valid_606384 = query.getOrDefault("HealthCheckPort")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "HealthCheckPort", valid_606384
  var valid_606385 = query.getOrDefault("TargetType")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = newJString("instance"))
  if valid_606385 != nil:
    section.add "TargetType", valid_606385
  var valid_606386 = query.getOrDefault("HealthCheckPath")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "HealthCheckPath", valid_606386
  var valid_606387 = query.getOrDefault("VpcId")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "VpcId", valid_606387
  var valid_606388 = query.getOrDefault("HealthCheckProtocol")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_606388 != nil:
    section.add "HealthCheckProtocol", valid_606388
  var valid_606389 = query.getOrDefault("Matcher.HttpCode")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "Matcher.HttpCode", valid_606389
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_606390 = query.getOrDefault("Name")
  valid_606390 = validateParameter(valid_606390, JString, required = true,
                                 default = nil)
  if valid_606390 != nil:
    section.add "Name", valid_606390
  var valid_606391 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_606391 = validateParameter(valid_606391, JInt, required = false, default = nil)
  if valid_606391 != nil:
    section.add "HealthCheckIntervalSeconds", valid_606391
  var valid_606392 = query.getOrDefault("HealthCheckEnabled")
  valid_606392 = validateParameter(valid_606392, JBool, required = false, default = nil)
  if valid_606392 != nil:
    section.add "HealthCheckEnabled", valid_606392
  var valid_606393 = query.getOrDefault("HealthyThresholdCount")
  valid_606393 = validateParameter(valid_606393, JInt, required = false, default = nil)
  if valid_606393 != nil:
    section.add "HealthyThresholdCount", valid_606393
  var valid_606394 = query.getOrDefault("UnhealthyThresholdCount")
  valid_606394 = validateParameter(valid_606394, JInt, required = false, default = nil)
  if valid_606394 != nil:
    section.add "UnhealthyThresholdCount", valid_606394
  var valid_606395 = query.getOrDefault("Action")
  valid_606395 = validateParameter(valid_606395, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_606395 != nil:
    section.add "Action", valid_606395
  var valid_606396 = query.getOrDefault("Protocol")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_606396 != nil:
    section.add "Protocol", valid_606396
  var valid_606397 = query.getOrDefault("Port")
  valid_606397 = validateParameter(valid_606397, JInt, required = false, default = nil)
  if valid_606397 != nil:
    section.add "Port", valid_606397
  var valid_606398 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_606398 = validateParameter(valid_606398, JInt, required = false, default = nil)
  if valid_606398 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_606398
  var valid_606399 = query.getOrDefault("Version")
  valid_606399 = validateParameter(valid_606399, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606399 != nil:
    section.add "Version", valid_606399
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
  var valid_606400 = header.getOrDefault("X-Amz-Signature")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Signature", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Content-Sha256", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-Date")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Date", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Credential")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Credential", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Security-Token")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Security-Token", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Algorithm")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Algorithm", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-SignedHeaders", valid_606406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606407: Call_GetCreateTargetGroup_606381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606407.validator(path, query, header, formData, body)
  let scheme = call_606407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606407.url(scheme.get, call_606407.host, call_606407.base,
                         call_606407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606407, url, valid)

proc call*(call_606408: Call_GetCreateTargetGroup_606381; Name: string;
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
  var query_606409 = newJObject()
  add(query_606409, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_606409, "TargetType", newJString(TargetType))
  add(query_606409, "HealthCheckPath", newJString(HealthCheckPath))
  add(query_606409, "VpcId", newJString(VpcId))
  add(query_606409, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_606409, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_606409, "Name", newJString(Name))
  add(query_606409, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_606409, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_606409, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_606409, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_606409, "Action", newJString(Action))
  add(query_606409, "Protocol", newJString(Protocol))
  add(query_606409, "Port", newJInt(Port))
  add(query_606409, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_606409, "Version", newJString(Version))
  result = call_606408.call(nil, query_606409, nil, nil, nil)

var getCreateTargetGroup* = Call_GetCreateTargetGroup_606381(
    name: "getCreateTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup", validator: validate_GetCreateTargetGroup_606382,
    base: "/", url: url_GetCreateTargetGroup_606383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteListener_606456 = ref object of OpenApiRestCall_605589
proc url_PostDeleteListener_606458(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteListener_606457(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606459 = query.getOrDefault("Action")
  valid_606459 = validateParameter(valid_606459, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_606459 != nil:
    section.add "Action", valid_606459
  var valid_606460 = query.getOrDefault("Version")
  valid_606460 = validateParameter(valid_606460, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606460 != nil:
    section.add "Version", valid_606460
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
  var valid_606461 = header.getOrDefault("X-Amz-Signature")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Signature", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Content-Sha256", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Date")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Date", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Credential")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Credential", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Security-Token")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Security-Token", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Algorithm")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Algorithm", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-SignedHeaders", valid_606467
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_606468 = formData.getOrDefault("ListenerArn")
  valid_606468 = validateParameter(valid_606468, JString, required = true,
                                 default = nil)
  if valid_606468 != nil:
    section.add "ListenerArn", valid_606468
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606469: Call_PostDeleteListener_606456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_606469.validator(path, query, header, formData, body)
  let scheme = call_606469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606469.url(scheme.get, call_606469.host, call_606469.base,
                         call_606469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606469, url, valid)

proc call*(call_606470: Call_PostDeleteListener_606456; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606471 = newJObject()
  var formData_606472 = newJObject()
  add(formData_606472, "ListenerArn", newJString(ListenerArn))
  add(query_606471, "Action", newJString(Action))
  add(query_606471, "Version", newJString(Version))
  result = call_606470.call(nil, query_606471, nil, formData_606472, nil)

var postDeleteListener* = Call_PostDeleteListener_606456(
    name: "postDeleteListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=DeleteListener",
    validator: validate_PostDeleteListener_606457, base: "/",
    url: url_PostDeleteListener_606458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteListener_606440 = ref object of OpenApiRestCall_605589
proc url_GetDeleteListener_606442(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteListener_606441(path: JsonNode; query: JsonNode;
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
  var valid_606443 = query.getOrDefault("ListenerArn")
  valid_606443 = validateParameter(valid_606443, JString, required = true,
                                 default = nil)
  if valid_606443 != nil:
    section.add "ListenerArn", valid_606443
  var valid_606444 = query.getOrDefault("Action")
  valid_606444 = validateParameter(valid_606444, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_606444 != nil:
    section.add "Action", valid_606444
  var valid_606445 = query.getOrDefault("Version")
  valid_606445 = validateParameter(valid_606445, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606445 != nil:
    section.add "Version", valid_606445
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
  var valid_606446 = header.getOrDefault("X-Amz-Signature")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Signature", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Content-Sha256", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Date")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Date", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Credential")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Credential", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Security-Token")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Security-Token", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Algorithm")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Algorithm", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-SignedHeaders", valid_606452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606453: Call_GetDeleteListener_606440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_606453.validator(path, query, header, formData, body)
  let scheme = call_606453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606453.url(scheme.get, call_606453.host, call_606453.base,
                         call_606453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606453, url, valid)

proc call*(call_606454: Call_GetDeleteListener_606440; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606455 = newJObject()
  add(query_606455, "ListenerArn", newJString(ListenerArn))
  add(query_606455, "Action", newJString(Action))
  add(query_606455, "Version", newJString(Version))
  result = call_606454.call(nil, query_606455, nil, nil, nil)

var getDeleteListener* = Call_GetDeleteListener_606440(name: "getDeleteListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteListener", validator: validate_GetDeleteListener_606441,
    base: "/", url: url_GetDeleteListener_606442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_606489 = ref object of OpenApiRestCall_605589
proc url_PostDeleteLoadBalancer_606491(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteLoadBalancer_606490(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606492 = query.getOrDefault("Action")
  valid_606492 = validateParameter(valid_606492, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_606492 != nil:
    section.add "Action", valid_606492
  var valid_606493 = query.getOrDefault("Version")
  valid_606493 = validateParameter(valid_606493, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606493 != nil:
    section.add "Version", valid_606493
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
  var valid_606494 = header.getOrDefault("X-Amz-Signature")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-Signature", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Content-Sha256", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-Date")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Date", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Credential")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Credential", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-Security-Token")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-Security-Token", valid_606498
  var valid_606499 = header.getOrDefault("X-Amz-Algorithm")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Algorithm", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-SignedHeaders", valid_606500
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_606501 = formData.getOrDefault("LoadBalancerArn")
  valid_606501 = validateParameter(valid_606501, JString, required = true,
                                 default = nil)
  if valid_606501 != nil:
    section.add "LoadBalancerArn", valid_606501
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606502: Call_PostDeleteLoadBalancer_606489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_606502.validator(path, query, header, formData, body)
  let scheme = call_606502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606502.url(scheme.get, call_606502.host, call_606502.base,
                         call_606502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606502, url, valid)

proc call*(call_606503: Call_PostDeleteLoadBalancer_606489;
          LoadBalancerArn: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2015-12-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_606504 = newJObject()
  var formData_606505 = newJObject()
  add(query_606504, "Action", newJString(Action))
  add(query_606504, "Version", newJString(Version))
  add(formData_606505, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_606503.call(nil, query_606504, nil, formData_606505, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_606489(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_606490, base: "/",
    url: url_PostDeleteLoadBalancer_606491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_606473 = ref object of OpenApiRestCall_605589
proc url_GetDeleteLoadBalancer_606475(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteLoadBalancer_606474(path: JsonNode; query: JsonNode;
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
  var valid_606476 = query.getOrDefault("LoadBalancerArn")
  valid_606476 = validateParameter(valid_606476, JString, required = true,
                                 default = nil)
  if valid_606476 != nil:
    section.add "LoadBalancerArn", valid_606476
  var valid_606477 = query.getOrDefault("Action")
  valid_606477 = validateParameter(valid_606477, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_606477 != nil:
    section.add "Action", valid_606477
  var valid_606478 = query.getOrDefault("Version")
  valid_606478 = validateParameter(valid_606478, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606478 != nil:
    section.add "Version", valid_606478
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
  var valid_606479 = header.getOrDefault("X-Amz-Signature")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Signature", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Content-Sha256", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-Date")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Date", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-Credential")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Credential", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-Security-Token")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Security-Token", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Algorithm")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Algorithm", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-SignedHeaders", valid_606485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606486: Call_GetDeleteLoadBalancer_606473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_606486.validator(path, query, header, formData, body)
  let scheme = call_606486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606486.url(scheme.get, call_606486.host, call_606486.base,
                         call_606486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606486, url, valid)

proc call*(call_606487: Call_GetDeleteLoadBalancer_606473; LoadBalancerArn: string;
          Action: string = "DeleteLoadBalancer"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606488 = newJObject()
  add(query_606488, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_606488, "Action", newJString(Action))
  add(query_606488, "Version", newJString(Version))
  result = call_606487.call(nil, query_606488, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_606473(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_606474, base: "/",
    url: url_GetDeleteLoadBalancer_606475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRule_606522 = ref object of OpenApiRestCall_605589
proc url_PostDeleteRule_606524(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteRule_606523(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606525 = query.getOrDefault("Action")
  valid_606525 = validateParameter(valid_606525, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_606525 != nil:
    section.add "Action", valid_606525
  var valid_606526 = query.getOrDefault("Version")
  valid_606526 = validateParameter(valid_606526, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606526 != nil:
    section.add "Version", valid_606526
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
  var valid_606527 = header.getOrDefault("X-Amz-Signature")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-Signature", valid_606527
  var valid_606528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-Content-Sha256", valid_606528
  var valid_606529 = header.getOrDefault("X-Amz-Date")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "X-Amz-Date", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Credential")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Credential", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Security-Token")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Security-Token", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Algorithm")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Algorithm", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-SignedHeaders", valid_606533
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_606534 = formData.getOrDefault("RuleArn")
  valid_606534 = validateParameter(valid_606534, JString, required = true,
                                 default = nil)
  if valid_606534 != nil:
    section.add "RuleArn", valid_606534
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606535: Call_PostDeleteRule_606522; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_606535.validator(path, query, header, formData, body)
  let scheme = call_606535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606535.url(scheme.get, call_606535.host, call_606535.base,
                         call_606535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606535, url, valid)

proc call*(call_606536: Call_PostDeleteRule_606522; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606537 = newJObject()
  var formData_606538 = newJObject()
  add(formData_606538, "RuleArn", newJString(RuleArn))
  add(query_606537, "Action", newJString(Action))
  add(query_606537, "Version", newJString(Version))
  result = call_606536.call(nil, query_606537, nil, formData_606538, nil)

var postDeleteRule* = Call_PostDeleteRule_606522(name: "postDeleteRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_PostDeleteRule_606523,
    base: "/", url: url_PostDeleteRule_606524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRule_606506 = ref object of OpenApiRestCall_605589
proc url_GetDeleteRule_606508(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteRule_606507(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606509 = query.getOrDefault("RuleArn")
  valid_606509 = validateParameter(valid_606509, JString, required = true,
                                 default = nil)
  if valid_606509 != nil:
    section.add "RuleArn", valid_606509
  var valid_606510 = query.getOrDefault("Action")
  valid_606510 = validateParameter(valid_606510, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_606510 != nil:
    section.add "Action", valid_606510
  var valid_606511 = query.getOrDefault("Version")
  valid_606511 = validateParameter(valid_606511, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606511 != nil:
    section.add "Version", valid_606511
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
  var valid_606512 = header.getOrDefault("X-Amz-Signature")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Signature", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Content-Sha256", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-Date")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Date", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Credential")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Credential", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Security-Token")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Security-Token", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Algorithm")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Algorithm", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-SignedHeaders", valid_606518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606519: Call_GetDeleteRule_606506; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_606519.validator(path, query, header, formData, body)
  let scheme = call_606519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606519.url(scheme.get, call_606519.host, call_606519.base,
                         call_606519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606519, url, valid)

proc call*(call_606520: Call_GetDeleteRule_606506; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606521 = newJObject()
  add(query_606521, "RuleArn", newJString(RuleArn))
  add(query_606521, "Action", newJString(Action))
  add(query_606521, "Version", newJString(Version))
  result = call_606520.call(nil, query_606521, nil, nil, nil)

var getDeleteRule* = Call_GetDeleteRule_606506(name: "getDeleteRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_GetDeleteRule_606507,
    base: "/", url: url_GetDeleteRule_606508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTargetGroup_606555 = ref object of OpenApiRestCall_605589
proc url_PostDeleteTargetGroup_606557(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteTargetGroup_606556(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606558 = query.getOrDefault("Action")
  valid_606558 = validateParameter(valid_606558, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_606558 != nil:
    section.add "Action", valid_606558
  var valid_606559 = query.getOrDefault("Version")
  valid_606559 = validateParameter(valid_606559, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606559 != nil:
    section.add "Version", valid_606559
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
  var valid_606560 = header.getOrDefault("X-Amz-Signature")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Signature", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Content-Sha256", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Date")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Date", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Credential")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Credential", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Security-Token")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Security-Token", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Algorithm")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Algorithm", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-SignedHeaders", valid_606566
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_606567 = formData.getOrDefault("TargetGroupArn")
  valid_606567 = validateParameter(valid_606567, JString, required = true,
                                 default = nil)
  if valid_606567 != nil:
    section.add "TargetGroupArn", valid_606567
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606568: Call_PostDeleteTargetGroup_606555; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_606568.validator(path, query, header, formData, body)
  let scheme = call_606568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606568.url(scheme.get, call_606568.host, call_606568.base,
                         call_606568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606568, url, valid)

proc call*(call_606569: Call_PostDeleteTargetGroup_606555; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_606570 = newJObject()
  var formData_606571 = newJObject()
  add(query_606570, "Action", newJString(Action))
  add(formData_606571, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_606570, "Version", newJString(Version))
  result = call_606569.call(nil, query_606570, nil, formData_606571, nil)

var postDeleteTargetGroup* = Call_PostDeleteTargetGroup_606555(
    name: "postDeleteTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup",
    validator: validate_PostDeleteTargetGroup_606556, base: "/",
    url: url_PostDeleteTargetGroup_606557, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTargetGroup_606539 = ref object of OpenApiRestCall_605589
proc url_GetDeleteTargetGroup_606541(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteTargetGroup_606540(path: JsonNode; query: JsonNode;
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
  var valid_606542 = query.getOrDefault("TargetGroupArn")
  valid_606542 = validateParameter(valid_606542, JString, required = true,
                                 default = nil)
  if valid_606542 != nil:
    section.add "TargetGroupArn", valid_606542
  var valid_606543 = query.getOrDefault("Action")
  valid_606543 = validateParameter(valid_606543, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_606543 != nil:
    section.add "Action", valid_606543
  var valid_606544 = query.getOrDefault("Version")
  valid_606544 = validateParameter(valid_606544, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606544 != nil:
    section.add "Version", valid_606544
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
  var valid_606545 = header.getOrDefault("X-Amz-Signature")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Signature", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Content-Sha256", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Date")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Date", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Credential")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Credential", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Security-Token")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Security-Token", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Algorithm")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Algorithm", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-SignedHeaders", valid_606551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606552: Call_GetDeleteTargetGroup_606539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_606552.validator(path, query, header, formData, body)
  let scheme = call_606552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606552.url(scheme.get, call_606552.host, call_606552.base,
                         call_606552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606552, url, valid)

proc call*(call_606553: Call_GetDeleteTargetGroup_606539; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606554 = newJObject()
  add(query_606554, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_606554, "Action", newJString(Action))
  add(query_606554, "Version", newJString(Version))
  result = call_606553.call(nil, query_606554, nil, nil, nil)

var getDeleteTargetGroup* = Call_GetDeleteTargetGroup_606539(
    name: "getDeleteTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup", validator: validate_GetDeleteTargetGroup_606540,
    base: "/", url: url_GetDeleteTargetGroup_606541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterTargets_606589 = ref object of OpenApiRestCall_605589
proc url_PostDeregisterTargets_606591(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeregisterTargets_606590(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606592 = query.getOrDefault("Action")
  valid_606592 = validateParameter(valid_606592, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_606592 != nil:
    section.add "Action", valid_606592
  var valid_606593 = query.getOrDefault("Version")
  valid_606593 = validateParameter(valid_606593, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606593 != nil:
    section.add "Version", valid_606593
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
  var valid_606594 = header.getOrDefault("X-Amz-Signature")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Signature", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Content-Sha256", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Date")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Date", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Credential")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Credential", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Security-Token")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Security-Token", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Algorithm")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Algorithm", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-SignedHeaders", valid_606600
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_606601 = formData.getOrDefault("Targets")
  valid_606601 = validateParameter(valid_606601, JArray, required = true, default = nil)
  if valid_606601 != nil:
    section.add "Targets", valid_606601
  var valid_606602 = formData.getOrDefault("TargetGroupArn")
  valid_606602 = validateParameter(valid_606602, JString, required = true,
                                 default = nil)
  if valid_606602 != nil:
    section.add "TargetGroupArn", valid_606602
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606603: Call_PostDeregisterTargets_606589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_606603.validator(path, query, header, formData, body)
  let scheme = call_606603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606603.url(scheme.get, call_606603.host, call_606603.base,
                         call_606603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606603, url, valid)

proc call*(call_606604: Call_PostDeregisterTargets_606589; Targets: JsonNode;
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
  var query_606605 = newJObject()
  var formData_606606 = newJObject()
  if Targets != nil:
    formData_606606.add "Targets", Targets
  add(query_606605, "Action", newJString(Action))
  add(formData_606606, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_606605, "Version", newJString(Version))
  result = call_606604.call(nil, query_606605, nil, formData_606606, nil)

var postDeregisterTargets* = Call_PostDeregisterTargets_606589(
    name: "postDeregisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets",
    validator: validate_PostDeregisterTargets_606590, base: "/",
    url: url_PostDeregisterTargets_606591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterTargets_606572 = ref object of OpenApiRestCall_605589
proc url_GetDeregisterTargets_606574(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeregisterTargets_606573(path: JsonNode; query: JsonNode;
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
  var valid_606575 = query.getOrDefault("Targets")
  valid_606575 = validateParameter(valid_606575, JArray, required = true, default = nil)
  if valid_606575 != nil:
    section.add "Targets", valid_606575
  var valid_606576 = query.getOrDefault("TargetGroupArn")
  valid_606576 = validateParameter(valid_606576, JString, required = true,
                                 default = nil)
  if valid_606576 != nil:
    section.add "TargetGroupArn", valid_606576
  var valid_606577 = query.getOrDefault("Action")
  valid_606577 = validateParameter(valid_606577, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_606577 != nil:
    section.add "Action", valid_606577
  var valid_606578 = query.getOrDefault("Version")
  valid_606578 = validateParameter(valid_606578, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606578 != nil:
    section.add "Version", valid_606578
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
  var valid_606579 = header.getOrDefault("X-Amz-Signature")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Signature", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Content-Sha256", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Date")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Date", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Credential")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Credential", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Security-Token")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Security-Token", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Algorithm")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Algorithm", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-SignedHeaders", valid_606585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606586: Call_GetDeregisterTargets_606572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_606586.validator(path, query, header, formData, body)
  let scheme = call_606586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606586.url(scheme.get, call_606586.host, call_606586.base,
                         call_606586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606586, url, valid)

proc call*(call_606587: Call_GetDeregisterTargets_606572; Targets: JsonNode;
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
  var query_606588 = newJObject()
  if Targets != nil:
    query_606588.add "Targets", Targets
  add(query_606588, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_606588, "Action", newJString(Action))
  add(query_606588, "Version", newJString(Version))
  result = call_606587.call(nil, query_606588, nil, nil, nil)

var getDeregisterTargets* = Call_GetDeregisterTargets_606572(
    name: "getDeregisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets", validator: validate_GetDeregisterTargets_606573,
    base: "/", url: url_GetDeregisterTargets_606574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_606624 = ref object of OpenApiRestCall_605589
proc url_PostDescribeAccountLimits_606626(protocol: Scheme; host: string;
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

proc validate_PostDescribeAccountLimits_606625(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606627 = query.getOrDefault("Action")
  valid_606627 = validateParameter(valid_606627, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_606627 != nil:
    section.add "Action", valid_606627
  var valid_606628 = query.getOrDefault("Version")
  valid_606628 = validateParameter(valid_606628, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606628 != nil:
    section.add "Version", valid_606628
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
  var valid_606629 = header.getOrDefault("X-Amz-Signature")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-Signature", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-Content-Sha256", valid_606630
  var valid_606631 = header.getOrDefault("X-Amz-Date")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "X-Amz-Date", valid_606631
  var valid_606632 = header.getOrDefault("X-Amz-Credential")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "X-Amz-Credential", valid_606632
  var valid_606633 = header.getOrDefault("X-Amz-Security-Token")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-Security-Token", valid_606633
  var valid_606634 = header.getOrDefault("X-Amz-Algorithm")
  valid_606634 = validateParameter(valid_606634, JString, required = false,
                                 default = nil)
  if valid_606634 != nil:
    section.add "X-Amz-Algorithm", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-SignedHeaders", valid_606635
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_606636 = formData.getOrDefault("Marker")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "Marker", valid_606636
  var valid_606637 = formData.getOrDefault("PageSize")
  valid_606637 = validateParameter(valid_606637, JInt, required = false, default = nil)
  if valid_606637 != nil:
    section.add "PageSize", valid_606637
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606638: Call_PostDescribeAccountLimits_606624; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606638.validator(path, query, header, formData, body)
  let scheme = call_606638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606638.url(scheme.get, call_606638.host, call_606638.base,
                         call_606638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606638, url, valid)

proc call*(call_606639: Call_PostDescribeAccountLimits_606624; Marker: string = "";
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
  var query_606640 = newJObject()
  var formData_606641 = newJObject()
  add(formData_606641, "Marker", newJString(Marker))
  add(query_606640, "Action", newJString(Action))
  add(formData_606641, "PageSize", newJInt(PageSize))
  add(query_606640, "Version", newJString(Version))
  result = call_606639.call(nil, query_606640, nil, formData_606641, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_606624(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_606625, base: "/",
    url: url_PostDescribeAccountLimits_606626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_606607 = ref object of OpenApiRestCall_605589
proc url_GetDescribeAccountLimits_606609(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAccountLimits_606608(path: JsonNode; query: JsonNode;
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
  var valid_606610 = query.getOrDefault("Marker")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "Marker", valid_606610
  var valid_606611 = query.getOrDefault("PageSize")
  valid_606611 = validateParameter(valid_606611, JInt, required = false, default = nil)
  if valid_606611 != nil:
    section.add "PageSize", valid_606611
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606612 = query.getOrDefault("Action")
  valid_606612 = validateParameter(valid_606612, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_606612 != nil:
    section.add "Action", valid_606612
  var valid_606613 = query.getOrDefault("Version")
  valid_606613 = validateParameter(valid_606613, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606613 != nil:
    section.add "Version", valid_606613
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
  var valid_606614 = header.getOrDefault("X-Amz-Signature")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Signature", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-Content-Sha256", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-Date")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Date", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-Credential")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Credential", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-Security-Token")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-Security-Token", valid_606618
  var valid_606619 = header.getOrDefault("X-Amz-Algorithm")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-Algorithm", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-SignedHeaders", valid_606620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606621: Call_GetDescribeAccountLimits_606607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606621.validator(path, query, header, formData, body)
  let scheme = call_606621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606621.url(scheme.get, call_606621.host, call_606621.base,
                         call_606621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606621, url, valid)

proc call*(call_606622: Call_GetDescribeAccountLimits_606607; Marker: string = "";
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
  var query_606623 = newJObject()
  add(query_606623, "Marker", newJString(Marker))
  add(query_606623, "PageSize", newJInt(PageSize))
  add(query_606623, "Action", newJString(Action))
  add(query_606623, "Version", newJString(Version))
  result = call_606622.call(nil, query_606623, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_606607(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_606608, base: "/",
    url: url_GetDescribeAccountLimits_606609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListenerCertificates_606660 = ref object of OpenApiRestCall_605589
proc url_PostDescribeListenerCertificates_606662(protocol: Scheme; host: string;
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

proc validate_PostDescribeListenerCertificates_606661(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606663 = query.getOrDefault("Action")
  valid_606663 = validateParameter(valid_606663, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_606663 != nil:
    section.add "Action", valid_606663
  var valid_606664 = query.getOrDefault("Version")
  valid_606664 = validateParameter(valid_606664, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606664 != nil:
    section.add "Version", valid_606664
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
  var valid_606665 = header.getOrDefault("X-Amz-Signature")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Signature", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Content-Sha256", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Date")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Date", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-Credential")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Credential", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Security-Token")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Security-Token", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Algorithm")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Algorithm", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-SignedHeaders", valid_606671
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
  var valid_606672 = formData.getOrDefault("ListenerArn")
  valid_606672 = validateParameter(valid_606672, JString, required = true,
                                 default = nil)
  if valid_606672 != nil:
    section.add "ListenerArn", valid_606672
  var valid_606673 = formData.getOrDefault("Marker")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "Marker", valid_606673
  var valid_606674 = formData.getOrDefault("PageSize")
  valid_606674 = validateParameter(valid_606674, JInt, required = false, default = nil)
  if valid_606674 != nil:
    section.add "PageSize", valid_606674
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606675: Call_PostDescribeListenerCertificates_606660;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606675.validator(path, query, header, formData, body)
  let scheme = call_606675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606675.url(scheme.get, call_606675.host, call_606675.base,
                         call_606675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606675, url, valid)

proc call*(call_606676: Call_PostDescribeListenerCertificates_606660;
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
  var query_606677 = newJObject()
  var formData_606678 = newJObject()
  add(formData_606678, "ListenerArn", newJString(ListenerArn))
  add(formData_606678, "Marker", newJString(Marker))
  add(query_606677, "Action", newJString(Action))
  add(formData_606678, "PageSize", newJInt(PageSize))
  add(query_606677, "Version", newJString(Version))
  result = call_606676.call(nil, query_606677, nil, formData_606678, nil)

var postDescribeListenerCertificates* = Call_PostDescribeListenerCertificates_606660(
    name: "postDescribeListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_PostDescribeListenerCertificates_606661, base: "/",
    url: url_PostDescribeListenerCertificates_606662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListenerCertificates_606642 = ref object of OpenApiRestCall_605589
proc url_GetDescribeListenerCertificates_606644(protocol: Scheme; host: string;
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

proc validate_GetDescribeListenerCertificates_606643(path: JsonNode;
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
  var valid_606645 = query.getOrDefault("Marker")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "Marker", valid_606645
  assert query != nil,
        "query argument is necessary due to required `ListenerArn` field"
  var valid_606646 = query.getOrDefault("ListenerArn")
  valid_606646 = validateParameter(valid_606646, JString, required = true,
                                 default = nil)
  if valid_606646 != nil:
    section.add "ListenerArn", valid_606646
  var valid_606647 = query.getOrDefault("PageSize")
  valid_606647 = validateParameter(valid_606647, JInt, required = false, default = nil)
  if valid_606647 != nil:
    section.add "PageSize", valid_606647
  var valid_606648 = query.getOrDefault("Action")
  valid_606648 = validateParameter(valid_606648, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_606648 != nil:
    section.add "Action", valid_606648
  var valid_606649 = query.getOrDefault("Version")
  valid_606649 = validateParameter(valid_606649, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606649 != nil:
    section.add "Version", valid_606649
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
  var valid_606650 = header.getOrDefault("X-Amz-Signature")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Signature", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Content-Sha256", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Date")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Date", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-Credential")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Credential", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-Security-Token")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Security-Token", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Algorithm")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Algorithm", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-SignedHeaders", valid_606656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606657: Call_GetDescribeListenerCertificates_606642;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606657.validator(path, query, header, formData, body)
  let scheme = call_606657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606657.url(scheme.get, call_606657.host, call_606657.base,
                         call_606657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606657, url, valid)

proc call*(call_606658: Call_GetDescribeListenerCertificates_606642;
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
  var query_606659 = newJObject()
  add(query_606659, "Marker", newJString(Marker))
  add(query_606659, "ListenerArn", newJString(ListenerArn))
  add(query_606659, "PageSize", newJInt(PageSize))
  add(query_606659, "Action", newJString(Action))
  add(query_606659, "Version", newJString(Version))
  result = call_606658.call(nil, query_606659, nil, nil, nil)

var getDescribeListenerCertificates* = Call_GetDescribeListenerCertificates_606642(
    name: "getDescribeListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_GetDescribeListenerCertificates_606643, base: "/",
    url: url_GetDescribeListenerCertificates_606644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListeners_606698 = ref object of OpenApiRestCall_605589
proc url_PostDescribeListeners_606700(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeListeners_606699(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606701 = query.getOrDefault("Action")
  valid_606701 = validateParameter(valid_606701, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_606701 != nil:
    section.add "Action", valid_606701
  var valid_606702 = query.getOrDefault("Version")
  valid_606702 = validateParameter(valid_606702, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606702 != nil:
    section.add "Version", valid_606702
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
  var valid_606703 = header.getOrDefault("X-Amz-Signature")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Signature", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-Content-Sha256", valid_606704
  var valid_606705 = header.getOrDefault("X-Amz-Date")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Date", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-Credential")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Credential", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-Security-Token")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Security-Token", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-Algorithm")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Algorithm", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-SignedHeaders", valid_606709
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
  var valid_606710 = formData.getOrDefault("Marker")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "Marker", valid_606710
  var valid_606711 = formData.getOrDefault("PageSize")
  valid_606711 = validateParameter(valid_606711, JInt, required = false, default = nil)
  if valid_606711 != nil:
    section.add "PageSize", valid_606711
  var valid_606712 = formData.getOrDefault("LoadBalancerArn")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "LoadBalancerArn", valid_606712
  var valid_606713 = formData.getOrDefault("ListenerArns")
  valid_606713 = validateParameter(valid_606713, JArray, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "ListenerArns", valid_606713
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606714: Call_PostDescribeListeners_606698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_606714.validator(path, query, header, formData, body)
  let scheme = call_606714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606714.url(scheme.get, call_606714.host, call_606714.base,
                         call_606714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606714, url, valid)

proc call*(call_606715: Call_PostDescribeListeners_606698; Marker: string = "";
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
  var query_606716 = newJObject()
  var formData_606717 = newJObject()
  add(formData_606717, "Marker", newJString(Marker))
  add(query_606716, "Action", newJString(Action))
  add(formData_606717, "PageSize", newJInt(PageSize))
  add(query_606716, "Version", newJString(Version))
  add(formData_606717, "LoadBalancerArn", newJString(LoadBalancerArn))
  if ListenerArns != nil:
    formData_606717.add "ListenerArns", ListenerArns
  result = call_606715.call(nil, query_606716, nil, formData_606717, nil)

var postDescribeListeners* = Call_PostDescribeListeners_606698(
    name: "postDescribeListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners",
    validator: validate_PostDescribeListeners_606699, base: "/",
    url: url_PostDescribeListeners_606700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListeners_606679 = ref object of OpenApiRestCall_605589
proc url_GetDescribeListeners_606681(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeListeners_606680(path: JsonNode; query: JsonNode;
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
  var valid_606682 = query.getOrDefault("Marker")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "Marker", valid_606682
  var valid_606683 = query.getOrDefault("LoadBalancerArn")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "LoadBalancerArn", valid_606683
  var valid_606684 = query.getOrDefault("ListenerArns")
  valid_606684 = validateParameter(valid_606684, JArray, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "ListenerArns", valid_606684
  var valid_606685 = query.getOrDefault("PageSize")
  valid_606685 = validateParameter(valid_606685, JInt, required = false, default = nil)
  if valid_606685 != nil:
    section.add "PageSize", valid_606685
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606686 = query.getOrDefault("Action")
  valid_606686 = validateParameter(valid_606686, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_606686 != nil:
    section.add "Action", valid_606686
  var valid_606687 = query.getOrDefault("Version")
  valid_606687 = validateParameter(valid_606687, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606687 != nil:
    section.add "Version", valid_606687
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
  var valid_606688 = header.getOrDefault("X-Amz-Signature")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Signature", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Content-Sha256", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-Date")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-Date", valid_606690
  var valid_606691 = header.getOrDefault("X-Amz-Credential")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Credential", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-Security-Token")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-Security-Token", valid_606692
  var valid_606693 = header.getOrDefault("X-Amz-Algorithm")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-Algorithm", valid_606693
  var valid_606694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606694 = validateParameter(valid_606694, JString, required = false,
                                 default = nil)
  if valid_606694 != nil:
    section.add "X-Amz-SignedHeaders", valid_606694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606695: Call_GetDescribeListeners_606679; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_606695.validator(path, query, header, formData, body)
  let scheme = call_606695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606695.url(scheme.get, call_606695.host, call_606695.base,
                         call_606695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606695, url, valid)

proc call*(call_606696: Call_GetDescribeListeners_606679; Marker: string = "";
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
  var query_606697 = newJObject()
  add(query_606697, "Marker", newJString(Marker))
  add(query_606697, "LoadBalancerArn", newJString(LoadBalancerArn))
  if ListenerArns != nil:
    query_606697.add "ListenerArns", ListenerArns
  add(query_606697, "PageSize", newJInt(PageSize))
  add(query_606697, "Action", newJString(Action))
  add(query_606697, "Version", newJString(Version))
  result = call_606696.call(nil, query_606697, nil, nil, nil)

var getDescribeListeners* = Call_GetDescribeListeners_606679(
    name: "getDescribeListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners", validator: validate_GetDescribeListeners_606680,
    base: "/", url: url_GetDescribeListeners_606681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_606734 = ref object of OpenApiRestCall_605589
proc url_PostDescribeLoadBalancerAttributes_606736(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancerAttributes_606735(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606737 = query.getOrDefault("Action")
  valid_606737 = validateParameter(valid_606737, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_606737 != nil:
    section.add "Action", valid_606737
  var valid_606738 = query.getOrDefault("Version")
  valid_606738 = validateParameter(valid_606738, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606738 != nil:
    section.add "Version", valid_606738
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
  var valid_606739 = header.getOrDefault("X-Amz-Signature")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "X-Amz-Signature", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-Content-Sha256", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-Date")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-Date", valid_606741
  var valid_606742 = header.getOrDefault("X-Amz-Credential")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Credential", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-Security-Token")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Security-Token", valid_606743
  var valid_606744 = header.getOrDefault("X-Amz-Algorithm")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Algorithm", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-SignedHeaders", valid_606745
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_606746 = formData.getOrDefault("LoadBalancerArn")
  valid_606746 = validateParameter(valid_606746, JString, required = true,
                                 default = nil)
  if valid_606746 != nil:
    section.add "LoadBalancerArn", valid_606746
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606747: Call_PostDescribeLoadBalancerAttributes_606734;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606747.validator(path, query, header, formData, body)
  let scheme = call_606747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606747.url(scheme.get, call_606747.host, call_606747.base,
                         call_606747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606747, url, valid)

proc call*(call_606748: Call_PostDescribeLoadBalancerAttributes_606734;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_606749 = newJObject()
  var formData_606750 = newJObject()
  add(query_606749, "Action", newJString(Action))
  add(query_606749, "Version", newJString(Version))
  add(formData_606750, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_606748.call(nil, query_606749, nil, formData_606750, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_606734(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_606735, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_606736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_606718 = ref object of OpenApiRestCall_605589
proc url_GetDescribeLoadBalancerAttributes_606720(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancerAttributes_606719(path: JsonNode;
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
  var valid_606721 = query.getOrDefault("LoadBalancerArn")
  valid_606721 = validateParameter(valid_606721, JString, required = true,
                                 default = nil)
  if valid_606721 != nil:
    section.add "LoadBalancerArn", valid_606721
  var valid_606722 = query.getOrDefault("Action")
  valid_606722 = validateParameter(valid_606722, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_606722 != nil:
    section.add "Action", valid_606722
  var valid_606723 = query.getOrDefault("Version")
  valid_606723 = validateParameter(valid_606723, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606723 != nil:
    section.add "Version", valid_606723
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
  var valid_606724 = header.getOrDefault("X-Amz-Signature")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Signature", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Content-Sha256", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-Date")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Date", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-Credential")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Credential", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-Security-Token")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-Security-Token", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-Algorithm")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-Algorithm", valid_606729
  var valid_606730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-SignedHeaders", valid_606730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606731: Call_GetDescribeLoadBalancerAttributes_606718;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606731.validator(path, query, header, formData, body)
  let scheme = call_606731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606731.url(scheme.get, call_606731.host, call_606731.base,
                         call_606731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606731, url, valid)

proc call*(call_606732: Call_GetDescribeLoadBalancerAttributes_606718;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606733 = newJObject()
  add(query_606733, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_606733, "Action", newJString(Action))
  add(query_606733, "Version", newJString(Version))
  result = call_606732.call(nil, query_606733, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_606718(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_606719, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_606720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_606770 = ref object of OpenApiRestCall_605589
proc url_PostDescribeLoadBalancers_606772(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancers_606771(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606773 = query.getOrDefault("Action")
  valid_606773 = validateParameter(valid_606773, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_606773 != nil:
    section.add "Action", valid_606773
  var valid_606774 = query.getOrDefault("Version")
  valid_606774 = validateParameter(valid_606774, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606774 != nil:
    section.add "Version", valid_606774
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
  var valid_606775 = header.getOrDefault("X-Amz-Signature")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "X-Amz-Signature", valid_606775
  var valid_606776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606776 = validateParameter(valid_606776, JString, required = false,
                                 default = nil)
  if valid_606776 != nil:
    section.add "X-Amz-Content-Sha256", valid_606776
  var valid_606777 = header.getOrDefault("X-Amz-Date")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-Date", valid_606777
  var valid_606778 = header.getOrDefault("X-Amz-Credential")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-Credential", valid_606778
  var valid_606779 = header.getOrDefault("X-Amz-Security-Token")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Security-Token", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Algorithm")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Algorithm", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-SignedHeaders", valid_606781
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
  var valid_606782 = formData.getOrDefault("Names")
  valid_606782 = validateParameter(valid_606782, JArray, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "Names", valid_606782
  var valid_606783 = formData.getOrDefault("Marker")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "Marker", valid_606783
  var valid_606784 = formData.getOrDefault("PageSize")
  valid_606784 = validateParameter(valid_606784, JInt, required = false, default = nil)
  if valid_606784 != nil:
    section.add "PageSize", valid_606784
  var valid_606785 = formData.getOrDefault("LoadBalancerArns")
  valid_606785 = validateParameter(valid_606785, JArray, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "LoadBalancerArns", valid_606785
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606786: Call_PostDescribeLoadBalancers_606770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_606786.validator(path, query, header, formData, body)
  let scheme = call_606786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606786.url(scheme.get, call_606786.host, call_606786.base,
                         call_606786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606786, url, valid)

proc call*(call_606787: Call_PostDescribeLoadBalancers_606770;
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
  var query_606788 = newJObject()
  var formData_606789 = newJObject()
  if Names != nil:
    formData_606789.add "Names", Names
  add(formData_606789, "Marker", newJString(Marker))
  add(query_606788, "Action", newJString(Action))
  add(formData_606789, "PageSize", newJInt(PageSize))
  add(query_606788, "Version", newJString(Version))
  if LoadBalancerArns != nil:
    formData_606789.add "LoadBalancerArns", LoadBalancerArns
  result = call_606787.call(nil, query_606788, nil, formData_606789, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_606770(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_606771, base: "/",
    url: url_PostDescribeLoadBalancers_606772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_606751 = ref object of OpenApiRestCall_605589
proc url_GetDescribeLoadBalancers_606753(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancers_606752(path: JsonNode; query: JsonNode;
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
  var valid_606754 = query.getOrDefault("Marker")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "Marker", valid_606754
  var valid_606755 = query.getOrDefault("PageSize")
  valid_606755 = validateParameter(valid_606755, JInt, required = false, default = nil)
  if valid_606755 != nil:
    section.add "PageSize", valid_606755
  var valid_606756 = query.getOrDefault("LoadBalancerArns")
  valid_606756 = validateParameter(valid_606756, JArray, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "LoadBalancerArns", valid_606756
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606757 = query.getOrDefault("Action")
  valid_606757 = validateParameter(valid_606757, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_606757 != nil:
    section.add "Action", valid_606757
  var valid_606758 = query.getOrDefault("Version")
  valid_606758 = validateParameter(valid_606758, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606758 != nil:
    section.add "Version", valid_606758
  var valid_606759 = query.getOrDefault("Names")
  valid_606759 = validateParameter(valid_606759, JArray, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "Names", valid_606759
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
  var valid_606760 = header.getOrDefault("X-Amz-Signature")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Signature", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-Content-Sha256", valid_606761
  var valid_606762 = header.getOrDefault("X-Amz-Date")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-Date", valid_606762
  var valid_606763 = header.getOrDefault("X-Amz-Credential")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Credential", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Security-Token")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Security-Token", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Algorithm")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Algorithm", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-SignedHeaders", valid_606766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606767: Call_GetDescribeLoadBalancers_606751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_606767.validator(path, query, header, formData, body)
  let scheme = call_606767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606767.url(scheme.get, call_606767.host, call_606767.base,
                         call_606767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606767, url, valid)

proc call*(call_606768: Call_GetDescribeLoadBalancers_606751; Marker: string = "";
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
  var query_606769 = newJObject()
  add(query_606769, "Marker", newJString(Marker))
  add(query_606769, "PageSize", newJInt(PageSize))
  if LoadBalancerArns != nil:
    query_606769.add "LoadBalancerArns", LoadBalancerArns
  add(query_606769, "Action", newJString(Action))
  add(query_606769, "Version", newJString(Version))
  if Names != nil:
    query_606769.add "Names", Names
  result = call_606768.call(nil, query_606769, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_606751(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_606752, base: "/",
    url: url_GetDescribeLoadBalancers_606753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRules_606809 = ref object of OpenApiRestCall_605589
proc url_PostDescribeRules_606811(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeRules_606810(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606812 = query.getOrDefault("Action")
  valid_606812 = validateParameter(valid_606812, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_606812 != nil:
    section.add "Action", valid_606812
  var valid_606813 = query.getOrDefault("Version")
  valid_606813 = validateParameter(valid_606813, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606813 != nil:
    section.add "Version", valid_606813
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
  var valid_606814 = header.getOrDefault("X-Amz-Signature")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Signature", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Content-Sha256", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-Date")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-Date", valid_606816
  var valid_606817 = header.getOrDefault("X-Amz-Credential")
  valid_606817 = validateParameter(valid_606817, JString, required = false,
                                 default = nil)
  if valid_606817 != nil:
    section.add "X-Amz-Credential", valid_606817
  var valid_606818 = header.getOrDefault("X-Amz-Security-Token")
  valid_606818 = validateParameter(valid_606818, JString, required = false,
                                 default = nil)
  if valid_606818 != nil:
    section.add "X-Amz-Security-Token", valid_606818
  var valid_606819 = header.getOrDefault("X-Amz-Algorithm")
  valid_606819 = validateParameter(valid_606819, JString, required = false,
                                 default = nil)
  if valid_606819 != nil:
    section.add "X-Amz-Algorithm", valid_606819
  var valid_606820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606820 = validateParameter(valid_606820, JString, required = false,
                                 default = nil)
  if valid_606820 != nil:
    section.add "X-Amz-SignedHeaders", valid_606820
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
  var valid_606821 = formData.getOrDefault("ListenerArn")
  valid_606821 = validateParameter(valid_606821, JString, required = false,
                                 default = nil)
  if valid_606821 != nil:
    section.add "ListenerArn", valid_606821
  var valid_606822 = formData.getOrDefault("Marker")
  valid_606822 = validateParameter(valid_606822, JString, required = false,
                                 default = nil)
  if valid_606822 != nil:
    section.add "Marker", valid_606822
  var valid_606823 = formData.getOrDefault("RuleArns")
  valid_606823 = validateParameter(valid_606823, JArray, required = false,
                                 default = nil)
  if valid_606823 != nil:
    section.add "RuleArns", valid_606823
  var valid_606824 = formData.getOrDefault("PageSize")
  valid_606824 = validateParameter(valid_606824, JInt, required = false, default = nil)
  if valid_606824 != nil:
    section.add "PageSize", valid_606824
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606825: Call_PostDescribeRules_606809; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_606825.validator(path, query, header, formData, body)
  let scheme = call_606825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606825.url(scheme.get, call_606825.host, call_606825.base,
                         call_606825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606825, url, valid)

proc call*(call_606826: Call_PostDescribeRules_606809; ListenerArn: string = "";
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
  var query_606827 = newJObject()
  var formData_606828 = newJObject()
  add(formData_606828, "ListenerArn", newJString(ListenerArn))
  add(formData_606828, "Marker", newJString(Marker))
  if RuleArns != nil:
    formData_606828.add "RuleArns", RuleArns
  add(query_606827, "Action", newJString(Action))
  add(formData_606828, "PageSize", newJInt(PageSize))
  add(query_606827, "Version", newJString(Version))
  result = call_606826.call(nil, query_606827, nil, formData_606828, nil)

var postDescribeRules* = Call_PostDescribeRules_606809(name: "postDescribeRules",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_PostDescribeRules_606810,
    base: "/", url: url_PostDescribeRules_606811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRules_606790 = ref object of OpenApiRestCall_605589
proc url_GetDescribeRules_606792(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeRules_606791(path: JsonNode; query: JsonNode;
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
  var valid_606793 = query.getOrDefault("Marker")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "Marker", valid_606793
  var valid_606794 = query.getOrDefault("ListenerArn")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "ListenerArn", valid_606794
  var valid_606795 = query.getOrDefault("PageSize")
  valid_606795 = validateParameter(valid_606795, JInt, required = false, default = nil)
  if valid_606795 != nil:
    section.add "PageSize", valid_606795
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606796 = query.getOrDefault("Action")
  valid_606796 = validateParameter(valid_606796, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_606796 != nil:
    section.add "Action", valid_606796
  var valid_606797 = query.getOrDefault("Version")
  valid_606797 = validateParameter(valid_606797, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606797 != nil:
    section.add "Version", valid_606797
  var valid_606798 = query.getOrDefault("RuleArns")
  valid_606798 = validateParameter(valid_606798, JArray, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "RuleArns", valid_606798
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
  var valid_606799 = header.getOrDefault("X-Amz-Signature")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-Signature", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Content-Sha256", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-Date")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-Date", valid_606801
  var valid_606802 = header.getOrDefault("X-Amz-Credential")
  valid_606802 = validateParameter(valid_606802, JString, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "X-Amz-Credential", valid_606802
  var valid_606803 = header.getOrDefault("X-Amz-Security-Token")
  valid_606803 = validateParameter(valid_606803, JString, required = false,
                                 default = nil)
  if valid_606803 != nil:
    section.add "X-Amz-Security-Token", valid_606803
  var valid_606804 = header.getOrDefault("X-Amz-Algorithm")
  valid_606804 = validateParameter(valid_606804, JString, required = false,
                                 default = nil)
  if valid_606804 != nil:
    section.add "X-Amz-Algorithm", valid_606804
  var valid_606805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606805 = validateParameter(valid_606805, JString, required = false,
                                 default = nil)
  if valid_606805 != nil:
    section.add "X-Amz-SignedHeaders", valid_606805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606806: Call_GetDescribeRules_606790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_606806.validator(path, query, header, formData, body)
  let scheme = call_606806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606806.url(scheme.get, call_606806.host, call_606806.base,
                         call_606806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606806, url, valid)

proc call*(call_606807: Call_GetDescribeRules_606790; Marker: string = "";
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
  var query_606808 = newJObject()
  add(query_606808, "Marker", newJString(Marker))
  add(query_606808, "ListenerArn", newJString(ListenerArn))
  add(query_606808, "PageSize", newJInt(PageSize))
  add(query_606808, "Action", newJString(Action))
  add(query_606808, "Version", newJString(Version))
  if RuleArns != nil:
    query_606808.add "RuleArns", RuleArns
  result = call_606807.call(nil, query_606808, nil, nil, nil)

var getDescribeRules* = Call_GetDescribeRules_606790(name: "getDescribeRules",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_GetDescribeRules_606791,
    base: "/", url: url_GetDescribeRules_606792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSSLPolicies_606847 = ref object of OpenApiRestCall_605589
proc url_PostDescribeSSLPolicies_606849(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeSSLPolicies_606848(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606850 = query.getOrDefault("Action")
  valid_606850 = validateParameter(valid_606850, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_606850 != nil:
    section.add "Action", valid_606850
  var valid_606851 = query.getOrDefault("Version")
  valid_606851 = validateParameter(valid_606851, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606851 != nil:
    section.add "Version", valid_606851
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
  var valid_606852 = header.getOrDefault("X-Amz-Signature")
  valid_606852 = validateParameter(valid_606852, JString, required = false,
                                 default = nil)
  if valid_606852 != nil:
    section.add "X-Amz-Signature", valid_606852
  var valid_606853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606853 = validateParameter(valid_606853, JString, required = false,
                                 default = nil)
  if valid_606853 != nil:
    section.add "X-Amz-Content-Sha256", valid_606853
  var valid_606854 = header.getOrDefault("X-Amz-Date")
  valid_606854 = validateParameter(valid_606854, JString, required = false,
                                 default = nil)
  if valid_606854 != nil:
    section.add "X-Amz-Date", valid_606854
  var valid_606855 = header.getOrDefault("X-Amz-Credential")
  valid_606855 = validateParameter(valid_606855, JString, required = false,
                                 default = nil)
  if valid_606855 != nil:
    section.add "X-Amz-Credential", valid_606855
  var valid_606856 = header.getOrDefault("X-Amz-Security-Token")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Security-Token", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Algorithm")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Algorithm", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-SignedHeaders", valid_606858
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the policies.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_606859 = formData.getOrDefault("Names")
  valid_606859 = validateParameter(valid_606859, JArray, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "Names", valid_606859
  var valid_606860 = formData.getOrDefault("Marker")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "Marker", valid_606860
  var valid_606861 = formData.getOrDefault("PageSize")
  valid_606861 = validateParameter(valid_606861, JInt, required = false, default = nil)
  if valid_606861 != nil:
    section.add "PageSize", valid_606861
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606862: Call_PostDescribeSSLPolicies_606847; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606862.validator(path, query, header, formData, body)
  let scheme = call_606862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606862.url(scheme.get, call_606862.host, call_606862.base,
                         call_606862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606862, url, valid)

proc call*(call_606863: Call_PostDescribeSSLPolicies_606847; Names: JsonNode = nil;
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
  var query_606864 = newJObject()
  var formData_606865 = newJObject()
  if Names != nil:
    formData_606865.add "Names", Names
  add(formData_606865, "Marker", newJString(Marker))
  add(query_606864, "Action", newJString(Action))
  add(formData_606865, "PageSize", newJInt(PageSize))
  add(query_606864, "Version", newJString(Version))
  result = call_606863.call(nil, query_606864, nil, formData_606865, nil)

var postDescribeSSLPolicies* = Call_PostDescribeSSLPolicies_606847(
    name: "postDescribeSSLPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_PostDescribeSSLPolicies_606848, base: "/",
    url: url_PostDescribeSSLPolicies_606849, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSSLPolicies_606829 = ref object of OpenApiRestCall_605589
proc url_GetDescribeSSLPolicies_606831(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeSSLPolicies_606830(path: JsonNode; query: JsonNode;
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
  var valid_606832 = query.getOrDefault("Marker")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "Marker", valid_606832
  var valid_606833 = query.getOrDefault("PageSize")
  valid_606833 = validateParameter(valid_606833, JInt, required = false, default = nil)
  if valid_606833 != nil:
    section.add "PageSize", valid_606833
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606834 = query.getOrDefault("Action")
  valid_606834 = validateParameter(valid_606834, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_606834 != nil:
    section.add "Action", valid_606834
  var valid_606835 = query.getOrDefault("Version")
  valid_606835 = validateParameter(valid_606835, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606835 != nil:
    section.add "Version", valid_606835
  var valid_606836 = query.getOrDefault("Names")
  valid_606836 = validateParameter(valid_606836, JArray, required = false,
                                 default = nil)
  if valid_606836 != nil:
    section.add "Names", valid_606836
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
  var valid_606837 = header.getOrDefault("X-Amz-Signature")
  valid_606837 = validateParameter(valid_606837, JString, required = false,
                                 default = nil)
  if valid_606837 != nil:
    section.add "X-Amz-Signature", valid_606837
  var valid_606838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606838 = validateParameter(valid_606838, JString, required = false,
                                 default = nil)
  if valid_606838 != nil:
    section.add "X-Amz-Content-Sha256", valid_606838
  var valid_606839 = header.getOrDefault("X-Amz-Date")
  valid_606839 = validateParameter(valid_606839, JString, required = false,
                                 default = nil)
  if valid_606839 != nil:
    section.add "X-Amz-Date", valid_606839
  var valid_606840 = header.getOrDefault("X-Amz-Credential")
  valid_606840 = validateParameter(valid_606840, JString, required = false,
                                 default = nil)
  if valid_606840 != nil:
    section.add "X-Amz-Credential", valid_606840
  var valid_606841 = header.getOrDefault("X-Amz-Security-Token")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = nil)
  if valid_606841 != nil:
    section.add "X-Amz-Security-Token", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Algorithm")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Algorithm", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-SignedHeaders", valid_606843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606844: Call_GetDescribeSSLPolicies_606829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606844.validator(path, query, header, formData, body)
  let scheme = call_606844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606844.url(scheme.get, call_606844.host, call_606844.base,
                         call_606844.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606844, url, valid)

proc call*(call_606845: Call_GetDescribeSSLPolicies_606829; Marker: string = "";
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
  var query_606846 = newJObject()
  add(query_606846, "Marker", newJString(Marker))
  add(query_606846, "PageSize", newJInt(PageSize))
  add(query_606846, "Action", newJString(Action))
  add(query_606846, "Version", newJString(Version))
  if Names != nil:
    query_606846.add "Names", Names
  result = call_606845.call(nil, query_606846, nil, nil, nil)

var getDescribeSSLPolicies* = Call_GetDescribeSSLPolicies_606829(
    name: "getDescribeSSLPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_GetDescribeSSLPolicies_606830, base: "/",
    url: url_GetDescribeSSLPolicies_606831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_606882 = ref object of OpenApiRestCall_605589
proc url_PostDescribeTags_606884(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeTags_606883(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606885 = query.getOrDefault("Action")
  valid_606885 = validateParameter(valid_606885, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_606885 != nil:
    section.add "Action", valid_606885
  var valid_606886 = query.getOrDefault("Version")
  valid_606886 = validateParameter(valid_606886, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606886 != nil:
    section.add "Version", valid_606886
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
  var valid_606887 = header.getOrDefault("X-Amz-Signature")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-Signature", valid_606887
  var valid_606888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606888 = validateParameter(valid_606888, JString, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "X-Amz-Content-Sha256", valid_606888
  var valid_606889 = header.getOrDefault("X-Amz-Date")
  valid_606889 = validateParameter(valid_606889, JString, required = false,
                                 default = nil)
  if valid_606889 != nil:
    section.add "X-Amz-Date", valid_606889
  var valid_606890 = header.getOrDefault("X-Amz-Credential")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Credential", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-Security-Token")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-Security-Token", valid_606891
  var valid_606892 = header.getOrDefault("X-Amz-Algorithm")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "X-Amz-Algorithm", valid_606892
  var valid_606893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606893 = validateParameter(valid_606893, JString, required = false,
                                 default = nil)
  if valid_606893 != nil:
    section.add "X-Amz-SignedHeaders", valid_606893
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_606894 = formData.getOrDefault("ResourceArns")
  valid_606894 = validateParameter(valid_606894, JArray, required = true, default = nil)
  if valid_606894 != nil:
    section.add "ResourceArns", valid_606894
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606895: Call_PostDescribeTags_606882; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_606895.validator(path, query, header, formData, body)
  let scheme = call_606895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606895.url(scheme.get, call_606895.host, call_606895.base,
                         call_606895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606895, url, valid)

proc call*(call_606896: Call_PostDescribeTags_606882; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606897 = newJObject()
  var formData_606898 = newJObject()
  if ResourceArns != nil:
    formData_606898.add "ResourceArns", ResourceArns
  add(query_606897, "Action", newJString(Action))
  add(query_606897, "Version", newJString(Version))
  result = call_606896.call(nil, query_606897, nil, formData_606898, nil)

var postDescribeTags* = Call_PostDescribeTags_606882(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_606883,
    base: "/", url: url_PostDescribeTags_606884,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_606866 = ref object of OpenApiRestCall_605589
proc url_GetDescribeTags_606868(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeTags_606867(path: JsonNode; query: JsonNode;
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
  var valid_606869 = query.getOrDefault("ResourceArns")
  valid_606869 = validateParameter(valid_606869, JArray, required = true, default = nil)
  if valid_606869 != nil:
    section.add "ResourceArns", valid_606869
  var valid_606870 = query.getOrDefault("Action")
  valid_606870 = validateParameter(valid_606870, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_606870 != nil:
    section.add "Action", valid_606870
  var valid_606871 = query.getOrDefault("Version")
  valid_606871 = validateParameter(valid_606871, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606871 != nil:
    section.add "Version", valid_606871
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
  var valid_606872 = header.getOrDefault("X-Amz-Signature")
  valid_606872 = validateParameter(valid_606872, JString, required = false,
                                 default = nil)
  if valid_606872 != nil:
    section.add "X-Amz-Signature", valid_606872
  var valid_606873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-Content-Sha256", valid_606873
  var valid_606874 = header.getOrDefault("X-Amz-Date")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Date", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Credential")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Credential", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Security-Token")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Security-Token", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-Algorithm")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-Algorithm", valid_606877
  var valid_606878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "X-Amz-SignedHeaders", valid_606878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606879: Call_GetDescribeTags_606866; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_606879.validator(path, query, header, formData, body)
  let scheme = call_606879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606879.url(scheme.get, call_606879.host, call_606879.base,
                         call_606879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606879, url, valid)

proc call*(call_606880: Call_GetDescribeTags_606866; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606881 = newJObject()
  if ResourceArns != nil:
    query_606881.add "ResourceArns", ResourceArns
  add(query_606881, "Action", newJString(Action))
  add(query_606881, "Version", newJString(Version))
  result = call_606880.call(nil, query_606881, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_606866(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_606867,
    base: "/", url: url_GetDescribeTags_606868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroupAttributes_606915 = ref object of OpenApiRestCall_605589
proc url_PostDescribeTargetGroupAttributes_606917(protocol: Scheme; host: string;
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

proc validate_PostDescribeTargetGroupAttributes_606916(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606918 = query.getOrDefault("Action")
  valid_606918 = validateParameter(valid_606918, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_606918 != nil:
    section.add "Action", valid_606918
  var valid_606919 = query.getOrDefault("Version")
  valid_606919 = validateParameter(valid_606919, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606919 != nil:
    section.add "Version", valid_606919
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
  var valid_606920 = header.getOrDefault("X-Amz-Signature")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "X-Amz-Signature", valid_606920
  var valid_606921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-Content-Sha256", valid_606921
  var valid_606922 = header.getOrDefault("X-Amz-Date")
  valid_606922 = validateParameter(valid_606922, JString, required = false,
                                 default = nil)
  if valid_606922 != nil:
    section.add "X-Amz-Date", valid_606922
  var valid_606923 = header.getOrDefault("X-Amz-Credential")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "X-Amz-Credential", valid_606923
  var valid_606924 = header.getOrDefault("X-Amz-Security-Token")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "X-Amz-Security-Token", valid_606924
  var valid_606925 = header.getOrDefault("X-Amz-Algorithm")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "X-Amz-Algorithm", valid_606925
  var valid_606926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "X-Amz-SignedHeaders", valid_606926
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_606927 = formData.getOrDefault("TargetGroupArn")
  valid_606927 = validateParameter(valid_606927, JString, required = true,
                                 default = nil)
  if valid_606927 != nil:
    section.add "TargetGroupArn", valid_606927
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606928: Call_PostDescribeTargetGroupAttributes_606915;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606928.validator(path, query, header, formData, body)
  let scheme = call_606928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606928.url(scheme.get, call_606928.host, call_606928.base,
                         call_606928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606928, url, valid)

proc call*(call_606929: Call_PostDescribeTargetGroupAttributes_606915;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_606930 = newJObject()
  var formData_606931 = newJObject()
  add(query_606930, "Action", newJString(Action))
  add(formData_606931, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_606930, "Version", newJString(Version))
  result = call_606929.call(nil, query_606930, nil, formData_606931, nil)

var postDescribeTargetGroupAttributes* = Call_PostDescribeTargetGroupAttributes_606915(
    name: "postDescribeTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_PostDescribeTargetGroupAttributes_606916, base: "/",
    url: url_PostDescribeTargetGroupAttributes_606917,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroupAttributes_606899 = ref object of OpenApiRestCall_605589
proc url_GetDescribeTargetGroupAttributes_606901(protocol: Scheme; host: string;
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

proc validate_GetDescribeTargetGroupAttributes_606900(path: JsonNode;
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
  var valid_606902 = query.getOrDefault("TargetGroupArn")
  valid_606902 = validateParameter(valid_606902, JString, required = true,
                                 default = nil)
  if valid_606902 != nil:
    section.add "TargetGroupArn", valid_606902
  var valid_606903 = query.getOrDefault("Action")
  valid_606903 = validateParameter(valid_606903, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_606903 != nil:
    section.add "Action", valid_606903
  var valid_606904 = query.getOrDefault("Version")
  valid_606904 = validateParameter(valid_606904, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606904 != nil:
    section.add "Version", valid_606904
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
  var valid_606905 = header.getOrDefault("X-Amz-Signature")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "X-Amz-Signature", valid_606905
  var valid_606906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606906 = validateParameter(valid_606906, JString, required = false,
                                 default = nil)
  if valid_606906 != nil:
    section.add "X-Amz-Content-Sha256", valid_606906
  var valid_606907 = header.getOrDefault("X-Amz-Date")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "X-Amz-Date", valid_606907
  var valid_606908 = header.getOrDefault("X-Amz-Credential")
  valid_606908 = validateParameter(valid_606908, JString, required = false,
                                 default = nil)
  if valid_606908 != nil:
    section.add "X-Amz-Credential", valid_606908
  var valid_606909 = header.getOrDefault("X-Amz-Security-Token")
  valid_606909 = validateParameter(valid_606909, JString, required = false,
                                 default = nil)
  if valid_606909 != nil:
    section.add "X-Amz-Security-Token", valid_606909
  var valid_606910 = header.getOrDefault("X-Amz-Algorithm")
  valid_606910 = validateParameter(valid_606910, JString, required = false,
                                 default = nil)
  if valid_606910 != nil:
    section.add "X-Amz-Algorithm", valid_606910
  var valid_606911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606911 = validateParameter(valid_606911, JString, required = false,
                                 default = nil)
  if valid_606911 != nil:
    section.add "X-Amz-SignedHeaders", valid_606911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606912: Call_GetDescribeTargetGroupAttributes_606899;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606912.validator(path, query, header, formData, body)
  let scheme = call_606912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606912.url(scheme.get, call_606912.host, call_606912.base,
                         call_606912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606912, url, valid)

proc call*(call_606913: Call_GetDescribeTargetGroupAttributes_606899;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606914 = newJObject()
  add(query_606914, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_606914, "Action", newJString(Action))
  add(query_606914, "Version", newJString(Version))
  result = call_606913.call(nil, query_606914, nil, nil, nil)

var getDescribeTargetGroupAttributes* = Call_GetDescribeTargetGroupAttributes_606899(
    name: "getDescribeTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_GetDescribeTargetGroupAttributes_606900, base: "/",
    url: url_GetDescribeTargetGroupAttributes_606901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroups_606952 = ref object of OpenApiRestCall_605589
proc url_PostDescribeTargetGroups_606954(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTargetGroups_606953(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606955 = query.getOrDefault("Action")
  valid_606955 = validateParameter(valid_606955, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_606955 != nil:
    section.add "Action", valid_606955
  var valid_606956 = query.getOrDefault("Version")
  valid_606956 = validateParameter(valid_606956, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606956 != nil:
    section.add "Version", valid_606956
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
  var valid_606957 = header.getOrDefault("X-Amz-Signature")
  valid_606957 = validateParameter(valid_606957, JString, required = false,
                                 default = nil)
  if valid_606957 != nil:
    section.add "X-Amz-Signature", valid_606957
  var valid_606958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606958 = validateParameter(valid_606958, JString, required = false,
                                 default = nil)
  if valid_606958 != nil:
    section.add "X-Amz-Content-Sha256", valid_606958
  var valid_606959 = header.getOrDefault("X-Amz-Date")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "X-Amz-Date", valid_606959
  var valid_606960 = header.getOrDefault("X-Amz-Credential")
  valid_606960 = validateParameter(valid_606960, JString, required = false,
                                 default = nil)
  if valid_606960 != nil:
    section.add "X-Amz-Credential", valid_606960
  var valid_606961 = header.getOrDefault("X-Amz-Security-Token")
  valid_606961 = validateParameter(valid_606961, JString, required = false,
                                 default = nil)
  if valid_606961 != nil:
    section.add "X-Amz-Security-Token", valid_606961
  var valid_606962 = header.getOrDefault("X-Amz-Algorithm")
  valid_606962 = validateParameter(valid_606962, JString, required = false,
                                 default = nil)
  if valid_606962 != nil:
    section.add "X-Amz-Algorithm", valid_606962
  var valid_606963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606963 = validateParameter(valid_606963, JString, required = false,
                                 default = nil)
  if valid_606963 != nil:
    section.add "X-Amz-SignedHeaders", valid_606963
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
  var valid_606964 = formData.getOrDefault("Names")
  valid_606964 = validateParameter(valid_606964, JArray, required = false,
                                 default = nil)
  if valid_606964 != nil:
    section.add "Names", valid_606964
  var valid_606965 = formData.getOrDefault("Marker")
  valid_606965 = validateParameter(valid_606965, JString, required = false,
                                 default = nil)
  if valid_606965 != nil:
    section.add "Marker", valid_606965
  var valid_606966 = formData.getOrDefault("TargetGroupArns")
  valid_606966 = validateParameter(valid_606966, JArray, required = false,
                                 default = nil)
  if valid_606966 != nil:
    section.add "TargetGroupArns", valid_606966
  var valid_606967 = formData.getOrDefault("PageSize")
  valid_606967 = validateParameter(valid_606967, JInt, required = false, default = nil)
  if valid_606967 != nil:
    section.add "PageSize", valid_606967
  var valid_606968 = formData.getOrDefault("LoadBalancerArn")
  valid_606968 = validateParameter(valid_606968, JString, required = false,
                                 default = nil)
  if valid_606968 != nil:
    section.add "LoadBalancerArn", valid_606968
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606969: Call_PostDescribeTargetGroups_606952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_606969.validator(path, query, header, formData, body)
  let scheme = call_606969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606969.url(scheme.get, call_606969.host, call_606969.base,
                         call_606969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606969, url, valid)

proc call*(call_606970: Call_PostDescribeTargetGroups_606952;
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
  var query_606971 = newJObject()
  var formData_606972 = newJObject()
  if Names != nil:
    formData_606972.add "Names", Names
  add(formData_606972, "Marker", newJString(Marker))
  add(query_606971, "Action", newJString(Action))
  if TargetGroupArns != nil:
    formData_606972.add "TargetGroupArns", TargetGroupArns
  add(formData_606972, "PageSize", newJInt(PageSize))
  add(query_606971, "Version", newJString(Version))
  add(formData_606972, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_606970.call(nil, query_606971, nil, formData_606972, nil)

var postDescribeTargetGroups* = Call_PostDescribeTargetGroups_606952(
    name: "postDescribeTargetGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_PostDescribeTargetGroups_606953, base: "/",
    url: url_PostDescribeTargetGroups_606954, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroups_606932 = ref object of OpenApiRestCall_605589
proc url_GetDescribeTargetGroups_606934(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTargetGroups_606933(path: JsonNode; query: JsonNode;
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
  var valid_606935 = query.getOrDefault("Marker")
  valid_606935 = validateParameter(valid_606935, JString, required = false,
                                 default = nil)
  if valid_606935 != nil:
    section.add "Marker", valid_606935
  var valid_606936 = query.getOrDefault("LoadBalancerArn")
  valid_606936 = validateParameter(valid_606936, JString, required = false,
                                 default = nil)
  if valid_606936 != nil:
    section.add "LoadBalancerArn", valid_606936
  var valid_606937 = query.getOrDefault("PageSize")
  valid_606937 = validateParameter(valid_606937, JInt, required = false, default = nil)
  if valid_606937 != nil:
    section.add "PageSize", valid_606937
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606938 = query.getOrDefault("Action")
  valid_606938 = validateParameter(valid_606938, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_606938 != nil:
    section.add "Action", valid_606938
  var valid_606939 = query.getOrDefault("TargetGroupArns")
  valid_606939 = validateParameter(valid_606939, JArray, required = false,
                                 default = nil)
  if valid_606939 != nil:
    section.add "TargetGroupArns", valid_606939
  var valid_606940 = query.getOrDefault("Version")
  valid_606940 = validateParameter(valid_606940, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606940 != nil:
    section.add "Version", valid_606940
  var valid_606941 = query.getOrDefault("Names")
  valid_606941 = validateParameter(valid_606941, JArray, required = false,
                                 default = nil)
  if valid_606941 != nil:
    section.add "Names", valid_606941
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
  var valid_606942 = header.getOrDefault("X-Amz-Signature")
  valid_606942 = validateParameter(valid_606942, JString, required = false,
                                 default = nil)
  if valid_606942 != nil:
    section.add "X-Amz-Signature", valid_606942
  var valid_606943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606943 = validateParameter(valid_606943, JString, required = false,
                                 default = nil)
  if valid_606943 != nil:
    section.add "X-Amz-Content-Sha256", valid_606943
  var valid_606944 = header.getOrDefault("X-Amz-Date")
  valid_606944 = validateParameter(valid_606944, JString, required = false,
                                 default = nil)
  if valid_606944 != nil:
    section.add "X-Amz-Date", valid_606944
  var valid_606945 = header.getOrDefault("X-Amz-Credential")
  valid_606945 = validateParameter(valid_606945, JString, required = false,
                                 default = nil)
  if valid_606945 != nil:
    section.add "X-Amz-Credential", valid_606945
  var valid_606946 = header.getOrDefault("X-Amz-Security-Token")
  valid_606946 = validateParameter(valid_606946, JString, required = false,
                                 default = nil)
  if valid_606946 != nil:
    section.add "X-Amz-Security-Token", valid_606946
  var valid_606947 = header.getOrDefault("X-Amz-Algorithm")
  valid_606947 = validateParameter(valid_606947, JString, required = false,
                                 default = nil)
  if valid_606947 != nil:
    section.add "X-Amz-Algorithm", valid_606947
  var valid_606948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606948 = validateParameter(valid_606948, JString, required = false,
                                 default = nil)
  if valid_606948 != nil:
    section.add "X-Amz-SignedHeaders", valid_606948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606949: Call_GetDescribeTargetGroups_606932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_606949.validator(path, query, header, formData, body)
  let scheme = call_606949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606949.url(scheme.get, call_606949.host, call_606949.base,
                         call_606949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606949, url, valid)

proc call*(call_606950: Call_GetDescribeTargetGroups_606932; Marker: string = "";
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
  var query_606951 = newJObject()
  add(query_606951, "Marker", newJString(Marker))
  add(query_606951, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_606951, "PageSize", newJInt(PageSize))
  add(query_606951, "Action", newJString(Action))
  if TargetGroupArns != nil:
    query_606951.add "TargetGroupArns", TargetGroupArns
  add(query_606951, "Version", newJString(Version))
  if Names != nil:
    query_606951.add "Names", Names
  result = call_606950.call(nil, query_606951, nil, nil, nil)

var getDescribeTargetGroups* = Call_GetDescribeTargetGroups_606932(
    name: "getDescribeTargetGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_GetDescribeTargetGroups_606933, base: "/",
    url: url_GetDescribeTargetGroups_606934, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetHealth_606990 = ref object of OpenApiRestCall_605589
proc url_PostDescribeTargetHealth_606992(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTargetHealth_606991(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606993 = query.getOrDefault("Action")
  valid_606993 = validateParameter(valid_606993, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_606993 != nil:
    section.add "Action", valid_606993
  var valid_606994 = query.getOrDefault("Version")
  valid_606994 = validateParameter(valid_606994, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606994 != nil:
    section.add "Version", valid_606994
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
  var valid_606995 = header.getOrDefault("X-Amz-Signature")
  valid_606995 = validateParameter(valid_606995, JString, required = false,
                                 default = nil)
  if valid_606995 != nil:
    section.add "X-Amz-Signature", valid_606995
  var valid_606996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606996 = validateParameter(valid_606996, JString, required = false,
                                 default = nil)
  if valid_606996 != nil:
    section.add "X-Amz-Content-Sha256", valid_606996
  var valid_606997 = header.getOrDefault("X-Amz-Date")
  valid_606997 = validateParameter(valid_606997, JString, required = false,
                                 default = nil)
  if valid_606997 != nil:
    section.add "X-Amz-Date", valid_606997
  var valid_606998 = header.getOrDefault("X-Amz-Credential")
  valid_606998 = validateParameter(valid_606998, JString, required = false,
                                 default = nil)
  if valid_606998 != nil:
    section.add "X-Amz-Credential", valid_606998
  var valid_606999 = header.getOrDefault("X-Amz-Security-Token")
  valid_606999 = validateParameter(valid_606999, JString, required = false,
                                 default = nil)
  if valid_606999 != nil:
    section.add "X-Amz-Security-Token", valid_606999
  var valid_607000 = header.getOrDefault("X-Amz-Algorithm")
  valid_607000 = validateParameter(valid_607000, JString, required = false,
                                 default = nil)
  if valid_607000 != nil:
    section.add "X-Amz-Algorithm", valid_607000
  var valid_607001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607001 = validateParameter(valid_607001, JString, required = false,
                                 default = nil)
  if valid_607001 != nil:
    section.add "X-Amz-SignedHeaders", valid_607001
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_607002 = formData.getOrDefault("Targets")
  valid_607002 = validateParameter(valid_607002, JArray, required = false,
                                 default = nil)
  if valid_607002 != nil:
    section.add "Targets", valid_607002
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_607003 = formData.getOrDefault("TargetGroupArn")
  valid_607003 = validateParameter(valid_607003, JString, required = true,
                                 default = nil)
  if valid_607003 != nil:
    section.add "TargetGroupArn", valid_607003
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607004: Call_PostDescribeTargetHealth_606990; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_607004.validator(path, query, header, formData, body)
  let scheme = call_607004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607004.url(scheme.get, call_607004.host, call_607004.base,
                         call_607004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607004, url, valid)

proc call*(call_607005: Call_PostDescribeTargetHealth_606990;
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
  var query_607006 = newJObject()
  var formData_607007 = newJObject()
  if Targets != nil:
    formData_607007.add "Targets", Targets
  add(query_607006, "Action", newJString(Action))
  add(formData_607007, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_607006, "Version", newJString(Version))
  result = call_607005.call(nil, query_607006, nil, formData_607007, nil)

var postDescribeTargetHealth* = Call_PostDescribeTargetHealth_606990(
    name: "postDescribeTargetHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_PostDescribeTargetHealth_606991, base: "/",
    url: url_PostDescribeTargetHealth_606992, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetHealth_606973 = ref object of OpenApiRestCall_605589
proc url_GetDescribeTargetHealth_606975(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTargetHealth_606974(path: JsonNode; query: JsonNode;
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
  var valid_606976 = query.getOrDefault("Targets")
  valid_606976 = validateParameter(valid_606976, JArray, required = false,
                                 default = nil)
  if valid_606976 != nil:
    section.add "Targets", valid_606976
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_606977 = query.getOrDefault("TargetGroupArn")
  valid_606977 = validateParameter(valid_606977, JString, required = true,
                                 default = nil)
  if valid_606977 != nil:
    section.add "TargetGroupArn", valid_606977
  var valid_606978 = query.getOrDefault("Action")
  valid_606978 = validateParameter(valid_606978, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_606978 != nil:
    section.add "Action", valid_606978
  var valid_606979 = query.getOrDefault("Version")
  valid_606979 = validateParameter(valid_606979, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_606979 != nil:
    section.add "Version", valid_606979
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
  var valid_606980 = header.getOrDefault("X-Amz-Signature")
  valid_606980 = validateParameter(valid_606980, JString, required = false,
                                 default = nil)
  if valid_606980 != nil:
    section.add "X-Amz-Signature", valid_606980
  var valid_606981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606981 = validateParameter(valid_606981, JString, required = false,
                                 default = nil)
  if valid_606981 != nil:
    section.add "X-Amz-Content-Sha256", valid_606981
  var valid_606982 = header.getOrDefault("X-Amz-Date")
  valid_606982 = validateParameter(valid_606982, JString, required = false,
                                 default = nil)
  if valid_606982 != nil:
    section.add "X-Amz-Date", valid_606982
  var valid_606983 = header.getOrDefault("X-Amz-Credential")
  valid_606983 = validateParameter(valid_606983, JString, required = false,
                                 default = nil)
  if valid_606983 != nil:
    section.add "X-Amz-Credential", valid_606983
  var valid_606984 = header.getOrDefault("X-Amz-Security-Token")
  valid_606984 = validateParameter(valid_606984, JString, required = false,
                                 default = nil)
  if valid_606984 != nil:
    section.add "X-Amz-Security-Token", valid_606984
  var valid_606985 = header.getOrDefault("X-Amz-Algorithm")
  valid_606985 = validateParameter(valid_606985, JString, required = false,
                                 default = nil)
  if valid_606985 != nil:
    section.add "X-Amz-Algorithm", valid_606985
  var valid_606986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606986 = validateParameter(valid_606986, JString, required = false,
                                 default = nil)
  if valid_606986 != nil:
    section.add "X-Amz-SignedHeaders", valid_606986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606987: Call_GetDescribeTargetHealth_606973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_606987.validator(path, query, header, formData, body)
  let scheme = call_606987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606987.url(scheme.get, call_606987.host, call_606987.base,
                         call_606987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606987, url, valid)

proc call*(call_606988: Call_GetDescribeTargetHealth_606973;
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
  var query_606989 = newJObject()
  if Targets != nil:
    query_606989.add "Targets", Targets
  add(query_606989, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_606989, "Action", newJString(Action))
  add(query_606989, "Version", newJString(Version))
  result = call_606988.call(nil, query_606989, nil, nil, nil)

var getDescribeTargetHealth* = Call_GetDescribeTargetHealth_606973(
    name: "getDescribeTargetHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_GetDescribeTargetHealth_606974, base: "/",
    url: url_GetDescribeTargetHealth_606975, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyListener_607029 = ref object of OpenApiRestCall_605589
proc url_PostModifyListener_607031(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyListener_607030(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607032 = query.getOrDefault("Action")
  valid_607032 = validateParameter(valid_607032, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_607032 != nil:
    section.add "Action", valid_607032
  var valid_607033 = query.getOrDefault("Version")
  valid_607033 = validateParameter(valid_607033, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607033 != nil:
    section.add "Version", valid_607033
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
  var valid_607034 = header.getOrDefault("X-Amz-Signature")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-Signature", valid_607034
  var valid_607035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607035 = validateParameter(valid_607035, JString, required = false,
                                 default = nil)
  if valid_607035 != nil:
    section.add "X-Amz-Content-Sha256", valid_607035
  var valid_607036 = header.getOrDefault("X-Amz-Date")
  valid_607036 = validateParameter(valid_607036, JString, required = false,
                                 default = nil)
  if valid_607036 != nil:
    section.add "X-Amz-Date", valid_607036
  var valid_607037 = header.getOrDefault("X-Amz-Credential")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "X-Amz-Credential", valid_607037
  var valid_607038 = header.getOrDefault("X-Amz-Security-Token")
  valid_607038 = validateParameter(valid_607038, JString, required = false,
                                 default = nil)
  if valid_607038 != nil:
    section.add "X-Amz-Security-Token", valid_607038
  var valid_607039 = header.getOrDefault("X-Amz-Algorithm")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "X-Amz-Algorithm", valid_607039
  var valid_607040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607040 = validateParameter(valid_607040, JString, required = false,
                                 default = nil)
  if valid_607040 != nil:
    section.add "X-Amz-SignedHeaders", valid_607040
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
  var valid_607041 = formData.getOrDefault("Port")
  valid_607041 = validateParameter(valid_607041, JInt, required = false, default = nil)
  if valid_607041 != nil:
    section.add "Port", valid_607041
  var valid_607042 = formData.getOrDefault("Certificates")
  valid_607042 = validateParameter(valid_607042, JArray, required = false,
                                 default = nil)
  if valid_607042 != nil:
    section.add "Certificates", valid_607042
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_607043 = formData.getOrDefault("ListenerArn")
  valid_607043 = validateParameter(valid_607043, JString, required = true,
                                 default = nil)
  if valid_607043 != nil:
    section.add "ListenerArn", valid_607043
  var valid_607044 = formData.getOrDefault("DefaultActions")
  valid_607044 = validateParameter(valid_607044, JArray, required = false,
                                 default = nil)
  if valid_607044 != nil:
    section.add "DefaultActions", valid_607044
  var valid_607045 = formData.getOrDefault("Protocol")
  valid_607045 = validateParameter(valid_607045, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_607045 != nil:
    section.add "Protocol", valid_607045
  var valid_607046 = formData.getOrDefault("SslPolicy")
  valid_607046 = validateParameter(valid_607046, JString, required = false,
                                 default = nil)
  if valid_607046 != nil:
    section.add "SslPolicy", valid_607046
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607047: Call_PostModifyListener_607029; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ## 
  let valid = call_607047.validator(path, query, header, formData, body)
  let scheme = call_607047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607047.url(scheme.get, call_607047.host, call_607047.base,
                         call_607047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607047, url, valid)

proc call*(call_607048: Call_PostModifyListener_607029; ListenerArn: string;
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
  var query_607049 = newJObject()
  var formData_607050 = newJObject()
  add(formData_607050, "Port", newJInt(Port))
  if Certificates != nil:
    formData_607050.add "Certificates", Certificates
  add(formData_607050, "ListenerArn", newJString(ListenerArn))
  if DefaultActions != nil:
    formData_607050.add "DefaultActions", DefaultActions
  add(formData_607050, "Protocol", newJString(Protocol))
  add(query_607049, "Action", newJString(Action))
  add(formData_607050, "SslPolicy", newJString(SslPolicy))
  add(query_607049, "Version", newJString(Version))
  result = call_607048.call(nil, query_607049, nil, formData_607050, nil)

var postModifyListener* = Call_PostModifyListener_607029(
    name: "postModifyListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=ModifyListener",
    validator: validate_PostModifyListener_607030, base: "/",
    url: url_PostModifyListener_607031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyListener_607008 = ref object of OpenApiRestCall_605589
proc url_GetModifyListener_607010(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyListener_607009(path: JsonNode; query: JsonNode;
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
  var valid_607011 = query.getOrDefault("SslPolicy")
  valid_607011 = validateParameter(valid_607011, JString, required = false,
                                 default = nil)
  if valid_607011 != nil:
    section.add "SslPolicy", valid_607011
  assert query != nil,
        "query argument is necessary due to required `ListenerArn` field"
  var valid_607012 = query.getOrDefault("ListenerArn")
  valid_607012 = validateParameter(valid_607012, JString, required = true,
                                 default = nil)
  if valid_607012 != nil:
    section.add "ListenerArn", valid_607012
  var valid_607013 = query.getOrDefault("Certificates")
  valid_607013 = validateParameter(valid_607013, JArray, required = false,
                                 default = nil)
  if valid_607013 != nil:
    section.add "Certificates", valid_607013
  var valid_607014 = query.getOrDefault("DefaultActions")
  valid_607014 = validateParameter(valid_607014, JArray, required = false,
                                 default = nil)
  if valid_607014 != nil:
    section.add "DefaultActions", valid_607014
  var valid_607015 = query.getOrDefault("Action")
  valid_607015 = validateParameter(valid_607015, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_607015 != nil:
    section.add "Action", valid_607015
  var valid_607016 = query.getOrDefault("Port")
  valid_607016 = validateParameter(valid_607016, JInt, required = false, default = nil)
  if valid_607016 != nil:
    section.add "Port", valid_607016
  var valid_607017 = query.getOrDefault("Protocol")
  valid_607017 = validateParameter(valid_607017, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_607017 != nil:
    section.add "Protocol", valid_607017
  var valid_607018 = query.getOrDefault("Version")
  valid_607018 = validateParameter(valid_607018, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607018 != nil:
    section.add "Version", valid_607018
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
  var valid_607019 = header.getOrDefault("X-Amz-Signature")
  valid_607019 = validateParameter(valid_607019, JString, required = false,
                                 default = nil)
  if valid_607019 != nil:
    section.add "X-Amz-Signature", valid_607019
  var valid_607020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "X-Amz-Content-Sha256", valid_607020
  var valid_607021 = header.getOrDefault("X-Amz-Date")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "X-Amz-Date", valid_607021
  var valid_607022 = header.getOrDefault("X-Amz-Credential")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "X-Amz-Credential", valid_607022
  var valid_607023 = header.getOrDefault("X-Amz-Security-Token")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "X-Amz-Security-Token", valid_607023
  var valid_607024 = header.getOrDefault("X-Amz-Algorithm")
  valid_607024 = validateParameter(valid_607024, JString, required = false,
                                 default = nil)
  if valid_607024 != nil:
    section.add "X-Amz-Algorithm", valid_607024
  var valid_607025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607025 = validateParameter(valid_607025, JString, required = false,
                                 default = nil)
  if valid_607025 != nil:
    section.add "X-Amz-SignedHeaders", valid_607025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607026: Call_GetModifyListener_607008; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ## 
  let valid = call_607026.validator(path, query, header, formData, body)
  let scheme = call_607026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607026.url(scheme.get, call_607026.host, call_607026.base,
                         call_607026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607026, url, valid)

proc call*(call_607027: Call_GetModifyListener_607008; ListenerArn: string;
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
  var query_607028 = newJObject()
  add(query_607028, "SslPolicy", newJString(SslPolicy))
  add(query_607028, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_607028.add "Certificates", Certificates
  if DefaultActions != nil:
    query_607028.add "DefaultActions", DefaultActions
  add(query_607028, "Action", newJString(Action))
  add(query_607028, "Port", newJInt(Port))
  add(query_607028, "Protocol", newJString(Protocol))
  add(query_607028, "Version", newJString(Version))
  result = call_607027.call(nil, query_607028, nil, nil, nil)

var getModifyListener* = Call_GetModifyListener_607008(name: "getModifyListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyListener", validator: validate_GetModifyListener_607009,
    base: "/", url: url_GetModifyListener_607010,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_607068 = ref object of OpenApiRestCall_605589
proc url_PostModifyLoadBalancerAttributes_607070(protocol: Scheme; host: string;
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

proc validate_PostModifyLoadBalancerAttributes_607069(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607071 = query.getOrDefault("Action")
  valid_607071 = validateParameter(valid_607071, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_607071 != nil:
    section.add "Action", valid_607071
  var valid_607072 = query.getOrDefault("Version")
  valid_607072 = validateParameter(valid_607072, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607072 != nil:
    section.add "Version", valid_607072
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
  var valid_607073 = header.getOrDefault("X-Amz-Signature")
  valid_607073 = validateParameter(valid_607073, JString, required = false,
                                 default = nil)
  if valid_607073 != nil:
    section.add "X-Amz-Signature", valid_607073
  var valid_607074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607074 = validateParameter(valid_607074, JString, required = false,
                                 default = nil)
  if valid_607074 != nil:
    section.add "X-Amz-Content-Sha256", valid_607074
  var valid_607075 = header.getOrDefault("X-Amz-Date")
  valid_607075 = validateParameter(valid_607075, JString, required = false,
                                 default = nil)
  if valid_607075 != nil:
    section.add "X-Amz-Date", valid_607075
  var valid_607076 = header.getOrDefault("X-Amz-Credential")
  valid_607076 = validateParameter(valid_607076, JString, required = false,
                                 default = nil)
  if valid_607076 != nil:
    section.add "X-Amz-Credential", valid_607076
  var valid_607077 = header.getOrDefault("X-Amz-Security-Token")
  valid_607077 = validateParameter(valid_607077, JString, required = false,
                                 default = nil)
  if valid_607077 != nil:
    section.add "X-Amz-Security-Token", valid_607077
  var valid_607078 = header.getOrDefault("X-Amz-Algorithm")
  valid_607078 = validateParameter(valid_607078, JString, required = false,
                                 default = nil)
  if valid_607078 != nil:
    section.add "X-Amz-Algorithm", valid_607078
  var valid_607079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607079 = validateParameter(valid_607079, JString, required = false,
                                 default = nil)
  if valid_607079 != nil:
    section.add "X-Amz-SignedHeaders", valid_607079
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_607080 = formData.getOrDefault("Attributes")
  valid_607080 = validateParameter(valid_607080, JArray, required = true, default = nil)
  if valid_607080 != nil:
    section.add "Attributes", valid_607080
  var valid_607081 = formData.getOrDefault("LoadBalancerArn")
  valid_607081 = validateParameter(valid_607081, JString, required = true,
                                 default = nil)
  if valid_607081 != nil:
    section.add "LoadBalancerArn", valid_607081
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607082: Call_PostModifyLoadBalancerAttributes_607068;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_607082.validator(path, query, header, formData, body)
  let scheme = call_607082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607082.url(scheme.get, call_607082.host, call_607082.base,
                         call_607082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607082, url, valid)

proc call*(call_607083: Call_PostModifyLoadBalancerAttributes_607068;
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
  var query_607084 = newJObject()
  var formData_607085 = newJObject()
  if Attributes != nil:
    formData_607085.add "Attributes", Attributes
  add(query_607084, "Action", newJString(Action))
  add(query_607084, "Version", newJString(Version))
  add(formData_607085, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_607083.call(nil, query_607084, nil, formData_607085, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_607068(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_607069, base: "/",
    url: url_PostModifyLoadBalancerAttributes_607070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_607051 = ref object of OpenApiRestCall_605589
proc url_GetModifyLoadBalancerAttributes_607053(protocol: Scheme; host: string;
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

proc validate_GetModifyLoadBalancerAttributes_607052(path: JsonNode;
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
  var valid_607054 = query.getOrDefault("LoadBalancerArn")
  valid_607054 = validateParameter(valid_607054, JString, required = true,
                                 default = nil)
  if valid_607054 != nil:
    section.add "LoadBalancerArn", valid_607054
  var valid_607055 = query.getOrDefault("Attributes")
  valid_607055 = validateParameter(valid_607055, JArray, required = true, default = nil)
  if valid_607055 != nil:
    section.add "Attributes", valid_607055
  var valid_607056 = query.getOrDefault("Action")
  valid_607056 = validateParameter(valid_607056, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_607056 != nil:
    section.add "Action", valid_607056
  var valid_607057 = query.getOrDefault("Version")
  valid_607057 = validateParameter(valid_607057, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607057 != nil:
    section.add "Version", valid_607057
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
  var valid_607058 = header.getOrDefault("X-Amz-Signature")
  valid_607058 = validateParameter(valid_607058, JString, required = false,
                                 default = nil)
  if valid_607058 != nil:
    section.add "X-Amz-Signature", valid_607058
  var valid_607059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607059 = validateParameter(valid_607059, JString, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "X-Amz-Content-Sha256", valid_607059
  var valid_607060 = header.getOrDefault("X-Amz-Date")
  valid_607060 = validateParameter(valid_607060, JString, required = false,
                                 default = nil)
  if valid_607060 != nil:
    section.add "X-Amz-Date", valid_607060
  var valid_607061 = header.getOrDefault("X-Amz-Credential")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-Credential", valid_607061
  var valid_607062 = header.getOrDefault("X-Amz-Security-Token")
  valid_607062 = validateParameter(valid_607062, JString, required = false,
                                 default = nil)
  if valid_607062 != nil:
    section.add "X-Amz-Security-Token", valid_607062
  var valid_607063 = header.getOrDefault("X-Amz-Algorithm")
  valid_607063 = validateParameter(valid_607063, JString, required = false,
                                 default = nil)
  if valid_607063 != nil:
    section.add "X-Amz-Algorithm", valid_607063
  var valid_607064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607064 = validateParameter(valid_607064, JString, required = false,
                                 default = nil)
  if valid_607064 != nil:
    section.add "X-Amz-SignedHeaders", valid_607064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607065: Call_GetModifyLoadBalancerAttributes_607051;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_607065.validator(path, query, header, formData, body)
  let scheme = call_607065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607065.url(scheme.get, call_607065.host, call_607065.base,
                         call_607065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607065, url, valid)

proc call*(call_607066: Call_GetModifyLoadBalancerAttributes_607051;
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
  var query_607067 = newJObject()
  add(query_607067, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Attributes != nil:
    query_607067.add "Attributes", Attributes
  add(query_607067, "Action", newJString(Action))
  add(query_607067, "Version", newJString(Version))
  result = call_607066.call(nil, query_607067, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_607051(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_607052, base: "/",
    url: url_GetModifyLoadBalancerAttributes_607053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyRule_607104 = ref object of OpenApiRestCall_605589
proc url_PostModifyRule_607106(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyRule_607105(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607107 = query.getOrDefault("Action")
  valid_607107 = validateParameter(valid_607107, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_607107 != nil:
    section.add "Action", valid_607107
  var valid_607108 = query.getOrDefault("Version")
  valid_607108 = validateParameter(valid_607108, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607108 != nil:
    section.add "Version", valid_607108
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
  var valid_607109 = header.getOrDefault("X-Amz-Signature")
  valid_607109 = validateParameter(valid_607109, JString, required = false,
                                 default = nil)
  if valid_607109 != nil:
    section.add "X-Amz-Signature", valid_607109
  var valid_607110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607110 = validateParameter(valid_607110, JString, required = false,
                                 default = nil)
  if valid_607110 != nil:
    section.add "X-Amz-Content-Sha256", valid_607110
  var valid_607111 = header.getOrDefault("X-Amz-Date")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "X-Amz-Date", valid_607111
  var valid_607112 = header.getOrDefault("X-Amz-Credential")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "X-Amz-Credential", valid_607112
  var valid_607113 = header.getOrDefault("X-Amz-Security-Token")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-Security-Token", valid_607113
  var valid_607114 = header.getOrDefault("X-Amz-Algorithm")
  valid_607114 = validateParameter(valid_607114, JString, required = false,
                                 default = nil)
  if valid_607114 != nil:
    section.add "X-Amz-Algorithm", valid_607114
  var valid_607115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607115 = validateParameter(valid_607115, JString, required = false,
                                 default = nil)
  if valid_607115 != nil:
    section.add "X-Amz-SignedHeaders", valid_607115
  result.add "header", section
  ## parameters in `formData` object:
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  var valid_607116 = formData.getOrDefault("Actions")
  valid_607116 = validateParameter(valid_607116, JArray, required = false,
                                 default = nil)
  if valid_607116 != nil:
    section.add "Actions", valid_607116
  var valid_607117 = formData.getOrDefault("Conditions")
  valid_607117 = validateParameter(valid_607117, JArray, required = false,
                                 default = nil)
  if valid_607117 != nil:
    section.add "Conditions", valid_607117
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_607118 = formData.getOrDefault("RuleArn")
  valid_607118 = validateParameter(valid_607118, JString, required = true,
                                 default = nil)
  if valid_607118 != nil:
    section.add "RuleArn", valid_607118
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607119: Call_PostModifyRule_607104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_607119.validator(path, query, header, formData, body)
  let scheme = call_607119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607119.url(scheme.get, call_607119.host, call_607119.base,
                         call_607119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607119, url, valid)

proc call*(call_607120: Call_PostModifyRule_607104; RuleArn: string;
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
  var query_607121 = newJObject()
  var formData_607122 = newJObject()
  if Actions != nil:
    formData_607122.add "Actions", Actions
  if Conditions != nil:
    formData_607122.add "Conditions", Conditions
  add(formData_607122, "RuleArn", newJString(RuleArn))
  add(query_607121, "Action", newJString(Action))
  add(query_607121, "Version", newJString(Version))
  result = call_607120.call(nil, query_607121, nil, formData_607122, nil)

var postModifyRule* = Call_PostModifyRule_607104(name: "postModifyRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_PostModifyRule_607105,
    base: "/", url: url_PostModifyRule_607106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyRule_607086 = ref object of OpenApiRestCall_605589
proc url_GetModifyRule_607088(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyRule_607087(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607089 = query.getOrDefault("RuleArn")
  valid_607089 = validateParameter(valid_607089, JString, required = true,
                                 default = nil)
  if valid_607089 != nil:
    section.add "RuleArn", valid_607089
  var valid_607090 = query.getOrDefault("Actions")
  valid_607090 = validateParameter(valid_607090, JArray, required = false,
                                 default = nil)
  if valid_607090 != nil:
    section.add "Actions", valid_607090
  var valid_607091 = query.getOrDefault("Action")
  valid_607091 = validateParameter(valid_607091, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_607091 != nil:
    section.add "Action", valid_607091
  var valid_607092 = query.getOrDefault("Version")
  valid_607092 = validateParameter(valid_607092, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607092 != nil:
    section.add "Version", valid_607092
  var valid_607093 = query.getOrDefault("Conditions")
  valid_607093 = validateParameter(valid_607093, JArray, required = false,
                                 default = nil)
  if valid_607093 != nil:
    section.add "Conditions", valid_607093
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
  var valid_607094 = header.getOrDefault("X-Amz-Signature")
  valid_607094 = validateParameter(valid_607094, JString, required = false,
                                 default = nil)
  if valid_607094 != nil:
    section.add "X-Amz-Signature", valid_607094
  var valid_607095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607095 = validateParameter(valid_607095, JString, required = false,
                                 default = nil)
  if valid_607095 != nil:
    section.add "X-Amz-Content-Sha256", valid_607095
  var valid_607096 = header.getOrDefault("X-Amz-Date")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "X-Amz-Date", valid_607096
  var valid_607097 = header.getOrDefault("X-Amz-Credential")
  valid_607097 = validateParameter(valid_607097, JString, required = false,
                                 default = nil)
  if valid_607097 != nil:
    section.add "X-Amz-Credential", valid_607097
  var valid_607098 = header.getOrDefault("X-Amz-Security-Token")
  valid_607098 = validateParameter(valid_607098, JString, required = false,
                                 default = nil)
  if valid_607098 != nil:
    section.add "X-Amz-Security-Token", valid_607098
  var valid_607099 = header.getOrDefault("X-Amz-Algorithm")
  valid_607099 = validateParameter(valid_607099, JString, required = false,
                                 default = nil)
  if valid_607099 != nil:
    section.add "X-Amz-Algorithm", valid_607099
  var valid_607100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607100 = validateParameter(valid_607100, JString, required = false,
                                 default = nil)
  if valid_607100 != nil:
    section.add "X-Amz-SignedHeaders", valid_607100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607101: Call_GetModifyRule_607086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_607101.validator(path, query, header, formData, body)
  let scheme = call_607101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607101.url(scheme.get, call_607101.host, call_607101.base,
                         call_607101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607101, url, valid)

proc call*(call_607102: Call_GetModifyRule_607086; RuleArn: string;
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
  var query_607103 = newJObject()
  add(query_607103, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    query_607103.add "Actions", Actions
  add(query_607103, "Action", newJString(Action))
  add(query_607103, "Version", newJString(Version))
  if Conditions != nil:
    query_607103.add "Conditions", Conditions
  result = call_607102.call(nil, query_607103, nil, nil, nil)

var getModifyRule* = Call_GetModifyRule_607086(name: "getModifyRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_GetModifyRule_607087,
    base: "/", url: url_GetModifyRule_607088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroup_607148 = ref object of OpenApiRestCall_605589
proc url_PostModifyTargetGroup_607150(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyTargetGroup_607149(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607151 = query.getOrDefault("Action")
  valid_607151 = validateParameter(valid_607151, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_607151 != nil:
    section.add "Action", valid_607151
  var valid_607152 = query.getOrDefault("Version")
  valid_607152 = validateParameter(valid_607152, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607152 != nil:
    section.add "Version", valid_607152
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
  var valid_607153 = header.getOrDefault("X-Amz-Signature")
  valid_607153 = validateParameter(valid_607153, JString, required = false,
                                 default = nil)
  if valid_607153 != nil:
    section.add "X-Amz-Signature", valid_607153
  var valid_607154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607154 = validateParameter(valid_607154, JString, required = false,
                                 default = nil)
  if valid_607154 != nil:
    section.add "X-Amz-Content-Sha256", valid_607154
  var valid_607155 = header.getOrDefault("X-Amz-Date")
  valid_607155 = validateParameter(valid_607155, JString, required = false,
                                 default = nil)
  if valid_607155 != nil:
    section.add "X-Amz-Date", valid_607155
  var valid_607156 = header.getOrDefault("X-Amz-Credential")
  valid_607156 = validateParameter(valid_607156, JString, required = false,
                                 default = nil)
  if valid_607156 != nil:
    section.add "X-Amz-Credential", valid_607156
  var valid_607157 = header.getOrDefault("X-Amz-Security-Token")
  valid_607157 = validateParameter(valid_607157, JString, required = false,
                                 default = nil)
  if valid_607157 != nil:
    section.add "X-Amz-Security-Token", valid_607157
  var valid_607158 = header.getOrDefault("X-Amz-Algorithm")
  valid_607158 = validateParameter(valid_607158, JString, required = false,
                                 default = nil)
  if valid_607158 != nil:
    section.add "X-Amz-Algorithm", valid_607158
  var valid_607159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607159 = validateParameter(valid_607159, JString, required = false,
                                 default = nil)
  if valid_607159 != nil:
    section.add "X-Amz-SignedHeaders", valid_607159
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
  var valid_607160 = formData.getOrDefault("HealthCheckProtocol")
  valid_607160 = validateParameter(valid_607160, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_607160 != nil:
    section.add "HealthCheckProtocol", valid_607160
  var valid_607161 = formData.getOrDefault("HealthCheckPort")
  valid_607161 = validateParameter(valid_607161, JString, required = false,
                                 default = nil)
  if valid_607161 != nil:
    section.add "HealthCheckPort", valid_607161
  var valid_607162 = formData.getOrDefault("HealthCheckEnabled")
  valid_607162 = validateParameter(valid_607162, JBool, required = false, default = nil)
  if valid_607162 != nil:
    section.add "HealthCheckEnabled", valid_607162
  var valid_607163 = formData.getOrDefault("HealthCheckPath")
  valid_607163 = validateParameter(valid_607163, JString, required = false,
                                 default = nil)
  if valid_607163 != nil:
    section.add "HealthCheckPath", valid_607163
  var valid_607164 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_607164 = validateParameter(valid_607164, JInt, required = false, default = nil)
  if valid_607164 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_607164
  var valid_607165 = formData.getOrDefault("HealthyThresholdCount")
  valid_607165 = validateParameter(valid_607165, JInt, required = false, default = nil)
  if valid_607165 != nil:
    section.add "HealthyThresholdCount", valid_607165
  var valid_607166 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_607166 = validateParameter(valid_607166, JInt, required = false, default = nil)
  if valid_607166 != nil:
    section.add "HealthCheckIntervalSeconds", valid_607166
  var valid_607167 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_607167 = validateParameter(valid_607167, JInt, required = false, default = nil)
  if valid_607167 != nil:
    section.add "UnhealthyThresholdCount", valid_607167
  var valid_607168 = formData.getOrDefault("Matcher.HttpCode")
  valid_607168 = validateParameter(valid_607168, JString, required = false,
                                 default = nil)
  if valid_607168 != nil:
    section.add "Matcher.HttpCode", valid_607168
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_607169 = formData.getOrDefault("TargetGroupArn")
  valid_607169 = validateParameter(valid_607169, JString, required = true,
                                 default = nil)
  if valid_607169 != nil:
    section.add "TargetGroupArn", valid_607169
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607170: Call_PostModifyTargetGroup_607148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_607170.validator(path, query, header, formData, body)
  let scheme = call_607170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607170.url(scheme.get, call_607170.host, call_607170.base,
                         call_607170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607170, url, valid)

proc call*(call_607171: Call_PostModifyTargetGroup_607148; TargetGroupArn: string;
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
  var query_607172 = newJObject()
  var formData_607173 = newJObject()
  add(formData_607173, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_607173, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_607173, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_607173, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_607173, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_607173, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_607173, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_607173, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_607173, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_607172, "Action", newJString(Action))
  add(formData_607173, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_607172, "Version", newJString(Version))
  result = call_607171.call(nil, query_607172, nil, formData_607173, nil)

var postModifyTargetGroup* = Call_PostModifyTargetGroup_607148(
    name: "postModifyTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup",
    validator: validate_PostModifyTargetGroup_607149, base: "/",
    url: url_PostModifyTargetGroup_607150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroup_607123 = ref object of OpenApiRestCall_605589
proc url_GetModifyTargetGroup_607125(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyTargetGroup_607124(path: JsonNode; query: JsonNode;
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
  var valid_607126 = query.getOrDefault("HealthCheckPort")
  valid_607126 = validateParameter(valid_607126, JString, required = false,
                                 default = nil)
  if valid_607126 != nil:
    section.add "HealthCheckPort", valid_607126
  var valid_607127 = query.getOrDefault("HealthCheckPath")
  valid_607127 = validateParameter(valid_607127, JString, required = false,
                                 default = nil)
  if valid_607127 != nil:
    section.add "HealthCheckPath", valid_607127
  var valid_607128 = query.getOrDefault("HealthCheckProtocol")
  valid_607128 = validateParameter(valid_607128, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_607128 != nil:
    section.add "HealthCheckProtocol", valid_607128
  var valid_607129 = query.getOrDefault("Matcher.HttpCode")
  valid_607129 = validateParameter(valid_607129, JString, required = false,
                                 default = nil)
  if valid_607129 != nil:
    section.add "Matcher.HttpCode", valid_607129
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_607130 = query.getOrDefault("TargetGroupArn")
  valid_607130 = validateParameter(valid_607130, JString, required = true,
                                 default = nil)
  if valid_607130 != nil:
    section.add "TargetGroupArn", valid_607130
  var valid_607131 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_607131 = validateParameter(valid_607131, JInt, required = false, default = nil)
  if valid_607131 != nil:
    section.add "HealthCheckIntervalSeconds", valid_607131
  var valid_607132 = query.getOrDefault("HealthCheckEnabled")
  valid_607132 = validateParameter(valid_607132, JBool, required = false, default = nil)
  if valid_607132 != nil:
    section.add "HealthCheckEnabled", valid_607132
  var valid_607133 = query.getOrDefault("HealthyThresholdCount")
  valid_607133 = validateParameter(valid_607133, JInt, required = false, default = nil)
  if valid_607133 != nil:
    section.add "HealthyThresholdCount", valid_607133
  var valid_607134 = query.getOrDefault("UnhealthyThresholdCount")
  valid_607134 = validateParameter(valid_607134, JInt, required = false, default = nil)
  if valid_607134 != nil:
    section.add "UnhealthyThresholdCount", valid_607134
  var valid_607135 = query.getOrDefault("Action")
  valid_607135 = validateParameter(valid_607135, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_607135 != nil:
    section.add "Action", valid_607135
  var valid_607136 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_607136 = validateParameter(valid_607136, JInt, required = false, default = nil)
  if valid_607136 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_607136
  var valid_607137 = query.getOrDefault("Version")
  valid_607137 = validateParameter(valid_607137, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607137 != nil:
    section.add "Version", valid_607137
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
  var valid_607138 = header.getOrDefault("X-Amz-Signature")
  valid_607138 = validateParameter(valid_607138, JString, required = false,
                                 default = nil)
  if valid_607138 != nil:
    section.add "X-Amz-Signature", valid_607138
  var valid_607139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607139 = validateParameter(valid_607139, JString, required = false,
                                 default = nil)
  if valid_607139 != nil:
    section.add "X-Amz-Content-Sha256", valid_607139
  var valid_607140 = header.getOrDefault("X-Amz-Date")
  valid_607140 = validateParameter(valid_607140, JString, required = false,
                                 default = nil)
  if valid_607140 != nil:
    section.add "X-Amz-Date", valid_607140
  var valid_607141 = header.getOrDefault("X-Amz-Credential")
  valid_607141 = validateParameter(valid_607141, JString, required = false,
                                 default = nil)
  if valid_607141 != nil:
    section.add "X-Amz-Credential", valid_607141
  var valid_607142 = header.getOrDefault("X-Amz-Security-Token")
  valid_607142 = validateParameter(valid_607142, JString, required = false,
                                 default = nil)
  if valid_607142 != nil:
    section.add "X-Amz-Security-Token", valid_607142
  var valid_607143 = header.getOrDefault("X-Amz-Algorithm")
  valid_607143 = validateParameter(valid_607143, JString, required = false,
                                 default = nil)
  if valid_607143 != nil:
    section.add "X-Amz-Algorithm", valid_607143
  var valid_607144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607144 = validateParameter(valid_607144, JString, required = false,
                                 default = nil)
  if valid_607144 != nil:
    section.add "X-Amz-SignedHeaders", valid_607144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607145: Call_GetModifyTargetGroup_607123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_607145.validator(path, query, header, formData, body)
  let scheme = call_607145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607145.url(scheme.get, call_607145.host, call_607145.base,
                         call_607145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607145, url, valid)

proc call*(call_607146: Call_GetModifyTargetGroup_607123; TargetGroupArn: string;
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
  var query_607147 = newJObject()
  add(query_607147, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_607147, "HealthCheckPath", newJString(HealthCheckPath))
  add(query_607147, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_607147, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_607147, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_607147, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_607147, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_607147, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_607147, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_607147, "Action", newJString(Action))
  add(query_607147, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_607147, "Version", newJString(Version))
  result = call_607146.call(nil, query_607147, nil, nil, nil)

var getModifyTargetGroup* = Call_GetModifyTargetGroup_607123(
    name: "getModifyTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup", validator: validate_GetModifyTargetGroup_607124,
    base: "/", url: url_GetModifyTargetGroup_607125,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroupAttributes_607191 = ref object of OpenApiRestCall_605589
proc url_PostModifyTargetGroupAttributes_607193(protocol: Scheme; host: string;
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

proc validate_PostModifyTargetGroupAttributes_607192(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607194 = query.getOrDefault("Action")
  valid_607194 = validateParameter(valid_607194, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_607194 != nil:
    section.add "Action", valid_607194
  var valid_607195 = query.getOrDefault("Version")
  valid_607195 = validateParameter(valid_607195, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607195 != nil:
    section.add "Version", valid_607195
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
  var valid_607196 = header.getOrDefault("X-Amz-Signature")
  valid_607196 = validateParameter(valid_607196, JString, required = false,
                                 default = nil)
  if valid_607196 != nil:
    section.add "X-Amz-Signature", valid_607196
  var valid_607197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607197 = validateParameter(valid_607197, JString, required = false,
                                 default = nil)
  if valid_607197 != nil:
    section.add "X-Amz-Content-Sha256", valid_607197
  var valid_607198 = header.getOrDefault("X-Amz-Date")
  valid_607198 = validateParameter(valid_607198, JString, required = false,
                                 default = nil)
  if valid_607198 != nil:
    section.add "X-Amz-Date", valid_607198
  var valid_607199 = header.getOrDefault("X-Amz-Credential")
  valid_607199 = validateParameter(valid_607199, JString, required = false,
                                 default = nil)
  if valid_607199 != nil:
    section.add "X-Amz-Credential", valid_607199
  var valid_607200 = header.getOrDefault("X-Amz-Security-Token")
  valid_607200 = validateParameter(valid_607200, JString, required = false,
                                 default = nil)
  if valid_607200 != nil:
    section.add "X-Amz-Security-Token", valid_607200
  var valid_607201 = header.getOrDefault("X-Amz-Algorithm")
  valid_607201 = validateParameter(valid_607201, JString, required = false,
                                 default = nil)
  if valid_607201 != nil:
    section.add "X-Amz-Algorithm", valid_607201
  var valid_607202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607202 = validateParameter(valid_607202, JString, required = false,
                                 default = nil)
  if valid_607202 != nil:
    section.add "X-Amz-SignedHeaders", valid_607202
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_607203 = formData.getOrDefault("Attributes")
  valid_607203 = validateParameter(valid_607203, JArray, required = true, default = nil)
  if valid_607203 != nil:
    section.add "Attributes", valid_607203
  var valid_607204 = formData.getOrDefault("TargetGroupArn")
  valid_607204 = validateParameter(valid_607204, JString, required = true,
                                 default = nil)
  if valid_607204 != nil:
    section.add "TargetGroupArn", valid_607204
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607205: Call_PostModifyTargetGroupAttributes_607191;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_607205.validator(path, query, header, formData, body)
  let scheme = call_607205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607205.url(scheme.get, call_607205.host, call_607205.base,
                         call_607205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607205, url, valid)

proc call*(call_607206: Call_PostModifyTargetGroupAttributes_607191;
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
  var query_607207 = newJObject()
  var formData_607208 = newJObject()
  if Attributes != nil:
    formData_607208.add "Attributes", Attributes
  add(query_607207, "Action", newJString(Action))
  add(formData_607208, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_607207, "Version", newJString(Version))
  result = call_607206.call(nil, query_607207, nil, formData_607208, nil)

var postModifyTargetGroupAttributes* = Call_PostModifyTargetGroupAttributes_607191(
    name: "postModifyTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_PostModifyTargetGroupAttributes_607192, base: "/",
    url: url_PostModifyTargetGroupAttributes_607193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroupAttributes_607174 = ref object of OpenApiRestCall_605589
proc url_GetModifyTargetGroupAttributes_607176(protocol: Scheme; host: string;
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

proc validate_GetModifyTargetGroupAttributes_607175(path: JsonNode;
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
  var valid_607177 = query.getOrDefault("TargetGroupArn")
  valid_607177 = validateParameter(valid_607177, JString, required = true,
                                 default = nil)
  if valid_607177 != nil:
    section.add "TargetGroupArn", valid_607177
  var valid_607178 = query.getOrDefault("Attributes")
  valid_607178 = validateParameter(valid_607178, JArray, required = true, default = nil)
  if valid_607178 != nil:
    section.add "Attributes", valid_607178
  var valid_607179 = query.getOrDefault("Action")
  valid_607179 = validateParameter(valid_607179, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_607179 != nil:
    section.add "Action", valid_607179
  var valid_607180 = query.getOrDefault("Version")
  valid_607180 = validateParameter(valid_607180, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607180 != nil:
    section.add "Version", valid_607180
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
  var valid_607181 = header.getOrDefault("X-Amz-Signature")
  valid_607181 = validateParameter(valid_607181, JString, required = false,
                                 default = nil)
  if valid_607181 != nil:
    section.add "X-Amz-Signature", valid_607181
  var valid_607182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607182 = validateParameter(valid_607182, JString, required = false,
                                 default = nil)
  if valid_607182 != nil:
    section.add "X-Amz-Content-Sha256", valid_607182
  var valid_607183 = header.getOrDefault("X-Amz-Date")
  valid_607183 = validateParameter(valid_607183, JString, required = false,
                                 default = nil)
  if valid_607183 != nil:
    section.add "X-Amz-Date", valid_607183
  var valid_607184 = header.getOrDefault("X-Amz-Credential")
  valid_607184 = validateParameter(valid_607184, JString, required = false,
                                 default = nil)
  if valid_607184 != nil:
    section.add "X-Amz-Credential", valid_607184
  var valid_607185 = header.getOrDefault("X-Amz-Security-Token")
  valid_607185 = validateParameter(valid_607185, JString, required = false,
                                 default = nil)
  if valid_607185 != nil:
    section.add "X-Amz-Security-Token", valid_607185
  var valid_607186 = header.getOrDefault("X-Amz-Algorithm")
  valid_607186 = validateParameter(valid_607186, JString, required = false,
                                 default = nil)
  if valid_607186 != nil:
    section.add "X-Amz-Algorithm", valid_607186
  var valid_607187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607187 = validateParameter(valid_607187, JString, required = false,
                                 default = nil)
  if valid_607187 != nil:
    section.add "X-Amz-SignedHeaders", valid_607187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607188: Call_GetModifyTargetGroupAttributes_607174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_607188.validator(path, query, header, formData, body)
  let scheme = call_607188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607188.url(scheme.get, call_607188.host, call_607188.base,
                         call_607188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607188, url, valid)

proc call*(call_607189: Call_GetModifyTargetGroupAttributes_607174;
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
  var query_607190 = newJObject()
  add(query_607190, "TargetGroupArn", newJString(TargetGroupArn))
  if Attributes != nil:
    query_607190.add "Attributes", Attributes
  add(query_607190, "Action", newJString(Action))
  add(query_607190, "Version", newJString(Version))
  result = call_607189.call(nil, query_607190, nil, nil, nil)

var getModifyTargetGroupAttributes* = Call_GetModifyTargetGroupAttributes_607174(
    name: "getModifyTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_GetModifyTargetGroupAttributes_607175, base: "/",
    url: url_GetModifyTargetGroupAttributes_607176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterTargets_607226 = ref object of OpenApiRestCall_605589
proc url_PostRegisterTargets_607228(protocol: Scheme; host: string; base: string;
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

proc validate_PostRegisterTargets_607227(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607229 = query.getOrDefault("Action")
  valid_607229 = validateParameter(valid_607229, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_607229 != nil:
    section.add "Action", valid_607229
  var valid_607230 = query.getOrDefault("Version")
  valid_607230 = validateParameter(valid_607230, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607230 != nil:
    section.add "Version", valid_607230
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
  var valid_607231 = header.getOrDefault("X-Amz-Signature")
  valid_607231 = validateParameter(valid_607231, JString, required = false,
                                 default = nil)
  if valid_607231 != nil:
    section.add "X-Amz-Signature", valid_607231
  var valid_607232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607232 = validateParameter(valid_607232, JString, required = false,
                                 default = nil)
  if valid_607232 != nil:
    section.add "X-Amz-Content-Sha256", valid_607232
  var valid_607233 = header.getOrDefault("X-Amz-Date")
  valid_607233 = validateParameter(valid_607233, JString, required = false,
                                 default = nil)
  if valid_607233 != nil:
    section.add "X-Amz-Date", valid_607233
  var valid_607234 = header.getOrDefault("X-Amz-Credential")
  valid_607234 = validateParameter(valid_607234, JString, required = false,
                                 default = nil)
  if valid_607234 != nil:
    section.add "X-Amz-Credential", valid_607234
  var valid_607235 = header.getOrDefault("X-Amz-Security-Token")
  valid_607235 = validateParameter(valid_607235, JString, required = false,
                                 default = nil)
  if valid_607235 != nil:
    section.add "X-Amz-Security-Token", valid_607235
  var valid_607236 = header.getOrDefault("X-Amz-Algorithm")
  valid_607236 = validateParameter(valid_607236, JString, required = false,
                                 default = nil)
  if valid_607236 != nil:
    section.add "X-Amz-Algorithm", valid_607236
  var valid_607237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607237 = validateParameter(valid_607237, JString, required = false,
                                 default = nil)
  if valid_607237 != nil:
    section.add "X-Amz-SignedHeaders", valid_607237
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_607238 = formData.getOrDefault("Targets")
  valid_607238 = validateParameter(valid_607238, JArray, required = true, default = nil)
  if valid_607238 != nil:
    section.add "Targets", valid_607238
  var valid_607239 = formData.getOrDefault("TargetGroupArn")
  valid_607239 = validateParameter(valid_607239, JString, required = true,
                                 default = nil)
  if valid_607239 != nil:
    section.add "TargetGroupArn", valid_607239
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607240: Call_PostRegisterTargets_607226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_607240.validator(path, query, header, formData, body)
  let scheme = call_607240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607240.url(scheme.get, call_607240.host, call_607240.base,
                         call_607240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607240, url, valid)

proc call*(call_607241: Call_PostRegisterTargets_607226; Targets: JsonNode;
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
  var query_607242 = newJObject()
  var formData_607243 = newJObject()
  if Targets != nil:
    formData_607243.add "Targets", Targets
  add(query_607242, "Action", newJString(Action))
  add(formData_607243, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_607242, "Version", newJString(Version))
  result = call_607241.call(nil, query_607242, nil, formData_607243, nil)

var postRegisterTargets* = Call_PostRegisterTargets_607226(
    name: "postRegisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_PostRegisterTargets_607227, base: "/",
    url: url_PostRegisterTargets_607228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterTargets_607209 = ref object of OpenApiRestCall_605589
proc url_GetRegisterTargets_607211(protocol: Scheme; host: string; base: string;
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

proc validate_GetRegisterTargets_607210(path: JsonNode; query: JsonNode;
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
  var valid_607212 = query.getOrDefault("Targets")
  valid_607212 = validateParameter(valid_607212, JArray, required = true, default = nil)
  if valid_607212 != nil:
    section.add "Targets", valid_607212
  var valid_607213 = query.getOrDefault("TargetGroupArn")
  valid_607213 = validateParameter(valid_607213, JString, required = true,
                                 default = nil)
  if valid_607213 != nil:
    section.add "TargetGroupArn", valid_607213
  var valid_607214 = query.getOrDefault("Action")
  valid_607214 = validateParameter(valid_607214, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_607214 != nil:
    section.add "Action", valid_607214
  var valid_607215 = query.getOrDefault("Version")
  valid_607215 = validateParameter(valid_607215, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607215 != nil:
    section.add "Version", valid_607215
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
  var valid_607216 = header.getOrDefault("X-Amz-Signature")
  valid_607216 = validateParameter(valid_607216, JString, required = false,
                                 default = nil)
  if valid_607216 != nil:
    section.add "X-Amz-Signature", valid_607216
  var valid_607217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607217 = validateParameter(valid_607217, JString, required = false,
                                 default = nil)
  if valid_607217 != nil:
    section.add "X-Amz-Content-Sha256", valid_607217
  var valid_607218 = header.getOrDefault("X-Amz-Date")
  valid_607218 = validateParameter(valid_607218, JString, required = false,
                                 default = nil)
  if valid_607218 != nil:
    section.add "X-Amz-Date", valid_607218
  var valid_607219 = header.getOrDefault("X-Amz-Credential")
  valid_607219 = validateParameter(valid_607219, JString, required = false,
                                 default = nil)
  if valid_607219 != nil:
    section.add "X-Amz-Credential", valid_607219
  var valid_607220 = header.getOrDefault("X-Amz-Security-Token")
  valid_607220 = validateParameter(valid_607220, JString, required = false,
                                 default = nil)
  if valid_607220 != nil:
    section.add "X-Amz-Security-Token", valid_607220
  var valid_607221 = header.getOrDefault("X-Amz-Algorithm")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "X-Amz-Algorithm", valid_607221
  var valid_607222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607222 = validateParameter(valid_607222, JString, required = false,
                                 default = nil)
  if valid_607222 != nil:
    section.add "X-Amz-SignedHeaders", valid_607222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607223: Call_GetRegisterTargets_607209; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_607223.validator(path, query, header, formData, body)
  let scheme = call_607223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607223.url(scheme.get, call_607223.host, call_607223.base,
                         call_607223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607223, url, valid)

proc call*(call_607224: Call_GetRegisterTargets_607209; Targets: JsonNode;
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
  var query_607225 = newJObject()
  if Targets != nil:
    query_607225.add "Targets", Targets
  add(query_607225, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_607225, "Action", newJString(Action))
  add(query_607225, "Version", newJString(Version))
  result = call_607224.call(nil, query_607225, nil, nil, nil)

var getRegisterTargets* = Call_GetRegisterTargets_607209(
    name: "getRegisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_GetRegisterTargets_607210, base: "/",
    url: url_GetRegisterTargets_607211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveListenerCertificates_607261 = ref object of OpenApiRestCall_605589
proc url_PostRemoveListenerCertificates_607263(protocol: Scheme; host: string;
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

proc validate_PostRemoveListenerCertificates_607262(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607264 = query.getOrDefault("Action")
  valid_607264 = validateParameter(valid_607264, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_607264 != nil:
    section.add "Action", valid_607264
  var valid_607265 = query.getOrDefault("Version")
  valid_607265 = validateParameter(valid_607265, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607265 != nil:
    section.add "Version", valid_607265
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
  var valid_607266 = header.getOrDefault("X-Amz-Signature")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-Signature", valid_607266
  var valid_607267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607267 = validateParameter(valid_607267, JString, required = false,
                                 default = nil)
  if valid_607267 != nil:
    section.add "X-Amz-Content-Sha256", valid_607267
  var valid_607268 = header.getOrDefault("X-Amz-Date")
  valid_607268 = validateParameter(valid_607268, JString, required = false,
                                 default = nil)
  if valid_607268 != nil:
    section.add "X-Amz-Date", valid_607268
  var valid_607269 = header.getOrDefault("X-Amz-Credential")
  valid_607269 = validateParameter(valid_607269, JString, required = false,
                                 default = nil)
  if valid_607269 != nil:
    section.add "X-Amz-Credential", valid_607269
  var valid_607270 = header.getOrDefault("X-Amz-Security-Token")
  valid_607270 = validateParameter(valid_607270, JString, required = false,
                                 default = nil)
  if valid_607270 != nil:
    section.add "X-Amz-Security-Token", valid_607270
  var valid_607271 = header.getOrDefault("X-Amz-Algorithm")
  valid_607271 = validateParameter(valid_607271, JString, required = false,
                                 default = nil)
  if valid_607271 != nil:
    section.add "X-Amz-Algorithm", valid_607271
  var valid_607272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607272 = validateParameter(valid_607272, JString, required = false,
                                 default = nil)
  if valid_607272 != nil:
    section.add "X-Amz-SignedHeaders", valid_607272
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_607273 = formData.getOrDefault("Certificates")
  valid_607273 = validateParameter(valid_607273, JArray, required = true, default = nil)
  if valid_607273 != nil:
    section.add "Certificates", valid_607273
  var valid_607274 = formData.getOrDefault("ListenerArn")
  valid_607274 = validateParameter(valid_607274, JString, required = true,
                                 default = nil)
  if valid_607274 != nil:
    section.add "ListenerArn", valid_607274
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607275: Call_PostRemoveListenerCertificates_607261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_607275.validator(path, query, header, formData, body)
  let scheme = call_607275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607275.url(scheme.get, call_607275.host, call_607275.base,
                         call_607275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607275, url, valid)

proc call*(call_607276: Call_PostRemoveListenerCertificates_607261;
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
  var query_607277 = newJObject()
  var formData_607278 = newJObject()
  if Certificates != nil:
    formData_607278.add "Certificates", Certificates
  add(formData_607278, "ListenerArn", newJString(ListenerArn))
  add(query_607277, "Action", newJString(Action))
  add(query_607277, "Version", newJString(Version))
  result = call_607276.call(nil, query_607277, nil, formData_607278, nil)

var postRemoveListenerCertificates* = Call_PostRemoveListenerCertificates_607261(
    name: "postRemoveListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_PostRemoveListenerCertificates_607262, base: "/",
    url: url_PostRemoveListenerCertificates_607263,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveListenerCertificates_607244 = ref object of OpenApiRestCall_605589
proc url_GetRemoveListenerCertificates_607246(protocol: Scheme; host: string;
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

proc validate_GetRemoveListenerCertificates_607245(path: JsonNode; query: JsonNode;
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
  var valid_607247 = query.getOrDefault("ListenerArn")
  valid_607247 = validateParameter(valid_607247, JString, required = true,
                                 default = nil)
  if valid_607247 != nil:
    section.add "ListenerArn", valid_607247
  var valid_607248 = query.getOrDefault("Certificates")
  valid_607248 = validateParameter(valid_607248, JArray, required = true, default = nil)
  if valid_607248 != nil:
    section.add "Certificates", valid_607248
  var valid_607249 = query.getOrDefault("Action")
  valid_607249 = validateParameter(valid_607249, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_607249 != nil:
    section.add "Action", valid_607249
  var valid_607250 = query.getOrDefault("Version")
  valid_607250 = validateParameter(valid_607250, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607250 != nil:
    section.add "Version", valid_607250
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
  var valid_607251 = header.getOrDefault("X-Amz-Signature")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "X-Amz-Signature", valid_607251
  var valid_607252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607252 = validateParameter(valid_607252, JString, required = false,
                                 default = nil)
  if valid_607252 != nil:
    section.add "X-Amz-Content-Sha256", valid_607252
  var valid_607253 = header.getOrDefault("X-Amz-Date")
  valid_607253 = validateParameter(valid_607253, JString, required = false,
                                 default = nil)
  if valid_607253 != nil:
    section.add "X-Amz-Date", valid_607253
  var valid_607254 = header.getOrDefault("X-Amz-Credential")
  valid_607254 = validateParameter(valid_607254, JString, required = false,
                                 default = nil)
  if valid_607254 != nil:
    section.add "X-Amz-Credential", valid_607254
  var valid_607255 = header.getOrDefault("X-Amz-Security-Token")
  valid_607255 = validateParameter(valid_607255, JString, required = false,
                                 default = nil)
  if valid_607255 != nil:
    section.add "X-Amz-Security-Token", valid_607255
  var valid_607256 = header.getOrDefault("X-Amz-Algorithm")
  valid_607256 = validateParameter(valid_607256, JString, required = false,
                                 default = nil)
  if valid_607256 != nil:
    section.add "X-Amz-Algorithm", valid_607256
  var valid_607257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607257 = validateParameter(valid_607257, JString, required = false,
                                 default = nil)
  if valid_607257 != nil:
    section.add "X-Amz-SignedHeaders", valid_607257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607258: Call_GetRemoveListenerCertificates_607244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_607258.validator(path, query, header, formData, body)
  let scheme = call_607258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607258.url(scheme.get, call_607258.host, call_607258.base,
                         call_607258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607258, url, valid)

proc call*(call_607259: Call_GetRemoveListenerCertificates_607244;
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
  var query_607260 = newJObject()
  add(query_607260, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_607260.add "Certificates", Certificates
  add(query_607260, "Action", newJString(Action))
  add(query_607260, "Version", newJString(Version))
  result = call_607259.call(nil, query_607260, nil, nil, nil)

var getRemoveListenerCertificates* = Call_GetRemoveListenerCertificates_607244(
    name: "getRemoveListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_GetRemoveListenerCertificates_607245, base: "/",
    url: url_GetRemoveListenerCertificates_607246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_607296 = ref object of OpenApiRestCall_605589
proc url_PostRemoveTags_607298(protocol: Scheme; host: string; base: string;
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

proc validate_PostRemoveTags_607297(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607299 = query.getOrDefault("Action")
  valid_607299 = validateParameter(valid_607299, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_607299 != nil:
    section.add "Action", valid_607299
  var valid_607300 = query.getOrDefault("Version")
  valid_607300 = validateParameter(valid_607300, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607300 != nil:
    section.add "Version", valid_607300
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
  var valid_607301 = header.getOrDefault("X-Amz-Signature")
  valid_607301 = validateParameter(valid_607301, JString, required = false,
                                 default = nil)
  if valid_607301 != nil:
    section.add "X-Amz-Signature", valid_607301
  var valid_607302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607302 = validateParameter(valid_607302, JString, required = false,
                                 default = nil)
  if valid_607302 != nil:
    section.add "X-Amz-Content-Sha256", valid_607302
  var valid_607303 = header.getOrDefault("X-Amz-Date")
  valid_607303 = validateParameter(valid_607303, JString, required = false,
                                 default = nil)
  if valid_607303 != nil:
    section.add "X-Amz-Date", valid_607303
  var valid_607304 = header.getOrDefault("X-Amz-Credential")
  valid_607304 = validateParameter(valid_607304, JString, required = false,
                                 default = nil)
  if valid_607304 != nil:
    section.add "X-Amz-Credential", valid_607304
  var valid_607305 = header.getOrDefault("X-Amz-Security-Token")
  valid_607305 = validateParameter(valid_607305, JString, required = false,
                                 default = nil)
  if valid_607305 != nil:
    section.add "X-Amz-Security-Token", valid_607305
  var valid_607306 = header.getOrDefault("X-Amz-Algorithm")
  valid_607306 = validateParameter(valid_607306, JString, required = false,
                                 default = nil)
  if valid_607306 != nil:
    section.add "X-Amz-Algorithm", valid_607306
  var valid_607307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607307 = validateParameter(valid_607307, JString, required = false,
                                 default = nil)
  if valid_607307 != nil:
    section.add "X-Amz-SignedHeaders", valid_607307
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_607308 = formData.getOrDefault("TagKeys")
  valid_607308 = validateParameter(valid_607308, JArray, required = true, default = nil)
  if valid_607308 != nil:
    section.add "TagKeys", valid_607308
  var valid_607309 = formData.getOrDefault("ResourceArns")
  valid_607309 = validateParameter(valid_607309, JArray, required = true, default = nil)
  if valid_607309 != nil:
    section.add "ResourceArns", valid_607309
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607310: Call_PostRemoveTags_607296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_607310.validator(path, query, header, formData, body)
  let scheme = call_607310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607310.url(scheme.get, call_607310.host, call_607310.base,
                         call_607310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607310, url, valid)

proc call*(call_607311: Call_PostRemoveTags_607296; TagKeys: JsonNode;
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
  var query_607312 = newJObject()
  var formData_607313 = newJObject()
  if TagKeys != nil:
    formData_607313.add "TagKeys", TagKeys
  if ResourceArns != nil:
    formData_607313.add "ResourceArns", ResourceArns
  add(query_607312, "Action", newJString(Action))
  add(query_607312, "Version", newJString(Version))
  result = call_607311.call(nil, query_607312, nil, formData_607313, nil)

var postRemoveTags* = Call_PostRemoveTags_607296(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_607297,
    base: "/", url: url_PostRemoveTags_607298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_607279 = ref object of OpenApiRestCall_605589
proc url_GetRemoveTags_607281(protocol: Scheme; host: string; base: string;
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

proc validate_GetRemoveTags_607280(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607282 = query.getOrDefault("ResourceArns")
  valid_607282 = validateParameter(valid_607282, JArray, required = true, default = nil)
  if valid_607282 != nil:
    section.add "ResourceArns", valid_607282
  var valid_607283 = query.getOrDefault("TagKeys")
  valid_607283 = validateParameter(valid_607283, JArray, required = true, default = nil)
  if valid_607283 != nil:
    section.add "TagKeys", valid_607283
  var valid_607284 = query.getOrDefault("Action")
  valid_607284 = validateParameter(valid_607284, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_607284 != nil:
    section.add "Action", valid_607284
  var valid_607285 = query.getOrDefault("Version")
  valid_607285 = validateParameter(valid_607285, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607285 != nil:
    section.add "Version", valid_607285
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
  var valid_607286 = header.getOrDefault("X-Amz-Signature")
  valid_607286 = validateParameter(valid_607286, JString, required = false,
                                 default = nil)
  if valid_607286 != nil:
    section.add "X-Amz-Signature", valid_607286
  var valid_607287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607287 = validateParameter(valid_607287, JString, required = false,
                                 default = nil)
  if valid_607287 != nil:
    section.add "X-Amz-Content-Sha256", valid_607287
  var valid_607288 = header.getOrDefault("X-Amz-Date")
  valid_607288 = validateParameter(valid_607288, JString, required = false,
                                 default = nil)
  if valid_607288 != nil:
    section.add "X-Amz-Date", valid_607288
  var valid_607289 = header.getOrDefault("X-Amz-Credential")
  valid_607289 = validateParameter(valid_607289, JString, required = false,
                                 default = nil)
  if valid_607289 != nil:
    section.add "X-Amz-Credential", valid_607289
  var valid_607290 = header.getOrDefault("X-Amz-Security-Token")
  valid_607290 = validateParameter(valid_607290, JString, required = false,
                                 default = nil)
  if valid_607290 != nil:
    section.add "X-Amz-Security-Token", valid_607290
  var valid_607291 = header.getOrDefault("X-Amz-Algorithm")
  valid_607291 = validateParameter(valid_607291, JString, required = false,
                                 default = nil)
  if valid_607291 != nil:
    section.add "X-Amz-Algorithm", valid_607291
  var valid_607292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607292 = validateParameter(valid_607292, JString, required = false,
                                 default = nil)
  if valid_607292 != nil:
    section.add "X-Amz-SignedHeaders", valid_607292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607293: Call_GetRemoveTags_607279; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_607293.validator(path, query, header, formData, body)
  let scheme = call_607293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607293.url(scheme.get, call_607293.host, call_607293.base,
                         call_607293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607293, url, valid)

proc call*(call_607294: Call_GetRemoveTags_607279; ResourceArns: JsonNode;
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
  var query_607295 = newJObject()
  if ResourceArns != nil:
    query_607295.add "ResourceArns", ResourceArns
  if TagKeys != nil:
    query_607295.add "TagKeys", TagKeys
  add(query_607295, "Action", newJString(Action))
  add(query_607295, "Version", newJString(Version))
  result = call_607294.call(nil, query_607295, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_607279(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_607280,
    base: "/", url: url_GetRemoveTags_607281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetIpAddressType_607331 = ref object of OpenApiRestCall_605589
proc url_PostSetIpAddressType_607333(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetIpAddressType_607332(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607334 = query.getOrDefault("Action")
  valid_607334 = validateParameter(valid_607334, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_607334 != nil:
    section.add "Action", valid_607334
  var valid_607335 = query.getOrDefault("Version")
  valid_607335 = validateParameter(valid_607335, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607335 != nil:
    section.add "Version", valid_607335
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
  var valid_607336 = header.getOrDefault("X-Amz-Signature")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Signature", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Content-Sha256", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-Date")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-Date", valid_607338
  var valid_607339 = header.getOrDefault("X-Amz-Credential")
  valid_607339 = validateParameter(valid_607339, JString, required = false,
                                 default = nil)
  if valid_607339 != nil:
    section.add "X-Amz-Credential", valid_607339
  var valid_607340 = header.getOrDefault("X-Amz-Security-Token")
  valid_607340 = validateParameter(valid_607340, JString, required = false,
                                 default = nil)
  if valid_607340 != nil:
    section.add "X-Amz-Security-Token", valid_607340
  var valid_607341 = header.getOrDefault("X-Amz-Algorithm")
  valid_607341 = validateParameter(valid_607341, JString, required = false,
                                 default = nil)
  if valid_607341 != nil:
    section.add "X-Amz-Algorithm", valid_607341
  var valid_607342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607342 = validateParameter(valid_607342, JString, required = false,
                                 default = nil)
  if valid_607342 != nil:
    section.add "X-Amz-SignedHeaders", valid_607342
  result.add "header", section
  ## parameters in `formData` object:
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `IpAddressType` field"
  var valid_607343 = formData.getOrDefault("IpAddressType")
  valid_607343 = validateParameter(valid_607343, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_607343 != nil:
    section.add "IpAddressType", valid_607343
  var valid_607344 = formData.getOrDefault("LoadBalancerArn")
  valid_607344 = validateParameter(valid_607344, JString, required = true,
                                 default = nil)
  if valid_607344 != nil:
    section.add "LoadBalancerArn", valid_607344
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607345: Call_PostSetIpAddressType_607331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_607345.validator(path, query, header, formData, body)
  let scheme = call_607345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607345.url(scheme.get, call_607345.host, call_607345.base,
                         call_607345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607345, url, valid)

proc call*(call_607346: Call_PostSetIpAddressType_607331; LoadBalancerArn: string;
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
  var query_607347 = newJObject()
  var formData_607348 = newJObject()
  add(formData_607348, "IpAddressType", newJString(IpAddressType))
  add(query_607347, "Action", newJString(Action))
  add(query_607347, "Version", newJString(Version))
  add(formData_607348, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_607346.call(nil, query_607347, nil, formData_607348, nil)

var postSetIpAddressType* = Call_PostSetIpAddressType_607331(
    name: "postSetIpAddressType", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_PostSetIpAddressType_607332,
    base: "/", url: url_PostSetIpAddressType_607333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetIpAddressType_607314 = ref object of OpenApiRestCall_605589
proc url_GetSetIpAddressType_607316(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetIpAddressType_607315(path: JsonNode; query: JsonNode;
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
  assert query != nil,
        "query argument is necessary due to required `IpAddressType` field"
  var valid_607317 = query.getOrDefault("IpAddressType")
  valid_607317 = validateParameter(valid_607317, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_607317 != nil:
    section.add "IpAddressType", valid_607317
  var valid_607318 = query.getOrDefault("LoadBalancerArn")
  valid_607318 = validateParameter(valid_607318, JString, required = true,
                                 default = nil)
  if valid_607318 != nil:
    section.add "LoadBalancerArn", valid_607318
  var valid_607319 = query.getOrDefault("Action")
  valid_607319 = validateParameter(valid_607319, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_607319 != nil:
    section.add "Action", valid_607319
  var valid_607320 = query.getOrDefault("Version")
  valid_607320 = validateParameter(valid_607320, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607320 != nil:
    section.add "Version", valid_607320
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
  var valid_607321 = header.getOrDefault("X-Amz-Signature")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "X-Amz-Signature", valid_607321
  var valid_607322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "X-Amz-Content-Sha256", valid_607322
  var valid_607323 = header.getOrDefault("X-Amz-Date")
  valid_607323 = validateParameter(valid_607323, JString, required = false,
                                 default = nil)
  if valid_607323 != nil:
    section.add "X-Amz-Date", valid_607323
  var valid_607324 = header.getOrDefault("X-Amz-Credential")
  valid_607324 = validateParameter(valid_607324, JString, required = false,
                                 default = nil)
  if valid_607324 != nil:
    section.add "X-Amz-Credential", valid_607324
  var valid_607325 = header.getOrDefault("X-Amz-Security-Token")
  valid_607325 = validateParameter(valid_607325, JString, required = false,
                                 default = nil)
  if valid_607325 != nil:
    section.add "X-Amz-Security-Token", valid_607325
  var valid_607326 = header.getOrDefault("X-Amz-Algorithm")
  valid_607326 = validateParameter(valid_607326, JString, required = false,
                                 default = nil)
  if valid_607326 != nil:
    section.add "X-Amz-Algorithm", valid_607326
  var valid_607327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607327 = validateParameter(valid_607327, JString, required = false,
                                 default = nil)
  if valid_607327 != nil:
    section.add "X-Amz-SignedHeaders", valid_607327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607328: Call_GetSetIpAddressType_607314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_607328.validator(path, query, header, formData, body)
  let scheme = call_607328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607328.url(scheme.get, call_607328.host, call_607328.base,
                         call_607328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607328, url, valid)

proc call*(call_607329: Call_GetSetIpAddressType_607314; LoadBalancerArn: string;
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
  var query_607330 = newJObject()
  add(query_607330, "IpAddressType", newJString(IpAddressType))
  add(query_607330, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_607330, "Action", newJString(Action))
  add(query_607330, "Version", newJString(Version))
  result = call_607329.call(nil, query_607330, nil, nil, nil)

var getSetIpAddressType* = Call_GetSetIpAddressType_607314(
    name: "getSetIpAddressType", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_GetSetIpAddressType_607315,
    base: "/", url: url_GetSetIpAddressType_607316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetRulePriorities_607365 = ref object of OpenApiRestCall_605589
proc url_PostSetRulePriorities_607367(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetRulePriorities_607366(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607368 = query.getOrDefault("Action")
  valid_607368 = validateParameter(valid_607368, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_607368 != nil:
    section.add "Action", valid_607368
  var valid_607369 = query.getOrDefault("Version")
  valid_607369 = validateParameter(valid_607369, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607369 != nil:
    section.add "Version", valid_607369
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
  var valid_607370 = header.getOrDefault("X-Amz-Signature")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "X-Amz-Signature", valid_607370
  var valid_607371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "X-Amz-Content-Sha256", valid_607371
  var valid_607372 = header.getOrDefault("X-Amz-Date")
  valid_607372 = validateParameter(valid_607372, JString, required = false,
                                 default = nil)
  if valid_607372 != nil:
    section.add "X-Amz-Date", valid_607372
  var valid_607373 = header.getOrDefault("X-Amz-Credential")
  valid_607373 = validateParameter(valid_607373, JString, required = false,
                                 default = nil)
  if valid_607373 != nil:
    section.add "X-Amz-Credential", valid_607373
  var valid_607374 = header.getOrDefault("X-Amz-Security-Token")
  valid_607374 = validateParameter(valid_607374, JString, required = false,
                                 default = nil)
  if valid_607374 != nil:
    section.add "X-Amz-Security-Token", valid_607374
  var valid_607375 = header.getOrDefault("X-Amz-Algorithm")
  valid_607375 = validateParameter(valid_607375, JString, required = false,
                                 default = nil)
  if valid_607375 != nil:
    section.add "X-Amz-Algorithm", valid_607375
  var valid_607376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607376 = validateParameter(valid_607376, JString, required = false,
                                 default = nil)
  if valid_607376 != nil:
    section.add "X-Amz-SignedHeaders", valid_607376
  result.add "header", section
  ## parameters in `formData` object:
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RulePriorities` field"
  var valid_607377 = formData.getOrDefault("RulePriorities")
  valid_607377 = validateParameter(valid_607377, JArray, required = true, default = nil)
  if valid_607377 != nil:
    section.add "RulePriorities", valid_607377
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607378: Call_PostSetRulePriorities_607365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_607378.validator(path, query, header, formData, body)
  let scheme = call_607378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607378.url(scheme.get, call_607378.host, call_607378.base,
                         call_607378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607378, url, valid)

proc call*(call_607379: Call_PostSetRulePriorities_607365;
          RulePriorities: JsonNode; Action: string = "SetRulePriorities";
          Version: string = "2015-12-01"): Recallable =
  ## postSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607380 = newJObject()
  var formData_607381 = newJObject()
  if RulePriorities != nil:
    formData_607381.add "RulePriorities", RulePriorities
  add(query_607380, "Action", newJString(Action))
  add(query_607380, "Version", newJString(Version))
  result = call_607379.call(nil, query_607380, nil, formData_607381, nil)

var postSetRulePriorities* = Call_PostSetRulePriorities_607365(
    name: "postSetRulePriorities", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities",
    validator: validate_PostSetRulePriorities_607366, base: "/",
    url: url_PostSetRulePriorities_607367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetRulePriorities_607349 = ref object of OpenApiRestCall_605589
proc url_GetSetRulePriorities_607351(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetRulePriorities_607350(path: JsonNode; query: JsonNode;
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
  var valid_607352 = query.getOrDefault("RulePriorities")
  valid_607352 = validateParameter(valid_607352, JArray, required = true, default = nil)
  if valid_607352 != nil:
    section.add "RulePriorities", valid_607352
  var valid_607353 = query.getOrDefault("Action")
  valid_607353 = validateParameter(valid_607353, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_607353 != nil:
    section.add "Action", valid_607353
  var valid_607354 = query.getOrDefault("Version")
  valid_607354 = validateParameter(valid_607354, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607354 != nil:
    section.add "Version", valid_607354
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
  var valid_607355 = header.getOrDefault("X-Amz-Signature")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "X-Amz-Signature", valid_607355
  var valid_607356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607356 = validateParameter(valid_607356, JString, required = false,
                                 default = nil)
  if valid_607356 != nil:
    section.add "X-Amz-Content-Sha256", valid_607356
  var valid_607357 = header.getOrDefault("X-Amz-Date")
  valid_607357 = validateParameter(valid_607357, JString, required = false,
                                 default = nil)
  if valid_607357 != nil:
    section.add "X-Amz-Date", valid_607357
  var valid_607358 = header.getOrDefault("X-Amz-Credential")
  valid_607358 = validateParameter(valid_607358, JString, required = false,
                                 default = nil)
  if valid_607358 != nil:
    section.add "X-Amz-Credential", valid_607358
  var valid_607359 = header.getOrDefault("X-Amz-Security-Token")
  valid_607359 = validateParameter(valid_607359, JString, required = false,
                                 default = nil)
  if valid_607359 != nil:
    section.add "X-Amz-Security-Token", valid_607359
  var valid_607360 = header.getOrDefault("X-Amz-Algorithm")
  valid_607360 = validateParameter(valid_607360, JString, required = false,
                                 default = nil)
  if valid_607360 != nil:
    section.add "X-Amz-Algorithm", valid_607360
  var valid_607361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607361 = validateParameter(valid_607361, JString, required = false,
                                 default = nil)
  if valid_607361 != nil:
    section.add "X-Amz-SignedHeaders", valid_607361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607362: Call_GetSetRulePriorities_607349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_607362.validator(path, query, header, formData, body)
  let scheme = call_607362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607362.url(scheme.get, call_607362.host, call_607362.base,
                         call_607362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607362, url, valid)

proc call*(call_607363: Call_GetSetRulePriorities_607349; RulePriorities: JsonNode;
          Action: string = "SetRulePriorities"; Version: string = "2015-12-01"): Recallable =
  ## getSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607364 = newJObject()
  if RulePriorities != nil:
    query_607364.add "RulePriorities", RulePriorities
  add(query_607364, "Action", newJString(Action))
  add(query_607364, "Version", newJString(Version))
  result = call_607363.call(nil, query_607364, nil, nil, nil)

var getSetRulePriorities* = Call_GetSetRulePriorities_607349(
    name: "getSetRulePriorities", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities", validator: validate_GetSetRulePriorities_607350,
    base: "/", url: url_GetSetRulePriorities_607351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSecurityGroups_607399 = ref object of OpenApiRestCall_605589
proc url_PostSetSecurityGroups_607401(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetSecurityGroups_607400(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607402 = query.getOrDefault("Action")
  valid_607402 = validateParameter(valid_607402, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_607402 != nil:
    section.add "Action", valid_607402
  var valid_607403 = query.getOrDefault("Version")
  valid_607403 = validateParameter(valid_607403, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607403 != nil:
    section.add "Version", valid_607403
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
  var valid_607404 = header.getOrDefault("X-Amz-Signature")
  valid_607404 = validateParameter(valid_607404, JString, required = false,
                                 default = nil)
  if valid_607404 != nil:
    section.add "X-Amz-Signature", valid_607404
  var valid_607405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607405 = validateParameter(valid_607405, JString, required = false,
                                 default = nil)
  if valid_607405 != nil:
    section.add "X-Amz-Content-Sha256", valid_607405
  var valid_607406 = header.getOrDefault("X-Amz-Date")
  valid_607406 = validateParameter(valid_607406, JString, required = false,
                                 default = nil)
  if valid_607406 != nil:
    section.add "X-Amz-Date", valid_607406
  var valid_607407 = header.getOrDefault("X-Amz-Credential")
  valid_607407 = validateParameter(valid_607407, JString, required = false,
                                 default = nil)
  if valid_607407 != nil:
    section.add "X-Amz-Credential", valid_607407
  var valid_607408 = header.getOrDefault("X-Amz-Security-Token")
  valid_607408 = validateParameter(valid_607408, JString, required = false,
                                 default = nil)
  if valid_607408 != nil:
    section.add "X-Amz-Security-Token", valid_607408
  var valid_607409 = header.getOrDefault("X-Amz-Algorithm")
  valid_607409 = validateParameter(valid_607409, JString, required = false,
                                 default = nil)
  if valid_607409 != nil:
    section.add "X-Amz-Algorithm", valid_607409
  var valid_607410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607410 = validateParameter(valid_607410, JString, required = false,
                                 default = nil)
  if valid_607410 != nil:
    section.add "X-Amz-SignedHeaders", valid_607410
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_607411 = formData.getOrDefault("SecurityGroups")
  valid_607411 = validateParameter(valid_607411, JArray, required = true, default = nil)
  if valid_607411 != nil:
    section.add "SecurityGroups", valid_607411
  var valid_607412 = formData.getOrDefault("LoadBalancerArn")
  valid_607412 = validateParameter(valid_607412, JString, required = true,
                                 default = nil)
  if valid_607412 != nil:
    section.add "LoadBalancerArn", valid_607412
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607413: Call_PostSetSecurityGroups_607399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_607413.validator(path, query, header, formData, body)
  let scheme = call_607413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607413.url(scheme.get, call_607413.host, call_607413.base,
                         call_607413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607413, url, valid)

proc call*(call_607414: Call_PostSetSecurityGroups_607399;
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
  var query_607415 = newJObject()
  var formData_607416 = newJObject()
  if SecurityGroups != nil:
    formData_607416.add "SecurityGroups", SecurityGroups
  add(query_607415, "Action", newJString(Action))
  add(query_607415, "Version", newJString(Version))
  add(formData_607416, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_607414.call(nil, query_607415, nil, formData_607416, nil)

var postSetSecurityGroups* = Call_PostSetSecurityGroups_607399(
    name: "postSetSecurityGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups",
    validator: validate_PostSetSecurityGroups_607400, base: "/",
    url: url_PostSetSecurityGroups_607401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSecurityGroups_607382 = ref object of OpenApiRestCall_605589
proc url_GetSetSecurityGroups_607384(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetSecurityGroups_607383(path: JsonNode; query: JsonNode;
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
  var valid_607385 = query.getOrDefault("LoadBalancerArn")
  valid_607385 = validateParameter(valid_607385, JString, required = true,
                                 default = nil)
  if valid_607385 != nil:
    section.add "LoadBalancerArn", valid_607385
  var valid_607386 = query.getOrDefault("SecurityGroups")
  valid_607386 = validateParameter(valid_607386, JArray, required = true, default = nil)
  if valid_607386 != nil:
    section.add "SecurityGroups", valid_607386
  var valid_607387 = query.getOrDefault("Action")
  valid_607387 = validateParameter(valid_607387, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_607387 != nil:
    section.add "Action", valid_607387
  var valid_607388 = query.getOrDefault("Version")
  valid_607388 = validateParameter(valid_607388, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607388 != nil:
    section.add "Version", valid_607388
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
  var valid_607389 = header.getOrDefault("X-Amz-Signature")
  valid_607389 = validateParameter(valid_607389, JString, required = false,
                                 default = nil)
  if valid_607389 != nil:
    section.add "X-Amz-Signature", valid_607389
  var valid_607390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607390 = validateParameter(valid_607390, JString, required = false,
                                 default = nil)
  if valid_607390 != nil:
    section.add "X-Amz-Content-Sha256", valid_607390
  var valid_607391 = header.getOrDefault("X-Amz-Date")
  valid_607391 = validateParameter(valid_607391, JString, required = false,
                                 default = nil)
  if valid_607391 != nil:
    section.add "X-Amz-Date", valid_607391
  var valid_607392 = header.getOrDefault("X-Amz-Credential")
  valid_607392 = validateParameter(valid_607392, JString, required = false,
                                 default = nil)
  if valid_607392 != nil:
    section.add "X-Amz-Credential", valid_607392
  var valid_607393 = header.getOrDefault("X-Amz-Security-Token")
  valid_607393 = validateParameter(valid_607393, JString, required = false,
                                 default = nil)
  if valid_607393 != nil:
    section.add "X-Amz-Security-Token", valid_607393
  var valid_607394 = header.getOrDefault("X-Amz-Algorithm")
  valid_607394 = validateParameter(valid_607394, JString, required = false,
                                 default = nil)
  if valid_607394 != nil:
    section.add "X-Amz-Algorithm", valid_607394
  var valid_607395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607395 = validateParameter(valid_607395, JString, required = false,
                                 default = nil)
  if valid_607395 != nil:
    section.add "X-Amz-SignedHeaders", valid_607395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607396: Call_GetSetSecurityGroups_607382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_607396.validator(path, query, header, formData, body)
  let scheme = call_607396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607396.url(scheme.get, call_607396.host, call_607396.base,
                         call_607396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607396, url, valid)

proc call*(call_607397: Call_GetSetSecurityGroups_607382; LoadBalancerArn: string;
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
  var query_607398 = newJObject()
  add(query_607398, "LoadBalancerArn", newJString(LoadBalancerArn))
  if SecurityGroups != nil:
    query_607398.add "SecurityGroups", SecurityGroups
  add(query_607398, "Action", newJString(Action))
  add(query_607398, "Version", newJString(Version))
  result = call_607397.call(nil, query_607398, nil, nil, nil)

var getSetSecurityGroups* = Call_GetSetSecurityGroups_607382(
    name: "getSetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups", validator: validate_GetSetSecurityGroups_607383,
    base: "/", url: url_GetSetSecurityGroups_607384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubnets_607435 = ref object of OpenApiRestCall_605589
proc url_PostSetSubnets_607437(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetSubnets_607436(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607438 = query.getOrDefault("Action")
  valid_607438 = validateParameter(valid_607438, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_607438 != nil:
    section.add "Action", valid_607438
  var valid_607439 = query.getOrDefault("Version")
  valid_607439 = validateParameter(valid_607439, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607439 != nil:
    section.add "Version", valid_607439
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
  var valid_607440 = header.getOrDefault("X-Amz-Signature")
  valid_607440 = validateParameter(valid_607440, JString, required = false,
                                 default = nil)
  if valid_607440 != nil:
    section.add "X-Amz-Signature", valid_607440
  var valid_607441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607441 = validateParameter(valid_607441, JString, required = false,
                                 default = nil)
  if valid_607441 != nil:
    section.add "X-Amz-Content-Sha256", valid_607441
  var valid_607442 = header.getOrDefault("X-Amz-Date")
  valid_607442 = validateParameter(valid_607442, JString, required = false,
                                 default = nil)
  if valid_607442 != nil:
    section.add "X-Amz-Date", valid_607442
  var valid_607443 = header.getOrDefault("X-Amz-Credential")
  valid_607443 = validateParameter(valid_607443, JString, required = false,
                                 default = nil)
  if valid_607443 != nil:
    section.add "X-Amz-Credential", valid_607443
  var valid_607444 = header.getOrDefault("X-Amz-Security-Token")
  valid_607444 = validateParameter(valid_607444, JString, required = false,
                                 default = nil)
  if valid_607444 != nil:
    section.add "X-Amz-Security-Token", valid_607444
  var valid_607445 = header.getOrDefault("X-Amz-Algorithm")
  valid_607445 = validateParameter(valid_607445, JString, required = false,
                                 default = nil)
  if valid_607445 != nil:
    section.add "X-Amz-Algorithm", valid_607445
  var valid_607446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607446 = validateParameter(valid_607446, JString, required = false,
                                 default = nil)
  if valid_607446 != nil:
    section.add "X-Amz-SignedHeaders", valid_607446
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. If you need static IP addresses for your internet-facing load balancer, you can specify one Elastic IP address per subnet. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  var valid_607447 = formData.getOrDefault("Subnets")
  valid_607447 = validateParameter(valid_607447, JArray, required = false,
                                 default = nil)
  if valid_607447 != nil:
    section.add "Subnets", valid_607447
  var valid_607448 = formData.getOrDefault("SubnetMappings")
  valid_607448 = validateParameter(valid_607448, JArray, required = false,
                                 default = nil)
  if valid_607448 != nil:
    section.add "SubnetMappings", valid_607448
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_607449 = formData.getOrDefault("LoadBalancerArn")
  valid_607449 = validateParameter(valid_607449, JString, required = true,
                                 default = nil)
  if valid_607449 != nil:
    section.add "LoadBalancerArn", valid_607449
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607450: Call_PostSetSubnets_607435; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ## 
  let valid = call_607450.validator(path, query, header, formData, body)
  let scheme = call_607450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607450.url(scheme.get, call_607450.host, call_607450.base,
                         call_607450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607450, url, valid)

proc call*(call_607451: Call_PostSetSubnets_607435; LoadBalancerArn: string;
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
  var query_607452 = newJObject()
  var formData_607453 = newJObject()
  if Subnets != nil:
    formData_607453.add "Subnets", Subnets
  add(query_607452, "Action", newJString(Action))
  if SubnetMappings != nil:
    formData_607453.add "SubnetMappings", SubnetMappings
  add(query_607452, "Version", newJString(Version))
  add(formData_607453, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_607451.call(nil, query_607452, nil, formData_607453, nil)

var postSetSubnets* = Call_PostSetSubnets_607435(name: "postSetSubnets",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_PostSetSubnets_607436,
    base: "/", url: url_PostSetSubnets_607437, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubnets_607417 = ref object of OpenApiRestCall_605589
proc url_GetSetSubnets_607419(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetSubnets_607418(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607420 = query.getOrDefault("SubnetMappings")
  valid_607420 = validateParameter(valid_607420, JArray, required = false,
                                 default = nil)
  if valid_607420 != nil:
    section.add "SubnetMappings", valid_607420
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_607421 = query.getOrDefault("LoadBalancerArn")
  valid_607421 = validateParameter(valid_607421, JString, required = true,
                                 default = nil)
  if valid_607421 != nil:
    section.add "LoadBalancerArn", valid_607421
  var valid_607422 = query.getOrDefault("Action")
  valid_607422 = validateParameter(valid_607422, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_607422 != nil:
    section.add "Action", valid_607422
  var valid_607423 = query.getOrDefault("Subnets")
  valid_607423 = validateParameter(valid_607423, JArray, required = false,
                                 default = nil)
  if valid_607423 != nil:
    section.add "Subnets", valid_607423
  var valid_607424 = query.getOrDefault("Version")
  valid_607424 = validateParameter(valid_607424, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_607424 != nil:
    section.add "Version", valid_607424
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
  var valid_607425 = header.getOrDefault("X-Amz-Signature")
  valid_607425 = validateParameter(valid_607425, JString, required = false,
                                 default = nil)
  if valid_607425 != nil:
    section.add "X-Amz-Signature", valid_607425
  var valid_607426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607426 = validateParameter(valid_607426, JString, required = false,
                                 default = nil)
  if valid_607426 != nil:
    section.add "X-Amz-Content-Sha256", valid_607426
  var valid_607427 = header.getOrDefault("X-Amz-Date")
  valid_607427 = validateParameter(valid_607427, JString, required = false,
                                 default = nil)
  if valid_607427 != nil:
    section.add "X-Amz-Date", valid_607427
  var valid_607428 = header.getOrDefault("X-Amz-Credential")
  valid_607428 = validateParameter(valid_607428, JString, required = false,
                                 default = nil)
  if valid_607428 != nil:
    section.add "X-Amz-Credential", valid_607428
  var valid_607429 = header.getOrDefault("X-Amz-Security-Token")
  valid_607429 = validateParameter(valid_607429, JString, required = false,
                                 default = nil)
  if valid_607429 != nil:
    section.add "X-Amz-Security-Token", valid_607429
  var valid_607430 = header.getOrDefault("X-Amz-Algorithm")
  valid_607430 = validateParameter(valid_607430, JString, required = false,
                                 default = nil)
  if valid_607430 != nil:
    section.add "X-Amz-Algorithm", valid_607430
  var valid_607431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607431 = validateParameter(valid_607431, JString, required = false,
                                 default = nil)
  if valid_607431 != nil:
    section.add "X-Amz-SignedHeaders", valid_607431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607432: Call_GetSetSubnets_607417; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ## 
  let valid = call_607432.validator(path, query, header, formData, body)
  let scheme = call_607432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607432.url(scheme.get, call_607432.host, call_607432.base,
                         call_607432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607432, url, valid)

proc call*(call_607433: Call_GetSetSubnets_607417; LoadBalancerArn: string;
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
  var query_607434 = newJObject()
  if SubnetMappings != nil:
    query_607434.add "SubnetMappings", SubnetMappings
  add(query_607434, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_607434, "Action", newJString(Action))
  if Subnets != nil:
    query_607434.add "Subnets", Subnets
  add(query_607434, "Version", newJString(Version))
  result = call_607433.call(nil, query_607434, nil, nil, nil)

var getSetSubnets* = Call_GetSetSubnets_607417(name: "getSetSubnets",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_GetSetSubnets_607418,
    base: "/", url: url_GetSetSubnets_607419, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
