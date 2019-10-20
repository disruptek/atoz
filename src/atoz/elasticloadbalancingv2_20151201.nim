
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddListenerCertificates_592975 = ref object of OpenApiRestCall_592364
proc url_PostAddListenerCertificates_592977(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddListenerCertificates_592976(path: JsonNode; query: JsonNode;
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
  var valid_592978 = query.getOrDefault("Action")
  valid_592978 = validateParameter(valid_592978, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_592978 != nil:
    section.add "Action", valid_592978
  var valid_592979 = query.getOrDefault("Version")
  valid_592979 = validateParameter(valid_592979, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_592979 != nil:
    section.add "Version", valid_592979
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
  var valid_592980 = header.getOrDefault("X-Amz-Signature")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Signature", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Content-Sha256", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Date")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Date", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Credential")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Credential", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Security-Token")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Security-Token", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Algorithm")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Algorithm", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-SignedHeaders", valid_592986
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_592987 = formData.getOrDefault("Certificates")
  valid_592987 = validateParameter(valid_592987, JArray, required = true, default = nil)
  if valid_592987 != nil:
    section.add "Certificates", valid_592987
  var valid_592988 = formData.getOrDefault("ListenerArn")
  valid_592988 = validateParameter(valid_592988, JString, required = true,
                                 default = nil)
  if valid_592988 != nil:
    section.add "ListenerArn", valid_592988
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592989: Call_PostAddListenerCertificates_592975; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_592989.validator(path, query, header, formData, body)
  let scheme = call_592989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592989.url(scheme.get, call_592989.host, call_592989.base,
                         call_592989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592989, url, valid)

proc call*(call_592990: Call_PostAddListenerCertificates_592975;
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
  var query_592991 = newJObject()
  var formData_592992 = newJObject()
  if Certificates != nil:
    formData_592992.add "Certificates", Certificates
  add(formData_592992, "ListenerArn", newJString(ListenerArn))
  add(query_592991, "Action", newJString(Action))
  add(query_592991, "Version", newJString(Version))
  result = call_592990.call(nil, query_592991, nil, formData_592992, nil)

var postAddListenerCertificates* = Call_PostAddListenerCertificates_592975(
    name: "postAddListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_PostAddListenerCertificates_592976, base: "/",
    url: url_PostAddListenerCertificates_592977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddListenerCertificates_592703 = ref object of OpenApiRestCall_592364
proc url_GetAddListenerCertificates_592705(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddListenerCertificates_592704(path: JsonNode; query: JsonNode;
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
  var valid_592817 = query.getOrDefault("ListenerArn")
  valid_592817 = validateParameter(valid_592817, JString, required = true,
                                 default = nil)
  if valid_592817 != nil:
    section.add "ListenerArn", valid_592817
  var valid_592818 = query.getOrDefault("Certificates")
  valid_592818 = validateParameter(valid_592818, JArray, required = true, default = nil)
  if valid_592818 != nil:
    section.add "Certificates", valid_592818
  var valid_592832 = query.getOrDefault("Action")
  valid_592832 = validateParameter(valid_592832, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_592832 != nil:
    section.add "Action", valid_592832
  var valid_592833 = query.getOrDefault("Version")
  valid_592833 = validateParameter(valid_592833, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_592833 != nil:
    section.add "Version", valid_592833
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
  var valid_592834 = header.getOrDefault("X-Amz-Signature")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Signature", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Content-Sha256", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Date")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Date", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Credential")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Credential", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-Security-Token")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-Security-Token", valid_592838
  var valid_592839 = header.getOrDefault("X-Amz-Algorithm")
  valid_592839 = validateParameter(valid_592839, JString, required = false,
                                 default = nil)
  if valid_592839 != nil:
    section.add "X-Amz-Algorithm", valid_592839
  var valid_592840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592840 = validateParameter(valid_592840, JString, required = false,
                                 default = nil)
  if valid_592840 != nil:
    section.add "X-Amz-SignedHeaders", valid_592840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592863: Call_GetAddListenerCertificates_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_592863.validator(path, query, header, formData, body)
  let scheme = call_592863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592863.url(scheme.get, call_592863.host, call_592863.base,
                         call_592863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592863, url, valid)

proc call*(call_592934: Call_GetAddListenerCertificates_592703;
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
  var query_592935 = newJObject()
  add(query_592935, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_592935.add "Certificates", Certificates
  add(query_592935, "Action", newJString(Action))
  add(query_592935, "Version", newJString(Version))
  result = call_592934.call(nil, query_592935, nil, nil, nil)

var getAddListenerCertificates* = Call_GetAddListenerCertificates_592703(
    name: "getAddListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_GetAddListenerCertificates_592704, base: "/",
    url: url_GetAddListenerCertificates_592705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTags_593010 = ref object of OpenApiRestCall_592364
proc url_PostAddTags_593012(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTags_593011(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593013 = query.getOrDefault("Action")
  valid_593013 = validateParameter(valid_593013, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_593013 != nil:
    section.add "Action", valid_593013
  var valid_593014 = query.getOrDefault("Version")
  valid_593014 = validateParameter(valid_593014, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593014 != nil:
    section.add "Version", valid_593014
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
  var valid_593015 = header.getOrDefault("X-Amz-Signature")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Signature", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Content-Sha256", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Date")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Date", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Credential")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Credential", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Security-Token")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Security-Token", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Algorithm")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Algorithm", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-SignedHeaders", valid_593021
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_593022 = formData.getOrDefault("ResourceArns")
  valid_593022 = validateParameter(valid_593022, JArray, required = true, default = nil)
  if valid_593022 != nil:
    section.add "ResourceArns", valid_593022
  var valid_593023 = formData.getOrDefault("Tags")
  valid_593023 = validateParameter(valid_593023, JArray, required = true, default = nil)
  if valid_593023 != nil:
    section.add "Tags", valid_593023
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593024: Call_PostAddTags_593010; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_593024.validator(path, query, header, formData, body)
  let scheme = call_593024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593024.url(scheme.get, call_593024.host, call_593024.base,
                         call_593024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593024, url, valid)

proc call*(call_593025: Call_PostAddTags_593010; ResourceArns: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2015-12-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Version: string (required)
  var query_593026 = newJObject()
  var formData_593027 = newJObject()
  if ResourceArns != nil:
    formData_593027.add "ResourceArns", ResourceArns
  add(query_593026, "Action", newJString(Action))
  if Tags != nil:
    formData_593027.add "Tags", Tags
  add(query_593026, "Version", newJString(Version))
  result = call_593025.call(nil, query_593026, nil, formData_593027, nil)

var postAddTags* = Call_PostAddTags_593010(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_593011,
                                        base: "/", url: url_PostAddTags_593012,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_592993 = ref object of OpenApiRestCall_592364
proc url_GetAddTags_592995(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTags_592994(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592996 = query.getOrDefault("Tags")
  valid_592996 = validateParameter(valid_592996, JArray, required = true, default = nil)
  if valid_592996 != nil:
    section.add "Tags", valid_592996
  var valid_592997 = query.getOrDefault("ResourceArns")
  valid_592997 = validateParameter(valid_592997, JArray, required = true, default = nil)
  if valid_592997 != nil:
    section.add "ResourceArns", valid_592997
  var valid_592998 = query.getOrDefault("Action")
  valid_592998 = validateParameter(valid_592998, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_592998 != nil:
    section.add "Action", valid_592998
  var valid_592999 = query.getOrDefault("Version")
  valid_592999 = validateParameter(valid_592999, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_592999 != nil:
    section.add "Version", valid_592999
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
  var valid_593000 = header.getOrDefault("X-Amz-Signature")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Signature", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Content-Sha256", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Date")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Date", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Credential")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Credential", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Security-Token")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Security-Token", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Algorithm")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Algorithm", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-SignedHeaders", valid_593006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593007: Call_GetAddTags_592993; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_593007.validator(path, query, header, formData, body)
  let scheme = call_593007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593007.url(scheme.get, call_593007.host, call_593007.base,
                         call_593007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593007, url, valid)

proc call*(call_593008: Call_GetAddTags_592993; Tags: JsonNode;
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
  var query_593009 = newJObject()
  if Tags != nil:
    query_593009.add "Tags", Tags
  if ResourceArns != nil:
    query_593009.add "ResourceArns", ResourceArns
  add(query_593009, "Action", newJString(Action))
  add(query_593009, "Version", newJString(Version))
  result = call_593008.call(nil, query_593009, nil, nil, nil)

var getAddTags* = Call_GetAddTags_592993(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_592994,
                                      base: "/", url: url_GetAddTags_592995,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateListener_593049 = ref object of OpenApiRestCall_592364
proc url_PostCreateListener_593051(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateListener_593050(path: JsonNode; query: JsonNode;
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
  var valid_593052 = query.getOrDefault("Action")
  valid_593052 = validateParameter(valid_593052, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_593052 != nil:
    section.add "Action", valid_593052
  var valid_593053 = query.getOrDefault("Version")
  valid_593053 = validateParameter(valid_593053, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593053 != nil:
    section.add "Version", valid_593053
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
  var valid_593054 = header.getOrDefault("X-Amz-Signature")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Signature", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Content-Sha256", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Date")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Date", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Credential")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Credential", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-Security-Token")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-Security-Token", valid_593058
  var valid_593059 = header.getOrDefault("X-Amz-Algorithm")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Algorithm", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-SignedHeaders", valid_593060
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt (required)
  ##       : The port on which the load balancer is listening.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list for the listener, use <a>AddListenerCertificates</a>.</p>
  ##   DefaultActions: JArray (required)
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Protocol: JString (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   SslPolicy: JString
  ##            : [HTTPS and TLS listeners] The security policy that defines which ciphers and protocols are supported. The default is the current predefined security policy.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Port` field"
  var valid_593061 = formData.getOrDefault("Port")
  valid_593061 = validateParameter(valid_593061, JInt, required = true, default = nil)
  if valid_593061 != nil:
    section.add "Port", valid_593061
  var valid_593062 = formData.getOrDefault("Certificates")
  valid_593062 = validateParameter(valid_593062, JArray, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "Certificates", valid_593062
  var valid_593063 = formData.getOrDefault("DefaultActions")
  valid_593063 = validateParameter(valid_593063, JArray, required = true, default = nil)
  if valid_593063 != nil:
    section.add "DefaultActions", valid_593063
  var valid_593064 = formData.getOrDefault("Protocol")
  valid_593064 = validateParameter(valid_593064, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_593064 != nil:
    section.add "Protocol", valid_593064
  var valid_593065 = formData.getOrDefault("SslPolicy")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "SslPolicy", valid_593065
  var valid_593066 = formData.getOrDefault("LoadBalancerArn")
  valid_593066 = validateParameter(valid_593066, JString, required = true,
                                 default = nil)
  if valid_593066 != nil:
    section.add "LoadBalancerArn", valid_593066
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593067: Call_PostCreateListener_593049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593067.validator(path, query, header, formData, body)
  let scheme = call_593067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593067.url(scheme.get, call_593067.host, call_593067.base,
                         call_593067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593067, url, valid)

proc call*(call_593068: Call_PostCreateListener_593049; Port: int;
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
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Protocol: string (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   Action: string (required)
  ##   SslPolicy: string
  ##            : [HTTPS and TLS listeners] The security policy that defines which ciphers and protocols are supported. The default is the current predefined security policy.
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_593069 = newJObject()
  var formData_593070 = newJObject()
  add(formData_593070, "Port", newJInt(Port))
  if Certificates != nil:
    formData_593070.add "Certificates", Certificates
  if DefaultActions != nil:
    formData_593070.add "DefaultActions", DefaultActions
  add(formData_593070, "Protocol", newJString(Protocol))
  add(query_593069, "Action", newJString(Action))
  add(formData_593070, "SslPolicy", newJString(SslPolicy))
  add(query_593069, "Version", newJString(Version))
  add(formData_593070, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_593068.call(nil, query_593069, nil, formData_593070, nil)

var postCreateListener* = Call_PostCreateListener_593049(
    name: "postCreateListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=CreateListener",
    validator: validate_PostCreateListener_593050, base: "/",
    url: url_PostCreateListener_593051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateListener_593028 = ref object of OpenApiRestCall_592364
proc url_GetCreateListener_593030(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateListener_593029(path: JsonNode; query: JsonNode;
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
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Action: JString (required)
  ##   Protocol: JString (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   Port: JInt (required)
  ##       : The port on which the load balancer is listening.
  ##   Version: JString (required)
  section = newJObject()
  var valid_593031 = query.getOrDefault("SslPolicy")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "SslPolicy", valid_593031
  var valid_593032 = query.getOrDefault("Certificates")
  valid_593032 = validateParameter(valid_593032, JArray, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "Certificates", valid_593032
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_593033 = query.getOrDefault("LoadBalancerArn")
  valid_593033 = validateParameter(valid_593033, JString, required = true,
                                 default = nil)
  if valid_593033 != nil:
    section.add "LoadBalancerArn", valid_593033
  var valid_593034 = query.getOrDefault("DefaultActions")
  valid_593034 = validateParameter(valid_593034, JArray, required = true, default = nil)
  if valid_593034 != nil:
    section.add "DefaultActions", valid_593034
  var valid_593035 = query.getOrDefault("Action")
  valid_593035 = validateParameter(valid_593035, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_593035 != nil:
    section.add "Action", valid_593035
  var valid_593036 = query.getOrDefault("Protocol")
  valid_593036 = validateParameter(valid_593036, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_593036 != nil:
    section.add "Protocol", valid_593036
  var valid_593037 = query.getOrDefault("Port")
  valid_593037 = validateParameter(valid_593037, JInt, required = true, default = nil)
  if valid_593037 != nil:
    section.add "Port", valid_593037
  var valid_593038 = query.getOrDefault("Version")
  valid_593038 = validateParameter(valid_593038, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593038 != nil:
    section.add "Version", valid_593038
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
  var valid_593039 = header.getOrDefault("X-Amz-Signature")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Signature", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Content-Sha256", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Date")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Date", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Credential")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Credential", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-Security-Token")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-Security-Token", valid_593043
  var valid_593044 = header.getOrDefault("X-Amz-Algorithm")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Algorithm", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-SignedHeaders", valid_593045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593046: Call_GetCreateListener_593028; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593046.validator(path, query, header, formData, body)
  let scheme = call_593046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593046.url(scheme.get, call_593046.host, call_593046.base,
                         call_593046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593046, url, valid)

proc call*(call_593047: Call_GetCreateListener_593028; LoadBalancerArn: string;
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
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Action: string (required)
  ##   Protocol: string (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   Port: int (required)
  ##       : The port on which the load balancer is listening.
  ##   Version: string (required)
  var query_593048 = newJObject()
  add(query_593048, "SslPolicy", newJString(SslPolicy))
  if Certificates != nil:
    query_593048.add "Certificates", Certificates
  add(query_593048, "LoadBalancerArn", newJString(LoadBalancerArn))
  if DefaultActions != nil:
    query_593048.add "DefaultActions", DefaultActions
  add(query_593048, "Action", newJString(Action))
  add(query_593048, "Protocol", newJString(Protocol))
  add(query_593048, "Port", newJInt(Port))
  add(query_593048, "Version", newJString(Version))
  result = call_593047.call(nil, query_593048, nil, nil, nil)

var getCreateListener* = Call_GetCreateListener_593028(name: "getCreateListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateListener", validator: validate_GetCreateListener_593029,
    base: "/", url: url_GetCreateListener_593030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_593094 = ref object of OpenApiRestCall_592364
proc url_PostCreateLoadBalancer_593096(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateLoadBalancer_593095(path: JsonNode; query: JsonNode;
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
  var valid_593097 = query.getOrDefault("Action")
  valid_593097 = validateParameter(valid_593097, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_593097 != nil:
    section.add "Action", valid_593097
  var valid_593098 = query.getOrDefault("Version")
  valid_593098 = validateParameter(valid_593098, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593098 != nil:
    section.add "Version", valid_593098
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
  var valid_593099 = header.getOrDefault("X-Amz-Signature")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Signature", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Content-Sha256", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Date")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Date", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Credential")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Credential", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-Security-Token")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Security-Token", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Algorithm")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Algorithm", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-SignedHeaders", valid_593105
  result.add "header", section
  ## parameters in `formData` object:
  ##   IpAddressType: JString
  ##                : [Application Load Balancers] The type of IP addresses used by the subnets for your load balancer. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>.
  ##   Scheme: JString
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can only route requests from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
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
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your load balancer.</p>
  section = newJObject()
  var valid_593106 = formData.getOrDefault("IpAddressType")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_593106 != nil:
    section.add "IpAddressType", valid_593106
  var valid_593107 = formData.getOrDefault("Scheme")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_593107 != nil:
    section.add "Scheme", valid_593107
  var valid_593108 = formData.getOrDefault("SecurityGroups")
  valid_593108 = validateParameter(valid_593108, JArray, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "SecurityGroups", valid_593108
  var valid_593109 = formData.getOrDefault("Subnets")
  valid_593109 = validateParameter(valid_593109, JArray, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "Subnets", valid_593109
  var valid_593110 = formData.getOrDefault("Type")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = newJString("application"))
  if valid_593110 != nil:
    section.add "Type", valid_593110
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_593111 = formData.getOrDefault("Name")
  valid_593111 = validateParameter(valid_593111, JString, required = true,
                                 default = nil)
  if valid_593111 != nil:
    section.add "Name", valid_593111
  var valid_593112 = formData.getOrDefault("Tags")
  valid_593112 = validateParameter(valid_593112, JArray, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "Tags", valid_593112
  var valid_593113 = formData.getOrDefault("SubnetMappings")
  valid_593113 = validateParameter(valid_593113, JArray, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "SubnetMappings", valid_593113
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593114: Call_PostCreateLoadBalancer_593094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593114.validator(path, query, header, formData, body)
  let scheme = call_593114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593114.url(scheme.get, call_593114.host, call_593114.base,
                         call_593114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593114, url, valid)

proc call*(call_593115: Call_PostCreateLoadBalancer_593094; Name: string;
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
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can only route requests from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
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
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your load balancer.</p>
  ##   Version: string (required)
  var query_593116 = newJObject()
  var formData_593117 = newJObject()
  add(formData_593117, "IpAddressType", newJString(IpAddressType))
  add(formData_593117, "Scheme", newJString(Scheme))
  if SecurityGroups != nil:
    formData_593117.add "SecurityGroups", SecurityGroups
  if Subnets != nil:
    formData_593117.add "Subnets", Subnets
  add(formData_593117, "Type", newJString(Type))
  add(query_593116, "Action", newJString(Action))
  add(formData_593117, "Name", newJString(Name))
  if Tags != nil:
    formData_593117.add "Tags", Tags
  if SubnetMappings != nil:
    formData_593117.add "SubnetMappings", SubnetMappings
  add(query_593116, "Version", newJString(Version))
  result = call_593115.call(nil, query_593116, nil, formData_593117, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_593094(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_593095, base: "/",
    url: url_PostCreateLoadBalancer_593096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_593071 = ref object of OpenApiRestCall_592364
proc url_GetCreateLoadBalancer_593073(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateLoadBalancer_593072(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your load balancer.</p>
  ##   Type: JString
  ##       : The type of load balancer. The default is <code>application</code>.
  ##   Tags: JArray
  ##       : One or more tags to assign to the load balancer.
  ##   Scheme: JString
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can only route requests from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
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
  var valid_593074 = query.getOrDefault("SubnetMappings")
  valid_593074 = validateParameter(valid_593074, JArray, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "SubnetMappings", valid_593074
  var valid_593075 = query.getOrDefault("Type")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = newJString("application"))
  if valid_593075 != nil:
    section.add "Type", valid_593075
  var valid_593076 = query.getOrDefault("Tags")
  valid_593076 = validateParameter(valid_593076, JArray, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "Tags", valid_593076
  var valid_593077 = query.getOrDefault("Scheme")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_593077 != nil:
    section.add "Scheme", valid_593077
  var valid_593078 = query.getOrDefault("IpAddressType")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_593078 != nil:
    section.add "IpAddressType", valid_593078
  var valid_593079 = query.getOrDefault("SecurityGroups")
  valid_593079 = validateParameter(valid_593079, JArray, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "SecurityGroups", valid_593079
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_593080 = query.getOrDefault("Name")
  valid_593080 = validateParameter(valid_593080, JString, required = true,
                                 default = nil)
  if valid_593080 != nil:
    section.add "Name", valid_593080
  var valid_593081 = query.getOrDefault("Action")
  valid_593081 = validateParameter(valid_593081, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_593081 != nil:
    section.add "Action", valid_593081
  var valid_593082 = query.getOrDefault("Subnets")
  valid_593082 = validateParameter(valid_593082, JArray, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "Subnets", valid_593082
  var valid_593083 = query.getOrDefault("Version")
  valid_593083 = validateParameter(valid_593083, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593083 != nil:
    section.add "Version", valid_593083
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
  var valid_593084 = header.getOrDefault("X-Amz-Signature")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Signature", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Content-Sha256", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Date")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Date", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Credential")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Credential", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Security-Token")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Security-Token", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-Algorithm")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Algorithm", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-SignedHeaders", valid_593090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593091: Call_GetCreateLoadBalancer_593071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593091.validator(path, query, header, formData, body)
  let scheme = call_593091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593091.url(scheme.get, call_593091.host, call_593091.base,
                         call_593091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593091, url, valid)

proc call*(call_593092: Call_GetCreateLoadBalancer_593071; Name: string;
          SubnetMappings: JsonNode = nil; Type: string = "application";
          Tags: JsonNode = nil; Scheme: string = "internet-facing";
          IpAddressType: string = "ipv4"; SecurityGroups: JsonNode = nil;
          Action: string = "CreateLoadBalancer"; Subnets: JsonNode = nil;
          Version: string = "2015-12-01"): Recallable =
  ## getCreateLoadBalancer
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your load balancer.</p>
  ##   Type: string
  ##       : The type of load balancer. The default is <code>application</code>.
  ##   Tags: JArray
  ##       : One or more tags to assign to the load balancer.
  ##   Scheme: string
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can only route requests from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
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
  var query_593093 = newJObject()
  if SubnetMappings != nil:
    query_593093.add "SubnetMappings", SubnetMappings
  add(query_593093, "Type", newJString(Type))
  if Tags != nil:
    query_593093.add "Tags", Tags
  add(query_593093, "Scheme", newJString(Scheme))
  add(query_593093, "IpAddressType", newJString(IpAddressType))
  if SecurityGroups != nil:
    query_593093.add "SecurityGroups", SecurityGroups
  add(query_593093, "Name", newJString(Name))
  add(query_593093, "Action", newJString(Action))
  if Subnets != nil:
    query_593093.add "Subnets", Subnets
  add(query_593093, "Version", newJString(Version))
  result = call_593092.call(nil, query_593093, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_593071(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_593072, base: "/",
    url: url_GetCreateLoadBalancer_593073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateRule_593137 = ref object of OpenApiRestCall_592364
proc url_PostCreateRule_593139(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateRule_593138(path: JsonNode; query: JsonNode;
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
  var valid_593140 = query.getOrDefault("Action")
  valid_593140 = validateParameter(valid_593140, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_593140 != nil:
    section.add "Action", valid_593140
  var valid_593141 = query.getOrDefault("Version")
  valid_593141 = validateParameter(valid_593141, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593141 != nil:
    section.add "Version", valid_593141
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
  var valid_593142 = header.getOrDefault("X-Amz-Signature")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Signature", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Content-Sha256", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Date")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Date", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Credential")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Credential", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Security-Token")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Security-Token", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-Algorithm")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-Algorithm", valid_593147
  var valid_593148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-SignedHeaders", valid_593148
  result.add "header", section
  ## parameters in `formData` object:
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Priority: JInt (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Actions` field"
  var valid_593149 = formData.getOrDefault("Actions")
  valid_593149 = validateParameter(valid_593149, JArray, required = true, default = nil)
  if valid_593149 != nil:
    section.add "Actions", valid_593149
  var valid_593150 = formData.getOrDefault("Conditions")
  valid_593150 = validateParameter(valid_593150, JArray, required = true, default = nil)
  if valid_593150 != nil:
    section.add "Conditions", valid_593150
  var valid_593151 = formData.getOrDefault("ListenerArn")
  valid_593151 = validateParameter(valid_593151, JString, required = true,
                                 default = nil)
  if valid_593151 != nil:
    section.add "ListenerArn", valid_593151
  var valid_593152 = formData.getOrDefault("Priority")
  valid_593152 = validateParameter(valid_593152, JInt, required = true, default = nil)
  if valid_593152 != nil:
    section.add "Priority", valid_593152
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593153: Call_PostCreateRule_593137; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_593153.validator(path, query, header, formData, body)
  let scheme = call_593153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593153.url(scheme.get, call_593153.host, call_593153.base,
                         call_593153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593153, url, valid)

proc call*(call_593154: Call_PostCreateRule_593137; Actions: JsonNode;
          Conditions: JsonNode; ListenerArn: string; Priority: int;
          Action: string = "CreateRule"; Version: string = "2015-12-01"): Recallable =
  ## postCreateRule
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Priority: int (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593155 = newJObject()
  var formData_593156 = newJObject()
  if Actions != nil:
    formData_593156.add "Actions", Actions
  if Conditions != nil:
    formData_593156.add "Conditions", Conditions
  add(formData_593156, "ListenerArn", newJString(ListenerArn))
  add(formData_593156, "Priority", newJInt(Priority))
  add(query_593155, "Action", newJString(Action))
  add(query_593155, "Version", newJString(Version))
  result = call_593154.call(nil, query_593155, nil, formData_593156, nil)

var postCreateRule* = Call_PostCreateRule_593137(name: "postCreateRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_PostCreateRule_593138,
    base: "/", url: url_PostCreateRule_593139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateRule_593118 = ref object of OpenApiRestCall_592364
proc url_GetCreateRule_593120(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateRule_593119(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
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
  var valid_593121 = query.getOrDefault("Actions")
  valid_593121 = validateParameter(valid_593121, JArray, required = true, default = nil)
  if valid_593121 != nil:
    section.add "Actions", valid_593121
  var valid_593122 = query.getOrDefault("ListenerArn")
  valid_593122 = validateParameter(valid_593122, JString, required = true,
                                 default = nil)
  if valid_593122 != nil:
    section.add "ListenerArn", valid_593122
  var valid_593123 = query.getOrDefault("Priority")
  valid_593123 = validateParameter(valid_593123, JInt, required = true, default = nil)
  if valid_593123 != nil:
    section.add "Priority", valid_593123
  var valid_593124 = query.getOrDefault("Action")
  valid_593124 = validateParameter(valid_593124, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_593124 != nil:
    section.add "Action", valid_593124
  var valid_593125 = query.getOrDefault("Version")
  valid_593125 = validateParameter(valid_593125, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593125 != nil:
    section.add "Version", valid_593125
  var valid_593126 = query.getOrDefault("Conditions")
  valid_593126 = validateParameter(valid_593126, JArray, required = true, default = nil)
  if valid_593126 != nil:
    section.add "Conditions", valid_593126
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
  var valid_593127 = header.getOrDefault("X-Amz-Signature")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Signature", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Content-Sha256", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Date")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Date", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Credential")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Credential", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Security-Token")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Security-Token", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-Algorithm")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Algorithm", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-SignedHeaders", valid_593133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593134: Call_GetCreateRule_593118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_593134.validator(path, query, header, formData, body)
  let scheme = call_593134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593134.url(scheme.get, call_593134.host, call_593134.base,
                         call_593134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593134, url, valid)

proc call*(call_593135: Call_GetCreateRule_593118; Actions: JsonNode;
          ListenerArn: string; Priority: int; Conditions: JsonNode;
          Action: string = "CreateRule"; Version: string = "2015-12-01"): Recallable =
  ## getCreateRule
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Priority: int (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  var query_593136 = newJObject()
  if Actions != nil:
    query_593136.add "Actions", Actions
  add(query_593136, "ListenerArn", newJString(ListenerArn))
  add(query_593136, "Priority", newJInt(Priority))
  add(query_593136, "Action", newJString(Action))
  add(query_593136, "Version", newJString(Version))
  if Conditions != nil:
    query_593136.add "Conditions", Conditions
  result = call_593135.call(nil, query_593136, nil, nil, nil)

var getCreateRule* = Call_GetCreateRule_593118(name: "getCreateRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_GetCreateRule_593119,
    base: "/", url: url_GetCreateRule_593120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTargetGroup_593186 = ref object of OpenApiRestCall_592364
proc url_PostCreateTargetGroup_593188(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateTargetGroup_593187(path: JsonNode; query: JsonNode;
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
  var valid_593189 = query.getOrDefault("Action")
  valid_593189 = validateParameter(valid_593189, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_593189 != nil:
    section.add "Action", valid_593189
  var valid_593190 = query.getOrDefault("Version")
  valid_593190 = validateParameter(valid_593190, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593190 != nil:
    section.add "Version", valid_593190
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
  var valid_593191 = header.getOrDefault("X-Amz-Signature")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Signature", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Content-Sha256", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Date")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Date", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-Credential")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Credential", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-Security-Token")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-Security-Token", valid_593195
  var valid_593196 = header.getOrDefault("X-Amz-Algorithm")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Algorithm", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-SignedHeaders", valid_593197
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
  var valid_593198 = formData.getOrDefault("HealthCheckProtocol")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_593198 != nil:
    section.add "HealthCheckProtocol", valid_593198
  var valid_593199 = formData.getOrDefault("Port")
  valid_593199 = validateParameter(valid_593199, JInt, required = false, default = nil)
  if valid_593199 != nil:
    section.add "Port", valid_593199
  var valid_593200 = formData.getOrDefault("HealthCheckPort")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "HealthCheckPort", valid_593200
  var valid_593201 = formData.getOrDefault("VpcId")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "VpcId", valid_593201
  var valid_593202 = formData.getOrDefault("HealthCheckEnabled")
  valid_593202 = validateParameter(valid_593202, JBool, required = false, default = nil)
  if valid_593202 != nil:
    section.add "HealthCheckEnabled", valid_593202
  var valid_593203 = formData.getOrDefault("HealthCheckPath")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "HealthCheckPath", valid_593203
  var valid_593204 = formData.getOrDefault("TargetType")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = newJString("instance"))
  if valid_593204 != nil:
    section.add "TargetType", valid_593204
  var valid_593205 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_593205 = validateParameter(valid_593205, JInt, required = false, default = nil)
  if valid_593205 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_593205
  var valid_593206 = formData.getOrDefault("HealthyThresholdCount")
  valid_593206 = validateParameter(valid_593206, JInt, required = false, default = nil)
  if valid_593206 != nil:
    section.add "HealthyThresholdCount", valid_593206
  var valid_593207 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_593207 = validateParameter(valid_593207, JInt, required = false, default = nil)
  if valid_593207 != nil:
    section.add "HealthCheckIntervalSeconds", valid_593207
  var valid_593208 = formData.getOrDefault("Protocol")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_593208 != nil:
    section.add "Protocol", valid_593208
  var valid_593209 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_593209 = validateParameter(valid_593209, JInt, required = false, default = nil)
  if valid_593209 != nil:
    section.add "UnhealthyThresholdCount", valid_593209
  var valid_593210 = formData.getOrDefault("Matcher.HttpCode")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "Matcher.HttpCode", valid_593210
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_593211 = formData.getOrDefault("Name")
  valid_593211 = validateParameter(valid_593211, JString, required = true,
                                 default = nil)
  if valid_593211 != nil:
    section.add "Name", valid_593211
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593212: Call_PostCreateTargetGroup_593186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593212.validator(path, query, header, formData, body)
  let scheme = call_593212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593212.url(scheme.get, call_593212.host, call_593212.base,
                         call_593212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593212, url, valid)

proc call*(call_593213: Call_PostCreateTargetGroup_593186; Name: string;
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
  var query_593214 = newJObject()
  var formData_593215 = newJObject()
  add(formData_593215, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_593215, "Port", newJInt(Port))
  add(formData_593215, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_593215, "VpcId", newJString(VpcId))
  add(formData_593215, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_593215, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_593215, "TargetType", newJString(TargetType))
  add(formData_593215, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_593215, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_593215, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_593215, "Protocol", newJString(Protocol))
  add(formData_593215, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_593215, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_593214, "Action", newJString(Action))
  add(formData_593215, "Name", newJString(Name))
  add(query_593214, "Version", newJString(Version))
  result = call_593213.call(nil, query_593214, nil, formData_593215, nil)

var postCreateTargetGroup* = Call_PostCreateTargetGroup_593186(
    name: "postCreateTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup",
    validator: validate_PostCreateTargetGroup_593187, base: "/",
    url: url_PostCreateTargetGroup_593188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTargetGroup_593157 = ref object of OpenApiRestCall_592364
proc url_GetCreateTargetGroup_593159(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateTargetGroup_593158(path: JsonNode; query: JsonNode;
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
  var valid_593160 = query.getOrDefault("HealthCheckPort")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "HealthCheckPort", valid_593160
  var valid_593161 = query.getOrDefault("TargetType")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = newJString("instance"))
  if valid_593161 != nil:
    section.add "TargetType", valid_593161
  var valid_593162 = query.getOrDefault("HealthCheckPath")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "HealthCheckPath", valid_593162
  var valid_593163 = query.getOrDefault("VpcId")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "VpcId", valid_593163
  var valid_593164 = query.getOrDefault("HealthCheckProtocol")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_593164 != nil:
    section.add "HealthCheckProtocol", valid_593164
  var valid_593165 = query.getOrDefault("Matcher.HttpCode")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "Matcher.HttpCode", valid_593165
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_593166 = query.getOrDefault("Name")
  valid_593166 = validateParameter(valid_593166, JString, required = true,
                                 default = nil)
  if valid_593166 != nil:
    section.add "Name", valid_593166
  var valid_593167 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_593167 = validateParameter(valid_593167, JInt, required = false, default = nil)
  if valid_593167 != nil:
    section.add "HealthCheckIntervalSeconds", valid_593167
  var valid_593168 = query.getOrDefault("HealthCheckEnabled")
  valid_593168 = validateParameter(valid_593168, JBool, required = false, default = nil)
  if valid_593168 != nil:
    section.add "HealthCheckEnabled", valid_593168
  var valid_593169 = query.getOrDefault("HealthyThresholdCount")
  valid_593169 = validateParameter(valid_593169, JInt, required = false, default = nil)
  if valid_593169 != nil:
    section.add "HealthyThresholdCount", valid_593169
  var valid_593170 = query.getOrDefault("UnhealthyThresholdCount")
  valid_593170 = validateParameter(valid_593170, JInt, required = false, default = nil)
  if valid_593170 != nil:
    section.add "UnhealthyThresholdCount", valid_593170
  var valid_593171 = query.getOrDefault("Action")
  valid_593171 = validateParameter(valid_593171, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_593171 != nil:
    section.add "Action", valid_593171
  var valid_593172 = query.getOrDefault("Protocol")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_593172 != nil:
    section.add "Protocol", valid_593172
  var valid_593173 = query.getOrDefault("Port")
  valid_593173 = validateParameter(valid_593173, JInt, required = false, default = nil)
  if valid_593173 != nil:
    section.add "Port", valid_593173
  var valid_593174 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_593174 = validateParameter(valid_593174, JInt, required = false, default = nil)
  if valid_593174 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_593174
  var valid_593175 = query.getOrDefault("Version")
  valid_593175 = validateParameter(valid_593175, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593175 != nil:
    section.add "Version", valid_593175
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
  var valid_593176 = header.getOrDefault("X-Amz-Signature")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Signature", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Content-Sha256", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-Date")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-Date", valid_593178
  var valid_593179 = header.getOrDefault("X-Amz-Credential")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Credential", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-Security-Token")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-Security-Token", valid_593180
  var valid_593181 = header.getOrDefault("X-Amz-Algorithm")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-Algorithm", valid_593181
  var valid_593182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-SignedHeaders", valid_593182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593183: Call_GetCreateTargetGroup_593157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593183.validator(path, query, header, formData, body)
  let scheme = call_593183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593183.url(scheme.get, call_593183.host, call_593183.base,
                         call_593183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593183, url, valid)

proc call*(call_593184: Call_GetCreateTargetGroup_593157; Name: string;
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
  var query_593185 = newJObject()
  add(query_593185, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_593185, "TargetType", newJString(TargetType))
  add(query_593185, "HealthCheckPath", newJString(HealthCheckPath))
  add(query_593185, "VpcId", newJString(VpcId))
  add(query_593185, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_593185, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_593185, "Name", newJString(Name))
  add(query_593185, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_593185, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_593185, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_593185, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_593185, "Action", newJString(Action))
  add(query_593185, "Protocol", newJString(Protocol))
  add(query_593185, "Port", newJInt(Port))
  add(query_593185, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_593185, "Version", newJString(Version))
  result = call_593184.call(nil, query_593185, nil, nil, nil)

var getCreateTargetGroup* = Call_GetCreateTargetGroup_593157(
    name: "getCreateTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup", validator: validate_GetCreateTargetGroup_593158,
    base: "/", url: url_GetCreateTargetGroup_593159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteListener_593232 = ref object of OpenApiRestCall_592364
proc url_PostDeleteListener_593234(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteListener_593233(path: JsonNode; query: JsonNode;
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
  var valid_593235 = query.getOrDefault("Action")
  valid_593235 = validateParameter(valid_593235, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_593235 != nil:
    section.add "Action", valid_593235
  var valid_593236 = query.getOrDefault("Version")
  valid_593236 = validateParameter(valid_593236, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593236 != nil:
    section.add "Version", valid_593236
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
  var valid_593237 = header.getOrDefault("X-Amz-Signature")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Signature", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Content-Sha256", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-Date")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Date", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Credential")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Credential", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-Security-Token")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Security-Token", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Algorithm")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Algorithm", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-SignedHeaders", valid_593243
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_593244 = formData.getOrDefault("ListenerArn")
  valid_593244 = validateParameter(valid_593244, JString, required = true,
                                 default = nil)
  if valid_593244 != nil:
    section.add "ListenerArn", valid_593244
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593245: Call_PostDeleteListener_593232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_593245.validator(path, query, header, formData, body)
  let scheme = call_593245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593245.url(scheme.get, call_593245.host, call_593245.base,
                         call_593245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593245, url, valid)

proc call*(call_593246: Call_PostDeleteListener_593232; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593247 = newJObject()
  var formData_593248 = newJObject()
  add(formData_593248, "ListenerArn", newJString(ListenerArn))
  add(query_593247, "Action", newJString(Action))
  add(query_593247, "Version", newJString(Version))
  result = call_593246.call(nil, query_593247, nil, formData_593248, nil)

var postDeleteListener* = Call_PostDeleteListener_593232(
    name: "postDeleteListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=DeleteListener",
    validator: validate_PostDeleteListener_593233, base: "/",
    url: url_PostDeleteListener_593234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteListener_593216 = ref object of OpenApiRestCall_592364
proc url_GetDeleteListener_593218(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteListener_593217(path: JsonNode; query: JsonNode;
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
  var valid_593219 = query.getOrDefault("ListenerArn")
  valid_593219 = validateParameter(valid_593219, JString, required = true,
                                 default = nil)
  if valid_593219 != nil:
    section.add "ListenerArn", valid_593219
  var valid_593220 = query.getOrDefault("Action")
  valid_593220 = validateParameter(valid_593220, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_593220 != nil:
    section.add "Action", valid_593220
  var valid_593221 = query.getOrDefault("Version")
  valid_593221 = validateParameter(valid_593221, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593221 != nil:
    section.add "Version", valid_593221
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
  var valid_593222 = header.getOrDefault("X-Amz-Signature")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Signature", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Content-Sha256", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Date")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Date", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Credential")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Credential", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Security-Token")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Security-Token", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-Algorithm")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Algorithm", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-SignedHeaders", valid_593228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593229: Call_GetDeleteListener_593216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_593229.validator(path, query, header, formData, body)
  let scheme = call_593229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593229.url(scheme.get, call_593229.host, call_593229.base,
                         call_593229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593229, url, valid)

proc call*(call_593230: Call_GetDeleteListener_593216; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593231 = newJObject()
  add(query_593231, "ListenerArn", newJString(ListenerArn))
  add(query_593231, "Action", newJString(Action))
  add(query_593231, "Version", newJString(Version))
  result = call_593230.call(nil, query_593231, nil, nil, nil)

var getDeleteListener* = Call_GetDeleteListener_593216(name: "getDeleteListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteListener", validator: validate_GetDeleteListener_593217,
    base: "/", url: url_GetDeleteListener_593218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_593265 = ref object of OpenApiRestCall_592364
proc url_PostDeleteLoadBalancer_593267(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteLoadBalancer_593266(path: JsonNode; query: JsonNode;
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
  var valid_593268 = query.getOrDefault("Action")
  valid_593268 = validateParameter(valid_593268, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_593268 != nil:
    section.add "Action", valid_593268
  var valid_593269 = query.getOrDefault("Version")
  valid_593269 = validateParameter(valid_593269, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593269 != nil:
    section.add "Version", valid_593269
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
  var valid_593270 = header.getOrDefault("X-Amz-Signature")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "X-Amz-Signature", valid_593270
  var valid_593271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Content-Sha256", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Date")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Date", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Credential")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Credential", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Security-Token")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Security-Token", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Algorithm")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Algorithm", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-SignedHeaders", valid_593276
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_593277 = formData.getOrDefault("LoadBalancerArn")
  valid_593277 = validateParameter(valid_593277, JString, required = true,
                                 default = nil)
  if valid_593277 != nil:
    section.add "LoadBalancerArn", valid_593277
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593278: Call_PostDeleteLoadBalancer_593265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_593278.validator(path, query, header, formData, body)
  let scheme = call_593278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593278.url(scheme.get, call_593278.host, call_593278.base,
                         call_593278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593278, url, valid)

proc call*(call_593279: Call_PostDeleteLoadBalancer_593265;
          LoadBalancerArn: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2015-12-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_593280 = newJObject()
  var formData_593281 = newJObject()
  add(query_593280, "Action", newJString(Action))
  add(query_593280, "Version", newJString(Version))
  add(formData_593281, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_593279.call(nil, query_593280, nil, formData_593281, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_593265(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_593266, base: "/",
    url: url_PostDeleteLoadBalancer_593267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_593249 = ref object of OpenApiRestCall_592364
proc url_GetDeleteLoadBalancer_593251(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteLoadBalancer_593250(path: JsonNode; query: JsonNode;
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
  var valid_593252 = query.getOrDefault("LoadBalancerArn")
  valid_593252 = validateParameter(valid_593252, JString, required = true,
                                 default = nil)
  if valid_593252 != nil:
    section.add "LoadBalancerArn", valid_593252
  var valid_593253 = query.getOrDefault("Action")
  valid_593253 = validateParameter(valid_593253, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_593253 != nil:
    section.add "Action", valid_593253
  var valid_593254 = query.getOrDefault("Version")
  valid_593254 = validateParameter(valid_593254, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593254 != nil:
    section.add "Version", valid_593254
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
  var valid_593255 = header.getOrDefault("X-Amz-Signature")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-Signature", valid_593255
  var valid_593256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Content-Sha256", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-Date")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Date", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Credential")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Credential", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-Security-Token")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Security-Token", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Algorithm")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Algorithm", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-SignedHeaders", valid_593261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593262: Call_GetDeleteLoadBalancer_593249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_593262.validator(path, query, header, formData, body)
  let scheme = call_593262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593262.url(scheme.get, call_593262.host, call_593262.base,
                         call_593262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593262, url, valid)

proc call*(call_593263: Call_GetDeleteLoadBalancer_593249; LoadBalancerArn: string;
          Action: string = "DeleteLoadBalancer"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593264 = newJObject()
  add(query_593264, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_593264, "Action", newJString(Action))
  add(query_593264, "Version", newJString(Version))
  result = call_593263.call(nil, query_593264, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_593249(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_593250, base: "/",
    url: url_GetDeleteLoadBalancer_593251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRule_593298 = ref object of OpenApiRestCall_592364
proc url_PostDeleteRule_593300(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteRule_593299(path: JsonNode; query: JsonNode;
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
  var valid_593301 = query.getOrDefault("Action")
  valid_593301 = validateParameter(valid_593301, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_593301 != nil:
    section.add "Action", valid_593301
  var valid_593302 = query.getOrDefault("Version")
  valid_593302 = validateParameter(valid_593302, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593302 != nil:
    section.add "Version", valid_593302
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
  var valid_593303 = header.getOrDefault("X-Amz-Signature")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-Signature", valid_593303
  var valid_593304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593304 = validateParameter(valid_593304, JString, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "X-Amz-Content-Sha256", valid_593304
  var valid_593305 = header.getOrDefault("X-Amz-Date")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "X-Amz-Date", valid_593305
  var valid_593306 = header.getOrDefault("X-Amz-Credential")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Credential", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Security-Token")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Security-Token", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Algorithm")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Algorithm", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-SignedHeaders", valid_593309
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_593310 = formData.getOrDefault("RuleArn")
  valid_593310 = validateParameter(valid_593310, JString, required = true,
                                 default = nil)
  if valid_593310 != nil:
    section.add "RuleArn", valid_593310
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593311: Call_PostDeleteRule_593298; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_593311.validator(path, query, header, formData, body)
  let scheme = call_593311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593311.url(scheme.get, call_593311.host, call_593311.base,
                         call_593311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593311, url, valid)

proc call*(call_593312: Call_PostDeleteRule_593298; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593313 = newJObject()
  var formData_593314 = newJObject()
  add(formData_593314, "RuleArn", newJString(RuleArn))
  add(query_593313, "Action", newJString(Action))
  add(query_593313, "Version", newJString(Version))
  result = call_593312.call(nil, query_593313, nil, formData_593314, nil)

var postDeleteRule* = Call_PostDeleteRule_593298(name: "postDeleteRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_PostDeleteRule_593299,
    base: "/", url: url_PostDeleteRule_593300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRule_593282 = ref object of OpenApiRestCall_592364
proc url_GetDeleteRule_593284(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteRule_593283(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593285 = query.getOrDefault("RuleArn")
  valid_593285 = validateParameter(valid_593285, JString, required = true,
                                 default = nil)
  if valid_593285 != nil:
    section.add "RuleArn", valid_593285
  var valid_593286 = query.getOrDefault("Action")
  valid_593286 = validateParameter(valid_593286, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_593286 != nil:
    section.add "Action", valid_593286
  var valid_593287 = query.getOrDefault("Version")
  valid_593287 = validateParameter(valid_593287, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593287 != nil:
    section.add "Version", valid_593287
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
  var valid_593288 = header.getOrDefault("X-Amz-Signature")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Signature", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Content-Sha256", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Date")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Date", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Credential")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Credential", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Security-Token")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Security-Token", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Algorithm")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Algorithm", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-SignedHeaders", valid_593294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593295: Call_GetDeleteRule_593282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_593295.validator(path, query, header, formData, body)
  let scheme = call_593295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593295.url(scheme.get, call_593295.host, call_593295.base,
                         call_593295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593295, url, valid)

proc call*(call_593296: Call_GetDeleteRule_593282; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593297 = newJObject()
  add(query_593297, "RuleArn", newJString(RuleArn))
  add(query_593297, "Action", newJString(Action))
  add(query_593297, "Version", newJString(Version))
  result = call_593296.call(nil, query_593297, nil, nil, nil)

var getDeleteRule* = Call_GetDeleteRule_593282(name: "getDeleteRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_GetDeleteRule_593283,
    base: "/", url: url_GetDeleteRule_593284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTargetGroup_593331 = ref object of OpenApiRestCall_592364
proc url_PostDeleteTargetGroup_593333(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteTargetGroup_593332(path: JsonNode; query: JsonNode;
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
  var valid_593334 = query.getOrDefault("Action")
  valid_593334 = validateParameter(valid_593334, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_593334 != nil:
    section.add "Action", valid_593334
  var valid_593335 = query.getOrDefault("Version")
  valid_593335 = validateParameter(valid_593335, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593335 != nil:
    section.add "Version", valid_593335
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
  var valid_593336 = header.getOrDefault("X-Amz-Signature")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Signature", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-Content-Sha256", valid_593337
  var valid_593338 = header.getOrDefault("X-Amz-Date")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-Date", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-Credential")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-Credential", valid_593339
  var valid_593340 = header.getOrDefault("X-Amz-Security-Token")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-Security-Token", valid_593340
  var valid_593341 = header.getOrDefault("X-Amz-Algorithm")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Algorithm", valid_593341
  var valid_593342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "X-Amz-SignedHeaders", valid_593342
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_593343 = formData.getOrDefault("TargetGroupArn")
  valid_593343 = validateParameter(valid_593343, JString, required = true,
                                 default = nil)
  if valid_593343 != nil:
    section.add "TargetGroupArn", valid_593343
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593344: Call_PostDeleteTargetGroup_593331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_593344.validator(path, query, header, formData, body)
  let scheme = call_593344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593344.url(scheme.get, call_593344.host, call_593344.base,
                         call_593344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593344, url, valid)

proc call*(call_593345: Call_PostDeleteTargetGroup_593331; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_593346 = newJObject()
  var formData_593347 = newJObject()
  add(query_593346, "Action", newJString(Action))
  add(formData_593347, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_593346, "Version", newJString(Version))
  result = call_593345.call(nil, query_593346, nil, formData_593347, nil)

var postDeleteTargetGroup* = Call_PostDeleteTargetGroup_593331(
    name: "postDeleteTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup",
    validator: validate_PostDeleteTargetGroup_593332, base: "/",
    url: url_PostDeleteTargetGroup_593333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTargetGroup_593315 = ref object of OpenApiRestCall_592364
proc url_GetDeleteTargetGroup_593317(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteTargetGroup_593316(path: JsonNode; query: JsonNode;
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
  var valid_593318 = query.getOrDefault("TargetGroupArn")
  valid_593318 = validateParameter(valid_593318, JString, required = true,
                                 default = nil)
  if valid_593318 != nil:
    section.add "TargetGroupArn", valid_593318
  var valid_593319 = query.getOrDefault("Action")
  valid_593319 = validateParameter(valid_593319, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_593319 != nil:
    section.add "Action", valid_593319
  var valid_593320 = query.getOrDefault("Version")
  valid_593320 = validateParameter(valid_593320, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593320 != nil:
    section.add "Version", valid_593320
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
  var valid_593321 = header.getOrDefault("X-Amz-Signature")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Signature", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Content-Sha256", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Date")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Date", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Credential")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Credential", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Security-Token")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Security-Token", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-Algorithm")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Algorithm", valid_593326
  var valid_593327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-SignedHeaders", valid_593327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593328: Call_GetDeleteTargetGroup_593315; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_593328.validator(path, query, header, formData, body)
  let scheme = call_593328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593328.url(scheme.get, call_593328.host, call_593328.base,
                         call_593328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593328, url, valid)

proc call*(call_593329: Call_GetDeleteTargetGroup_593315; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593330 = newJObject()
  add(query_593330, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_593330, "Action", newJString(Action))
  add(query_593330, "Version", newJString(Version))
  result = call_593329.call(nil, query_593330, nil, nil, nil)

var getDeleteTargetGroup* = Call_GetDeleteTargetGroup_593315(
    name: "getDeleteTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup", validator: validate_GetDeleteTargetGroup_593316,
    base: "/", url: url_GetDeleteTargetGroup_593317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterTargets_593365 = ref object of OpenApiRestCall_592364
proc url_PostDeregisterTargets_593367(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeregisterTargets_593366(path: JsonNode; query: JsonNode;
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
  var valid_593368 = query.getOrDefault("Action")
  valid_593368 = validateParameter(valid_593368, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_593368 != nil:
    section.add "Action", valid_593368
  var valid_593369 = query.getOrDefault("Version")
  valid_593369 = validateParameter(valid_593369, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593369 != nil:
    section.add "Version", valid_593369
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
  var valid_593370 = header.getOrDefault("X-Amz-Signature")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Signature", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Content-Sha256", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-Date")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Date", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-Credential")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-Credential", valid_593373
  var valid_593374 = header.getOrDefault("X-Amz-Security-Token")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "X-Amz-Security-Token", valid_593374
  var valid_593375 = header.getOrDefault("X-Amz-Algorithm")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "X-Amz-Algorithm", valid_593375
  var valid_593376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "X-Amz-SignedHeaders", valid_593376
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_593377 = formData.getOrDefault("Targets")
  valid_593377 = validateParameter(valid_593377, JArray, required = true, default = nil)
  if valid_593377 != nil:
    section.add "Targets", valid_593377
  var valid_593378 = formData.getOrDefault("TargetGroupArn")
  valid_593378 = validateParameter(valid_593378, JString, required = true,
                                 default = nil)
  if valid_593378 != nil:
    section.add "TargetGroupArn", valid_593378
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593379: Call_PostDeregisterTargets_593365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_593379.validator(path, query, header, formData, body)
  let scheme = call_593379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593379.url(scheme.get, call_593379.host, call_593379.base,
                         call_593379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593379, url, valid)

proc call*(call_593380: Call_PostDeregisterTargets_593365; Targets: JsonNode;
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
  var query_593381 = newJObject()
  var formData_593382 = newJObject()
  if Targets != nil:
    formData_593382.add "Targets", Targets
  add(query_593381, "Action", newJString(Action))
  add(formData_593382, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_593381, "Version", newJString(Version))
  result = call_593380.call(nil, query_593381, nil, formData_593382, nil)

var postDeregisterTargets* = Call_PostDeregisterTargets_593365(
    name: "postDeregisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets",
    validator: validate_PostDeregisterTargets_593366, base: "/",
    url: url_PostDeregisterTargets_593367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterTargets_593348 = ref object of OpenApiRestCall_592364
proc url_GetDeregisterTargets_593350(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeregisterTargets_593349(path: JsonNode; query: JsonNode;
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
  var valid_593351 = query.getOrDefault("Targets")
  valid_593351 = validateParameter(valid_593351, JArray, required = true, default = nil)
  if valid_593351 != nil:
    section.add "Targets", valid_593351
  var valid_593352 = query.getOrDefault("TargetGroupArn")
  valid_593352 = validateParameter(valid_593352, JString, required = true,
                                 default = nil)
  if valid_593352 != nil:
    section.add "TargetGroupArn", valid_593352
  var valid_593353 = query.getOrDefault("Action")
  valid_593353 = validateParameter(valid_593353, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_593353 != nil:
    section.add "Action", valid_593353
  var valid_593354 = query.getOrDefault("Version")
  valid_593354 = validateParameter(valid_593354, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593354 != nil:
    section.add "Version", valid_593354
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
  var valid_593355 = header.getOrDefault("X-Amz-Signature")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Signature", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Content-Sha256", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-Date")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-Date", valid_593357
  var valid_593358 = header.getOrDefault("X-Amz-Credential")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "X-Amz-Credential", valid_593358
  var valid_593359 = header.getOrDefault("X-Amz-Security-Token")
  valid_593359 = validateParameter(valid_593359, JString, required = false,
                                 default = nil)
  if valid_593359 != nil:
    section.add "X-Amz-Security-Token", valid_593359
  var valid_593360 = header.getOrDefault("X-Amz-Algorithm")
  valid_593360 = validateParameter(valid_593360, JString, required = false,
                                 default = nil)
  if valid_593360 != nil:
    section.add "X-Amz-Algorithm", valid_593360
  var valid_593361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593361 = validateParameter(valid_593361, JString, required = false,
                                 default = nil)
  if valid_593361 != nil:
    section.add "X-Amz-SignedHeaders", valid_593361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593362: Call_GetDeregisterTargets_593348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_593362.validator(path, query, header, formData, body)
  let scheme = call_593362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593362.url(scheme.get, call_593362.host, call_593362.base,
                         call_593362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593362, url, valid)

proc call*(call_593363: Call_GetDeregisterTargets_593348; Targets: JsonNode;
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
  var query_593364 = newJObject()
  if Targets != nil:
    query_593364.add "Targets", Targets
  add(query_593364, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_593364, "Action", newJString(Action))
  add(query_593364, "Version", newJString(Version))
  result = call_593363.call(nil, query_593364, nil, nil, nil)

var getDeregisterTargets* = Call_GetDeregisterTargets_593348(
    name: "getDeregisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets", validator: validate_GetDeregisterTargets_593349,
    base: "/", url: url_GetDeregisterTargets_593350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_593400 = ref object of OpenApiRestCall_592364
proc url_PostDescribeAccountLimits_593402(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAccountLimits_593401(path: JsonNode; query: JsonNode;
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
  var valid_593403 = query.getOrDefault("Action")
  valid_593403 = validateParameter(valid_593403, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_593403 != nil:
    section.add "Action", valid_593403
  var valid_593404 = query.getOrDefault("Version")
  valid_593404 = validateParameter(valid_593404, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593404 != nil:
    section.add "Version", valid_593404
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
  var valid_593405 = header.getOrDefault("X-Amz-Signature")
  valid_593405 = validateParameter(valid_593405, JString, required = false,
                                 default = nil)
  if valid_593405 != nil:
    section.add "X-Amz-Signature", valid_593405
  var valid_593406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593406 = validateParameter(valid_593406, JString, required = false,
                                 default = nil)
  if valid_593406 != nil:
    section.add "X-Amz-Content-Sha256", valid_593406
  var valid_593407 = header.getOrDefault("X-Amz-Date")
  valid_593407 = validateParameter(valid_593407, JString, required = false,
                                 default = nil)
  if valid_593407 != nil:
    section.add "X-Amz-Date", valid_593407
  var valid_593408 = header.getOrDefault("X-Amz-Credential")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "X-Amz-Credential", valid_593408
  var valid_593409 = header.getOrDefault("X-Amz-Security-Token")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "X-Amz-Security-Token", valid_593409
  var valid_593410 = header.getOrDefault("X-Amz-Algorithm")
  valid_593410 = validateParameter(valid_593410, JString, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "X-Amz-Algorithm", valid_593410
  var valid_593411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "X-Amz-SignedHeaders", valid_593411
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_593412 = formData.getOrDefault("Marker")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "Marker", valid_593412
  var valid_593413 = formData.getOrDefault("PageSize")
  valid_593413 = validateParameter(valid_593413, JInt, required = false, default = nil)
  if valid_593413 != nil:
    section.add "PageSize", valid_593413
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593414: Call_PostDescribeAccountLimits_593400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593414.validator(path, query, header, formData, body)
  let scheme = call_593414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593414.url(scheme.get, call_593414.host, call_593414.base,
                         call_593414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593414, url, valid)

proc call*(call_593415: Call_PostDescribeAccountLimits_593400; Marker: string = "";
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
  var query_593416 = newJObject()
  var formData_593417 = newJObject()
  add(formData_593417, "Marker", newJString(Marker))
  add(query_593416, "Action", newJString(Action))
  add(formData_593417, "PageSize", newJInt(PageSize))
  add(query_593416, "Version", newJString(Version))
  result = call_593415.call(nil, query_593416, nil, formData_593417, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_593400(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_593401, base: "/",
    url: url_PostDescribeAccountLimits_593402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_593383 = ref object of OpenApiRestCall_592364
proc url_GetDescribeAccountLimits_593385(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAccountLimits_593384(path: JsonNode; query: JsonNode;
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
  var valid_593386 = query.getOrDefault("Marker")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "Marker", valid_593386
  var valid_593387 = query.getOrDefault("PageSize")
  valid_593387 = validateParameter(valid_593387, JInt, required = false, default = nil)
  if valid_593387 != nil:
    section.add "PageSize", valid_593387
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593388 = query.getOrDefault("Action")
  valid_593388 = validateParameter(valid_593388, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_593388 != nil:
    section.add "Action", valid_593388
  var valid_593389 = query.getOrDefault("Version")
  valid_593389 = validateParameter(valid_593389, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593389 != nil:
    section.add "Version", valid_593389
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
  var valid_593390 = header.getOrDefault("X-Amz-Signature")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Signature", valid_593390
  var valid_593391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-Content-Sha256", valid_593391
  var valid_593392 = header.getOrDefault("X-Amz-Date")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-Date", valid_593392
  var valid_593393 = header.getOrDefault("X-Amz-Credential")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-Credential", valid_593393
  var valid_593394 = header.getOrDefault("X-Amz-Security-Token")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-Security-Token", valid_593394
  var valid_593395 = header.getOrDefault("X-Amz-Algorithm")
  valid_593395 = validateParameter(valid_593395, JString, required = false,
                                 default = nil)
  if valid_593395 != nil:
    section.add "X-Amz-Algorithm", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-SignedHeaders", valid_593396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593397: Call_GetDescribeAccountLimits_593383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593397.validator(path, query, header, formData, body)
  let scheme = call_593397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593397.url(scheme.get, call_593397.host, call_593397.base,
                         call_593397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593397, url, valid)

proc call*(call_593398: Call_GetDescribeAccountLimits_593383; Marker: string = "";
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
  var query_593399 = newJObject()
  add(query_593399, "Marker", newJString(Marker))
  add(query_593399, "PageSize", newJInt(PageSize))
  add(query_593399, "Action", newJString(Action))
  add(query_593399, "Version", newJString(Version))
  result = call_593398.call(nil, query_593399, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_593383(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_593384, base: "/",
    url: url_GetDescribeAccountLimits_593385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListenerCertificates_593436 = ref object of OpenApiRestCall_592364
proc url_PostDescribeListenerCertificates_593438(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeListenerCertificates_593437(path: JsonNode;
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
  var valid_593439 = query.getOrDefault("Action")
  valid_593439 = validateParameter(valid_593439, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_593439 != nil:
    section.add "Action", valid_593439
  var valid_593440 = query.getOrDefault("Version")
  valid_593440 = validateParameter(valid_593440, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593440 != nil:
    section.add "Version", valid_593440
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
  var valid_593441 = header.getOrDefault("X-Amz-Signature")
  valid_593441 = validateParameter(valid_593441, JString, required = false,
                                 default = nil)
  if valid_593441 != nil:
    section.add "X-Amz-Signature", valid_593441
  var valid_593442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "X-Amz-Content-Sha256", valid_593442
  var valid_593443 = header.getOrDefault("X-Amz-Date")
  valid_593443 = validateParameter(valid_593443, JString, required = false,
                                 default = nil)
  if valid_593443 != nil:
    section.add "X-Amz-Date", valid_593443
  var valid_593444 = header.getOrDefault("X-Amz-Credential")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "X-Amz-Credential", valid_593444
  var valid_593445 = header.getOrDefault("X-Amz-Security-Token")
  valid_593445 = validateParameter(valid_593445, JString, required = false,
                                 default = nil)
  if valid_593445 != nil:
    section.add "X-Amz-Security-Token", valid_593445
  var valid_593446 = header.getOrDefault("X-Amz-Algorithm")
  valid_593446 = validateParameter(valid_593446, JString, required = false,
                                 default = nil)
  if valid_593446 != nil:
    section.add "X-Amz-Algorithm", valid_593446
  var valid_593447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-SignedHeaders", valid_593447
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
  var valid_593448 = formData.getOrDefault("ListenerArn")
  valid_593448 = validateParameter(valid_593448, JString, required = true,
                                 default = nil)
  if valid_593448 != nil:
    section.add "ListenerArn", valid_593448
  var valid_593449 = formData.getOrDefault("Marker")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "Marker", valid_593449
  var valid_593450 = formData.getOrDefault("PageSize")
  valid_593450 = validateParameter(valid_593450, JInt, required = false, default = nil)
  if valid_593450 != nil:
    section.add "PageSize", valid_593450
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593451: Call_PostDescribeListenerCertificates_593436;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593451.validator(path, query, header, formData, body)
  let scheme = call_593451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593451.url(scheme.get, call_593451.host, call_593451.base,
                         call_593451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593451, url, valid)

proc call*(call_593452: Call_PostDescribeListenerCertificates_593436;
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
  var query_593453 = newJObject()
  var formData_593454 = newJObject()
  add(formData_593454, "ListenerArn", newJString(ListenerArn))
  add(formData_593454, "Marker", newJString(Marker))
  add(query_593453, "Action", newJString(Action))
  add(formData_593454, "PageSize", newJInt(PageSize))
  add(query_593453, "Version", newJString(Version))
  result = call_593452.call(nil, query_593453, nil, formData_593454, nil)

var postDescribeListenerCertificates* = Call_PostDescribeListenerCertificates_593436(
    name: "postDescribeListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_PostDescribeListenerCertificates_593437, base: "/",
    url: url_PostDescribeListenerCertificates_593438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListenerCertificates_593418 = ref object of OpenApiRestCall_592364
proc url_GetDescribeListenerCertificates_593420(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeListenerCertificates_593419(path: JsonNode;
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
  var valid_593421 = query.getOrDefault("Marker")
  valid_593421 = validateParameter(valid_593421, JString, required = false,
                                 default = nil)
  if valid_593421 != nil:
    section.add "Marker", valid_593421
  assert query != nil,
        "query argument is necessary due to required `ListenerArn` field"
  var valid_593422 = query.getOrDefault("ListenerArn")
  valid_593422 = validateParameter(valid_593422, JString, required = true,
                                 default = nil)
  if valid_593422 != nil:
    section.add "ListenerArn", valid_593422
  var valid_593423 = query.getOrDefault("PageSize")
  valid_593423 = validateParameter(valid_593423, JInt, required = false, default = nil)
  if valid_593423 != nil:
    section.add "PageSize", valid_593423
  var valid_593424 = query.getOrDefault("Action")
  valid_593424 = validateParameter(valid_593424, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_593424 != nil:
    section.add "Action", valid_593424
  var valid_593425 = query.getOrDefault("Version")
  valid_593425 = validateParameter(valid_593425, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593425 != nil:
    section.add "Version", valid_593425
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
  var valid_593426 = header.getOrDefault("X-Amz-Signature")
  valid_593426 = validateParameter(valid_593426, JString, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "X-Amz-Signature", valid_593426
  var valid_593427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-Content-Sha256", valid_593427
  var valid_593428 = header.getOrDefault("X-Amz-Date")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-Date", valid_593428
  var valid_593429 = header.getOrDefault("X-Amz-Credential")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-Credential", valid_593429
  var valid_593430 = header.getOrDefault("X-Amz-Security-Token")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-Security-Token", valid_593430
  var valid_593431 = header.getOrDefault("X-Amz-Algorithm")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Algorithm", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-SignedHeaders", valid_593432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593433: Call_GetDescribeListenerCertificates_593418;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593433.validator(path, query, header, formData, body)
  let scheme = call_593433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593433.url(scheme.get, call_593433.host, call_593433.base,
                         call_593433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593433, url, valid)

proc call*(call_593434: Call_GetDescribeListenerCertificates_593418;
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
  var query_593435 = newJObject()
  add(query_593435, "Marker", newJString(Marker))
  add(query_593435, "ListenerArn", newJString(ListenerArn))
  add(query_593435, "PageSize", newJInt(PageSize))
  add(query_593435, "Action", newJString(Action))
  add(query_593435, "Version", newJString(Version))
  result = call_593434.call(nil, query_593435, nil, nil, nil)

var getDescribeListenerCertificates* = Call_GetDescribeListenerCertificates_593418(
    name: "getDescribeListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_GetDescribeListenerCertificates_593419, base: "/",
    url: url_GetDescribeListenerCertificates_593420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListeners_593474 = ref object of OpenApiRestCall_592364
proc url_PostDescribeListeners_593476(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeListeners_593475(path: JsonNode; query: JsonNode;
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
  var valid_593477 = query.getOrDefault("Action")
  valid_593477 = validateParameter(valid_593477, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_593477 != nil:
    section.add "Action", valid_593477
  var valid_593478 = query.getOrDefault("Version")
  valid_593478 = validateParameter(valid_593478, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593478 != nil:
    section.add "Version", valid_593478
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
  var valid_593479 = header.getOrDefault("X-Amz-Signature")
  valid_593479 = validateParameter(valid_593479, JString, required = false,
                                 default = nil)
  if valid_593479 != nil:
    section.add "X-Amz-Signature", valid_593479
  var valid_593480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593480 = validateParameter(valid_593480, JString, required = false,
                                 default = nil)
  if valid_593480 != nil:
    section.add "X-Amz-Content-Sha256", valid_593480
  var valid_593481 = header.getOrDefault("X-Amz-Date")
  valid_593481 = validateParameter(valid_593481, JString, required = false,
                                 default = nil)
  if valid_593481 != nil:
    section.add "X-Amz-Date", valid_593481
  var valid_593482 = header.getOrDefault("X-Amz-Credential")
  valid_593482 = validateParameter(valid_593482, JString, required = false,
                                 default = nil)
  if valid_593482 != nil:
    section.add "X-Amz-Credential", valid_593482
  var valid_593483 = header.getOrDefault("X-Amz-Security-Token")
  valid_593483 = validateParameter(valid_593483, JString, required = false,
                                 default = nil)
  if valid_593483 != nil:
    section.add "X-Amz-Security-Token", valid_593483
  var valid_593484 = header.getOrDefault("X-Amz-Algorithm")
  valid_593484 = validateParameter(valid_593484, JString, required = false,
                                 default = nil)
  if valid_593484 != nil:
    section.add "X-Amz-Algorithm", valid_593484
  var valid_593485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593485 = validateParameter(valid_593485, JString, required = false,
                                 default = nil)
  if valid_593485 != nil:
    section.add "X-Amz-SignedHeaders", valid_593485
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
  var valid_593486 = formData.getOrDefault("Marker")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "Marker", valid_593486
  var valid_593487 = formData.getOrDefault("PageSize")
  valid_593487 = validateParameter(valid_593487, JInt, required = false, default = nil)
  if valid_593487 != nil:
    section.add "PageSize", valid_593487
  var valid_593488 = formData.getOrDefault("LoadBalancerArn")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "LoadBalancerArn", valid_593488
  var valid_593489 = formData.getOrDefault("ListenerArns")
  valid_593489 = validateParameter(valid_593489, JArray, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "ListenerArns", valid_593489
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593490: Call_PostDescribeListeners_593474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_593490.validator(path, query, header, formData, body)
  let scheme = call_593490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593490.url(scheme.get, call_593490.host, call_593490.base,
                         call_593490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593490, url, valid)

proc call*(call_593491: Call_PostDescribeListeners_593474; Marker: string = "";
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
  var query_593492 = newJObject()
  var formData_593493 = newJObject()
  add(formData_593493, "Marker", newJString(Marker))
  add(query_593492, "Action", newJString(Action))
  add(formData_593493, "PageSize", newJInt(PageSize))
  add(query_593492, "Version", newJString(Version))
  add(formData_593493, "LoadBalancerArn", newJString(LoadBalancerArn))
  if ListenerArns != nil:
    formData_593493.add "ListenerArns", ListenerArns
  result = call_593491.call(nil, query_593492, nil, formData_593493, nil)

var postDescribeListeners* = Call_PostDescribeListeners_593474(
    name: "postDescribeListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners",
    validator: validate_PostDescribeListeners_593475, base: "/",
    url: url_PostDescribeListeners_593476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListeners_593455 = ref object of OpenApiRestCall_592364
proc url_GetDescribeListeners_593457(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeListeners_593456(path: JsonNode; query: JsonNode;
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
  var valid_593458 = query.getOrDefault("Marker")
  valid_593458 = validateParameter(valid_593458, JString, required = false,
                                 default = nil)
  if valid_593458 != nil:
    section.add "Marker", valid_593458
  var valid_593459 = query.getOrDefault("LoadBalancerArn")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "LoadBalancerArn", valid_593459
  var valid_593460 = query.getOrDefault("ListenerArns")
  valid_593460 = validateParameter(valid_593460, JArray, required = false,
                                 default = nil)
  if valid_593460 != nil:
    section.add "ListenerArns", valid_593460
  var valid_593461 = query.getOrDefault("PageSize")
  valid_593461 = validateParameter(valid_593461, JInt, required = false, default = nil)
  if valid_593461 != nil:
    section.add "PageSize", valid_593461
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593462 = query.getOrDefault("Action")
  valid_593462 = validateParameter(valid_593462, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_593462 != nil:
    section.add "Action", valid_593462
  var valid_593463 = query.getOrDefault("Version")
  valid_593463 = validateParameter(valid_593463, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593463 != nil:
    section.add "Version", valid_593463
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
  var valid_593464 = header.getOrDefault("X-Amz-Signature")
  valid_593464 = validateParameter(valid_593464, JString, required = false,
                                 default = nil)
  if valid_593464 != nil:
    section.add "X-Amz-Signature", valid_593464
  var valid_593465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-Content-Sha256", valid_593465
  var valid_593466 = header.getOrDefault("X-Amz-Date")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "X-Amz-Date", valid_593466
  var valid_593467 = header.getOrDefault("X-Amz-Credential")
  valid_593467 = validateParameter(valid_593467, JString, required = false,
                                 default = nil)
  if valid_593467 != nil:
    section.add "X-Amz-Credential", valid_593467
  var valid_593468 = header.getOrDefault("X-Amz-Security-Token")
  valid_593468 = validateParameter(valid_593468, JString, required = false,
                                 default = nil)
  if valid_593468 != nil:
    section.add "X-Amz-Security-Token", valid_593468
  var valid_593469 = header.getOrDefault("X-Amz-Algorithm")
  valid_593469 = validateParameter(valid_593469, JString, required = false,
                                 default = nil)
  if valid_593469 != nil:
    section.add "X-Amz-Algorithm", valid_593469
  var valid_593470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593470 = validateParameter(valid_593470, JString, required = false,
                                 default = nil)
  if valid_593470 != nil:
    section.add "X-Amz-SignedHeaders", valid_593470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593471: Call_GetDescribeListeners_593455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_593471.validator(path, query, header, formData, body)
  let scheme = call_593471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593471.url(scheme.get, call_593471.host, call_593471.base,
                         call_593471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593471, url, valid)

proc call*(call_593472: Call_GetDescribeListeners_593455; Marker: string = "";
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
  var query_593473 = newJObject()
  add(query_593473, "Marker", newJString(Marker))
  add(query_593473, "LoadBalancerArn", newJString(LoadBalancerArn))
  if ListenerArns != nil:
    query_593473.add "ListenerArns", ListenerArns
  add(query_593473, "PageSize", newJInt(PageSize))
  add(query_593473, "Action", newJString(Action))
  add(query_593473, "Version", newJString(Version))
  result = call_593472.call(nil, query_593473, nil, nil, nil)

var getDescribeListeners* = Call_GetDescribeListeners_593455(
    name: "getDescribeListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners", validator: validate_GetDescribeListeners_593456,
    base: "/", url: url_GetDescribeListeners_593457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_593510 = ref object of OpenApiRestCall_592364
proc url_PostDescribeLoadBalancerAttributes_593512(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancerAttributes_593511(path: JsonNode;
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
  var valid_593513 = query.getOrDefault("Action")
  valid_593513 = validateParameter(valid_593513, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_593513 != nil:
    section.add "Action", valid_593513
  var valid_593514 = query.getOrDefault("Version")
  valid_593514 = validateParameter(valid_593514, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593514 != nil:
    section.add "Version", valid_593514
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
  var valid_593515 = header.getOrDefault("X-Amz-Signature")
  valid_593515 = validateParameter(valid_593515, JString, required = false,
                                 default = nil)
  if valid_593515 != nil:
    section.add "X-Amz-Signature", valid_593515
  var valid_593516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593516 = validateParameter(valid_593516, JString, required = false,
                                 default = nil)
  if valid_593516 != nil:
    section.add "X-Amz-Content-Sha256", valid_593516
  var valid_593517 = header.getOrDefault("X-Amz-Date")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "X-Amz-Date", valid_593517
  var valid_593518 = header.getOrDefault("X-Amz-Credential")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "X-Amz-Credential", valid_593518
  var valid_593519 = header.getOrDefault("X-Amz-Security-Token")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "X-Amz-Security-Token", valid_593519
  var valid_593520 = header.getOrDefault("X-Amz-Algorithm")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "X-Amz-Algorithm", valid_593520
  var valid_593521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-SignedHeaders", valid_593521
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_593522 = formData.getOrDefault("LoadBalancerArn")
  valid_593522 = validateParameter(valid_593522, JString, required = true,
                                 default = nil)
  if valid_593522 != nil:
    section.add "LoadBalancerArn", valid_593522
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593523: Call_PostDescribeLoadBalancerAttributes_593510;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593523.validator(path, query, header, formData, body)
  let scheme = call_593523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593523.url(scheme.get, call_593523.host, call_593523.base,
                         call_593523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593523, url, valid)

proc call*(call_593524: Call_PostDescribeLoadBalancerAttributes_593510;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_593525 = newJObject()
  var formData_593526 = newJObject()
  add(query_593525, "Action", newJString(Action))
  add(query_593525, "Version", newJString(Version))
  add(formData_593526, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_593524.call(nil, query_593525, nil, formData_593526, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_593510(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_593511, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_593512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_593494 = ref object of OpenApiRestCall_592364
proc url_GetDescribeLoadBalancerAttributes_593496(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancerAttributes_593495(path: JsonNode;
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
  var valid_593497 = query.getOrDefault("LoadBalancerArn")
  valid_593497 = validateParameter(valid_593497, JString, required = true,
                                 default = nil)
  if valid_593497 != nil:
    section.add "LoadBalancerArn", valid_593497
  var valid_593498 = query.getOrDefault("Action")
  valid_593498 = validateParameter(valid_593498, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_593498 != nil:
    section.add "Action", valid_593498
  var valid_593499 = query.getOrDefault("Version")
  valid_593499 = validateParameter(valid_593499, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593499 != nil:
    section.add "Version", valid_593499
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
  var valid_593500 = header.getOrDefault("X-Amz-Signature")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "X-Amz-Signature", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Content-Sha256", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-Date")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-Date", valid_593502
  var valid_593503 = header.getOrDefault("X-Amz-Credential")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-Credential", valid_593503
  var valid_593504 = header.getOrDefault("X-Amz-Security-Token")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "X-Amz-Security-Token", valid_593504
  var valid_593505 = header.getOrDefault("X-Amz-Algorithm")
  valid_593505 = validateParameter(valid_593505, JString, required = false,
                                 default = nil)
  if valid_593505 != nil:
    section.add "X-Amz-Algorithm", valid_593505
  var valid_593506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593506 = validateParameter(valid_593506, JString, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "X-Amz-SignedHeaders", valid_593506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593507: Call_GetDescribeLoadBalancerAttributes_593494;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593507.validator(path, query, header, formData, body)
  let scheme = call_593507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593507.url(scheme.get, call_593507.host, call_593507.base,
                         call_593507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593507, url, valid)

proc call*(call_593508: Call_GetDescribeLoadBalancerAttributes_593494;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593509 = newJObject()
  add(query_593509, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_593509, "Action", newJString(Action))
  add(query_593509, "Version", newJString(Version))
  result = call_593508.call(nil, query_593509, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_593494(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_593495, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_593496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_593546 = ref object of OpenApiRestCall_592364
proc url_PostDescribeLoadBalancers_593548(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancers_593547(path: JsonNode; query: JsonNode;
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
  var valid_593549 = query.getOrDefault("Action")
  valid_593549 = validateParameter(valid_593549, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_593549 != nil:
    section.add "Action", valid_593549
  var valid_593550 = query.getOrDefault("Version")
  valid_593550 = validateParameter(valid_593550, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593550 != nil:
    section.add "Version", valid_593550
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
  var valid_593551 = header.getOrDefault("X-Amz-Signature")
  valid_593551 = validateParameter(valid_593551, JString, required = false,
                                 default = nil)
  if valid_593551 != nil:
    section.add "X-Amz-Signature", valid_593551
  var valid_593552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593552 = validateParameter(valid_593552, JString, required = false,
                                 default = nil)
  if valid_593552 != nil:
    section.add "X-Amz-Content-Sha256", valid_593552
  var valid_593553 = header.getOrDefault("X-Amz-Date")
  valid_593553 = validateParameter(valid_593553, JString, required = false,
                                 default = nil)
  if valid_593553 != nil:
    section.add "X-Amz-Date", valid_593553
  var valid_593554 = header.getOrDefault("X-Amz-Credential")
  valid_593554 = validateParameter(valid_593554, JString, required = false,
                                 default = nil)
  if valid_593554 != nil:
    section.add "X-Amz-Credential", valid_593554
  var valid_593555 = header.getOrDefault("X-Amz-Security-Token")
  valid_593555 = validateParameter(valid_593555, JString, required = false,
                                 default = nil)
  if valid_593555 != nil:
    section.add "X-Amz-Security-Token", valid_593555
  var valid_593556 = header.getOrDefault("X-Amz-Algorithm")
  valid_593556 = validateParameter(valid_593556, JString, required = false,
                                 default = nil)
  if valid_593556 != nil:
    section.add "X-Amz-Algorithm", valid_593556
  var valid_593557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593557 = validateParameter(valid_593557, JString, required = false,
                                 default = nil)
  if valid_593557 != nil:
    section.add "X-Amz-SignedHeaders", valid_593557
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
  var valid_593558 = formData.getOrDefault("Names")
  valid_593558 = validateParameter(valid_593558, JArray, required = false,
                                 default = nil)
  if valid_593558 != nil:
    section.add "Names", valid_593558
  var valid_593559 = formData.getOrDefault("Marker")
  valid_593559 = validateParameter(valid_593559, JString, required = false,
                                 default = nil)
  if valid_593559 != nil:
    section.add "Marker", valid_593559
  var valid_593560 = formData.getOrDefault("PageSize")
  valid_593560 = validateParameter(valid_593560, JInt, required = false, default = nil)
  if valid_593560 != nil:
    section.add "PageSize", valid_593560
  var valid_593561 = formData.getOrDefault("LoadBalancerArns")
  valid_593561 = validateParameter(valid_593561, JArray, required = false,
                                 default = nil)
  if valid_593561 != nil:
    section.add "LoadBalancerArns", valid_593561
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593562: Call_PostDescribeLoadBalancers_593546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_593562.validator(path, query, header, formData, body)
  let scheme = call_593562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593562.url(scheme.get, call_593562.host, call_593562.base,
                         call_593562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593562, url, valid)

proc call*(call_593563: Call_PostDescribeLoadBalancers_593546;
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
  var query_593564 = newJObject()
  var formData_593565 = newJObject()
  if Names != nil:
    formData_593565.add "Names", Names
  add(formData_593565, "Marker", newJString(Marker))
  add(query_593564, "Action", newJString(Action))
  add(formData_593565, "PageSize", newJInt(PageSize))
  add(query_593564, "Version", newJString(Version))
  if LoadBalancerArns != nil:
    formData_593565.add "LoadBalancerArns", LoadBalancerArns
  result = call_593563.call(nil, query_593564, nil, formData_593565, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_593546(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_593547, base: "/",
    url: url_PostDescribeLoadBalancers_593548,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_593527 = ref object of OpenApiRestCall_592364
proc url_GetDescribeLoadBalancers_593529(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancers_593528(path: JsonNode; query: JsonNode;
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
  var valid_593530 = query.getOrDefault("Marker")
  valid_593530 = validateParameter(valid_593530, JString, required = false,
                                 default = nil)
  if valid_593530 != nil:
    section.add "Marker", valid_593530
  var valid_593531 = query.getOrDefault("PageSize")
  valid_593531 = validateParameter(valid_593531, JInt, required = false, default = nil)
  if valid_593531 != nil:
    section.add "PageSize", valid_593531
  var valid_593532 = query.getOrDefault("LoadBalancerArns")
  valid_593532 = validateParameter(valid_593532, JArray, required = false,
                                 default = nil)
  if valid_593532 != nil:
    section.add "LoadBalancerArns", valid_593532
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593533 = query.getOrDefault("Action")
  valid_593533 = validateParameter(valid_593533, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_593533 != nil:
    section.add "Action", valid_593533
  var valid_593534 = query.getOrDefault("Version")
  valid_593534 = validateParameter(valid_593534, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593534 != nil:
    section.add "Version", valid_593534
  var valid_593535 = query.getOrDefault("Names")
  valid_593535 = validateParameter(valid_593535, JArray, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "Names", valid_593535
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
  var valid_593536 = header.getOrDefault("X-Amz-Signature")
  valid_593536 = validateParameter(valid_593536, JString, required = false,
                                 default = nil)
  if valid_593536 != nil:
    section.add "X-Amz-Signature", valid_593536
  var valid_593537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593537 = validateParameter(valid_593537, JString, required = false,
                                 default = nil)
  if valid_593537 != nil:
    section.add "X-Amz-Content-Sha256", valid_593537
  var valid_593538 = header.getOrDefault("X-Amz-Date")
  valid_593538 = validateParameter(valid_593538, JString, required = false,
                                 default = nil)
  if valid_593538 != nil:
    section.add "X-Amz-Date", valid_593538
  var valid_593539 = header.getOrDefault("X-Amz-Credential")
  valid_593539 = validateParameter(valid_593539, JString, required = false,
                                 default = nil)
  if valid_593539 != nil:
    section.add "X-Amz-Credential", valid_593539
  var valid_593540 = header.getOrDefault("X-Amz-Security-Token")
  valid_593540 = validateParameter(valid_593540, JString, required = false,
                                 default = nil)
  if valid_593540 != nil:
    section.add "X-Amz-Security-Token", valid_593540
  var valid_593541 = header.getOrDefault("X-Amz-Algorithm")
  valid_593541 = validateParameter(valid_593541, JString, required = false,
                                 default = nil)
  if valid_593541 != nil:
    section.add "X-Amz-Algorithm", valid_593541
  var valid_593542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593542 = validateParameter(valid_593542, JString, required = false,
                                 default = nil)
  if valid_593542 != nil:
    section.add "X-Amz-SignedHeaders", valid_593542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593543: Call_GetDescribeLoadBalancers_593527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_593543.validator(path, query, header, formData, body)
  let scheme = call_593543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593543.url(scheme.get, call_593543.host, call_593543.base,
                         call_593543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593543, url, valid)

proc call*(call_593544: Call_GetDescribeLoadBalancers_593527; Marker: string = "";
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
  var query_593545 = newJObject()
  add(query_593545, "Marker", newJString(Marker))
  add(query_593545, "PageSize", newJInt(PageSize))
  if LoadBalancerArns != nil:
    query_593545.add "LoadBalancerArns", LoadBalancerArns
  add(query_593545, "Action", newJString(Action))
  add(query_593545, "Version", newJString(Version))
  if Names != nil:
    query_593545.add "Names", Names
  result = call_593544.call(nil, query_593545, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_593527(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_593528, base: "/",
    url: url_GetDescribeLoadBalancers_593529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRules_593585 = ref object of OpenApiRestCall_592364
proc url_PostDescribeRules_593587(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeRules_593586(path: JsonNode; query: JsonNode;
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
  var valid_593588 = query.getOrDefault("Action")
  valid_593588 = validateParameter(valid_593588, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_593588 != nil:
    section.add "Action", valid_593588
  var valid_593589 = query.getOrDefault("Version")
  valid_593589 = validateParameter(valid_593589, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593589 != nil:
    section.add "Version", valid_593589
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
  var valid_593590 = header.getOrDefault("X-Amz-Signature")
  valid_593590 = validateParameter(valid_593590, JString, required = false,
                                 default = nil)
  if valid_593590 != nil:
    section.add "X-Amz-Signature", valid_593590
  var valid_593591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593591 = validateParameter(valid_593591, JString, required = false,
                                 default = nil)
  if valid_593591 != nil:
    section.add "X-Amz-Content-Sha256", valid_593591
  var valid_593592 = header.getOrDefault("X-Amz-Date")
  valid_593592 = validateParameter(valid_593592, JString, required = false,
                                 default = nil)
  if valid_593592 != nil:
    section.add "X-Amz-Date", valid_593592
  var valid_593593 = header.getOrDefault("X-Amz-Credential")
  valid_593593 = validateParameter(valid_593593, JString, required = false,
                                 default = nil)
  if valid_593593 != nil:
    section.add "X-Amz-Credential", valid_593593
  var valid_593594 = header.getOrDefault("X-Amz-Security-Token")
  valid_593594 = validateParameter(valid_593594, JString, required = false,
                                 default = nil)
  if valid_593594 != nil:
    section.add "X-Amz-Security-Token", valid_593594
  var valid_593595 = header.getOrDefault("X-Amz-Algorithm")
  valid_593595 = validateParameter(valid_593595, JString, required = false,
                                 default = nil)
  if valid_593595 != nil:
    section.add "X-Amz-Algorithm", valid_593595
  var valid_593596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593596 = validateParameter(valid_593596, JString, required = false,
                                 default = nil)
  if valid_593596 != nil:
    section.add "X-Amz-SignedHeaders", valid_593596
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
  var valid_593597 = formData.getOrDefault("ListenerArn")
  valid_593597 = validateParameter(valid_593597, JString, required = false,
                                 default = nil)
  if valid_593597 != nil:
    section.add "ListenerArn", valid_593597
  var valid_593598 = formData.getOrDefault("Marker")
  valid_593598 = validateParameter(valid_593598, JString, required = false,
                                 default = nil)
  if valid_593598 != nil:
    section.add "Marker", valid_593598
  var valid_593599 = formData.getOrDefault("RuleArns")
  valid_593599 = validateParameter(valid_593599, JArray, required = false,
                                 default = nil)
  if valid_593599 != nil:
    section.add "RuleArns", valid_593599
  var valid_593600 = formData.getOrDefault("PageSize")
  valid_593600 = validateParameter(valid_593600, JInt, required = false, default = nil)
  if valid_593600 != nil:
    section.add "PageSize", valid_593600
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593601: Call_PostDescribeRules_593585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_593601.validator(path, query, header, formData, body)
  let scheme = call_593601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593601.url(scheme.get, call_593601.host, call_593601.base,
                         call_593601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593601, url, valid)

proc call*(call_593602: Call_PostDescribeRules_593585; ListenerArn: string = "";
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
  var query_593603 = newJObject()
  var formData_593604 = newJObject()
  add(formData_593604, "ListenerArn", newJString(ListenerArn))
  add(formData_593604, "Marker", newJString(Marker))
  if RuleArns != nil:
    formData_593604.add "RuleArns", RuleArns
  add(query_593603, "Action", newJString(Action))
  add(formData_593604, "PageSize", newJInt(PageSize))
  add(query_593603, "Version", newJString(Version))
  result = call_593602.call(nil, query_593603, nil, formData_593604, nil)

var postDescribeRules* = Call_PostDescribeRules_593585(name: "postDescribeRules",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_PostDescribeRules_593586,
    base: "/", url: url_PostDescribeRules_593587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRules_593566 = ref object of OpenApiRestCall_592364
proc url_GetDescribeRules_593568(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeRules_593567(path: JsonNode; query: JsonNode;
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
  var valid_593569 = query.getOrDefault("Marker")
  valid_593569 = validateParameter(valid_593569, JString, required = false,
                                 default = nil)
  if valid_593569 != nil:
    section.add "Marker", valid_593569
  var valid_593570 = query.getOrDefault("ListenerArn")
  valid_593570 = validateParameter(valid_593570, JString, required = false,
                                 default = nil)
  if valid_593570 != nil:
    section.add "ListenerArn", valid_593570
  var valid_593571 = query.getOrDefault("PageSize")
  valid_593571 = validateParameter(valid_593571, JInt, required = false, default = nil)
  if valid_593571 != nil:
    section.add "PageSize", valid_593571
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593572 = query.getOrDefault("Action")
  valid_593572 = validateParameter(valid_593572, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_593572 != nil:
    section.add "Action", valid_593572
  var valid_593573 = query.getOrDefault("Version")
  valid_593573 = validateParameter(valid_593573, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593573 != nil:
    section.add "Version", valid_593573
  var valid_593574 = query.getOrDefault("RuleArns")
  valid_593574 = validateParameter(valid_593574, JArray, required = false,
                                 default = nil)
  if valid_593574 != nil:
    section.add "RuleArns", valid_593574
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
  var valid_593575 = header.getOrDefault("X-Amz-Signature")
  valid_593575 = validateParameter(valid_593575, JString, required = false,
                                 default = nil)
  if valid_593575 != nil:
    section.add "X-Amz-Signature", valid_593575
  var valid_593576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593576 = validateParameter(valid_593576, JString, required = false,
                                 default = nil)
  if valid_593576 != nil:
    section.add "X-Amz-Content-Sha256", valid_593576
  var valid_593577 = header.getOrDefault("X-Amz-Date")
  valid_593577 = validateParameter(valid_593577, JString, required = false,
                                 default = nil)
  if valid_593577 != nil:
    section.add "X-Amz-Date", valid_593577
  var valid_593578 = header.getOrDefault("X-Amz-Credential")
  valid_593578 = validateParameter(valid_593578, JString, required = false,
                                 default = nil)
  if valid_593578 != nil:
    section.add "X-Amz-Credential", valid_593578
  var valid_593579 = header.getOrDefault("X-Amz-Security-Token")
  valid_593579 = validateParameter(valid_593579, JString, required = false,
                                 default = nil)
  if valid_593579 != nil:
    section.add "X-Amz-Security-Token", valid_593579
  var valid_593580 = header.getOrDefault("X-Amz-Algorithm")
  valid_593580 = validateParameter(valid_593580, JString, required = false,
                                 default = nil)
  if valid_593580 != nil:
    section.add "X-Amz-Algorithm", valid_593580
  var valid_593581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593581 = validateParameter(valid_593581, JString, required = false,
                                 default = nil)
  if valid_593581 != nil:
    section.add "X-Amz-SignedHeaders", valid_593581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593582: Call_GetDescribeRules_593566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_593582.validator(path, query, header, formData, body)
  let scheme = call_593582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593582.url(scheme.get, call_593582.host, call_593582.base,
                         call_593582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593582, url, valid)

proc call*(call_593583: Call_GetDescribeRules_593566; Marker: string = "";
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
  var query_593584 = newJObject()
  add(query_593584, "Marker", newJString(Marker))
  add(query_593584, "ListenerArn", newJString(ListenerArn))
  add(query_593584, "PageSize", newJInt(PageSize))
  add(query_593584, "Action", newJString(Action))
  add(query_593584, "Version", newJString(Version))
  if RuleArns != nil:
    query_593584.add "RuleArns", RuleArns
  result = call_593583.call(nil, query_593584, nil, nil, nil)

var getDescribeRules* = Call_GetDescribeRules_593566(name: "getDescribeRules",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_GetDescribeRules_593567,
    base: "/", url: url_GetDescribeRules_593568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSSLPolicies_593623 = ref object of OpenApiRestCall_592364
proc url_PostDescribeSSLPolicies_593625(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeSSLPolicies_593624(path: JsonNode; query: JsonNode;
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
  var valid_593626 = query.getOrDefault("Action")
  valid_593626 = validateParameter(valid_593626, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_593626 != nil:
    section.add "Action", valid_593626
  var valid_593627 = query.getOrDefault("Version")
  valid_593627 = validateParameter(valid_593627, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593627 != nil:
    section.add "Version", valid_593627
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
  var valid_593628 = header.getOrDefault("X-Amz-Signature")
  valid_593628 = validateParameter(valid_593628, JString, required = false,
                                 default = nil)
  if valid_593628 != nil:
    section.add "X-Amz-Signature", valid_593628
  var valid_593629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593629 = validateParameter(valid_593629, JString, required = false,
                                 default = nil)
  if valid_593629 != nil:
    section.add "X-Amz-Content-Sha256", valid_593629
  var valid_593630 = header.getOrDefault("X-Amz-Date")
  valid_593630 = validateParameter(valid_593630, JString, required = false,
                                 default = nil)
  if valid_593630 != nil:
    section.add "X-Amz-Date", valid_593630
  var valid_593631 = header.getOrDefault("X-Amz-Credential")
  valid_593631 = validateParameter(valid_593631, JString, required = false,
                                 default = nil)
  if valid_593631 != nil:
    section.add "X-Amz-Credential", valid_593631
  var valid_593632 = header.getOrDefault("X-Amz-Security-Token")
  valid_593632 = validateParameter(valid_593632, JString, required = false,
                                 default = nil)
  if valid_593632 != nil:
    section.add "X-Amz-Security-Token", valid_593632
  var valid_593633 = header.getOrDefault("X-Amz-Algorithm")
  valid_593633 = validateParameter(valid_593633, JString, required = false,
                                 default = nil)
  if valid_593633 != nil:
    section.add "X-Amz-Algorithm", valid_593633
  var valid_593634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593634 = validateParameter(valid_593634, JString, required = false,
                                 default = nil)
  if valid_593634 != nil:
    section.add "X-Amz-SignedHeaders", valid_593634
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the policies.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_593635 = formData.getOrDefault("Names")
  valid_593635 = validateParameter(valid_593635, JArray, required = false,
                                 default = nil)
  if valid_593635 != nil:
    section.add "Names", valid_593635
  var valid_593636 = formData.getOrDefault("Marker")
  valid_593636 = validateParameter(valid_593636, JString, required = false,
                                 default = nil)
  if valid_593636 != nil:
    section.add "Marker", valid_593636
  var valid_593637 = formData.getOrDefault("PageSize")
  valid_593637 = validateParameter(valid_593637, JInt, required = false, default = nil)
  if valid_593637 != nil:
    section.add "PageSize", valid_593637
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593638: Call_PostDescribeSSLPolicies_593623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593638.validator(path, query, header, formData, body)
  let scheme = call_593638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593638.url(scheme.get, call_593638.host, call_593638.base,
                         call_593638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593638, url, valid)

proc call*(call_593639: Call_PostDescribeSSLPolicies_593623; Names: JsonNode = nil;
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
  var query_593640 = newJObject()
  var formData_593641 = newJObject()
  if Names != nil:
    formData_593641.add "Names", Names
  add(formData_593641, "Marker", newJString(Marker))
  add(query_593640, "Action", newJString(Action))
  add(formData_593641, "PageSize", newJInt(PageSize))
  add(query_593640, "Version", newJString(Version))
  result = call_593639.call(nil, query_593640, nil, formData_593641, nil)

var postDescribeSSLPolicies* = Call_PostDescribeSSLPolicies_593623(
    name: "postDescribeSSLPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_PostDescribeSSLPolicies_593624, base: "/",
    url: url_PostDescribeSSLPolicies_593625, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSSLPolicies_593605 = ref object of OpenApiRestCall_592364
proc url_GetDescribeSSLPolicies_593607(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeSSLPolicies_593606(path: JsonNode; query: JsonNode;
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
  var valid_593608 = query.getOrDefault("Marker")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "Marker", valid_593608
  var valid_593609 = query.getOrDefault("PageSize")
  valid_593609 = validateParameter(valid_593609, JInt, required = false, default = nil)
  if valid_593609 != nil:
    section.add "PageSize", valid_593609
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593610 = query.getOrDefault("Action")
  valid_593610 = validateParameter(valid_593610, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_593610 != nil:
    section.add "Action", valid_593610
  var valid_593611 = query.getOrDefault("Version")
  valid_593611 = validateParameter(valid_593611, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593611 != nil:
    section.add "Version", valid_593611
  var valid_593612 = query.getOrDefault("Names")
  valid_593612 = validateParameter(valid_593612, JArray, required = false,
                                 default = nil)
  if valid_593612 != nil:
    section.add "Names", valid_593612
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
  var valid_593613 = header.getOrDefault("X-Amz-Signature")
  valid_593613 = validateParameter(valid_593613, JString, required = false,
                                 default = nil)
  if valid_593613 != nil:
    section.add "X-Amz-Signature", valid_593613
  var valid_593614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593614 = validateParameter(valid_593614, JString, required = false,
                                 default = nil)
  if valid_593614 != nil:
    section.add "X-Amz-Content-Sha256", valid_593614
  var valid_593615 = header.getOrDefault("X-Amz-Date")
  valid_593615 = validateParameter(valid_593615, JString, required = false,
                                 default = nil)
  if valid_593615 != nil:
    section.add "X-Amz-Date", valid_593615
  var valid_593616 = header.getOrDefault("X-Amz-Credential")
  valid_593616 = validateParameter(valid_593616, JString, required = false,
                                 default = nil)
  if valid_593616 != nil:
    section.add "X-Amz-Credential", valid_593616
  var valid_593617 = header.getOrDefault("X-Amz-Security-Token")
  valid_593617 = validateParameter(valid_593617, JString, required = false,
                                 default = nil)
  if valid_593617 != nil:
    section.add "X-Amz-Security-Token", valid_593617
  var valid_593618 = header.getOrDefault("X-Amz-Algorithm")
  valid_593618 = validateParameter(valid_593618, JString, required = false,
                                 default = nil)
  if valid_593618 != nil:
    section.add "X-Amz-Algorithm", valid_593618
  var valid_593619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593619 = validateParameter(valid_593619, JString, required = false,
                                 default = nil)
  if valid_593619 != nil:
    section.add "X-Amz-SignedHeaders", valid_593619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593620: Call_GetDescribeSSLPolicies_593605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593620.validator(path, query, header, formData, body)
  let scheme = call_593620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593620.url(scheme.get, call_593620.host, call_593620.base,
                         call_593620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593620, url, valid)

proc call*(call_593621: Call_GetDescribeSSLPolicies_593605; Marker: string = "";
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
  var query_593622 = newJObject()
  add(query_593622, "Marker", newJString(Marker))
  add(query_593622, "PageSize", newJInt(PageSize))
  add(query_593622, "Action", newJString(Action))
  add(query_593622, "Version", newJString(Version))
  if Names != nil:
    query_593622.add "Names", Names
  result = call_593621.call(nil, query_593622, nil, nil, nil)

var getDescribeSSLPolicies* = Call_GetDescribeSSLPolicies_593605(
    name: "getDescribeSSLPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_GetDescribeSSLPolicies_593606, base: "/",
    url: url_GetDescribeSSLPolicies_593607, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_593658 = ref object of OpenApiRestCall_592364
proc url_PostDescribeTags_593660(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeTags_593659(path: JsonNode; query: JsonNode;
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
  var valid_593661 = query.getOrDefault("Action")
  valid_593661 = validateParameter(valid_593661, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_593661 != nil:
    section.add "Action", valid_593661
  var valid_593662 = query.getOrDefault("Version")
  valid_593662 = validateParameter(valid_593662, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593662 != nil:
    section.add "Version", valid_593662
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
  var valid_593663 = header.getOrDefault("X-Amz-Signature")
  valid_593663 = validateParameter(valid_593663, JString, required = false,
                                 default = nil)
  if valid_593663 != nil:
    section.add "X-Amz-Signature", valid_593663
  var valid_593664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593664 = validateParameter(valid_593664, JString, required = false,
                                 default = nil)
  if valid_593664 != nil:
    section.add "X-Amz-Content-Sha256", valid_593664
  var valid_593665 = header.getOrDefault("X-Amz-Date")
  valid_593665 = validateParameter(valid_593665, JString, required = false,
                                 default = nil)
  if valid_593665 != nil:
    section.add "X-Amz-Date", valid_593665
  var valid_593666 = header.getOrDefault("X-Amz-Credential")
  valid_593666 = validateParameter(valid_593666, JString, required = false,
                                 default = nil)
  if valid_593666 != nil:
    section.add "X-Amz-Credential", valid_593666
  var valid_593667 = header.getOrDefault("X-Amz-Security-Token")
  valid_593667 = validateParameter(valid_593667, JString, required = false,
                                 default = nil)
  if valid_593667 != nil:
    section.add "X-Amz-Security-Token", valid_593667
  var valid_593668 = header.getOrDefault("X-Amz-Algorithm")
  valid_593668 = validateParameter(valid_593668, JString, required = false,
                                 default = nil)
  if valid_593668 != nil:
    section.add "X-Amz-Algorithm", valid_593668
  var valid_593669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593669 = validateParameter(valid_593669, JString, required = false,
                                 default = nil)
  if valid_593669 != nil:
    section.add "X-Amz-SignedHeaders", valid_593669
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_593670 = formData.getOrDefault("ResourceArns")
  valid_593670 = validateParameter(valid_593670, JArray, required = true, default = nil)
  if valid_593670 != nil:
    section.add "ResourceArns", valid_593670
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593671: Call_PostDescribeTags_593658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_593671.validator(path, query, header, formData, body)
  let scheme = call_593671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593671.url(scheme.get, call_593671.host, call_593671.base,
                         call_593671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593671, url, valid)

proc call*(call_593672: Call_PostDescribeTags_593658; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593673 = newJObject()
  var formData_593674 = newJObject()
  if ResourceArns != nil:
    formData_593674.add "ResourceArns", ResourceArns
  add(query_593673, "Action", newJString(Action))
  add(query_593673, "Version", newJString(Version))
  result = call_593672.call(nil, query_593673, nil, formData_593674, nil)

var postDescribeTags* = Call_PostDescribeTags_593658(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_593659,
    base: "/", url: url_PostDescribeTags_593660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_593642 = ref object of OpenApiRestCall_592364
proc url_GetDescribeTags_593644(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeTags_593643(path: JsonNode; query: JsonNode;
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
  var valid_593645 = query.getOrDefault("ResourceArns")
  valid_593645 = validateParameter(valid_593645, JArray, required = true, default = nil)
  if valid_593645 != nil:
    section.add "ResourceArns", valid_593645
  var valid_593646 = query.getOrDefault("Action")
  valid_593646 = validateParameter(valid_593646, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_593646 != nil:
    section.add "Action", valid_593646
  var valid_593647 = query.getOrDefault("Version")
  valid_593647 = validateParameter(valid_593647, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593647 != nil:
    section.add "Version", valid_593647
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
  var valid_593648 = header.getOrDefault("X-Amz-Signature")
  valid_593648 = validateParameter(valid_593648, JString, required = false,
                                 default = nil)
  if valid_593648 != nil:
    section.add "X-Amz-Signature", valid_593648
  var valid_593649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593649 = validateParameter(valid_593649, JString, required = false,
                                 default = nil)
  if valid_593649 != nil:
    section.add "X-Amz-Content-Sha256", valid_593649
  var valid_593650 = header.getOrDefault("X-Amz-Date")
  valid_593650 = validateParameter(valid_593650, JString, required = false,
                                 default = nil)
  if valid_593650 != nil:
    section.add "X-Amz-Date", valid_593650
  var valid_593651 = header.getOrDefault("X-Amz-Credential")
  valid_593651 = validateParameter(valid_593651, JString, required = false,
                                 default = nil)
  if valid_593651 != nil:
    section.add "X-Amz-Credential", valid_593651
  var valid_593652 = header.getOrDefault("X-Amz-Security-Token")
  valid_593652 = validateParameter(valid_593652, JString, required = false,
                                 default = nil)
  if valid_593652 != nil:
    section.add "X-Amz-Security-Token", valid_593652
  var valid_593653 = header.getOrDefault("X-Amz-Algorithm")
  valid_593653 = validateParameter(valid_593653, JString, required = false,
                                 default = nil)
  if valid_593653 != nil:
    section.add "X-Amz-Algorithm", valid_593653
  var valid_593654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "X-Amz-SignedHeaders", valid_593654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593655: Call_GetDescribeTags_593642; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_593655.validator(path, query, header, formData, body)
  let scheme = call_593655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593655.url(scheme.get, call_593655.host, call_593655.base,
                         call_593655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593655, url, valid)

proc call*(call_593656: Call_GetDescribeTags_593642; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593657 = newJObject()
  if ResourceArns != nil:
    query_593657.add "ResourceArns", ResourceArns
  add(query_593657, "Action", newJString(Action))
  add(query_593657, "Version", newJString(Version))
  result = call_593656.call(nil, query_593657, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_593642(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_593643,
    base: "/", url: url_GetDescribeTags_593644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroupAttributes_593691 = ref object of OpenApiRestCall_592364
proc url_PostDescribeTargetGroupAttributes_593693(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeTargetGroupAttributes_593692(path: JsonNode;
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
  var valid_593694 = query.getOrDefault("Action")
  valid_593694 = validateParameter(valid_593694, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_593694 != nil:
    section.add "Action", valid_593694
  var valid_593695 = query.getOrDefault("Version")
  valid_593695 = validateParameter(valid_593695, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593695 != nil:
    section.add "Version", valid_593695
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
  var valid_593696 = header.getOrDefault("X-Amz-Signature")
  valid_593696 = validateParameter(valid_593696, JString, required = false,
                                 default = nil)
  if valid_593696 != nil:
    section.add "X-Amz-Signature", valid_593696
  var valid_593697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593697 = validateParameter(valid_593697, JString, required = false,
                                 default = nil)
  if valid_593697 != nil:
    section.add "X-Amz-Content-Sha256", valid_593697
  var valid_593698 = header.getOrDefault("X-Amz-Date")
  valid_593698 = validateParameter(valid_593698, JString, required = false,
                                 default = nil)
  if valid_593698 != nil:
    section.add "X-Amz-Date", valid_593698
  var valid_593699 = header.getOrDefault("X-Amz-Credential")
  valid_593699 = validateParameter(valid_593699, JString, required = false,
                                 default = nil)
  if valid_593699 != nil:
    section.add "X-Amz-Credential", valid_593699
  var valid_593700 = header.getOrDefault("X-Amz-Security-Token")
  valid_593700 = validateParameter(valid_593700, JString, required = false,
                                 default = nil)
  if valid_593700 != nil:
    section.add "X-Amz-Security-Token", valid_593700
  var valid_593701 = header.getOrDefault("X-Amz-Algorithm")
  valid_593701 = validateParameter(valid_593701, JString, required = false,
                                 default = nil)
  if valid_593701 != nil:
    section.add "X-Amz-Algorithm", valid_593701
  var valid_593702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593702 = validateParameter(valid_593702, JString, required = false,
                                 default = nil)
  if valid_593702 != nil:
    section.add "X-Amz-SignedHeaders", valid_593702
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_593703 = formData.getOrDefault("TargetGroupArn")
  valid_593703 = validateParameter(valid_593703, JString, required = true,
                                 default = nil)
  if valid_593703 != nil:
    section.add "TargetGroupArn", valid_593703
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593704: Call_PostDescribeTargetGroupAttributes_593691;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593704.validator(path, query, header, formData, body)
  let scheme = call_593704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593704.url(scheme.get, call_593704.host, call_593704.base,
                         call_593704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593704, url, valid)

proc call*(call_593705: Call_PostDescribeTargetGroupAttributes_593691;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_593706 = newJObject()
  var formData_593707 = newJObject()
  add(query_593706, "Action", newJString(Action))
  add(formData_593707, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_593706, "Version", newJString(Version))
  result = call_593705.call(nil, query_593706, nil, formData_593707, nil)

var postDescribeTargetGroupAttributes* = Call_PostDescribeTargetGroupAttributes_593691(
    name: "postDescribeTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_PostDescribeTargetGroupAttributes_593692, base: "/",
    url: url_PostDescribeTargetGroupAttributes_593693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroupAttributes_593675 = ref object of OpenApiRestCall_592364
proc url_GetDescribeTargetGroupAttributes_593677(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeTargetGroupAttributes_593676(path: JsonNode;
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
  var valid_593678 = query.getOrDefault("TargetGroupArn")
  valid_593678 = validateParameter(valid_593678, JString, required = true,
                                 default = nil)
  if valid_593678 != nil:
    section.add "TargetGroupArn", valid_593678
  var valid_593679 = query.getOrDefault("Action")
  valid_593679 = validateParameter(valid_593679, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_593679 != nil:
    section.add "Action", valid_593679
  var valid_593680 = query.getOrDefault("Version")
  valid_593680 = validateParameter(valid_593680, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593680 != nil:
    section.add "Version", valid_593680
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
  var valid_593681 = header.getOrDefault("X-Amz-Signature")
  valid_593681 = validateParameter(valid_593681, JString, required = false,
                                 default = nil)
  if valid_593681 != nil:
    section.add "X-Amz-Signature", valid_593681
  var valid_593682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593682 = validateParameter(valid_593682, JString, required = false,
                                 default = nil)
  if valid_593682 != nil:
    section.add "X-Amz-Content-Sha256", valid_593682
  var valid_593683 = header.getOrDefault("X-Amz-Date")
  valid_593683 = validateParameter(valid_593683, JString, required = false,
                                 default = nil)
  if valid_593683 != nil:
    section.add "X-Amz-Date", valid_593683
  var valid_593684 = header.getOrDefault("X-Amz-Credential")
  valid_593684 = validateParameter(valid_593684, JString, required = false,
                                 default = nil)
  if valid_593684 != nil:
    section.add "X-Amz-Credential", valid_593684
  var valid_593685 = header.getOrDefault("X-Amz-Security-Token")
  valid_593685 = validateParameter(valid_593685, JString, required = false,
                                 default = nil)
  if valid_593685 != nil:
    section.add "X-Amz-Security-Token", valid_593685
  var valid_593686 = header.getOrDefault("X-Amz-Algorithm")
  valid_593686 = validateParameter(valid_593686, JString, required = false,
                                 default = nil)
  if valid_593686 != nil:
    section.add "X-Amz-Algorithm", valid_593686
  var valid_593687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593687 = validateParameter(valid_593687, JString, required = false,
                                 default = nil)
  if valid_593687 != nil:
    section.add "X-Amz-SignedHeaders", valid_593687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593688: Call_GetDescribeTargetGroupAttributes_593675;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593688.validator(path, query, header, formData, body)
  let scheme = call_593688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593688.url(scheme.get, call_593688.host, call_593688.base,
                         call_593688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593688, url, valid)

proc call*(call_593689: Call_GetDescribeTargetGroupAttributes_593675;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593690 = newJObject()
  add(query_593690, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_593690, "Action", newJString(Action))
  add(query_593690, "Version", newJString(Version))
  result = call_593689.call(nil, query_593690, nil, nil, nil)

var getDescribeTargetGroupAttributes* = Call_GetDescribeTargetGroupAttributes_593675(
    name: "getDescribeTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_GetDescribeTargetGroupAttributes_593676, base: "/",
    url: url_GetDescribeTargetGroupAttributes_593677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroups_593728 = ref object of OpenApiRestCall_592364
proc url_PostDescribeTargetGroups_593730(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeTargetGroups_593729(path: JsonNode; query: JsonNode;
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
  var valid_593731 = query.getOrDefault("Action")
  valid_593731 = validateParameter(valid_593731, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_593731 != nil:
    section.add "Action", valid_593731
  var valid_593732 = query.getOrDefault("Version")
  valid_593732 = validateParameter(valid_593732, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593732 != nil:
    section.add "Version", valid_593732
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
  var valid_593733 = header.getOrDefault("X-Amz-Signature")
  valid_593733 = validateParameter(valid_593733, JString, required = false,
                                 default = nil)
  if valid_593733 != nil:
    section.add "X-Amz-Signature", valid_593733
  var valid_593734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593734 = validateParameter(valid_593734, JString, required = false,
                                 default = nil)
  if valid_593734 != nil:
    section.add "X-Amz-Content-Sha256", valid_593734
  var valid_593735 = header.getOrDefault("X-Amz-Date")
  valid_593735 = validateParameter(valid_593735, JString, required = false,
                                 default = nil)
  if valid_593735 != nil:
    section.add "X-Amz-Date", valid_593735
  var valid_593736 = header.getOrDefault("X-Amz-Credential")
  valid_593736 = validateParameter(valid_593736, JString, required = false,
                                 default = nil)
  if valid_593736 != nil:
    section.add "X-Amz-Credential", valid_593736
  var valid_593737 = header.getOrDefault("X-Amz-Security-Token")
  valid_593737 = validateParameter(valid_593737, JString, required = false,
                                 default = nil)
  if valid_593737 != nil:
    section.add "X-Amz-Security-Token", valid_593737
  var valid_593738 = header.getOrDefault("X-Amz-Algorithm")
  valid_593738 = validateParameter(valid_593738, JString, required = false,
                                 default = nil)
  if valid_593738 != nil:
    section.add "X-Amz-Algorithm", valid_593738
  var valid_593739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593739 = validateParameter(valid_593739, JString, required = false,
                                 default = nil)
  if valid_593739 != nil:
    section.add "X-Amz-SignedHeaders", valid_593739
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
  var valid_593740 = formData.getOrDefault("Names")
  valid_593740 = validateParameter(valid_593740, JArray, required = false,
                                 default = nil)
  if valid_593740 != nil:
    section.add "Names", valid_593740
  var valid_593741 = formData.getOrDefault("Marker")
  valid_593741 = validateParameter(valid_593741, JString, required = false,
                                 default = nil)
  if valid_593741 != nil:
    section.add "Marker", valid_593741
  var valid_593742 = formData.getOrDefault("TargetGroupArns")
  valid_593742 = validateParameter(valid_593742, JArray, required = false,
                                 default = nil)
  if valid_593742 != nil:
    section.add "TargetGroupArns", valid_593742
  var valid_593743 = formData.getOrDefault("PageSize")
  valid_593743 = validateParameter(valid_593743, JInt, required = false, default = nil)
  if valid_593743 != nil:
    section.add "PageSize", valid_593743
  var valid_593744 = formData.getOrDefault("LoadBalancerArn")
  valid_593744 = validateParameter(valid_593744, JString, required = false,
                                 default = nil)
  if valid_593744 != nil:
    section.add "LoadBalancerArn", valid_593744
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593745: Call_PostDescribeTargetGroups_593728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_593745.validator(path, query, header, formData, body)
  let scheme = call_593745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593745.url(scheme.get, call_593745.host, call_593745.base,
                         call_593745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593745, url, valid)

proc call*(call_593746: Call_PostDescribeTargetGroups_593728;
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
  var query_593747 = newJObject()
  var formData_593748 = newJObject()
  if Names != nil:
    formData_593748.add "Names", Names
  add(formData_593748, "Marker", newJString(Marker))
  add(query_593747, "Action", newJString(Action))
  if TargetGroupArns != nil:
    formData_593748.add "TargetGroupArns", TargetGroupArns
  add(formData_593748, "PageSize", newJInt(PageSize))
  add(query_593747, "Version", newJString(Version))
  add(formData_593748, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_593746.call(nil, query_593747, nil, formData_593748, nil)

var postDescribeTargetGroups* = Call_PostDescribeTargetGroups_593728(
    name: "postDescribeTargetGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_PostDescribeTargetGroups_593729, base: "/",
    url: url_PostDescribeTargetGroups_593730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroups_593708 = ref object of OpenApiRestCall_592364
proc url_GetDescribeTargetGroups_593710(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeTargetGroups_593709(path: JsonNode; query: JsonNode;
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
  var valid_593711 = query.getOrDefault("Marker")
  valid_593711 = validateParameter(valid_593711, JString, required = false,
                                 default = nil)
  if valid_593711 != nil:
    section.add "Marker", valid_593711
  var valid_593712 = query.getOrDefault("LoadBalancerArn")
  valid_593712 = validateParameter(valid_593712, JString, required = false,
                                 default = nil)
  if valid_593712 != nil:
    section.add "LoadBalancerArn", valid_593712
  var valid_593713 = query.getOrDefault("PageSize")
  valid_593713 = validateParameter(valid_593713, JInt, required = false, default = nil)
  if valid_593713 != nil:
    section.add "PageSize", valid_593713
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593714 = query.getOrDefault("Action")
  valid_593714 = validateParameter(valid_593714, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_593714 != nil:
    section.add "Action", valid_593714
  var valid_593715 = query.getOrDefault("TargetGroupArns")
  valid_593715 = validateParameter(valid_593715, JArray, required = false,
                                 default = nil)
  if valid_593715 != nil:
    section.add "TargetGroupArns", valid_593715
  var valid_593716 = query.getOrDefault("Version")
  valid_593716 = validateParameter(valid_593716, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593716 != nil:
    section.add "Version", valid_593716
  var valid_593717 = query.getOrDefault("Names")
  valid_593717 = validateParameter(valid_593717, JArray, required = false,
                                 default = nil)
  if valid_593717 != nil:
    section.add "Names", valid_593717
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
  var valid_593718 = header.getOrDefault("X-Amz-Signature")
  valid_593718 = validateParameter(valid_593718, JString, required = false,
                                 default = nil)
  if valid_593718 != nil:
    section.add "X-Amz-Signature", valid_593718
  var valid_593719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593719 = validateParameter(valid_593719, JString, required = false,
                                 default = nil)
  if valid_593719 != nil:
    section.add "X-Amz-Content-Sha256", valid_593719
  var valid_593720 = header.getOrDefault("X-Amz-Date")
  valid_593720 = validateParameter(valid_593720, JString, required = false,
                                 default = nil)
  if valid_593720 != nil:
    section.add "X-Amz-Date", valid_593720
  var valid_593721 = header.getOrDefault("X-Amz-Credential")
  valid_593721 = validateParameter(valid_593721, JString, required = false,
                                 default = nil)
  if valid_593721 != nil:
    section.add "X-Amz-Credential", valid_593721
  var valid_593722 = header.getOrDefault("X-Amz-Security-Token")
  valid_593722 = validateParameter(valid_593722, JString, required = false,
                                 default = nil)
  if valid_593722 != nil:
    section.add "X-Amz-Security-Token", valid_593722
  var valid_593723 = header.getOrDefault("X-Amz-Algorithm")
  valid_593723 = validateParameter(valid_593723, JString, required = false,
                                 default = nil)
  if valid_593723 != nil:
    section.add "X-Amz-Algorithm", valid_593723
  var valid_593724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593724 = validateParameter(valid_593724, JString, required = false,
                                 default = nil)
  if valid_593724 != nil:
    section.add "X-Amz-SignedHeaders", valid_593724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593725: Call_GetDescribeTargetGroups_593708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_593725.validator(path, query, header, formData, body)
  let scheme = call_593725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593725.url(scheme.get, call_593725.host, call_593725.base,
                         call_593725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593725, url, valid)

proc call*(call_593726: Call_GetDescribeTargetGroups_593708; Marker: string = "";
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
  var query_593727 = newJObject()
  add(query_593727, "Marker", newJString(Marker))
  add(query_593727, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_593727, "PageSize", newJInt(PageSize))
  add(query_593727, "Action", newJString(Action))
  if TargetGroupArns != nil:
    query_593727.add "TargetGroupArns", TargetGroupArns
  add(query_593727, "Version", newJString(Version))
  if Names != nil:
    query_593727.add "Names", Names
  result = call_593726.call(nil, query_593727, nil, nil, nil)

var getDescribeTargetGroups* = Call_GetDescribeTargetGroups_593708(
    name: "getDescribeTargetGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_GetDescribeTargetGroups_593709, base: "/",
    url: url_GetDescribeTargetGroups_593710, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetHealth_593766 = ref object of OpenApiRestCall_592364
proc url_PostDescribeTargetHealth_593768(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeTargetHealth_593767(path: JsonNode; query: JsonNode;
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
  var valid_593769 = query.getOrDefault("Action")
  valid_593769 = validateParameter(valid_593769, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_593769 != nil:
    section.add "Action", valid_593769
  var valid_593770 = query.getOrDefault("Version")
  valid_593770 = validateParameter(valid_593770, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593770 != nil:
    section.add "Version", valid_593770
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
  var valid_593771 = header.getOrDefault("X-Amz-Signature")
  valid_593771 = validateParameter(valid_593771, JString, required = false,
                                 default = nil)
  if valid_593771 != nil:
    section.add "X-Amz-Signature", valid_593771
  var valid_593772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593772 = validateParameter(valid_593772, JString, required = false,
                                 default = nil)
  if valid_593772 != nil:
    section.add "X-Amz-Content-Sha256", valid_593772
  var valid_593773 = header.getOrDefault("X-Amz-Date")
  valid_593773 = validateParameter(valid_593773, JString, required = false,
                                 default = nil)
  if valid_593773 != nil:
    section.add "X-Amz-Date", valid_593773
  var valid_593774 = header.getOrDefault("X-Amz-Credential")
  valid_593774 = validateParameter(valid_593774, JString, required = false,
                                 default = nil)
  if valid_593774 != nil:
    section.add "X-Amz-Credential", valid_593774
  var valid_593775 = header.getOrDefault("X-Amz-Security-Token")
  valid_593775 = validateParameter(valid_593775, JString, required = false,
                                 default = nil)
  if valid_593775 != nil:
    section.add "X-Amz-Security-Token", valid_593775
  var valid_593776 = header.getOrDefault("X-Amz-Algorithm")
  valid_593776 = validateParameter(valid_593776, JString, required = false,
                                 default = nil)
  if valid_593776 != nil:
    section.add "X-Amz-Algorithm", valid_593776
  var valid_593777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593777 = validateParameter(valid_593777, JString, required = false,
                                 default = nil)
  if valid_593777 != nil:
    section.add "X-Amz-SignedHeaders", valid_593777
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_593778 = formData.getOrDefault("Targets")
  valid_593778 = validateParameter(valid_593778, JArray, required = false,
                                 default = nil)
  if valid_593778 != nil:
    section.add "Targets", valid_593778
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_593779 = formData.getOrDefault("TargetGroupArn")
  valid_593779 = validateParameter(valid_593779, JString, required = true,
                                 default = nil)
  if valid_593779 != nil:
    section.add "TargetGroupArn", valid_593779
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593780: Call_PostDescribeTargetHealth_593766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_593780.validator(path, query, header, formData, body)
  let scheme = call_593780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593780.url(scheme.get, call_593780.host, call_593780.base,
                         call_593780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593780, url, valid)

proc call*(call_593781: Call_PostDescribeTargetHealth_593766;
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
  var query_593782 = newJObject()
  var formData_593783 = newJObject()
  if Targets != nil:
    formData_593783.add "Targets", Targets
  add(query_593782, "Action", newJString(Action))
  add(formData_593783, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_593782, "Version", newJString(Version))
  result = call_593781.call(nil, query_593782, nil, formData_593783, nil)

var postDescribeTargetHealth* = Call_PostDescribeTargetHealth_593766(
    name: "postDescribeTargetHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_PostDescribeTargetHealth_593767, base: "/",
    url: url_PostDescribeTargetHealth_593768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetHealth_593749 = ref object of OpenApiRestCall_592364
proc url_GetDescribeTargetHealth_593751(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeTargetHealth_593750(path: JsonNode; query: JsonNode;
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
  var valid_593752 = query.getOrDefault("Targets")
  valid_593752 = validateParameter(valid_593752, JArray, required = false,
                                 default = nil)
  if valid_593752 != nil:
    section.add "Targets", valid_593752
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_593753 = query.getOrDefault("TargetGroupArn")
  valid_593753 = validateParameter(valid_593753, JString, required = true,
                                 default = nil)
  if valid_593753 != nil:
    section.add "TargetGroupArn", valid_593753
  var valid_593754 = query.getOrDefault("Action")
  valid_593754 = validateParameter(valid_593754, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_593754 != nil:
    section.add "Action", valid_593754
  var valid_593755 = query.getOrDefault("Version")
  valid_593755 = validateParameter(valid_593755, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593755 != nil:
    section.add "Version", valid_593755
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
  var valid_593756 = header.getOrDefault("X-Amz-Signature")
  valid_593756 = validateParameter(valid_593756, JString, required = false,
                                 default = nil)
  if valid_593756 != nil:
    section.add "X-Amz-Signature", valid_593756
  var valid_593757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593757 = validateParameter(valid_593757, JString, required = false,
                                 default = nil)
  if valid_593757 != nil:
    section.add "X-Amz-Content-Sha256", valid_593757
  var valid_593758 = header.getOrDefault("X-Amz-Date")
  valid_593758 = validateParameter(valid_593758, JString, required = false,
                                 default = nil)
  if valid_593758 != nil:
    section.add "X-Amz-Date", valid_593758
  var valid_593759 = header.getOrDefault("X-Amz-Credential")
  valid_593759 = validateParameter(valid_593759, JString, required = false,
                                 default = nil)
  if valid_593759 != nil:
    section.add "X-Amz-Credential", valid_593759
  var valid_593760 = header.getOrDefault("X-Amz-Security-Token")
  valid_593760 = validateParameter(valid_593760, JString, required = false,
                                 default = nil)
  if valid_593760 != nil:
    section.add "X-Amz-Security-Token", valid_593760
  var valid_593761 = header.getOrDefault("X-Amz-Algorithm")
  valid_593761 = validateParameter(valid_593761, JString, required = false,
                                 default = nil)
  if valid_593761 != nil:
    section.add "X-Amz-Algorithm", valid_593761
  var valid_593762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593762 = validateParameter(valid_593762, JString, required = false,
                                 default = nil)
  if valid_593762 != nil:
    section.add "X-Amz-SignedHeaders", valid_593762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593763: Call_GetDescribeTargetHealth_593749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_593763.validator(path, query, header, formData, body)
  let scheme = call_593763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593763.url(scheme.get, call_593763.host, call_593763.base,
                         call_593763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593763, url, valid)

proc call*(call_593764: Call_GetDescribeTargetHealth_593749;
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
  var query_593765 = newJObject()
  if Targets != nil:
    query_593765.add "Targets", Targets
  add(query_593765, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_593765, "Action", newJString(Action))
  add(query_593765, "Version", newJString(Version))
  result = call_593764.call(nil, query_593765, nil, nil, nil)

var getDescribeTargetHealth* = Call_GetDescribeTargetHealth_593749(
    name: "getDescribeTargetHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_GetDescribeTargetHealth_593750, base: "/",
    url: url_GetDescribeTargetHealth_593751, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyListener_593805 = ref object of OpenApiRestCall_592364
proc url_PostModifyListener_593807(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyListener_593806(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
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
  var valid_593808 = query.getOrDefault("Action")
  valid_593808 = validateParameter(valid_593808, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_593808 != nil:
    section.add "Action", valid_593808
  var valid_593809 = query.getOrDefault("Version")
  valid_593809 = validateParameter(valid_593809, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593809 != nil:
    section.add "Version", valid_593809
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
  var valid_593810 = header.getOrDefault("X-Amz-Signature")
  valid_593810 = validateParameter(valid_593810, JString, required = false,
                                 default = nil)
  if valid_593810 != nil:
    section.add "X-Amz-Signature", valid_593810
  var valid_593811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593811 = validateParameter(valid_593811, JString, required = false,
                                 default = nil)
  if valid_593811 != nil:
    section.add "X-Amz-Content-Sha256", valid_593811
  var valid_593812 = header.getOrDefault("X-Amz-Date")
  valid_593812 = validateParameter(valid_593812, JString, required = false,
                                 default = nil)
  if valid_593812 != nil:
    section.add "X-Amz-Date", valid_593812
  var valid_593813 = header.getOrDefault("X-Amz-Credential")
  valid_593813 = validateParameter(valid_593813, JString, required = false,
                                 default = nil)
  if valid_593813 != nil:
    section.add "X-Amz-Credential", valid_593813
  var valid_593814 = header.getOrDefault("X-Amz-Security-Token")
  valid_593814 = validateParameter(valid_593814, JString, required = false,
                                 default = nil)
  if valid_593814 != nil:
    section.add "X-Amz-Security-Token", valid_593814
  var valid_593815 = header.getOrDefault("X-Amz-Algorithm")
  valid_593815 = validateParameter(valid_593815, JString, required = false,
                                 default = nil)
  if valid_593815 != nil:
    section.add "X-Amz-Algorithm", valid_593815
  var valid_593816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593816 = validateParameter(valid_593816, JString, required = false,
                                 default = nil)
  if valid_593816 != nil:
    section.add "X-Amz-SignedHeaders", valid_593816
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : The port for connections from clients to the load balancer.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list, use <a>AddListenerCertificates</a>.</p>
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   DefaultActions: JArray
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Protocol: JString
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   SslPolicy: JString
  ##            : [HTTPS and TLS listeners] The security policy that defines which protocols and ciphers are supported. For more information, see <a 
  ## href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.
  section = newJObject()
  var valid_593817 = formData.getOrDefault("Port")
  valid_593817 = validateParameter(valid_593817, JInt, required = false, default = nil)
  if valid_593817 != nil:
    section.add "Port", valid_593817
  var valid_593818 = formData.getOrDefault("Certificates")
  valid_593818 = validateParameter(valid_593818, JArray, required = false,
                                 default = nil)
  if valid_593818 != nil:
    section.add "Certificates", valid_593818
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_593819 = formData.getOrDefault("ListenerArn")
  valid_593819 = validateParameter(valid_593819, JString, required = true,
                                 default = nil)
  if valid_593819 != nil:
    section.add "ListenerArn", valid_593819
  var valid_593820 = formData.getOrDefault("DefaultActions")
  valid_593820 = validateParameter(valid_593820, JArray, required = false,
                                 default = nil)
  if valid_593820 != nil:
    section.add "DefaultActions", valid_593820
  var valid_593821 = formData.getOrDefault("Protocol")
  valid_593821 = validateParameter(valid_593821, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_593821 != nil:
    section.add "Protocol", valid_593821
  var valid_593822 = formData.getOrDefault("SslPolicy")
  valid_593822 = validateParameter(valid_593822, JString, required = false,
                                 default = nil)
  if valid_593822 != nil:
    section.add "SslPolicy", valid_593822
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593823: Call_PostModifyListener_593805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  let valid = call_593823.validator(path, query, header, formData, body)
  let scheme = call_593823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593823.url(scheme.get, call_593823.host, call_593823.base,
                         call_593823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593823, url, valid)

proc call*(call_593824: Call_PostModifyListener_593805; ListenerArn: string;
          Port: int = 0; Certificates: JsonNode = nil; DefaultActions: JsonNode = nil;
          Protocol: string = "HTTP"; Action: string = "ModifyListener";
          SslPolicy: string = ""; Version: string = "2015-12-01"): Recallable =
  ## postModifyListener
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ##   Port: int
  ##       : The port for connections from clients to the load balancer.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list, use <a>AddListenerCertificates</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   DefaultActions: JArray
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Protocol: string
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   Action: string (required)
  ##   SslPolicy: string
  ##            : [HTTPS and TLS listeners] The security policy that defines which protocols and ciphers are supported. For more information, see <a 
  ## href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.
  ##   Version: string (required)
  var query_593825 = newJObject()
  var formData_593826 = newJObject()
  add(formData_593826, "Port", newJInt(Port))
  if Certificates != nil:
    formData_593826.add "Certificates", Certificates
  add(formData_593826, "ListenerArn", newJString(ListenerArn))
  if DefaultActions != nil:
    formData_593826.add "DefaultActions", DefaultActions
  add(formData_593826, "Protocol", newJString(Protocol))
  add(query_593825, "Action", newJString(Action))
  add(formData_593826, "SslPolicy", newJString(SslPolicy))
  add(query_593825, "Version", newJString(Version))
  result = call_593824.call(nil, query_593825, nil, formData_593826, nil)

var postModifyListener* = Call_PostModifyListener_593805(
    name: "postModifyListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=ModifyListener",
    validator: validate_PostModifyListener_593806, base: "/",
    url: url_PostModifyListener_593807, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyListener_593784 = ref object of OpenApiRestCall_592364
proc url_GetModifyListener_593786(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyListener_593785(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
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
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Action: JString (required)
  ##   Port: JInt
  ##       : The port for connections from clients to the load balancer.
  ##   Protocol: JString
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   Version: JString (required)
  section = newJObject()
  var valid_593787 = query.getOrDefault("SslPolicy")
  valid_593787 = validateParameter(valid_593787, JString, required = false,
                                 default = nil)
  if valid_593787 != nil:
    section.add "SslPolicy", valid_593787
  assert query != nil,
        "query argument is necessary due to required `ListenerArn` field"
  var valid_593788 = query.getOrDefault("ListenerArn")
  valid_593788 = validateParameter(valid_593788, JString, required = true,
                                 default = nil)
  if valid_593788 != nil:
    section.add "ListenerArn", valid_593788
  var valid_593789 = query.getOrDefault("Certificates")
  valid_593789 = validateParameter(valid_593789, JArray, required = false,
                                 default = nil)
  if valid_593789 != nil:
    section.add "Certificates", valid_593789
  var valid_593790 = query.getOrDefault("DefaultActions")
  valid_593790 = validateParameter(valid_593790, JArray, required = false,
                                 default = nil)
  if valid_593790 != nil:
    section.add "DefaultActions", valid_593790
  var valid_593791 = query.getOrDefault("Action")
  valid_593791 = validateParameter(valid_593791, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_593791 != nil:
    section.add "Action", valid_593791
  var valid_593792 = query.getOrDefault("Port")
  valid_593792 = validateParameter(valid_593792, JInt, required = false, default = nil)
  if valid_593792 != nil:
    section.add "Port", valid_593792
  var valid_593793 = query.getOrDefault("Protocol")
  valid_593793 = validateParameter(valid_593793, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_593793 != nil:
    section.add "Protocol", valid_593793
  var valid_593794 = query.getOrDefault("Version")
  valid_593794 = validateParameter(valid_593794, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593794 != nil:
    section.add "Version", valid_593794
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
  var valid_593795 = header.getOrDefault("X-Amz-Signature")
  valid_593795 = validateParameter(valid_593795, JString, required = false,
                                 default = nil)
  if valid_593795 != nil:
    section.add "X-Amz-Signature", valid_593795
  var valid_593796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593796 = validateParameter(valid_593796, JString, required = false,
                                 default = nil)
  if valid_593796 != nil:
    section.add "X-Amz-Content-Sha256", valid_593796
  var valid_593797 = header.getOrDefault("X-Amz-Date")
  valid_593797 = validateParameter(valid_593797, JString, required = false,
                                 default = nil)
  if valid_593797 != nil:
    section.add "X-Amz-Date", valid_593797
  var valid_593798 = header.getOrDefault("X-Amz-Credential")
  valid_593798 = validateParameter(valid_593798, JString, required = false,
                                 default = nil)
  if valid_593798 != nil:
    section.add "X-Amz-Credential", valid_593798
  var valid_593799 = header.getOrDefault("X-Amz-Security-Token")
  valid_593799 = validateParameter(valid_593799, JString, required = false,
                                 default = nil)
  if valid_593799 != nil:
    section.add "X-Amz-Security-Token", valid_593799
  var valid_593800 = header.getOrDefault("X-Amz-Algorithm")
  valid_593800 = validateParameter(valid_593800, JString, required = false,
                                 default = nil)
  if valid_593800 != nil:
    section.add "X-Amz-Algorithm", valid_593800
  var valid_593801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593801 = validateParameter(valid_593801, JString, required = false,
                                 default = nil)
  if valid_593801 != nil:
    section.add "X-Amz-SignedHeaders", valid_593801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593802: Call_GetModifyListener_593784; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  let valid = call_593802.validator(path, query, header, formData, body)
  let scheme = call_593802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593802.url(scheme.get, call_593802.host, call_593802.base,
                         call_593802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593802, url, valid)

proc call*(call_593803: Call_GetModifyListener_593784; ListenerArn: string;
          SslPolicy: string = ""; Certificates: JsonNode = nil;
          DefaultActions: JsonNode = nil; Action: string = "ModifyListener";
          Port: int = 0; Protocol: string = "HTTP"; Version: string = "2015-12-01"): Recallable =
  ## getModifyListener
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ##   SslPolicy: string
  ##            : [HTTPS and TLS listeners] The security policy that defines which protocols and ciphers are supported. For more information, see <a 
  ## href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list, use <a>AddListenerCertificates</a>.</p>
  ##   DefaultActions: JArray
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Action: string (required)
  ##   Port: int
  ##       : The port for connections from clients to the load balancer.
  ##   Protocol: string
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   Version: string (required)
  var query_593804 = newJObject()
  add(query_593804, "SslPolicy", newJString(SslPolicy))
  add(query_593804, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_593804.add "Certificates", Certificates
  if DefaultActions != nil:
    query_593804.add "DefaultActions", DefaultActions
  add(query_593804, "Action", newJString(Action))
  add(query_593804, "Port", newJInt(Port))
  add(query_593804, "Protocol", newJString(Protocol))
  add(query_593804, "Version", newJString(Version))
  result = call_593803.call(nil, query_593804, nil, nil, nil)

var getModifyListener* = Call_GetModifyListener_593784(name: "getModifyListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyListener", validator: validate_GetModifyListener_593785,
    base: "/", url: url_GetModifyListener_593786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_593844 = ref object of OpenApiRestCall_592364
proc url_PostModifyLoadBalancerAttributes_593846(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyLoadBalancerAttributes_593845(path: JsonNode;
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
  var valid_593847 = query.getOrDefault("Action")
  valid_593847 = validateParameter(valid_593847, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_593847 != nil:
    section.add "Action", valid_593847
  var valid_593848 = query.getOrDefault("Version")
  valid_593848 = validateParameter(valid_593848, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593848 != nil:
    section.add "Version", valid_593848
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
  var valid_593849 = header.getOrDefault("X-Amz-Signature")
  valid_593849 = validateParameter(valid_593849, JString, required = false,
                                 default = nil)
  if valid_593849 != nil:
    section.add "X-Amz-Signature", valid_593849
  var valid_593850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593850 = validateParameter(valid_593850, JString, required = false,
                                 default = nil)
  if valid_593850 != nil:
    section.add "X-Amz-Content-Sha256", valid_593850
  var valid_593851 = header.getOrDefault("X-Amz-Date")
  valid_593851 = validateParameter(valid_593851, JString, required = false,
                                 default = nil)
  if valid_593851 != nil:
    section.add "X-Amz-Date", valid_593851
  var valid_593852 = header.getOrDefault("X-Amz-Credential")
  valid_593852 = validateParameter(valid_593852, JString, required = false,
                                 default = nil)
  if valid_593852 != nil:
    section.add "X-Amz-Credential", valid_593852
  var valid_593853 = header.getOrDefault("X-Amz-Security-Token")
  valid_593853 = validateParameter(valid_593853, JString, required = false,
                                 default = nil)
  if valid_593853 != nil:
    section.add "X-Amz-Security-Token", valid_593853
  var valid_593854 = header.getOrDefault("X-Amz-Algorithm")
  valid_593854 = validateParameter(valid_593854, JString, required = false,
                                 default = nil)
  if valid_593854 != nil:
    section.add "X-Amz-Algorithm", valid_593854
  var valid_593855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "X-Amz-SignedHeaders", valid_593855
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_593856 = formData.getOrDefault("Attributes")
  valid_593856 = validateParameter(valid_593856, JArray, required = true, default = nil)
  if valid_593856 != nil:
    section.add "Attributes", valid_593856
  var valid_593857 = formData.getOrDefault("LoadBalancerArn")
  valid_593857 = validateParameter(valid_593857, JString, required = true,
                                 default = nil)
  if valid_593857 != nil:
    section.add "LoadBalancerArn", valid_593857
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593858: Call_PostModifyLoadBalancerAttributes_593844;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_593858.validator(path, query, header, formData, body)
  let scheme = call_593858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593858.url(scheme.get, call_593858.host, call_593858.base,
                         call_593858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593858, url, valid)

proc call*(call_593859: Call_PostModifyLoadBalancerAttributes_593844;
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
  var query_593860 = newJObject()
  var formData_593861 = newJObject()
  if Attributes != nil:
    formData_593861.add "Attributes", Attributes
  add(query_593860, "Action", newJString(Action))
  add(query_593860, "Version", newJString(Version))
  add(formData_593861, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_593859.call(nil, query_593860, nil, formData_593861, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_593844(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_593845, base: "/",
    url: url_PostModifyLoadBalancerAttributes_593846,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_593827 = ref object of OpenApiRestCall_592364
proc url_GetModifyLoadBalancerAttributes_593829(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyLoadBalancerAttributes_593828(path: JsonNode;
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
  var valid_593830 = query.getOrDefault("LoadBalancerArn")
  valid_593830 = validateParameter(valid_593830, JString, required = true,
                                 default = nil)
  if valid_593830 != nil:
    section.add "LoadBalancerArn", valid_593830
  var valid_593831 = query.getOrDefault("Attributes")
  valid_593831 = validateParameter(valid_593831, JArray, required = true, default = nil)
  if valid_593831 != nil:
    section.add "Attributes", valid_593831
  var valid_593832 = query.getOrDefault("Action")
  valid_593832 = validateParameter(valid_593832, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_593832 != nil:
    section.add "Action", valid_593832
  var valid_593833 = query.getOrDefault("Version")
  valid_593833 = validateParameter(valid_593833, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593833 != nil:
    section.add "Version", valid_593833
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
  var valid_593834 = header.getOrDefault("X-Amz-Signature")
  valid_593834 = validateParameter(valid_593834, JString, required = false,
                                 default = nil)
  if valid_593834 != nil:
    section.add "X-Amz-Signature", valid_593834
  var valid_593835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593835 = validateParameter(valid_593835, JString, required = false,
                                 default = nil)
  if valid_593835 != nil:
    section.add "X-Amz-Content-Sha256", valid_593835
  var valid_593836 = header.getOrDefault("X-Amz-Date")
  valid_593836 = validateParameter(valid_593836, JString, required = false,
                                 default = nil)
  if valid_593836 != nil:
    section.add "X-Amz-Date", valid_593836
  var valid_593837 = header.getOrDefault("X-Amz-Credential")
  valid_593837 = validateParameter(valid_593837, JString, required = false,
                                 default = nil)
  if valid_593837 != nil:
    section.add "X-Amz-Credential", valid_593837
  var valid_593838 = header.getOrDefault("X-Amz-Security-Token")
  valid_593838 = validateParameter(valid_593838, JString, required = false,
                                 default = nil)
  if valid_593838 != nil:
    section.add "X-Amz-Security-Token", valid_593838
  var valid_593839 = header.getOrDefault("X-Amz-Algorithm")
  valid_593839 = validateParameter(valid_593839, JString, required = false,
                                 default = nil)
  if valid_593839 != nil:
    section.add "X-Amz-Algorithm", valid_593839
  var valid_593840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593840 = validateParameter(valid_593840, JString, required = false,
                                 default = nil)
  if valid_593840 != nil:
    section.add "X-Amz-SignedHeaders", valid_593840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593841: Call_GetModifyLoadBalancerAttributes_593827;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_593841.validator(path, query, header, formData, body)
  let scheme = call_593841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593841.url(scheme.get, call_593841.host, call_593841.base,
                         call_593841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593841, url, valid)

proc call*(call_593842: Call_GetModifyLoadBalancerAttributes_593827;
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
  var query_593843 = newJObject()
  add(query_593843, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Attributes != nil:
    query_593843.add "Attributes", Attributes
  add(query_593843, "Action", newJString(Action))
  add(query_593843, "Version", newJString(Version))
  result = call_593842.call(nil, query_593843, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_593827(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_593828, base: "/",
    url: url_GetModifyLoadBalancerAttributes_593829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyRule_593880 = ref object of OpenApiRestCall_592364
proc url_PostModifyRule_593882(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyRule_593881(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
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
  var valid_593883 = query.getOrDefault("Action")
  valid_593883 = validateParameter(valid_593883, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_593883 != nil:
    section.add "Action", valid_593883
  var valid_593884 = query.getOrDefault("Version")
  valid_593884 = validateParameter(valid_593884, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593884 != nil:
    section.add "Version", valid_593884
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
  var valid_593885 = header.getOrDefault("X-Amz-Signature")
  valid_593885 = validateParameter(valid_593885, JString, required = false,
                                 default = nil)
  if valid_593885 != nil:
    section.add "X-Amz-Signature", valid_593885
  var valid_593886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593886 = validateParameter(valid_593886, JString, required = false,
                                 default = nil)
  if valid_593886 != nil:
    section.add "X-Amz-Content-Sha256", valid_593886
  var valid_593887 = header.getOrDefault("X-Amz-Date")
  valid_593887 = validateParameter(valid_593887, JString, required = false,
                                 default = nil)
  if valid_593887 != nil:
    section.add "X-Amz-Date", valid_593887
  var valid_593888 = header.getOrDefault("X-Amz-Credential")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Credential", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-Algorithm")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Algorithm", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-SignedHeaders", valid_593891
  result.add "header", section
  ## parameters in `formData` object:
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  var valid_593892 = formData.getOrDefault("Actions")
  valid_593892 = validateParameter(valid_593892, JArray, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "Actions", valid_593892
  var valid_593893 = formData.getOrDefault("Conditions")
  valid_593893 = validateParameter(valid_593893, JArray, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "Conditions", valid_593893
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_593894 = formData.getOrDefault("RuleArn")
  valid_593894 = validateParameter(valid_593894, JString, required = true,
                                 default = nil)
  if valid_593894 != nil:
    section.add "RuleArn", valid_593894
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593895: Call_PostModifyRule_593880; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_593895.validator(path, query, header, formData, body)
  let scheme = call_593895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593895.url(scheme.get, call_593895.host, call_593895.base,
                         call_593895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593895, url, valid)

proc call*(call_593896: Call_PostModifyRule_593880; RuleArn: string;
          Actions: JsonNode = nil; Conditions: JsonNode = nil;
          Action: string = "ModifyRule"; Version: string = "2015-12-01"): Recallable =
  ## postModifyRule
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593897 = newJObject()
  var formData_593898 = newJObject()
  if Actions != nil:
    formData_593898.add "Actions", Actions
  if Conditions != nil:
    formData_593898.add "Conditions", Conditions
  add(formData_593898, "RuleArn", newJString(RuleArn))
  add(query_593897, "Action", newJString(Action))
  add(query_593897, "Version", newJString(Version))
  result = call_593896.call(nil, query_593897, nil, formData_593898, nil)

var postModifyRule* = Call_PostModifyRule_593880(name: "postModifyRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_PostModifyRule_593881,
    base: "/", url: url_PostModifyRule_593882, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyRule_593862 = ref object of OpenApiRestCall_592364
proc url_GetModifyRule_593864(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyRule_593863(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `RuleArn` field"
  var valid_593865 = query.getOrDefault("RuleArn")
  valid_593865 = validateParameter(valid_593865, JString, required = true,
                                 default = nil)
  if valid_593865 != nil:
    section.add "RuleArn", valid_593865
  var valid_593866 = query.getOrDefault("Actions")
  valid_593866 = validateParameter(valid_593866, JArray, required = false,
                                 default = nil)
  if valid_593866 != nil:
    section.add "Actions", valid_593866
  var valid_593867 = query.getOrDefault("Action")
  valid_593867 = validateParameter(valid_593867, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_593867 != nil:
    section.add "Action", valid_593867
  var valid_593868 = query.getOrDefault("Version")
  valid_593868 = validateParameter(valid_593868, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593868 != nil:
    section.add "Version", valid_593868
  var valid_593869 = query.getOrDefault("Conditions")
  valid_593869 = validateParameter(valid_593869, JArray, required = false,
                                 default = nil)
  if valid_593869 != nil:
    section.add "Conditions", valid_593869
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
  var valid_593870 = header.getOrDefault("X-Amz-Signature")
  valid_593870 = validateParameter(valid_593870, JString, required = false,
                                 default = nil)
  if valid_593870 != nil:
    section.add "X-Amz-Signature", valid_593870
  var valid_593871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593871 = validateParameter(valid_593871, JString, required = false,
                                 default = nil)
  if valid_593871 != nil:
    section.add "X-Amz-Content-Sha256", valid_593871
  var valid_593872 = header.getOrDefault("X-Amz-Date")
  valid_593872 = validateParameter(valid_593872, JString, required = false,
                                 default = nil)
  if valid_593872 != nil:
    section.add "X-Amz-Date", valid_593872
  var valid_593873 = header.getOrDefault("X-Amz-Credential")
  valid_593873 = validateParameter(valid_593873, JString, required = false,
                                 default = nil)
  if valid_593873 != nil:
    section.add "X-Amz-Credential", valid_593873
  var valid_593874 = header.getOrDefault("X-Amz-Security-Token")
  valid_593874 = validateParameter(valid_593874, JString, required = false,
                                 default = nil)
  if valid_593874 != nil:
    section.add "X-Amz-Security-Token", valid_593874
  var valid_593875 = header.getOrDefault("X-Amz-Algorithm")
  valid_593875 = validateParameter(valid_593875, JString, required = false,
                                 default = nil)
  if valid_593875 != nil:
    section.add "X-Amz-Algorithm", valid_593875
  var valid_593876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593876 = validateParameter(valid_593876, JString, required = false,
                                 default = nil)
  if valid_593876 != nil:
    section.add "X-Amz-SignedHeaders", valid_593876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593877: Call_GetModifyRule_593862; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_593877.validator(path, query, header, formData, body)
  let scheme = call_593877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593877.url(scheme.get, call_593877.host, call_593877.base,
                         call_593877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593877, url, valid)

proc call*(call_593878: Call_GetModifyRule_593862; RuleArn: string;
          Actions: JsonNode = nil; Action: string = "ModifyRule";
          Version: string = "2015-12-01"; Conditions: JsonNode = nil): Recallable =
  ## getModifyRule
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  var query_593879 = newJObject()
  add(query_593879, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    query_593879.add "Actions", Actions
  add(query_593879, "Action", newJString(Action))
  add(query_593879, "Version", newJString(Version))
  if Conditions != nil:
    query_593879.add "Conditions", Conditions
  result = call_593878.call(nil, query_593879, nil, nil, nil)

var getModifyRule* = Call_GetModifyRule_593862(name: "getModifyRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_GetModifyRule_593863,
    base: "/", url: url_GetModifyRule_593864, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroup_593924 = ref object of OpenApiRestCall_592364
proc url_PostModifyTargetGroup_593926(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyTargetGroup_593925(path: JsonNode; query: JsonNode;
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
  var valid_593927 = query.getOrDefault("Action")
  valid_593927 = validateParameter(valid_593927, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_593927 != nil:
    section.add "Action", valid_593927
  var valid_593928 = query.getOrDefault("Version")
  valid_593928 = validateParameter(valid_593928, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593928 != nil:
    section.add "Version", valid_593928
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
  var valid_593929 = header.getOrDefault("X-Amz-Signature")
  valid_593929 = validateParameter(valid_593929, JString, required = false,
                                 default = nil)
  if valid_593929 != nil:
    section.add "X-Amz-Signature", valid_593929
  var valid_593930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593930 = validateParameter(valid_593930, JString, required = false,
                                 default = nil)
  if valid_593930 != nil:
    section.add "X-Amz-Content-Sha256", valid_593930
  var valid_593931 = header.getOrDefault("X-Amz-Date")
  valid_593931 = validateParameter(valid_593931, JString, required = false,
                                 default = nil)
  if valid_593931 != nil:
    section.add "X-Amz-Date", valid_593931
  var valid_593932 = header.getOrDefault("X-Amz-Credential")
  valid_593932 = validateParameter(valid_593932, JString, required = false,
                                 default = nil)
  if valid_593932 != nil:
    section.add "X-Amz-Credential", valid_593932
  var valid_593933 = header.getOrDefault("X-Amz-Security-Token")
  valid_593933 = validateParameter(valid_593933, JString, required = false,
                                 default = nil)
  if valid_593933 != nil:
    section.add "X-Amz-Security-Token", valid_593933
  var valid_593934 = header.getOrDefault("X-Amz-Algorithm")
  valid_593934 = validateParameter(valid_593934, JString, required = false,
                                 default = nil)
  if valid_593934 != nil:
    section.add "X-Amz-Algorithm", valid_593934
  var valid_593935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593935 = validateParameter(valid_593935, JString, required = false,
                                 default = nil)
  if valid_593935 != nil:
    section.add "X-Amz-SignedHeaders", valid_593935
  result.add "header", section
  ## parameters in `formData` object:
  ##   HealthCheckProtocol: JString
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   HealthCheckPort: JString
  ##                  : The port the load balancer uses when performing health checks on targets.
  ##   HealthCheckEnabled: JBool
  ##                     : Indicates whether health checks are enabled.
  ##   HealthCheckPath: JString
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination for the health check request.
  ##   HealthCheckTimeoutSeconds: JInt
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   HealthyThresholdCount: JInt
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   HealthCheckIntervalSeconds: JInt
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   UnhealthyThresholdCount: JInt
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   Matcher.HttpCode: JString
  ##                   : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_593936 = formData.getOrDefault("HealthCheckProtocol")
  valid_593936 = validateParameter(valid_593936, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_593936 != nil:
    section.add "HealthCheckProtocol", valid_593936
  var valid_593937 = formData.getOrDefault("HealthCheckPort")
  valid_593937 = validateParameter(valid_593937, JString, required = false,
                                 default = nil)
  if valid_593937 != nil:
    section.add "HealthCheckPort", valid_593937
  var valid_593938 = formData.getOrDefault("HealthCheckEnabled")
  valid_593938 = validateParameter(valid_593938, JBool, required = false, default = nil)
  if valid_593938 != nil:
    section.add "HealthCheckEnabled", valid_593938
  var valid_593939 = formData.getOrDefault("HealthCheckPath")
  valid_593939 = validateParameter(valid_593939, JString, required = false,
                                 default = nil)
  if valid_593939 != nil:
    section.add "HealthCheckPath", valid_593939
  var valid_593940 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_593940 = validateParameter(valid_593940, JInt, required = false, default = nil)
  if valid_593940 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_593940
  var valid_593941 = formData.getOrDefault("HealthyThresholdCount")
  valid_593941 = validateParameter(valid_593941, JInt, required = false, default = nil)
  if valid_593941 != nil:
    section.add "HealthyThresholdCount", valid_593941
  var valid_593942 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_593942 = validateParameter(valid_593942, JInt, required = false, default = nil)
  if valid_593942 != nil:
    section.add "HealthCheckIntervalSeconds", valid_593942
  var valid_593943 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_593943 = validateParameter(valid_593943, JInt, required = false, default = nil)
  if valid_593943 != nil:
    section.add "UnhealthyThresholdCount", valid_593943
  var valid_593944 = formData.getOrDefault("Matcher.HttpCode")
  valid_593944 = validateParameter(valid_593944, JString, required = false,
                                 default = nil)
  if valid_593944 != nil:
    section.add "Matcher.HttpCode", valid_593944
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_593945 = formData.getOrDefault("TargetGroupArn")
  valid_593945 = validateParameter(valid_593945, JString, required = true,
                                 default = nil)
  if valid_593945 != nil:
    section.add "TargetGroupArn", valid_593945
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593946: Call_PostModifyTargetGroup_593924; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_593946.validator(path, query, header, formData, body)
  let scheme = call_593946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593946.url(scheme.get, call_593946.host, call_593946.base,
                         call_593946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593946, url, valid)

proc call*(call_593947: Call_PostModifyTargetGroup_593924; TargetGroupArn: string;
          HealthCheckProtocol: string = "HTTP"; HealthCheckPort: string = "";
          HealthCheckEnabled: bool = false; HealthCheckPath: string = "";
          HealthCheckTimeoutSeconds: int = 0; HealthyThresholdCount: int = 0;
          HealthCheckIntervalSeconds: int = 0; UnhealthyThresholdCount: int = 0;
          MatcherHttpCode: string = ""; Action: string = "ModifyTargetGroup";
          Version: string = "2015-12-01"): Recallable =
  ## postModifyTargetGroup
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ##   HealthCheckProtocol: string
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   HealthCheckPort: string
  ##                  : The port the load balancer uses when performing health checks on targets.
  ##   HealthCheckEnabled: bool
  ##                     : Indicates whether health checks are enabled.
  ##   HealthCheckPath: string
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination for the health check request.
  ##   HealthCheckTimeoutSeconds: int
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   HealthyThresholdCount: int
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   HealthCheckIntervalSeconds: int
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   UnhealthyThresholdCount: int
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   MatcherHttpCode: string
  ##                  : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_593948 = newJObject()
  var formData_593949 = newJObject()
  add(formData_593949, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_593949, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_593949, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_593949, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_593949, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_593949, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_593949, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_593949, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_593949, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_593948, "Action", newJString(Action))
  add(formData_593949, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_593948, "Version", newJString(Version))
  result = call_593947.call(nil, query_593948, nil, formData_593949, nil)

var postModifyTargetGroup* = Call_PostModifyTargetGroup_593924(
    name: "postModifyTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup",
    validator: validate_PostModifyTargetGroup_593925, base: "/",
    url: url_PostModifyTargetGroup_593926, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroup_593899 = ref object of OpenApiRestCall_592364
proc url_GetModifyTargetGroup_593901(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyTargetGroup_593900(path: JsonNode; query: JsonNode;
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
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   Matcher.HttpCode: JString
  ##                   : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   HealthCheckIntervalSeconds: JInt
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   HealthCheckEnabled: JBool
  ##                     : Indicates whether health checks are enabled.
  ##   HealthyThresholdCount: JInt
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   UnhealthyThresholdCount: JInt
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   Action: JString (required)
  ##   HealthCheckTimeoutSeconds: JInt
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_593902 = query.getOrDefault("HealthCheckPort")
  valid_593902 = validateParameter(valid_593902, JString, required = false,
                                 default = nil)
  if valid_593902 != nil:
    section.add "HealthCheckPort", valid_593902
  var valid_593903 = query.getOrDefault("HealthCheckPath")
  valid_593903 = validateParameter(valid_593903, JString, required = false,
                                 default = nil)
  if valid_593903 != nil:
    section.add "HealthCheckPath", valid_593903
  var valid_593904 = query.getOrDefault("HealthCheckProtocol")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_593904 != nil:
    section.add "HealthCheckProtocol", valid_593904
  var valid_593905 = query.getOrDefault("Matcher.HttpCode")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "Matcher.HttpCode", valid_593905
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_593906 = query.getOrDefault("TargetGroupArn")
  valid_593906 = validateParameter(valid_593906, JString, required = true,
                                 default = nil)
  if valid_593906 != nil:
    section.add "TargetGroupArn", valid_593906
  var valid_593907 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_593907 = validateParameter(valid_593907, JInt, required = false, default = nil)
  if valid_593907 != nil:
    section.add "HealthCheckIntervalSeconds", valid_593907
  var valid_593908 = query.getOrDefault("HealthCheckEnabled")
  valid_593908 = validateParameter(valid_593908, JBool, required = false, default = nil)
  if valid_593908 != nil:
    section.add "HealthCheckEnabled", valid_593908
  var valid_593909 = query.getOrDefault("HealthyThresholdCount")
  valid_593909 = validateParameter(valid_593909, JInt, required = false, default = nil)
  if valid_593909 != nil:
    section.add "HealthyThresholdCount", valid_593909
  var valid_593910 = query.getOrDefault("UnhealthyThresholdCount")
  valid_593910 = validateParameter(valid_593910, JInt, required = false, default = nil)
  if valid_593910 != nil:
    section.add "UnhealthyThresholdCount", valid_593910
  var valid_593911 = query.getOrDefault("Action")
  valid_593911 = validateParameter(valid_593911, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_593911 != nil:
    section.add "Action", valid_593911
  var valid_593912 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_593912 = validateParameter(valid_593912, JInt, required = false, default = nil)
  if valid_593912 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_593912
  var valid_593913 = query.getOrDefault("Version")
  valid_593913 = validateParameter(valid_593913, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593913 != nil:
    section.add "Version", valid_593913
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
  var valid_593914 = header.getOrDefault("X-Amz-Signature")
  valid_593914 = validateParameter(valid_593914, JString, required = false,
                                 default = nil)
  if valid_593914 != nil:
    section.add "X-Amz-Signature", valid_593914
  var valid_593915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593915 = validateParameter(valid_593915, JString, required = false,
                                 default = nil)
  if valid_593915 != nil:
    section.add "X-Amz-Content-Sha256", valid_593915
  var valid_593916 = header.getOrDefault("X-Amz-Date")
  valid_593916 = validateParameter(valid_593916, JString, required = false,
                                 default = nil)
  if valid_593916 != nil:
    section.add "X-Amz-Date", valid_593916
  var valid_593917 = header.getOrDefault("X-Amz-Credential")
  valid_593917 = validateParameter(valid_593917, JString, required = false,
                                 default = nil)
  if valid_593917 != nil:
    section.add "X-Amz-Credential", valid_593917
  var valid_593918 = header.getOrDefault("X-Amz-Security-Token")
  valid_593918 = validateParameter(valid_593918, JString, required = false,
                                 default = nil)
  if valid_593918 != nil:
    section.add "X-Amz-Security-Token", valid_593918
  var valid_593919 = header.getOrDefault("X-Amz-Algorithm")
  valid_593919 = validateParameter(valid_593919, JString, required = false,
                                 default = nil)
  if valid_593919 != nil:
    section.add "X-Amz-Algorithm", valid_593919
  var valid_593920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593920 = validateParameter(valid_593920, JString, required = false,
                                 default = nil)
  if valid_593920 != nil:
    section.add "X-Amz-SignedHeaders", valid_593920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593921: Call_GetModifyTargetGroup_593899; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_593921.validator(path, query, header, formData, body)
  let scheme = call_593921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593921.url(scheme.get, call_593921.host, call_593921.base,
                         call_593921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593921, url, valid)

proc call*(call_593922: Call_GetModifyTargetGroup_593899; TargetGroupArn: string;
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
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   MatcherHttpCode: string
  ##                  : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   HealthCheckIntervalSeconds: int
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   HealthCheckEnabled: bool
  ##                     : Indicates whether health checks are enabled.
  ##   HealthyThresholdCount: int
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   UnhealthyThresholdCount: int
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   Action: string (required)
  ##   HealthCheckTimeoutSeconds: int
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   Version: string (required)
  var query_593923 = newJObject()
  add(query_593923, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_593923, "HealthCheckPath", newJString(HealthCheckPath))
  add(query_593923, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_593923, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_593923, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_593923, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_593923, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_593923, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_593923, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_593923, "Action", newJString(Action))
  add(query_593923, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_593923, "Version", newJString(Version))
  result = call_593922.call(nil, query_593923, nil, nil, nil)

var getModifyTargetGroup* = Call_GetModifyTargetGroup_593899(
    name: "getModifyTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup", validator: validate_GetModifyTargetGroup_593900,
    base: "/", url: url_GetModifyTargetGroup_593901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroupAttributes_593967 = ref object of OpenApiRestCall_592364
proc url_PostModifyTargetGroupAttributes_593969(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyTargetGroupAttributes_593968(path: JsonNode;
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
  var valid_593970 = query.getOrDefault("Action")
  valid_593970 = validateParameter(valid_593970, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_593970 != nil:
    section.add "Action", valid_593970
  var valid_593971 = query.getOrDefault("Version")
  valid_593971 = validateParameter(valid_593971, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593971 != nil:
    section.add "Version", valid_593971
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
  var valid_593972 = header.getOrDefault("X-Amz-Signature")
  valid_593972 = validateParameter(valid_593972, JString, required = false,
                                 default = nil)
  if valid_593972 != nil:
    section.add "X-Amz-Signature", valid_593972
  var valid_593973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593973 = validateParameter(valid_593973, JString, required = false,
                                 default = nil)
  if valid_593973 != nil:
    section.add "X-Amz-Content-Sha256", valid_593973
  var valid_593974 = header.getOrDefault("X-Amz-Date")
  valid_593974 = validateParameter(valid_593974, JString, required = false,
                                 default = nil)
  if valid_593974 != nil:
    section.add "X-Amz-Date", valid_593974
  var valid_593975 = header.getOrDefault("X-Amz-Credential")
  valid_593975 = validateParameter(valid_593975, JString, required = false,
                                 default = nil)
  if valid_593975 != nil:
    section.add "X-Amz-Credential", valid_593975
  var valid_593976 = header.getOrDefault("X-Amz-Security-Token")
  valid_593976 = validateParameter(valid_593976, JString, required = false,
                                 default = nil)
  if valid_593976 != nil:
    section.add "X-Amz-Security-Token", valid_593976
  var valid_593977 = header.getOrDefault("X-Amz-Algorithm")
  valid_593977 = validateParameter(valid_593977, JString, required = false,
                                 default = nil)
  if valid_593977 != nil:
    section.add "X-Amz-Algorithm", valid_593977
  var valid_593978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593978 = validateParameter(valid_593978, JString, required = false,
                                 default = nil)
  if valid_593978 != nil:
    section.add "X-Amz-SignedHeaders", valid_593978
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_593979 = formData.getOrDefault("Attributes")
  valid_593979 = validateParameter(valid_593979, JArray, required = true, default = nil)
  if valid_593979 != nil:
    section.add "Attributes", valid_593979
  var valid_593980 = formData.getOrDefault("TargetGroupArn")
  valid_593980 = validateParameter(valid_593980, JString, required = true,
                                 default = nil)
  if valid_593980 != nil:
    section.add "TargetGroupArn", valid_593980
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593981: Call_PostModifyTargetGroupAttributes_593967;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_593981.validator(path, query, header, formData, body)
  let scheme = call_593981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593981.url(scheme.get, call_593981.host, call_593981.base,
                         call_593981.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593981, url, valid)

proc call*(call_593982: Call_PostModifyTargetGroupAttributes_593967;
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
  var query_593983 = newJObject()
  var formData_593984 = newJObject()
  if Attributes != nil:
    formData_593984.add "Attributes", Attributes
  add(query_593983, "Action", newJString(Action))
  add(formData_593984, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_593983, "Version", newJString(Version))
  result = call_593982.call(nil, query_593983, nil, formData_593984, nil)

var postModifyTargetGroupAttributes* = Call_PostModifyTargetGroupAttributes_593967(
    name: "postModifyTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_PostModifyTargetGroupAttributes_593968, base: "/",
    url: url_PostModifyTargetGroupAttributes_593969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroupAttributes_593950 = ref object of OpenApiRestCall_592364
proc url_GetModifyTargetGroupAttributes_593952(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyTargetGroupAttributes_593951(path: JsonNode;
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
  var valid_593953 = query.getOrDefault("TargetGroupArn")
  valid_593953 = validateParameter(valid_593953, JString, required = true,
                                 default = nil)
  if valid_593953 != nil:
    section.add "TargetGroupArn", valid_593953
  var valid_593954 = query.getOrDefault("Attributes")
  valid_593954 = validateParameter(valid_593954, JArray, required = true, default = nil)
  if valid_593954 != nil:
    section.add "Attributes", valid_593954
  var valid_593955 = query.getOrDefault("Action")
  valid_593955 = validateParameter(valid_593955, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_593955 != nil:
    section.add "Action", valid_593955
  var valid_593956 = query.getOrDefault("Version")
  valid_593956 = validateParameter(valid_593956, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593956 != nil:
    section.add "Version", valid_593956
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
  var valid_593957 = header.getOrDefault("X-Amz-Signature")
  valid_593957 = validateParameter(valid_593957, JString, required = false,
                                 default = nil)
  if valid_593957 != nil:
    section.add "X-Amz-Signature", valid_593957
  var valid_593958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593958 = validateParameter(valid_593958, JString, required = false,
                                 default = nil)
  if valid_593958 != nil:
    section.add "X-Amz-Content-Sha256", valid_593958
  var valid_593959 = header.getOrDefault("X-Amz-Date")
  valid_593959 = validateParameter(valid_593959, JString, required = false,
                                 default = nil)
  if valid_593959 != nil:
    section.add "X-Amz-Date", valid_593959
  var valid_593960 = header.getOrDefault("X-Amz-Credential")
  valid_593960 = validateParameter(valid_593960, JString, required = false,
                                 default = nil)
  if valid_593960 != nil:
    section.add "X-Amz-Credential", valid_593960
  var valid_593961 = header.getOrDefault("X-Amz-Security-Token")
  valid_593961 = validateParameter(valid_593961, JString, required = false,
                                 default = nil)
  if valid_593961 != nil:
    section.add "X-Amz-Security-Token", valid_593961
  var valid_593962 = header.getOrDefault("X-Amz-Algorithm")
  valid_593962 = validateParameter(valid_593962, JString, required = false,
                                 default = nil)
  if valid_593962 != nil:
    section.add "X-Amz-Algorithm", valid_593962
  var valid_593963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593963 = validateParameter(valid_593963, JString, required = false,
                                 default = nil)
  if valid_593963 != nil:
    section.add "X-Amz-SignedHeaders", valid_593963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593964: Call_GetModifyTargetGroupAttributes_593950; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_593964.validator(path, query, header, formData, body)
  let scheme = call_593964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593964.url(scheme.get, call_593964.host, call_593964.base,
                         call_593964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593964, url, valid)

proc call*(call_593965: Call_GetModifyTargetGroupAttributes_593950;
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
  var query_593966 = newJObject()
  add(query_593966, "TargetGroupArn", newJString(TargetGroupArn))
  if Attributes != nil:
    query_593966.add "Attributes", Attributes
  add(query_593966, "Action", newJString(Action))
  add(query_593966, "Version", newJString(Version))
  result = call_593965.call(nil, query_593966, nil, nil, nil)

var getModifyTargetGroupAttributes* = Call_GetModifyTargetGroupAttributes_593950(
    name: "getModifyTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_GetModifyTargetGroupAttributes_593951, base: "/",
    url: url_GetModifyTargetGroupAttributes_593952,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterTargets_594002 = ref object of OpenApiRestCall_592364
proc url_PostRegisterTargets_594004(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRegisterTargets_594003(path: JsonNode; query: JsonNode;
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
  var valid_594005 = query.getOrDefault("Action")
  valid_594005 = validateParameter(valid_594005, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_594005 != nil:
    section.add "Action", valid_594005
  var valid_594006 = query.getOrDefault("Version")
  valid_594006 = validateParameter(valid_594006, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594006 != nil:
    section.add "Version", valid_594006
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
  var valid_594007 = header.getOrDefault("X-Amz-Signature")
  valid_594007 = validateParameter(valid_594007, JString, required = false,
                                 default = nil)
  if valid_594007 != nil:
    section.add "X-Amz-Signature", valid_594007
  var valid_594008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594008 = validateParameter(valid_594008, JString, required = false,
                                 default = nil)
  if valid_594008 != nil:
    section.add "X-Amz-Content-Sha256", valid_594008
  var valid_594009 = header.getOrDefault("X-Amz-Date")
  valid_594009 = validateParameter(valid_594009, JString, required = false,
                                 default = nil)
  if valid_594009 != nil:
    section.add "X-Amz-Date", valid_594009
  var valid_594010 = header.getOrDefault("X-Amz-Credential")
  valid_594010 = validateParameter(valid_594010, JString, required = false,
                                 default = nil)
  if valid_594010 != nil:
    section.add "X-Amz-Credential", valid_594010
  var valid_594011 = header.getOrDefault("X-Amz-Security-Token")
  valid_594011 = validateParameter(valid_594011, JString, required = false,
                                 default = nil)
  if valid_594011 != nil:
    section.add "X-Amz-Security-Token", valid_594011
  var valid_594012 = header.getOrDefault("X-Amz-Algorithm")
  valid_594012 = validateParameter(valid_594012, JString, required = false,
                                 default = nil)
  if valid_594012 != nil:
    section.add "X-Amz-Algorithm", valid_594012
  var valid_594013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594013 = validateParameter(valid_594013, JString, required = false,
                                 default = nil)
  if valid_594013 != nil:
    section.add "X-Amz-SignedHeaders", valid_594013
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_594014 = formData.getOrDefault("Targets")
  valid_594014 = validateParameter(valid_594014, JArray, required = true, default = nil)
  if valid_594014 != nil:
    section.add "Targets", valid_594014
  var valid_594015 = formData.getOrDefault("TargetGroupArn")
  valid_594015 = validateParameter(valid_594015, JString, required = true,
                                 default = nil)
  if valid_594015 != nil:
    section.add "TargetGroupArn", valid_594015
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594016: Call_PostRegisterTargets_594002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_594016.validator(path, query, header, formData, body)
  let scheme = call_594016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594016.url(scheme.get, call_594016.host, call_594016.base,
                         call_594016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594016, url, valid)

proc call*(call_594017: Call_PostRegisterTargets_594002; Targets: JsonNode;
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
  var query_594018 = newJObject()
  var formData_594019 = newJObject()
  if Targets != nil:
    formData_594019.add "Targets", Targets
  add(query_594018, "Action", newJString(Action))
  add(formData_594019, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594018, "Version", newJString(Version))
  result = call_594017.call(nil, query_594018, nil, formData_594019, nil)

var postRegisterTargets* = Call_PostRegisterTargets_594002(
    name: "postRegisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_PostRegisterTargets_594003, base: "/",
    url: url_PostRegisterTargets_594004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterTargets_593985 = ref object of OpenApiRestCall_592364
proc url_GetRegisterTargets_593987(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRegisterTargets_593986(path: JsonNode; query: JsonNode;
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
  var valid_593988 = query.getOrDefault("Targets")
  valid_593988 = validateParameter(valid_593988, JArray, required = true, default = nil)
  if valid_593988 != nil:
    section.add "Targets", valid_593988
  var valid_593989 = query.getOrDefault("TargetGroupArn")
  valid_593989 = validateParameter(valid_593989, JString, required = true,
                                 default = nil)
  if valid_593989 != nil:
    section.add "TargetGroupArn", valid_593989
  var valid_593990 = query.getOrDefault("Action")
  valid_593990 = validateParameter(valid_593990, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_593990 != nil:
    section.add "Action", valid_593990
  var valid_593991 = query.getOrDefault("Version")
  valid_593991 = validateParameter(valid_593991, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593991 != nil:
    section.add "Version", valid_593991
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
  var valid_593992 = header.getOrDefault("X-Amz-Signature")
  valid_593992 = validateParameter(valid_593992, JString, required = false,
                                 default = nil)
  if valid_593992 != nil:
    section.add "X-Amz-Signature", valid_593992
  var valid_593993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593993 = validateParameter(valid_593993, JString, required = false,
                                 default = nil)
  if valid_593993 != nil:
    section.add "X-Amz-Content-Sha256", valid_593993
  var valid_593994 = header.getOrDefault("X-Amz-Date")
  valid_593994 = validateParameter(valid_593994, JString, required = false,
                                 default = nil)
  if valid_593994 != nil:
    section.add "X-Amz-Date", valid_593994
  var valid_593995 = header.getOrDefault("X-Amz-Credential")
  valid_593995 = validateParameter(valid_593995, JString, required = false,
                                 default = nil)
  if valid_593995 != nil:
    section.add "X-Amz-Credential", valid_593995
  var valid_593996 = header.getOrDefault("X-Amz-Security-Token")
  valid_593996 = validateParameter(valid_593996, JString, required = false,
                                 default = nil)
  if valid_593996 != nil:
    section.add "X-Amz-Security-Token", valid_593996
  var valid_593997 = header.getOrDefault("X-Amz-Algorithm")
  valid_593997 = validateParameter(valid_593997, JString, required = false,
                                 default = nil)
  if valid_593997 != nil:
    section.add "X-Amz-Algorithm", valid_593997
  var valid_593998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593998 = validateParameter(valid_593998, JString, required = false,
                                 default = nil)
  if valid_593998 != nil:
    section.add "X-Amz-SignedHeaders", valid_593998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593999: Call_GetRegisterTargets_593985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_593999.validator(path, query, header, formData, body)
  let scheme = call_593999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593999.url(scheme.get, call_593999.host, call_593999.base,
                         call_593999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593999, url, valid)

proc call*(call_594000: Call_GetRegisterTargets_593985; Targets: JsonNode;
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
  var query_594001 = newJObject()
  if Targets != nil:
    query_594001.add "Targets", Targets
  add(query_594001, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594001, "Action", newJString(Action))
  add(query_594001, "Version", newJString(Version))
  result = call_594000.call(nil, query_594001, nil, nil, nil)

var getRegisterTargets* = Call_GetRegisterTargets_593985(
    name: "getRegisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_GetRegisterTargets_593986, base: "/",
    url: url_GetRegisterTargets_593987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveListenerCertificates_594037 = ref object of OpenApiRestCall_592364
proc url_PostRemoveListenerCertificates_594039(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveListenerCertificates_594038(path: JsonNode;
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
  var valid_594040 = query.getOrDefault("Action")
  valid_594040 = validateParameter(valid_594040, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_594040 != nil:
    section.add "Action", valid_594040
  var valid_594041 = query.getOrDefault("Version")
  valid_594041 = validateParameter(valid_594041, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594041 != nil:
    section.add "Version", valid_594041
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
  var valid_594042 = header.getOrDefault("X-Amz-Signature")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "X-Amz-Signature", valid_594042
  var valid_594043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594043 = validateParameter(valid_594043, JString, required = false,
                                 default = nil)
  if valid_594043 != nil:
    section.add "X-Amz-Content-Sha256", valid_594043
  var valid_594044 = header.getOrDefault("X-Amz-Date")
  valid_594044 = validateParameter(valid_594044, JString, required = false,
                                 default = nil)
  if valid_594044 != nil:
    section.add "X-Amz-Date", valid_594044
  var valid_594045 = header.getOrDefault("X-Amz-Credential")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-Credential", valid_594045
  var valid_594046 = header.getOrDefault("X-Amz-Security-Token")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Security-Token", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Algorithm")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Algorithm", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-SignedHeaders", valid_594048
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_594049 = formData.getOrDefault("Certificates")
  valid_594049 = validateParameter(valid_594049, JArray, required = true, default = nil)
  if valid_594049 != nil:
    section.add "Certificates", valid_594049
  var valid_594050 = formData.getOrDefault("ListenerArn")
  valid_594050 = validateParameter(valid_594050, JString, required = true,
                                 default = nil)
  if valid_594050 != nil:
    section.add "ListenerArn", valid_594050
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594051: Call_PostRemoveListenerCertificates_594037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_594051.validator(path, query, header, formData, body)
  let scheme = call_594051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594051.url(scheme.get, call_594051.host, call_594051.base,
                         call_594051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594051, url, valid)

proc call*(call_594052: Call_PostRemoveListenerCertificates_594037;
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
  var query_594053 = newJObject()
  var formData_594054 = newJObject()
  if Certificates != nil:
    formData_594054.add "Certificates", Certificates
  add(formData_594054, "ListenerArn", newJString(ListenerArn))
  add(query_594053, "Action", newJString(Action))
  add(query_594053, "Version", newJString(Version))
  result = call_594052.call(nil, query_594053, nil, formData_594054, nil)

var postRemoveListenerCertificates* = Call_PostRemoveListenerCertificates_594037(
    name: "postRemoveListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_PostRemoveListenerCertificates_594038, base: "/",
    url: url_PostRemoveListenerCertificates_594039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveListenerCertificates_594020 = ref object of OpenApiRestCall_592364
proc url_GetRemoveListenerCertificates_594022(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveListenerCertificates_594021(path: JsonNode; query: JsonNode;
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
  var valid_594023 = query.getOrDefault("ListenerArn")
  valid_594023 = validateParameter(valid_594023, JString, required = true,
                                 default = nil)
  if valid_594023 != nil:
    section.add "ListenerArn", valid_594023
  var valid_594024 = query.getOrDefault("Certificates")
  valid_594024 = validateParameter(valid_594024, JArray, required = true, default = nil)
  if valid_594024 != nil:
    section.add "Certificates", valid_594024
  var valid_594025 = query.getOrDefault("Action")
  valid_594025 = validateParameter(valid_594025, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_594025 != nil:
    section.add "Action", valid_594025
  var valid_594026 = query.getOrDefault("Version")
  valid_594026 = validateParameter(valid_594026, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594026 != nil:
    section.add "Version", valid_594026
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
  var valid_594027 = header.getOrDefault("X-Amz-Signature")
  valid_594027 = validateParameter(valid_594027, JString, required = false,
                                 default = nil)
  if valid_594027 != nil:
    section.add "X-Amz-Signature", valid_594027
  var valid_594028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594028 = validateParameter(valid_594028, JString, required = false,
                                 default = nil)
  if valid_594028 != nil:
    section.add "X-Amz-Content-Sha256", valid_594028
  var valid_594029 = header.getOrDefault("X-Amz-Date")
  valid_594029 = validateParameter(valid_594029, JString, required = false,
                                 default = nil)
  if valid_594029 != nil:
    section.add "X-Amz-Date", valid_594029
  var valid_594030 = header.getOrDefault("X-Amz-Credential")
  valid_594030 = validateParameter(valid_594030, JString, required = false,
                                 default = nil)
  if valid_594030 != nil:
    section.add "X-Amz-Credential", valid_594030
  var valid_594031 = header.getOrDefault("X-Amz-Security-Token")
  valid_594031 = validateParameter(valid_594031, JString, required = false,
                                 default = nil)
  if valid_594031 != nil:
    section.add "X-Amz-Security-Token", valid_594031
  var valid_594032 = header.getOrDefault("X-Amz-Algorithm")
  valid_594032 = validateParameter(valid_594032, JString, required = false,
                                 default = nil)
  if valid_594032 != nil:
    section.add "X-Amz-Algorithm", valid_594032
  var valid_594033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-SignedHeaders", valid_594033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594034: Call_GetRemoveListenerCertificates_594020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_594034.validator(path, query, header, formData, body)
  let scheme = call_594034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594034.url(scheme.get, call_594034.host, call_594034.base,
                         call_594034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594034, url, valid)

proc call*(call_594035: Call_GetRemoveListenerCertificates_594020;
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
  var query_594036 = newJObject()
  add(query_594036, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_594036.add "Certificates", Certificates
  add(query_594036, "Action", newJString(Action))
  add(query_594036, "Version", newJString(Version))
  result = call_594035.call(nil, query_594036, nil, nil, nil)

var getRemoveListenerCertificates* = Call_GetRemoveListenerCertificates_594020(
    name: "getRemoveListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_GetRemoveListenerCertificates_594021, base: "/",
    url: url_GetRemoveListenerCertificates_594022,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_594072 = ref object of OpenApiRestCall_592364
proc url_PostRemoveTags_594074(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTags_594073(path: JsonNode; query: JsonNode;
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
  var valid_594075 = query.getOrDefault("Action")
  valid_594075 = validateParameter(valid_594075, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_594075 != nil:
    section.add "Action", valid_594075
  var valid_594076 = query.getOrDefault("Version")
  valid_594076 = validateParameter(valid_594076, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594076 != nil:
    section.add "Version", valid_594076
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
  var valid_594077 = header.getOrDefault("X-Amz-Signature")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Signature", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Content-Sha256", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Date")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Date", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Credential")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Credential", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Security-Token")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Security-Token", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Algorithm")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Algorithm", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-SignedHeaders", valid_594083
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_594084 = formData.getOrDefault("TagKeys")
  valid_594084 = validateParameter(valid_594084, JArray, required = true, default = nil)
  if valid_594084 != nil:
    section.add "TagKeys", valid_594084
  var valid_594085 = formData.getOrDefault("ResourceArns")
  valid_594085 = validateParameter(valid_594085, JArray, required = true, default = nil)
  if valid_594085 != nil:
    section.add "ResourceArns", valid_594085
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594086: Call_PostRemoveTags_594072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_594086.validator(path, query, header, formData, body)
  let scheme = call_594086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594086.url(scheme.get, call_594086.host, call_594086.base,
                         call_594086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594086, url, valid)

proc call*(call_594087: Call_PostRemoveTags_594072; TagKeys: JsonNode;
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
  var query_594088 = newJObject()
  var formData_594089 = newJObject()
  if TagKeys != nil:
    formData_594089.add "TagKeys", TagKeys
  if ResourceArns != nil:
    formData_594089.add "ResourceArns", ResourceArns
  add(query_594088, "Action", newJString(Action))
  add(query_594088, "Version", newJString(Version))
  result = call_594087.call(nil, query_594088, nil, formData_594089, nil)

var postRemoveTags* = Call_PostRemoveTags_594072(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_594073,
    base: "/", url: url_PostRemoveTags_594074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_594055 = ref object of OpenApiRestCall_592364
proc url_GetRemoveTags_594057(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTags_594056(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594058 = query.getOrDefault("ResourceArns")
  valid_594058 = validateParameter(valid_594058, JArray, required = true, default = nil)
  if valid_594058 != nil:
    section.add "ResourceArns", valid_594058
  var valid_594059 = query.getOrDefault("TagKeys")
  valid_594059 = validateParameter(valid_594059, JArray, required = true, default = nil)
  if valid_594059 != nil:
    section.add "TagKeys", valid_594059
  var valid_594060 = query.getOrDefault("Action")
  valid_594060 = validateParameter(valid_594060, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_594060 != nil:
    section.add "Action", valid_594060
  var valid_594061 = query.getOrDefault("Version")
  valid_594061 = validateParameter(valid_594061, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594061 != nil:
    section.add "Version", valid_594061
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
  var valid_594062 = header.getOrDefault("X-Amz-Signature")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Signature", valid_594062
  var valid_594063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Content-Sha256", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Date")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Date", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Credential")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Credential", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Security-Token")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Security-Token", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Algorithm")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Algorithm", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-SignedHeaders", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594069: Call_GetRemoveTags_594055; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_594069.validator(path, query, header, formData, body)
  let scheme = call_594069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594069.url(scheme.get, call_594069.host, call_594069.base,
                         call_594069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594069, url, valid)

proc call*(call_594070: Call_GetRemoveTags_594055; ResourceArns: JsonNode;
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
  var query_594071 = newJObject()
  if ResourceArns != nil:
    query_594071.add "ResourceArns", ResourceArns
  if TagKeys != nil:
    query_594071.add "TagKeys", TagKeys
  add(query_594071, "Action", newJString(Action))
  add(query_594071, "Version", newJString(Version))
  result = call_594070.call(nil, query_594071, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_594055(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_594056,
    base: "/", url: url_GetRemoveTags_594057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetIpAddressType_594107 = ref object of OpenApiRestCall_592364
proc url_PostSetIpAddressType_594109(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetIpAddressType_594108(path: JsonNode; query: JsonNode;
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
  var valid_594110 = query.getOrDefault("Action")
  valid_594110 = validateParameter(valid_594110, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_594110 != nil:
    section.add "Action", valid_594110
  var valid_594111 = query.getOrDefault("Version")
  valid_594111 = validateParameter(valid_594111, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594111 != nil:
    section.add "Version", valid_594111
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
  var valid_594112 = header.getOrDefault("X-Amz-Signature")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Signature", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Content-Sha256", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Date")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Date", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Credential")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Credential", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Security-Token")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Security-Token", valid_594116
  var valid_594117 = header.getOrDefault("X-Amz-Algorithm")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-Algorithm", valid_594117
  var valid_594118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-SignedHeaders", valid_594118
  result.add "header", section
  ## parameters in `formData` object:
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `IpAddressType` field"
  var valid_594119 = formData.getOrDefault("IpAddressType")
  valid_594119 = validateParameter(valid_594119, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_594119 != nil:
    section.add "IpAddressType", valid_594119
  var valid_594120 = formData.getOrDefault("LoadBalancerArn")
  valid_594120 = validateParameter(valid_594120, JString, required = true,
                                 default = nil)
  if valid_594120 != nil:
    section.add "LoadBalancerArn", valid_594120
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594121: Call_PostSetIpAddressType_594107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_594121.validator(path, query, header, formData, body)
  let scheme = call_594121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594121.url(scheme.get, call_594121.host, call_594121.base,
                         call_594121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594121, url, valid)

proc call*(call_594122: Call_PostSetIpAddressType_594107; LoadBalancerArn: string;
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
  var query_594123 = newJObject()
  var formData_594124 = newJObject()
  add(formData_594124, "IpAddressType", newJString(IpAddressType))
  add(query_594123, "Action", newJString(Action))
  add(query_594123, "Version", newJString(Version))
  add(formData_594124, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_594122.call(nil, query_594123, nil, formData_594124, nil)

var postSetIpAddressType* = Call_PostSetIpAddressType_594107(
    name: "postSetIpAddressType", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_PostSetIpAddressType_594108,
    base: "/", url: url_PostSetIpAddressType_594109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetIpAddressType_594090 = ref object of OpenApiRestCall_592364
proc url_GetSetIpAddressType_594092(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetIpAddressType_594091(path: JsonNode; query: JsonNode;
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
  var valid_594093 = query.getOrDefault("IpAddressType")
  valid_594093 = validateParameter(valid_594093, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_594093 != nil:
    section.add "IpAddressType", valid_594093
  var valid_594094 = query.getOrDefault("LoadBalancerArn")
  valid_594094 = validateParameter(valid_594094, JString, required = true,
                                 default = nil)
  if valid_594094 != nil:
    section.add "LoadBalancerArn", valid_594094
  var valid_594095 = query.getOrDefault("Action")
  valid_594095 = validateParameter(valid_594095, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_594095 != nil:
    section.add "Action", valid_594095
  var valid_594096 = query.getOrDefault("Version")
  valid_594096 = validateParameter(valid_594096, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594096 != nil:
    section.add "Version", valid_594096
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
  var valid_594097 = header.getOrDefault("X-Amz-Signature")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Signature", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Content-Sha256", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Date")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Date", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-Credential")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Credential", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-Security-Token")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Security-Token", valid_594101
  var valid_594102 = header.getOrDefault("X-Amz-Algorithm")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-Algorithm", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-SignedHeaders", valid_594103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594104: Call_GetSetIpAddressType_594090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_594104.validator(path, query, header, formData, body)
  let scheme = call_594104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594104.url(scheme.get, call_594104.host, call_594104.base,
                         call_594104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594104, url, valid)

proc call*(call_594105: Call_GetSetIpAddressType_594090; LoadBalancerArn: string;
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
  var query_594106 = newJObject()
  add(query_594106, "IpAddressType", newJString(IpAddressType))
  add(query_594106, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_594106, "Action", newJString(Action))
  add(query_594106, "Version", newJString(Version))
  result = call_594105.call(nil, query_594106, nil, nil, nil)

var getSetIpAddressType* = Call_GetSetIpAddressType_594090(
    name: "getSetIpAddressType", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_GetSetIpAddressType_594091,
    base: "/", url: url_GetSetIpAddressType_594092,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetRulePriorities_594141 = ref object of OpenApiRestCall_592364
proc url_PostSetRulePriorities_594143(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetRulePriorities_594142(path: JsonNode; query: JsonNode;
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
  var valid_594144 = query.getOrDefault("Action")
  valid_594144 = validateParameter(valid_594144, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_594144 != nil:
    section.add "Action", valid_594144
  var valid_594145 = query.getOrDefault("Version")
  valid_594145 = validateParameter(valid_594145, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594145 != nil:
    section.add "Version", valid_594145
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
  var valid_594146 = header.getOrDefault("X-Amz-Signature")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Signature", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Content-Sha256", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Date")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Date", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Credential")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Credential", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Security-Token")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Security-Token", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Algorithm")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Algorithm", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-SignedHeaders", valid_594152
  result.add "header", section
  ## parameters in `formData` object:
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RulePriorities` field"
  var valid_594153 = formData.getOrDefault("RulePriorities")
  valid_594153 = validateParameter(valid_594153, JArray, required = true, default = nil)
  if valid_594153 != nil:
    section.add "RulePriorities", valid_594153
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594154: Call_PostSetRulePriorities_594141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_594154.validator(path, query, header, formData, body)
  let scheme = call_594154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594154.url(scheme.get, call_594154.host, call_594154.base,
                         call_594154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594154, url, valid)

proc call*(call_594155: Call_PostSetRulePriorities_594141;
          RulePriorities: JsonNode; Action: string = "SetRulePriorities";
          Version: string = "2015-12-01"): Recallable =
  ## postSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594156 = newJObject()
  var formData_594157 = newJObject()
  if RulePriorities != nil:
    formData_594157.add "RulePriorities", RulePriorities
  add(query_594156, "Action", newJString(Action))
  add(query_594156, "Version", newJString(Version))
  result = call_594155.call(nil, query_594156, nil, formData_594157, nil)

var postSetRulePriorities* = Call_PostSetRulePriorities_594141(
    name: "postSetRulePriorities", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities",
    validator: validate_PostSetRulePriorities_594142, base: "/",
    url: url_PostSetRulePriorities_594143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetRulePriorities_594125 = ref object of OpenApiRestCall_592364
proc url_GetSetRulePriorities_594127(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetRulePriorities_594126(path: JsonNode; query: JsonNode;
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
  var valid_594128 = query.getOrDefault("RulePriorities")
  valid_594128 = validateParameter(valid_594128, JArray, required = true, default = nil)
  if valid_594128 != nil:
    section.add "RulePriorities", valid_594128
  var valid_594129 = query.getOrDefault("Action")
  valid_594129 = validateParameter(valid_594129, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_594129 != nil:
    section.add "Action", valid_594129
  var valid_594130 = query.getOrDefault("Version")
  valid_594130 = validateParameter(valid_594130, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594130 != nil:
    section.add "Version", valid_594130
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
  var valid_594131 = header.getOrDefault("X-Amz-Signature")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Signature", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Content-Sha256", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Date")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Date", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-Credential")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Credential", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Security-Token")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Security-Token", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Algorithm")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Algorithm", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-SignedHeaders", valid_594137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594138: Call_GetSetRulePriorities_594125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_594138.validator(path, query, header, formData, body)
  let scheme = call_594138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594138.url(scheme.get, call_594138.host, call_594138.base,
                         call_594138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594138, url, valid)

proc call*(call_594139: Call_GetSetRulePriorities_594125; RulePriorities: JsonNode;
          Action: string = "SetRulePriorities"; Version: string = "2015-12-01"): Recallable =
  ## getSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594140 = newJObject()
  if RulePriorities != nil:
    query_594140.add "RulePriorities", RulePriorities
  add(query_594140, "Action", newJString(Action))
  add(query_594140, "Version", newJString(Version))
  result = call_594139.call(nil, query_594140, nil, nil, nil)

var getSetRulePriorities* = Call_GetSetRulePriorities_594125(
    name: "getSetRulePriorities", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities", validator: validate_GetSetRulePriorities_594126,
    base: "/", url: url_GetSetRulePriorities_594127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSecurityGroups_594175 = ref object of OpenApiRestCall_592364
proc url_PostSetSecurityGroups_594177(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetSecurityGroups_594176(path: JsonNode; query: JsonNode;
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
  var valid_594178 = query.getOrDefault("Action")
  valid_594178 = validateParameter(valid_594178, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_594178 != nil:
    section.add "Action", valid_594178
  var valid_594179 = query.getOrDefault("Version")
  valid_594179 = validateParameter(valid_594179, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594179 != nil:
    section.add "Version", valid_594179
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
  var valid_594180 = header.getOrDefault("X-Amz-Signature")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Signature", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Content-Sha256", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Date")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Date", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Credential")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Credential", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Security-Token")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Security-Token", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-SignedHeaders", valid_594186
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_594187 = formData.getOrDefault("SecurityGroups")
  valid_594187 = validateParameter(valid_594187, JArray, required = true, default = nil)
  if valid_594187 != nil:
    section.add "SecurityGroups", valid_594187
  var valid_594188 = formData.getOrDefault("LoadBalancerArn")
  valid_594188 = validateParameter(valid_594188, JString, required = true,
                                 default = nil)
  if valid_594188 != nil:
    section.add "LoadBalancerArn", valid_594188
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594189: Call_PostSetSecurityGroups_594175; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_594189.validator(path, query, header, formData, body)
  let scheme = call_594189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594189.url(scheme.get, call_594189.host, call_594189.base,
                         call_594189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594189, url, valid)

proc call*(call_594190: Call_PostSetSecurityGroups_594175;
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
  var query_594191 = newJObject()
  var formData_594192 = newJObject()
  if SecurityGroups != nil:
    formData_594192.add "SecurityGroups", SecurityGroups
  add(query_594191, "Action", newJString(Action))
  add(query_594191, "Version", newJString(Version))
  add(formData_594192, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_594190.call(nil, query_594191, nil, formData_594192, nil)

var postSetSecurityGroups* = Call_PostSetSecurityGroups_594175(
    name: "postSetSecurityGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups",
    validator: validate_PostSetSecurityGroups_594176, base: "/",
    url: url_PostSetSecurityGroups_594177, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSecurityGroups_594158 = ref object of OpenApiRestCall_592364
proc url_GetSetSecurityGroups_594160(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetSecurityGroups_594159(path: JsonNode; query: JsonNode;
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
  var valid_594161 = query.getOrDefault("LoadBalancerArn")
  valid_594161 = validateParameter(valid_594161, JString, required = true,
                                 default = nil)
  if valid_594161 != nil:
    section.add "LoadBalancerArn", valid_594161
  var valid_594162 = query.getOrDefault("SecurityGroups")
  valid_594162 = validateParameter(valid_594162, JArray, required = true, default = nil)
  if valid_594162 != nil:
    section.add "SecurityGroups", valid_594162
  var valid_594163 = query.getOrDefault("Action")
  valid_594163 = validateParameter(valid_594163, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_594163 != nil:
    section.add "Action", valid_594163
  var valid_594164 = query.getOrDefault("Version")
  valid_594164 = validateParameter(valid_594164, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594164 != nil:
    section.add "Version", valid_594164
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
  var valid_594165 = header.getOrDefault("X-Amz-Signature")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Signature", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Content-Sha256", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Date")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Date", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Credential")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Credential", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Security-Token")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Security-Token", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-SignedHeaders", valid_594171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594172: Call_GetSetSecurityGroups_594158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_594172.validator(path, query, header, formData, body)
  let scheme = call_594172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594172.url(scheme.get, call_594172.host, call_594172.base,
                         call_594172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594172, url, valid)

proc call*(call_594173: Call_GetSetSecurityGroups_594158; LoadBalancerArn: string;
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
  var query_594174 = newJObject()
  add(query_594174, "LoadBalancerArn", newJString(LoadBalancerArn))
  if SecurityGroups != nil:
    query_594174.add "SecurityGroups", SecurityGroups
  add(query_594174, "Action", newJString(Action))
  add(query_594174, "Version", newJString(Version))
  result = call_594173.call(nil, query_594174, nil, nil, nil)

var getSetSecurityGroups* = Call_GetSetSecurityGroups_594158(
    name: "getSetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups", validator: validate_GetSetSecurityGroups_594159,
    base: "/", url: url_GetSetSecurityGroups_594160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubnets_594211 = ref object of OpenApiRestCall_592364
proc url_PostSetSubnets_594213(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetSubnets_594212(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
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
  var valid_594214 = query.getOrDefault("Action")
  valid_594214 = validateParameter(valid_594214, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_594214 != nil:
    section.add "Action", valid_594214
  var valid_594215 = query.getOrDefault("Version")
  valid_594215 = validateParameter(valid_594215, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594215 != nil:
    section.add "Version", valid_594215
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
  var valid_594216 = header.getOrDefault("X-Amz-Signature")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Signature", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-Content-Sha256", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Date")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Date", valid_594218
  var valid_594219 = header.getOrDefault("X-Amz-Credential")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "X-Amz-Credential", valid_594219
  var valid_594220 = header.getOrDefault("X-Amz-Security-Token")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "X-Amz-Security-Token", valid_594220
  var valid_594221 = header.getOrDefault("X-Amz-Algorithm")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "X-Amz-Algorithm", valid_594221
  var valid_594222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "X-Amz-SignedHeaders", valid_594222
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>You cannot specify Elastic IP addresses for your subnets.</p>
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  var valid_594223 = formData.getOrDefault("Subnets")
  valid_594223 = validateParameter(valid_594223, JArray, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "Subnets", valid_594223
  var valid_594224 = formData.getOrDefault("SubnetMappings")
  valid_594224 = validateParameter(valid_594224, JArray, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "SubnetMappings", valid_594224
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_594225 = formData.getOrDefault("LoadBalancerArn")
  valid_594225 = validateParameter(valid_594225, JString, required = true,
                                 default = nil)
  if valid_594225 != nil:
    section.add "LoadBalancerArn", valid_594225
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594226: Call_PostSetSubnets_594211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  let valid = call_594226.validator(path, query, header, formData, body)
  let scheme = call_594226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594226.url(scheme.get, call_594226.host, call_594226.base,
                         call_594226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594226, url, valid)

proc call*(call_594227: Call_PostSetSubnets_594211; LoadBalancerArn: string;
          Subnets: JsonNode = nil; Action: string = "SetSubnets";
          SubnetMappings: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
  ## postSetSubnets
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   Action: string (required)
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>You cannot specify Elastic IP addresses for your subnets.</p>
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_594228 = newJObject()
  var formData_594229 = newJObject()
  if Subnets != nil:
    formData_594229.add "Subnets", Subnets
  add(query_594228, "Action", newJString(Action))
  if SubnetMappings != nil:
    formData_594229.add "SubnetMappings", SubnetMappings
  add(query_594228, "Version", newJString(Version))
  add(formData_594229, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_594227.call(nil, query_594228, nil, formData_594229, nil)

var postSetSubnets* = Call_PostSetSubnets_594211(name: "postSetSubnets",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_PostSetSubnets_594212,
    base: "/", url: url_PostSetSubnets_594213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubnets_594193 = ref object of OpenApiRestCall_592364
proc url_GetSetSubnets_594195(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetSubnets_594194(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>You cannot specify Elastic IP addresses for your subnets.</p>
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: JString (required)
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   Version: JString (required)
  section = newJObject()
  var valid_594196 = query.getOrDefault("SubnetMappings")
  valid_594196 = validateParameter(valid_594196, JArray, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "SubnetMappings", valid_594196
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_594197 = query.getOrDefault("LoadBalancerArn")
  valid_594197 = validateParameter(valid_594197, JString, required = true,
                                 default = nil)
  if valid_594197 != nil:
    section.add "LoadBalancerArn", valid_594197
  var valid_594198 = query.getOrDefault("Action")
  valid_594198 = validateParameter(valid_594198, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_594198 != nil:
    section.add "Action", valid_594198
  var valid_594199 = query.getOrDefault("Subnets")
  valid_594199 = validateParameter(valid_594199, JArray, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "Subnets", valid_594199
  var valid_594200 = query.getOrDefault("Version")
  valid_594200 = validateParameter(valid_594200, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594200 != nil:
    section.add "Version", valid_594200
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
  var valid_594201 = header.getOrDefault("X-Amz-Signature")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Signature", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-Content-Sha256", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Date")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Date", valid_594203
  var valid_594204 = header.getOrDefault("X-Amz-Credential")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "X-Amz-Credential", valid_594204
  var valid_594205 = header.getOrDefault("X-Amz-Security-Token")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "X-Amz-Security-Token", valid_594205
  var valid_594206 = header.getOrDefault("X-Amz-Algorithm")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-Algorithm", valid_594206
  var valid_594207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-SignedHeaders", valid_594207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594208: Call_GetSetSubnets_594193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  let valid = call_594208.validator(path, query, header, formData, body)
  let scheme = call_594208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594208.url(scheme.get, call_594208.host, call_594208.base,
                         call_594208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594208, url, valid)

proc call*(call_594209: Call_GetSetSubnets_594193; LoadBalancerArn: string;
          SubnetMappings: JsonNode = nil; Action: string = "SetSubnets";
          Subnets: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
  ## getSetSubnets
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>You cannot specify Elastic IP addresses for your subnets.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   Version: string (required)
  var query_594210 = newJObject()
  if SubnetMappings != nil:
    query_594210.add "SubnetMappings", SubnetMappings
  add(query_594210, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_594210, "Action", newJString(Action))
  if Subnets != nil:
    query_594210.add "Subnets", Subnets
  add(query_594210, "Version", newJString(Version))
  result = call_594209.call(nil, query_594210, nil, nil, nil)

var getSetSubnets* = Call_GetSetSubnets_594193(name: "getSetSubnets",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_GetSetSubnets_594194,
    base: "/", url: url_GetSetSubnets_594195, schemes: {Scheme.Https, Scheme.Http})
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
