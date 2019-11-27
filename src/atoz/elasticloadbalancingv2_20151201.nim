
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_PostAddListenerCertificates_599977 = ref object of OpenApiRestCall_599368
proc url_PostAddListenerCertificates_599979(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddListenerCertificates_599978(path: JsonNode; query: JsonNode;
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
  var valid_599980 = query.getOrDefault("Action")
  valid_599980 = validateParameter(valid_599980, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_599980 != nil:
    section.add "Action", valid_599980
  var valid_599981 = query.getOrDefault("Version")
  valid_599981 = validateParameter(valid_599981, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_599981 != nil:
    section.add "Version", valid_599981
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
  var valid_599982 = header.getOrDefault("X-Amz-Date")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Date", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Security-Token")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Security-Token", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Content-Sha256", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Algorithm")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Algorithm", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Signature")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Signature", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-SignedHeaders", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Credential")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Credential", valid_599988
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_599989 = formData.getOrDefault("Certificates")
  valid_599989 = validateParameter(valid_599989, JArray, required = true, default = nil)
  if valid_599989 != nil:
    section.add "Certificates", valid_599989
  var valid_599990 = formData.getOrDefault("ListenerArn")
  valid_599990 = validateParameter(valid_599990, JString, required = true,
                                 default = nil)
  if valid_599990 != nil:
    section.add "ListenerArn", valid_599990
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599991: Call_PostAddListenerCertificates_599977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_599991.validator(path, query, header, formData, body)
  let scheme = call_599991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599991.url(scheme.get, call_599991.host, call_599991.base,
                         call_599991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599991, url, valid)

proc call*(call_599992: Call_PostAddListenerCertificates_599977;
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
  var query_599993 = newJObject()
  var formData_599994 = newJObject()
  if Certificates != nil:
    formData_599994.add "Certificates", Certificates
  add(formData_599994, "ListenerArn", newJString(ListenerArn))
  add(query_599993, "Action", newJString(Action))
  add(query_599993, "Version", newJString(Version))
  result = call_599992.call(nil, query_599993, nil, formData_599994, nil)

var postAddListenerCertificates* = Call_PostAddListenerCertificates_599977(
    name: "postAddListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_PostAddListenerCertificates_599978, base: "/",
    url: url_PostAddListenerCertificates_599979,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddListenerCertificates_599705 = ref object of OpenApiRestCall_599368
proc url_GetAddListenerCertificates_599707(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddListenerCertificates_599706(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599819 = query.getOrDefault("Certificates")
  valid_599819 = validateParameter(valid_599819, JArray, required = true, default = nil)
  if valid_599819 != nil:
    section.add "Certificates", valid_599819
  var valid_599833 = query.getOrDefault("Action")
  valid_599833 = validateParameter(valid_599833, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_599833 != nil:
    section.add "Action", valid_599833
  var valid_599834 = query.getOrDefault("ListenerArn")
  valid_599834 = validateParameter(valid_599834, JString, required = true,
                                 default = nil)
  if valid_599834 != nil:
    section.add "ListenerArn", valid_599834
  var valid_599835 = query.getOrDefault("Version")
  valid_599835 = validateParameter(valid_599835, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_599835 != nil:
    section.add "Version", valid_599835
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
  var valid_599836 = header.getOrDefault("X-Amz-Date")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Date", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Security-Token")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Security-Token", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Content-Sha256", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Algorithm")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Algorithm", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Signature")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Signature", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-SignedHeaders", valid_599841
  var valid_599842 = header.getOrDefault("X-Amz-Credential")
  valid_599842 = validateParameter(valid_599842, JString, required = false,
                                 default = nil)
  if valid_599842 != nil:
    section.add "X-Amz-Credential", valid_599842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599865: Call_GetAddListenerCertificates_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_599865.validator(path, query, header, formData, body)
  let scheme = call_599865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599865.url(scheme.get, call_599865.host, call_599865.base,
                         call_599865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599865, url, valid)

proc call*(call_599936: Call_GetAddListenerCertificates_599705;
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
  var query_599937 = newJObject()
  if Certificates != nil:
    query_599937.add "Certificates", Certificates
  add(query_599937, "Action", newJString(Action))
  add(query_599937, "ListenerArn", newJString(ListenerArn))
  add(query_599937, "Version", newJString(Version))
  result = call_599936.call(nil, query_599937, nil, nil, nil)

var getAddListenerCertificates* = Call_GetAddListenerCertificates_599705(
    name: "getAddListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_GetAddListenerCertificates_599706, base: "/",
    url: url_GetAddListenerCertificates_599707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTags_600012 = ref object of OpenApiRestCall_599368
proc url_PostAddTags_600014(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddTags_600013(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600015 = query.getOrDefault("Action")
  valid_600015 = validateParameter(valid_600015, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_600015 != nil:
    section.add "Action", valid_600015
  var valid_600016 = query.getOrDefault("Version")
  valid_600016 = validateParameter(valid_600016, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600016 != nil:
    section.add "Version", valid_600016
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
  var valid_600017 = header.getOrDefault("X-Amz-Date")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Date", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Security-Token")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Security-Token", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Content-Sha256", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Algorithm")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Algorithm", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Signature")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Signature", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-SignedHeaders", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Credential")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Credential", valid_600023
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_600024 = formData.getOrDefault("ResourceArns")
  valid_600024 = validateParameter(valid_600024, JArray, required = true, default = nil)
  if valid_600024 != nil:
    section.add "ResourceArns", valid_600024
  var valid_600025 = formData.getOrDefault("Tags")
  valid_600025 = validateParameter(valid_600025, JArray, required = true, default = nil)
  if valid_600025 != nil:
    section.add "Tags", valid_600025
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600026: Call_PostAddTags_600012; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_600026.validator(path, query, header, formData, body)
  let scheme = call_600026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600026.url(scheme.get, call_600026.host, call_600026.base,
                         call_600026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600026, url, valid)

proc call*(call_600027: Call_PostAddTags_600012; ResourceArns: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2015-12-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600028 = newJObject()
  var formData_600029 = newJObject()
  if ResourceArns != nil:
    formData_600029.add "ResourceArns", ResourceArns
  if Tags != nil:
    formData_600029.add "Tags", Tags
  add(query_600028, "Action", newJString(Action))
  add(query_600028, "Version", newJString(Version))
  result = call_600027.call(nil, query_600028, nil, formData_600029, nil)

var postAddTags* = Call_PostAddTags_600012(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_600013,
                                        base: "/", url: url_PostAddTags_600014,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_599995 = ref object of OpenApiRestCall_599368
proc url_GetAddTags_599997(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTags_599996(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   Action: JString (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_599998 = query.getOrDefault("Tags")
  valid_599998 = validateParameter(valid_599998, JArray, required = true, default = nil)
  if valid_599998 != nil:
    section.add "Tags", valid_599998
  var valid_599999 = query.getOrDefault("Action")
  valid_599999 = validateParameter(valid_599999, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_599999 != nil:
    section.add "Action", valid_599999
  var valid_600000 = query.getOrDefault("ResourceArns")
  valid_600000 = validateParameter(valid_600000, JArray, required = true, default = nil)
  if valid_600000 != nil:
    section.add "ResourceArns", valid_600000
  var valid_600001 = query.getOrDefault("Version")
  valid_600001 = validateParameter(valid_600001, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600001 != nil:
    section.add "Version", valid_600001
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
  var valid_600002 = header.getOrDefault("X-Amz-Date")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Date", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Security-Token")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Security-Token", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Content-Sha256", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Algorithm")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Algorithm", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Signature")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Signature", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-SignedHeaders", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Credential")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Credential", valid_600008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600009: Call_GetAddTags_599995; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_600009.validator(path, query, header, formData, body)
  let scheme = call_600009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600009.url(scheme.get, call_600009.host, call_600009.base,
                         call_600009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600009, url, valid)

proc call*(call_600010: Call_GetAddTags_599995; Tags: JsonNode;
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
  var query_600011 = newJObject()
  if Tags != nil:
    query_600011.add "Tags", Tags
  add(query_600011, "Action", newJString(Action))
  if ResourceArns != nil:
    query_600011.add "ResourceArns", ResourceArns
  add(query_600011, "Version", newJString(Version))
  result = call_600010.call(nil, query_600011, nil, nil, nil)

var getAddTags* = Call_GetAddTags_599995(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_599996,
                                      base: "/", url: url_GetAddTags_599997,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateListener_600051 = ref object of OpenApiRestCall_599368
proc url_PostCreateListener_600053(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateListener_600052(path: JsonNode; query: JsonNode;
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
  var valid_600054 = query.getOrDefault("Action")
  valid_600054 = validateParameter(valid_600054, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_600054 != nil:
    section.add "Action", valid_600054
  var valid_600055 = query.getOrDefault("Version")
  valid_600055 = validateParameter(valid_600055, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600055 != nil:
    section.add "Version", valid_600055
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
  var valid_600056 = header.getOrDefault("X-Amz-Date")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Date", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Security-Token")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Security-Token", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Content-Sha256", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Algorithm")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Algorithm", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-Signature")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Signature", valid_600060
  var valid_600061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-SignedHeaders", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-Credential")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-Credential", valid_600062
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
  var valid_600063 = formData.getOrDefault("Certificates")
  valid_600063 = validateParameter(valid_600063, JArray, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "Certificates", valid_600063
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_600064 = formData.getOrDefault("LoadBalancerArn")
  valid_600064 = validateParameter(valid_600064, JString, required = true,
                                 default = nil)
  if valid_600064 != nil:
    section.add "LoadBalancerArn", valid_600064
  var valid_600065 = formData.getOrDefault("Port")
  valid_600065 = validateParameter(valid_600065, JInt, required = true, default = nil)
  if valid_600065 != nil:
    section.add "Port", valid_600065
  var valid_600066 = formData.getOrDefault("Protocol")
  valid_600066 = validateParameter(valid_600066, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_600066 != nil:
    section.add "Protocol", valid_600066
  var valid_600067 = formData.getOrDefault("SslPolicy")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "SslPolicy", valid_600067
  var valid_600068 = formData.getOrDefault("DefaultActions")
  valid_600068 = validateParameter(valid_600068, JArray, required = true, default = nil)
  if valid_600068 != nil:
    section.add "DefaultActions", valid_600068
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600069: Call_PostCreateListener_600051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600069.validator(path, query, header, formData, body)
  let scheme = call_600069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600069.url(scheme.get, call_600069.host, call_600069.base,
                         call_600069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600069, url, valid)

proc call*(call_600070: Call_PostCreateListener_600051; LoadBalancerArn: string;
          Port: int; DefaultActions: JsonNode; Certificates: JsonNode = nil;
          Protocol: string = "HTTP"; Action: string = "CreateListener";
          SslPolicy: string = ""; Version: string = "2015-12-01"): Recallable =
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
  var query_600071 = newJObject()
  var formData_600072 = newJObject()
  if Certificates != nil:
    formData_600072.add "Certificates", Certificates
  add(formData_600072, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_600072, "Port", newJInt(Port))
  add(formData_600072, "Protocol", newJString(Protocol))
  add(query_600071, "Action", newJString(Action))
  add(formData_600072, "SslPolicy", newJString(SslPolicy))
  if DefaultActions != nil:
    formData_600072.add "DefaultActions", DefaultActions
  add(query_600071, "Version", newJString(Version))
  result = call_600070.call(nil, query_600071, nil, formData_600072, nil)

var postCreateListener* = Call_PostCreateListener_600051(
    name: "postCreateListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=CreateListener",
    validator: validate_PostCreateListener_600052, base: "/",
    url: url_PostCreateListener_600053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateListener_600030 = ref object of OpenApiRestCall_599368
proc url_GetCreateListener_600032(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateListener_600031(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_600033 = query.getOrDefault("DefaultActions")
  valid_600033 = validateParameter(valid_600033, JArray, required = true, default = nil)
  if valid_600033 != nil:
    section.add "DefaultActions", valid_600033
  var valid_600034 = query.getOrDefault("SslPolicy")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "SslPolicy", valid_600034
  var valid_600035 = query.getOrDefault("Protocol")
  valid_600035 = validateParameter(valid_600035, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_600035 != nil:
    section.add "Protocol", valid_600035
  var valid_600036 = query.getOrDefault("Certificates")
  valid_600036 = validateParameter(valid_600036, JArray, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "Certificates", valid_600036
  var valid_600037 = query.getOrDefault("Action")
  valid_600037 = validateParameter(valid_600037, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_600037 != nil:
    section.add "Action", valid_600037
  var valid_600038 = query.getOrDefault("LoadBalancerArn")
  valid_600038 = validateParameter(valid_600038, JString, required = true,
                                 default = nil)
  if valid_600038 != nil:
    section.add "LoadBalancerArn", valid_600038
  var valid_600039 = query.getOrDefault("Port")
  valid_600039 = validateParameter(valid_600039, JInt, required = true, default = nil)
  if valid_600039 != nil:
    section.add "Port", valid_600039
  var valid_600040 = query.getOrDefault("Version")
  valid_600040 = validateParameter(valid_600040, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600040 != nil:
    section.add "Version", valid_600040
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
  var valid_600041 = header.getOrDefault("X-Amz-Date")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Date", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Security-Token")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Security-Token", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Content-Sha256", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Algorithm")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Algorithm", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Signature")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Signature", valid_600045
  var valid_600046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-SignedHeaders", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-Credential")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Credential", valid_600047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600048: Call_GetCreateListener_600030; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600048.validator(path, query, header, formData, body)
  let scheme = call_600048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600048.url(scheme.get, call_600048.host, call_600048.base,
                         call_600048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600048, url, valid)

proc call*(call_600049: Call_GetCreateListener_600030; DefaultActions: JsonNode;
          LoadBalancerArn: string; Port: int; SslPolicy: string = "";
          Protocol: string = "HTTP"; Certificates: JsonNode = nil;
          Action: string = "CreateListener"; Version: string = "2015-12-01"): Recallable =
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
  var query_600050 = newJObject()
  if DefaultActions != nil:
    query_600050.add "DefaultActions", DefaultActions
  add(query_600050, "SslPolicy", newJString(SslPolicy))
  add(query_600050, "Protocol", newJString(Protocol))
  if Certificates != nil:
    query_600050.add "Certificates", Certificates
  add(query_600050, "Action", newJString(Action))
  add(query_600050, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_600050, "Port", newJInt(Port))
  add(query_600050, "Version", newJString(Version))
  result = call_600049.call(nil, query_600050, nil, nil, nil)

var getCreateListener* = Call_GetCreateListener_600030(name: "getCreateListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateListener", validator: validate_GetCreateListener_600031,
    base: "/", url: url_GetCreateListener_600032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_600096 = ref object of OpenApiRestCall_599368
proc url_PostCreateLoadBalancer_600098(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateLoadBalancer_600097(path: JsonNode; query: JsonNode;
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
  var valid_600099 = query.getOrDefault("Action")
  valid_600099 = validateParameter(valid_600099, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_600099 != nil:
    section.add "Action", valid_600099
  var valid_600100 = query.getOrDefault("Version")
  valid_600100 = validateParameter(valid_600100, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600100 != nil:
    section.add "Version", valid_600100
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
  var valid_600101 = header.getOrDefault("X-Amz-Date")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Date", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Security-Token")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Security-Token", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Content-Sha256", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Algorithm")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Algorithm", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Signature")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Signature", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-SignedHeaders", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-Credential")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Credential", valid_600107
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
  var valid_600108 = formData.getOrDefault("Name")
  valid_600108 = validateParameter(valid_600108, JString, required = true,
                                 default = nil)
  if valid_600108 != nil:
    section.add "Name", valid_600108
  var valid_600109 = formData.getOrDefault("IpAddressType")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_600109 != nil:
    section.add "IpAddressType", valid_600109
  var valid_600110 = formData.getOrDefault("Tags")
  valid_600110 = validateParameter(valid_600110, JArray, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "Tags", valid_600110
  var valid_600111 = formData.getOrDefault("Type")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = newJString("application"))
  if valid_600111 != nil:
    section.add "Type", valid_600111
  var valid_600112 = formData.getOrDefault("Subnets")
  valid_600112 = validateParameter(valid_600112, JArray, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "Subnets", valid_600112
  var valid_600113 = formData.getOrDefault("SecurityGroups")
  valid_600113 = validateParameter(valid_600113, JArray, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "SecurityGroups", valid_600113
  var valid_600114 = formData.getOrDefault("SubnetMappings")
  valid_600114 = validateParameter(valid_600114, JArray, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "SubnetMappings", valid_600114
  var valid_600115 = formData.getOrDefault("Scheme")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_600115 != nil:
    section.add "Scheme", valid_600115
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600116: Call_PostCreateLoadBalancer_600096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600116.validator(path, query, header, formData, body)
  let scheme = call_600116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600116.url(scheme.get, call_600116.host, call_600116.base,
                         call_600116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600116, url, valid)

proc call*(call_600117: Call_PostCreateLoadBalancer_600096; Name: string;
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
  var query_600118 = newJObject()
  var formData_600119 = newJObject()
  add(formData_600119, "Name", newJString(Name))
  add(formData_600119, "IpAddressType", newJString(IpAddressType))
  if Tags != nil:
    formData_600119.add "Tags", Tags
  add(formData_600119, "Type", newJString(Type))
  add(query_600118, "Action", newJString(Action))
  if Subnets != nil:
    formData_600119.add "Subnets", Subnets
  if SecurityGroups != nil:
    formData_600119.add "SecurityGroups", SecurityGroups
  if SubnetMappings != nil:
    formData_600119.add "SubnetMappings", SubnetMappings
  add(formData_600119, "Scheme", newJString(Scheme))
  add(query_600118, "Version", newJString(Version))
  result = call_600117.call(nil, query_600118, nil, formData_600119, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_600096(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_600097, base: "/",
    url: url_PostCreateLoadBalancer_600098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_600073 = ref object of OpenApiRestCall_599368
proc url_GetCreateLoadBalancer_600075(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateLoadBalancer_600074(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600076 = query.getOrDefault("Name")
  valid_600076 = validateParameter(valid_600076, JString, required = true,
                                 default = nil)
  if valid_600076 != nil:
    section.add "Name", valid_600076
  var valid_600077 = query.getOrDefault("SubnetMappings")
  valid_600077 = validateParameter(valid_600077, JArray, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "SubnetMappings", valid_600077
  var valid_600078 = query.getOrDefault("IpAddressType")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_600078 != nil:
    section.add "IpAddressType", valid_600078
  var valid_600079 = query.getOrDefault("Scheme")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_600079 != nil:
    section.add "Scheme", valid_600079
  var valid_600080 = query.getOrDefault("Tags")
  valid_600080 = validateParameter(valid_600080, JArray, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "Tags", valid_600080
  var valid_600081 = query.getOrDefault("Type")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = newJString("application"))
  if valid_600081 != nil:
    section.add "Type", valid_600081
  var valid_600082 = query.getOrDefault("Action")
  valid_600082 = validateParameter(valid_600082, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_600082 != nil:
    section.add "Action", valid_600082
  var valid_600083 = query.getOrDefault("Subnets")
  valid_600083 = validateParameter(valid_600083, JArray, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "Subnets", valid_600083
  var valid_600084 = query.getOrDefault("Version")
  valid_600084 = validateParameter(valid_600084, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600084 != nil:
    section.add "Version", valid_600084
  var valid_600085 = query.getOrDefault("SecurityGroups")
  valid_600085 = validateParameter(valid_600085, JArray, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "SecurityGroups", valid_600085
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
  var valid_600086 = header.getOrDefault("X-Amz-Date")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Date", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Security-Token")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Security-Token", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Content-Sha256", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Algorithm")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Algorithm", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Signature")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Signature", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-SignedHeaders", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-Credential")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Credential", valid_600092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600093: Call_GetCreateLoadBalancer_600073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600093.validator(path, query, header, formData, body)
  let scheme = call_600093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600093.url(scheme.get, call_600093.host, call_600093.base,
                         call_600093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600093, url, valid)

proc call*(call_600094: Call_GetCreateLoadBalancer_600073; Name: string;
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
  var query_600095 = newJObject()
  add(query_600095, "Name", newJString(Name))
  if SubnetMappings != nil:
    query_600095.add "SubnetMappings", SubnetMappings
  add(query_600095, "IpAddressType", newJString(IpAddressType))
  add(query_600095, "Scheme", newJString(Scheme))
  if Tags != nil:
    query_600095.add "Tags", Tags
  add(query_600095, "Type", newJString(Type))
  add(query_600095, "Action", newJString(Action))
  if Subnets != nil:
    query_600095.add "Subnets", Subnets
  add(query_600095, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_600095.add "SecurityGroups", SecurityGroups
  result = call_600094.call(nil, query_600095, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_600073(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_600074, base: "/",
    url: url_GetCreateLoadBalancer_600075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateRule_600139 = ref object of OpenApiRestCall_599368
proc url_PostCreateRule_600141(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateRule_600140(path: JsonNode; query: JsonNode;
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
  var valid_600142 = query.getOrDefault("Action")
  valid_600142 = validateParameter(valid_600142, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_600142 != nil:
    section.add "Action", valid_600142
  var valid_600143 = query.getOrDefault("Version")
  valid_600143 = validateParameter(valid_600143, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600143 != nil:
    section.add "Version", valid_600143
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
  var valid_600144 = header.getOrDefault("X-Amz-Date")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Date", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Security-Token")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Security-Token", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Content-Sha256", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Algorithm")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Algorithm", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Signature")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Signature", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-SignedHeaders", valid_600149
  var valid_600150 = header.getOrDefault("X-Amz-Credential")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-Credential", valid_600150
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
  var valid_600151 = formData.getOrDefault("ListenerArn")
  valid_600151 = validateParameter(valid_600151, JString, required = true,
                                 default = nil)
  if valid_600151 != nil:
    section.add "ListenerArn", valid_600151
  var valid_600152 = formData.getOrDefault("Actions")
  valid_600152 = validateParameter(valid_600152, JArray, required = true, default = nil)
  if valid_600152 != nil:
    section.add "Actions", valid_600152
  var valid_600153 = formData.getOrDefault("Conditions")
  valid_600153 = validateParameter(valid_600153, JArray, required = true, default = nil)
  if valid_600153 != nil:
    section.add "Conditions", valid_600153
  var valid_600154 = formData.getOrDefault("Priority")
  valid_600154 = validateParameter(valid_600154, JInt, required = true, default = nil)
  if valid_600154 != nil:
    section.add "Priority", valid_600154
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600155: Call_PostCreateRule_600139; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_600155.validator(path, query, header, formData, body)
  let scheme = call_600155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600155.url(scheme.get, call_600155.host, call_600155.base,
                         call_600155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600155, url, valid)

proc call*(call_600156: Call_PostCreateRule_600139; ListenerArn: string;
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
  var query_600157 = newJObject()
  var formData_600158 = newJObject()
  add(formData_600158, "ListenerArn", newJString(ListenerArn))
  if Actions != nil:
    formData_600158.add "Actions", Actions
  if Conditions != nil:
    formData_600158.add "Conditions", Conditions
  add(query_600157, "Action", newJString(Action))
  add(formData_600158, "Priority", newJInt(Priority))
  add(query_600157, "Version", newJString(Version))
  result = call_600156.call(nil, query_600157, nil, formData_600158, nil)

var postCreateRule* = Call_PostCreateRule_600139(name: "postCreateRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_PostCreateRule_600140,
    base: "/", url: url_PostCreateRule_600141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateRule_600120 = ref object of OpenApiRestCall_599368
proc url_GetCreateRule_600122(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateRule_600121(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600123 = query.getOrDefault("Conditions")
  valid_600123 = validateParameter(valid_600123, JArray, required = true, default = nil)
  if valid_600123 != nil:
    section.add "Conditions", valid_600123
  var valid_600124 = query.getOrDefault("Action")
  valid_600124 = validateParameter(valid_600124, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_600124 != nil:
    section.add "Action", valid_600124
  var valid_600125 = query.getOrDefault("ListenerArn")
  valid_600125 = validateParameter(valid_600125, JString, required = true,
                                 default = nil)
  if valid_600125 != nil:
    section.add "ListenerArn", valid_600125
  var valid_600126 = query.getOrDefault("Actions")
  valid_600126 = validateParameter(valid_600126, JArray, required = true, default = nil)
  if valid_600126 != nil:
    section.add "Actions", valid_600126
  var valid_600127 = query.getOrDefault("Priority")
  valid_600127 = validateParameter(valid_600127, JInt, required = true, default = nil)
  if valid_600127 != nil:
    section.add "Priority", valid_600127
  var valid_600128 = query.getOrDefault("Version")
  valid_600128 = validateParameter(valid_600128, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600128 != nil:
    section.add "Version", valid_600128
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
  var valid_600129 = header.getOrDefault("X-Amz-Date")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Date", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Security-Token")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Security-Token", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Content-Sha256", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Algorithm")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Algorithm", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Signature")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Signature", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-SignedHeaders", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-Credential")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-Credential", valid_600135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600136: Call_GetCreateRule_600120; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_600136.validator(path, query, header, formData, body)
  let scheme = call_600136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600136.url(scheme.get, call_600136.host, call_600136.base,
                         call_600136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600136, url, valid)

proc call*(call_600137: Call_GetCreateRule_600120; Conditions: JsonNode;
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
  var query_600138 = newJObject()
  if Conditions != nil:
    query_600138.add "Conditions", Conditions
  add(query_600138, "Action", newJString(Action))
  add(query_600138, "ListenerArn", newJString(ListenerArn))
  if Actions != nil:
    query_600138.add "Actions", Actions
  add(query_600138, "Priority", newJInt(Priority))
  add(query_600138, "Version", newJString(Version))
  result = call_600137.call(nil, query_600138, nil, nil, nil)

var getCreateRule* = Call_GetCreateRule_600120(name: "getCreateRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_GetCreateRule_600121,
    base: "/", url: url_GetCreateRule_600122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTargetGroup_600188 = ref object of OpenApiRestCall_599368
proc url_PostCreateTargetGroup_600190(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateTargetGroup_600189(path: JsonNode; query: JsonNode;
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
  var valid_600191 = query.getOrDefault("Action")
  valid_600191 = validateParameter(valid_600191, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_600191 != nil:
    section.add "Action", valid_600191
  var valid_600192 = query.getOrDefault("Version")
  valid_600192 = validateParameter(valid_600192, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600192 != nil:
    section.add "Version", valid_600192
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
  var valid_600193 = header.getOrDefault("X-Amz-Date")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Date", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Security-Token")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Security-Token", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-Content-Sha256", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Algorithm")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Algorithm", valid_600196
  var valid_600197 = header.getOrDefault("X-Amz-Signature")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-Signature", valid_600197
  var valid_600198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-SignedHeaders", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-Credential")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-Credential", valid_600199
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
  var valid_600200 = formData.getOrDefault("Name")
  valid_600200 = validateParameter(valid_600200, JString, required = true,
                                 default = nil)
  if valid_600200 != nil:
    section.add "Name", valid_600200
  var valid_600201 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_600201 = validateParameter(valid_600201, JInt, required = false, default = nil)
  if valid_600201 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_600201
  var valid_600202 = formData.getOrDefault("Port")
  valid_600202 = validateParameter(valid_600202, JInt, required = false, default = nil)
  if valid_600202 != nil:
    section.add "Port", valid_600202
  var valid_600203 = formData.getOrDefault("Protocol")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_600203 != nil:
    section.add "Protocol", valid_600203
  var valid_600204 = formData.getOrDefault("HealthCheckPort")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "HealthCheckPort", valid_600204
  var valid_600205 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_600205 = validateParameter(valid_600205, JInt, required = false, default = nil)
  if valid_600205 != nil:
    section.add "UnhealthyThresholdCount", valid_600205
  var valid_600206 = formData.getOrDefault("HealthCheckEnabled")
  valid_600206 = validateParameter(valid_600206, JBool, required = false, default = nil)
  if valid_600206 != nil:
    section.add "HealthCheckEnabled", valid_600206
  var valid_600207 = formData.getOrDefault("HealthCheckPath")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "HealthCheckPath", valid_600207
  var valid_600208 = formData.getOrDefault("TargetType")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = newJString("instance"))
  if valid_600208 != nil:
    section.add "TargetType", valid_600208
  var valid_600209 = formData.getOrDefault("VpcId")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "VpcId", valid_600209
  var valid_600210 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_600210 = validateParameter(valid_600210, JInt, required = false, default = nil)
  if valid_600210 != nil:
    section.add "HealthCheckIntervalSeconds", valid_600210
  var valid_600211 = formData.getOrDefault("HealthyThresholdCount")
  valid_600211 = validateParameter(valid_600211, JInt, required = false, default = nil)
  if valid_600211 != nil:
    section.add "HealthyThresholdCount", valid_600211
  var valid_600212 = formData.getOrDefault("HealthCheckProtocol")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_600212 != nil:
    section.add "HealthCheckProtocol", valid_600212
  var valid_600213 = formData.getOrDefault("Matcher.HttpCode")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "Matcher.HttpCode", valid_600213
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600214: Call_PostCreateTargetGroup_600188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600214.validator(path, query, header, formData, body)
  let scheme = call_600214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600214.url(scheme.get, call_600214.host, call_600214.base,
                         call_600214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600214, url, valid)

proc call*(call_600215: Call_PostCreateTargetGroup_600188; Name: string;
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
  var query_600216 = newJObject()
  var formData_600217 = newJObject()
  add(formData_600217, "Name", newJString(Name))
  add(formData_600217, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_600217, "Port", newJInt(Port))
  add(formData_600217, "Protocol", newJString(Protocol))
  add(formData_600217, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_600217, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_600217, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_600217, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_600217, "TargetType", newJString(TargetType))
  add(query_600216, "Action", newJString(Action))
  add(formData_600217, "VpcId", newJString(VpcId))
  add(formData_600217, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_600217, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_600217, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_600217, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_600216, "Version", newJString(Version))
  result = call_600215.call(nil, query_600216, nil, formData_600217, nil)

var postCreateTargetGroup* = Call_PostCreateTargetGroup_600188(
    name: "postCreateTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup",
    validator: validate_PostCreateTargetGroup_600189, base: "/",
    url: url_PostCreateTargetGroup_600190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTargetGroup_600159 = ref object of OpenApiRestCall_599368
proc url_GetCreateTargetGroup_600161(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateTargetGroup_600160(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600162 = query.getOrDefault("HealthCheckEnabled")
  valid_600162 = validateParameter(valid_600162, JBool, required = false, default = nil)
  if valid_600162 != nil:
    section.add "HealthCheckEnabled", valid_600162
  var valid_600163 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_600163 = validateParameter(valid_600163, JInt, required = false, default = nil)
  if valid_600163 != nil:
    section.add "HealthCheckIntervalSeconds", valid_600163
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_600164 = query.getOrDefault("Name")
  valid_600164 = validateParameter(valid_600164, JString, required = true,
                                 default = nil)
  if valid_600164 != nil:
    section.add "Name", valid_600164
  var valid_600165 = query.getOrDefault("HealthCheckPort")
  valid_600165 = validateParameter(valid_600165, JString, required = false,
                                 default = nil)
  if valid_600165 != nil:
    section.add "HealthCheckPort", valid_600165
  var valid_600166 = query.getOrDefault("Protocol")
  valid_600166 = validateParameter(valid_600166, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_600166 != nil:
    section.add "Protocol", valid_600166
  var valid_600167 = query.getOrDefault("VpcId")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "VpcId", valid_600167
  var valid_600168 = query.getOrDefault("Action")
  valid_600168 = validateParameter(valid_600168, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_600168 != nil:
    section.add "Action", valid_600168
  var valid_600169 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_600169 = validateParameter(valid_600169, JInt, required = false, default = nil)
  if valid_600169 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_600169
  var valid_600170 = query.getOrDefault("Matcher.HttpCode")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "Matcher.HttpCode", valid_600170
  var valid_600171 = query.getOrDefault("UnhealthyThresholdCount")
  valid_600171 = validateParameter(valid_600171, JInt, required = false, default = nil)
  if valid_600171 != nil:
    section.add "UnhealthyThresholdCount", valid_600171
  var valid_600172 = query.getOrDefault("TargetType")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = newJString("instance"))
  if valid_600172 != nil:
    section.add "TargetType", valid_600172
  var valid_600173 = query.getOrDefault("Port")
  valid_600173 = validateParameter(valid_600173, JInt, required = false, default = nil)
  if valid_600173 != nil:
    section.add "Port", valid_600173
  var valid_600174 = query.getOrDefault("HealthCheckProtocol")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_600174 != nil:
    section.add "HealthCheckProtocol", valid_600174
  var valid_600175 = query.getOrDefault("HealthyThresholdCount")
  valid_600175 = validateParameter(valid_600175, JInt, required = false, default = nil)
  if valid_600175 != nil:
    section.add "HealthyThresholdCount", valid_600175
  var valid_600176 = query.getOrDefault("Version")
  valid_600176 = validateParameter(valid_600176, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600176 != nil:
    section.add "Version", valid_600176
  var valid_600177 = query.getOrDefault("HealthCheckPath")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "HealthCheckPath", valid_600177
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
  var valid_600178 = header.getOrDefault("X-Amz-Date")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Date", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Security-Token")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Security-Token", valid_600179
  var valid_600180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-Content-Sha256", valid_600180
  var valid_600181 = header.getOrDefault("X-Amz-Algorithm")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Algorithm", valid_600181
  var valid_600182 = header.getOrDefault("X-Amz-Signature")
  valid_600182 = validateParameter(valid_600182, JString, required = false,
                                 default = nil)
  if valid_600182 != nil:
    section.add "X-Amz-Signature", valid_600182
  var valid_600183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-SignedHeaders", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-Credential")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Credential", valid_600184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600185: Call_GetCreateTargetGroup_600159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600185.validator(path, query, header, formData, body)
  let scheme = call_600185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600185.url(scheme.get, call_600185.host, call_600185.base,
                         call_600185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600185, url, valid)

proc call*(call_600186: Call_GetCreateTargetGroup_600159; Name: string;
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
  var query_600187 = newJObject()
  add(query_600187, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_600187, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_600187, "Name", newJString(Name))
  add(query_600187, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_600187, "Protocol", newJString(Protocol))
  add(query_600187, "VpcId", newJString(VpcId))
  add(query_600187, "Action", newJString(Action))
  add(query_600187, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_600187, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_600187, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_600187, "TargetType", newJString(TargetType))
  add(query_600187, "Port", newJInt(Port))
  add(query_600187, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_600187, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_600187, "Version", newJString(Version))
  add(query_600187, "HealthCheckPath", newJString(HealthCheckPath))
  result = call_600186.call(nil, query_600187, nil, nil, nil)

var getCreateTargetGroup* = Call_GetCreateTargetGroup_600159(
    name: "getCreateTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup", validator: validate_GetCreateTargetGroup_600160,
    base: "/", url: url_GetCreateTargetGroup_600161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteListener_600234 = ref object of OpenApiRestCall_599368
proc url_PostDeleteListener_600236(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteListener_600235(path: JsonNode; query: JsonNode;
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
  var valid_600237 = query.getOrDefault("Action")
  valid_600237 = validateParameter(valid_600237, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_600237 != nil:
    section.add "Action", valid_600237
  var valid_600238 = query.getOrDefault("Version")
  valid_600238 = validateParameter(valid_600238, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600238 != nil:
    section.add "Version", valid_600238
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
  var valid_600239 = header.getOrDefault("X-Amz-Date")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Date", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-Security-Token")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Security-Token", valid_600240
  var valid_600241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Content-Sha256", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-Algorithm")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Algorithm", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Signature")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Signature", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-SignedHeaders", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Credential")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Credential", valid_600245
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_600246 = formData.getOrDefault("ListenerArn")
  valid_600246 = validateParameter(valid_600246, JString, required = true,
                                 default = nil)
  if valid_600246 != nil:
    section.add "ListenerArn", valid_600246
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600247: Call_PostDeleteListener_600234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_600247.validator(path, query, header, formData, body)
  let scheme = call_600247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600247.url(scheme.get, call_600247.host, call_600247.base,
                         call_600247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600247, url, valid)

proc call*(call_600248: Call_PostDeleteListener_600234; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600249 = newJObject()
  var formData_600250 = newJObject()
  add(formData_600250, "ListenerArn", newJString(ListenerArn))
  add(query_600249, "Action", newJString(Action))
  add(query_600249, "Version", newJString(Version))
  result = call_600248.call(nil, query_600249, nil, formData_600250, nil)

var postDeleteListener* = Call_PostDeleteListener_600234(
    name: "postDeleteListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=DeleteListener",
    validator: validate_PostDeleteListener_600235, base: "/",
    url: url_PostDeleteListener_600236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteListener_600218 = ref object of OpenApiRestCall_599368
proc url_GetDeleteListener_600220(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteListener_600219(path: JsonNode; query: JsonNode;
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
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600221 = query.getOrDefault("Action")
  valid_600221 = validateParameter(valid_600221, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_600221 != nil:
    section.add "Action", valid_600221
  var valid_600222 = query.getOrDefault("ListenerArn")
  valid_600222 = validateParameter(valid_600222, JString, required = true,
                                 default = nil)
  if valid_600222 != nil:
    section.add "ListenerArn", valid_600222
  var valid_600223 = query.getOrDefault("Version")
  valid_600223 = validateParameter(valid_600223, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600223 != nil:
    section.add "Version", valid_600223
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
  var valid_600224 = header.getOrDefault("X-Amz-Date")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Date", valid_600224
  var valid_600225 = header.getOrDefault("X-Amz-Security-Token")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Security-Token", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Content-Sha256", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-Algorithm")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Algorithm", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Signature")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Signature", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-SignedHeaders", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Credential")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Credential", valid_600230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600231: Call_GetDeleteListener_600218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_600231.validator(path, query, header, formData, body)
  let scheme = call_600231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600231.url(scheme.get, call_600231.host, call_600231.base,
                         call_600231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600231, url, valid)

proc call*(call_600232: Call_GetDeleteListener_600218; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   Action: string (required)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: string (required)
  var query_600233 = newJObject()
  add(query_600233, "Action", newJString(Action))
  add(query_600233, "ListenerArn", newJString(ListenerArn))
  add(query_600233, "Version", newJString(Version))
  result = call_600232.call(nil, query_600233, nil, nil, nil)

var getDeleteListener* = Call_GetDeleteListener_600218(name: "getDeleteListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteListener", validator: validate_GetDeleteListener_600219,
    base: "/", url: url_GetDeleteListener_600220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_600267 = ref object of OpenApiRestCall_599368
proc url_PostDeleteLoadBalancer_600269(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteLoadBalancer_600268(path: JsonNode; query: JsonNode;
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
  var valid_600270 = query.getOrDefault("Action")
  valid_600270 = validateParameter(valid_600270, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_600270 != nil:
    section.add "Action", valid_600270
  var valid_600271 = query.getOrDefault("Version")
  valid_600271 = validateParameter(valid_600271, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600271 != nil:
    section.add "Version", valid_600271
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
  var valid_600272 = header.getOrDefault("X-Amz-Date")
  valid_600272 = validateParameter(valid_600272, JString, required = false,
                                 default = nil)
  if valid_600272 != nil:
    section.add "X-Amz-Date", valid_600272
  var valid_600273 = header.getOrDefault("X-Amz-Security-Token")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-Security-Token", valid_600273
  var valid_600274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Content-Sha256", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-Algorithm")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-Algorithm", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Signature")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Signature", valid_600276
  var valid_600277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-SignedHeaders", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Credential")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Credential", valid_600278
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_600279 = formData.getOrDefault("LoadBalancerArn")
  valid_600279 = validateParameter(valid_600279, JString, required = true,
                                 default = nil)
  if valid_600279 != nil:
    section.add "LoadBalancerArn", valid_600279
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600280: Call_PostDeleteLoadBalancer_600267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_600280.validator(path, query, header, formData, body)
  let scheme = call_600280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600280.url(scheme.get, call_600280.host, call_600280.base,
                         call_600280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600280, url, valid)

proc call*(call_600281: Call_PostDeleteLoadBalancer_600267;
          LoadBalancerArn: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2015-12-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600282 = newJObject()
  var formData_600283 = newJObject()
  add(formData_600283, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_600282, "Action", newJString(Action))
  add(query_600282, "Version", newJString(Version))
  result = call_600281.call(nil, query_600282, nil, formData_600283, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_600267(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_600268, base: "/",
    url: url_PostDeleteLoadBalancer_600269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_600251 = ref object of OpenApiRestCall_599368
proc url_GetDeleteLoadBalancer_600253(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteLoadBalancer_600252(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600254 = query.getOrDefault("Action")
  valid_600254 = validateParameter(valid_600254, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_600254 != nil:
    section.add "Action", valid_600254
  var valid_600255 = query.getOrDefault("LoadBalancerArn")
  valid_600255 = validateParameter(valid_600255, JString, required = true,
                                 default = nil)
  if valid_600255 != nil:
    section.add "LoadBalancerArn", valid_600255
  var valid_600256 = query.getOrDefault("Version")
  valid_600256 = validateParameter(valid_600256, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600256 != nil:
    section.add "Version", valid_600256
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
  var valid_600257 = header.getOrDefault("X-Amz-Date")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Date", valid_600257
  var valid_600258 = header.getOrDefault("X-Amz-Security-Token")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Security-Token", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Content-Sha256", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Algorithm")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Algorithm", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Signature")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Signature", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-SignedHeaders", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Credential")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Credential", valid_600263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600264: Call_GetDeleteLoadBalancer_600251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_600264.validator(path, query, header, formData, body)
  let scheme = call_600264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600264.url(scheme.get, call_600264.host, call_600264.base,
                         call_600264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600264, url, valid)

proc call*(call_600265: Call_GetDeleteLoadBalancer_600251; LoadBalancerArn: string;
          Action: string = "DeleteLoadBalancer"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_600266 = newJObject()
  add(query_600266, "Action", newJString(Action))
  add(query_600266, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_600266, "Version", newJString(Version))
  result = call_600265.call(nil, query_600266, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_600251(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_600252, base: "/",
    url: url_GetDeleteLoadBalancer_600253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRule_600300 = ref object of OpenApiRestCall_599368
proc url_PostDeleteRule_600302(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteRule_600301(path: JsonNode; query: JsonNode;
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
  var valid_600303 = query.getOrDefault("Action")
  valid_600303 = validateParameter(valid_600303, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_600303 != nil:
    section.add "Action", valid_600303
  var valid_600304 = query.getOrDefault("Version")
  valid_600304 = validateParameter(valid_600304, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600304 != nil:
    section.add "Version", valid_600304
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
  var valid_600305 = header.getOrDefault("X-Amz-Date")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Date", valid_600305
  var valid_600306 = header.getOrDefault("X-Amz-Security-Token")
  valid_600306 = validateParameter(valid_600306, JString, required = false,
                                 default = nil)
  if valid_600306 != nil:
    section.add "X-Amz-Security-Token", valid_600306
  var valid_600307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Content-Sha256", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Algorithm")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Algorithm", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Signature")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Signature", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-SignedHeaders", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Credential")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Credential", valid_600311
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_600312 = formData.getOrDefault("RuleArn")
  valid_600312 = validateParameter(valid_600312, JString, required = true,
                                 default = nil)
  if valid_600312 != nil:
    section.add "RuleArn", valid_600312
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600313: Call_PostDeleteRule_600300; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_600313.validator(path, query, header, formData, body)
  let scheme = call_600313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600313.url(scheme.get, call_600313.host, call_600313.base,
                         call_600313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600313, url, valid)

proc call*(call_600314: Call_PostDeleteRule_600300; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600315 = newJObject()
  var formData_600316 = newJObject()
  add(formData_600316, "RuleArn", newJString(RuleArn))
  add(query_600315, "Action", newJString(Action))
  add(query_600315, "Version", newJString(Version))
  result = call_600314.call(nil, query_600315, nil, formData_600316, nil)

var postDeleteRule* = Call_PostDeleteRule_600300(name: "postDeleteRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_PostDeleteRule_600301,
    base: "/", url: url_PostDeleteRule_600302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRule_600284 = ref object of OpenApiRestCall_599368
proc url_GetDeleteRule_600286(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteRule_600285(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600287 = query.getOrDefault("Action")
  valid_600287 = validateParameter(valid_600287, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_600287 != nil:
    section.add "Action", valid_600287
  var valid_600288 = query.getOrDefault("RuleArn")
  valid_600288 = validateParameter(valid_600288, JString, required = true,
                                 default = nil)
  if valid_600288 != nil:
    section.add "RuleArn", valid_600288
  var valid_600289 = query.getOrDefault("Version")
  valid_600289 = validateParameter(valid_600289, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600289 != nil:
    section.add "Version", valid_600289
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
  var valid_600290 = header.getOrDefault("X-Amz-Date")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Date", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Security-Token")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Security-Token", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Content-Sha256", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Algorithm")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Algorithm", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Signature")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Signature", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-SignedHeaders", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Credential")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Credential", valid_600296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600297: Call_GetDeleteRule_600284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_600297.validator(path, query, header, formData, body)
  let scheme = call_600297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600297.url(scheme.get, call_600297.host, call_600297.base,
                         call_600297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600297, url, valid)

proc call*(call_600298: Call_GetDeleteRule_600284; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteRule
  ## Deletes the specified rule.
  ##   Action: string (required)
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Version: string (required)
  var query_600299 = newJObject()
  add(query_600299, "Action", newJString(Action))
  add(query_600299, "RuleArn", newJString(RuleArn))
  add(query_600299, "Version", newJString(Version))
  result = call_600298.call(nil, query_600299, nil, nil, nil)

var getDeleteRule* = Call_GetDeleteRule_600284(name: "getDeleteRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_GetDeleteRule_600285,
    base: "/", url: url_GetDeleteRule_600286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTargetGroup_600333 = ref object of OpenApiRestCall_599368
proc url_PostDeleteTargetGroup_600335(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteTargetGroup_600334(path: JsonNode; query: JsonNode;
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
  var valid_600336 = query.getOrDefault("Action")
  valid_600336 = validateParameter(valid_600336, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_600336 != nil:
    section.add "Action", valid_600336
  var valid_600337 = query.getOrDefault("Version")
  valid_600337 = validateParameter(valid_600337, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600337 != nil:
    section.add "Version", valid_600337
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
  var valid_600338 = header.getOrDefault("X-Amz-Date")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Date", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-Security-Token")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Security-Token", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Content-Sha256", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Algorithm")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Algorithm", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Signature")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Signature", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-SignedHeaders", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Credential")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Credential", valid_600344
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_600345 = formData.getOrDefault("TargetGroupArn")
  valid_600345 = validateParameter(valid_600345, JString, required = true,
                                 default = nil)
  if valid_600345 != nil:
    section.add "TargetGroupArn", valid_600345
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600346: Call_PostDeleteTargetGroup_600333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_600346.validator(path, query, header, formData, body)
  let scheme = call_600346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600346.url(scheme.get, call_600346.host, call_600346.base,
                         call_600346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600346, url, valid)

proc call*(call_600347: Call_PostDeleteTargetGroup_600333; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_600348 = newJObject()
  var formData_600349 = newJObject()
  add(query_600348, "Action", newJString(Action))
  add(formData_600349, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_600348, "Version", newJString(Version))
  result = call_600347.call(nil, query_600348, nil, formData_600349, nil)

var postDeleteTargetGroup* = Call_PostDeleteTargetGroup_600333(
    name: "postDeleteTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup",
    validator: validate_PostDeleteTargetGroup_600334, base: "/",
    url: url_PostDeleteTargetGroup_600335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTargetGroup_600317 = ref object of OpenApiRestCall_599368
proc url_GetDeleteTargetGroup_600319(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteTargetGroup_600318(path: JsonNode; query: JsonNode;
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
  var valid_600320 = query.getOrDefault("TargetGroupArn")
  valid_600320 = validateParameter(valid_600320, JString, required = true,
                                 default = nil)
  if valid_600320 != nil:
    section.add "TargetGroupArn", valid_600320
  var valid_600321 = query.getOrDefault("Action")
  valid_600321 = validateParameter(valid_600321, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_600321 != nil:
    section.add "Action", valid_600321
  var valid_600322 = query.getOrDefault("Version")
  valid_600322 = validateParameter(valid_600322, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600322 != nil:
    section.add "Version", valid_600322
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
  var valid_600323 = header.getOrDefault("X-Amz-Date")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Date", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-Security-Token")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Security-Token", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Content-Sha256", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Algorithm")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Algorithm", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Signature")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Signature", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-SignedHeaders", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Credential")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Credential", valid_600329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600330: Call_GetDeleteTargetGroup_600317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_600330.validator(path, query, header, formData, body)
  let scheme = call_600330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600330.url(scheme.get, call_600330.host, call_600330.base,
                         call_600330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600330, url, valid)

proc call*(call_600331: Call_GetDeleteTargetGroup_600317; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600332 = newJObject()
  add(query_600332, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_600332, "Action", newJString(Action))
  add(query_600332, "Version", newJString(Version))
  result = call_600331.call(nil, query_600332, nil, nil, nil)

var getDeleteTargetGroup* = Call_GetDeleteTargetGroup_600317(
    name: "getDeleteTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup", validator: validate_GetDeleteTargetGroup_600318,
    base: "/", url: url_GetDeleteTargetGroup_600319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterTargets_600367 = ref object of OpenApiRestCall_599368
proc url_PostDeregisterTargets_600369(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeregisterTargets_600368(path: JsonNode; query: JsonNode;
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
  var valid_600370 = query.getOrDefault("Action")
  valid_600370 = validateParameter(valid_600370, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_600370 != nil:
    section.add "Action", valid_600370
  var valid_600371 = query.getOrDefault("Version")
  valid_600371 = validateParameter(valid_600371, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600371 != nil:
    section.add "Version", valid_600371
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
  var valid_600372 = header.getOrDefault("X-Amz-Date")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Date", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-Security-Token")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-Security-Token", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Content-Sha256", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Algorithm")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Algorithm", valid_600375
  var valid_600376 = header.getOrDefault("X-Amz-Signature")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-Signature", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-SignedHeaders", valid_600377
  var valid_600378 = header.getOrDefault("X-Amz-Credential")
  valid_600378 = validateParameter(valid_600378, JString, required = false,
                                 default = nil)
  if valid_600378 != nil:
    section.add "X-Amz-Credential", valid_600378
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_600379 = formData.getOrDefault("Targets")
  valid_600379 = validateParameter(valid_600379, JArray, required = true, default = nil)
  if valid_600379 != nil:
    section.add "Targets", valid_600379
  var valid_600380 = formData.getOrDefault("TargetGroupArn")
  valid_600380 = validateParameter(valid_600380, JString, required = true,
                                 default = nil)
  if valid_600380 != nil:
    section.add "TargetGroupArn", valid_600380
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600381: Call_PostDeregisterTargets_600367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_600381.validator(path, query, header, formData, body)
  let scheme = call_600381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600381.url(scheme.get, call_600381.host, call_600381.base,
                         call_600381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600381, url, valid)

proc call*(call_600382: Call_PostDeregisterTargets_600367; Targets: JsonNode;
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
  var query_600383 = newJObject()
  var formData_600384 = newJObject()
  if Targets != nil:
    formData_600384.add "Targets", Targets
  add(query_600383, "Action", newJString(Action))
  add(formData_600384, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_600383, "Version", newJString(Version))
  result = call_600382.call(nil, query_600383, nil, formData_600384, nil)

var postDeregisterTargets* = Call_PostDeregisterTargets_600367(
    name: "postDeregisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets",
    validator: validate_PostDeregisterTargets_600368, base: "/",
    url: url_PostDeregisterTargets_600369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterTargets_600350 = ref object of OpenApiRestCall_599368
proc url_GetDeregisterTargets_600352(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeregisterTargets_600351(path: JsonNode; query: JsonNode;
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
  var valid_600353 = query.getOrDefault("Targets")
  valid_600353 = validateParameter(valid_600353, JArray, required = true, default = nil)
  if valid_600353 != nil:
    section.add "Targets", valid_600353
  var valid_600354 = query.getOrDefault("TargetGroupArn")
  valid_600354 = validateParameter(valid_600354, JString, required = true,
                                 default = nil)
  if valid_600354 != nil:
    section.add "TargetGroupArn", valid_600354
  var valid_600355 = query.getOrDefault("Action")
  valid_600355 = validateParameter(valid_600355, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_600355 != nil:
    section.add "Action", valid_600355
  var valid_600356 = query.getOrDefault("Version")
  valid_600356 = validateParameter(valid_600356, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600356 != nil:
    section.add "Version", valid_600356
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
  var valid_600357 = header.getOrDefault("X-Amz-Date")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Date", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-Security-Token")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-Security-Token", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Content-Sha256", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Algorithm")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Algorithm", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-Signature")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-Signature", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-SignedHeaders", valid_600362
  var valid_600363 = header.getOrDefault("X-Amz-Credential")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "X-Amz-Credential", valid_600363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600364: Call_GetDeregisterTargets_600350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_600364.validator(path, query, header, formData, body)
  let scheme = call_600364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600364.url(scheme.get, call_600364.host, call_600364.base,
                         call_600364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600364, url, valid)

proc call*(call_600365: Call_GetDeregisterTargets_600350; Targets: JsonNode;
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
  var query_600366 = newJObject()
  if Targets != nil:
    query_600366.add "Targets", Targets
  add(query_600366, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_600366, "Action", newJString(Action))
  add(query_600366, "Version", newJString(Version))
  result = call_600365.call(nil, query_600366, nil, nil, nil)

var getDeregisterTargets* = Call_GetDeregisterTargets_600350(
    name: "getDeregisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets", validator: validate_GetDeregisterTargets_600351,
    base: "/", url: url_GetDeregisterTargets_600352,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_600402 = ref object of OpenApiRestCall_599368
proc url_PostDescribeAccountLimits_600404(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAccountLimits_600403(path: JsonNode; query: JsonNode;
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
  var valid_600405 = query.getOrDefault("Action")
  valid_600405 = validateParameter(valid_600405, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_600405 != nil:
    section.add "Action", valid_600405
  var valid_600406 = query.getOrDefault("Version")
  valid_600406 = validateParameter(valid_600406, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600406 != nil:
    section.add "Version", valid_600406
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
  var valid_600407 = header.getOrDefault("X-Amz-Date")
  valid_600407 = validateParameter(valid_600407, JString, required = false,
                                 default = nil)
  if valid_600407 != nil:
    section.add "X-Amz-Date", valid_600407
  var valid_600408 = header.getOrDefault("X-Amz-Security-Token")
  valid_600408 = validateParameter(valid_600408, JString, required = false,
                                 default = nil)
  if valid_600408 != nil:
    section.add "X-Amz-Security-Token", valid_600408
  var valid_600409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600409 = validateParameter(valid_600409, JString, required = false,
                                 default = nil)
  if valid_600409 != nil:
    section.add "X-Amz-Content-Sha256", valid_600409
  var valid_600410 = header.getOrDefault("X-Amz-Algorithm")
  valid_600410 = validateParameter(valid_600410, JString, required = false,
                                 default = nil)
  if valid_600410 != nil:
    section.add "X-Amz-Algorithm", valid_600410
  var valid_600411 = header.getOrDefault("X-Amz-Signature")
  valid_600411 = validateParameter(valid_600411, JString, required = false,
                                 default = nil)
  if valid_600411 != nil:
    section.add "X-Amz-Signature", valid_600411
  var valid_600412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600412 = validateParameter(valid_600412, JString, required = false,
                                 default = nil)
  if valid_600412 != nil:
    section.add "X-Amz-SignedHeaders", valid_600412
  var valid_600413 = header.getOrDefault("X-Amz-Credential")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "X-Amz-Credential", valid_600413
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_600414 = formData.getOrDefault("Marker")
  valid_600414 = validateParameter(valid_600414, JString, required = false,
                                 default = nil)
  if valid_600414 != nil:
    section.add "Marker", valid_600414
  var valid_600415 = formData.getOrDefault("PageSize")
  valid_600415 = validateParameter(valid_600415, JInt, required = false, default = nil)
  if valid_600415 != nil:
    section.add "PageSize", valid_600415
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600416: Call_PostDescribeAccountLimits_600402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600416.validator(path, query, header, formData, body)
  let scheme = call_600416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600416.url(scheme.get, call_600416.host, call_600416.base,
                         call_600416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600416, url, valid)

proc call*(call_600417: Call_PostDescribeAccountLimits_600402; Marker: string = "";
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
  var query_600418 = newJObject()
  var formData_600419 = newJObject()
  add(formData_600419, "Marker", newJString(Marker))
  add(query_600418, "Action", newJString(Action))
  add(formData_600419, "PageSize", newJInt(PageSize))
  add(query_600418, "Version", newJString(Version))
  result = call_600417.call(nil, query_600418, nil, formData_600419, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_600402(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_600403, base: "/",
    url: url_PostDescribeAccountLimits_600404,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_600385 = ref object of OpenApiRestCall_599368
proc url_GetDescribeAccountLimits_600387(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAccountLimits_600386(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600388 = query.getOrDefault("PageSize")
  valid_600388 = validateParameter(valid_600388, JInt, required = false, default = nil)
  if valid_600388 != nil:
    section.add "PageSize", valid_600388
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600389 = query.getOrDefault("Action")
  valid_600389 = validateParameter(valid_600389, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_600389 != nil:
    section.add "Action", valid_600389
  var valid_600390 = query.getOrDefault("Marker")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "Marker", valid_600390
  var valid_600391 = query.getOrDefault("Version")
  valid_600391 = validateParameter(valid_600391, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600391 != nil:
    section.add "Version", valid_600391
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
  var valid_600392 = header.getOrDefault("X-Amz-Date")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-Date", valid_600392
  var valid_600393 = header.getOrDefault("X-Amz-Security-Token")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "X-Amz-Security-Token", valid_600393
  var valid_600394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600394 = validateParameter(valid_600394, JString, required = false,
                                 default = nil)
  if valid_600394 != nil:
    section.add "X-Amz-Content-Sha256", valid_600394
  var valid_600395 = header.getOrDefault("X-Amz-Algorithm")
  valid_600395 = validateParameter(valid_600395, JString, required = false,
                                 default = nil)
  if valid_600395 != nil:
    section.add "X-Amz-Algorithm", valid_600395
  var valid_600396 = header.getOrDefault("X-Amz-Signature")
  valid_600396 = validateParameter(valid_600396, JString, required = false,
                                 default = nil)
  if valid_600396 != nil:
    section.add "X-Amz-Signature", valid_600396
  var valid_600397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-SignedHeaders", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Credential")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Credential", valid_600398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600399: Call_GetDescribeAccountLimits_600385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600399.validator(path, query, header, formData, body)
  let scheme = call_600399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600399.url(scheme.get, call_600399.host, call_600399.base,
                         call_600399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600399, url, valid)

proc call*(call_600400: Call_GetDescribeAccountLimits_600385; PageSize: int = 0;
          Action: string = "DescribeAccountLimits"; Marker: string = "";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeAccountLimits
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: string (required)
  var query_600401 = newJObject()
  add(query_600401, "PageSize", newJInt(PageSize))
  add(query_600401, "Action", newJString(Action))
  add(query_600401, "Marker", newJString(Marker))
  add(query_600401, "Version", newJString(Version))
  result = call_600400.call(nil, query_600401, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_600385(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_600386, base: "/",
    url: url_GetDescribeAccountLimits_600387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListenerCertificates_600438 = ref object of OpenApiRestCall_599368
proc url_PostDescribeListenerCertificates_600440(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeListenerCertificates_600439(path: JsonNode;
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
  var valid_600441 = query.getOrDefault("Action")
  valid_600441 = validateParameter(valid_600441, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_600441 != nil:
    section.add "Action", valid_600441
  var valid_600442 = query.getOrDefault("Version")
  valid_600442 = validateParameter(valid_600442, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600442 != nil:
    section.add "Version", valid_600442
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
  var valid_600443 = header.getOrDefault("X-Amz-Date")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-Date", valid_600443
  var valid_600444 = header.getOrDefault("X-Amz-Security-Token")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "X-Amz-Security-Token", valid_600444
  var valid_600445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600445 = validateParameter(valid_600445, JString, required = false,
                                 default = nil)
  if valid_600445 != nil:
    section.add "X-Amz-Content-Sha256", valid_600445
  var valid_600446 = header.getOrDefault("X-Amz-Algorithm")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-Algorithm", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Signature")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Signature", valid_600447
  var valid_600448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600448 = validateParameter(valid_600448, JString, required = false,
                                 default = nil)
  if valid_600448 != nil:
    section.add "X-Amz-SignedHeaders", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-Credential")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Credential", valid_600449
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
  var valid_600450 = formData.getOrDefault("ListenerArn")
  valid_600450 = validateParameter(valid_600450, JString, required = true,
                                 default = nil)
  if valid_600450 != nil:
    section.add "ListenerArn", valid_600450
  var valid_600451 = formData.getOrDefault("Marker")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "Marker", valid_600451
  var valid_600452 = formData.getOrDefault("PageSize")
  valid_600452 = validateParameter(valid_600452, JInt, required = false, default = nil)
  if valid_600452 != nil:
    section.add "PageSize", valid_600452
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600453: Call_PostDescribeListenerCertificates_600438;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600453.validator(path, query, header, formData, body)
  let scheme = call_600453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600453.url(scheme.get, call_600453.host, call_600453.base,
                         call_600453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600453, url, valid)

proc call*(call_600454: Call_PostDescribeListenerCertificates_600438;
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
  var query_600455 = newJObject()
  var formData_600456 = newJObject()
  add(formData_600456, "ListenerArn", newJString(ListenerArn))
  add(formData_600456, "Marker", newJString(Marker))
  add(query_600455, "Action", newJString(Action))
  add(formData_600456, "PageSize", newJInt(PageSize))
  add(query_600455, "Version", newJString(Version))
  result = call_600454.call(nil, query_600455, nil, formData_600456, nil)

var postDescribeListenerCertificates* = Call_PostDescribeListenerCertificates_600438(
    name: "postDescribeListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_PostDescribeListenerCertificates_600439, base: "/",
    url: url_PostDescribeListenerCertificates_600440,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListenerCertificates_600420 = ref object of OpenApiRestCall_599368
proc url_GetDescribeListenerCertificates_600422(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeListenerCertificates_600421(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600423 = query.getOrDefault("PageSize")
  valid_600423 = validateParameter(valid_600423, JInt, required = false, default = nil)
  if valid_600423 != nil:
    section.add "PageSize", valid_600423
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600424 = query.getOrDefault("Action")
  valid_600424 = validateParameter(valid_600424, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_600424 != nil:
    section.add "Action", valid_600424
  var valid_600425 = query.getOrDefault("Marker")
  valid_600425 = validateParameter(valid_600425, JString, required = false,
                                 default = nil)
  if valid_600425 != nil:
    section.add "Marker", valid_600425
  var valid_600426 = query.getOrDefault("ListenerArn")
  valid_600426 = validateParameter(valid_600426, JString, required = true,
                                 default = nil)
  if valid_600426 != nil:
    section.add "ListenerArn", valid_600426
  var valid_600427 = query.getOrDefault("Version")
  valid_600427 = validateParameter(valid_600427, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600427 != nil:
    section.add "Version", valid_600427
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
  var valid_600428 = header.getOrDefault("X-Amz-Date")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-Date", valid_600428
  var valid_600429 = header.getOrDefault("X-Amz-Security-Token")
  valid_600429 = validateParameter(valid_600429, JString, required = false,
                                 default = nil)
  if valid_600429 != nil:
    section.add "X-Amz-Security-Token", valid_600429
  var valid_600430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600430 = validateParameter(valid_600430, JString, required = false,
                                 default = nil)
  if valid_600430 != nil:
    section.add "X-Amz-Content-Sha256", valid_600430
  var valid_600431 = header.getOrDefault("X-Amz-Algorithm")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Algorithm", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Signature")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Signature", valid_600432
  var valid_600433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-SignedHeaders", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Credential")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Credential", valid_600434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600435: Call_GetDescribeListenerCertificates_600420;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600435.validator(path, query, header, formData, body)
  let scheme = call_600435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600435.url(scheme.get, call_600435.host, call_600435.base,
                         call_600435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600435, url, valid)

proc call*(call_600436: Call_GetDescribeListenerCertificates_600420;
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
  var query_600437 = newJObject()
  add(query_600437, "PageSize", newJInt(PageSize))
  add(query_600437, "Action", newJString(Action))
  add(query_600437, "Marker", newJString(Marker))
  add(query_600437, "ListenerArn", newJString(ListenerArn))
  add(query_600437, "Version", newJString(Version))
  result = call_600436.call(nil, query_600437, nil, nil, nil)

var getDescribeListenerCertificates* = Call_GetDescribeListenerCertificates_600420(
    name: "getDescribeListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_GetDescribeListenerCertificates_600421, base: "/",
    url: url_GetDescribeListenerCertificates_600422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListeners_600476 = ref object of OpenApiRestCall_599368
proc url_PostDescribeListeners_600478(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeListeners_600477(path: JsonNode; query: JsonNode;
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
  var valid_600479 = query.getOrDefault("Action")
  valid_600479 = validateParameter(valid_600479, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_600479 != nil:
    section.add "Action", valid_600479
  var valid_600480 = query.getOrDefault("Version")
  valid_600480 = validateParameter(valid_600480, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600480 != nil:
    section.add "Version", valid_600480
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
  var valid_600481 = header.getOrDefault("X-Amz-Date")
  valid_600481 = validateParameter(valid_600481, JString, required = false,
                                 default = nil)
  if valid_600481 != nil:
    section.add "X-Amz-Date", valid_600481
  var valid_600482 = header.getOrDefault("X-Amz-Security-Token")
  valid_600482 = validateParameter(valid_600482, JString, required = false,
                                 default = nil)
  if valid_600482 != nil:
    section.add "X-Amz-Security-Token", valid_600482
  var valid_600483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600483 = validateParameter(valid_600483, JString, required = false,
                                 default = nil)
  if valid_600483 != nil:
    section.add "X-Amz-Content-Sha256", valid_600483
  var valid_600484 = header.getOrDefault("X-Amz-Algorithm")
  valid_600484 = validateParameter(valid_600484, JString, required = false,
                                 default = nil)
  if valid_600484 != nil:
    section.add "X-Amz-Algorithm", valid_600484
  var valid_600485 = header.getOrDefault("X-Amz-Signature")
  valid_600485 = validateParameter(valid_600485, JString, required = false,
                                 default = nil)
  if valid_600485 != nil:
    section.add "X-Amz-Signature", valid_600485
  var valid_600486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600486 = validateParameter(valid_600486, JString, required = false,
                                 default = nil)
  if valid_600486 != nil:
    section.add "X-Amz-SignedHeaders", valid_600486
  var valid_600487 = header.getOrDefault("X-Amz-Credential")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Credential", valid_600487
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
  var valid_600488 = formData.getOrDefault("LoadBalancerArn")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "LoadBalancerArn", valid_600488
  var valid_600489 = formData.getOrDefault("Marker")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "Marker", valid_600489
  var valid_600490 = formData.getOrDefault("PageSize")
  valid_600490 = validateParameter(valid_600490, JInt, required = false, default = nil)
  if valid_600490 != nil:
    section.add "PageSize", valid_600490
  var valid_600491 = formData.getOrDefault("ListenerArns")
  valid_600491 = validateParameter(valid_600491, JArray, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "ListenerArns", valid_600491
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600492: Call_PostDescribeListeners_600476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_600492.validator(path, query, header, formData, body)
  let scheme = call_600492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600492.url(scheme.get, call_600492.host, call_600492.base,
                         call_600492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600492, url, valid)

proc call*(call_600493: Call_PostDescribeListeners_600476;
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
  var query_600494 = newJObject()
  var formData_600495 = newJObject()
  add(formData_600495, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_600495, "Marker", newJString(Marker))
  add(query_600494, "Action", newJString(Action))
  add(formData_600495, "PageSize", newJInt(PageSize))
  if ListenerArns != nil:
    formData_600495.add "ListenerArns", ListenerArns
  add(query_600494, "Version", newJString(Version))
  result = call_600493.call(nil, query_600494, nil, formData_600495, nil)

var postDescribeListeners* = Call_PostDescribeListeners_600476(
    name: "postDescribeListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners",
    validator: validate_PostDescribeListeners_600477, base: "/",
    url: url_PostDescribeListeners_600478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListeners_600457 = ref object of OpenApiRestCall_599368
proc url_GetDescribeListeners_600459(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeListeners_600458(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600460 = query.getOrDefault("ListenerArns")
  valid_600460 = validateParameter(valid_600460, JArray, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "ListenerArns", valid_600460
  var valid_600461 = query.getOrDefault("PageSize")
  valid_600461 = validateParameter(valid_600461, JInt, required = false, default = nil)
  if valid_600461 != nil:
    section.add "PageSize", valid_600461
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600462 = query.getOrDefault("Action")
  valid_600462 = validateParameter(valid_600462, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_600462 != nil:
    section.add "Action", valid_600462
  var valid_600463 = query.getOrDefault("Marker")
  valid_600463 = validateParameter(valid_600463, JString, required = false,
                                 default = nil)
  if valid_600463 != nil:
    section.add "Marker", valid_600463
  var valid_600464 = query.getOrDefault("LoadBalancerArn")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "LoadBalancerArn", valid_600464
  var valid_600465 = query.getOrDefault("Version")
  valid_600465 = validateParameter(valid_600465, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600465 != nil:
    section.add "Version", valid_600465
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
  var valid_600466 = header.getOrDefault("X-Amz-Date")
  valid_600466 = validateParameter(valid_600466, JString, required = false,
                                 default = nil)
  if valid_600466 != nil:
    section.add "X-Amz-Date", valid_600466
  var valid_600467 = header.getOrDefault("X-Amz-Security-Token")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "X-Amz-Security-Token", valid_600467
  var valid_600468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600468 = validateParameter(valid_600468, JString, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "X-Amz-Content-Sha256", valid_600468
  var valid_600469 = header.getOrDefault("X-Amz-Algorithm")
  valid_600469 = validateParameter(valid_600469, JString, required = false,
                                 default = nil)
  if valid_600469 != nil:
    section.add "X-Amz-Algorithm", valid_600469
  var valid_600470 = header.getOrDefault("X-Amz-Signature")
  valid_600470 = validateParameter(valid_600470, JString, required = false,
                                 default = nil)
  if valid_600470 != nil:
    section.add "X-Amz-Signature", valid_600470
  var valid_600471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600471 = validateParameter(valid_600471, JString, required = false,
                                 default = nil)
  if valid_600471 != nil:
    section.add "X-Amz-SignedHeaders", valid_600471
  var valid_600472 = header.getOrDefault("X-Amz-Credential")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "X-Amz-Credential", valid_600472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600473: Call_GetDescribeListeners_600457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_600473.validator(path, query, header, formData, body)
  let scheme = call_600473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600473.url(scheme.get, call_600473.host, call_600473.base,
                         call_600473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600473, url, valid)

proc call*(call_600474: Call_GetDescribeListeners_600457;
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
  var query_600475 = newJObject()
  if ListenerArns != nil:
    query_600475.add "ListenerArns", ListenerArns
  add(query_600475, "PageSize", newJInt(PageSize))
  add(query_600475, "Action", newJString(Action))
  add(query_600475, "Marker", newJString(Marker))
  add(query_600475, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_600475, "Version", newJString(Version))
  result = call_600474.call(nil, query_600475, nil, nil, nil)

var getDescribeListeners* = Call_GetDescribeListeners_600457(
    name: "getDescribeListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners", validator: validate_GetDescribeListeners_600458,
    base: "/", url: url_GetDescribeListeners_600459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_600512 = ref object of OpenApiRestCall_599368
proc url_PostDescribeLoadBalancerAttributes_600514(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancerAttributes_600513(path: JsonNode;
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
  var valid_600515 = query.getOrDefault("Action")
  valid_600515 = validateParameter(valid_600515, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_600515 != nil:
    section.add "Action", valid_600515
  var valid_600516 = query.getOrDefault("Version")
  valid_600516 = validateParameter(valid_600516, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600516 != nil:
    section.add "Version", valid_600516
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
  var valid_600517 = header.getOrDefault("X-Amz-Date")
  valid_600517 = validateParameter(valid_600517, JString, required = false,
                                 default = nil)
  if valid_600517 != nil:
    section.add "X-Amz-Date", valid_600517
  var valid_600518 = header.getOrDefault("X-Amz-Security-Token")
  valid_600518 = validateParameter(valid_600518, JString, required = false,
                                 default = nil)
  if valid_600518 != nil:
    section.add "X-Amz-Security-Token", valid_600518
  var valid_600519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = nil)
  if valid_600519 != nil:
    section.add "X-Amz-Content-Sha256", valid_600519
  var valid_600520 = header.getOrDefault("X-Amz-Algorithm")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-Algorithm", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Signature")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Signature", valid_600521
  var valid_600522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-SignedHeaders", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-Credential")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-Credential", valid_600523
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_600524 = formData.getOrDefault("LoadBalancerArn")
  valid_600524 = validateParameter(valid_600524, JString, required = true,
                                 default = nil)
  if valid_600524 != nil:
    section.add "LoadBalancerArn", valid_600524
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600525: Call_PostDescribeLoadBalancerAttributes_600512;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600525.validator(path, query, header, formData, body)
  let scheme = call_600525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600525.url(scheme.get, call_600525.host, call_600525.base,
                         call_600525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600525, url, valid)

proc call*(call_600526: Call_PostDescribeLoadBalancerAttributes_600512;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600527 = newJObject()
  var formData_600528 = newJObject()
  add(formData_600528, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_600527, "Action", newJString(Action))
  add(query_600527, "Version", newJString(Version))
  result = call_600526.call(nil, query_600527, nil, formData_600528, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_600512(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_600513, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_600514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_600496 = ref object of OpenApiRestCall_599368
proc url_GetDescribeLoadBalancerAttributes_600498(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancerAttributes_600497(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600499 = query.getOrDefault("Action")
  valid_600499 = validateParameter(valid_600499, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_600499 != nil:
    section.add "Action", valid_600499
  var valid_600500 = query.getOrDefault("LoadBalancerArn")
  valid_600500 = validateParameter(valid_600500, JString, required = true,
                                 default = nil)
  if valid_600500 != nil:
    section.add "LoadBalancerArn", valid_600500
  var valid_600501 = query.getOrDefault("Version")
  valid_600501 = validateParameter(valid_600501, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600501 != nil:
    section.add "Version", valid_600501
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
  var valid_600502 = header.getOrDefault("X-Amz-Date")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "X-Amz-Date", valid_600502
  var valid_600503 = header.getOrDefault("X-Amz-Security-Token")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-Security-Token", valid_600503
  var valid_600504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "X-Amz-Content-Sha256", valid_600504
  var valid_600505 = header.getOrDefault("X-Amz-Algorithm")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "X-Amz-Algorithm", valid_600505
  var valid_600506 = header.getOrDefault("X-Amz-Signature")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-Signature", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-SignedHeaders", valid_600507
  var valid_600508 = header.getOrDefault("X-Amz-Credential")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-Credential", valid_600508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600509: Call_GetDescribeLoadBalancerAttributes_600496;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600509.validator(path, query, header, formData, body)
  let scheme = call_600509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600509.url(scheme.get, call_600509.host, call_600509.base,
                         call_600509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600509, url, valid)

proc call*(call_600510: Call_GetDescribeLoadBalancerAttributes_600496;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_600511 = newJObject()
  add(query_600511, "Action", newJString(Action))
  add(query_600511, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_600511, "Version", newJString(Version))
  result = call_600510.call(nil, query_600511, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_600496(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_600497, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_600498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_600548 = ref object of OpenApiRestCall_599368
proc url_PostDescribeLoadBalancers_600550(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancers_600549(path: JsonNode; query: JsonNode;
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
  var valid_600551 = query.getOrDefault("Action")
  valid_600551 = validateParameter(valid_600551, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_600551 != nil:
    section.add "Action", valid_600551
  var valid_600552 = query.getOrDefault("Version")
  valid_600552 = validateParameter(valid_600552, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600552 != nil:
    section.add "Version", valid_600552
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
  var valid_600553 = header.getOrDefault("X-Amz-Date")
  valid_600553 = validateParameter(valid_600553, JString, required = false,
                                 default = nil)
  if valid_600553 != nil:
    section.add "X-Amz-Date", valid_600553
  var valid_600554 = header.getOrDefault("X-Amz-Security-Token")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-Security-Token", valid_600554
  var valid_600555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600555 = validateParameter(valid_600555, JString, required = false,
                                 default = nil)
  if valid_600555 != nil:
    section.add "X-Amz-Content-Sha256", valid_600555
  var valid_600556 = header.getOrDefault("X-Amz-Algorithm")
  valid_600556 = validateParameter(valid_600556, JString, required = false,
                                 default = nil)
  if valid_600556 != nil:
    section.add "X-Amz-Algorithm", valid_600556
  var valid_600557 = header.getOrDefault("X-Amz-Signature")
  valid_600557 = validateParameter(valid_600557, JString, required = false,
                                 default = nil)
  if valid_600557 != nil:
    section.add "X-Amz-Signature", valid_600557
  var valid_600558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-SignedHeaders", valid_600558
  var valid_600559 = header.getOrDefault("X-Amz-Credential")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-Credential", valid_600559
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
  var valid_600560 = formData.getOrDefault("Names")
  valid_600560 = validateParameter(valid_600560, JArray, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "Names", valid_600560
  var valid_600561 = formData.getOrDefault("Marker")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "Marker", valid_600561
  var valid_600562 = formData.getOrDefault("LoadBalancerArns")
  valid_600562 = validateParameter(valid_600562, JArray, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "LoadBalancerArns", valid_600562
  var valid_600563 = formData.getOrDefault("PageSize")
  valid_600563 = validateParameter(valid_600563, JInt, required = false, default = nil)
  if valid_600563 != nil:
    section.add "PageSize", valid_600563
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600564: Call_PostDescribeLoadBalancers_600548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_600564.validator(path, query, header, formData, body)
  let scheme = call_600564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600564.url(scheme.get, call_600564.host, call_600564.base,
                         call_600564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600564, url, valid)

proc call*(call_600565: Call_PostDescribeLoadBalancers_600548;
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
  var query_600566 = newJObject()
  var formData_600567 = newJObject()
  if Names != nil:
    formData_600567.add "Names", Names
  add(formData_600567, "Marker", newJString(Marker))
  add(query_600566, "Action", newJString(Action))
  if LoadBalancerArns != nil:
    formData_600567.add "LoadBalancerArns", LoadBalancerArns
  add(formData_600567, "PageSize", newJInt(PageSize))
  add(query_600566, "Version", newJString(Version))
  result = call_600565.call(nil, query_600566, nil, formData_600567, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_600548(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_600549, base: "/",
    url: url_PostDescribeLoadBalancers_600550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_600529 = ref object of OpenApiRestCall_599368
proc url_GetDescribeLoadBalancers_600531(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancers_600530(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600532 = query.getOrDefault("Names")
  valid_600532 = validateParameter(valid_600532, JArray, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "Names", valid_600532
  var valid_600533 = query.getOrDefault("PageSize")
  valid_600533 = validateParameter(valid_600533, JInt, required = false, default = nil)
  if valid_600533 != nil:
    section.add "PageSize", valid_600533
  var valid_600534 = query.getOrDefault("LoadBalancerArns")
  valid_600534 = validateParameter(valid_600534, JArray, required = false,
                                 default = nil)
  if valid_600534 != nil:
    section.add "LoadBalancerArns", valid_600534
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600535 = query.getOrDefault("Action")
  valid_600535 = validateParameter(valid_600535, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_600535 != nil:
    section.add "Action", valid_600535
  var valid_600536 = query.getOrDefault("Marker")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "Marker", valid_600536
  var valid_600537 = query.getOrDefault("Version")
  valid_600537 = validateParameter(valid_600537, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600537 != nil:
    section.add "Version", valid_600537
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
  var valid_600538 = header.getOrDefault("X-Amz-Date")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-Date", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-Security-Token")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-Security-Token", valid_600539
  var valid_600540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-Content-Sha256", valid_600540
  var valid_600541 = header.getOrDefault("X-Amz-Algorithm")
  valid_600541 = validateParameter(valid_600541, JString, required = false,
                                 default = nil)
  if valid_600541 != nil:
    section.add "X-Amz-Algorithm", valid_600541
  var valid_600542 = header.getOrDefault("X-Amz-Signature")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "X-Amz-Signature", valid_600542
  var valid_600543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "X-Amz-SignedHeaders", valid_600543
  var valid_600544 = header.getOrDefault("X-Amz-Credential")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "X-Amz-Credential", valid_600544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600545: Call_GetDescribeLoadBalancers_600529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_600545.validator(path, query, header, formData, body)
  let scheme = call_600545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600545.url(scheme.get, call_600545.host, call_600545.base,
                         call_600545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600545, url, valid)

proc call*(call_600546: Call_GetDescribeLoadBalancers_600529;
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
  var query_600547 = newJObject()
  if Names != nil:
    query_600547.add "Names", Names
  add(query_600547, "PageSize", newJInt(PageSize))
  if LoadBalancerArns != nil:
    query_600547.add "LoadBalancerArns", LoadBalancerArns
  add(query_600547, "Action", newJString(Action))
  add(query_600547, "Marker", newJString(Marker))
  add(query_600547, "Version", newJString(Version))
  result = call_600546.call(nil, query_600547, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_600529(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_600530, base: "/",
    url: url_GetDescribeLoadBalancers_600531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRules_600587 = ref object of OpenApiRestCall_599368
proc url_PostDescribeRules_600589(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeRules_600588(path: JsonNode; query: JsonNode;
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
  var valid_600590 = query.getOrDefault("Action")
  valid_600590 = validateParameter(valid_600590, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_600590 != nil:
    section.add "Action", valid_600590
  var valid_600591 = query.getOrDefault("Version")
  valid_600591 = validateParameter(valid_600591, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600591 != nil:
    section.add "Version", valid_600591
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
  var valid_600592 = header.getOrDefault("X-Amz-Date")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-Date", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-Security-Token")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Security-Token", valid_600593
  var valid_600594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600594 = validateParameter(valid_600594, JString, required = false,
                                 default = nil)
  if valid_600594 != nil:
    section.add "X-Amz-Content-Sha256", valid_600594
  var valid_600595 = header.getOrDefault("X-Amz-Algorithm")
  valid_600595 = validateParameter(valid_600595, JString, required = false,
                                 default = nil)
  if valid_600595 != nil:
    section.add "X-Amz-Algorithm", valid_600595
  var valid_600596 = header.getOrDefault("X-Amz-Signature")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "X-Amz-Signature", valid_600596
  var valid_600597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "X-Amz-SignedHeaders", valid_600597
  var valid_600598 = header.getOrDefault("X-Amz-Credential")
  valid_600598 = validateParameter(valid_600598, JString, required = false,
                                 default = nil)
  if valid_600598 != nil:
    section.add "X-Amz-Credential", valid_600598
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
  var valid_600599 = formData.getOrDefault("ListenerArn")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "ListenerArn", valid_600599
  var valid_600600 = formData.getOrDefault("RuleArns")
  valid_600600 = validateParameter(valid_600600, JArray, required = false,
                                 default = nil)
  if valid_600600 != nil:
    section.add "RuleArns", valid_600600
  var valid_600601 = formData.getOrDefault("Marker")
  valid_600601 = validateParameter(valid_600601, JString, required = false,
                                 default = nil)
  if valid_600601 != nil:
    section.add "Marker", valid_600601
  var valid_600602 = formData.getOrDefault("PageSize")
  valid_600602 = validateParameter(valid_600602, JInt, required = false, default = nil)
  if valid_600602 != nil:
    section.add "PageSize", valid_600602
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600603: Call_PostDescribeRules_600587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_600603.validator(path, query, header, formData, body)
  let scheme = call_600603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600603.url(scheme.get, call_600603.host, call_600603.base,
                         call_600603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600603, url, valid)

proc call*(call_600604: Call_PostDescribeRules_600587; ListenerArn: string = "";
          RuleArns: JsonNode = nil; Marker: string = "";
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
  var query_600605 = newJObject()
  var formData_600606 = newJObject()
  add(formData_600606, "ListenerArn", newJString(ListenerArn))
  if RuleArns != nil:
    formData_600606.add "RuleArns", RuleArns
  add(formData_600606, "Marker", newJString(Marker))
  add(query_600605, "Action", newJString(Action))
  add(formData_600606, "PageSize", newJInt(PageSize))
  add(query_600605, "Version", newJString(Version))
  result = call_600604.call(nil, query_600605, nil, formData_600606, nil)

var postDescribeRules* = Call_PostDescribeRules_600587(name: "postDescribeRules",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_PostDescribeRules_600588,
    base: "/", url: url_PostDescribeRules_600589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRules_600568 = ref object of OpenApiRestCall_599368
proc url_GetDescribeRules_600570(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeRules_600569(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_600571 = query.getOrDefault("PageSize")
  valid_600571 = validateParameter(valid_600571, JInt, required = false, default = nil)
  if valid_600571 != nil:
    section.add "PageSize", valid_600571
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600572 = query.getOrDefault("Action")
  valid_600572 = validateParameter(valid_600572, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_600572 != nil:
    section.add "Action", valid_600572
  var valid_600573 = query.getOrDefault("Marker")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "Marker", valid_600573
  var valid_600574 = query.getOrDefault("ListenerArn")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "ListenerArn", valid_600574
  var valid_600575 = query.getOrDefault("Version")
  valid_600575 = validateParameter(valid_600575, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600575 != nil:
    section.add "Version", valid_600575
  var valid_600576 = query.getOrDefault("RuleArns")
  valid_600576 = validateParameter(valid_600576, JArray, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "RuleArns", valid_600576
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
  var valid_600577 = header.getOrDefault("X-Amz-Date")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "X-Amz-Date", valid_600577
  var valid_600578 = header.getOrDefault("X-Amz-Security-Token")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-Security-Token", valid_600578
  var valid_600579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600579 = validateParameter(valid_600579, JString, required = false,
                                 default = nil)
  if valid_600579 != nil:
    section.add "X-Amz-Content-Sha256", valid_600579
  var valid_600580 = header.getOrDefault("X-Amz-Algorithm")
  valid_600580 = validateParameter(valid_600580, JString, required = false,
                                 default = nil)
  if valid_600580 != nil:
    section.add "X-Amz-Algorithm", valid_600580
  var valid_600581 = header.getOrDefault("X-Amz-Signature")
  valid_600581 = validateParameter(valid_600581, JString, required = false,
                                 default = nil)
  if valid_600581 != nil:
    section.add "X-Amz-Signature", valid_600581
  var valid_600582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600582 = validateParameter(valid_600582, JString, required = false,
                                 default = nil)
  if valid_600582 != nil:
    section.add "X-Amz-SignedHeaders", valid_600582
  var valid_600583 = header.getOrDefault("X-Amz-Credential")
  valid_600583 = validateParameter(valid_600583, JString, required = false,
                                 default = nil)
  if valid_600583 != nil:
    section.add "X-Amz-Credential", valid_600583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600584: Call_GetDescribeRules_600568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_600584.validator(path, query, header, formData, body)
  let scheme = call_600584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600584.url(scheme.get, call_600584.host, call_600584.base,
                         call_600584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600584, url, valid)

proc call*(call_600585: Call_GetDescribeRules_600568; PageSize: int = 0;
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
  var query_600586 = newJObject()
  add(query_600586, "PageSize", newJInt(PageSize))
  add(query_600586, "Action", newJString(Action))
  add(query_600586, "Marker", newJString(Marker))
  add(query_600586, "ListenerArn", newJString(ListenerArn))
  add(query_600586, "Version", newJString(Version))
  if RuleArns != nil:
    query_600586.add "RuleArns", RuleArns
  result = call_600585.call(nil, query_600586, nil, nil, nil)

var getDescribeRules* = Call_GetDescribeRules_600568(name: "getDescribeRules",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_GetDescribeRules_600569,
    base: "/", url: url_GetDescribeRules_600570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSSLPolicies_600625 = ref object of OpenApiRestCall_599368
proc url_PostDescribeSSLPolicies_600627(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeSSLPolicies_600626(path: JsonNode; query: JsonNode;
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
  var valid_600628 = query.getOrDefault("Action")
  valid_600628 = validateParameter(valid_600628, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_600628 != nil:
    section.add "Action", valid_600628
  var valid_600629 = query.getOrDefault("Version")
  valid_600629 = validateParameter(valid_600629, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600629 != nil:
    section.add "Version", valid_600629
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
  var valid_600630 = header.getOrDefault("X-Amz-Date")
  valid_600630 = validateParameter(valid_600630, JString, required = false,
                                 default = nil)
  if valid_600630 != nil:
    section.add "X-Amz-Date", valid_600630
  var valid_600631 = header.getOrDefault("X-Amz-Security-Token")
  valid_600631 = validateParameter(valid_600631, JString, required = false,
                                 default = nil)
  if valid_600631 != nil:
    section.add "X-Amz-Security-Token", valid_600631
  var valid_600632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600632 = validateParameter(valid_600632, JString, required = false,
                                 default = nil)
  if valid_600632 != nil:
    section.add "X-Amz-Content-Sha256", valid_600632
  var valid_600633 = header.getOrDefault("X-Amz-Algorithm")
  valid_600633 = validateParameter(valid_600633, JString, required = false,
                                 default = nil)
  if valid_600633 != nil:
    section.add "X-Amz-Algorithm", valid_600633
  var valid_600634 = header.getOrDefault("X-Amz-Signature")
  valid_600634 = validateParameter(valid_600634, JString, required = false,
                                 default = nil)
  if valid_600634 != nil:
    section.add "X-Amz-Signature", valid_600634
  var valid_600635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "X-Amz-SignedHeaders", valid_600635
  var valid_600636 = header.getOrDefault("X-Amz-Credential")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "X-Amz-Credential", valid_600636
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the policies.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_600637 = formData.getOrDefault("Names")
  valid_600637 = validateParameter(valid_600637, JArray, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "Names", valid_600637
  var valid_600638 = formData.getOrDefault("Marker")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "Marker", valid_600638
  var valid_600639 = formData.getOrDefault("PageSize")
  valid_600639 = validateParameter(valid_600639, JInt, required = false, default = nil)
  if valid_600639 != nil:
    section.add "PageSize", valid_600639
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600640: Call_PostDescribeSSLPolicies_600625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600640.validator(path, query, header, formData, body)
  let scheme = call_600640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600640.url(scheme.get, call_600640.host, call_600640.base,
                         call_600640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600640, url, valid)

proc call*(call_600641: Call_PostDescribeSSLPolicies_600625; Names: JsonNode = nil;
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
  var query_600642 = newJObject()
  var formData_600643 = newJObject()
  if Names != nil:
    formData_600643.add "Names", Names
  add(formData_600643, "Marker", newJString(Marker))
  add(query_600642, "Action", newJString(Action))
  add(formData_600643, "PageSize", newJInt(PageSize))
  add(query_600642, "Version", newJString(Version))
  result = call_600641.call(nil, query_600642, nil, formData_600643, nil)

var postDescribeSSLPolicies* = Call_PostDescribeSSLPolicies_600625(
    name: "postDescribeSSLPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_PostDescribeSSLPolicies_600626, base: "/",
    url: url_PostDescribeSSLPolicies_600627, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSSLPolicies_600607 = ref object of OpenApiRestCall_599368
proc url_GetDescribeSSLPolicies_600609(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeSSLPolicies_600608(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600610 = query.getOrDefault("Names")
  valid_600610 = validateParameter(valid_600610, JArray, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "Names", valid_600610
  var valid_600611 = query.getOrDefault("PageSize")
  valid_600611 = validateParameter(valid_600611, JInt, required = false, default = nil)
  if valid_600611 != nil:
    section.add "PageSize", valid_600611
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600612 = query.getOrDefault("Action")
  valid_600612 = validateParameter(valid_600612, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_600612 != nil:
    section.add "Action", valid_600612
  var valid_600613 = query.getOrDefault("Marker")
  valid_600613 = validateParameter(valid_600613, JString, required = false,
                                 default = nil)
  if valid_600613 != nil:
    section.add "Marker", valid_600613
  var valid_600614 = query.getOrDefault("Version")
  valid_600614 = validateParameter(valid_600614, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600614 != nil:
    section.add "Version", valid_600614
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
  var valid_600615 = header.getOrDefault("X-Amz-Date")
  valid_600615 = validateParameter(valid_600615, JString, required = false,
                                 default = nil)
  if valid_600615 != nil:
    section.add "X-Amz-Date", valid_600615
  var valid_600616 = header.getOrDefault("X-Amz-Security-Token")
  valid_600616 = validateParameter(valid_600616, JString, required = false,
                                 default = nil)
  if valid_600616 != nil:
    section.add "X-Amz-Security-Token", valid_600616
  var valid_600617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600617 = validateParameter(valid_600617, JString, required = false,
                                 default = nil)
  if valid_600617 != nil:
    section.add "X-Amz-Content-Sha256", valid_600617
  var valid_600618 = header.getOrDefault("X-Amz-Algorithm")
  valid_600618 = validateParameter(valid_600618, JString, required = false,
                                 default = nil)
  if valid_600618 != nil:
    section.add "X-Amz-Algorithm", valid_600618
  var valid_600619 = header.getOrDefault("X-Amz-Signature")
  valid_600619 = validateParameter(valid_600619, JString, required = false,
                                 default = nil)
  if valid_600619 != nil:
    section.add "X-Amz-Signature", valid_600619
  var valid_600620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600620 = validateParameter(valid_600620, JString, required = false,
                                 default = nil)
  if valid_600620 != nil:
    section.add "X-Amz-SignedHeaders", valid_600620
  var valid_600621 = header.getOrDefault("X-Amz-Credential")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Credential", valid_600621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600622: Call_GetDescribeSSLPolicies_600607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600622.validator(path, query, header, formData, body)
  let scheme = call_600622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600622.url(scheme.get, call_600622.host, call_600622.base,
                         call_600622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600622, url, valid)

proc call*(call_600623: Call_GetDescribeSSLPolicies_600607; Names: JsonNode = nil;
          PageSize: int = 0; Action: string = "DescribeSSLPolicies";
          Marker: string = ""; Version: string = "2015-12-01"): Recallable =
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
  var query_600624 = newJObject()
  if Names != nil:
    query_600624.add "Names", Names
  add(query_600624, "PageSize", newJInt(PageSize))
  add(query_600624, "Action", newJString(Action))
  add(query_600624, "Marker", newJString(Marker))
  add(query_600624, "Version", newJString(Version))
  result = call_600623.call(nil, query_600624, nil, nil, nil)

var getDescribeSSLPolicies* = Call_GetDescribeSSLPolicies_600607(
    name: "getDescribeSSLPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_GetDescribeSSLPolicies_600608, base: "/",
    url: url_GetDescribeSSLPolicies_600609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_600660 = ref object of OpenApiRestCall_599368
proc url_PostDescribeTags_600662(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTags_600661(path: JsonNode; query: JsonNode;
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
  var valid_600663 = query.getOrDefault("Action")
  valid_600663 = validateParameter(valid_600663, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_600663 != nil:
    section.add "Action", valid_600663
  var valid_600664 = query.getOrDefault("Version")
  valid_600664 = validateParameter(valid_600664, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600664 != nil:
    section.add "Version", valid_600664
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
  var valid_600665 = header.getOrDefault("X-Amz-Date")
  valid_600665 = validateParameter(valid_600665, JString, required = false,
                                 default = nil)
  if valid_600665 != nil:
    section.add "X-Amz-Date", valid_600665
  var valid_600666 = header.getOrDefault("X-Amz-Security-Token")
  valid_600666 = validateParameter(valid_600666, JString, required = false,
                                 default = nil)
  if valid_600666 != nil:
    section.add "X-Amz-Security-Token", valid_600666
  var valid_600667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "X-Amz-Content-Sha256", valid_600667
  var valid_600668 = header.getOrDefault("X-Amz-Algorithm")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Algorithm", valid_600668
  var valid_600669 = header.getOrDefault("X-Amz-Signature")
  valid_600669 = validateParameter(valid_600669, JString, required = false,
                                 default = nil)
  if valid_600669 != nil:
    section.add "X-Amz-Signature", valid_600669
  var valid_600670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600670 = validateParameter(valid_600670, JString, required = false,
                                 default = nil)
  if valid_600670 != nil:
    section.add "X-Amz-SignedHeaders", valid_600670
  var valid_600671 = header.getOrDefault("X-Amz-Credential")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "X-Amz-Credential", valid_600671
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_600672 = formData.getOrDefault("ResourceArns")
  valid_600672 = validateParameter(valid_600672, JArray, required = true, default = nil)
  if valid_600672 != nil:
    section.add "ResourceArns", valid_600672
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600673: Call_PostDescribeTags_600660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_600673.validator(path, query, header, formData, body)
  let scheme = call_600673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600673.url(scheme.get, call_600673.host, call_600673.base,
                         call_600673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600673, url, valid)

proc call*(call_600674: Call_PostDescribeTags_600660; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600675 = newJObject()
  var formData_600676 = newJObject()
  if ResourceArns != nil:
    formData_600676.add "ResourceArns", ResourceArns
  add(query_600675, "Action", newJString(Action))
  add(query_600675, "Version", newJString(Version))
  result = call_600674.call(nil, query_600675, nil, formData_600676, nil)

var postDescribeTags* = Call_PostDescribeTags_600660(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_600661,
    base: "/", url: url_PostDescribeTags_600662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_600644 = ref object of OpenApiRestCall_599368
proc url_GetDescribeTags_600646(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTags_600645(path: JsonNode; query: JsonNode;
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
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600647 = query.getOrDefault("Action")
  valid_600647 = validateParameter(valid_600647, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_600647 != nil:
    section.add "Action", valid_600647
  var valid_600648 = query.getOrDefault("ResourceArns")
  valid_600648 = validateParameter(valid_600648, JArray, required = true, default = nil)
  if valid_600648 != nil:
    section.add "ResourceArns", valid_600648
  var valid_600649 = query.getOrDefault("Version")
  valid_600649 = validateParameter(valid_600649, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600649 != nil:
    section.add "Version", valid_600649
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
  var valid_600650 = header.getOrDefault("X-Amz-Date")
  valid_600650 = validateParameter(valid_600650, JString, required = false,
                                 default = nil)
  if valid_600650 != nil:
    section.add "X-Amz-Date", valid_600650
  var valid_600651 = header.getOrDefault("X-Amz-Security-Token")
  valid_600651 = validateParameter(valid_600651, JString, required = false,
                                 default = nil)
  if valid_600651 != nil:
    section.add "X-Amz-Security-Token", valid_600651
  var valid_600652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600652 = validateParameter(valid_600652, JString, required = false,
                                 default = nil)
  if valid_600652 != nil:
    section.add "X-Amz-Content-Sha256", valid_600652
  var valid_600653 = header.getOrDefault("X-Amz-Algorithm")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Algorithm", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-Signature")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-Signature", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-SignedHeaders", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-Credential")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-Credential", valid_600656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600657: Call_GetDescribeTags_600644; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_600657.validator(path, query, header, formData, body)
  let scheme = call_600657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600657.url(scheme.get, call_600657.host, call_600657.base,
                         call_600657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600657, url, valid)

proc call*(call_600658: Call_GetDescribeTags_600644; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   Action: string (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Version: string (required)
  var query_600659 = newJObject()
  add(query_600659, "Action", newJString(Action))
  if ResourceArns != nil:
    query_600659.add "ResourceArns", ResourceArns
  add(query_600659, "Version", newJString(Version))
  result = call_600658.call(nil, query_600659, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_600644(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_600645,
    base: "/", url: url_GetDescribeTags_600646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroupAttributes_600693 = ref object of OpenApiRestCall_599368
proc url_PostDescribeTargetGroupAttributes_600695(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTargetGroupAttributes_600694(path: JsonNode;
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
  var valid_600696 = query.getOrDefault("Action")
  valid_600696 = validateParameter(valid_600696, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_600696 != nil:
    section.add "Action", valid_600696
  var valid_600697 = query.getOrDefault("Version")
  valid_600697 = validateParameter(valid_600697, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600697 != nil:
    section.add "Version", valid_600697
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
  var valid_600698 = header.getOrDefault("X-Amz-Date")
  valid_600698 = validateParameter(valid_600698, JString, required = false,
                                 default = nil)
  if valid_600698 != nil:
    section.add "X-Amz-Date", valid_600698
  var valid_600699 = header.getOrDefault("X-Amz-Security-Token")
  valid_600699 = validateParameter(valid_600699, JString, required = false,
                                 default = nil)
  if valid_600699 != nil:
    section.add "X-Amz-Security-Token", valid_600699
  var valid_600700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600700 = validateParameter(valid_600700, JString, required = false,
                                 default = nil)
  if valid_600700 != nil:
    section.add "X-Amz-Content-Sha256", valid_600700
  var valid_600701 = header.getOrDefault("X-Amz-Algorithm")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "X-Amz-Algorithm", valid_600701
  var valid_600702 = header.getOrDefault("X-Amz-Signature")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-Signature", valid_600702
  var valid_600703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "X-Amz-SignedHeaders", valid_600703
  var valid_600704 = header.getOrDefault("X-Amz-Credential")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "X-Amz-Credential", valid_600704
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_600705 = formData.getOrDefault("TargetGroupArn")
  valid_600705 = validateParameter(valid_600705, JString, required = true,
                                 default = nil)
  if valid_600705 != nil:
    section.add "TargetGroupArn", valid_600705
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600706: Call_PostDescribeTargetGroupAttributes_600693;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600706.validator(path, query, header, formData, body)
  let scheme = call_600706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600706.url(scheme.get, call_600706.host, call_600706.base,
                         call_600706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600706, url, valid)

proc call*(call_600707: Call_PostDescribeTargetGroupAttributes_600693;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_600708 = newJObject()
  var formData_600709 = newJObject()
  add(query_600708, "Action", newJString(Action))
  add(formData_600709, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_600708, "Version", newJString(Version))
  result = call_600707.call(nil, query_600708, nil, formData_600709, nil)

var postDescribeTargetGroupAttributes* = Call_PostDescribeTargetGroupAttributes_600693(
    name: "postDescribeTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_PostDescribeTargetGroupAttributes_600694, base: "/",
    url: url_PostDescribeTargetGroupAttributes_600695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroupAttributes_600677 = ref object of OpenApiRestCall_599368
proc url_GetDescribeTargetGroupAttributes_600679(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTargetGroupAttributes_600678(path: JsonNode;
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
  var valid_600680 = query.getOrDefault("TargetGroupArn")
  valid_600680 = validateParameter(valid_600680, JString, required = true,
                                 default = nil)
  if valid_600680 != nil:
    section.add "TargetGroupArn", valid_600680
  var valid_600681 = query.getOrDefault("Action")
  valid_600681 = validateParameter(valid_600681, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_600681 != nil:
    section.add "Action", valid_600681
  var valid_600682 = query.getOrDefault("Version")
  valid_600682 = validateParameter(valid_600682, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600682 != nil:
    section.add "Version", valid_600682
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
  var valid_600683 = header.getOrDefault("X-Amz-Date")
  valid_600683 = validateParameter(valid_600683, JString, required = false,
                                 default = nil)
  if valid_600683 != nil:
    section.add "X-Amz-Date", valid_600683
  var valid_600684 = header.getOrDefault("X-Amz-Security-Token")
  valid_600684 = validateParameter(valid_600684, JString, required = false,
                                 default = nil)
  if valid_600684 != nil:
    section.add "X-Amz-Security-Token", valid_600684
  var valid_600685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "X-Amz-Content-Sha256", valid_600685
  var valid_600686 = header.getOrDefault("X-Amz-Algorithm")
  valid_600686 = validateParameter(valid_600686, JString, required = false,
                                 default = nil)
  if valid_600686 != nil:
    section.add "X-Amz-Algorithm", valid_600686
  var valid_600687 = header.getOrDefault("X-Amz-Signature")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-Signature", valid_600687
  var valid_600688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "X-Amz-SignedHeaders", valid_600688
  var valid_600689 = header.getOrDefault("X-Amz-Credential")
  valid_600689 = validateParameter(valid_600689, JString, required = false,
                                 default = nil)
  if valid_600689 != nil:
    section.add "X-Amz-Credential", valid_600689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600690: Call_GetDescribeTargetGroupAttributes_600677;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600690.validator(path, query, header, formData, body)
  let scheme = call_600690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600690.url(scheme.get, call_600690.host, call_600690.base,
                         call_600690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600690, url, valid)

proc call*(call_600691: Call_GetDescribeTargetGroupAttributes_600677;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600692 = newJObject()
  add(query_600692, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_600692, "Action", newJString(Action))
  add(query_600692, "Version", newJString(Version))
  result = call_600691.call(nil, query_600692, nil, nil, nil)

var getDescribeTargetGroupAttributes* = Call_GetDescribeTargetGroupAttributes_600677(
    name: "getDescribeTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_GetDescribeTargetGroupAttributes_600678, base: "/",
    url: url_GetDescribeTargetGroupAttributes_600679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroups_600730 = ref object of OpenApiRestCall_599368
proc url_PostDescribeTargetGroups_600732(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTargetGroups_600731(path: JsonNode; query: JsonNode;
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
  var valid_600733 = query.getOrDefault("Action")
  valid_600733 = validateParameter(valid_600733, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_600733 != nil:
    section.add "Action", valid_600733
  var valid_600734 = query.getOrDefault("Version")
  valid_600734 = validateParameter(valid_600734, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600734 != nil:
    section.add "Version", valid_600734
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
  var valid_600735 = header.getOrDefault("X-Amz-Date")
  valid_600735 = validateParameter(valid_600735, JString, required = false,
                                 default = nil)
  if valid_600735 != nil:
    section.add "X-Amz-Date", valid_600735
  var valid_600736 = header.getOrDefault("X-Amz-Security-Token")
  valid_600736 = validateParameter(valid_600736, JString, required = false,
                                 default = nil)
  if valid_600736 != nil:
    section.add "X-Amz-Security-Token", valid_600736
  var valid_600737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-Content-Sha256", valid_600737
  var valid_600738 = header.getOrDefault("X-Amz-Algorithm")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-Algorithm", valid_600738
  var valid_600739 = header.getOrDefault("X-Amz-Signature")
  valid_600739 = validateParameter(valid_600739, JString, required = false,
                                 default = nil)
  if valid_600739 != nil:
    section.add "X-Amz-Signature", valid_600739
  var valid_600740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600740 = validateParameter(valid_600740, JString, required = false,
                                 default = nil)
  if valid_600740 != nil:
    section.add "X-Amz-SignedHeaders", valid_600740
  var valid_600741 = header.getOrDefault("X-Amz-Credential")
  valid_600741 = validateParameter(valid_600741, JString, required = false,
                                 default = nil)
  if valid_600741 != nil:
    section.add "X-Amz-Credential", valid_600741
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
  var valid_600742 = formData.getOrDefault("LoadBalancerArn")
  valid_600742 = validateParameter(valid_600742, JString, required = false,
                                 default = nil)
  if valid_600742 != nil:
    section.add "LoadBalancerArn", valid_600742
  var valid_600743 = formData.getOrDefault("TargetGroupArns")
  valid_600743 = validateParameter(valid_600743, JArray, required = false,
                                 default = nil)
  if valid_600743 != nil:
    section.add "TargetGroupArns", valid_600743
  var valid_600744 = formData.getOrDefault("Names")
  valid_600744 = validateParameter(valid_600744, JArray, required = false,
                                 default = nil)
  if valid_600744 != nil:
    section.add "Names", valid_600744
  var valid_600745 = formData.getOrDefault("Marker")
  valid_600745 = validateParameter(valid_600745, JString, required = false,
                                 default = nil)
  if valid_600745 != nil:
    section.add "Marker", valid_600745
  var valid_600746 = formData.getOrDefault("PageSize")
  valid_600746 = validateParameter(valid_600746, JInt, required = false, default = nil)
  if valid_600746 != nil:
    section.add "PageSize", valid_600746
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600747: Call_PostDescribeTargetGroups_600730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_600747.validator(path, query, header, formData, body)
  let scheme = call_600747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600747.url(scheme.get, call_600747.host, call_600747.base,
                         call_600747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600747, url, valid)

proc call*(call_600748: Call_PostDescribeTargetGroups_600730;
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
  var query_600749 = newJObject()
  var formData_600750 = newJObject()
  add(formData_600750, "LoadBalancerArn", newJString(LoadBalancerArn))
  if TargetGroupArns != nil:
    formData_600750.add "TargetGroupArns", TargetGroupArns
  if Names != nil:
    formData_600750.add "Names", Names
  add(formData_600750, "Marker", newJString(Marker))
  add(query_600749, "Action", newJString(Action))
  add(formData_600750, "PageSize", newJInt(PageSize))
  add(query_600749, "Version", newJString(Version))
  result = call_600748.call(nil, query_600749, nil, formData_600750, nil)

var postDescribeTargetGroups* = Call_PostDescribeTargetGroups_600730(
    name: "postDescribeTargetGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_PostDescribeTargetGroups_600731, base: "/",
    url: url_PostDescribeTargetGroups_600732, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroups_600710 = ref object of OpenApiRestCall_599368
proc url_GetDescribeTargetGroups_600712(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTargetGroups_600711(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600713 = query.getOrDefault("Names")
  valid_600713 = validateParameter(valid_600713, JArray, required = false,
                                 default = nil)
  if valid_600713 != nil:
    section.add "Names", valid_600713
  var valid_600714 = query.getOrDefault("PageSize")
  valid_600714 = validateParameter(valid_600714, JInt, required = false, default = nil)
  if valid_600714 != nil:
    section.add "PageSize", valid_600714
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600715 = query.getOrDefault("Action")
  valid_600715 = validateParameter(valid_600715, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_600715 != nil:
    section.add "Action", valid_600715
  var valid_600716 = query.getOrDefault("Marker")
  valid_600716 = validateParameter(valid_600716, JString, required = false,
                                 default = nil)
  if valid_600716 != nil:
    section.add "Marker", valid_600716
  var valid_600717 = query.getOrDefault("LoadBalancerArn")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = nil)
  if valid_600717 != nil:
    section.add "LoadBalancerArn", valid_600717
  var valid_600718 = query.getOrDefault("TargetGroupArns")
  valid_600718 = validateParameter(valid_600718, JArray, required = false,
                                 default = nil)
  if valid_600718 != nil:
    section.add "TargetGroupArns", valid_600718
  var valid_600719 = query.getOrDefault("Version")
  valid_600719 = validateParameter(valid_600719, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600719 != nil:
    section.add "Version", valid_600719
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
  var valid_600720 = header.getOrDefault("X-Amz-Date")
  valid_600720 = validateParameter(valid_600720, JString, required = false,
                                 default = nil)
  if valid_600720 != nil:
    section.add "X-Amz-Date", valid_600720
  var valid_600721 = header.getOrDefault("X-Amz-Security-Token")
  valid_600721 = validateParameter(valid_600721, JString, required = false,
                                 default = nil)
  if valid_600721 != nil:
    section.add "X-Amz-Security-Token", valid_600721
  var valid_600722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600722 = validateParameter(valid_600722, JString, required = false,
                                 default = nil)
  if valid_600722 != nil:
    section.add "X-Amz-Content-Sha256", valid_600722
  var valid_600723 = header.getOrDefault("X-Amz-Algorithm")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "X-Amz-Algorithm", valid_600723
  var valid_600724 = header.getOrDefault("X-Amz-Signature")
  valid_600724 = validateParameter(valid_600724, JString, required = false,
                                 default = nil)
  if valid_600724 != nil:
    section.add "X-Amz-Signature", valid_600724
  var valid_600725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600725 = validateParameter(valid_600725, JString, required = false,
                                 default = nil)
  if valid_600725 != nil:
    section.add "X-Amz-SignedHeaders", valid_600725
  var valid_600726 = header.getOrDefault("X-Amz-Credential")
  valid_600726 = validateParameter(valid_600726, JString, required = false,
                                 default = nil)
  if valid_600726 != nil:
    section.add "X-Amz-Credential", valid_600726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600727: Call_GetDescribeTargetGroups_600710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_600727.validator(path, query, header, formData, body)
  let scheme = call_600727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600727.url(scheme.get, call_600727.host, call_600727.base,
                         call_600727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600727, url, valid)

proc call*(call_600728: Call_GetDescribeTargetGroups_600710; Names: JsonNode = nil;
          PageSize: int = 0; Action: string = "DescribeTargetGroups";
          Marker: string = ""; LoadBalancerArn: string = "";
          TargetGroupArns: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
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
  var query_600729 = newJObject()
  if Names != nil:
    query_600729.add "Names", Names
  add(query_600729, "PageSize", newJInt(PageSize))
  add(query_600729, "Action", newJString(Action))
  add(query_600729, "Marker", newJString(Marker))
  add(query_600729, "LoadBalancerArn", newJString(LoadBalancerArn))
  if TargetGroupArns != nil:
    query_600729.add "TargetGroupArns", TargetGroupArns
  add(query_600729, "Version", newJString(Version))
  result = call_600728.call(nil, query_600729, nil, nil, nil)

var getDescribeTargetGroups* = Call_GetDescribeTargetGroups_600710(
    name: "getDescribeTargetGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_GetDescribeTargetGroups_600711, base: "/",
    url: url_GetDescribeTargetGroups_600712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetHealth_600768 = ref object of OpenApiRestCall_599368
proc url_PostDescribeTargetHealth_600770(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTargetHealth_600769(path: JsonNode; query: JsonNode;
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
  var valid_600771 = query.getOrDefault("Action")
  valid_600771 = validateParameter(valid_600771, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_600771 != nil:
    section.add "Action", valid_600771
  var valid_600772 = query.getOrDefault("Version")
  valid_600772 = validateParameter(valid_600772, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600772 != nil:
    section.add "Version", valid_600772
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
  var valid_600773 = header.getOrDefault("X-Amz-Date")
  valid_600773 = validateParameter(valid_600773, JString, required = false,
                                 default = nil)
  if valid_600773 != nil:
    section.add "X-Amz-Date", valid_600773
  var valid_600774 = header.getOrDefault("X-Amz-Security-Token")
  valid_600774 = validateParameter(valid_600774, JString, required = false,
                                 default = nil)
  if valid_600774 != nil:
    section.add "X-Amz-Security-Token", valid_600774
  var valid_600775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600775 = validateParameter(valid_600775, JString, required = false,
                                 default = nil)
  if valid_600775 != nil:
    section.add "X-Amz-Content-Sha256", valid_600775
  var valid_600776 = header.getOrDefault("X-Amz-Algorithm")
  valid_600776 = validateParameter(valid_600776, JString, required = false,
                                 default = nil)
  if valid_600776 != nil:
    section.add "X-Amz-Algorithm", valid_600776
  var valid_600777 = header.getOrDefault("X-Amz-Signature")
  valid_600777 = validateParameter(valid_600777, JString, required = false,
                                 default = nil)
  if valid_600777 != nil:
    section.add "X-Amz-Signature", valid_600777
  var valid_600778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600778 = validateParameter(valid_600778, JString, required = false,
                                 default = nil)
  if valid_600778 != nil:
    section.add "X-Amz-SignedHeaders", valid_600778
  var valid_600779 = header.getOrDefault("X-Amz-Credential")
  valid_600779 = validateParameter(valid_600779, JString, required = false,
                                 default = nil)
  if valid_600779 != nil:
    section.add "X-Amz-Credential", valid_600779
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_600780 = formData.getOrDefault("Targets")
  valid_600780 = validateParameter(valid_600780, JArray, required = false,
                                 default = nil)
  if valid_600780 != nil:
    section.add "Targets", valid_600780
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_600781 = formData.getOrDefault("TargetGroupArn")
  valid_600781 = validateParameter(valid_600781, JString, required = true,
                                 default = nil)
  if valid_600781 != nil:
    section.add "TargetGroupArn", valid_600781
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600782: Call_PostDescribeTargetHealth_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_600782.validator(path, query, header, formData, body)
  let scheme = call_600782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600782.url(scheme.get, call_600782.host, call_600782.base,
                         call_600782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600782, url, valid)

proc call*(call_600783: Call_PostDescribeTargetHealth_600768;
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
  var query_600784 = newJObject()
  var formData_600785 = newJObject()
  if Targets != nil:
    formData_600785.add "Targets", Targets
  add(query_600784, "Action", newJString(Action))
  add(formData_600785, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_600784, "Version", newJString(Version))
  result = call_600783.call(nil, query_600784, nil, formData_600785, nil)

var postDescribeTargetHealth* = Call_PostDescribeTargetHealth_600768(
    name: "postDescribeTargetHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_PostDescribeTargetHealth_600769, base: "/",
    url: url_PostDescribeTargetHealth_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetHealth_600751 = ref object of OpenApiRestCall_599368
proc url_GetDescribeTargetHealth_600753(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTargetHealth_600752(path: JsonNode; query: JsonNode;
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
  var valid_600754 = query.getOrDefault("Targets")
  valid_600754 = validateParameter(valid_600754, JArray, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "Targets", valid_600754
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_600755 = query.getOrDefault("TargetGroupArn")
  valid_600755 = validateParameter(valid_600755, JString, required = true,
                                 default = nil)
  if valid_600755 != nil:
    section.add "TargetGroupArn", valid_600755
  var valid_600756 = query.getOrDefault("Action")
  valid_600756 = validateParameter(valid_600756, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_600756 != nil:
    section.add "Action", valid_600756
  var valid_600757 = query.getOrDefault("Version")
  valid_600757 = validateParameter(valid_600757, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600757 != nil:
    section.add "Version", valid_600757
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
  var valid_600758 = header.getOrDefault("X-Amz-Date")
  valid_600758 = validateParameter(valid_600758, JString, required = false,
                                 default = nil)
  if valid_600758 != nil:
    section.add "X-Amz-Date", valid_600758
  var valid_600759 = header.getOrDefault("X-Amz-Security-Token")
  valid_600759 = validateParameter(valid_600759, JString, required = false,
                                 default = nil)
  if valid_600759 != nil:
    section.add "X-Amz-Security-Token", valid_600759
  var valid_600760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600760 = validateParameter(valid_600760, JString, required = false,
                                 default = nil)
  if valid_600760 != nil:
    section.add "X-Amz-Content-Sha256", valid_600760
  var valid_600761 = header.getOrDefault("X-Amz-Algorithm")
  valid_600761 = validateParameter(valid_600761, JString, required = false,
                                 default = nil)
  if valid_600761 != nil:
    section.add "X-Amz-Algorithm", valid_600761
  var valid_600762 = header.getOrDefault("X-Amz-Signature")
  valid_600762 = validateParameter(valid_600762, JString, required = false,
                                 default = nil)
  if valid_600762 != nil:
    section.add "X-Amz-Signature", valid_600762
  var valid_600763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600763 = validateParameter(valid_600763, JString, required = false,
                                 default = nil)
  if valid_600763 != nil:
    section.add "X-Amz-SignedHeaders", valid_600763
  var valid_600764 = header.getOrDefault("X-Amz-Credential")
  valid_600764 = validateParameter(valid_600764, JString, required = false,
                                 default = nil)
  if valid_600764 != nil:
    section.add "X-Amz-Credential", valid_600764
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600765: Call_GetDescribeTargetHealth_600751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_600765.validator(path, query, header, formData, body)
  let scheme = call_600765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600765.url(scheme.get, call_600765.host, call_600765.base,
                         call_600765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600765, url, valid)

proc call*(call_600766: Call_GetDescribeTargetHealth_600751;
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
  var query_600767 = newJObject()
  if Targets != nil:
    query_600767.add "Targets", Targets
  add(query_600767, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_600767, "Action", newJString(Action))
  add(query_600767, "Version", newJString(Version))
  result = call_600766.call(nil, query_600767, nil, nil, nil)

var getDescribeTargetHealth* = Call_GetDescribeTargetHealth_600751(
    name: "getDescribeTargetHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_GetDescribeTargetHealth_600752, base: "/",
    url: url_GetDescribeTargetHealth_600753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyListener_600807 = ref object of OpenApiRestCall_599368
proc url_PostModifyListener_600809(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyListener_600808(path: JsonNode; query: JsonNode;
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
  var valid_600810 = query.getOrDefault("Action")
  valid_600810 = validateParameter(valid_600810, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_600810 != nil:
    section.add "Action", valid_600810
  var valid_600811 = query.getOrDefault("Version")
  valid_600811 = validateParameter(valid_600811, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600811 != nil:
    section.add "Version", valid_600811
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
  var valid_600812 = header.getOrDefault("X-Amz-Date")
  valid_600812 = validateParameter(valid_600812, JString, required = false,
                                 default = nil)
  if valid_600812 != nil:
    section.add "X-Amz-Date", valid_600812
  var valid_600813 = header.getOrDefault("X-Amz-Security-Token")
  valid_600813 = validateParameter(valid_600813, JString, required = false,
                                 default = nil)
  if valid_600813 != nil:
    section.add "X-Amz-Security-Token", valid_600813
  var valid_600814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600814 = validateParameter(valid_600814, JString, required = false,
                                 default = nil)
  if valid_600814 != nil:
    section.add "X-Amz-Content-Sha256", valid_600814
  var valid_600815 = header.getOrDefault("X-Amz-Algorithm")
  valid_600815 = validateParameter(valid_600815, JString, required = false,
                                 default = nil)
  if valid_600815 != nil:
    section.add "X-Amz-Algorithm", valid_600815
  var valid_600816 = header.getOrDefault("X-Amz-Signature")
  valid_600816 = validateParameter(valid_600816, JString, required = false,
                                 default = nil)
  if valid_600816 != nil:
    section.add "X-Amz-Signature", valid_600816
  var valid_600817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "X-Amz-SignedHeaders", valid_600817
  var valid_600818 = header.getOrDefault("X-Amz-Credential")
  valid_600818 = validateParameter(valid_600818, JString, required = false,
                                 default = nil)
  if valid_600818 != nil:
    section.add "X-Amz-Credential", valid_600818
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
  var valid_600819 = formData.getOrDefault("Certificates")
  valid_600819 = validateParameter(valid_600819, JArray, required = false,
                                 default = nil)
  if valid_600819 != nil:
    section.add "Certificates", valid_600819
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_600820 = formData.getOrDefault("ListenerArn")
  valid_600820 = validateParameter(valid_600820, JString, required = true,
                                 default = nil)
  if valid_600820 != nil:
    section.add "ListenerArn", valid_600820
  var valid_600821 = formData.getOrDefault("Port")
  valid_600821 = validateParameter(valid_600821, JInt, required = false, default = nil)
  if valid_600821 != nil:
    section.add "Port", valid_600821
  var valid_600822 = formData.getOrDefault("Protocol")
  valid_600822 = validateParameter(valid_600822, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_600822 != nil:
    section.add "Protocol", valid_600822
  var valid_600823 = formData.getOrDefault("SslPolicy")
  valid_600823 = validateParameter(valid_600823, JString, required = false,
                                 default = nil)
  if valid_600823 != nil:
    section.add "SslPolicy", valid_600823
  var valid_600824 = formData.getOrDefault("DefaultActions")
  valid_600824 = validateParameter(valid_600824, JArray, required = false,
                                 default = nil)
  if valid_600824 != nil:
    section.add "DefaultActions", valid_600824
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600825: Call_PostModifyListener_600807; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ## 
  let valid = call_600825.validator(path, query, header, formData, body)
  let scheme = call_600825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600825.url(scheme.get, call_600825.host, call_600825.base,
                         call_600825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600825, url, valid)

proc call*(call_600826: Call_PostModifyListener_600807; ListenerArn: string;
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
  var query_600827 = newJObject()
  var formData_600828 = newJObject()
  if Certificates != nil:
    formData_600828.add "Certificates", Certificates
  add(formData_600828, "ListenerArn", newJString(ListenerArn))
  add(formData_600828, "Port", newJInt(Port))
  add(formData_600828, "Protocol", newJString(Protocol))
  add(query_600827, "Action", newJString(Action))
  add(formData_600828, "SslPolicy", newJString(SslPolicy))
  if DefaultActions != nil:
    formData_600828.add "DefaultActions", DefaultActions
  add(query_600827, "Version", newJString(Version))
  result = call_600826.call(nil, query_600827, nil, formData_600828, nil)

var postModifyListener* = Call_PostModifyListener_600807(
    name: "postModifyListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=ModifyListener",
    validator: validate_PostModifyListener_600808, base: "/",
    url: url_PostModifyListener_600809, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyListener_600786 = ref object of OpenApiRestCall_599368
proc url_GetModifyListener_600788(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyListener_600787(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_600789 = query.getOrDefault("DefaultActions")
  valid_600789 = validateParameter(valid_600789, JArray, required = false,
                                 default = nil)
  if valid_600789 != nil:
    section.add "DefaultActions", valid_600789
  var valid_600790 = query.getOrDefault("SslPolicy")
  valid_600790 = validateParameter(valid_600790, JString, required = false,
                                 default = nil)
  if valid_600790 != nil:
    section.add "SslPolicy", valid_600790
  var valid_600791 = query.getOrDefault("Protocol")
  valid_600791 = validateParameter(valid_600791, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_600791 != nil:
    section.add "Protocol", valid_600791
  var valid_600792 = query.getOrDefault("Certificates")
  valid_600792 = validateParameter(valid_600792, JArray, required = false,
                                 default = nil)
  if valid_600792 != nil:
    section.add "Certificates", valid_600792
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600793 = query.getOrDefault("Action")
  valid_600793 = validateParameter(valid_600793, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_600793 != nil:
    section.add "Action", valid_600793
  var valid_600794 = query.getOrDefault("ListenerArn")
  valid_600794 = validateParameter(valid_600794, JString, required = true,
                                 default = nil)
  if valid_600794 != nil:
    section.add "ListenerArn", valid_600794
  var valid_600795 = query.getOrDefault("Port")
  valid_600795 = validateParameter(valid_600795, JInt, required = false, default = nil)
  if valid_600795 != nil:
    section.add "Port", valid_600795
  var valid_600796 = query.getOrDefault("Version")
  valid_600796 = validateParameter(valid_600796, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600796 != nil:
    section.add "Version", valid_600796
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
  var valid_600797 = header.getOrDefault("X-Amz-Date")
  valid_600797 = validateParameter(valid_600797, JString, required = false,
                                 default = nil)
  if valid_600797 != nil:
    section.add "X-Amz-Date", valid_600797
  var valid_600798 = header.getOrDefault("X-Amz-Security-Token")
  valid_600798 = validateParameter(valid_600798, JString, required = false,
                                 default = nil)
  if valid_600798 != nil:
    section.add "X-Amz-Security-Token", valid_600798
  var valid_600799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600799 = validateParameter(valid_600799, JString, required = false,
                                 default = nil)
  if valid_600799 != nil:
    section.add "X-Amz-Content-Sha256", valid_600799
  var valid_600800 = header.getOrDefault("X-Amz-Algorithm")
  valid_600800 = validateParameter(valid_600800, JString, required = false,
                                 default = nil)
  if valid_600800 != nil:
    section.add "X-Amz-Algorithm", valid_600800
  var valid_600801 = header.getOrDefault("X-Amz-Signature")
  valid_600801 = validateParameter(valid_600801, JString, required = false,
                                 default = nil)
  if valid_600801 != nil:
    section.add "X-Amz-Signature", valid_600801
  var valid_600802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-SignedHeaders", valid_600802
  var valid_600803 = header.getOrDefault("X-Amz-Credential")
  valid_600803 = validateParameter(valid_600803, JString, required = false,
                                 default = nil)
  if valid_600803 != nil:
    section.add "X-Amz-Credential", valid_600803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600804: Call_GetModifyListener_600786; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ## 
  let valid = call_600804.validator(path, query, header, formData, body)
  let scheme = call_600804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600804.url(scheme.get, call_600804.host, call_600804.base,
                         call_600804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600804, url, valid)

proc call*(call_600805: Call_GetModifyListener_600786; ListenerArn: string;
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
  var query_600806 = newJObject()
  if DefaultActions != nil:
    query_600806.add "DefaultActions", DefaultActions
  add(query_600806, "SslPolicy", newJString(SslPolicy))
  add(query_600806, "Protocol", newJString(Protocol))
  if Certificates != nil:
    query_600806.add "Certificates", Certificates
  add(query_600806, "Action", newJString(Action))
  add(query_600806, "ListenerArn", newJString(ListenerArn))
  add(query_600806, "Port", newJInt(Port))
  add(query_600806, "Version", newJString(Version))
  result = call_600805.call(nil, query_600806, nil, nil, nil)

var getModifyListener* = Call_GetModifyListener_600786(name: "getModifyListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyListener", validator: validate_GetModifyListener_600787,
    base: "/", url: url_GetModifyListener_600788,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_600846 = ref object of OpenApiRestCall_599368
proc url_PostModifyLoadBalancerAttributes_600848(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyLoadBalancerAttributes_600847(path: JsonNode;
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
  var valid_600849 = query.getOrDefault("Action")
  valid_600849 = validateParameter(valid_600849, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_600849 != nil:
    section.add "Action", valid_600849
  var valid_600850 = query.getOrDefault("Version")
  valid_600850 = validateParameter(valid_600850, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600850 != nil:
    section.add "Version", valid_600850
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
  var valid_600851 = header.getOrDefault("X-Amz-Date")
  valid_600851 = validateParameter(valid_600851, JString, required = false,
                                 default = nil)
  if valid_600851 != nil:
    section.add "X-Amz-Date", valid_600851
  var valid_600852 = header.getOrDefault("X-Amz-Security-Token")
  valid_600852 = validateParameter(valid_600852, JString, required = false,
                                 default = nil)
  if valid_600852 != nil:
    section.add "X-Amz-Security-Token", valid_600852
  var valid_600853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600853 = validateParameter(valid_600853, JString, required = false,
                                 default = nil)
  if valid_600853 != nil:
    section.add "X-Amz-Content-Sha256", valid_600853
  var valid_600854 = header.getOrDefault("X-Amz-Algorithm")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "X-Amz-Algorithm", valid_600854
  var valid_600855 = header.getOrDefault("X-Amz-Signature")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "X-Amz-Signature", valid_600855
  var valid_600856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600856 = validateParameter(valid_600856, JString, required = false,
                                 default = nil)
  if valid_600856 != nil:
    section.add "X-Amz-SignedHeaders", valid_600856
  var valid_600857 = header.getOrDefault("X-Amz-Credential")
  valid_600857 = validateParameter(valid_600857, JString, required = false,
                                 default = nil)
  if valid_600857 != nil:
    section.add "X-Amz-Credential", valid_600857
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_600858 = formData.getOrDefault("LoadBalancerArn")
  valid_600858 = validateParameter(valid_600858, JString, required = true,
                                 default = nil)
  if valid_600858 != nil:
    section.add "LoadBalancerArn", valid_600858
  var valid_600859 = formData.getOrDefault("Attributes")
  valid_600859 = validateParameter(valid_600859, JArray, required = true, default = nil)
  if valid_600859 != nil:
    section.add "Attributes", valid_600859
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600860: Call_PostModifyLoadBalancerAttributes_600846;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_600860.validator(path, query, header, formData, body)
  let scheme = call_600860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600860.url(scheme.get, call_600860.host, call_600860.base,
                         call_600860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600860, url, valid)

proc call*(call_600861: Call_PostModifyLoadBalancerAttributes_600846;
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
  var query_600862 = newJObject()
  var formData_600863 = newJObject()
  add(formData_600863, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Attributes != nil:
    formData_600863.add "Attributes", Attributes
  add(query_600862, "Action", newJString(Action))
  add(query_600862, "Version", newJString(Version))
  result = call_600861.call(nil, query_600862, nil, formData_600863, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_600846(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_600847, base: "/",
    url: url_PostModifyLoadBalancerAttributes_600848,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_600829 = ref object of OpenApiRestCall_599368
proc url_GetModifyLoadBalancerAttributes_600831(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyLoadBalancerAttributes_600830(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600832 = query.getOrDefault("Attributes")
  valid_600832 = validateParameter(valid_600832, JArray, required = true, default = nil)
  if valid_600832 != nil:
    section.add "Attributes", valid_600832
  var valid_600833 = query.getOrDefault("Action")
  valid_600833 = validateParameter(valid_600833, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_600833 != nil:
    section.add "Action", valid_600833
  var valid_600834 = query.getOrDefault("LoadBalancerArn")
  valid_600834 = validateParameter(valid_600834, JString, required = true,
                                 default = nil)
  if valid_600834 != nil:
    section.add "LoadBalancerArn", valid_600834
  var valid_600835 = query.getOrDefault("Version")
  valid_600835 = validateParameter(valid_600835, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600835 != nil:
    section.add "Version", valid_600835
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
  var valid_600836 = header.getOrDefault("X-Amz-Date")
  valid_600836 = validateParameter(valid_600836, JString, required = false,
                                 default = nil)
  if valid_600836 != nil:
    section.add "X-Amz-Date", valid_600836
  var valid_600837 = header.getOrDefault("X-Amz-Security-Token")
  valid_600837 = validateParameter(valid_600837, JString, required = false,
                                 default = nil)
  if valid_600837 != nil:
    section.add "X-Amz-Security-Token", valid_600837
  var valid_600838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "X-Amz-Content-Sha256", valid_600838
  var valid_600839 = header.getOrDefault("X-Amz-Algorithm")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "X-Amz-Algorithm", valid_600839
  var valid_600840 = header.getOrDefault("X-Amz-Signature")
  valid_600840 = validateParameter(valid_600840, JString, required = false,
                                 default = nil)
  if valid_600840 != nil:
    section.add "X-Amz-Signature", valid_600840
  var valid_600841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600841 = validateParameter(valid_600841, JString, required = false,
                                 default = nil)
  if valid_600841 != nil:
    section.add "X-Amz-SignedHeaders", valid_600841
  var valid_600842 = header.getOrDefault("X-Amz-Credential")
  valid_600842 = validateParameter(valid_600842, JString, required = false,
                                 default = nil)
  if valid_600842 != nil:
    section.add "X-Amz-Credential", valid_600842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600843: Call_GetModifyLoadBalancerAttributes_600829;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_600843.validator(path, query, header, formData, body)
  let scheme = call_600843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600843.url(scheme.get, call_600843.host, call_600843.base,
                         call_600843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600843, url, valid)

proc call*(call_600844: Call_GetModifyLoadBalancerAttributes_600829;
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
  var query_600845 = newJObject()
  if Attributes != nil:
    query_600845.add "Attributes", Attributes
  add(query_600845, "Action", newJString(Action))
  add(query_600845, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_600845, "Version", newJString(Version))
  result = call_600844.call(nil, query_600845, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_600829(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_600830, base: "/",
    url: url_GetModifyLoadBalancerAttributes_600831,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyRule_600882 = ref object of OpenApiRestCall_599368
proc url_PostModifyRule_600884(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyRule_600883(path: JsonNode; query: JsonNode;
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
  var valid_600885 = query.getOrDefault("Action")
  valid_600885 = validateParameter(valid_600885, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_600885 != nil:
    section.add "Action", valid_600885
  var valid_600886 = query.getOrDefault("Version")
  valid_600886 = validateParameter(valid_600886, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600886 != nil:
    section.add "Version", valid_600886
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
  var valid_600887 = header.getOrDefault("X-Amz-Date")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Date", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Security-Token")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Security-Token", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Content-Sha256", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Algorithm")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Algorithm", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Signature")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Signature", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-SignedHeaders", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-Credential")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Credential", valid_600893
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
  var valid_600894 = formData.getOrDefault("RuleArn")
  valid_600894 = validateParameter(valid_600894, JString, required = true,
                                 default = nil)
  if valid_600894 != nil:
    section.add "RuleArn", valid_600894
  var valid_600895 = formData.getOrDefault("Actions")
  valid_600895 = validateParameter(valid_600895, JArray, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "Actions", valid_600895
  var valid_600896 = formData.getOrDefault("Conditions")
  valid_600896 = validateParameter(valid_600896, JArray, required = false,
                                 default = nil)
  if valid_600896 != nil:
    section.add "Conditions", valid_600896
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600897: Call_PostModifyRule_600882; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_600897.validator(path, query, header, formData, body)
  let scheme = call_600897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600897.url(scheme.get, call_600897.host, call_600897.base,
                         call_600897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600897, url, valid)

proc call*(call_600898: Call_PostModifyRule_600882; RuleArn: string;
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
  var query_600899 = newJObject()
  var formData_600900 = newJObject()
  add(formData_600900, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    formData_600900.add "Actions", Actions
  if Conditions != nil:
    formData_600900.add "Conditions", Conditions
  add(query_600899, "Action", newJString(Action))
  add(query_600899, "Version", newJString(Version))
  result = call_600898.call(nil, query_600899, nil, formData_600900, nil)

var postModifyRule* = Call_PostModifyRule_600882(name: "postModifyRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_PostModifyRule_600883,
    base: "/", url: url_PostModifyRule_600884, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyRule_600864 = ref object of OpenApiRestCall_599368
proc url_GetModifyRule_600866(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyRule_600865(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600867 = query.getOrDefault("Conditions")
  valid_600867 = validateParameter(valid_600867, JArray, required = false,
                                 default = nil)
  if valid_600867 != nil:
    section.add "Conditions", valid_600867
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600868 = query.getOrDefault("Action")
  valid_600868 = validateParameter(valid_600868, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_600868 != nil:
    section.add "Action", valid_600868
  var valid_600869 = query.getOrDefault("RuleArn")
  valid_600869 = validateParameter(valid_600869, JString, required = true,
                                 default = nil)
  if valid_600869 != nil:
    section.add "RuleArn", valid_600869
  var valid_600870 = query.getOrDefault("Actions")
  valid_600870 = validateParameter(valid_600870, JArray, required = false,
                                 default = nil)
  if valid_600870 != nil:
    section.add "Actions", valid_600870
  var valid_600871 = query.getOrDefault("Version")
  valid_600871 = validateParameter(valid_600871, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600871 != nil:
    section.add "Version", valid_600871
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
  var valid_600872 = header.getOrDefault("X-Amz-Date")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Date", valid_600872
  var valid_600873 = header.getOrDefault("X-Amz-Security-Token")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "X-Amz-Security-Token", valid_600873
  var valid_600874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "X-Amz-Content-Sha256", valid_600874
  var valid_600875 = header.getOrDefault("X-Amz-Algorithm")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "X-Amz-Algorithm", valid_600875
  var valid_600876 = header.getOrDefault("X-Amz-Signature")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "X-Amz-Signature", valid_600876
  var valid_600877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600877 = validateParameter(valid_600877, JString, required = false,
                                 default = nil)
  if valid_600877 != nil:
    section.add "X-Amz-SignedHeaders", valid_600877
  var valid_600878 = header.getOrDefault("X-Amz-Credential")
  valid_600878 = validateParameter(valid_600878, JString, required = false,
                                 default = nil)
  if valid_600878 != nil:
    section.add "X-Amz-Credential", valid_600878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600879: Call_GetModifyRule_600864; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_600879.validator(path, query, header, formData, body)
  let scheme = call_600879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600879.url(scheme.get, call_600879.host, call_600879.base,
                         call_600879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600879, url, valid)

proc call*(call_600880: Call_GetModifyRule_600864; RuleArn: string;
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
  var query_600881 = newJObject()
  if Conditions != nil:
    query_600881.add "Conditions", Conditions
  add(query_600881, "Action", newJString(Action))
  add(query_600881, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    query_600881.add "Actions", Actions
  add(query_600881, "Version", newJString(Version))
  result = call_600880.call(nil, query_600881, nil, nil, nil)

var getModifyRule* = Call_GetModifyRule_600864(name: "getModifyRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_GetModifyRule_600865,
    base: "/", url: url_GetModifyRule_600866, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroup_600926 = ref object of OpenApiRestCall_599368
proc url_PostModifyTargetGroup_600928(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyTargetGroup_600927(path: JsonNode; query: JsonNode;
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
  var valid_600929 = query.getOrDefault("Action")
  valid_600929 = validateParameter(valid_600929, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_600929 != nil:
    section.add "Action", valid_600929
  var valid_600930 = query.getOrDefault("Version")
  valid_600930 = validateParameter(valid_600930, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600930 != nil:
    section.add "Version", valid_600930
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
  var valid_600931 = header.getOrDefault("X-Amz-Date")
  valid_600931 = validateParameter(valid_600931, JString, required = false,
                                 default = nil)
  if valid_600931 != nil:
    section.add "X-Amz-Date", valid_600931
  var valid_600932 = header.getOrDefault("X-Amz-Security-Token")
  valid_600932 = validateParameter(valid_600932, JString, required = false,
                                 default = nil)
  if valid_600932 != nil:
    section.add "X-Amz-Security-Token", valid_600932
  var valid_600933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600933 = validateParameter(valid_600933, JString, required = false,
                                 default = nil)
  if valid_600933 != nil:
    section.add "X-Amz-Content-Sha256", valid_600933
  var valid_600934 = header.getOrDefault("X-Amz-Algorithm")
  valid_600934 = validateParameter(valid_600934, JString, required = false,
                                 default = nil)
  if valid_600934 != nil:
    section.add "X-Amz-Algorithm", valid_600934
  var valid_600935 = header.getOrDefault("X-Amz-Signature")
  valid_600935 = validateParameter(valid_600935, JString, required = false,
                                 default = nil)
  if valid_600935 != nil:
    section.add "X-Amz-Signature", valid_600935
  var valid_600936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600936 = validateParameter(valid_600936, JString, required = false,
                                 default = nil)
  if valid_600936 != nil:
    section.add "X-Amz-SignedHeaders", valid_600936
  var valid_600937 = header.getOrDefault("X-Amz-Credential")
  valid_600937 = validateParameter(valid_600937, JString, required = false,
                                 default = nil)
  if valid_600937 != nil:
    section.add "X-Amz-Credential", valid_600937
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
  var valid_600938 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_600938 = validateParameter(valid_600938, JInt, required = false, default = nil)
  if valid_600938 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_600938
  var valid_600939 = formData.getOrDefault("HealthCheckPort")
  valid_600939 = validateParameter(valid_600939, JString, required = false,
                                 default = nil)
  if valid_600939 != nil:
    section.add "HealthCheckPort", valid_600939
  var valid_600940 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_600940 = validateParameter(valid_600940, JInt, required = false, default = nil)
  if valid_600940 != nil:
    section.add "UnhealthyThresholdCount", valid_600940
  var valid_600941 = formData.getOrDefault("HealthCheckPath")
  valid_600941 = validateParameter(valid_600941, JString, required = false,
                                 default = nil)
  if valid_600941 != nil:
    section.add "HealthCheckPath", valid_600941
  var valid_600942 = formData.getOrDefault("HealthCheckEnabled")
  valid_600942 = validateParameter(valid_600942, JBool, required = false, default = nil)
  if valid_600942 != nil:
    section.add "HealthCheckEnabled", valid_600942
  var valid_600943 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_600943 = validateParameter(valid_600943, JInt, required = false, default = nil)
  if valid_600943 != nil:
    section.add "HealthCheckIntervalSeconds", valid_600943
  var valid_600944 = formData.getOrDefault("HealthyThresholdCount")
  valid_600944 = validateParameter(valid_600944, JInt, required = false, default = nil)
  if valid_600944 != nil:
    section.add "HealthyThresholdCount", valid_600944
  var valid_600945 = formData.getOrDefault("HealthCheckProtocol")
  valid_600945 = validateParameter(valid_600945, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_600945 != nil:
    section.add "HealthCheckProtocol", valid_600945
  var valid_600946 = formData.getOrDefault("Matcher.HttpCode")
  valid_600946 = validateParameter(valid_600946, JString, required = false,
                                 default = nil)
  if valid_600946 != nil:
    section.add "Matcher.HttpCode", valid_600946
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_600947 = formData.getOrDefault("TargetGroupArn")
  valid_600947 = validateParameter(valid_600947, JString, required = true,
                                 default = nil)
  if valid_600947 != nil:
    section.add "TargetGroupArn", valid_600947
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600948: Call_PostModifyTargetGroup_600926; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_600948.validator(path, query, header, formData, body)
  let scheme = call_600948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600948.url(scheme.get, call_600948.host, call_600948.base,
                         call_600948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600948, url, valid)

proc call*(call_600949: Call_PostModifyTargetGroup_600926; TargetGroupArn: string;
          HealthCheckTimeoutSeconds: int = 0; HealthCheckPort: string = "";
          UnhealthyThresholdCount: int = 0; HealthCheckPath: string = "";
          HealthCheckEnabled: bool = false; Action: string = "ModifyTargetGroup";
          HealthCheckIntervalSeconds: int = 0; HealthyThresholdCount: int = 0;
          HealthCheckProtocol: string = "HTTP"; MatcherHttpCode: string = "";
          Version: string = "2015-12-01"): Recallable =
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
  var query_600950 = newJObject()
  var formData_600951 = newJObject()
  add(formData_600951, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_600951, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_600951, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_600951, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_600951, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_600950, "Action", newJString(Action))
  add(formData_600951, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_600951, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_600951, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_600951, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(formData_600951, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_600950, "Version", newJString(Version))
  result = call_600949.call(nil, query_600950, nil, formData_600951, nil)

var postModifyTargetGroup* = Call_PostModifyTargetGroup_600926(
    name: "postModifyTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup",
    validator: validate_PostModifyTargetGroup_600927, base: "/",
    url: url_PostModifyTargetGroup_600928, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroup_600901 = ref object of OpenApiRestCall_599368
proc url_GetModifyTargetGroup_600903(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyTargetGroup_600902(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600904 = query.getOrDefault("HealthCheckEnabled")
  valid_600904 = validateParameter(valid_600904, JBool, required = false, default = nil)
  if valid_600904 != nil:
    section.add "HealthCheckEnabled", valid_600904
  var valid_600905 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_600905 = validateParameter(valid_600905, JInt, required = false, default = nil)
  if valid_600905 != nil:
    section.add "HealthCheckIntervalSeconds", valid_600905
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_600906 = query.getOrDefault("TargetGroupArn")
  valid_600906 = validateParameter(valid_600906, JString, required = true,
                                 default = nil)
  if valid_600906 != nil:
    section.add "TargetGroupArn", valid_600906
  var valid_600907 = query.getOrDefault("HealthCheckPort")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "HealthCheckPort", valid_600907
  var valid_600908 = query.getOrDefault("Action")
  valid_600908 = validateParameter(valid_600908, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_600908 != nil:
    section.add "Action", valid_600908
  var valid_600909 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_600909 = validateParameter(valid_600909, JInt, required = false, default = nil)
  if valid_600909 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_600909
  var valid_600910 = query.getOrDefault("Matcher.HttpCode")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "Matcher.HttpCode", valid_600910
  var valid_600911 = query.getOrDefault("UnhealthyThresholdCount")
  valid_600911 = validateParameter(valid_600911, JInt, required = false, default = nil)
  if valid_600911 != nil:
    section.add "UnhealthyThresholdCount", valid_600911
  var valid_600912 = query.getOrDefault("HealthCheckProtocol")
  valid_600912 = validateParameter(valid_600912, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_600912 != nil:
    section.add "HealthCheckProtocol", valid_600912
  var valid_600913 = query.getOrDefault("HealthyThresholdCount")
  valid_600913 = validateParameter(valid_600913, JInt, required = false, default = nil)
  if valid_600913 != nil:
    section.add "HealthyThresholdCount", valid_600913
  var valid_600914 = query.getOrDefault("Version")
  valid_600914 = validateParameter(valid_600914, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600914 != nil:
    section.add "Version", valid_600914
  var valid_600915 = query.getOrDefault("HealthCheckPath")
  valid_600915 = validateParameter(valid_600915, JString, required = false,
                                 default = nil)
  if valid_600915 != nil:
    section.add "HealthCheckPath", valid_600915
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
  var valid_600916 = header.getOrDefault("X-Amz-Date")
  valid_600916 = validateParameter(valid_600916, JString, required = false,
                                 default = nil)
  if valid_600916 != nil:
    section.add "X-Amz-Date", valid_600916
  var valid_600917 = header.getOrDefault("X-Amz-Security-Token")
  valid_600917 = validateParameter(valid_600917, JString, required = false,
                                 default = nil)
  if valid_600917 != nil:
    section.add "X-Amz-Security-Token", valid_600917
  var valid_600918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600918 = validateParameter(valid_600918, JString, required = false,
                                 default = nil)
  if valid_600918 != nil:
    section.add "X-Amz-Content-Sha256", valid_600918
  var valid_600919 = header.getOrDefault("X-Amz-Algorithm")
  valid_600919 = validateParameter(valid_600919, JString, required = false,
                                 default = nil)
  if valid_600919 != nil:
    section.add "X-Amz-Algorithm", valid_600919
  var valid_600920 = header.getOrDefault("X-Amz-Signature")
  valid_600920 = validateParameter(valid_600920, JString, required = false,
                                 default = nil)
  if valid_600920 != nil:
    section.add "X-Amz-Signature", valid_600920
  var valid_600921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600921 = validateParameter(valid_600921, JString, required = false,
                                 default = nil)
  if valid_600921 != nil:
    section.add "X-Amz-SignedHeaders", valid_600921
  var valid_600922 = header.getOrDefault("X-Amz-Credential")
  valid_600922 = validateParameter(valid_600922, JString, required = false,
                                 default = nil)
  if valid_600922 != nil:
    section.add "X-Amz-Credential", valid_600922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600923: Call_GetModifyTargetGroup_600901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_600923.validator(path, query, header, formData, body)
  let scheme = call_600923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600923.url(scheme.get, call_600923.host, call_600923.base,
                         call_600923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600923, url, valid)

proc call*(call_600924: Call_GetModifyTargetGroup_600901; TargetGroupArn: string;
          HealthCheckEnabled: bool = false; HealthCheckIntervalSeconds: int = 0;
          HealthCheckPort: string = ""; Action: string = "ModifyTargetGroup";
          HealthCheckTimeoutSeconds: int = 0; MatcherHttpCode: string = "";
          UnhealthyThresholdCount: int = 0; HealthCheckProtocol: string = "HTTP";
          HealthyThresholdCount: int = 0; Version: string = "2015-12-01";
          HealthCheckPath: string = ""): Recallable =
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
  var query_600925 = newJObject()
  add(query_600925, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_600925, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_600925, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_600925, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_600925, "Action", newJString(Action))
  add(query_600925, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_600925, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_600925, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_600925, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_600925, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_600925, "Version", newJString(Version))
  add(query_600925, "HealthCheckPath", newJString(HealthCheckPath))
  result = call_600924.call(nil, query_600925, nil, nil, nil)

var getModifyTargetGroup* = Call_GetModifyTargetGroup_600901(
    name: "getModifyTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup", validator: validate_GetModifyTargetGroup_600902,
    base: "/", url: url_GetModifyTargetGroup_600903,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroupAttributes_600969 = ref object of OpenApiRestCall_599368
proc url_PostModifyTargetGroupAttributes_600971(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyTargetGroupAttributes_600970(path: JsonNode;
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
  var valid_600972 = query.getOrDefault("Action")
  valid_600972 = validateParameter(valid_600972, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_600972 != nil:
    section.add "Action", valid_600972
  var valid_600973 = query.getOrDefault("Version")
  valid_600973 = validateParameter(valid_600973, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600973 != nil:
    section.add "Version", valid_600973
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
  var valid_600974 = header.getOrDefault("X-Amz-Date")
  valid_600974 = validateParameter(valid_600974, JString, required = false,
                                 default = nil)
  if valid_600974 != nil:
    section.add "X-Amz-Date", valid_600974
  var valid_600975 = header.getOrDefault("X-Amz-Security-Token")
  valid_600975 = validateParameter(valid_600975, JString, required = false,
                                 default = nil)
  if valid_600975 != nil:
    section.add "X-Amz-Security-Token", valid_600975
  var valid_600976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600976 = validateParameter(valid_600976, JString, required = false,
                                 default = nil)
  if valid_600976 != nil:
    section.add "X-Amz-Content-Sha256", valid_600976
  var valid_600977 = header.getOrDefault("X-Amz-Algorithm")
  valid_600977 = validateParameter(valid_600977, JString, required = false,
                                 default = nil)
  if valid_600977 != nil:
    section.add "X-Amz-Algorithm", valid_600977
  var valid_600978 = header.getOrDefault("X-Amz-Signature")
  valid_600978 = validateParameter(valid_600978, JString, required = false,
                                 default = nil)
  if valid_600978 != nil:
    section.add "X-Amz-Signature", valid_600978
  var valid_600979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600979 = validateParameter(valid_600979, JString, required = false,
                                 default = nil)
  if valid_600979 != nil:
    section.add "X-Amz-SignedHeaders", valid_600979
  var valid_600980 = header.getOrDefault("X-Amz-Credential")
  valid_600980 = validateParameter(valid_600980, JString, required = false,
                                 default = nil)
  if valid_600980 != nil:
    section.add "X-Amz-Credential", valid_600980
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_600981 = formData.getOrDefault("Attributes")
  valid_600981 = validateParameter(valid_600981, JArray, required = true, default = nil)
  if valid_600981 != nil:
    section.add "Attributes", valid_600981
  var valid_600982 = formData.getOrDefault("TargetGroupArn")
  valid_600982 = validateParameter(valid_600982, JString, required = true,
                                 default = nil)
  if valid_600982 != nil:
    section.add "TargetGroupArn", valid_600982
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600983: Call_PostModifyTargetGroupAttributes_600969;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_600983.validator(path, query, header, formData, body)
  let scheme = call_600983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600983.url(scheme.get, call_600983.host, call_600983.base,
                         call_600983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600983, url, valid)

proc call*(call_600984: Call_PostModifyTargetGroupAttributes_600969;
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
  var query_600985 = newJObject()
  var formData_600986 = newJObject()
  if Attributes != nil:
    formData_600986.add "Attributes", Attributes
  add(query_600985, "Action", newJString(Action))
  add(formData_600986, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_600985, "Version", newJString(Version))
  result = call_600984.call(nil, query_600985, nil, formData_600986, nil)

var postModifyTargetGroupAttributes* = Call_PostModifyTargetGroupAttributes_600969(
    name: "postModifyTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_PostModifyTargetGroupAttributes_600970, base: "/",
    url: url_PostModifyTargetGroupAttributes_600971,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroupAttributes_600952 = ref object of OpenApiRestCall_599368
proc url_GetModifyTargetGroupAttributes_600954(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyTargetGroupAttributes_600953(path: JsonNode;
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
  var valid_600955 = query.getOrDefault("TargetGroupArn")
  valid_600955 = validateParameter(valid_600955, JString, required = true,
                                 default = nil)
  if valid_600955 != nil:
    section.add "TargetGroupArn", valid_600955
  var valid_600956 = query.getOrDefault("Attributes")
  valid_600956 = validateParameter(valid_600956, JArray, required = true, default = nil)
  if valid_600956 != nil:
    section.add "Attributes", valid_600956
  var valid_600957 = query.getOrDefault("Action")
  valid_600957 = validateParameter(valid_600957, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_600957 != nil:
    section.add "Action", valid_600957
  var valid_600958 = query.getOrDefault("Version")
  valid_600958 = validateParameter(valid_600958, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600958 != nil:
    section.add "Version", valid_600958
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
  var valid_600959 = header.getOrDefault("X-Amz-Date")
  valid_600959 = validateParameter(valid_600959, JString, required = false,
                                 default = nil)
  if valid_600959 != nil:
    section.add "X-Amz-Date", valid_600959
  var valid_600960 = header.getOrDefault("X-Amz-Security-Token")
  valid_600960 = validateParameter(valid_600960, JString, required = false,
                                 default = nil)
  if valid_600960 != nil:
    section.add "X-Amz-Security-Token", valid_600960
  var valid_600961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600961 = validateParameter(valid_600961, JString, required = false,
                                 default = nil)
  if valid_600961 != nil:
    section.add "X-Amz-Content-Sha256", valid_600961
  var valid_600962 = header.getOrDefault("X-Amz-Algorithm")
  valid_600962 = validateParameter(valid_600962, JString, required = false,
                                 default = nil)
  if valid_600962 != nil:
    section.add "X-Amz-Algorithm", valid_600962
  var valid_600963 = header.getOrDefault("X-Amz-Signature")
  valid_600963 = validateParameter(valid_600963, JString, required = false,
                                 default = nil)
  if valid_600963 != nil:
    section.add "X-Amz-Signature", valid_600963
  var valid_600964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600964 = validateParameter(valid_600964, JString, required = false,
                                 default = nil)
  if valid_600964 != nil:
    section.add "X-Amz-SignedHeaders", valid_600964
  var valid_600965 = header.getOrDefault("X-Amz-Credential")
  valid_600965 = validateParameter(valid_600965, JString, required = false,
                                 default = nil)
  if valid_600965 != nil:
    section.add "X-Amz-Credential", valid_600965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600966: Call_GetModifyTargetGroupAttributes_600952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_600966.validator(path, query, header, formData, body)
  let scheme = call_600966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600966.url(scheme.get, call_600966.host, call_600966.base,
                         call_600966.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600966, url, valid)

proc call*(call_600967: Call_GetModifyTargetGroupAttributes_600952;
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
  var query_600968 = newJObject()
  add(query_600968, "TargetGroupArn", newJString(TargetGroupArn))
  if Attributes != nil:
    query_600968.add "Attributes", Attributes
  add(query_600968, "Action", newJString(Action))
  add(query_600968, "Version", newJString(Version))
  result = call_600967.call(nil, query_600968, nil, nil, nil)

var getModifyTargetGroupAttributes* = Call_GetModifyTargetGroupAttributes_600952(
    name: "getModifyTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_GetModifyTargetGroupAttributes_600953, base: "/",
    url: url_GetModifyTargetGroupAttributes_600954,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterTargets_601004 = ref object of OpenApiRestCall_599368
proc url_PostRegisterTargets_601006(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRegisterTargets_601005(path: JsonNode; query: JsonNode;
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
  var valid_601007 = query.getOrDefault("Action")
  valid_601007 = validateParameter(valid_601007, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_601007 != nil:
    section.add "Action", valid_601007
  var valid_601008 = query.getOrDefault("Version")
  valid_601008 = validateParameter(valid_601008, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601008 != nil:
    section.add "Version", valid_601008
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
  var valid_601009 = header.getOrDefault("X-Amz-Date")
  valid_601009 = validateParameter(valid_601009, JString, required = false,
                                 default = nil)
  if valid_601009 != nil:
    section.add "X-Amz-Date", valid_601009
  var valid_601010 = header.getOrDefault("X-Amz-Security-Token")
  valid_601010 = validateParameter(valid_601010, JString, required = false,
                                 default = nil)
  if valid_601010 != nil:
    section.add "X-Amz-Security-Token", valid_601010
  var valid_601011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601011 = validateParameter(valid_601011, JString, required = false,
                                 default = nil)
  if valid_601011 != nil:
    section.add "X-Amz-Content-Sha256", valid_601011
  var valid_601012 = header.getOrDefault("X-Amz-Algorithm")
  valid_601012 = validateParameter(valid_601012, JString, required = false,
                                 default = nil)
  if valid_601012 != nil:
    section.add "X-Amz-Algorithm", valid_601012
  var valid_601013 = header.getOrDefault("X-Amz-Signature")
  valid_601013 = validateParameter(valid_601013, JString, required = false,
                                 default = nil)
  if valid_601013 != nil:
    section.add "X-Amz-Signature", valid_601013
  var valid_601014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601014 = validateParameter(valid_601014, JString, required = false,
                                 default = nil)
  if valid_601014 != nil:
    section.add "X-Amz-SignedHeaders", valid_601014
  var valid_601015 = header.getOrDefault("X-Amz-Credential")
  valid_601015 = validateParameter(valid_601015, JString, required = false,
                                 default = nil)
  if valid_601015 != nil:
    section.add "X-Amz-Credential", valid_601015
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_601016 = formData.getOrDefault("Targets")
  valid_601016 = validateParameter(valid_601016, JArray, required = true, default = nil)
  if valid_601016 != nil:
    section.add "Targets", valid_601016
  var valid_601017 = formData.getOrDefault("TargetGroupArn")
  valid_601017 = validateParameter(valid_601017, JString, required = true,
                                 default = nil)
  if valid_601017 != nil:
    section.add "TargetGroupArn", valid_601017
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601018: Call_PostRegisterTargets_601004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_601018.validator(path, query, header, formData, body)
  let scheme = call_601018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601018.url(scheme.get, call_601018.host, call_601018.base,
                         call_601018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601018, url, valid)

proc call*(call_601019: Call_PostRegisterTargets_601004; Targets: JsonNode;
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
  var query_601020 = newJObject()
  var formData_601021 = newJObject()
  if Targets != nil:
    formData_601021.add "Targets", Targets
  add(query_601020, "Action", newJString(Action))
  add(formData_601021, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_601020, "Version", newJString(Version))
  result = call_601019.call(nil, query_601020, nil, formData_601021, nil)

var postRegisterTargets* = Call_PostRegisterTargets_601004(
    name: "postRegisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_PostRegisterTargets_601005, base: "/",
    url: url_PostRegisterTargets_601006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterTargets_600987 = ref object of OpenApiRestCall_599368
proc url_GetRegisterTargets_600989(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRegisterTargets_600988(path: JsonNode; query: JsonNode;
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
  var valid_600990 = query.getOrDefault("Targets")
  valid_600990 = validateParameter(valid_600990, JArray, required = true, default = nil)
  if valid_600990 != nil:
    section.add "Targets", valid_600990
  var valid_600991 = query.getOrDefault("TargetGroupArn")
  valid_600991 = validateParameter(valid_600991, JString, required = true,
                                 default = nil)
  if valid_600991 != nil:
    section.add "TargetGroupArn", valid_600991
  var valid_600992 = query.getOrDefault("Action")
  valid_600992 = validateParameter(valid_600992, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_600992 != nil:
    section.add "Action", valid_600992
  var valid_600993 = query.getOrDefault("Version")
  valid_600993 = validateParameter(valid_600993, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600993 != nil:
    section.add "Version", valid_600993
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
  var valid_600994 = header.getOrDefault("X-Amz-Date")
  valid_600994 = validateParameter(valid_600994, JString, required = false,
                                 default = nil)
  if valid_600994 != nil:
    section.add "X-Amz-Date", valid_600994
  var valid_600995 = header.getOrDefault("X-Amz-Security-Token")
  valid_600995 = validateParameter(valid_600995, JString, required = false,
                                 default = nil)
  if valid_600995 != nil:
    section.add "X-Amz-Security-Token", valid_600995
  var valid_600996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600996 = validateParameter(valid_600996, JString, required = false,
                                 default = nil)
  if valid_600996 != nil:
    section.add "X-Amz-Content-Sha256", valid_600996
  var valid_600997 = header.getOrDefault("X-Amz-Algorithm")
  valid_600997 = validateParameter(valid_600997, JString, required = false,
                                 default = nil)
  if valid_600997 != nil:
    section.add "X-Amz-Algorithm", valid_600997
  var valid_600998 = header.getOrDefault("X-Amz-Signature")
  valid_600998 = validateParameter(valid_600998, JString, required = false,
                                 default = nil)
  if valid_600998 != nil:
    section.add "X-Amz-Signature", valid_600998
  var valid_600999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600999 = validateParameter(valid_600999, JString, required = false,
                                 default = nil)
  if valid_600999 != nil:
    section.add "X-Amz-SignedHeaders", valid_600999
  var valid_601000 = header.getOrDefault("X-Amz-Credential")
  valid_601000 = validateParameter(valid_601000, JString, required = false,
                                 default = nil)
  if valid_601000 != nil:
    section.add "X-Amz-Credential", valid_601000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601001: Call_GetRegisterTargets_600987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_601001.validator(path, query, header, formData, body)
  let scheme = call_601001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601001.url(scheme.get, call_601001.host, call_601001.base,
                         call_601001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601001, url, valid)

proc call*(call_601002: Call_GetRegisterTargets_600987; Targets: JsonNode;
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
  var query_601003 = newJObject()
  if Targets != nil:
    query_601003.add "Targets", Targets
  add(query_601003, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_601003, "Action", newJString(Action))
  add(query_601003, "Version", newJString(Version))
  result = call_601002.call(nil, query_601003, nil, nil, nil)

var getRegisterTargets* = Call_GetRegisterTargets_600987(
    name: "getRegisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_GetRegisterTargets_600988, base: "/",
    url: url_GetRegisterTargets_600989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveListenerCertificates_601039 = ref object of OpenApiRestCall_599368
proc url_PostRemoveListenerCertificates_601041(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveListenerCertificates_601040(path: JsonNode;
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
  var valid_601042 = query.getOrDefault("Action")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_601042 != nil:
    section.add "Action", valid_601042
  var valid_601043 = query.getOrDefault("Version")
  valid_601043 = validateParameter(valid_601043, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601043 != nil:
    section.add "Version", valid_601043
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
  var valid_601044 = header.getOrDefault("X-Amz-Date")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Date", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Security-Token")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Security-Token", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Content-Sha256", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Algorithm")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Algorithm", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Signature")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Signature", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-SignedHeaders", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Credential")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Credential", valid_601050
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_601051 = formData.getOrDefault("Certificates")
  valid_601051 = validateParameter(valid_601051, JArray, required = true, default = nil)
  if valid_601051 != nil:
    section.add "Certificates", valid_601051
  var valid_601052 = formData.getOrDefault("ListenerArn")
  valid_601052 = validateParameter(valid_601052, JString, required = true,
                                 default = nil)
  if valid_601052 != nil:
    section.add "ListenerArn", valid_601052
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601053: Call_PostRemoveListenerCertificates_601039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_601053.validator(path, query, header, formData, body)
  let scheme = call_601053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601053.url(scheme.get, call_601053.host, call_601053.base,
                         call_601053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601053, url, valid)

proc call*(call_601054: Call_PostRemoveListenerCertificates_601039;
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
  var query_601055 = newJObject()
  var formData_601056 = newJObject()
  if Certificates != nil:
    formData_601056.add "Certificates", Certificates
  add(formData_601056, "ListenerArn", newJString(ListenerArn))
  add(query_601055, "Action", newJString(Action))
  add(query_601055, "Version", newJString(Version))
  result = call_601054.call(nil, query_601055, nil, formData_601056, nil)

var postRemoveListenerCertificates* = Call_PostRemoveListenerCertificates_601039(
    name: "postRemoveListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_PostRemoveListenerCertificates_601040, base: "/",
    url: url_PostRemoveListenerCertificates_601041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveListenerCertificates_601022 = ref object of OpenApiRestCall_599368
proc url_GetRemoveListenerCertificates_601024(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveListenerCertificates_601023(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601025 = query.getOrDefault("Certificates")
  valid_601025 = validateParameter(valid_601025, JArray, required = true, default = nil)
  if valid_601025 != nil:
    section.add "Certificates", valid_601025
  var valid_601026 = query.getOrDefault("Action")
  valid_601026 = validateParameter(valid_601026, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_601026 != nil:
    section.add "Action", valid_601026
  var valid_601027 = query.getOrDefault("ListenerArn")
  valid_601027 = validateParameter(valid_601027, JString, required = true,
                                 default = nil)
  if valid_601027 != nil:
    section.add "ListenerArn", valid_601027
  var valid_601028 = query.getOrDefault("Version")
  valid_601028 = validateParameter(valid_601028, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601028 != nil:
    section.add "Version", valid_601028
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
  var valid_601029 = header.getOrDefault("X-Amz-Date")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Date", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Security-Token")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Security-Token", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Content-Sha256", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Algorithm")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Algorithm", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-Signature")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-Signature", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-SignedHeaders", valid_601034
  var valid_601035 = header.getOrDefault("X-Amz-Credential")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Credential", valid_601035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601036: Call_GetRemoveListenerCertificates_601022; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_601036.validator(path, query, header, formData, body)
  let scheme = call_601036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601036.url(scheme.get, call_601036.host, call_601036.base,
                         call_601036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601036, url, valid)

proc call*(call_601037: Call_GetRemoveListenerCertificates_601022;
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
  var query_601038 = newJObject()
  if Certificates != nil:
    query_601038.add "Certificates", Certificates
  add(query_601038, "Action", newJString(Action))
  add(query_601038, "ListenerArn", newJString(ListenerArn))
  add(query_601038, "Version", newJString(Version))
  result = call_601037.call(nil, query_601038, nil, nil, nil)

var getRemoveListenerCertificates* = Call_GetRemoveListenerCertificates_601022(
    name: "getRemoveListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_GetRemoveListenerCertificates_601023, base: "/",
    url: url_GetRemoveListenerCertificates_601024,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_601074 = ref object of OpenApiRestCall_599368
proc url_PostRemoveTags_601076(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTags_601075(path: JsonNode; query: JsonNode;
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
  var valid_601077 = query.getOrDefault("Action")
  valid_601077 = validateParameter(valid_601077, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_601077 != nil:
    section.add "Action", valid_601077
  var valid_601078 = query.getOrDefault("Version")
  valid_601078 = validateParameter(valid_601078, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601078 != nil:
    section.add "Version", valid_601078
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
  var valid_601079 = header.getOrDefault("X-Amz-Date")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Date", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Security-Token")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Security-Token", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Content-Sha256", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Algorithm")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Algorithm", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Signature")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Signature", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-SignedHeaders", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Credential")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Credential", valid_601085
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_601086 = formData.getOrDefault("ResourceArns")
  valid_601086 = validateParameter(valid_601086, JArray, required = true, default = nil)
  if valid_601086 != nil:
    section.add "ResourceArns", valid_601086
  var valid_601087 = formData.getOrDefault("TagKeys")
  valid_601087 = validateParameter(valid_601087, JArray, required = true, default = nil)
  if valid_601087 != nil:
    section.add "TagKeys", valid_601087
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601088: Call_PostRemoveTags_601074; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_601088.validator(path, query, header, formData, body)
  let scheme = call_601088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601088.url(scheme.get, call_601088.host, call_601088.base,
                         call_601088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601088, url, valid)

proc call*(call_601089: Call_PostRemoveTags_601074; ResourceArns: JsonNode;
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
  var query_601090 = newJObject()
  var formData_601091 = newJObject()
  if ResourceArns != nil:
    formData_601091.add "ResourceArns", ResourceArns
  add(query_601090, "Action", newJString(Action))
  if TagKeys != nil:
    formData_601091.add "TagKeys", TagKeys
  add(query_601090, "Version", newJString(Version))
  result = call_601089.call(nil, query_601090, nil, formData_601091, nil)

var postRemoveTags* = Call_PostRemoveTags_601074(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_601075,
    base: "/", url: url_PostRemoveTags_601076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_601057 = ref object of OpenApiRestCall_599368
proc url_GetRemoveTags_601059(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTags_601058(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601060 = query.getOrDefault("Action")
  valid_601060 = validateParameter(valid_601060, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_601060 != nil:
    section.add "Action", valid_601060
  var valid_601061 = query.getOrDefault("ResourceArns")
  valid_601061 = validateParameter(valid_601061, JArray, required = true, default = nil)
  if valid_601061 != nil:
    section.add "ResourceArns", valid_601061
  var valid_601062 = query.getOrDefault("TagKeys")
  valid_601062 = validateParameter(valid_601062, JArray, required = true, default = nil)
  if valid_601062 != nil:
    section.add "TagKeys", valid_601062
  var valid_601063 = query.getOrDefault("Version")
  valid_601063 = validateParameter(valid_601063, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601063 != nil:
    section.add "Version", valid_601063
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
  var valid_601064 = header.getOrDefault("X-Amz-Date")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Date", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Security-Token")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Security-Token", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Content-Sha256", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Algorithm")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Algorithm", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Signature")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Signature", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-SignedHeaders", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Credential")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Credential", valid_601070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601071: Call_GetRemoveTags_601057; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_601071.validator(path, query, header, formData, body)
  let scheme = call_601071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601071.url(scheme.get, call_601071.host, call_601071.base,
                         call_601071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601071, url, valid)

proc call*(call_601072: Call_GetRemoveTags_601057; ResourceArns: JsonNode;
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
  var query_601073 = newJObject()
  add(query_601073, "Action", newJString(Action))
  if ResourceArns != nil:
    query_601073.add "ResourceArns", ResourceArns
  if TagKeys != nil:
    query_601073.add "TagKeys", TagKeys
  add(query_601073, "Version", newJString(Version))
  result = call_601072.call(nil, query_601073, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_601057(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_601058,
    base: "/", url: url_GetRemoveTags_601059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetIpAddressType_601109 = ref object of OpenApiRestCall_599368
proc url_PostSetIpAddressType_601111(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetIpAddressType_601110(path: JsonNode; query: JsonNode;
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
  var valid_601112 = query.getOrDefault("Action")
  valid_601112 = validateParameter(valid_601112, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_601112 != nil:
    section.add "Action", valid_601112
  var valid_601113 = query.getOrDefault("Version")
  valid_601113 = validateParameter(valid_601113, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601113 != nil:
    section.add "Version", valid_601113
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
  var valid_601114 = header.getOrDefault("X-Amz-Date")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Date", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Security-Token")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Security-Token", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Content-Sha256", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-Algorithm")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Algorithm", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Signature")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Signature", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-SignedHeaders", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Credential")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Credential", valid_601120
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_601121 = formData.getOrDefault("LoadBalancerArn")
  valid_601121 = validateParameter(valid_601121, JString, required = true,
                                 default = nil)
  if valid_601121 != nil:
    section.add "LoadBalancerArn", valid_601121
  var valid_601122 = formData.getOrDefault("IpAddressType")
  valid_601122 = validateParameter(valid_601122, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_601122 != nil:
    section.add "IpAddressType", valid_601122
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601123: Call_PostSetIpAddressType_601109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_601123.validator(path, query, header, formData, body)
  let scheme = call_601123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601123.url(scheme.get, call_601123.host, call_601123.base,
                         call_601123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601123, url, valid)

proc call*(call_601124: Call_PostSetIpAddressType_601109; LoadBalancerArn: string;
          IpAddressType: string = "ipv4"; Action: string = "SetIpAddressType";
          Version: string = "2015-12-01"): Recallable =
  ## postSetIpAddressType
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   IpAddressType: string (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601125 = newJObject()
  var formData_601126 = newJObject()
  add(formData_601126, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_601126, "IpAddressType", newJString(IpAddressType))
  add(query_601125, "Action", newJString(Action))
  add(query_601125, "Version", newJString(Version))
  result = call_601124.call(nil, query_601125, nil, formData_601126, nil)

var postSetIpAddressType* = Call_PostSetIpAddressType_601109(
    name: "postSetIpAddressType", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_PostSetIpAddressType_601110,
    base: "/", url: url_PostSetIpAddressType_601111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetIpAddressType_601092 = ref object of OpenApiRestCall_599368
proc url_GetSetIpAddressType_601094(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetIpAddressType_601093(path: JsonNode; query: JsonNode;
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
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `IpAddressType` field"
  var valid_601095 = query.getOrDefault("IpAddressType")
  valid_601095 = validateParameter(valid_601095, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_601095 != nil:
    section.add "IpAddressType", valid_601095
  var valid_601096 = query.getOrDefault("Action")
  valid_601096 = validateParameter(valid_601096, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_601096 != nil:
    section.add "Action", valid_601096
  var valid_601097 = query.getOrDefault("LoadBalancerArn")
  valid_601097 = validateParameter(valid_601097, JString, required = true,
                                 default = nil)
  if valid_601097 != nil:
    section.add "LoadBalancerArn", valid_601097
  var valid_601098 = query.getOrDefault("Version")
  valid_601098 = validateParameter(valid_601098, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601098 != nil:
    section.add "Version", valid_601098
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
  var valid_601099 = header.getOrDefault("X-Amz-Date")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Date", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Security-Token")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Security-Token", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Content-Sha256", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-Algorithm")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Algorithm", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Signature")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Signature", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-SignedHeaders", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Credential")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Credential", valid_601105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601106: Call_GetSetIpAddressType_601092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_601106.validator(path, query, header, formData, body)
  let scheme = call_601106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601106.url(scheme.get, call_601106.host, call_601106.base,
                         call_601106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601106, url, valid)

proc call*(call_601107: Call_GetSetIpAddressType_601092; LoadBalancerArn: string;
          IpAddressType: string = "ipv4"; Action: string = "SetIpAddressType";
          Version: string = "2015-12-01"): Recallable =
  ## getSetIpAddressType
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ##   IpAddressType: string (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_601108 = newJObject()
  add(query_601108, "IpAddressType", newJString(IpAddressType))
  add(query_601108, "Action", newJString(Action))
  add(query_601108, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_601108, "Version", newJString(Version))
  result = call_601107.call(nil, query_601108, nil, nil, nil)

var getSetIpAddressType* = Call_GetSetIpAddressType_601092(
    name: "getSetIpAddressType", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_GetSetIpAddressType_601093,
    base: "/", url: url_GetSetIpAddressType_601094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetRulePriorities_601143 = ref object of OpenApiRestCall_599368
proc url_PostSetRulePriorities_601145(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetRulePriorities_601144(path: JsonNode; query: JsonNode;
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
  var valid_601146 = query.getOrDefault("Action")
  valid_601146 = validateParameter(valid_601146, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_601146 != nil:
    section.add "Action", valid_601146
  var valid_601147 = query.getOrDefault("Version")
  valid_601147 = validateParameter(valid_601147, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601147 != nil:
    section.add "Version", valid_601147
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
  var valid_601148 = header.getOrDefault("X-Amz-Date")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Date", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Security-Token")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Security-Token", valid_601149
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
  ## parameters in `formData` object:
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RulePriorities` field"
  var valid_601155 = formData.getOrDefault("RulePriorities")
  valid_601155 = validateParameter(valid_601155, JArray, required = true, default = nil)
  if valid_601155 != nil:
    section.add "RulePriorities", valid_601155
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601156: Call_PostSetRulePriorities_601143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_601156.validator(path, query, header, formData, body)
  let scheme = call_601156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601156.url(scheme.get, call_601156.host, call_601156.base,
                         call_601156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601156, url, valid)

proc call*(call_601157: Call_PostSetRulePriorities_601143;
          RulePriorities: JsonNode; Action: string = "SetRulePriorities";
          Version: string = "2015-12-01"): Recallable =
  ## postSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601158 = newJObject()
  var formData_601159 = newJObject()
  if RulePriorities != nil:
    formData_601159.add "RulePriorities", RulePriorities
  add(query_601158, "Action", newJString(Action))
  add(query_601158, "Version", newJString(Version))
  result = call_601157.call(nil, query_601158, nil, formData_601159, nil)

var postSetRulePriorities* = Call_PostSetRulePriorities_601143(
    name: "postSetRulePriorities", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities",
    validator: validate_PostSetRulePriorities_601144, base: "/",
    url: url_PostSetRulePriorities_601145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetRulePriorities_601127 = ref object of OpenApiRestCall_599368
proc url_GetSetRulePriorities_601129(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetRulePriorities_601128(path: JsonNode; query: JsonNode;
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
  var valid_601130 = query.getOrDefault("RulePriorities")
  valid_601130 = validateParameter(valid_601130, JArray, required = true, default = nil)
  if valid_601130 != nil:
    section.add "RulePriorities", valid_601130
  var valid_601131 = query.getOrDefault("Action")
  valid_601131 = validateParameter(valid_601131, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_601131 != nil:
    section.add "Action", valid_601131
  var valid_601132 = query.getOrDefault("Version")
  valid_601132 = validateParameter(valid_601132, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601132 != nil:
    section.add "Version", valid_601132
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
  var valid_601133 = header.getOrDefault("X-Amz-Date")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Date", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Security-Token")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Security-Token", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Content-Sha256", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Algorithm")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Algorithm", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Signature")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Signature", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-SignedHeaders", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Credential")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Credential", valid_601139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601140: Call_GetSetRulePriorities_601127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_601140.validator(path, query, header, formData, body)
  let scheme = call_601140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601140.url(scheme.get, call_601140.host, call_601140.base,
                         call_601140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601140, url, valid)

proc call*(call_601141: Call_GetSetRulePriorities_601127; RulePriorities: JsonNode;
          Action: string = "SetRulePriorities"; Version: string = "2015-12-01"): Recallable =
  ## getSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601142 = newJObject()
  if RulePriorities != nil:
    query_601142.add "RulePriorities", RulePriorities
  add(query_601142, "Action", newJString(Action))
  add(query_601142, "Version", newJString(Version))
  result = call_601141.call(nil, query_601142, nil, nil, nil)

var getSetRulePriorities* = Call_GetSetRulePriorities_601127(
    name: "getSetRulePriorities", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities", validator: validate_GetSetRulePriorities_601128,
    base: "/", url: url_GetSetRulePriorities_601129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSecurityGroups_601177 = ref object of OpenApiRestCall_599368
proc url_PostSetSecurityGroups_601179(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetSecurityGroups_601178(path: JsonNode; query: JsonNode;
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
  var valid_601180 = query.getOrDefault("Action")
  valid_601180 = validateParameter(valid_601180, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_601180 != nil:
    section.add "Action", valid_601180
  var valid_601181 = query.getOrDefault("Version")
  valid_601181 = validateParameter(valid_601181, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601181 != nil:
    section.add "Version", valid_601181
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
  var valid_601182 = header.getOrDefault("X-Amz-Date")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Date", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Security-Token")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Security-Token", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Content-Sha256", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Algorithm")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Algorithm", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Signature")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Signature", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-SignedHeaders", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Credential")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Credential", valid_601188
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_601189 = formData.getOrDefault("LoadBalancerArn")
  valid_601189 = validateParameter(valid_601189, JString, required = true,
                                 default = nil)
  if valid_601189 != nil:
    section.add "LoadBalancerArn", valid_601189
  var valid_601190 = formData.getOrDefault("SecurityGroups")
  valid_601190 = validateParameter(valid_601190, JArray, required = true, default = nil)
  if valid_601190 != nil:
    section.add "SecurityGroups", valid_601190
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601191: Call_PostSetSecurityGroups_601177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_601191.validator(path, query, header, formData, body)
  let scheme = call_601191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601191.url(scheme.get, call_601191.host, call_601191.base,
                         call_601191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601191, url, valid)

proc call*(call_601192: Call_PostSetSecurityGroups_601177; LoadBalancerArn: string;
          SecurityGroups: JsonNode; Action: string = "SetSecurityGroups";
          Version: string = "2015-12-01"): Recallable =
  ## postSetSecurityGroups
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  ##   Version: string (required)
  var query_601193 = newJObject()
  var formData_601194 = newJObject()
  add(formData_601194, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_601193, "Action", newJString(Action))
  if SecurityGroups != nil:
    formData_601194.add "SecurityGroups", SecurityGroups
  add(query_601193, "Version", newJString(Version))
  result = call_601192.call(nil, query_601193, nil, formData_601194, nil)

var postSetSecurityGroups* = Call_PostSetSecurityGroups_601177(
    name: "postSetSecurityGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups",
    validator: validate_PostSetSecurityGroups_601178, base: "/",
    url: url_PostSetSecurityGroups_601179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSecurityGroups_601160 = ref object of OpenApiRestCall_599368
proc url_GetSetSecurityGroups_601162(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetSecurityGroups_601161(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601163 = query.getOrDefault("Action")
  valid_601163 = validateParameter(valid_601163, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_601163 != nil:
    section.add "Action", valid_601163
  var valid_601164 = query.getOrDefault("LoadBalancerArn")
  valid_601164 = validateParameter(valid_601164, JString, required = true,
                                 default = nil)
  if valid_601164 != nil:
    section.add "LoadBalancerArn", valid_601164
  var valid_601165 = query.getOrDefault("Version")
  valid_601165 = validateParameter(valid_601165, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601165 != nil:
    section.add "Version", valid_601165
  var valid_601166 = query.getOrDefault("SecurityGroups")
  valid_601166 = validateParameter(valid_601166, JArray, required = true, default = nil)
  if valid_601166 != nil:
    section.add "SecurityGroups", valid_601166
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
  var valid_601167 = header.getOrDefault("X-Amz-Date")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Date", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Security-Token")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Security-Token", valid_601168
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
  if body != nil:
    result.add "body", body

proc call*(call_601174: Call_GetSetSecurityGroups_601160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_601174.validator(path, query, header, formData, body)
  let scheme = call_601174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601174.url(scheme.get, call_601174.host, call_601174.base,
                         call_601174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601174, url, valid)

proc call*(call_601175: Call_GetSetSecurityGroups_601160; LoadBalancerArn: string;
          SecurityGroups: JsonNode; Action: string = "SetSecurityGroups";
          Version: string = "2015-12-01"): Recallable =
  ## getSetSecurityGroups
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  var query_601176 = newJObject()
  add(query_601176, "Action", newJString(Action))
  add(query_601176, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_601176, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_601176.add "SecurityGroups", SecurityGroups
  result = call_601175.call(nil, query_601176, nil, nil, nil)

var getSetSecurityGroups* = Call_GetSetSecurityGroups_601160(
    name: "getSetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups", validator: validate_GetSetSecurityGroups_601161,
    base: "/", url: url_GetSetSecurityGroups_601162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubnets_601213 = ref object of OpenApiRestCall_599368
proc url_PostSetSubnets_601215(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetSubnets_601214(path: JsonNode; query: JsonNode;
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
  var valid_601216 = query.getOrDefault("Action")
  valid_601216 = validateParameter(valid_601216, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_601216 != nil:
    section.add "Action", valid_601216
  var valid_601217 = query.getOrDefault("Version")
  valid_601217 = validateParameter(valid_601217, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601217 != nil:
    section.add "Version", valid_601217
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
  var valid_601218 = header.getOrDefault("X-Amz-Date")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Date", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Security-Token")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Security-Token", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Content-Sha256", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Algorithm")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Algorithm", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Signature")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Signature", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-SignedHeaders", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Credential")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Credential", valid_601224
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
  var valid_601225 = formData.getOrDefault("LoadBalancerArn")
  valid_601225 = validateParameter(valid_601225, JString, required = true,
                                 default = nil)
  if valid_601225 != nil:
    section.add "LoadBalancerArn", valid_601225
  var valid_601226 = formData.getOrDefault("Subnets")
  valid_601226 = validateParameter(valid_601226, JArray, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "Subnets", valid_601226
  var valid_601227 = formData.getOrDefault("SubnetMappings")
  valid_601227 = validateParameter(valid_601227, JArray, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "SubnetMappings", valid_601227
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601228: Call_PostSetSubnets_601213; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ## 
  let valid = call_601228.validator(path, query, header, formData, body)
  let scheme = call_601228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601228.url(scheme.get, call_601228.host, call_601228.base,
                         call_601228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601228, url, valid)

proc call*(call_601229: Call_PostSetSubnets_601213; LoadBalancerArn: string;
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
  var query_601230 = newJObject()
  var formData_601231 = newJObject()
  add(formData_601231, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_601230, "Action", newJString(Action))
  if Subnets != nil:
    formData_601231.add "Subnets", Subnets
  if SubnetMappings != nil:
    formData_601231.add "SubnetMappings", SubnetMappings
  add(query_601230, "Version", newJString(Version))
  result = call_601229.call(nil, query_601230, nil, formData_601231, nil)

var postSetSubnets* = Call_PostSetSubnets_601213(name: "postSetSubnets",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_PostSetSubnets_601214,
    base: "/", url: url_PostSetSubnets_601215, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubnets_601195 = ref object of OpenApiRestCall_599368
proc url_GetSetSubnets_601197(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetSubnets_601196(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   Version: JString (required)
  section = newJObject()
  var valid_601198 = query.getOrDefault("SubnetMappings")
  valid_601198 = validateParameter(valid_601198, JArray, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "SubnetMappings", valid_601198
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601199 = query.getOrDefault("Action")
  valid_601199 = validateParameter(valid_601199, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_601199 != nil:
    section.add "Action", valid_601199
  var valid_601200 = query.getOrDefault("LoadBalancerArn")
  valid_601200 = validateParameter(valid_601200, JString, required = true,
                                 default = nil)
  if valid_601200 != nil:
    section.add "LoadBalancerArn", valid_601200
  var valid_601201 = query.getOrDefault("Subnets")
  valid_601201 = validateParameter(valid_601201, JArray, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "Subnets", valid_601201
  var valid_601202 = query.getOrDefault("Version")
  valid_601202 = validateParameter(valid_601202, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601202 != nil:
    section.add "Version", valid_601202
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
  var valid_601203 = header.getOrDefault("X-Amz-Date")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Date", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Security-Token")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Security-Token", valid_601204
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
  if body != nil:
    result.add "body", body

proc call*(call_601210: Call_GetSetSubnets_601195; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ## 
  let valid = call_601210.validator(path, query, header, formData, body)
  let scheme = call_601210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601210.url(scheme.get, call_601210.host, call_601210.base,
                         call_601210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601210, url, valid)

proc call*(call_601211: Call_GetSetSubnets_601195; LoadBalancerArn: string;
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
  var query_601212 = newJObject()
  if SubnetMappings != nil:
    query_601212.add "SubnetMappings", SubnetMappings
  add(query_601212, "Action", newJString(Action))
  add(query_601212, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Subnets != nil:
    query_601212.add "Subnets", Subnets
  add(query_601212, "Version", newJString(Version))
  result = call_601211.call(nil, query_601212, nil, nil, nil)

var getSetSubnets* = Call_GetSetSubnets_601195(name: "getSetSubnets",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_GetSetSubnets_601196,
    base: "/", url: url_GetSetSubnets_601197, schemes: {Scheme.Https, Scheme.Http})
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
