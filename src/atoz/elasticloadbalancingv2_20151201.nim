
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

  OpenApiRestCall_593389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593389): Option[Scheme] {.used.} =
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
  Call_PostAddListenerCertificates_593999 = ref object of OpenApiRestCall_593389
proc url_PostAddListenerCertificates_594001(protocol: Scheme; host: string;
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

proc validate_PostAddListenerCertificates_594000(path: JsonNode; query: JsonNode;
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
  var valid_594002 = query.getOrDefault("Action")
  valid_594002 = validateParameter(valid_594002, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_594002 != nil:
    section.add "Action", valid_594002
  var valid_594003 = query.getOrDefault("Version")
  valid_594003 = validateParameter(valid_594003, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594003 != nil:
    section.add "Version", valid_594003
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
  var valid_594004 = header.getOrDefault("X-Amz-Signature")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Signature", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-Content-Sha256", valid_594005
  var valid_594006 = header.getOrDefault("X-Amz-Date")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "X-Amz-Date", valid_594006
  var valid_594007 = header.getOrDefault("X-Amz-Credential")
  valid_594007 = validateParameter(valid_594007, JString, required = false,
                                 default = nil)
  if valid_594007 != nil:
    section.add "X-Amz-Credential", valid_594007
  var valid_594008 = header.getOrDefault("X-Amz-Security-Token")
  valid_594008 = validateParameter(valid_594008, JString, required = false,
                                 default = nil)
  if valid_594008 != nil:
    section.add "X-Amz-Security-Token", valid_594008
  var valid_594009 = header.getOrDefault("X-Amz-Algorithm")
  valid_594009 = validateParameter(valid_594009, JString, required = false,
                                 default = nil)
  if valid_594009 != nil:
    section.add "X-Amz-Algorithm", valid_594009
  var valid_594010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594010 = validateParameter(valid_594010, JString, required = false,
                                 default = nil)
  if valid_594010 != nil:
    section.add "X-Amz-SignedHeaders", valid_594010
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_594011 = formData.getOrDefault("Certificates")
  valid_594011 = validateParameter(valid_594011, JArray, required = true, default = nil)
  if valid_594011 != nil:
    section.add "Certificates", valid_594011
  var valid_594012 = formData.getOrDefault("ListenerArn")
  valid_594012 = validateParameter(valid_594012, JString, required = true,
                                 default = nil)
  if valid_594012 != nil:
    section.add "ListenerArn", valid_594012
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594013: Call_PostAddListenerCertificates_593999; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594013.validator(path, query, header, formData, body)
  let scheme = call_594013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594013.url(scheme.get, call_594013.host, call_594013.base,
                         call_594013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594013, url, valid)

proc call*(call_594014: Call_PostAddListenerCertificates_593999;
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
  var query_594015 = newJObject()
  var formData_594016 = newJObject()
  if Certificates != nil:
    formData_594016.add "Certificates", Certificates
  add(formData_594016, "ListenerArn", newJString(ListenerArn))
  add(query_594015, "Action", newJString(Action))
  add(query_594015, "Version", newJString(Version))
  result = call_594014.call(nil, query_594015, nil, formData_594016, nil)

var postAddListenerCertificates* = Call_PostAddListenerCertificates_593999(
    name: "postAddListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_PostAddListenerCertificates_594000, base: "/",
    url: url_PostAddListenerCertificates_594001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddListenerCertificates_593727 = ref object of OpenApiRestCall_593389
proc url_GetAddListenerCertificates_593729(protocol: Scheme; host: string;
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

proc validate_GetAddListenerCertificates_593728(path: JsonNode; query: JsonNode;
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
  var valid_593841 = query.getOrDefault("ListenerArn")
  valid_593841 = validateParameter(valid_593841, JString, required = true,
                                 default = nil)
  if valid_593841 != nil:
    section.add "ListenerArn", valid_593841
  var valid_593842 = query.getOrDefault("Certificates")
  valid_593842 = validateParameter(valid_593842, JArray, required = true, default = nil)
  if valid_593842 != nil:
    section.add "Certificates", valid_593842
  var valid_593856 = query.getOrDefault("Action")
  valid_593856 = validateParameter(valid_593856, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_593856 != nil:
    section.add "Action", valid_593856
  var valid_593857 = query.getOrDefault("Version")
  valid_593857 = validateParameter(valid_593857, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593857 != nil:
    section.add "Version", valid_593857
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
  var valid_593858 = header.getOrDefault("X-Amz-Signature")
  valid_593858 = validateParameter(valid_593858, JString, required = false,
                                 default = nil)
  if valid_593858 != nil:
    section.add "X-Amz-Signature", valid_593858
  var valid_593859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593859 = validateParameter(valid_593859, JString, required = false,
                                 default = nil)
  if valid_593859 != nil:
    section.add "X-Amz-Content-Sha256", valid_593859
  var valid_593860 = header.getOrDefault("X-Amz-Date")
  valid_593860 = validateParameter(valid_593860, JString, required = false,
                                 default = nil)
  if valid_593860 != nil:
    section.add "X-Amz-Date", valid_593860
  var valid_593861 = header.getOrDefault("X-Amz-Credential")
  valid_593861 = validateParameter(valid_593861, JString, required = false,
                                 default = nil)
  if valid_593861 != nil:
    section.add "X-Amz-Credential", valid_593861
  var valid_593862 = header.getOrDefault("X-Amz-Security-Token")
  valid_593862 = validateParameter(valid_593862, JString, required = false,
                                 default = nil)
  if valid_593862 != nil:
    section.add "X-Amz-Security-Token", valid_593862
  var valid_593863 = header.getOrDefault("X-Amz-Algorithm")
  valid_593863 = validateParameter(valid_593863, JString, required = false,
                                 default = nil)
  if valid_593863 != nil:
    section.add "X-Amz-Algorithm", valid_593863
  var valid_593864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593864 = validateParameter(valid_593864, JString, required = false,
                                 default = nil)
  if valid_593864 != nil:
    section.add "X-Amz-SignedHeaders", valid_593864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593887: Call_GetAddListenerCertificates_593727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593887.validator(path, query, header, formData, body)
  let scheme = call_593887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593887.url(scheme.get, call_593887.host, call_593887.base,
                         call_593887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593887, url, valid)

proc call*(call_593958: Call_GetAddListenerCertificates_593727;
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
  var query_593959 = newJObject()
  add(query_593959, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_593959.add "Certificates", Certificates
  add(query_593959, "Action", newJString(Action))
  add(query_593959, "Version", newJString(Version))
  result = call_593958.call(nil, query_593959, nil, nil, nil)

var getAddListenerCertificates* = Call_GetAddListenerCertificates_593727(
    name: "getAddListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_GetAddListenerCertificates_593728, base: "/",
    url: url_GetAddListenerCertificates_593729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTags_594034 = ref object of OpenApiRestCall_593389
proc url_PostAddTags_594036(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddTags_594035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594037 = query.getOrDefault("Action")
  valid_594037 = validateParameter(valid_594037, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_594037 != nil:
    section.add "Action", valid_594037
  var valid_594038 = query.getOrDefault("Version")
  valid_594038 = validateParameter(valid_594038, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594038 != nil:
    section.add "Version", valid_594038
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
  var valid_594039 = header.getOrDefault("X-Amz-Signature")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-Signature", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-Content-Sha256", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-Date")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Date", valid_594041
  var valid_594042 = header.getOrDefault("X-Amz-Credential")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "X-Amz-Credential", valid_594042
  var valid_594043 = header.getOrDefault("X-Amz-Security-Token")
  valid_594043 = validateParameter(valid_594043, JString, required = false,
                                 default = nil)
  if valid_594043 != nil:
    section.add "X-Amz-Security-Token", valid_594043
  var valid_594044 = header.getOrDefault("X-Amz-Algorithm")
  valid_594044 = validateParameter(valid_594044, JString, required = false,
                                 default = nil)
  if valid_594044 != nil:
    section.add "X-Amz-Algorithm", valid_594044
  var valid_594045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-SignedHeaders", valid_594045
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_594046 = formData.getOrDefault("ResourceArns")
  valid_594046 = validateParameter(valid_594046, JArray, required = true, default = nil)
  if valid_594046 != nil:
    section.add "ResourceArns", valid_594046
  var valid_594047 = formData.getOrDefault("Tags")
  valid_594047 = validateParameter(valid_594047, JArray, required = true, default = nil)
  if valid_594047 != nil:
    section.add "Tags", valid_594047
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594048: Call_PostAddTags_594034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_594048.validator(path, query, header, formData, body)
  let scheme = call_594048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594048.url(scheme.get, call_594048.host, call_594048.base,
                         call_594048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594048, url, valid)

proc call*(call_594049: Call_PostAddTags_594034; ResourceArns: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2015-12-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Version: string (required)
  var query_594050 = newJObject()
  var formData_594051 = newJObject()
  if ResourceArns != nil:
    formData_594051.add "ResourceArns", ResourceArns
  add(query_594050, "Action", newJString(Action))
  if Tags != nil:
    formData_594051.add "Tags", Tags
  add(query_594050, "Version", newJString(Version))
  result = call_594049.call(nil, query_594050, nil, formData_594051, nil)

var postAddTags* = Call_PostAddTags_594034(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_594035,
                                        base: "/", url: url_PostAddTags_594036,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_594017 = ref object of OpenApiRestCall_593389
proc url_GetAddTags_594019(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAddTags_594018(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594020 = query.getOrDefault("Tags")
  valid_594020 = validateParameter(valid_594020, JArray, required = true, default = nil)
  if valid_594020 != nil:
    section.add "Tags", valid_594020
  var valid_594021 = query.getOrDefault("ResourceArns")
  valid_594021 = validateParameter(valid_594021, JArray, required = true, default = nil)
  if valid_594021 != nil:
    section.add "ResourceArns", valid_594021
  var valid_594022 = query.getOrDefault("Action")
  valid_594022 = validateParameter(valid_594022, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_594022 != nil:
    section.add "Action", valid_594022
  var valid_594023 = query.getOrDefault("Version")
  valid_594023 = validateParameter(valid_594023, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594023 != nil:
    section.add "Version", valid_594023
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
  var valid_594024 = header.getOrDefault("X-Amz-Signature")
  valid_594024 = validateParameter(valid_594024, JString, required = false,
                                 default = nil)
  if valid_594024 != nil:
    section.add "X-Amz-Signature", valid_594024
  var valid_594025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594025 = validateParameter(valid_594025, JString, required = false,
                                 default = nil)
  if valid_594025 != nil:
    section.add "X-Amz-Content-Sha256", valid_594025
  var valid_594026 = header.getOrDefault("X-Amz-Date")
  valid_594026 = validateParameter(valid_594026, JString, required = false,
                                 default = nil)
  if valid_594026 != nil:
    section.add "X-Amz-Date", valid_594026
  var valid_594027 = header.getOrDefault("X-Amz-Credential")
  valid_594027 = validateParameter(valid_594027, JString, required = false,
                                 default = nil)
  if valid_594027 != nil:
    section.add "X-Amz-Credential", valid_594027
  var valid_594028 = header.getOrDefault("X-Amz-Security-Token")
  valid_594028 = validateParameter(valid_594028, JString, required = false,
                                 default = nil)
  if valid_594028 != nil:
    section.add "X-Amz-Security-Token", valid_594028
  var valid_594029 = header.getOrDefault("X-Amz-Algorithm")
  valid_594029 = validateParameter(valid_594029, JString, required = false,
                                 default = nil)
  if valid_594029 != nil:
    section.add "X-Amz-Algorithm", valid_594029
  var valid_594030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594030 = validateParameter(valid_594030, JString, required = false,
                                 default = nil)
  if valid_594030 != nil:
    section.add "X-Amz-SignedHeaders", valid_594030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594031: Call_GetAddTags_594017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_594031.validator(path, query, header, formData, body)
  let scheme = call_594031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594031.url(scheme.get, call_594031.host, call_594031.base,
                         call_594031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594031, url, valid)

proc call*(call_594032: Call_GetAddTags_594017; Tags: JsonNode;
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
  var query_594033 = newJObject()
  if Tags != nil:
    query_594033.add "Tags", Tags
  if ResourceArns != nil:
    query_594033.add "ResourceArns", ResourceArns
  add(query_594033, "Action", newJString(Action))
  add(query_594033, "Version", newJString(Version))
  result = call_594032.call(nil, query_594033, nil, nil, nil)

var getAddTags* = Call_GetAddTags_594017(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_594018,
                                      base: "/", url: url_GetAddTags_594019,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateListener_594073 = ref object of OpenApiRestCall_593389
proc url_PostCreateListener_594075(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateListener_594074(path: JsonNode; query: JsonNode;
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
  var valid_594076 = query.getOrDefault("Action")
  valid_594076 = validateParameter(valid_594076, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_594076 != nil:
    section.add "Action", valid_594076
  var valid_594077 = query.getOrDefault("Version")
  valid_594077 = validateParameter(valid_594077, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594077 != nil:
    section.add "Version", valid_594077
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
  var valid_594078 = header.getOrDefault("X-Amz-Signature")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Signature", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Content-Sha256", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Date")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Date", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Credential")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Credential", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Security-Token")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Security-Token", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Algorithm")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Algorithm", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-SignedHeaders", valid_594084
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
  var valid_594085 = formData.getOrDefault("Port")
  valid_594085 = validateParameter(valid_594085, JInt, required = true, default = nil)
  if valid_594085 != nil:
    section.add "Port", valid_594085
  var valid_594086 = formData.getOrDefault("Certificates")
  valid_594086 = validateParameter(valid_594086, JArray, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "Certificates", valid_594086
  var valid_594087 = formData.getOrDefault("DefaultActions")
  valid_594087 = validateParameter(valid_594087, JArray, required = true, default = nil)
  if valid_594087 != nil:
    section.add "DefaultActions", valid_594087
  var valid_594088 = formData.getOrDefault("Protocol")
  valid_594088 = validateParameter(valid_594088, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_594088 != nil:
    section.add "Protocol", valid_594088
  var valid_594089 = formData.getOrDefault("SslPolicy")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "SslPolicy", valid_594089
  var valid_594090 = formData.getOrDefault("LoadBalancerArn")
  valid_594090 = validateParameter(valid_594090, JString, required = true,
                                 default = nil)
  if valid_594090 != nil:
    section.add "LoadBalancerArn", valid_594090
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594091: Call_PostCreateListener_594073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594091.validator(path, query, header, formData, body)
  let scheme = call_594091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594091.url(scheme.get, call_594091.host, call_594091.base,
                         call_594091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594091, url, valid)

proc call*(call_594092: Call_PostCreateListener_594073; Port: int;
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
  var query_594093 = newJObject()
  var formData_594094 = newJObject()
  add(formData_594094, "Port", newJInt(Port))
  if Certificates != nil:
    formData_594094.add "Certificates", Certificates
  if DefaultActions != nil:
    formData_594094.add "DefaultActions", DefaultActions
  add(formData_594094, "Protocol", newJString(Protocol))
  add(query_594093, "Action", newJString(Action))
  add(formData_594094, "SslPolicy", newJString(SslPolicy))
  add(query_594093, "Version", newJString(Version))
  add(formData_594094, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_594092.call(nil, query_594093, nil, formData_594094, nil)

var postCreateListener* = Call_PostCreateListener_594073(
    name: "postCreateListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=CreateListener",
    validator: validate_PostCreateListener_594074, base: "/",
    url: url_PostCreateListener_594075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateListener_594052 = ref object of OpenApiRestCall_593389
proc url_GetCreateListener_594054(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateListener_594053(path: JsonNode; query: JsonNode;
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
  var valid_594055 = query.getOrDefault("SslPolicy")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "SslPolicy", valid_594055
  var valid_594056 = query.getOrDefault("Certificates")
  valid_594056 = validateParameter(valid_594056, JArray, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "Certificates", valid_594056
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_594057 = query.getOrDefault("LoadBalancerArn")
  valid_594057 = validateParameter(valid_594057, JString, required = true,
                                 default = nil)
  if valid_594057 != nil:
    section.add "LoadBalancerArn", valid_594057
  var valid_594058 = query.getOrDefault("DefaultActions")
  valid_594058 = validateParameter(valid_594058, JArray, required = true, default = nil)
  if valid_594058 != nil:
    section.add "DefaultActions", valid_594058
  var valid_594059 = query.getOrDefault("Action")
  valid_594059 = validateParameter(valid_594059, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_594059 != nil:
    section.add "Action", valid_594059
  var valid_594060 = query.getOrDefault("Protocol")
  valid_594060 = validateParameter(valid_594060, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_594060 != nil:
    section.add "Protocol", valid_594060
  var valid_594061 = query.getOrDefault("Port")
  valid_594061 = validateParameter(valid_594061, JInt, required = true, default = nil)
  if valid_594061 != nil:
    section.add "Port", valid_594061
  var valid_594062 = query.getOrDefault("Version")
  valid_594062 = validateParameter(valid_594062, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594062 != nil:
    section.add "Version", valid_594062
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
  var valid_594063 = header.getOrDefault("X-Amz-Signature")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Signature", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Date")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Date", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Credential")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Credential", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Security-Token")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Security-Token", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Algorithm")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Algorithm", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-SignedHeaders", valid_594069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594070: Call_GetCreateListener_594052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594070.validator(path, query, header, formData, body)
  let scheme = call_594070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594070.url(scheme.get, call_594070.host, call_594070.base,
                         call_594070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594070, url, valid)

proc call*(call_594071: Call_GetCreateListener_594052; LoadBalancerArn: string;
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
  var query_594072 = newJObject()
  add(query_594072, "SslPolicy", newJString(SslPolicy))
  if Certificates != nil:
    query_594072.add "Certificates", Certificates
  add(query_594072, "LoadBalancerArn", newJString(LoadBalancerArn))
  if DefaultActions != nil:
    query_594072.add "DefaultActions", DefaultActions
  add(query_594072, "Action", newJString(Action))
  add(query_594072, "Protocol", newJString(Protocol))
  add(query_594072, "Port", newJInt(Port))
  add(query_594072, "Version", newJString(Version))
  result = call_594071.call(nil, query_594072, nil, nil, nil)

var getCreateListener* = Call_GetCreateListener_594052(name: "getCreateListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateListener", validator: validate_GetCreateListener_594053,
    base: "/", url: url_GetCreateListener_594054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_594118 = ref object of OpenApiRestCall_593389
proc url_PostCreateLoadBalancer_594120(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateLoadBalancer_594119(path: JsonNode; query: JsonNode;
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
  var valid_594121 = query.getOrDefault("Action")
  valid_594121 = validateParameter(valid_594121, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_594121 != nil:
    section.add "Action", valid_594121
  var valid_594122 = query.getOrDefault("Version")
  valid_594122 = validateParameter(valid_594122, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594122 != nil:
    section.add "Version", valid_594122
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
  var valid_594123 = header.getOrDefault("X-Amz-Signature")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Signature", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Content-Sha256", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Date")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Date", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Credential")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Credential", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Security-Token")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Security-Token", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Algorithm")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Algorithm", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-SignedHeaders", valid_594129
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
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your load balancer.</p>
  section = newJObject()
  var valid_594130 = formData.getOrDefault("IpAddressType")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_594130 != nil:
    section.add "IpAddressType", valid_594130
  var valid_594131 = formData.getOrDefault("Scheme")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_594131 != nil:
    section.add "Scheme", valid_594131
  var valid_594132 = formData.getOrDefault("SecurityGroups")
  valid_594132 = validateParameter(valid_594132, JArray, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "SecurityGroups", valid_594132
  var valid_594133 = formData.getOrDefault("Subnets")
  valid_594133 = validateParameter(valid_594133, JArray, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "Subnets", valid_594133
  var valid_594134 = formData.getOrDefault("Type")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = newJString("application"))
  if valid_594134 != nil:
    section.add "Type", valid_594134
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_594135 = formData.getOrDefault("Name")
  valid_594135 = validateParameter(valid_594135, JString, required = true,
                                 default = nil)
  if valid_594135 != nil:
    section.add "Name", valid_594135
  var valid_594136 = formData.getOrDefault("Tags")
  valid_594136 = validateParameter(valid_594136, JArray, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "Tags", valid_594136
  var valid_594137 = formData.getOrDefault("SubnetMappings")
  valid_594137 = validateParameter(valid_594137, JArray, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "SubnetMappings", valid_594137
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594138: Call_PostCreateLoadBalancer_594118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594138.validator(path, query, header, formData, body)
  let scheme = call_594138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594138.url(scheme.get, call_594138.host, call_594138.base,
                         call_594138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594138, url, valid)

proc call*(call_594139: Call_PostCreateLoadBalancer_594118; Name: string;
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
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your load balancer.</p>
  ##   Version: string (required)
  var query_594140 = newJObject()
  var formData_594141 = newJObject()
  add(formData_594141, "IpAddressType", newJString(IpAddressType))
  add(formData_594141, "Scheme", newJString(Scheme))
  if SecurityGroups != nil:
    formData_594141.add "SecurityGroups", SecurityGroups
  if Subnets != nil:
    formData_594141.add "Subnets", Subnets
  add(formData_594141, "Type", newJString(Type))
  add(query_594140, "Action", newJString(Action))
  add(formData_594141, "Name", newJString(Name))
  if Tags != nil:
    formData_594141.add "Tags", Tags
  if SubnetMappings != nil:
    formData_594141.add "SubnetMappings", SubnetMappings
  add(query_594140, "Version", newJString(Version))
  result = call_594139.call(nil, query_594140, nil, formData_594141, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_594118(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_594119, base: "/",
    url: url_PostCreateLoadBalancer_594120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_594095 = ref object of OpenApiRestCall_593389
proc url_GetCreateLoadBalancer_594097(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateLoadBalancer_594096(path: JsonNode; query: JsonNode;
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
  var valid_594098 = query.getOrDefault("SubnetMappings")
  valid_594098 = validateParameter(valid_594098, JArray, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "SubnetMappings", valid_594098
  var valid_594099 = query.getOrDefault("Type")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = newJString("application"))
  if valid_594099 != nil:
    section.add "Type", valid_594099
  var valid_594100 = query.getOrDefault("Tags")
  valid_594100 = validateParameter(valid_594100, JArray, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "Tags", valid_594100
  var valid_594101 = query.getOrDefault("Scheme")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_594101 != nil:
    section.add "Scheme", valid_594101
  var valid_594102 = query.getOrDefault("IpAddressType")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_594102 != nil:
    section.add "IpAddressType", valid_594102
  var valid_594103 = query.getOrDefault("SecurityGroups")
  valid_594103 = validateParameter(valid_594103, JArray, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "SecurityGroups", valid_594103
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_594104 = query.getOrDefault("Name")
  valid_594104 = validateParameter(valid_594104, JString, required = true,
                                 default = nil)
  if valid_594104 != nil:
    section.add "Name", valid_594104
  var valid_594105 = query.getOrDefault("Action")
  valid_594105 = validateParameter(valid_594105, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_594105 != nil:
    section.add "Action", valid_594105
  var valid_594106 = query.getOrDefault("Subnets")
  valid_594106 = validateParameter(valid_594106, JArray, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "Subnets", valid_594106
  var valid_594107 = query.getOrDefault("Version")
  valid_594107 = validateParameter(valid_594107, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594107 != nil:
    section.add "Version", valid_594107
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
  var valid_594108 = header.getOrDefault("X-Amz-Signature")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Signature", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Content-Sha256", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Date")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Date", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Credential")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Credential", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Security-Token")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Security-Token", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Algorithm")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Algorithm", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-SignedHeaders", valid_594114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594115: Call_GetCreateLoadBalancer_594095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594115.validator(path, query, header, formData, body)
  let scheme = call_594115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594115.url(scheme.get, call_594115.host, call_594115.base,
                         call_594115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594115, url, valid)

proc call*(call_594116: Call_GetCreateLoadBalancer_594095; Name: string;
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
  var query_594117 = newJObject()
  if SubnetMappings != nil:
    query_594117.add "SubnetMappings", SubnetMappings
  add(query_594117, "Type", newJString(Type))
  if Tags != nil:
    query_594117.add "Tags", Tags
  add(query_594117, "Scheme", newJString(Scheme))
  add(query_594117, "IpAddressType", newJString(IpAddressType))
  if SecurityGroups != nil:
    query_594117.add "SecurityGroups", SecurityGroups
  add(query_594117, "Name", newJString(Name))
  add(query_594117, "Action", newJString(Action))
  if Subnets != nil:
    query_594117.add "Subnets", Subnets
  add(query_594117, "Version", newJString(Version))
  result = call_594116.call(nil, query_594117, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_594095(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_594096, base: "/",
    url: url_GetCreateLoadBalancer_594097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateRule_594161 = ref object of OpenApiRestCall_593389
proc url_PostCreateRule_594163(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateRule_594162(path: JsonNode; query: JsonNode;
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
  var valid_594164 = query.getOrDefault("Action")
  valid_594164 = validateParameter(valid_594164, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_594164 != nil:
    section.add "Action", valid_594164
  var valid_594165 = query.getOrDefault("Version")
  valid_594165 = validateParameter(valid_594165, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594165 != nil:
    section.add "Version", valid_594165
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
  var valid_594166 = header.getOrDefault("X-Amz-Signature")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Signature", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Content-Sha256", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Date")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Date", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Credential")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Credential", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Security-Token")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Security-Token", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Algorithm")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Algorithm", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-SignedHeaders", valid_594172
  result.add "header", section
  ## parameters in `formData` object:
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Priority: JInt (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Actions` field"
  var valid_594173 = formData.getOrDefault("Actions")
  valid_594173 = validateParameter(valid_594173, JArray, required = true, default = nil)
  if valid_594173 != nil:
    section.add "Actions", valid_594173
  var valid_594174 = formData.getOrDefault("Conditions")
  valid_594174 = validateParameter(valid_594174, JArray, required = true, default = nil)
  if valid_594174 != nil:
    section.add "Conditions", valid_594174
  var valid_594175 = formData.getOrDefault("ListenerArn")
  valid_594175 = validateParameter(valid_594175, JString, required = true,
                                 default = nil)
  if valid_594175 != nil:
    section.add "ListenerArn", valid_594175
  var valid_594176 = formData.getOrDefault("Priority")
  valid_594176 = validateParameter(valid_594176, JInt, required = true, default = nil)
  if valid_594176 != nil:
    section.add "Priority", valid_594176
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594177: Call_PostCreateRule_594161; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_594177.validator(path, query, header, formData, body)
  let scheme = call_594177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594177.url(scheme.get, call_594177.host, call_594177.base,
                         call_594177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594177, url, valid)

proc call*(call_594178: Call_PostCreateRule_594161; Actions: JsonNode;
          Conditions: JsonNode; ListenerArn: string; Priority: int;
          Action: string = "CreateRule"; Version: string = "2015-12-01"): Recallable =
  ## postCreateRule
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Priority: int (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594179 = newJObject()
  var formData_594180 = newJObject()
  if Actions != nil:
    formData_594180.add "Actions", Actions
  if Conditions != nil:
    formData_594180.add "Conditions", Conditions
  add(formData_594180, "ListenerArn", newJString(ListenerArn))
  add(formData_594180, "Priority", newJInt(Priority))
  add(query_594179, "Action", newJString(Action))
  add(query_594179, "Version", newJString(Version))
  result = call_594178.call(nil, query_594179, nil, formData_594180, nil)

var postCreateRule* = Call_PostCreateRule_594161(name: "postCreateRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_PostCreateRule_594162,
    base: "/", url: url_PostCreateRule_594163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateRule_594142 = ref object of OpenApiRestCall_593389
proc url_GetCreateRule_594144(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateRule_594143(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
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
  var valid_594145 = query.getOrDefault("Actions")
  valid_594145 = validateParameter(valid_594145, JArray, required = true, default = nil)
  if valid_594145 != nil:
    section.add "Actions", valid_594145
  var valid_594146 = query.getOrDefault("ListenerArn")
  valid_594146 = validateParameter(valid_594146, JString, required = true,
                                 default = nil)
  if valid_594146 != nil:
    section.add "ListenerArn", valid_594146
  var valid_594147 = query.getOrDefault("Priority")
  valid_594147 = validateParameter(valid_594147, JInt, required = true, default = nil)
  if valid_594147 != nil:
    section.add "Priority", valid_594147
  var valid_594148 = query.getOrDefault("Action")
  valid_594148 = validateParameter(valid_594148, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_594148 != nil:
    section.add "Action", valid_594148
  var valid_594149 = query.getOrDefault("Version")
  valid_594149 = validateParameter(valid_594149, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594149 != nil:
    section.add "Version", valid_594149
  var valid_594150 = query.getOrDefault("Conditions")
  valid_594150 = validateParameter(valid_594150, JArray, required = true, default = nil)
  if valid_594150 != nil:
    section.add "Conditions", valid_594150
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
  var valid_594151 = header.getOrDefault("X-Amz-Signature")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Signature", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Content-Sha256", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Date")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Date", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Credential")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Credential", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Security-Token")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Security-Token", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Algorithm")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Algorithm", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-SignedHeaders", valid_594157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594158: Call_GetCreateRule_594142; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_594158.validator(path, query, header, formData, body)
  let scheme = call_594158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594158.url(scheme.get, call_594158.host, call_594158.base,
                         call_594158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594158, url, valid)

proc call*(call_594159: Call_GetCreateRule_594142; Actions: JsonNode;
          ListenerArn: string; Priority: int; Conditions: JsonNode;
          Action: string = "CreateRule"; Version: string = "2015-12-01"): Recallable =
  ## getCreateRule
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Priority: int (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  var query_594160 = newJObject()
  if Actions != nil:
    query_594160.add "Actions", Actions
  add(query_594160, "ListenerArn", newJString(ListenerArn))
  add(query_594160, "Priority", newJInt(Priority))
  add(query_594160, "Action", newJString(Action))
  add(query_594160, "Version", newJString(Version))
  if Conditions != nil:
    query_594160.add "Conditions", Conditions
  result = call_594159.call(nil, query_594160, nil, nil, nil)

var getCreateRule* = Call_GetCreateRule_594142(name: "getCreateRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_GetCreateRule_594143,
    base: "/", url: url_GetCreateRule_594144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTargetGroup_594210 = ref object of OpenApiRestCall_593389
proc url_PostCreateTargetGroup_594212(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateTargetGroup_594211(path: JsonNode; query: JsonNode;
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
  var valid_594213 = query.getOrDefault("Action")
  valid_594213 = validateParameter(valid_594213, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_594213 != nil:
    section.add "Action", valid_594213
  var valid_594214 = query.getOrDefault("Version")
  valid_594214 = validateParameter(valid_594214, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594214 != nil:
    section.add "Version", valid_594214
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
  var valid_594215 = header.getOrDefault("X-Amz-Signature")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Signature", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Content-Sha256", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-Date")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-Date", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Credential")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Credential", valid_594218
  var valid_594219 = header.getOrDefault("X-Amz-Security-Token")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "X-Amz-Security-Token", valid_594219
  var valid_594220 = header.getOrDefault("X-Amz-Algorithm")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "X-Amz-Algorithm", valid_594220
  var valid_594221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "X-Amz-SignedHeaders", valid_594221
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
  var valid_594222 = formData.getOrDefault("HealthCheckProtocol")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_594222 != nil:
    section.add "HealthCheckProtocol", valid_594222
  var valid_594223 = formData.getOrDefault("Port")
  valid_594223 = validateParameter(valid_594223, JInt, required = false, default = nil)
  if valid_594223 != nil:
    section.add "Port", valid_594223
  var valid_594224 = formData.getOrDefault("HealthCheckPort")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "HealthCheckPort", valid_594224
  var valid_594225 = formData.getOrDefault("VpcId")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "VpcId", valid_594225
  var valid_594226 = formData.getOrDefault("HealthCheckEnabled")
  valid_594226 = validateParameter(valid_594226, JBool, required = false, default = nil)
  if valid_594226 != nil:
    section.add "HealthCheckEnabled", valid_594226
  var valid_594227 = formData.getOrDefault("HealthCheckPath")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "HealthCheckPath", valid_594227
  var valid_594228 = formData.getOrDefault("TargetType")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = newJString("instance"))
  if valid_594228 != nil:
    section.add "TargetType", valid_594228
  var valid_594229 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_594229 = validateParameter(valid_594229, JInt, required = false, default = nil)
  if valid_594229 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_594229
  var valid_594230 = formData.getOrDefault("HealthyThresholdCount")
  valid_594230 = validateParameter(valid_594230, JInt, required = false, default = nil)
  if valid_594230 != nil:
    section.add "HealthyThresholdCount", valid_594230
  var valid_594231 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_594231 = validateParameter(valid_594231, JInt, required = false, default = nil)
  if valid_594231 != nil:
    section.add "HealthCheckIntervalSeconds", valid_594231
  var valid_594232 = formData.getOrDefault("Protocol")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_594232 != nil:
    section.add "Protocol", valid_594232
  var valid_594233 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_594233 = validateParameter(valid_594233, JInt, required = false, default = nil)
  if valid_594233 != nil:
    section.add "UnhealthyThresholdCount", valid_594233
  var valid_594234 = formData.getOrDefault("Matcher.HttpCode")
  valid_594234 = validateParameter(valid_594234, JString, required = false,
                                 default = nil)
  if valid_594234 != nil:
    section.add "Matcher.HttpCode", valid_594234
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_594235 = formData.getOrDefault("Name")
  valid_594235 = validateParameter(valid_594235, JString, required = true,
                                 default = nil)
  if valid_594235 != nil:
    section.add "Name", valid_594235
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594236: Call_PostCreateTargetGroup_594210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594236.validator(path, query, header, formData, body)
  let scheme = call_594236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594236.url(scheme.get, call_594236.host, call_594236.base,
                         call_594236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594236, url, valid)

proc call*(call_594237: Call_PostCreateTargetGroup_594210; Name: string;
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
  var query_594238 = newJObject()
  var formData_594239 = newJObject()
  add(formData_594239, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_594239, "Port", newJInt(Port))
  add(formData_594239, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_594239, "VpcId", newJString(VpcId))
  add(formData_594239, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_594239, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_594239, "TargetType", newJString(TargetType))
  add(formData_594239, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_594239, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_594239, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_594239, "Protocol", newJString(Protocol))
  add(formData_594239, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_594239, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_594238, "Action", newJString(Action))
  add(formData_594239, "Name", newJString(Name))
  add(query_594238, "Version", newJString(Version))
  result = call_594237.call(nil, query_594238, nil, formData_594239, nil)

var postCreateTargetGroup* = Call_PostCreateTargetGroup_594210(
    name: "postCreateTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup",
    validator: validate_PostCreateTargetGroup_594211, base: "/",
    url: url_PostCreateTargetGroup_594212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTargetGroup_594181 = ref object of OpenApiRestCall_593389
proc url_GetCreateTargetGroup_594183(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateTargetGroup_594182(path: JsonNode; query: JsonNode;
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
  var valid_594184 = query.getOrDefault("HealthCheckPort")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "HealthCheckPort", valid_594184
  var valid_594185 = query.getOrDefault("TargetType")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = newJString("instance"))
  if valid_594185 != nil:
    section.add "TargetType", valid_594185
  var valid_594186 = query.getOrDefault("HealthCheckPath")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "HealthCheckPath", valid_594186
  var valid_594187 = query.getOrDefault("VpcId")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "VpcId", valid_594187
  var valid_594188 = query.getOrDefault("HealthCheckProtocol")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_594188 != nil:
    section.add "HealthCheckProtocol", valid_594188
  var valid_594189 = query.getOrDefault("Matcher.HttpCode")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "Matcher.HttpCode", valid_594189
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_594190 = query.getOrDefault("Name")
  valid_594190 = validateParameter(valid_594190, JString, required = true,
                                 default = nil)
  if valid_594190 != nil:
    section.add "Name", valid_594190
  var valid_594191 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_594191 = validateParameter(valid_594191, JInt, required = false, default = nil)
  if valid_594191 != nil:
    section.add "HealthCheckIntervalSeconds", valid_594191
  var valid_594192 = query.getOrDefault("HealthCheckEnabled")
  valid_594192 = validateParameter(valid_594192, JBool, required = false, default = nil)
  if valid_594192 != nil:
    section.add "HealthCheckEnabled", valid_594192
  var valid_594193 = query.getOrDefault("HealthyThresholdCount")
  valid_594193 = validateParameter(valid_594193, JInt, required = false, default = nil)
  if valid_594193 != nil:
    section.add "HealthyThresholdCount", valid_594193
  var valid_594194 = query.getOrDefault("UnhealthyThresholdCount")
  valid_594194 = validateParameter(valid_594194, JInt, required = false, default = nil)
  if valid_594194 != nil:
    section.add "UnhealthyThresholdCount", valid_594194
  var valid_594195 = query.getOrDefault("Action")
  valid_594195 = validateParameter(valid_594195, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_594195 != nil:
    section.add "Action", valid_594195
  var valid_594196 = query.getOrDefault("Protocol")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_594196 != nil:
    section.add "Protocol", valid_594196
  var valid_594197 = query.getOrDefault("Port")
  valid_594197 = validateParameter(valid_594197, JInt, required = false, default = nil)
  if valid_594197 != nil:
    section.add "Port", valid_594197
  var valid_594198 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_594198 = validateParameter(valid_594198, JInt, required = false, default = nil)
  if valid_594198 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_594198
  var valid_594199 = query.getOrDefault("Version")
  valid_594199 = validateParameter(valid_594199, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594199 != nil:
    section.add "Version", valid_594199
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
  var valid_594200 = header.getOrDefault("X-Amz-Signature")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Signature", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Content-Sha256", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-Date")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-Date", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Credential")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Credential", valid_594203
  var valid_594204 = header.getOrDefault("X-Amz-Security-Token")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "X-Amz-Security-Token", valid_594204
  var valid_594205 = header.getOrDefault("X-Amz-Algorithm")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "X-Amz-Algorithm", valid_594205
  var valid_594206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-SignedHeaders", valid_594206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594207: Call_GetCreateTargetGroup_594181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594207.validator(path, query, header, formData, body)
  let scheme = call_594207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594207.url(scheme.get, call_594207.host, call_594207.base,
                         call_594207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594207, url, valid)

proc call*(call_594208: Call_GetCreateTargetGroup_594181; Name: string;
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
  var query_594209 = newJObject()
  add(query_594209, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_594209, "TargetType", newJString(TargetType))
  add(query_594209, "HealthCheckPath", newJString(HealthCheckPath))
  add(query_594209, "VpcId", newJString(VpcId))
  add(query_594209, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_594209, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_594209, "Name", newJString(Name))
  add(query_594209, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_594209, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_594209, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_594209, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_594209, "Action", newJString(Action))
  add(query_594209, "Protocol", newJString(Protocol))
  add(query_594209, "Port", newJInt(Port))
  add(query_594209, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_594209, "Version", newJString(Version))
  result = call_594208.call(nil, query_594209, nil, nil, nil)

var getCreateTargetGroup* = Call_GetCreateTargetGroup_594181(
    name: "getCreateTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup", validator: validate_GetCreateTargetGroup_594182,
    base: "/", url: url_GetCreateTargetGroup_594183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteListener_594256 = ref object of OpenApiRestCall_593389
proc url_PostDeleteListener_594258(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteListener_594257(path: JsonNode; query: JsonNode;
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
  var valid_594259 = query.getOrDefault("Action")
  valid_594259 = validateParameter(valid_594259, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_594259 != nil:
    section.add "Action", valid_594259
  var valid_594260 = query.getOrDefault("Version")
  valid_594260 = validateParameter(valid_594260, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594260 != nil:
    section.add "Version", valid_594260
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
  var valid_594261 = header.getOrDefault("X-Amz-Signature")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Signature", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-Content-Sha256", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Date")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Date", valid_594263
  var valid_594264 = header.getOrDefault("X-Amz-Credential")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-Credential", valid_594264
  var valid_594265 = header.getOrDefault("X-Amz-Security-Token")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Security-Token", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-Algorithm")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Algorithm", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-SignedHeaders", valid_594267
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_594268 = formData.getOrDefault("ListenerArn")
  valid_594268 = validateParameter(valid_594268, JString, required = true,
                                 default = nil)
  if valid_594268 != nil:
    section.add "ListenerArn", valid_594268
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594269: Call_PostDeleteListener_594256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_594269.validator(path, query, header, formData, body)
  let scheme = call_594269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594269.url(scheme.get, call_594269.host, call_594269.base,
                         call_594269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594269, url, valid)

proc call*(call_594270: Call_PostDeleteListener_594256; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594271 = newJObject()
  var formData_594272 = newJObject()
  add(formData_594272, "ListenerArn", newJString(ListenerArn))
  add(query_594271, "Action", newJString(Action))
  add(query_594271, "Version", newJString(Version))
  result = call_594270.call(nil, query_594271, nil, formData_594272, nil)

var postDeleteListener* = Call_PostDeleteListener_594256(
    name: "postDeleteListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=DeleteListener",
    validator: validate_PostDeleteListener_594257, base: "/",
    url: url_PostDeleteListener_594258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteListener_594240 = ref object of OpenApiRestCall_593389
proc url_GetDeleteListener_594242(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteListener_594241(path: JsonNode; query: JsonNode;
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
  var valid_594243 = query.getOrDefault("ListenerArn")
  valid_594243 = validateParameter(valid_594243, JString, required = true,
                                 default = nil)
  if valid_594243 != nil:
    section.add "ListenerArn", valid_594243
  var valid_594244 = query.getOrDefault("Action")
  valid_594244 = validateParameter(valid_594244, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_594244 != nil:
    section.add "Action", valid_594244
  var valid_594245 = query.getOrDefault("Version")
  valid_594245 = validateParameter(valid_594245, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594245 != nil:
    section.add "Version", valid_594245
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
  var valid_594246 = header.getOrDefault("X-Amz-Signature")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Signature", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-Content-Sha256", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-Date")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Date", valid_594248
  var valid_594249 = header.getOrDefault("X-Amz-Credential")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "X-Amz-Credential", valid_594249
  var valid_594250 = header.getOrDefault("X-Amz-Security-Token")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "X-Amz-Security-Token", valid_594250
  var valid_594251 = header.getOrDefault("X-Amz-Algorithm")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-Algorithm", valid_594251
  var valid_594252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-SignedHeaders", valid_594252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594253: Call_GetDeleteListener_594240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_594253.validator(path, query, header, formData, body)
  let scheme = call_594253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594253.url(scheme.get, call_594253.host, call_594253.base,
                         call_594253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594253, url, valid)

proc call*(call_594254: Call_GetDeleteListener_594240; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594255 = newJObject()
  add(query_594255, "ListenerArn", newJString(ListenerArn))
  add(query_594255, "Action", newJString(Action))
  add(query_594255, "Version", newJString(Version))
  result = call_594254.call(nil, query_594255, nil, nil, nil)

var getDeleteListener* = Call_GetDeleteListener_594240(name: "getDeleteListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteListener", validator: validate_GetDeleteListener_594241,
    base: "/", url: url_GetDeleteListener_594242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_594289 = ref object of OpenApiRestCall_593389
proc url_PostDeleteLoadBalancer_594291(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteLoadBalancer_594290(path: JsonNode; query: JsonNode;
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
  var valid_594292 = query.getOrDefault("Action")
  valid_594292 = validateParameter(valid_594292, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_594292 != nil:
    section.add "Action", valid_594292
  var valid_594293 = query.getOrDefault("Version")
  valid_594293 = validateParameter(valid_594293, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594293 != nil:
    section.add "Version", valid_594293
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
  var valid_594294 = header.getOrDefault("X-Amz-Signature")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-Signature", valid_594294
  var valid_594295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "X-Amz-Content-Sha256", valid_594295
  var valid_594296 = header.getOrDefault("X-Amz-Date")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "X-Amz-Date", valid_594296
  var valid_594297 = header.getOrDefault("X-Amz-Credential")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "X-Amz-Credential", valid_594297
  var valid_594298 = header.getOrDefault("X-Amz-Security-Token")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "X-Amz-Security-Token", valid_594298
  var valid_594299 = header.getOrDefault("X-Amz-Algorithm")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-Algorithm", valid_594299
  var valid_594300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "X-Amz-SignedHeaders", valid_594300
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_594301 = formData.getOrDefault("LoadBalancerArn")
  valid_594301 = validateParameter(valid_594301, JString, required = true,
                                 default = nil)
  if valid_594301 != nil:
    section.add "LoadBalancerArn", valid_594301
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594302: Call_PostDeleteLoadBalancer_594289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_594302.validator(path, query, header, formData, body)
  let scheme = call_594302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594302.url(scheme.get, call_594302.host, call_594302.base,
                         call_594302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594302, url, valid)

proc call*(call_594303: Call_PostDeleteLoadBalancer_594289;
          LoadBalancerArn: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2015-12-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_594304 = newJObject()
  var formData_594305 = newJObject()
  add(query_594304, "Action", newJString(Action))
  add(query_594304, "Version", newJString(Version))
  add(formData_594305, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_594303.call(nil, query_594304, nil, formData_594305, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_594289(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_594290, base: "/",
    url: url_PostDeleteLoadBalancer_594291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_594273 = ref object of OpenApiRestCall_593389
proc url_GetDeleteLoadBalancer_594275(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteLoadBalancer_594274(path: JsonNode; query: JsonNode;
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
  var valid_594276 = query.getOrDefault("LoadBalancerArn")
  valid_594276 = validateParameter(valid_594276, JString, required = true,
                                 default = nil)
  if valid_594276 != nil:
    section.add "LoadBalancerArn", valid_594276
  var valid_594277 = query.getOrDefault("Action")
  valid_594277 = validateParameter(valid_594277, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_594277 != nil:
    section.add "Action", valid_594277
  var valid_594278 = query.getOrDefault("Version")
  valid_594278 = validateParameter(valid_594278, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594278 != nil:
    section.add "Version", valid_594278
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
  var valid_594279 = header.getOrDefault("X-Amz-Signature")
  valid_594279 = validateParameter(valid_594279, JString, required = false,
                                 default = nil)
  if valid_594279 != nil:
    section.add "X-Amz-Signature", valid_594279
  var valid_594280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "X-Amz-Content-Sha256", valid_594280
  var valid_594281 = header.getOrDefault("X-Amz-Date")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "X-Amz-Date", valid_594281
  var valid_594282 = header.getOrDefault("X-Amz-Credential")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "X-Amz-Credential", valid_594282
  var valid_594283 = header.getOrDefault("X-Amz-Security-Token")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "X-Amz-Security-Token", valid_594283
  var valid_594284 = header.getOrDefault("X-Amz-Algorithm")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "X-Amz-Algorithm", valid_594284
  var valid_594285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-SignedHeaders", valid_594285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594286: Call_GetDeleteLoadBalancer_594273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_594286.validator(path, query, header, formData, body)
  let scheme = call_594286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594286.url(scheme.get, call_594286.host, call_594286.base,
                         call_594286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594286, url, valid)

proc call*(call_594287: Call_GetDeleteLoadBalancer_594273; LoadBalancerArn: string;
          Action: string = "DeleteLoadBalancer"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594288 = newJObject()
  add(query_594288, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_594288, "Action", newJString(Action))
  add(query_594288, "Version", newJString(Version))
  result = call_594287.call(nil, query_594288, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_594273(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_594274, base: "/",
    url: url_GetDeleteLoadBalancer_594275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRule_594322 = ref object of OpenApiRestCall_593389
proc url_PostDeleteRule_594324(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteRule_594323(path: JsonNode; query: JsonNode;
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
  var valid_594325 = query.getOrDefault("Action")
  valid_594325 = validateParameter(valid_594325, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_594325 != nil:
    section.add "Action", valid_594325
  var valid_594326 = query.getOrDefault("Version")
  valid_594326 = validateParameter(valid_594326, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594326 != nil:
    section.add "Version", valid_594326
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
  var valid_594327 = header.getOrDefault("X-Amz-Signature")
  valid_594327 = validateParameter(valid_594327, JString, required = false,
                                 default = nil)
  if valid_594327 != nil:
    section.add "X-Amz-Signature", valid_594327
  var valid_594328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594328 = validateParameter(valid_594328, JString, required = false,
                                 default = nil)
  if valid_594328 != nil:
    section.add "X-Amz-Content-Sha256", valid_594328
  var valid_594329 = header.getOrDefault("X-Amz-Date")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-Date", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-Credential")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-Credential", valid_594330
  var valid_594331 = header.getOrDefault("X-Amz-Security-Token")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Security-Token", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Algorithm")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Algorithm", valid_594332
  var valid_594333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-SignedHeaders", valid_594333
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_594334 = formData.getOrDefault("RuleArn")
  valid_594334 = validateParameter(valid_594334, JString, required = true,
                                 default = nil)
  if valid_594334 != nil:
    section.add "RuleArn", valid_594334
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594335: Call_PostDeleteRule_594322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_594335.validator(path, query, header, formData, body)
  let scheme = call_594335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594335.url(scheme.get, call_594335.host, call_594335.base,
                         call_594335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594335, url, valid)

proc call*(call_594336: Call_PostDeleteRule_594322; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594337 = newJObject()
  var formData_594338 = newJObject()
  add(formData_594338, "RuleArn", newJString(RuleArn))
  add(query_594337, "Action", newJString(Action))
  add(query_594337, "Version", newJString(Version))
  result = call_594336.call(nil, query_594337, nil, formData_594338, nil)

var postDeleteRule* = Call_PostDeleteRule_594322(name: "postDeleteRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_PostDeleteRule_594323,
    base: "/", url: url_PostDeleteRule_594324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRule_594306 = ref object of OpenApiRestCall_593389
proc url_GetDeleteRule_594308(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteRule_594307(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594309 = query.getOrDefault("RuleArn")
  valid_594309 = validateParameter(valid_594309, JString, required = true,
                                 default = nil)
  if valid_594309 != nil:
    section.add "RuleArn", valid_594309
  var valid_594310 = query.getOrDefault("Action")
  valid_594310 = validateParameter(valid_594310, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_594310 != nil:
    section.add "Action", valid_594310
  var valid_594311 = query.getOrDefault("Version")
  valid_594311 = validateParameter(valid_594311, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594311 != nil:
    section.add "Version", valid_594311
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
  var valid_594312 = header.getOrDefault("X-Amz-Signature")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "X-Amz-Signature", valid_594312
  var valid_594313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "X-Amz-Content-Sha256", valid_594313
  var valid_594314 = header.getOrDefault("X-Amz-Date")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "X-Amz-Date", valid_594314
  var valid_594315 = header.getOrDefault("X-Amz-Credential")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "X-Amz-Credential", valid_594315
  var valid_594316 = header.getOrDefault("X-Amz-Security-Token")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Security-Token", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Algorithm")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Algorithm", valid_594317
  var valid_594318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "X-Amz-SignedHeaders", valid_594318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594319: Call_GetDeleteRule_594306; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_594319.validator(path, query, header, formData, body)
  let scheme = call_594319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594319.url(scheme.get, call_594319.host, call_594319.base,
                         call_594319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594319, url, valid)

proc call*(call_594320: Call_GetDeleteRule_594306; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594321 = newJObject()
  add(query_594321, "RuleArn", newJString(RuleArn))
  add(query_594321, "Action", newJString(Action))
  add(query_594321, "Version", newJString(Version))
  result = call_594320.call(nil, query_594321, nil, nil, nil)

var getDeleteRule* = Call_GetDeleteRule_594306(name: "getDeleteRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_GetDeleteRule_594307,
    base: "/", url: url_GetDeleteRule_594308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTargetGroup_594355 = ref object of OpenApiRestCall_593389
proc url_PostDeleteTargetGroup_594357(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteTargetGroup_594356(path: JsonNode; query: JsonNode;
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
  var valid_594358 = query.getOrDefault("Action")
  valid_594358 = validateParameter(valid_594358, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_594358 != nil:
    section.add "Action", valid_594358
  var valid_594359 = query.getOrDefault("Version")
  valid_594359 = validateParameter(valid_594359, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594359 != nil:
    section.add "Version", valid_594359
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
  var valid_594360 = header.getOrDefault("X-Amz-Signature")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "X-Amz-Signature", valid_594360
  var valid_594361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Content-Sha256", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-Date")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Date", valid_594362
  var valid_594363 = header.getOrDefault("X-Amz-Credential")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-Credential", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Security-Token")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Security-Token", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Algorithm")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Algorithm", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-SignedHeaders", valid_594366
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_594367 = formData.getOrDefault("TargetGroupArn")
  valid_594367 = validateParameter(valid_594367, JString, required = true,
                                 default = nil)
  if valid_594367 != nil:
    section.add "TargetGroupArn", valid_594367
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594368: Call_PostDeleteTargetGroup_594355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_594368.validator(path, query, header, formData, body)
  let scheme = call_594368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594368.url(scheme.get, call_594368.host, call_594368.base,
                         call_594368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594368, url, valid)

proc call*(call_594369: Call_PostDeleteTargetGroup_594355; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_594370 = newJObject()
  var formData_594371 = newJObject()
  add(query_594370, "Action", newJString(Action))
  add(formData_594371, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594370, "Version", newJString(Version))
  result = call_594369.call(nil, query_594370, nil, formData_594371, nil)

var postDeleteTargetGroup* = Call_PostDeleteTargetGroup_594355(
    name: "postDeleteTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup",
    validator: validate_PostDeleteTargetGroup_594356, base: "/",
    url: url_PostDeleteTargetGroup_594357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTargetGroup_594339 = ref object of OpenApiRestCall_593389
proc url_GetDeleteTargetGroup_594341(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteTargetGroup_594340(path: JsonNode; query: JsonNode;
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
  var valid_594342 = query.getOrDefault("TargetGroupArn")
  valid_594342 = validateParameter(valid_594342, JString, required = true,
                                 default = nil)
  if valid_594342 != nil:
    section.add "TargetGroupArn", valid_594342
  var valid_594343 = query.getOrDefault("Action")
  valid_594343 = validateParameter(valid_594343, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_594343 != nil:
    section.add "Action", valid_594343
  var valid_594344 = query.getOrDefault("Version")
  valid_594344 = validateParameter(valid_594344, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594344 != nil:
    section.add "Version", valid_594344
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
  var valid_594345 = header.getOrDefault("X-Amz-Signature")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-Signature", valid_594345
  var valid_594346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Content-Sha256", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Date")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Date", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Credential")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Credential", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Security-Token")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Security-Token", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Algorithm")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Algorithm", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-SignedHeaders", valid_594351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594352: Call_GetDeleteTargetGroup_594339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_594352.validator(path, query, header, formData, body)
  let scheme = call_594352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594352.url(scheme.get, call_594352.host, call_594352.base,
                         call_594352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594352, url, valid)

proc call*(call_594353: Call_GetDeleteTargetGroup_594339; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594354 = newJObject()
  add(query_594354, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594354, "Action", newJString(Action))
  add(query_594354, "Version", newJString(Version))
  result = call_594353.call(nil, query_594354, nil, nil, nil)

var getDeleteTargetGroup* = Call_GetDeleteTargetGroup_594339(
    name: "getDeleteTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup", validator: validate_GetDeleteTargetGroup_594340,
    base: "/", url: url_GetDeleteTargetGroup_594341,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterTargets_594389 = ref object of OpenApiRestCall_593389
proc url_PostDeregisterTargets_594391(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeregisterTargets_594390(path: JsonNode; query: JsonNode;
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
  var valid_594392 = query.getOrDefault("Action")
  valid_594392 = validateParameter(valid_594392, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_594392 != nil:
    section.add "Action", valid_594392
  var valid_594393 = query.getOrDefault("Version")
  valid_594393 = validateParameter(valid_594393, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594393 != nil:
    section.add "Version", valid_594393
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
  var valid_594394 = header.getOrDefault("X-Amz-Signature")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Signature", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Content-Sha256", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Date")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Date", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-Credential")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Credential", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Security-Token")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Security-Token", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-Algorithm")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-Algorithm", valid_594399
  var valid_594400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-SignedHeaders", valid_594400
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_594401 = formData.getOrDefault("Targets")
  valid_594401 = validateParameter(valid_594401, JArray, required = true, default = nil)
  if valid_594401 != nil:
    section.add "Targets", valid_594401
  var valid_594402 = formData.getOrDefault("TargetGroupArn")
  valid_594402 = validateParameter(valid_594402, JString, required = true,
                                 default = nil)
  if valid_594402 != nil:
    section.add "TargetGroupArn", valid_594402
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594403: Call_PostDeregisterTargets_594389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_594403.validator(path, query, header, formData, body)
  let scheme = call_594403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594403.url(scheme.get, call_594403.host, call_594403.base,
                         call_594403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594403, url, valid)

proc call*(call_594404: Call_PostDeregisterTargets_594389; Targets: JsonNode;
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
  var query_594405 = newJObject()
  var formData_594406 = newJObject()
  if Targets != nil:
    formData_594406.add "Targets", Targets
  add(query_594405, "Action", newJString(Action))
  add(formData_594406, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594405, "Version", newJString(Version))
  result = call_594404.call(nil, query_594405, nil, formData_594406, nil)

var postDeregisterTargets* = Call_PostDeregisterTargets_594389(
    name: "postDeregisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets",
    validator: validate_PostDeregisterTargets_594390, base: "/",
    url: url_PostDeregisterTargets_594391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterTargets_594372 = ref object of OpenApiRestCall_593389
proc url_GetDeregisterTargets_594374(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeregisterTargets_594373(path: JsonNode; query: JsonNode;
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
  var valid_594375 = query.getOrDefault("Targets")
  valid_594375 = validateParameter(valid_594375, JArray, required = true, default = nil)
  if valid_594375 != nil:
    section.add "Targets", valid_594375
  var valid_594376 = query.getOrDefault("TargetGroupArn")
  valid_594376 = validateParameter(valid_594376, JString, required = true,
                                 default = nil)
  if valid_594376 != nil:
    section.add "TargetGroupArn", valid_594376
  var valid_594377 = query.getOrDefault("Action")
  valid_594377 = validateParameter(valid_594377, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_594377 != nil:
    section.add "Action", valid_594377
  var valid_594378 = query.getOrDefault("Version")
  valid_594378 = validateParameter(valid_594378, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594378 != nil:
    section.add "Version", valid_594378
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
  var valid_594379 = header.getOrDefault("X-Amz-Signature")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Signature", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Content-Sha256", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Date")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Date", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-Credential")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Credential", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Security-Token")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Security-Token", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-Algorithm")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-Algorithm", valid_594384
  var valid_594385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-SignedHeaders", valid_594385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594386: Call_GetDeregisterTargets_594372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_594386.validator(path, query, header, formData, body)
  let scheme = call_594386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594386.url(scheme.get, call_594386.host, call_594386.base,
                         call_594386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594386, url, valid)

proc call*(call_594387: Call_GetDeregisterTargets_594372; Targets: JsonNode;
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
  var query_594388 = newJObject()
  if Targets != nil:
    query_594388.add "Targets", Targets
  add(query_594388, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594388, "Action", newJString(Action))
  add(query_594388, "Version", newJString(Version))
  result = call_594387.call(nil, query_594388, nil, nil, nil)

var getDeregisterTargets* = Call_GetDeregisterTargets_594372(
    name: "getDeregisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets", validator: validate_GetDeregisterTargets_594373,
    base: "/", url: url_GetDeregisterTargets_594374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_594424 = ref object of OpenApiRestCall_593389
proc url_PostDescribeAccountLimits_594426(protocol: Scheme; host: string;
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

proc validate_PostDescribeAccountLimits_594425(path: JsonNode; query: JsonNode;
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
  var valid_594427 = query.getOrDefault("Action")
  valid_594427 = validateParameter(valid_594427, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_594427 != nil:
    section.add "Action", valid_594427
  var valid_594428 = query.getOrDefault("Version")
  valid_594428 = validateParameter(valid_594428, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594428 != nil:
    section.add "Version", valid_594428
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
  var valid_594429 = header.getOrDefault("X-Amz-Signature")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Signature", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Content-Sha256", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-Date")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-Date", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-Credential")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-Credential", valid_594432
  var valid_594433 = header.getOrDefault("X-Amz-Security-Token")
  valid_594433 = validateParameter(valid_594433, JString, required = false,
                                 default = nil)
  if valid_594433 != nil:
    section.add "X-Amz-Security-Token", valid_594433
  var valid_594434 = header.getOrDefault("X-Amz-Algorithm")
  valid_594434 = validateParameter(valid_594434, JString, required = false,
                                 default = nil)
  if valid_594434 != nil:
    section.add "X-Amz-Algorithm", valid_594434
  var valid_594435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594435 = validateParameter(valid_594435, JString, required = false,
                                 default = nil)
  if valid_594435 != nil:
    section.add "X-Amz-SignedHeaders", valid_594435
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_594436 = formData.getOrDefault("Marker")
  valid_594436 = validateParameter(valid_594436, JString, required = false,
                                 default = nil)
  if valid_594436 != nil:
    section.add "Marker", valid_594436
  var valid_594437 = formData.getOrDefault("PageSize")
  valid_594437 = validateParameter(valid_594437, JInt, required = false, default = nil)
  if valid_594437 != nil:
    section.add "PageSize", valid_594437
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594438: Call_PostDescribeAccountLimits_594424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594438.validator(path, query, header, formData, body)
  let scheme = call_594438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594438.url(scheme.get, call_594438.host, call_594438.base,
                         call_594438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594438, url, valid)

proc call*(call_594439: Call_PostDescribeAccountLimits_594424; Marker: string = "";
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
  var query_594440 = newJObject()
  var formData_594441 = newJObject()
  add(formData_594441, "Marker", newJString(Marker))
  add(query_594440, "Action", newJString(Action))
  add(formData_594441, "PageSize", newJInt(PageSize))
  add(query_594440, "Version", newJString(Version))
  result = call_594439.call(nil, query_594440, nil, formData_594441, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_594424(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_594425, base: "/",
    url: url_PostDescribeAccountLimits_594426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_594407 = ref object of OpenApiRestCall_593389
proc url_GetDescribeAccountLimits_594409(protocol: Scheme; host: string;
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

proc validate_GetDescribeAccountLimits_594408(path: JsonNode; query: JsonNode;
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
  var valid_594410 = query.getOrDefault("Marker")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "Marker", valid_594410
  var valid_594411 = query.getOrDefault("PageSize")
  valid_594411 = validateParameter(valid_594411, JInt, required = false, default = nil)
  if valid_594411 != nil:
    section.add "PageSize", valid_594411
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594412 = query.getOrDefault("Action")
  valid_594412 = validateParameter(valid_594412, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_594412 != nil:
    section.add "Action", valid_594412
  var valid_594413 = query.getOrDefault("Version")
  valid_594413 = validateParameter(valid_594413, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594413 != nil:
    section.add "Version", valid_594413
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
  var valid_594414 = header.getOrDefault("X-Amz-Signature")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Signature", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-Content-Sha256", valid_594415
  var valid_594416 = header.getOrDefault("X-Amz-Date")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "X-Amz-Date", valid_594416
  var valid_594417 = header.getOrDefault("X-Amz-Credential")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-Credential", valid_594417
  var valid_594418 = header.getOrDefault("X-Amz-Security-Token")
  valid_594418 = validateParameter(valid_594418, JString, required = false,
                                 default = nil)
  if valid_594418 != nil:
    section.add "X-Amz-Security-Token", valid_594418
  var valid_594419 = header.getOrDefault("X-Amz-Algorithm")
  valid_594419 = validateParameter(valid_594419, JString, required = false,
                                 default = nil)
  if valid_594419 != nil:
    section.add "X-Amz-Algorithm", valid_594419
  var valid_594420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594420 = validateParameter(valid_594420, JString, required = false,
                                 default = nil)
  if valid_594420 != nil:
    section.add "X-Amz-SignedHeaders", valid_594420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594421: Call_GetDescribeAccountLimits_594407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594421.validator(path, query, header, formData, body)
  let scheme = call_594421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594421.url(scheme.get, call_594421.host, call_594421.base,
                         call_594421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594421, url, valid)

proc call*(call_594422: Call_GetDescribeAccountLimits_594407; Marker: string = "";
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
  var query_594423 = newJObject()
  add(query_594423, "Marker", newJString(Marker))
  add(query_594423, "PageSize", newJInt(PageSize))
  add(query_594423, "Action", newJString(Action))
  add(query_594423, "Version", newJString(Version))
  result = call_594422.call(nil, query_594423, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_594407(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_594408, base: "/",
    url: url_GetDescribeAccountLimits_594409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListenerCertificates_594460 = ref object of OpenApiRestCall_593389
proc url_PostDescribeListenerCertificates_594462(protocol: Scheme; host: string;
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

proc validate_PostDescribeListenerCertificates_594461(path: JsonNode;
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
  var valid_594463 = query.getOrDefault("Action")
  valid_594463 = validateParameter(valid_594463, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_594463 != nil:
    section.add "Action", valid_594463
  var valid_594464 = query.getOrDefault("Version")
  valid_594464 = validateParameter(valid_594464, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594464 != nil:
    section.add "Version", valid_594464
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
  var valid_594465 = header.getOrDefault("X-Amz-Signature")
  valid_594465 = validateParameter(valid_594465, JString, required = false,
                                 default = nil)
  if valid_594465 != nil:
    section.add "X-Amz-Signature", valid_594465
  var valid_594466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594466 = validateParameter(valid_594466, JString, required = false,
                                 default = nil)
  if valid_594466 != nil:
    section.add "X-Amz-Content-Sha256", valid_594466
  var valid_594467 = header.getOrDefault("X-Amz-Date")
  valid_594467 = validateParameter(valid_594467, JString, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "X-Amz-Date", valid_594467
  var valid_594468 = header.getOrDefault("X-Amz-Credential")
  valid_594468 = validateParameter(valid_594468, JString, required = false,
                                 default = nil)
  if valid_594468 != nil:
    section.add "X-Amz-Credential", valid_594468
  var valid_594469 = header.getOrDefault("X-Amz-Security-Token")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "X-Amz-Security-Token", valid_594469
  var valid_594470 = header.getOrDefault("X-Amz-Algorithm")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-Algorithm", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-SignedHeaders", valid_594471
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
  var valid_594472 = formData.getOrDefault("ListenerArn")
  valid_594472 = validateParameter(valid_594472, JString, required = true,
                                 default = nil)
  if valid_594472 != nil:
    section.add "ListenerArn", valid_594472
  var valid_594473 = formData.getOrDefault("Marker")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "Marker", valid_594473
  var valid_594474 = formData.getOrDefault("PageSize")
  valid_594474 = validateParameter(valid_594474, JInt, required = false, default = nil)
  if valid_594474 != nil:
    section.add "PageSize", valid_594474
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594475: Call_PostDescribeListenerCertificates_594460;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594475.validator(path, query, header, formData, body)
  let scheme = call_594475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594475.url(scheme.get, call_594475.host, call_594475.base,
                         call_594475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594475, url, valid)

proc call*(call_594476: Call_PostDescribeListenerCertificates_594460;
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
  var query_594477 = newJObject()
  var formData_594478 = newJObject()
  add(formData_594478, "ListenerArn", newJString(ListenerArn))
  add(formData_594478, "Marker", newJString(Marker))
  add(query_594477, "Action", newJString(Action))
  add(formData_594478, "PageSize", newJInt(PageSize))
  add(query_594477, "Version", newJString(Version))
  result = call_594476.call(nil, query_594477, nil, formData_594478, nil)

var postDescribeListenerCertificates* = Call_PostDescribeListenerCertificates_594460(
    name: "postDescribeListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_PostDescribeListenerCertificates_594461, base: "/",
    url: url_PostDescribeListenerCertificates_594462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListenerCertificates_594442 = ref object of OpenApiRestCall_593389
proc url_GetDescribeListenerCertificates_594444(protocol: Scheme; host: string;
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

proc validate_GetDescribeListenerCertificates_594443(path: JsonNode;
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
  var valid_594445 = query.getOrDefault("Marker")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "Marker", valid_594445
  assert query != nil,
        "query argument is necessary due to required `ListenerArn` field"
  var valid_594446 = query.getOrDefault("ListenerArn")
  valid_594446 = validateParameter(valid_594446, JString, required = true,
                                 default = nil)
  if valid_594446 != nil:
    section.add "ListenerArn", valid_594446
  var valid_594447 = query.getOrDefault("PageSize")
  valid_594447 = validateParameter(valid_594447, JInt, required = false, default = nil)
  if valid_594447 != nil:
    section.add "PageSize", valid_594447
  var valid_594448 = query.getOrDefault("Action")
  valid_594448 = validateParameter(valid_594448, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_594448 != nil:
    section.add "Action", valid_594448
  var valid_594449 = query.getOrDefault("Version")
  valid_594449 = validateParameter(valid_594449, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594449 != nil:
    section.add "Version", valid_594449
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
  var valid_594450 = header.getOrDefault("X-Amz-Signature")
  valid_594450 = validateParameter(valid_594450, JString, required = false,
                                 default = nil)
  if valid_594450 != nil:
    section.add "X-Amz-Signature", valid_594450
  var valid_594451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Content-Sha256", valid_594451
  var valid_594452 = header.getOrDefault("X-Amz-Date")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-Date", valid_594452
  var valid_594453 = header.getOrDefault("X-Amz-Credential")
  valid_594453 = validateParameter(valid_594453, JString, required = false,
                                 default = nil)
  if valid_594453 != nil:
    section.add "X-Amz-Credential", valid_594453
  var valid_594454 = header.getOrDefault("X-Amz-Security-Token")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-Security-Token", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-Algorithm")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Algorithm", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-SignedHeaders", valid_594456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594457: Call_GetDescribeListenerCertificates_594442;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594457.validator(path, query, header, formData, body)
  let scheme = call_594457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594457.url(scheme.get, call_594457.host, call_594457.base,
                         call_594457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594457, url, valid)

proc call*(call_594458: Call_GetDescribeListenerCertificates_594442;
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
  var query_594459 = newJObject()
  add(query_594459, "Marker", newJString(Marker))
  add(query_594459, "ListenerArn", newJString(ListenerArn))
  add(query_594459, "PageSize", newJInt(PageSize))
  add(query_594459, "Action", newJString(Action))
  add(query_594459, "Version", newJString(Version))
  result = call_594458.call(nil, query_594459, nil, nil, nil)

var getDescribeListenerCertificates* = Call_GetDescribeListenerCertificates_594442(
    name: "getDescribeListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_GetDescribeListenerCertificates_594443, base: "/",
    url: url_GetDescribeListenerCertificates_594444,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListeners_594498 = ref object of OpenApiRestCall_593389
proc url_PostDescribeListeners_594500(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeListeners_594499(path: JsonNode; query: JsonNode;
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
  var valid_594501 = query.getOrDefault("Action")
  valid_594501 = validateParameter(valid_594501, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_594501 != nil:
    section.add "Action", valid_594501
  var valid_594502 = query.getOrDefault("Version")
  valid_594502 = validateParameter(valid_594502, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594502 != nil:
    section.add "Version", valid_594502
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
  var valid_594503 = header.getOrDefault("X-Amz-Signature")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Signature", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Content-Sha256", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-Date")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-Date", valid_594505
  var valid_594506 = header.getOrDefault("X-Amz-Credential")
  valid_594506 = validateParameter(valid_594506, JString, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "X-Amz-Credential", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-Security-Token")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Security-Token", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-Algorithm")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-Algorithm", valid_594508
  var valid_594509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594509 = validateParameter(valid_594509, JString, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "X-Amz-SignedHeaders", valid_594509
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
  var valid_594510 = formData.getOrDefault("Marker")
  valid_594510 = validateParameter(valid_594510, JString, required = false,
                                 default = nil)
  if valid_594510 != nil:
    section.add "Marker", valid_594510
  var valid_594511 = formData.getOrDefault("PageSize")
  valid_594511 = validateParameter(valid_594511, JInt, required = false, default = nil)
  if valid_594511 != nil:
    section.add "PageSize", valid_594511
  var valid_594512 = formData.getOrDefault("LoadBalancerArn")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "LoadBalancerArn", valid_594512
  var valid_594513 = formData.getOrDefault("ListenerArns")
  valid_594513 = validateParameter(valid_594513, JArray, required = false,
                                 default = nil)
  if valid_594513 != nil:
    section.add "ListenerArns", valid_594513
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594514: Call_PostDescribeListeners_594498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_594514.validator(path, query, header, formData, body)
  let scheme = call_594514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594514.url(scheme.get, call_594514.host, call_594514.base,
                         call_594514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594514, url, valid)

proc call*(call_594515: Call_PostDescribeListeners_594498; Marker: string = "";
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
  var query_594516 = newJObject()
  var formData_594517 = newJObject()
  add(formData_594517, "Marker", newJString(Marker))
  add(query_594516, "Action", newJString(Action))
  add(formData_594517, "PageSize", newJInt(PageSize))
  add(query_594516, "Version", newJString(Version))
  add(formData_594517, "LoadBalancerArn", newJString(LoadBalancerArn))
  if ListenerArns != nil:
    formData_594517.add "ListenerArns", ListenerArns
  result = call_594515.call(nil, query_594516, nil, formData_594517, nil)

var postDescribeListeners* = Call_PostDescribeListeners_594498(
    name: "postDescribeListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners",
    validator: validate_PostDescribeListeners_594499, base: "/",
    url: url_PostDescribeListeners_594500, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListeners_594479 = ref object of OpenApiRestCall_593389
proc url_GetDescribeListeners_594481(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeListeners_594480(path: JsonNode; query: JsonNode;
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
  var valid_594482 = query.getOrDefault("Marker")
  valid_594482 = validateParameter(valid_594482, JString, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "Marker", valid_594482
  var valid_594483 = query.getOrDefault("LoadBalancerArn")
  valid_594483 = validateParameter(valid_594483, JString, required = false,
                                 default = nil)
  if valid_594483 != nil:
    section.add "LoadBalancerArn", valid_594483
  var valid_594484 = query.getOrDefault("ListenerArns")
  valid_594484 = validateParameter(valid_594484, JArray, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "ListenerArns", valid_594484
  var valid_594485 = query.getOrDefault("PageSize")
  valid_594485 = validateParameter(valid_594485, JInt, required = false, default = nil)
  if valid_594485 != nil:
    section.add "PageSize", valid_594485
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594486 = query.getOrDefault("Action")
  valid_594486 = validateParameter(valid_594486, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_594486 != nil:
    section.add "Action", valid_594486
  var valid_594487 = query.getOrDefault("Version")
  valid_594487 = validateParameter(valid_594487, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594487 != nil:
    section.add "Version", valid_594487
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
  var valid_594488 = header.getOrDefault("X-Amz-Signature")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Signature", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Content-Sha256", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Date")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Date", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-Credential")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-Credential", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-Security-Token")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-Security-Token", valid_594492
  var valid_594493 = header.getOrDefault("X-Amz-Algorithm")
  valid_594493 = validateParameter(valid_594493, JString, required = false,
                                 default = nil)
  if valid_594493 != nil:
    section.add "X-Amz-Algorithm", valid_594493
  var valid_594494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594494 = validateParameter(valid_594494, JString, required = false,
                                 default = nil)
  if valid_594494 != nil:
    section.add "X-Amz-SignedHeaders", valid_594494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594495: Call_GetDescribeListeners_594479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_594495.validator(path, query, header, formData, body)
  let scheme = call_594495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594495.url(scheme.get, call_594495.host, call_594495.base,
                         call_594495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594495, url, valid)

proc call*(call_594496: Call_GetDescribeListeners_594479; Marker: string = "";
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
  var query_594497 = newJObject()
  add(query_594497, "Marker", newJString(Marker))
  add(query_594497, "LoadBalancerArn", newJString(LoadBalancerArn))
  if ListenerArns != nil:
    query_594497.add "ListenerArns", ListenerArns
  add(query_594497, "PageSize", newJInt(PageSize))
  add(query_594497, "Action", newJString(Action))
  add(query_594497, "Version", newJString(Version))
  result = call_594496.call(nil, query_594497, nil, nil, nil)

var getDescribeListeners* = Call_GetDescribeListeners_594479(
    name: "getDescribeListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners", validator: validate_GetDescribeListeners_594480,
    base: "/", url: url_GetDescribeListeners_594481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_594534 = ref object of OpenApiRestCall_593389
proc url_PostDescribeLoadBalancerAttributes_594536(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancerAttributes_594535(path: JsonNode;
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
  var valid_594537 = query.getOrDefault("Action")
  valid_594537 = validateParameter(valid_594537, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_594537 != nil:
    section.add "Action", valid_594537
  var valid_594538 = query.getOrDefault("Version")
  valid_594538 = validateParameter(valid_594538, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594538 != nil:
    section.add "Version", valid_594538
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
  var valid_594539 = header.getOrDefault("X-Amz-Signature")
  valid_594539 = validateParameter(valid_594539, JString, required = false,
                                 default = nil)
  if valid_594539 != nil:
    section.add "X-Amz-Signature", valid_594539
  var valid_594540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594540 = validateParameter(valid_594540, JString, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "X-Amz-Content-Sha256", valid_594540
  var valid_594541 = header.getOrDefault("X-Amz-Date")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-Date", valid_594541
  var valid_594542 = header.getOrDefault("X-Amz-Credential")
  valid_594542 = validateParameter(valid_594542, JString, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "X-Amz-Credential", valid_594542
  var valid_594543 = header.getOrDefault("X-Amz-Security-Token")
  valid_594543 = validateParameter(valid_594543, JString, required = false,
                                 default = nil)
  if valid_594543 != nil:
    section.add "X-Amz-Security-Token", valid_594543
  var valid_594544 = header.getOrDefault("X-Amz-Algorithm")
  valid_594544 = validateParameter(valid_594544, JString, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "X-Amz-Algorithm", valid_594544
  var valid_594545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594545 = validateParameter(valid_594545, JString, required = false,
                                 default = nil)
  if valid_594545 != nil:
    section.add "X-Amz-SignedHeaders", valid_594545
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_594546 = formData.getOrDefault("LoadBalancerArn")
  valid_594546 = validateParameter(valid_594546, JString, required = true,
                                 default = nil)
  if valid_594546 != nil:
    section.add "LoadBalancerArn", valid_594546
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594547: Call_PostDescribeLoadBalancerAttributes_594534;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594547.validator(path, query, header, formData, body)
  let scheme = call_594547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594547.url(scheme.get, call_594547.host, call_594547.base,
                         call_594547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594547, url, valid)

proc call*(call_594548: Call_PostDescribeLoadBalancerAttributes_594534;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_594549 = newJObject()
  var formData_594550 = newJObject()
  add(query_594549, "Action", newJString(Action))
  add(query_594549, "Version", newJString(Version))
  add(formData_594550, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_594548.call(nil, query_594549, nil, formData_594550, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_594534(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_594535, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_594536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_594518 = ref object of OpenApiRestCall_593389
proc url_GetDescribeLoadBalancerAttributes_594520(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancerAttributes_594519(path: JsonNode;
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
  var valid_594521 = query.getOrDefault("LoadBalancerArn")
  valid_594521 = validateParameter(valid_594521, JString, required = true,
                                 default = nil)
  if valid_594521 != nil:
    section.add "LoadBalancerArn", valid_594521
  var valid_594522 = query.getOrDefault("Action")
  valid_594522 = validateParameter(valid_594522, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_594522 != nil:
    section.add "Action", valid_594522
  var valid_594523 = query.getOrDefault("Version")
  valid_594523 = validateParameter(valid_594523, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594523 != nil:
    section.add "Version", valid_594523
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
  var valid_594524 = header.getOrDefault("X-Amz-Signature")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Signature", valid_594524
  var valid_594525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594525 = validateParameter(valid_594525, JString, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "X-Amz-Content-Sha256", valid_594525
  var valid_594526 = header.getOrDefault("X-Amz-Date")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-Date", valid_594526
  var valid_594527 = header.getOrDefault("X-Amz-Credential")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-Credential", valid_594527
  var valid_594528 = header.getOrDefault("X-Amz-Security-Token")
  valid_594528 = validateParameter(valid_594528, JString, required = false,
                                 default = nil)
  if valid_594528 != nil:
    section.add "X-Amz-Security-Token", valid_594528
  var valid_594529 = header.getOrDefault("X-Amz-Algorithm")
  valid_594529 = validateParameter(valid_594529, JString, required = false,
                                 default = nil)
  if valid_594529 != nil:
    section.add "X-Amz-Algorithm", valid_594529
  var valid_594530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594530 = validateParameter(valid_594530, JString, required = false,
                                 default = nil)
  if valid_594530 != nil:
    section.add "X-Amz-SignedHeaders", valid_594530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594531: Call_GetDescribeLoadBalancerAttributes_594518;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594531.validator(path, query, header, formData, body)
  let scheme = call_594531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594531.url(scheme.get, call_594531.host, call_594531.base,
                         call_594531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594531, url, valid)

proc call*(call_594532: Call_GetDescribeLoadBalancerAttributes_594518;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594533 = newJObject()
  add(query_594533, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_594533, "Action", newJString(Action))
  add(query_594533, "Version", newJString(Version))
  result = call_594532.call(nil, query_594533, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_594518(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_594519, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_594520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_594570 = ref object of OpenApiRestCall_593389
proc url_PostDescribeLoadBalancers_594572(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancers_594571(path: JsonNode; query: JsonNode;
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
  var valid_594573 = query.getOrDefault("Action")
  valid_594573 = validateParameter(valid_594573, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_594573 != nil:
    section.add "Action", valid_594573
  var valid_594574 = query.getOrDefault("Version")
  valid_594574 = validateParameter(valid_594574, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594574 != nil:
    section.add "Version", valid_594574
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
  var valid_594575 = header.getOrDefault("X-Amz-Signature")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "X-Amz-Signature", valid_594575
  var valid_594576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-Content-Sha256", valid_594576
  var valid_594577 = header.getOrDefault("X-Amz-Date")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-Date", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-Credential")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Credential", valid_594578
  var valid_594579 = header.getOrDefault("X-Amz-Security-Token")
  valid_594579 = validateParameter(valid_594579, JString, required = false,
                                 default = nil)
  if valid_594579 != nil:
    section.add "X-Amz-Security-Token", valid_594579
  var valid_594580 = header.getOrDefault("X-Amz-Algorithm")
  valid_594580 = validateParameter(valid_594580, JString, required = false,
                                 default = nil)
  if valid_594580 != nil:
    section.add "X-Amz-Algorithm", valid_594580
  var valid_594581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594581 = validateParameter(valid_594581, JString, required = false,
                                 default = nil)
  if valid_594581 != nil:
    section.add "X-Amz-SignedHeaders", valid_594581
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
  var valid_594582 = formData.getOrDefault("Names")
  valid_594582 = validateParameter(valid_594582, JArray, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "Names", valid_594582
  var valid_594583 = formData.getOrDefault("Marker")
  valid_594583 = validateParameter(valid_594583, JString, required = false,
                                 default = nil)
  if valid_594583 != nil:
    section.add "Marker", valid_594583
  var valid_594584 = formData.getOrDefault("PageSize")
  valid_594584 = validateParameter(valid_594584, JInt, required = false, default = nil)
  if valid_594584 != nil:
    section.add "PageSize", valid_594584
  var valid_594585 = formData.getOrDefault("LoadBalancerArns")
  valid_594585 = validateParameter(valid_594585, JArray, required = false,
                                 default = nil)
  if valid_594585 != nil:
    section.add "LoadBalancerArns", valid_594585
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594586: Call_PostDescribeLoadBalancers_594570; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_594586.validator(path, query, header, formData, body)
  let scheme = call_594586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594586.url(scheme.get, call_594586.host, call_594586.base,
                         call_594586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594586, url, valid)

proc call*(call_594587: Call_PostDescribeLoadBalancers_594570;
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
  var query_594588 = newJObject()
  var formData_594589 = newJObject()
  if Names != nil:
    formData_594589.add "Names", Names
  add(formData_594589, "Marker", newJString(Marker))
  add(query_594588, "Action", newJString(Action))
  add(formData_594589, "PageSize", newJInt(PageSize))
  add(query_594588, "Version", newJString(Version))
  if LoadBalancerArns != nil:
    formData_594589.add "LoadBalancerArns", LoadBalancerArns
  result = call_594587.call(nil, query_594588, nil, formData_594589, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_594570(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_594571, base: "/",
    url: url_PostDescribeLoadBalancers_594572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_594551 = ref object of OpenApiRestCall_593389
proc url_GetDescribeLoadBalancers_594553(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancers_594552(path: JsonNode; query: JsonNode;
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
  var valid_594554 = query.getOrDefault("Marker")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "Marker", valid_594554
  var valid_594555 = query.getOrDefault("PageSize")
  valid_594555 = validateParameter(valid_594555, JInt, required = false, default = nil)
  if valid_594555 != nil:
    section.add "PageSize", valid_594555
  var valid_594556 = query.getOrDefault("LoadBalancerArns")
  valid_594556 = validateParameter(valid_594556, JArray, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "LoadBalancerArns", valid_594556
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594557 = query.getOrDefault("Action")
  valid_594557 = validateParameter(valid_594557, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_594557 != nil:
    section.add "Action", valid_594557
  var valid_594558 = query.getOrDefault("Version")
  valid_594558 = validateParameter(valid_594558, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594558 != nil:
    section.add "Version", valid_594558
  var valid_594559 = query.getOrDefault("Names")
  valid_594559 = validateParameter(valid_594559, JArray, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "Names", valid_594559
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
  var valid_594560 = header.getOrDefault("X-Amz-Signature")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-Signature", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-Content-Sha256", valid_594561
  var valid_594562 = header.getOrDefault("X-Amz-Date")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-Date", valid_594562
  var valid_594563 = header.getOrDefault("X-Amz-Credential")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "X-Amz-Credential", valid_594563
  var valid_594564 = header.getOrDefault("X-Amz-Security-Token")
  valid_594564 = validateParameter(valid_594564, JString, required = false,
                                 default = nil)
  if valid_594564 != nil:
    section.add "X-Amz-Security-Token", valid_594564
  var valid_594565 = header.getOrDefault("X-Amz-Algorithm")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "X-Amz-Algorithm", valid_594565
  var valid_594566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "X-Amz-SignedHeaders", valid_594566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594567: Call_GetDescribeLoadBalancers_594551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_594567.validator(path, query, header, formData, body)
  let scheme = call_594567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594567.url(scheme.get, call_594567.host, call_594567.base,
                         call_594567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594567, url, valid)

proc call*(call_594568: Call_GetDescribeLoadBalancers_594551; Marker: string = "";
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
  var query_594569 = newJObject()
  add(query_594569, "Marker", newJString(Marker))
  add(query_594569, "PageSize", newJInt(PageSize))
  if LoadBalancerArns != nil:
    query_594569.add "LoadBalancerArns", LoadBalancerArns
  add(query_594569, "Action", newJString(Action))
  add(query_594569, "Version", newJString(Version))
  if Names != nil:
    query_594569.add "Names", Names
  result = call_594568.call(nil, query_594569, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_594551(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_594552, base: "/",
    url: url_GetDescribeLoadBalancers_594553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRules_594609 = ref object of OpenApiRestCall_593389
proc url_PostDescribeRules_594611(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeRules_594610(path: JsonNode; query: JsonNode;
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
  var valid_594612 = query.getOrDefault("Action")
  valid_594612 = validateParameter(valid_594612, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_594612 != nil:
    section.add "Action", valid_594612
  var valid_594613 = query.getOrDefault("Version")
  valid_594613 = validateParameter(valid_594613, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594613 != nil:
    section.add "Version", valid_594613
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
  var valid_594614 = header.getOrDefault("X-Amz-Signature")
  valid_594614 = validateParameter(valid_594614, JString, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "X-Amz-Signature", valid_594614
  var valid_594615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594615 = validateParameter(valid_594615, JString, required = false,
                                 default = nil)
  if valid_594615 != nil:
    section.add "X-Amz-Content-Sha256", valid_594615
  var valid_594616 = header.getOrDefault("X-Amz-Date")
  valid_594616 = validateParameter(valid_594616, JString, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "X-Amz-Date", valid_594616
  var valid_594617 = header.getOrDefault("X-Amz-Credential")
  valid_594617 = validateParameter(valid_594617, JString, required = false,
                                 default = nil)
  if valid_594617 != nil:
    section.add "X-Amz-Credential", valid_594617
  var valid_594618 = header.getOrDefault("X-Amz-Security-Token")
  valid_594618 = validateParameter(valid_594618, JString, required = false,
                                 default = nil)
  if valid_594618 != nil:
    section.add "X-Amz-Security-Token", valid_594618
  var valid_594619 = header.getOrDefault("X-Amz-Algorithm")
  valid_594619 = validateParameter(valid_594619, JString, required = false,
                                 default = nil)
  if valid_594619 != nil:
    section.add "X-Amz-Algorithm", valid_594619
  var valid_594620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594620 = validateParameter(valid_594620, JString, required = false,
                                 default = nil)
  if valid_594620 != nil:
    section.add "X-Amz-SignedHeaders", valid_594620
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
  var valid_594621 = formData.getOrDefault("ListenerArn")
  valid_594621 = validateParameter(valid_594621, JString, required = false,
                                 default = nil)
  if valid_594621 != nil:
    section.add "ListenerArn", valid_594621
  var valid_594622 = formData.getOrDefault("Marker")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "Marker", valid_594622
  var valid_594623 = formData.getOrDefault("RuleArns")
  valid_594623 = validateParameter(valid_594623, JArray, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "RuleArns", valid_594623
  var valid_594624 = formData.getOrDefault("PageSize")
  valid_594624 = validateParameter(valid_594624, JInt, required = false, default = nil)
  if valid_594624 != nil:
    section.add "PageSize", valid_594624
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594625: Call_PostDescribeRules_594609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_594625.validator(path, query, header, formData, body)
  let scheme = call_594625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594625.url(scheme.get, call_594625.host, call_594625.base,
                         call_594625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594625, url, valid)

proc call*(call_594626: Call_PostDescribeRules_594609; ListenerArn: string = "";
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
  var query_594627 = newJObject()
  var formData_594628 = newJObject()
  add(formData_594628, "ListenerArn", newJString(ListenerArn))
  add(formData_594628, "Marker", newJString(Marker))
  if RuleArns != nil:
    formData_594628.add "RuleArns", RuleArns
  add(query_594627, "Action", newJString(Action))
  add(formData_594628, "PageSize", newJInt(PageSize))
  add(query_594627, "Version", newJString(Version))
  result = call_594626.call(nil, query_594627, nil, formData_594628, nil)

var postDescribeRules* = Call_PostDescribeRules_594609(name: "postDescribeRules",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_PostDescribeRules_594610,
    base: "/", url: url_PostDescribeRules_594611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRules_594590 = ref object of OpenApiRestCall_593389
proc url_GetDescribeRules_594592(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeRules_594591(path: JsonNode; query: JsonNode;
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
  var valid_594593 = query.getOrDefault("Marker")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "Marker", valid_594593
  var valid_594594 = query.getOrDefault("ListenerArn")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "ListenerArn", valid_594594
  var valid_594595 = query.getOrDefault("PageSize")
  valid_594595 = validateParameter(valid_594595, JInt, required = false, default = nil)
  if valid_594595 != nil:
    section.add "PageSize", valid_594595
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594596 = query.getOrDefault("Action")
  valid_594596 = validateParameter(valid_594596, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_594596 != nil:
    section.add "Action", valid_594596
  var valid_594597 = query.getOrDefault("Version")
  valid_594597 = validateParameter(valid_594597, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594597 != nil:
    section.add "Version", valid_594597
  var valid_594598 = query.getOrDefault("RuleArns")
  valid_594598 = validateParameter(valid_594598, JArray, required = false,
                                 default = nil)
  if valid_594598 != nil:
    section.add "RuleArns", valid_594598
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
  var valid_594599 = header.getOrDefault("X-Amz-Signature")
  valid_594599 = validateParameter(valid_594599, JString, required = false,
                                 default = nil)
  if valid_594599 != nil:
    section.add "X-Amz-Signature", valid_594599
  var valid_594600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594600 = validateParameter(valid_594600, JString, required = false,
                                 default = nil)
  if valid_594600 != nil:
    section.add "X-Amz-Content-Sha256", valid_594600
  var valid_594601 = header.getOrDefault("X-Amz-Date")
  valid_594601 = validateParameter(valid_594601, JString, required = false,
                                 default = nil)
  if valid_594601 != nil:
    section.add "X-Amz-Date", valid_594601
  var valid_594602 = header.getOrDefault("X-Amz-Credential")
  valid_594602 = validateParameter(valid_594602, JString, required = false,
                                 default = nil)
  if valid_594602 != nil:
    section.add "X-Amz-Credential", valid_594602
  var valid_594603 = header.getOrDefault("X-Amz-Security-Token")
  valid_594603 = validateParameter(valid_594603, JString, required = false,
                                 default = nil)
  if valid_594603 != nil:
    section.add "X-Amz-Security-Token", valid_594603
  var valid_594604 = header.getOrDefault("X-Amz-Algorithm")
  valid_594604 = validateParameter(valid_594604, JString, required = false,
                                 default = nil)
  if valid_594604 != nil:
    section.add "X-Amz-Algorithm", valid_594604
  var valid_594605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "X-Amz-SignedHeaders", valid_594605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594606: Call_GetDescribeRules_594590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_594606.validator(path, query, header, formData, body)
  let scheme = call_594606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594606.url(scheme.get, call_594606.host, call_594606.base,
                         call_594606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594606, url, valid)

proc call*(call_594607: Call_GetDescribeRules_594590; Marker: string = "";
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
  var query_594608 = newJObject()
  add(query_594608, "Marker", newJString(Marker))
  add(query_594608, "ListenerArn", newJString(ListenerArn))
  add(query_594608, "PageSize", newJInt(PageSize))
  add(query_594608, "Action", newJString(Action))
  add(query_594608, "Version", newJString(Version))
  if RuleArns != nil:
    query_594608.add "RuleArns", RuleArns
  result = call_594607.call(nil, query_594608, nil, nil, nil)

var getDescribeRules* = Call_GetDescribeRules_594590(name: "getDescribeRules",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_GetDescribeRules_594591,
    base: "/", url: url_GetDescribeRules_594592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSSLPolicies_594647 = ref object of OpenApiRestCall_593389
proc url_PostDescribeSSLPolicies_594649(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeSSLPolicies_594648(path: JsonNode; query: JsonNode;
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
  var valid_594650 = query.getOrDefault("Action")
  valid_594650 = validateParameter(valid_594650, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_594650 != nil:
    section.add "Action", valid_594650
  var valid_594651 = query.getOrDefault("Version")
  valid_594651 = validateParameter(valid_594651, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594651 != nil:
    section.add "Version", valid_594651
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
  var valid_594652 = header.getOrDefault("X-Amz-Signature")
  valid_594652 = validateParameter(valid_594652, JString, required = false,
                                 default = nil)
  if valid_594652 != nil:
    section.add "X-Amz-Signature", valid_594652
  var valid_594653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Content-Sha256", valid_594653
  var valid_594654 = header.getOrDefault("X-Amz-Date")
  valid_594654 = validateParameter(valid_594654, JString, required = false,
                                 default = nil)
  if valid_594654 != nil:
    section.add "X-Amz-Date", valid_594654
  var valid_594655 = header.getOrDefault("X-Amz-Credential")
  valid_594655 = validateParameter(valid_594655, JString, required = false,
                                 default = nil)
  if valid_594655 != nil:
    section.add "X-Amz-Credential", valid_594655
  var valid_594656 = header.getOrDefault("X-Amz-Security-Token")
  valid_594656 = validateParameter(valid_594656, JString, required = false,
                                 default = nil)
  if valid_594656 != nil:
    section.add "X-Amz-Security-Token", valid_594656
  var valid_594657 = header.getOrDefault("X-Amz-Algorithm")
  valid_594657 = validateParameter(valid_594657, JString, required = false,
                                 default = nil)
  if valid_594657 != nil:
    section.add "X-Amz-Algorithm", valid_594657
  var valid_594658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "X-Amz-SignedHeaders", valid_594658
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the policies.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_594659 = formData.getOrDefault("Names")
  valid_594659 = validateParameter(valid_594659, JArray, required = false,
                                 default = nil)
  if valid_594659 != nil:
    section.add "Names", valid_594659
  var valid_594660 = formData.getOrDefault("Marker")
  valid_594660 = validateParameter(valid_594660, JString, required = false,
                                 default = nil)
  if valid_594660 != nil:
    section.add "Marker", valid_594660
  var valid_594661 = formData.getOrDefault("PageSize")
  valid_594661 = validateParameter(valid_594661, JInt, required = false, default = nil)
  if valid_594661 != nil:
    section.add "PageSize", valid_594661
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594662: Call_PostDescribeSSLPolicies_594647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594662.validator(path, query, header, formData, body)
  let scheme = call_594662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594662.url(scheme.get, call_594662.host, call_594662.base,
                         call_594662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594662, url, valid)

proc call*(call_594663: Call_PostDescribeSSLPolicies_594647; Names: JsonNode = nil;
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
  var query_594664 = newJObject()
  var formData_594665 = newJObject()
  if Names != nil:
    formData_594665.add "Names", Names
  add(formData_594665, "Marker", newJString(Marker))
  add(query_594664, "Action", newJString(Action))
  add(formData_594665, "PageSize", newJInt(PageSize))
  add(query_594664, "Version", newJString(Version))
  result = call_594663.call(nil, query_594664, nil, formData_594665, nil)

var postDescribeSSLPolicies* = Call_PostDescribeSSLPolicies_594647(
    name: "postDescribeSSLPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_PostDescribeSSLPolicies_594648, base: "/",
    url: url_PostDescribeSSLPolicies_594649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSSLPolicies_594629 = ref object of OpenApiRestCall_593389
proc url_GetDescribeSSLPolicies_594631(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeSSLPolicies_594630(path: JsonNode; query: JsonNode;
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
  var valid_594632 = query.getOrDefault("Marker")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "Marker", valid_594632
  var valid_594633 = query.getOrDefault("PageSize")
  valid_594633 = validateParameter(valid_594633, JInt, required = false, default = nil)
  if valid_594633 != nil:
    section.add "PageSize", valid_594633
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594634 = query.getOrDefault("Action")
  valid_594634 = validateParameter(valid_594634, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_594634 != nil:
    section.add "Action", valid_594634
  var valid_594635 = query.getOrDefault("Version")
  valid_594635 = validateParameter(valid_594635, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594635 != nil:
    section.add "Version", valid_594635
  var valid_594636 = query.getOrDefault("Names")
  valid_594636 = validateParameter(valid_594636, JArray, required = false,
                                 default = nil)
  if valid_594636 != nil:
    section.add "Names", valid_594636
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
  var valid_594637 = header.getOrDefault("X-Amz-Signature")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "X-Amz-Signature", valid_594637
  var valid_594638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-Content-Sha256", valid_594638
  var valid_594639 = header.getOrDefault("X-Amz-Date")
  valid_594639 = validateParameter(valid_594639, JString, required = false,
                                 default = nil)
  if valid_594639 != nil:
    section.add "X-Amz-Date", valid_594639
  var valid_594640 = header.getOrDefault("X-Amz-Credential")
  valid_594640 = validateParameter(valid_594640, JString, required = false,
                                 default = nil)
  if valid_594640 != nil:
    section.add "X-Amz-Credential", valid_594640
  var valid_594641 = header.getOrDefault("X-Amz-Security-Token")
  valid_594641 = validateParameter(valid_594641, JString, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "X-Amz-Security-Token", valid_594641
  var valid_594642 = header.getOrDefault("X-Amz-Algorithm")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "X-Amz-Algorithm", valid_594642
  var valid_594643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "X-Amz-SignedHeaders", valid_594643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594644: Call_GetDescribeSSLPolicies_594629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594644.validator(path, query, header, formData, body)
  let scheme = call_594644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594644.url(scheme.get, call_594644.host, call_594644.base,
                         call_594644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594644, url, valid)

proc call*(call_594645: Call_GetDescribeSSLPolicies_594629; Marker: string = "";
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
  var query_594646 = newJObject()
  add(query_594646, "Marker", newJString(Marker))
  add(query_594646, "PageSize", newJInt(PageSize))
  add(query_594646, "Action", newJString(Action))
  add(query_594646, "Version", newJString(Version))
  if Names != nil:
    query_594646.add "Names", Names
  result = call_594645.call(nil, query_594646, nil, nil, nil)

var getDescribeSSLPolicies* = Call_GetDescribeSSLPolicies_594629(
    name: "getDescribeSSLPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_GetDescribeSSLPolicies_594630, base: "/",
    url: url_GetDescribeSSLPolicies_594631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_594682 = ref object of OpenApiRestCall_593389
proc url_PostDescribeTags_594684(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeTags_594683(path: JsonNode; query: JsonNode;
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
  var valid_594685 = query.getOrDefault("Action")
  valid_594685 = validateParameter(valid_594685, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_594685 != nil:
    section.add "Action", valid_594685
  var valid_594686 = query.getOrDefault("Version")
  valid_594686 = validateParameter(valid_594686, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594686 != nil:
    section.add "Version", valid_594686
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
  var valid_594687 = header.getOrDefault("X-Amz-Signature")
  valid_594687 = validateParameter(valid_594687, JString, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "X-Amz-Signature", valid_594687
  var valid_594688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594688 = validateParameter(valid_594688, JString, required = false,
                                 default = nil)
  if valid_594688 != nil:
    section.add "X-Amz-Content-Sha256", valid_594688
  var valid_594689 = header.getOrDefault("X-Amz-Date")
  valid_594689 = validateParameter(valid_594689, JString, required = false,
                                 default = nil)
  if valid_594689 != nil:
    section.add "X-Amz-Date", valid_594689
  var valid_594690 = header.getOrDefault("X-Amz-Credential")
  valid_594690 = validateParameter(valid_594690, JString, required = false,
                                 default = nil)
  if valid_594690 != nil:
    section.add "X-Amz-Credential", valid_594690
  var valid_594691 = header.getOrDefault("X-Amz-Security-Token")
  valid_594691 = validateParameter(valid_594691, JString, required = false,
                                 default = nil)
  if valid_594691 != nil:
    section.add "X-Amz-Security-Token", valid_594691
  var valid_594692 = header.getOrDefault("X-Amz-Algorithm")
  valid_594692 = validateParameter(valid_594692, JString, required = false,
                                 default = nil)
  if valid_594692 != nil:
    section.add "X-Amz-Algorithm", valid_594692
  var valid_594693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594693 = validateParameter(valid_594693, JString, required = false,
                                 default = nil)
  if valid_594693 != nil:
    section.add "X-Amz-SignedHeaders", valid_594693
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_594694 = formData.getOrDefault("ResourceArns")
  valid_594694 = validateParameter(valid_594694, JArray, required = true, default = nil)
  if valid_594694 != nil:
    section.add "ResourceArns", valid_594694
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594695: Call_PostDescribeTags_594682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_594695.validator(path, query, header, formData, body)
  let scheme = call_594695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594695.url(scheme.get, call_594695.host, call_594695.base,
                         call_594695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594695, url, valid)

proc call*(call_594696: Call_PostDescribeTags_594682; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594697 = newJObject()
  var formData_594698 = newJObject()
  if ResourceArns != nil:
    formData_594698.add "ResourceArns", ResourceArns
  add(query_594697, "Action", newJString(Action))
  add(query_594697, "Version", newJString(Version))
  result = call_594696.call(nil, query_594697, nil, formData_594698, nil)

var postDescribeTags* = Call_PostDescribeTags_594682(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_594683,
    base: "/", url: url_PostDescribeTags_594684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_594666 = ref object of OpenApiRestCall_593389
proc url_GetDescribeTags_594668(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeTags_594667(path: JsonNode; query: JsonNode;
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
  var valid_594669 = query.getOrDefault("ResourceArns")
  valid_594669 = validateParameter(valid_594669, JArray, required = true, default = nil)
  if valid_594669 != nil:
    section.add "ResourceArns", valid_594669
  var valid_594670 = query.getOrDefault("Action")
  valid_594670 = validateParameter(valid_594670, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_594670 != nil:
    section.add "Action", valid_594670
  var valid_594671 = query.getOrDefault("Version")
  valid_594671 = validateParameter(valid_594671, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594671 != nil:
    section.add "Version", valid_594671
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
  var valid_594672 = header.getOrDefault("X-Amz-Signature")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "X-Amz-Signature", valid_594672
  var valid_594673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "X-Amz-Content-Sha256", valid_594673
  var valid_594674 = header.getOrDefault("X-Amz-Date")
  valid_594674 = validateParameter(valid_594674, JString, required = false,
                                 default = nil)
  if valid_594674 != nil:
    section.add "X-Amz-Date", valid_594674
  var valid_594675 = header.getOrDefault("X-Amz-Credential")
  valid_594675 = validateParameter(valid_594675, JString, required = false,
                                 default = nil)
  if valid_594675 != nil:
    section.add "X-Amz-Credential", valid_594675
  var valid_594676 = header.getOrDefault("X-Amz-Security-Token")
  valid_594676 = validateParameter(valid_594676, JString, required = false,
                                 default = nil)
  if valid_594676 != nil:
    section.add "X-Amz-Security-Token", valid_594676
  var valid_594677 = header.getOrDefault("X-Amz-Algorithm")
  valid_594677 = validateParameter(valid_594677, JString, required = false,
                                 default = nil)
  if valid_594677 != nil:
    section.add "X-Amz-Algorithm", valid_594677
  var valid_594678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594678 = validateParameter(valid_594678, JString, required = false,
                                 default = nil)
  if valid_594678 != nil:
    section.add "X-Amz-SignedHeaders", valid_594678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594679: Call_GetDescribeTags_594666; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_594679.validator(path, query, header, formData, body)
  let scheme = call_594679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594679.url(scheme.get, call_594679.host, call_594679.base,
                         call_594679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594679, url, valid)

proc call*(call_594680: Call_GetDescribeTags_594666; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594681 = newJObject()
  if ResourceArns != nil:
    query_594681.add "ResourceArns", ResourceArns
  add(query_594681, "Action", newJString(Action))
  add(query_594681, "Version", newJString(Version))
  result = call_594680.call(nil, query_594681, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_594666(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_594667,
    base: "/", url: url_GetDescribeTags_594668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroupAttributes_594715 = ref object of OpenApiRestCall_593389
proc url_PostDescribeTargetGroupAttributes_594717(protocol: Scheme; host: string;
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

proc validate_PostDescribeTargetGroupAttributes_594716(path: JsonNode;
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
  var valid_594718 = query.getOrDefault("Action")
  valid_594718 = validateParameter(valid_594718, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_594718 != nil:
    section.add "Action", valid_594718
  var valid_594719 = query.getOrDefault("Version")
  valid_594719 = validateParameter(valid_594719, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594719 != nil:
    section.add "Version", valid_594719
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
  var valid_594720 = header.getOrDefault("X-Amz-Signature")
  valid_594720 = validateParameter(valid_594720, JString, required = false,
                                 default = nil)
  if valid_594720 != nil:
    section.add "X-Amz-Signature", valid_594720
  var valid_594721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594721 = validateParameter(valid_594721, JString, required = false,
                                 default = nil)
  if valid_594721 != nil:
    section.add "X-Amz-Content-Sha256", valid_594721
  var valid_594722 = header.getOrDefault("X-Amz-Date")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "X-Amz-Date", valid_594722
  var valid_594723 = header.getOrDefault("X-Amz-Credential")
  valid_594723 = validateParameter(valid_594723, JString, required = false,
                                 default = nil)
  if valid_594723 != nil:
    section.add "X-Amz-Credential", valid_594723
  var valid_594724 = header.getOrDefault("X-Amz-Security-Token")
  valid_594724 = validateParameter(valid_594724, JString, required = false,
                                 default = nil)
  if valid_594724 != nil:
    section.add "X-Amz-Security-Token", valid_594724
  var valid_594725 = header.getOrDefault("X-Amz-Algorithm")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "X-Amz-Algorithm", valid_594725
  var valid_594726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594726 = validateParameter(valid_594726, JString, required = false,
                                 default = nil)
  if valid_594726 != nil:
    section.add "X-Amz-SignedHeaders", valid_594726
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_594727 = formData.getOrDefault("TargetGroupArn")
  valid_594727 = validateParameter(valid_594727, JString, required = true,
                                 default = nil)
  if valid_594727 != nil:
    section.add "TargetGroupArn", valid_594727
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594728: Call_PostDescribeTargetGroupAttributes_594715;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594728.validator(path, query, header, formData, body)
  let scheme = call_594728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594728.url(scheme.get, call_594728.host, call_594728.base,
                         call_594728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594728, url, valid)

proc call*(call_594729: Call_PostDescribeTargetGroupAttributes_594715;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_594730 = newJObject()
  var formData_594731 = newJObject()
  add(query_594730, "Action", newJString(Action))
  add(formData_594731, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594730, "Version", newJString(Version))
  result = call_594729.call(nil, query_594730, nil, formData_594731, nil)

var postDescribeTargetGroupAttributes* = Call_PostDescribeTargetGroupAttributes_594715(
    name: "postDescribeTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_PostDescribeTargetGroupAttributes_594716, base: "/",
    url: url_PostDescribeTargetGroupAttributes_594717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroupAttributes_594699 = ref object of OpenApiRestCall_593389
proc url_GetDescribeTargetGroupAttributes_594701(protocol: Scheme; host: string;
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

proc validate_GetDescribeTargetGroupAttributes_594700(path: JsonNode;
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
  var valid_594702 = query.getOrDefault("TargetGroupArn")
  valid_594702 = validateParameter(valid_594702, JString, required = true,
                                 default = nil)
  if valid_594702 != nil:
    section.add "TargetGroupArn", valid_594702
  var valid_594703 = query.getOrDefault("Action")
  valid_594703 = validateParameter(valid_594703, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_594703 != nil:
    section.add "Action", valid_594703
  var valid_594704 = query.getOrDefault("Version")
  valid_594704 = validateParameter(valid_594704, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594704 != nil:
    section.add "Version", valid_594704
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
  var valid_594705 = header.getOrDefault("X-Amz-Signature")
  valid_594705 = validateParameter(valid_594705, JString, required = false,
                                 default = nil)
  if valid_594705 != nil:
    section.add "X-Amz-Signature", valid_594705
  var valid_594706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594706 = validateParameter(valid_594706, JString, required = false,
                                 default = nil)
  if valid_594706 != nil:
    section.add "X-Amz-Content-Sha256", valid_594706
  var valid_594707 = header.getOrDefault("X-Amz-Date")
  valid_594707 = validateParameter(valid_594707, JString, required = false,
                                 default = nil)
  if valid_594707 != nil:
    section.add "X-Amz-Date", valid_594707
  var valid_594708 = header.getOrDefault("X-Amz-Credential")
  valid_594708 = validateParameter(valid_594708, JString, required = false,
                                 default = nil)
  if valid_594708 != nil:
    section.add "X-Amz-Credential", valid_594708
  var valid_594709 = header.getOrDefault("X-Amz-Security-Token")
  valid_594709 = validateParameter(valid_594709, JString, required = false,
                                 default = nil)
  if valid_594709 != nil:
    section.add "X-Amz-Security-Token", valid_594709
  var valid_594710 = header.getOrDefault("X-Amz-Algorithm")
  valid_594710 = validateParameter(valid_594710, JString, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "X-Amz-Algorithm", valid_594710
  var valid_594711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594711 = validateParameter(valid_594711, JString, required = false,
                                 default = nil)
  if valid_594711 != nil:
    section.add "X-Amz-SignedHeaders", valid_594711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594712: Call_GetDescribeTargetGroupAttributes_594699;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594712.validator(path, query, header, formData, body)
  let scheme = call_594712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594712.url(scheme.get, call_594712.host, call_594712.base,
                         call_594712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594712, url, valid)

proc call*(call_594713: Call_GetDescribeTargetGroupAttributes_594699;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594714 = newJObject()
  add(query_594714, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594714, "Action", newJString(Action))
  add(query_594714, "Version", newJString(Version))
  result = call_594713.call(nil, query_594714, nil, nil, nil)

var getDescribeTargetGroupAttributes* = Call_GetDescribeTargetGroupAttributes_594699(
    name: "getDescribeTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_GetDescribeTargetGroupAttributes_594700, base: "/",
    url: url_GetDescribeTargetGroupAttributes_594701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroups_594752 = ref object of OpenApiRestCall_593389
proc url_PostDescribeTargetGroups_594754(protocol: Scheme; host: string;
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

proc validate_PostDescribeTargetGroups_594753(path: JsonNode; query: JsonNode;
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
  var valid_594755 = query.getOrDefault("Action")
  valid_594755 = validateParameter(valid_594755, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_594755 != nil:
    section.add "Action", valid_594755
  var valid_594756 = query.getOrDefault("Version")
  valid_594756 = validateParameter(valid_594756, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594756 != nil:
    section.add "Version", valid_594756
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
  var valid_594757 = header.getOrDefault("X-Amz-Signature")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "X-Amz-Signature", valid_594757
  var valid_594758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "X-Amz-Content-Sha256", valid_594758
  var valid_594759 = header.getOrDefault("X-Amz-Date")
  valid_594759 = validateParameter(valid_594759, JString, required = false,
                                 default = nil)
  if valid_594759 != nil:
    section.add "X-Amz-Date", valid_594759
  var valid_594760 = header.getOrDefault("X-Amz-Credential")
  valid_594760 = validateParameter(valid_594760, JString, required = false,
                                 default = nil)
  if valid_594760 != nil:
    section.add "X-Amz-Credential", valid_594760
  var valid_594761 = header.getOrDefault("X-Amz-Security-Token")
  valid_594761 = validateParameter(valid_594761, JString, required = false,
                                 default = nil)
  if valid_594761 != nil:
    section.add "X-Amz-Security-Token", valid_594761
  var valid_594762 = header.getOrDefault("X-Amz-Algorithm")
  valid_594762 = validateParameter(valid_594762, JString, required = false,
                                 default = nil)
  if valid_594762 != nil:
    section.add "X-Amz-Algorithm", valid_594762
  var valid_594763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594763 = validateParameter(valid_594763, JString, required = false,
                                 default = nil)
  if valid_594763 != nil:
    section.add "X-Amz-SignedHeaders", valid_594763
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
  var valid_594764 = formData.getOrDefault("Names")
  valid_594764 = validateParameter(valid_594764, JArray, required = false,
                                 default = nil)
  if valid_594764 != nil:
    section.add "Names", valid_594764
  var valid_594765 = formData.getOrDefault("Marker")
  valid_594765 = validateParameter(valid_594765, JString, required = false,
                                 default = nil)
  if valid_594765 != nil:
    section.add "Marker", valid_594765
  var valid_594766 = formData.getOrDefault("TargetGroupArns")
  valid_594766 = validateParameter(valid_594766, JArray, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "TargetGroupArns", valid_594766
  var valid_594767 = formData.getOrDefault("PageSize")
  valid_594767 = validateParameter(valid_594767, JInt, required = false, default = nil)
  if valid_594767 != nil:
    section.add "PageSize", valid_594767
  var valid_594768 = formData.getOrDefault("LoadBalancerArn")
  valid_594768 = validateParameter(valid_594768, JString, required = false,
                                 default = nil)
  if valid_594768 != nil:
    section.add "LoadBalancerArn", valid_594768
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594769: Call_PostDescribeTargetGroups_594752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_594769.validator(path, query, header, formData, body)
  let scheme = call_594769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594769.url(scheme.get, call_594769.host, call_594769.base,
                         call_594769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594769, url, valid)

proc call*(call_594770: Call_PostDescribeTargetGroups_594752;
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
  var query_594771 = newJObject()
  var formData_594772 = newJObject()
  if Names != nil:
    formData_594772.add "Names", Names
  add(formData_594772, "Marker", newJString(Marker))
  add(query_594771, "Action", newJString(Action))
  if TargetGroupArns != nil:
    formData_594772.add "TargetGroupArns", TargetGroupArns
  add(formData_594772, "PageSize", newJInt(PageSize))
  add(query_594771, "Version", newJString(Version))
  add(formData_594772, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_594770.call(nil, query_594771, nil, formData_594772, nil)

var postDescribeTargetGroups* = Call_PostDescribeTargetGroups_594752(
    name: "postDescribeTargetGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_PostDescribeTargetGroups_594753, base: "/",
    url: url_PostDescribeTargetGroups_594754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroups_594732 = ref object of OpenApiRestCall_593389
proc url_GetDescribeTargetGroups_594734(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeTargetGroups_594733(path: JsonNode; query: JsonNode;
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
  var valid_594735 = query.getOrDefault("Marker")
  valid_594735 = validateParameter(valid_594735, JString, required = false,
                                 default = nil)
  if valid_594735 != nil:
    section.add "Marker", valid_594735
  var valid_594736 = query.getOrDefault("LoadBalancerArn")
  valid_594736 = validateParameter(valid_594736, JString, required = false,
                                 default = nil)
  if valid_594736 != nil:
    section.add "LoadBalancerArn", valid_594736
  var valid_594737 = query.getOrDefault("PageSize")
  valid_594737 = validateParameter(valid_594737, JInt, required = false, default = nil)
  if valid_594737 != nil:
    section.add "PageSize", valid_594737
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594738 = query.getOrDefault("Action")
  valid_594738 = validateParameter(valid_594738, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_594738 != nil:
    section.add "Action", valid_594738
  var valid_594739 = query.getOrDefault("TargetGroupArns")
  valid_594739 = validateParameter(valid_594739, JArray, required = false,
                                 default = nil)
  if valid_594739 != nil:
    section.add "TargetGroupArns", valid_594739
  var valid_594740 = query.getOrDefault("Version")
  valid_594740 = validateParameter(valid_594740, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594740 != nil:
    section.add "Version", valid_594740
  var valid_594741 = query.getOrDefault("Names")
  valid_594741 = validateParameter(valid_594741, JArray, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "Names", valid_594741
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
  var valid_594742 = header.getOrDefault("X-Amz-Signature")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "X-Amz-Signature", valid_594742
  var valid_594743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Content-Sha256", valid_594743
  var valid_594744 = header.getOrDefault("X-Amz-Date")
  valid_594744 = validateParameter(valid_594744, JString, required = false,
                                 default = nil)
  if valid_594744 != nil:
    section.add "X-Amz-Date", valid_594744
  var valid_594745 = header.getOrDefault("X-Amz-Credential")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "X-Amz-Credential", valid_594745
  var valid_594746 = header.getOrDefault("X-Amz-Security-Token")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "X-Amz-Security-Token", valid_594746
  var valid_594747 = header.getOrDefault("X-Amz-Algorithm")
  valid_594747 = validateParameter(valid_594747, JString, required = false,
                                 default = nil)
  if valid_594747 != nil:
    section.add "X-Amz-Algorithm", valid_594747
  var valid_594748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594748 = validateParameter(valid_594748, JString, required = false,
                                 default = nil)
  if valid_594748 != nil:
    section.add "X-Amz-SignedHeaders", valid_594748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594749: Call_GetDescribeTargetGroups_594732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_594749.validator(path, query, header, formData, body)
  let scheme = call_594749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594749.url(scheme.get, call_594749.host, call_594749.base,
                         call_594749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594749, url, valid)

proc call*(call_594750: Call_GetDescribeTargetGroups_594732; Marker: string = "";
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
  var query_594751 = newJObject()
  add(query_594751, "Marker", newJString(Marker))
  add(query_594751, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_594751, "PageSize", newJInt(PageSize))
  add(query_594751, "Action", newJString(Action))
  if TargetGroupArns != nil:
    query_594751.add "TargetGroupArns", TargetGroupArns
  add(query_594751, "Version", newJString(Version))
  if Names != nil:
    query_594751.add "Names", Names
  result = call_594750.call(nil, query_594751, nil, nil, nil)

var getDescribeTargetGroups* = Call_GetDescribeTargetGroups_594732(
    name: "getDescribeTargetGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_GetDescribeTargetGroups_594733, base: "/",
    url: url_GetDescribeTargetGroups_594734, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetHealth_594790 = ref object of OpenApiRestCall_593389
proc url_PostDescribeTargetHealth_594792(protocol: Scheme; host: string;
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

proc validate_PostDescribeTargetHealth_594791(path: JsonNode; query: JsonNode;
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
  var valid_594793 = query.getOrDefault("Action")
  valid_594793 = validateParameter(valid_594793, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_594793 != nil:
    section.add "Action", valid_594793
  var valid_594794 = query.getOrDefault("Version")
  valid_594794 = validateParameter(valid_594794, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594794 != nil:
    section.add "Version", valid_594794
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
  var valid_594795 = header.getOrDefault("X-Amz-Signature")
  valid_594795 = validateParameter(valid_594795, JString, required = false,
                                 default = nil)
  if valid_594795 != nil:
    section.add "X-Amz-Signature", valid_594795
  var valid_594796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "X-Amz-Content-Sha256", valid_594796
  var valid_594797 = header.getOrDefault("X-Amz-Date")
  valid_594797 = validateParameter(valid_594797, JString, required = false,
                                 default = nil)
  if valid_594797 != nil:
    section.add "X-Amz-Date", valid_594797
  var valid_594798 = header.getOrDefault("X-Amz-Credential")
  valid_594798 = validateParameter(valid_594798, JString, required = false,
                                 default = nil)
  if valid_594798 != nil:
    section.add "X-Amz-Credential", valid_594798
  var valid_594799 = header.getOrDefault("X-Amz-Security-Token")
  valid_594799 = validateParameter(valid_594799, JString, required = false,
                                 default = nil)
  if valid_594799 != nil:
    section.add "X-Amz-Security-Token", valid_594799
  var valid_594800 = header.getOrDefault("X-Amz-Algorithm")
  valid_594800 = validateParameter(valid_594800, JString, required = false,
                                 default = nil)
  if valid_594800 != nil:
    section.add "X-Amz-Algorithm", valid_594800
  var valid_594801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594801 = validateParameter(valid_594801, JString, required = false,
                                 default = nil)
  if valid_594801 != nil:
    section.add "X-Amz-SignedHeaders", valid_594801
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_594802 = formData.getOrDefault("Targets")
  valid_594802 = validateParameter(valid_594802, JArray, required = false,
                                 default = nil)
  if valid_594802 != nil:
    section.add "Targets", valid_594802
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_594803 = formData.getOrDefault("TargetGroupArn")
  valid_594803 = validateParameter(valid_594803, JString, required = true,
                                 default = nil)
  if valid_594803 != nil:
    section.add "TargetGroupArn", valid_594803
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594804: Call_PostDescribeTargetHealth_594790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_594804.validator(path, query, header, formData, body)
  let scheme = call_594804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594804.url(scheme.get, call_594804.host, call_594804.base,
                         call_594804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594804, url, valid)

proc call*(call_594805: Call_PostDescribeTargetHealth_594790;
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
  var query_594806 = newJObject()
  var formData_594807 = newJObject()
  if Targets != nil:
    formData_594807.add "Targets", Targets
  add(query_594806, "Action", newJString(Action))
  add(formData_594807, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594806, "Version", newJString(Version))
  result = call_594805.call(nil, query_594806, nil, formData_594807, nil)

var postDescribeTargetHealth* = Call_PostDescribeTargetHealth_594790(
    name: "postDescribeTargetHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_PostDescribeTargetHealth_594791, base: "/",
    url: url_PostDescribeTargetHealth_594792, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetHealth_594773 = ref object of OpenApiRestCall_593389
proc url_GetDescribeTargetHealth_594775(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeTargetHealth_594774(path: JsonNode; query: JsonNode;
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
  var valid_594776 = query.getOrDefault("Targets")
  valid_594776 = validateParameter(valid_594776, JArray, required = false,
                                 default = nil)
  if valid_594776 != nil:
    section.add "Targets", valid_594776
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_594777 = query.getOrDefault("TargetGroupArn")
  valid_594777 = validateParameter(valid_594777, JString, required = true,
                                 default = nil)
  if valid_594777 != nil:
    section.add "TargetGroupArn", valid_594777
  var valid_594778 = query.getOrDefault("Action")
  valid_594778 = validateParameter(valid_594778, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_594778 != nil:
    section.add "Action", valid_594778
  var valid_594779 = query.getOrDefault("Version")
  valid_594779 = validateParameter(valid_594779, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594779 != nil:
    section.add "Version", valid_594779
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
  var valid_594780 = header.getOrDefault("X-Amz-Signature")
  valid_594780 = validateParameter(valid_594780, JString, required = false,
                                 default = nil)
  if valid_594780 != nil:
    section.add "X-Amz-Signature", valid_594780
  var valid_594781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-Content-Sha256", valid_594781
  var valid_594782 = header.getOrDefault("X-Amz-Date")
  valid_594782 = validateParameter(valid_594782, JString, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "X-Amz-Date", valid_594782
  var valid_594783 = header.getOrDefault("X-Amz-Credential")
  valid_594783 = validateParameter(valid_594783, JString, required = false,
                                 default = nil)
  if valid_594783 != nil:
    section.add "X-Amz-Credential", valid_594783
  var valid_594784 = header.getOrDefault("X-Amz-Security-Token")
  valid_594784 = validateParameter(valid_594784, JString, required = false,
                                 default = nil)
  if valid_594784 != nil:
    section.add "X-Amz-Security-Token", valid_594784
  var valid_594785 = header.getOrDefault("X-Amz-Algorithm")
  valid_594785 = validateParameter(valid_594785, JString, required = false,
                                 default = nil)
  if valid_594785 != nil:
    section.add "X-Amz-Algorithm", valid_594785
  var valid_594786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594786 = validateParameter(valid_594786, JString, required = false,
                                 default = nil)
  if valid_594786 != nil:
    section.add "X-Amz-SignedHeaders", valid_594786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594787: Call_GetDescribeTargetHealth_594773; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_594787.validator(path, query, header, formData, body)
  let scheme = call_594787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594787.url(scheme.get, call_594787.host, call_594787.base,
                         call_594787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594787, url, valid)

proc call*(call_594788: Call_GetDescribeTargetHealth_594773;
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
  var query_594789 = newJObject()
  if Targets != nil:
    query_594789.add "Targets", Targets
  add(query_594789, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594789, "Action", newJString(Action))
  add(query_594789, "Version", newJString(Version))
  result = call_594788.call(nil, query_594789, nil, nil, nil)

var getDescribeTargetHealth* = Call_GetDescribeTargetHealth_594773(
    name: "getDescribeTargetHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_GetDescribeTargetHealth_594774, base: "/",
    url: url_GetDescribeTargetHealth_594775, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyListener_594829 = ref object of OpenApiRestCall_593389
proc url_PostModifyListener_594831(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyListener_594830(path: JsonNode; query: JsonNode;
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
  var valid_594832 = query.getOrDefault("Action")
  valid_594832 = validateParameter(valid_594832, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_594832 != nil:
    section.add "Action", valid_594832
  var valid_594833 = query.getOrDefault("Version")
  valid_594833 = validateParameter(valid_594833, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594833 != nil:
    section.add "Version", valid_594833
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
  var valid_594834 = header.getOrDefault("X-Amz-Signature")
  valid_594834 = validateParameter(valid_594834, JString, required = false,
                                 default = nil)
  if valid_594834 != nil:
    section.add "X-Amz-Signature", valid_594834
  var valid_594835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594835 = validateParameter(valid_594835, JString, required = false,
                                 default = nil)
  if valid_594835 != nil:
    section.add "X-Amz-Content-Sha256", valid_594835
  var valid_594836 = header.getOrDefault("X-Amz-Date")
  valid_594836 = validateParameter(valid_594836, JString, required = false,
                                 default = nil)
  if valid_594836 != nil:
    section.add "X-Amz-Date", valid_594836
  var valid_594837 = header.getOrDefault("X-Amz-Credential")
  valid_594837 = validateParameter(valid_594837, JString, required = false,
                                 default = nil)
  if valid_594837 != nil:
    section.add "X-Amz-Credential", valid_594837
  var valid_594838 = header.getOrDefault("X-Amz-Security-Token")
  valid_594838 = validateParameter(valid_594838, JString, required = false,
                                 default = nil)
  if valid_594838 != nil:
    section.add "X-Amz-Security-Token", valid_594838
  var valid_594839 = header.getOrDefault("X-Amz-Algorithm")
  valid_594839 = validateParameter(valid_594839, JString, required = false,
                                 default = nil)
  if valid_594839 != nil:
    section.add "X-Amz-Algorithm", valid_594839
  var valid_594840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594840 = validateParameter(valid_594840, JString, required = false,
                                 default = nil)
  if valid_594840 != nil:
    section.add "X-Amz-SignedHeaders", valid_594840
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
  var valid_594841 = formData.getOrDefault("Port")
  valid_594841 = validateParameter(valid_594841, JInt, required = false, default = nil)
  if valid_594841 != nil:
    section.add "Port", valid_594841
  var valid_594842 = formData.getOrDefault("Certificates")
  valid_594842 = validateParameter(valid_594842, JArray, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "Certificates", valid_594842
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_594843 = formData.getOrDefault("ListenerArn")
  valid_594843 = validateParameter(valid_594843, JString, required = true,
                                 default = nil)
  if valid_594843 != nil:
    section.add "ListenerArn", valid_594843
  var valid_594844 = formData.getOrDefault("DefaultActions")
  valid_594844 = validateParameter(valid_594844, JArray, required = false,
                                 default = nil)
  if valid_594844 != nil:
    section.add "DefaultActions", valid_594844
  var valid_594845 = formData.getOrDefault("Protocol")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_594845 != nil:
    section.add "Protocol", valid_594845
  var valid_594846 = formData.getOrDefault("SslPolicy")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "SslPolicy", valid_594846
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594847: Call_PostModifyListener_594829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  let valid = call_594847.validator(path, query, header, formData, body)
  let scheme = call_594847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594847.url(scheme.get, call_594847.host, call_594847.base,
                         call_594847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594847, url, valid)

proc call*(call_594848: Call_PostModifyListener_594829; ListenerArn: string;
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
  var query_594849 = newJObject()
  var formData_594850 = newJObject()
  add(formData_594850, "Port", newJInt(Port))
  if Certificates != nil:
    formData_594850.add "Certificates", Certificates
  add(formData_594850, "ListenerArn", newJString(ListenerArn))
  if DefaultActions != nil:
    formData_594850.add "DefaultActions", DefaultActions
  add(formData_594850, "Protocol", newJString(Protocol))
  add(query_594849, "Action", newJString(Action))
  add(formData_594850, "SslPolicy", newJString(SslPolicy))
  add(query_594849, "Version", newJString(Version))
  result = call_594848.call(nil, query_594849, nil, formData_594850, nil)

var postModifyListener* = Call_PostModifyListener_594829(
    name: "postModifyListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=ModifyListener",
    validator: validate_PostModifyListener_594830, base: "/",
    url: url_PostModifyListener_594831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyListener_594808 = ref object of OpenApiRestCall_593389
proc url_GetModifyListener_594810(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyListener_594809(path: JsonNode; query: JsonNode;
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
  var valid_594811 = query.getOrDefault("SslPolicy")
  valid_594811 = validateParameter(valid_594811, JString, required = false,
                                 default = nil)
  if valid_594811 != nil:
    section.add "SslPolicy", valid_594811
  assert query != nil,
        "query argument is necessary due to required `ListenerArn` field"
  var valid_594812 = query.getOrDefault("ListenerArn")
  valid_594812 = validateParameter(valid_594812, JString, required = true,
                                 default = nil)
  if valid_594812 != nil:
    section.add "ListenerArn", valid_594812
  var valid_594813 = query.getOrDefault("Certificates")
  valid_594813 = validateParameter(valid_594813, JArray, required = false,
                                 default = nil)
  if valid_594813 != nil:
    section.add "Certificates", valid_594813
  var valid_594814 = query.getOrDefault("DefaultActions")
  valid_594814 = validateParameter(valid_594814, JArray, required = false,
                                 default = nil)
  if valid_594814 != nil:
    section.add "DefaultActions", valid_594814
  var valid_594815 = query.getOrDefault("Action")
  valid_594815 = validateParameter(valid_594815, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_594815 != nil:
    section.add "Action", valid_594815
  var valid_594816 = query.getOrDefault("Port")
  valid_594816 = validateParameter(valid_594816, JInt, required = false, default = nil)
  if valid_594816 != nil:
    section.add "Port", valid_594816
  var valid_594817 = query.getOrDefault("Protocol")
  valid_594817 = validateParameter(valid_594817, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_594817 != nil:
    section.add "Protocol", valid_594817
  var valid_594818 = query.getOrDefault("Version")
  valid_594818 = validateParameter(valid_594818, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594818 != nil:
    section.add "Version", valid_594818
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
  var valid_594819 = header.getOrDefault("X-Amz-Signature")
  valid_594819 = validateParameter(valid_594819, JString, required = false,
                                 default = nil)
  if valid_594819 != nil:
    section.add "X-Amz-Signature", valid_594819
  var valid_594820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594820 = validateParameter(valid_594820, JString, required = false,
                                 default = nil)
  if valid_594820 != nil:
    section.add "X-Amz-Content-Sha256", valid_594820
  var valid_594821 = header.getOrDefault("X-Amz-Date")
  valid_594821 = validateParameter(valid_594821, JString, required = false,
                                 default = nil)
  if valid_594821 != nil:
    section.add "X-Amz-Date", valid_594821
  var valid_594822 = header.getOrDefault("X-Amz-Credential")
  valid_594822 = validateParameter(valid_594822, JString, required = false,
                                 default = nil)
  if valid_594822 != nil:
    section.add "X-Amz-Credential", valid_594822
  var valid_594823 = header.getOrDefault("X-Amz-Security-Token")
  valid_594823 = validateParameter(valid_594823, JString, required = false,
                                 default = nil)
  if valid_594823 != nil:
    section.add "X-Amz-Security-Token", valid_594823
  var valid_594824 = header.getOrDefault("X-Amz-Algorithm")
  valid_594824 = validateParameter(valid_594824, JString, required = false,
                                 default = nil)
  if valid_594824 != nil:
    section.add "X-Amz-Algorithm", valid_594824
  var valid_594825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594825 = validateParameter(valid_594825, JString, required = false,
                                 default = nil)
  if valid_594825 != nil:
    section.add "X-Amz-SignedHeaders", valid_594825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594826: Call_GetModifyListener_594808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  let valid = call_594826.validator(path, query, header, formData, body)
  let scheme = call_594826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594826.url(scheme.get, call_594826.host, call_594826.base,
                         call_594826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594826, url, valid)

proc call*(call_594827: Call_GetModifyListener_594808; ListenerArn: string;
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
  var query_594828 = newJObject()
  add(query_594828, "SslPolicy", newJString(SslPolicy))
  add(query_594828, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_594828.add "Certificates", Certificates
  if DefaultActions != nil:
    query_594828.add "DefaultActions", DefaultActions
  add(query_594828, "Action", newJString(Action))
  add(query_594828, "Port", newJInt(Port))
  add(query_594828, "Protocol", newJString(Protocol))
  add(query_594828, "Version", newJString(Version))
  result = call_594827.call(nil, query_594828, nil, nil, nil)

var getModifyListener* = Call_GetModifyListener_594808(name: "getModifyListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyListener", validator: validate_GetModifyListener_594809,
    base: "/", url: url_GetModifyListener_594810,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_594868 = ref object of OpenApiRestCall_593389
proc url_PostModifyLoadBalancerAttributes_594870(protocol: Scheme; host: string;
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

proc validate_PostModifyLoadBalancerAttributes_594869(path: JsonNode;
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
  var valid_594871 = query.getOrDefault("Action")
  valid_594871 = validateParameter(valid_594871, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_594871 != nil:
    section.add "Action", valid_594871
  var valid_594872 = query.getOrDefault("Version")
  valid_594872 = validateParameter(valid_594872, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594872 != nil:
    section.add "Version", valid_594872
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
  var valid_594873 = header.getOrDefault("X-Amz-Signature")
  valid_594873 = validateParameter(valid_594873, JString, required = false,
                                 default = nil)
  if valid_594873 != nil:
    section.add "X-Amz-Signature", valid_594873
  var valid_594874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594874 = validateParameter(valid_594874, JString, required = false,
                                 default = nil)
  if valid_594874 != nil:
    section.add "X-Amz-Content-Sha256", valid_594874
  var valid_594875 = header.getOrDefault("X-Amz-Date")
  valid_594875 = validateParameter(valid_594875, JString, required = false,
                                 default = nil)
  if valid_594875 != nil:
    section.add "X-Amz-Date", valid_594875
  var valid_594876 = header.getOrDefault("X-Amz-Credential")
  valid_594876 = validateParameter(valid_594876, JString, required = false,
                                 default = nil)
  if valid_594876 != nil:
    section.add "X-Amz-Credential", valid_594876
  var valid_594877 = header.getOrDefault("X-Amz-Security-Token")
  valid_594877 = validateParameter(valid_594877, JString, required = false,
                                 default = nil)
  if valid_594877 != nil:
    section.add "X-Amz-Security-Token", valid_594877
  var valid_594878 = header.getOrDefault("X-Amz-Algorithm")
  valid_594878 = validateParameter(valid_594878, JString, required = false,
                                 default = nil)
  if valid_594878 != nil:
    section.add "X-Amz-Algorithm", valid_594878
  var valid_594879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594879 = validateParameter(valid_594879, JString, required = false,
                                 default = nil)
  if valid_594879 != nil:
    section.add "X-Amz-SignedHeaders", valid_594879
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_594880 = formData.getOrDefault("Attributes")
  valid_594880 = validateParameter(valid_594880, JArray, required = true, default = nil)
  if valid_594880 != nil:
    section.add "Attributes", valid_594880
  var valid_594881 = formData.getOrDefault("LoadBalancerArn")
  valid_594881 = validateParameter(valid_594881, JString, required = true,
                                 default = nil)
  if valid_594881 != nil:
    section.add "LoadBalancerArn", valid_594881
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594882: Call_PostModifyLoadBalancerAttributes_594868;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_594882.validator(path, query, header, formData, body)
  let scheme = call_594882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594882.url(scheme.get, call_594882.host, call_594882.base,
                         call_594882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594882, url, valid)

proc call*(call_594883: Call_PostModifyLoadBalancerAttributes_594868;
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
  var query_594884 = newJObject()
  var formData_594885 = newJObject()
  if Attributes != nil:
    formData_594885.add "Attributes", Attributes
  add(query_594884, "Action", newJString(Action))
  add(query_594884, "Version", newJString(Version))
  add(formData_594885, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_594883.call(nil, query_594884, nil, formData_594885, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_594868(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_594869, base: "/",
    url: url_PostModifyLoadBalancerAttributes_594870,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_594851 = ref object of OpenApiRestCall_593389
proc url_GetModifyLoadBalancerAttributes_594853(protocol: Scheme; host: string;
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

proc validate_GetModifyLoadBalancerAttributes_594852(path: JsonNode;
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
  var valid_594854 = query.getOrDefault("LoadBalancerArn")
  valid_594854 = validateParameter(valid_594854, JString, required = true,
                                 default = nil)
  if valid_594854 != nil:
    section.add "LoadBalancerArn", valid_594854
  var valid_594855 = query.getOrDefault("Attributes")
  valid_594855 = validateParameter(valid_594855, JArray, required = true, default = nil)
  if valid_594855 != nil:
    section.add "Attributes", valid_594855
  var valid_594856 = query.getOrDefault("Action")
  valid_594856 = validateParameter(valid_594856, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_594856 != nil:
    section.add "Action", valid_594856
  var valid_594857 = query.getOrDefault("Version")
  valid_594857 = validateParameter(valid_594857, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594857 != nil:
    section.add "Version", valid_594857
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
  var valid_594858 = header.getOrDefault("X-Amz-Signature")
  valid_594858 = validateParameter(valid_594858, JString, required = false,
                                 default = nil)
  if valid_594858 != nil:
    section.add "X-Amz-Signature", valid_594858
  var valid_594859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594859 = validateParameter(valid_594859, JString, required = false,
                                 default = nil)
  if valid_594859 != nil:
    section.add "X-Amz-Content-Sha256", valid_594859
  var valid_594860 = header.getOrDefault("X-Amz-Date")
  valid_594860 = validateParameter(valid_594860, JString, required = false,
                                 default = nil)
  if valid_594860 != nil:
    section.add "X-Amz-Date", valid_594860
  var valid_594861 = header.getOrDefault("X-Amz-Credential")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "X-Amz-Credential", valid_594861
  var valid_594862 = header.getOrDefault("X-Amz-Security-Token")
  valid_594862 = validateParameter(valid_594862, JString, required = false,
                                 default = nil)
  if valid_594862 != nil:
    section.add "X-Amz-Security-Token", valid_594862
  var valid_594863 = header.getOrDefault("X-Amz-Algorithm")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "X-Amz-Algorithm", valid_594863
  var valid_594864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594864 = validateParameter(valid_594864, JString, required = false,
                                 default = nil)
  if valid_594864 != nil:
    section.add "X-Amz-SignedHeaders", valid_594864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594865: Call_GetModifyLoadBalancerAttributes_594851;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_594865.validator(path, query, header, formData, body)
  let scheme = call_594865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594865.url(scheme.get, call_594865.host, call_594865.base,
                         call_594865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594865, url, valid)

proc call*(call_594866: Call_GetModifyLoadBalancerAttributes_594851;
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
  var query_594867 = newJObject()
  add(query_594867, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Attributes != nil:
    query_594867.add "Attributes", Attributes
  add(query_594867, "Action", newJString(Action))
  add(query_594867, "Version", newJString(Version))
  result = call_594866.call(nil, query_594867, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_594851(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_594852, base: "/",
    url: url_GetModifyLoadBalancerAttributes_594853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyRule_594904 = ref object of OpenApiRestCall_593389
proc url_PostModifyRule_594906(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyRule_594905(path: JsonNode; query: JsonNode;
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
  var valid_594907 = query.getOrDefault("Action")
  valid_594907 = validateParameter(valid_594907, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_594907 != nil:
    section.add "Action", valid_594907
  var valid_594908 = query.getOrDefault("Version")
  valid_594908 = validateParameter(valid_594908, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594908 != nil:
    section.add "Version", valid_594908
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
  var valid_594909 = header.getOrDefault("X-Amz-Signature")
  valid_594909 = validateParameter(valid_594909, JString, required = false,
                                 default = nil)
  if valid_594909 != nil:
    section.add "X-Amz-Signature", valid_594909
  var valid_594910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594910 = validateParameter(valid_594910, JString, required = false,
                                 default = nil)
  if valid_594910 != nil:
    section.add "X-Amz-Content-Sha256", valid_594910
  var valid_594911 = header.getOrDefault("X-Amz-Date")
  valid_594911 = validateParameter(valid_594911, JString, required = false,
                                 default = nil)
  if valid_594911 != nil:
    section.add "X-Amz-Date", valid_594911
  var valid_594912 = header.getOrDefault("X-Amz-Credential")
  valid_594912 = validateParameter(valid_594912, JString, required = false,
                                 default = nil)
  if valid_594912 != nil:
    section.add "X-Amz-Credential", valid_594912
  var valid_594913 = header.getOrDefault("X-Amz-Security-Token")
  valid_594913 = validateParameter(valid_594913, JString, required = false,
                                 default = nil)
  if valid_594913 != nil:
    section.add "X-Amz-Security-Token", valid_594913
  var valid_594914 = header.getOrDefault("X-Amz-Algorithm")
  valid_594914 = validateParameter(valid_594914, JString, required = false,
                                 default = nil)
  if valid_594914 != nil:
    section.add "X-Amz-Algorithm", valid_594914
  var valid_594915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594915 = validateParameter(valid_594915, JString, required = false,
                                 default = nil)
  if valid_594915 != nil:
    section.add "X-Amz-SignedHeaders", valid_594915
  result.add "header", section
  ## parameters in `formData` object:
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  var valid_594916 = formData.getOrDefault("Actions")
  valid_594916 = validateParameter(valid_594916, JArray, required = false,
                                 default = nil)
  if valid_594916 != nil:
    section.add "Actions", valid_594916
  var valid_594917 = formData.getOrDefault("Conditions")
  valid_594917 = validateParameter(valid_594917, JArray, required = false,
                                 default = nil)
  if valid_594917 != nil:
    section.add "Conditions", valid_594917
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_594918 = formData.getOrDefault("RuleArn")
  valid_594918 = validateParameter(valid_594918, JString, required = true,
                                 default = nil)
  if valid_594918 != nil:
    section.add "RuleArn", valid_594918
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594919: Call_PostModifyRule_594904; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_594919.validator(path, query, header, formData, body)
  let scheme = call_594919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594919.url(scheme.get, call_594919.host, call_594919.base,
                         call_594919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594919, url, valid)

proc call*(call_594920: Call_PostModifyRule_594904; RuleArn: string;
          Actions: JsonNode = nil; Conditions: JsonNode = nil;
          Action: string = "ModifyRule"; Version: string = "2015-12-01"): Recallable =
  ## postModifyRule
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594921 = newJObject()
  var formData_594922 = newJObject()
  if Actions != nil:
    formData_594922.add "Actions", Actions
  if Conditions != nil:
    formData_594922.add "Conditions", Conditions
  add(formData_594922, "RuleArn", newJString(RuleArn))
  add(query_594921, "Action", newJString(Action))
  add(query_594921, "Version", newJString(Version))
  result = call_594920.call(nil, query_594921, nil, formData_594922, nil)

var postModifyRule* = Call_PostModifyRule_594904(name: "postModifyRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_PostModifyRule_594905,
    base: "/", url: url_PostModifyRule_594906, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyRule_594886 = ref object of OpenApiRestCall_593389
proc url_GetModifyRule_594888(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyRule_594887(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `RuleArn` field"
  var valid_594889 = query.getOrDefault("RuleArn")
  valid_594889 = validateParameter(valid_594889, JString, required = true,
                                 default = nil)
  if valid_594889 != nil:
    section.add "RuleArn", valid_594889
  var valid_594890 = query.getOrDefault("Actions")
  valid_594890 = validateParameter(valid_594890, JArray, required = false,
                                 default = nil)
  if valid_594890 != nil:
    section.add "Actions", valid_594890
  var valid_594891 = query.getOrDefault("Action")
  valid_594891 = validateParameter(valid_594891, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_594891 != nil:
    section.add "Action", valid_594891
  var valid_594892 = query.getOrDefault("Version")
  valid_594892 = validateParameter(valid_594892, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594892 != nil:
    section.add "Version", valid_594892
  var valid_594893 = query.getOrDefault("Conditions")
  valid_594893 = validateParameter(valid_594893, JArray, required = false,
                                 default = nil)
  if valid_594893 != nil:
    section.add "Conditions", valid_594893
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
  var valid_594894 = header.getOrDefault("X-Amz-Signature")
  valid_594894 = validateParameter(valid_594894, JString, required = false,
                                 default = nil)
  if valid_594894 != nil:
    section.add "X-Amz-Signature", valid_594894
  var valid_594895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594895 = validateParameter(valid_594895, JString, required = false,
                                 default = nil)
  if valid_594895 != nil:
    section.add "X-Amz-Content-Sha256", valid_594895
  var valid_594896 = header.getOrDefault("X-Amz-Date")
  valid_594896 = validateParameter(valid_594896, JString, required = false,
                                 default = nil)
  if valid_594896 != nil:
    section.add "X-Amz-Date", valid_594896
  var valid_594897 = header.getOrDefault("X-Amz-Credential")
  valid_594897 = validateParameter(valid_594897, JString, required = false,
                                 default = nil)
  if valid_594897 != nil:
    section.add "X-Amz-Credential", valid_594897
  var valid_594898 = header.getOrDefault("X-Amz-Security-Token")
  valid_594898 = validateParameter(valid_594898, JString, required = false,
                                 default = nil)
  if valid_594898 != nil:
    section.add "X-Amz-Security-Token", valid_594898
  var valid_594899 = header.getOrDefault("X-Amz-Algorithm")
  valid_594899 = validateParameter(valid_594899, JString, required = false,
                                 default = nil)
  if valid_594899 != nil:
    section.add "X-Amz-Algorithm", valid_594899
  var valid_594900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594900 = validateParameter(valid_594900, JString, required = false,
                                 default = nil)
  if valid_594900 != nil:
    section.add "X-Amz-SignedHeaders", valid_594900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594901: Call_GetModifyRule_594886; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_594901.validator(path, query, header, formData, body)
  let scheme = call_594901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594901.url(scheme.get, call_594901.host, call_594901.base,
                         call_594901.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594901, url, valid)

proc call*(call_594902: Call_GetModifyRule_594886; RuleArn: string;
          Actions: JsonNode = nil; Action: string = "ModifyRule";
          Version: string = "2015-12-01"; Conditions: JsonNode = nil): Recallable =
  ## getModifyRule
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  var query_594903 = newJObject()
  add(query_594903, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    query_594903.add "Actions", Actions
  add(query_594903, "Action", newJString(Action))
  add(query_594903, "Version", newJString(Version))
  if Conditions != nil:
    query_594903.add "Conditions", Conditions
  result = call_594902.call(nil, query_594903, nil, nil, nil)

var getModifyRule* = Call_GetModifyRule_594886(name: "getModifyRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_GetModifyRule_594887,
    base: "/", url: url_GetModifyRule_594888, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroup_594948 = ref object of OpenApiRestCall_593389
proc url_PostModifyTargetGroup_594950(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyTargetGroup_594949(path: JsonNode; query: JsonNode;
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
  var valid_594951 = query.getOrDefault("Action")
  valid_594951 = validateParameter(valid_594951, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_594951 != nil:
    section.add "Action", valid_594951
  var valid_594952 = query.getOrDefault("Version")
  valid_594952 = validateParameter(valid_594952, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594952 != nil:
    section.add "Version", valid_594952
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
  var valid_594953 = header.getOrDefault("X-Amz-Signature")
  valid_594953 = validateParameter(valid_594953, JString, required = false,
                                 default = nil)
  if valid_594953 != nil:
    section.add "X-Amz-Signature", valid_594953
  var valid_594954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594954 = validateParameter(valid_594954, JString, required = false,
                                 default = nil)
  if valid_594954 != nil:
    section.add "X-Amz-Content-Sha256", valid_594954
  var valid_594955 = header.getOrDefault("X-Amz-Date")
  valid_594955 = validateParameter(valid_594955, JString, required = false,
                                 default = nil)
  if valid_594955 != nil:
    section.add "X-Amz-Date", valid_594955
  var valid_594956 = header.getOrDefault("X-Amz-Credential")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "X-Amz-Credential", valid_594956
  var valid_594957 = header.getOrDefault("X-Amz-Security-Token")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "X-Amz-Security-Token", valid_594957
  var valid_594958 = header.getOrDefault("X-Amz-Algorithm")
  valid_594958 = validateParameter(valid_594958, JString, required = false,
                                 default = nil)
  if valid_594958 != nil:
    section.add "X-Amz-Algorithm", valid_594958
  var valid_594959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594959 = validateParameter(valid_594959, JString, required = false,
                                 default = nil)
  if valid_594959 != nil:
    section.add "X-Amz-SignedHeaders", valid_594959
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
  var valid_594960 = formData.getOrDefault("HealthCheckProtocol")
  valid_594960 = validateParameter(valid_594960, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_594960 != nil:
    section.add "HealthCheckProtocol", valid_594960
  var valid_594961 = formData.getOrDefault("HealthCheckPort")
  valid_594961 = validateParameter(valid_594961, JString, required = false,
                                 default = nil)
  if valid_594961 != nil:
    section.add "HealthCheckPort", valid_594961
  var valid_594962 = formData.getOrDefault("HealthCheckEnabled")
  valid_594962 = validateParameter(valid_594962, JBool, required = false, default = nil)
  if valid_594962 != nil:
    section.add "HealthCheckEnabled", valid_594962
  var valid_594963 = formData.getOrDefault("HealthCheckPath")
  valid_594963 = validateParameter(valid_594963, JString, required = false,
                                 default = nil)
  if valid_594963 != nil:
    section.add "HealthCheckPath", valid_594963
  var valid_594964 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_594964 = validateParameter(valid_594964, JInt, required = false, default = nil)
  if valid_594964 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_594964
  var valid_594965 = formData.getOrDefault("HealthyThresholdCount")
  valid_594965 = validateParameter(valid_594965, JInt, required = false, default = nil)
  if valid_594965 != nil:
    section.add "HealthyThresholdCount", valid_594965
  var valid_594966 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_594966 = validateParameter(valid_594966, JInt, required = false, default = nil)
  if valid_594966 != nil:
    section.add "HealthCheckIntervalSeconds", valid_594966
  var valid_594967 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_594967 = validateParameter(valid_594967, JInt, required = false, default = nil)
  if valid_594967 != nil:
    section.add "UnhealthyThresholdCount", valid_594967
  var valid_594968 = formData.getOrDefault("Matcher.HttpCode")
  valid_594968 = validateParameter(valid_594968, JString, required = false,
                                 default = nil)
  if valid_594968 != nil:
    section.add "Matcher.HttpCode", valid_594968
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_594969 = formData.getOrDefault("TargetGroupArn")
  valid_594969 = validateParameter(valid_594969, JString, required = true,
                                 default = nil)
  if valid_594969 != nil:
    section.add "TargetGroupArn", valid_594969
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594970: Call_PostModifyTargetGroup_594948; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_594970.validator(path, query, header, formData, body)
  let scheme = call_594970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594970.url(scheme.get, call_594970.host, call_594970.base,
                         call_594970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594970, url, valid)

proc call*(call_594971: Call_PostModifyTargetGroup_594948; TargetGroupArn: string;
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
  var query_594972 = newJObject()
  var formData_594973 = newJObject()
  add(formData_594973, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_594973, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_594973, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_594973, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_594973, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_594973, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_594973, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_594973, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_594973, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_594972, "Action", newJString(Action))
  add(formData_594973, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594972, "Version", newJString(Version))
  result = call_594971.call(nil, query_594972, nil, formData_594973, nil)

var postModifyTargetGroup* = Call_PostModifyTargetGroup_594948(
    name: "postModifyTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup",
    validator: validate_PostModifyTargetGroup_594949, base: "/",
    url: url_PostModifyTargetGroup_594950, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroup_594923 = ref object of OpenApiRestCall_593389
proc url_GetModifyTargetGroup_594925(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyTargetGroup_594924(path: JsonNode; query: JsonNode;
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
  var valid_594926 = query.getOrDefault("HealthCheckPort")
  valid_594926 = validateParameter(valid_594926, JString, required = false,
                                 default = nil)
  if valid_594926 != nil:
    section.add "HealthCheckPort", valid_594926
  var valid_594927 = query.getOrDefault("HealthCheckPath")
  valid_594927 = validateParameter(valid_594927, JString, required = false,
                                 default = nil)
  if valid_594927 != nil:
    section.add "HealthCheckPath", valid_594927
  var valid_594928 = query.getOrDefault("HealthCheckProtocol")
  valid_594928 = validateParameter(valid_594928, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_594928 != nil:
    section.add "HealthCheckProtocol", valid_594928
  var valid_594929 = query.getOrDefault("Matcher.HttpCode")
  valid_594929 = validateParameter(valid_594929, JString, required = false,
                                 default = nil)
  if valid_594929 != nil:
    section.add "Matcher.HttpCode", valid_594929
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_594930 = query.getOrDefault("TargetGroupArn")
  valid_594930 = validateParameter(valid_594930, JString, required = true,
                                 default = nil)
  if valid_594930 != nil:
    section.add "TargetGroupArn", valid_594930
  var valid_594931 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_594931 = validateParameter(valid_594931, JInt, required = false, default = nil)
  if valid_594931 != nil:
    section.add "HealthCheckIntervalSeconds", valid_594931
  var valid_594932 = query.getOrDefault("HealthCheckEnabled")
  valid_594932 = validateParameter(valid_594932, JBool, required = false, default = nil)
  if valid_594932 != nil:
    section.add "HealthCheckEnabled", valid_594932
  var valid_594933 = query.getOrDefault("HealthyThresholdCount")
  valid_594933 = validateParameter(valid_594933, JInt, required = false, default = nil)
  if valid_594933 != nil:
    section.add "HealthyThresholdCount", valid_594933
  var valid_594934 = query.getOrDefault("UnhealthyThresholdCount")
  valid_594934 = validateParameter(valid_594934, JInt, required = false, default = nil)
  if valid_594934 != nil:
    section.add "UnhealthyThresholdCount", valid_594934
  var valid_594935 = query.getOrDefault("Action")
  valid_594935 = validateParameter(valid_594935, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_594935 != nil:
    section.add "Action", valid_594935
  var valid_594936 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_594936 = validateParameter(valid_594936, JInt, required = false, default = nil)
  if valid_594936 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_594936
  var valid_594937 = query.getOrDefault("Version")
  valid_594937 = validateParameter(valid_594937, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594937 != nil:
    section.add "Version", valid_594937
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
  var valid_594938 = header.getOrDefault("X-Amz-Signature")
  valid_594938 = validateParameter(valid_594938, JString, required = false,
                                 default = nil)
  if valid_594938 != nil:
    section.add "X-Amz-Signature", valid_594938
  var valid_594939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594939 = validateParameter(valid_594939, JString, required = false,
                                 default = nil)
  if valid_594939 != nil:
    section.add "X-Amz-Content-Sha256", valid_594939
  var valid_594940 = header.getOrDefault("X-Amz-Date")
  valid_594940 = validateParameter(valid_594940, JString, required = false,
                                 default = nil)
  if valid_594940 != nil:
    section.add "X-Amz-Date", valid_594940
  var valid_594941 = header.getOrDefault("X-Amz-Credential")
  valid_594941 = validateParameter(valid_594941, JString, required = false,
                                 default = nil)
  if valid_594941 != nil:
    section.add "X-Amz-Credential", valid_594941
  var valid_594942 = header.getOrDefault("X-Amz-Security-Token")
  valid_594942 = validateParameter(valid_594942, JString, required = false,
                                 default = nil)
  if valid_594942 != nil:
    section.add "X-Amz-Security-Token", valid_594942
  var valid_594943 = header.getOrDefault("X-Amz-Algorithm")
  valid_594943 = validateParameter(valid_594943, JString, required = false,
                                 default = nil)
  if valid_594943 != nil:
    section.add "X-Amz-Algorithm", valid_594943
  var valid_594944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594944 = validateParameter(valid_594944, JString, required = false,
                                 default = nil)
  if valid_594944 != nil:
    section.add "X-Amz-SignedHeaders", valid_594944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594945: Call_GetModifyTargetGroup_594923; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_594945.validator(path, query, header, formData, body)
  let scheme = call_594945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594945.url(scheme.get, call_594945.host, call_594945.base,
                         call_594945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594945, url, valid)

proc call*(call_594946: Call_GetModifyTargetGroup_594923; TargetGroupArn: string;
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
  var query_594947 = newJObject()
  add(query_594947, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_594947, "HealthCheckPath", newJString(HealthCheckPath))
  add(query_594947, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_594947, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_594947, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594947, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_594947, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_594947, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_594947, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_594947, "Action", newJString(Action))
  add(query_594947, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_594947, "Version", newJString(Version))
  result = call_594946.call(nil, query_594947, nil, nil, nil)

var getModifyTargetGroup* = Call_GetModifyTargetGroup_594923(
    name: "getModifyTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup", validator: validate_GetModifyTargetGroup_594924,
    base: "/", url: url_GetModifyTargetGroup_594925,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroupAttributes_594991 = ref object of OpenApiRestCall_593389
proc url_PostModifyTargetGroupAttributes_594993(protocol: Scheme; host: string;
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

proc validate_PostModifyTargetGroupAttributes_594992(path: JsonNode;
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
  var valid_594994 = query.getOrDefault("Action")
  valid_594994 = validateParameter(valid_594994, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_594994 != nil:
    section.add "Action", valid_594994
  var valid_594995 = query.getOrDefault("Version")
  valid_594995 = validateParameter(valid_594995, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594995 != nil:
    section.add "Version", valid_594995
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
  var valid_594996 = header.getOrDefault("X-Amz-Signature")
  valid_594996 = validateParameter(valid_594996, JString, required = false,
                                 default = nil)
  if valid_594996 != nil:
    section.add "X-Amz-Signature", valid_594996
  var valid_594997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594997 = validateParameter(valid_594997, JString, required = false,
                                 default = nil)
  if valid_594997 != nil:
    section.add "X-Amz-Content-Sha256", valid_594997
  var valid_594998 = header.getOrDefault("X-Amz-Date")
  valid_594998 = validateParameter(valid_594998, JString, required = false,
                                 default = nil)
  if valid_594998 != nil:
    section.add "X-Amz-Date", valid_594998
  var valid_594999 = header.getOrDefault("X-Amz-Credential")
  valid_594999 = validateParameter(valid_594999, JString, required = false,
                                 default = nil)
  if valid_594999 != nil:
    section.add "X-Amz-Credential", valid_594999
  var valid_595000 = header.getOrDefault("X-Amz-Security-Token")
  valid_595000 = validateParameter(valid_595000, JString, required = false,
                                 default = nil)
  if valid_595000 != nil:
    section.add "X-Amz-Security-Token", valid_595000
  var valid_595001 = header.getOrDefault("X-Amz-Algorithm")
  valid_595001 = validateParameter(valid_595001, JString, required = false,
                                 default = nil)
  if valid_595001 != nil:
    section.add "X-Amz-Algorithm", valid_595001
  var valid_595002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595002 = validateParameter(valid_595002, JString, required = false,
                                 default = nil)
  if valid_595002 != nil:
    section.add "X-Amz-SignedHeaders", valid_595002
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_595003 = formData.getOrDefault("Attributes")
  valid_595003 = validateParameter(valid_595003, JArray, required = true, default = nil)
  if valid_595003 != nil:
    section.add "Attributes", valid_595003
  var valid_595004 = formData.getOrDefault("TargetGroupArn")
  valid_595004 = validateParameter(valid_595004, JString, required = true,
                                 default = nil)
  if valid_595004 != nil:
    section.add "TargetGroupArn", valid_595004
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595005: Call_PostModifyTargetGroupAttributes_594991;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_595005.validator(path, query, header, formData, body)
  let scheme = call_595005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595005.url(scheme.get, call_595005.host, call_595005.base,
                         call_595005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595005, url, valid)

proc call*(call_595006: Call_PostModifyTargetGroupAttributes_594991;
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
  var query_595007 = newJObject()
  var formData_595008 = newJObject()
  if Attributes != nil:
    formData_595008.add "Attributes", Attributes
  add(query_595007, "Action", newJString(Action))
  add(formData_595008, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_595007, "Version", newJString(Version))
  result = call_595006.call(nil, query_595007, nil, formData_595008, nil)

var postModifyTargetGroupAttributes* = Call_PostModifyTargetGroupAttributes_594991(
    name: "postModifyTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_PostModifyTargetGroupAttributes_594992, base: "/",
    url: url_PostModifyTargetGroupAttributes_594993,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroupAttributes_594974 = ref object of OpenApiRestCall_593389
proc url_GetModifyTargetGroupAttributes_594976(protocol: Scheme; host: string;
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

proc validate_GetModifyTargetGroupAttributes_594975(path: JsonNode;
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
  var valid_594977 = query.getOrDefault("TargetGroupArn")
  valid_594977 = validateParameter(valid_594977, JString, required = true,
                                 default = nil)
  if valid_594977 != nil:
    section.add "TargetGroupArn", valid_594977
  var valid_594978 = query.getOrDefault("Attributes")
  valid_594978 = validateParameter(valid_594978, JArray, required = true, default = nil)
  if valid_594978 != nil:
    section.add "Attributes", valid_594978
  var valid_594979 = query.getOrDefault("Action")
  valid_594979 = validateParameter(valid_594979, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_594979 != nil:
    section.add "Action", valid_594979
  var valid_594980 = query.getOrDefault("Version")
  valid_594980 = validateParameter(valid_594980, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594980 != nil:
    section.add "Version", valid_594980
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
  var valid_594981 = header.getOrDefault("X-Amz-Signature")
  valid_594981 = validateParameter(valid_594981, JString, required = false,
                                 default = nil)
  if valid_594981 != nil:
    section.add "X-Amz-Signature", valid_594981
  var valid_594982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594982 = validateParameter(valid_594982, JString, required = false,
                                 default = nil)
  if valid_594982 != nil:
    section.add "X-Amz-Content-Sha256", valid_594982
  var valid_594983 = header.getOrDefault("X-Amz-Date")
  valid_594983 = validateParameter(valid_594983, JString, required = false,
                                 default = nil)
  if valid_594983 != nil:
    section.add "X-Amz-Date", valid_594983
  var valid_594984 = header.getOrDefault("X-Amz-Credential")
  valid_594984 = validateParameter(valid_594984, JString, required = false,
                                 default = nil)
  if valid_594984 != nil:
    section.add "X-Amz-Credential", valid_594984
  var valid_594985 = header.getOrDefault("X-Amz-Security-Token")
  valid_594985 = validateParameter(valid_594985, JString, required = false,
                                 default = nil)
  if valid_594985 != nil:
    section.add "X-Amz-Security-Token", valid_594985
  var valid_594986 = header.getOrDefault("X-Amz-Algorithm")
  valid_594986 = validateParameter(valid_594986, JString, required = false,
                                 default = nil)
  if valid_594986 != nil:
    section.add "X-Amz-Algorithm", valid_594986
  var valid_594987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594987 = validateParameter(valid_594987, JString, required = false,
                                 default = nil)
  if valid_594987 != nil:
    section.add "X-Amz-SignedHeaders", valid_594987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594988: Call_GetModifyTargetGroupAttributes_594974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_594988.validator(path, query, header, formData, body)
  let scheme = call_594988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594988.url(scheme.get, call_594988.host, call_594988.base,
                         call_594988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594988, url, valid)

proc call*(call_594989: Call_GetModifyTargetGroupAttributes_594974;
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
  var query_594990 = newJObject()
  add(query_594990, "TargetGroupArn", newJString(TargetGroupArn))
  if Attributes != nil:
    query_594990.add "Attributes", Attributes
  add(query_594990, "Action", newJString(Action))
  add(query_594990, "Version", newJString(Version))
  result = call_594989.call(nil, query_594990, nil, nil, nil)

var getModifyTargetGroupAttributes* = Call_GetModifyTargetGroupAttributes_594974(
    name: "getModifyTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_GetModifyTargetGroupAttributes_594975, base: "/",
    url: url_GetModifyTargetGroupAttributes_594976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterTargets_595026 = ref object of OpenApiRestCall_593389
proc url_PostRegisterTargets_595028(protocol: Scheme; host: string; base: string;
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

proc validate_PostRegisterTargets_595027(path: JsonNode; query: JsonNode;
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
  var valid_595029 = query.getOrDefault("Action")
  valid_595029 = validateParameter(valid_595029, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_595029 != nil:
    section.add "Action", valid_595029
  var valid_595030 = query.getOrDefault("Version")
  valid_595030 = validateParameter(valid_595030, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595030 != nil:
    section.add "Version", valid_595030
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
  var valid_595031 = header.getOrDefault("X-Amz-Signature")
  valid_595031 = validateParameter(valid_595031, JString, required = false,
                                 default = nil)
  if valid_595031 != nil:
    section.add "X-Amz-Signature", valid_595031
  var valid_595032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595032 = validateParameter(valid_595032, JString, required = false,
                                 default = nil)
  if valid_595032 != nil:
    section.add "X-Amz-Content-Sha256", valid_595032
  var valid_595033 = header.getOrDefault("X-Amz-Date")
  valid_595033 = validateParameter(valid_595033, JString, required = false,
                                 default = nil)
  if valid_595033 != nil:
    section.add "X-Amz-Date", valid_595033
  var valid_595034 = header.getOrDefault("X-Amz-Credential")
  valid_595034 = validateParameter(valid_595034, JString, required = false,
                                 default = nil)
  if valid_595034 != nil:
    section.add "X-Amz-Credential", valid_595034
  var valid_595035 = header.getOrDefault("X-Amz-Security-Token")
  valid_595035 = validateParameter(valid_595035, JString, required = false,
                                 default = nil)
  if valid_595035 != nil:
    section.add "X-Amz-Security-Token", valid_595035
  var valid_595036 = header.getOrDefault("X-Amz-Algorithm")
  valid_595036 = validateParameter(valid_595036, JString, required = false,
                                 default = nil)
  if valid_595036 != nil:
    section.add "X-Amz-Algorithm", valid_595036
  var valid_595037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595037 = validateParameter(valid_595037, JString, required = false,
                                 default = nil)
  if valid_595037 != nil:
    section.add "X-Amz-SignedHeaders", valid_595037
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_595038 = formData.getOrDefault("Targets")
  valid_595038 = validateParameter(valid_595038, JArray, required = true, default = nil)
  if valid_595038 != nil:
    section.add "Targets", valid_595038
  var valid_595039 = formData.getOrDefault("TargetGroupArn")
  valid_595039 = validateParameter(valid_595039, JString, required = true,
                                 default = nil)
  if valid_595039 != nil:
    section.add "TargetGroupArn", valid_595039
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595040: Call_PostRegisterTargets_595026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_595040.validator(path, query, header, formData, body)
  let scheme = call_595040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595040.url(scheme.get, call_595040.host, call_595040.base,
                         call_595040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595040, url, valid)

proc call*(call_595041: Call_PostRegisterTargets_595026; Targets: JsonNode;
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
  var query_595042 = newJObject()
  var formData_595043 = newJObject()
  if Targets != nil:
    formData_595043.add "Targets", Targets
  add(query_595042, "Action", newJString(Action))
  add(formData_595043, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_595042, "Version", newJString(Version))
  result = call_595041.call(nil, query_595042, nil, formData_595043, nil)

var postRegisterTargets* = Call_PostRegisterTargets_595026(
    name: "postRegisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_PostRegisterTargets_595027, base: "/",
    url: url_PostRegisterTargets_595028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterTargets_595009 = ref object of OpenApiRestCall_593389
proc url_GetRegisterTargets_595011(protocol: Scheme; host: string; base: string;
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

proc validate_GetRegisterTargets_595010(path: JsonNode; query: JsonNode;
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
  var valid_595012 = query.getOrDefault("Targets")
  valid_595012 = validateParameter(valid_595012, JArray, required = true, default = nil)
  if valid_595012 != nil:
    section.add "Targets", valid_595012
  var valid_595013 = query.getOrDefault("TargetGroupArn")
  valid_595013 = validateParameter(valid_595013, JString, required = true,
                                 default = nil)
  if valid_595013 != nil:
    section.add "TargetGroupArn", valid_595013
  var valid_595014 = query.getOrDefault("Action")
  valid_595014 = validateParameter(valid_595014, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_595014 != nil:
    section.add "Action", valid_595014
  var valid_595015 = query.getOrDefault("Version")
  valid_595015 = validateParameter(valid_595015, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595015 != nil:
    section.add "Version", valid_595015
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
  var valid_595016 = header.getOrDefault("X-Amz-Signature")
  valid_595016 = validateParameter(valid_595016, JString, required = false,
                                 default = nil)
  if valid_595016 != nil:
    section.add "X-Amz-Signature", valid_595016
  var valid_595017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595017 = validateParameter(valid_595017, JString, required = false,
                                 default = nil)
  if valid_595017 != nil:
    section.add "X-Amz-Content-Sha256", valid_595017
  var valid_595018 = header.getOrDefault("X-Amz-Date")
  valid_595018 = validateParameter(valid_595018, JString, required = false,
                                 default = nil)
  if valid_595018 != nil:
    section.add "X-Amz-Date", valid_595018
  var valid_595019 = header.getOrDefault("X-Amz-Credential")
  valid_595019 = validateParameter(valid_595019, JString, required = false,
                                 default = nil)
  if valid_595019 != nil:
    section.add "X-Amz-Credential", valid_595019
  var valid_595020 = header.getOrDefault("X-Amz-Security-Token")
  valid_595020 = validateParameter(valid_595020, JString, required = false,
                                 default = nil)
  if valid_595020 != nil:
    section.add "X-Amz-Security-Token", valid_595020
  var valid_595021 = header.getOrDefault("X-Amz-Algorithm")
  valid_595021 = validateParameter(valid_595021, JString, required = false,
                                 default = nil)
  if valid_595021 != nil:
    section.add "X-Amz-Algorithm", valid_595021
  var valid_595022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595022 = validateParameter(valid_595022, JString, required = false,
                                 default = nil)
  if valid_595022 != nil:
    section.add "X-Amz-SignedHeaders", valid_595022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595023: Call_GetRegisterTargets_595009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_595023.validator(path, query, header, formData, body)
  let scheme = call_595023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595023.url(scheme.get, call_595023.host, call_595023.base,
                         call_595023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595023, url, valid)

proc call*(call_595024: Call_GetRegisterTargets_595009; Targets: JsonNode;
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
  var query_595025 = newJObject()
  if Targets != nil:
    query_595025.add "Targets", Targets
  add(query_595025, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_595025, "Action", newJString(Action))
  add(query_595025, "Version", newJString(Version))
  result = call_595024.call(nil, query_595025, nil, nil, nil)

var getRegisterTargets* = Call_GetRegisterTargets_595009(
    name: "getRegisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_GetRegisterTargets_595010, base: "/",
    url: url_GetRegisterTargets_595011, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveListenerCertificates_595061 = ref object of OpenApiRestCall_593389
proc url_PostRemoveListenerCertificates_595063(protocol: Scheme; host: string;
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

proc validate_PostRemoveListenerCertificates_595062(path: JsonNode;
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
  var valid_595064 = query.getOrDefault("Action")
  valid_595064 = validateParameter(valid_595064, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_595064 != nil:
    section.add "Action", valid_595064
  var valid_595065 = query.getOrDefault("Version")
  valid_595065 = validateParameter(valid_595065, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595065 != nil:
    section.add "Version", valid_595065
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
  var valid_595066 = header.getOrDefault("X-Amz-Signature")
  valid_595066 = validateParameter(valid_595066, JString, required = false,
                                 default = nil)
  if valid_595066 != nil:
    section.add "X-Amz-Signature", valid_595066
  var valid_595067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595067 = validateParameter(valid_595067, JString, required = false,
                                 default = nil)
  if valid_595067 != nil:
    section.add "X-Amz-Content-Sha256", valid_595067
  var valid_595068 = header.getOrDefault("X-Amz-Date")
  valid_595068 = validateParameter(valid_595068, JString, required = false,
                                 default = nil)
  if valid_595068 != nil:
    section.add "X-Amz-Date", valid_595068
  var valid_595069 = header.getOrDefault("X-Amz-Credential")
  valid_595069 = validateParameter(valid_595069, JString, required = false,
                                 default = nil)
  if valid_595069 != nil:
    section.add "X-Amz-Credential", valid_595069
  var valid_595070 = header.getOrDefault("X-Amz-Security-Token")
  valid_595070 = validateParameter(valid_595070, JString, required = false,
                                 default = nil)
  if valid_595070 != nil:
    section.add "X-Amz-Security-Token", valid_595070
  var valid_595071 = header.getOrDefault("X-Amz-Algorithm")
  valid_595071 = validateParameter(valid_595071, JString, required = false,
                                 default = nil)
  if valid_595071 != nil:
    section.add "X-Amz-Algorithm", valid_595071
  var valid_595072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595072 = validateParameter(valid_595072, JString, required = false,
                                 default = nil)
  if valid_595072 != nil:
    section.add "X-Amz-SignedHeaders", valid_595072
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_595073 = formData.getOrDefault("Certificates")
  valid_595073 = validateParameter(valid_595073, JArray, required = true, default = nil)
  if valid_595073 != nil:
    section.add "Certificates", valid_595073
  var valid_595074 = formData.getOrDefault("ListenerArn")
  valid_595074 = validateParameter(valid_595074, JString, required = true,
                                 default = nil)
  if valid_595074 != nil:
    section.add "ListenerArn", valid_595074
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595075: Call_PostRemoveListenerCertificates_595061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_595075.validator(path, query, header, formData, body)
  let scheme = call_595075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595075.url(scheme.get, call_595075.host, call_595075.base,
                         call_595075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595075, url, valid)

proc call*(call_595076: Call_PostRemoveListenerCertificates_595061;
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
  var query_595077 = newJObject()
  var formData_595078 = newJObject()
  if Certificates != nil:
    formData_595078.add "Certificates", Certificates
  add(formData_595078, "ListenerArn", newJString(ListenerArn))
  add(query_595077, "Action", newJString(Action))
  add(query_595077, "Version", newJString(Version))
  result = call_595076.call(nil, query_595077, nil, formData_595078, nil)

var postRemoveListenerCertificates* = Call_PostRemoveListenerCertificates_595061(
    name: "postRemoveListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_PostRemoveListenerCertificates_595062, base: "/",
    url: url_PostRemoveListenerCertificates_595063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveListenerCertificates_595044 = ref object of OpenApiRestCall_593389
proc url_GetRemoveListenerCertificates_595046(protocol: Scheme; host: string;
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

proc validate_GetRemoveListenerCertificates_595045(path: JsonNode; query: JsonNode;
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
  var valid_595047 = query.getOrDefault("ListenerArn")
  valid_595047 = validateParameter(valid_595047, JString, required = true,
                                 default = nil)
  if valid_595047 != nil:
    section.add "ListenerArn", valid_595047
  var valid_595048 = query.getOrDefault("Certificates")
  valid_595048 = validateParameter(valid_595048, JArray, required = true, default = nil)
  if valid_595048 != nil:
    section.add "Certificates", valid_595048
  var valid_595049 = query.getOrDefault("Action")
  valid_595049 = validateParameter(valid_595049, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_595049 != nil:
    section.add "Action", valid_595049
  var valid_595050 = query.getOrDefault("Version")
  valid_595050 = validateParameter(valid_595050, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595050 != nil:
    section.add "Version", valid_595050
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
  var valid_595051 = header.getOrDefault("X-Amz-Signature")
  valid_595051 = validateParameter(valid_595051, JString, required = false,
                                 default = nil)
  if valid_595051 != nil:
    section.add "X-Amz-Signature", valid_595051
  var valid_595052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595052 = validateParameter(valid_595052, JString, required = false,
                                 default = nil)
  if valid_595052 != nil:
    section.add "X-Amz-Content-Sha256", valid_595052
  var valid_595053 = header.getOrDefault("X-Amz-Date")
  valid_595053 = validateParameter(valid_595053, JString, required = false,
                                 default = nil)
  if valid_595053 != nil:
    section.add "X-Amz-Date", valid_595053
  var valid_595054 = header.getOrDefault("X-Amz-Credential")
  valid_595054 = validateParameter(valid_595054, JString, required = false,
                                 default = nil)
  if valid_595054 != nil:
    section.add "X-Amz-Credential", valid_595054
  var valid_595055 = header.getOrDefault("X-Amz-Security-Token")
  valid_595055 = validateParameter(valid_595055, JString, required = false,
                                 default = nil)
  if valid_595055 != nil:
    section.add "X-Amz-Security-Token", valid_595055
  var valid_595056 = header.getOrDefault("X-Amz-Algorithm")
  valid_595056 = validateParameter(valid_595056, JString, required = false,
                                 default = nil)
  if valid_595056 != nil:
    section.add "X-Amz-Algorithm", valid_595056
  var valid_595057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595057 = validateParameter(valid_595057, JString, required = false,
                                 default = nil)
  if valid_595057 != nil:
    section.add "X-Amz-SignedHeaders", valid_595057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595058: Call_GetRemoveListenerCertificates_595044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_595058.validator(path, query, header, formData, body)
  let scheme = call_595058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595058.url(scheme.get, call_595058.host, call_595058.base,
                         call_595058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595058, url, valid)

proc call*(call_595059: Call_GetRemoveListenerCertificates_595044;
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
  var query_595060 = newJObject()
  add(query_595060, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_595060.add "Certificates", Certificates
  add(query_595060, "Action", newJString(Action))
  add(query_595060, "Version", newJString(Version))
  result = call_595059.call(nil, query_595060, nil, nil, nil)

var getRemoveListenerCertificates* = Call_GetRemoveListenerCertificates_595044(
    name: "getRemoveListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_GetRemoveListenerCertificates_595045, base: "/",
    url: url_GetRemoveListenerCertificates_595046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_595096 = ref object of OpenApiRestCall_593389
proc url_PostRemoveTags_595098(protocol: Scheme; host: string; base: string;
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

proc validate_PostRemoveTags_595097(path: JsonNode; query: JsonNode;
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
  var valid_595099 = query.getOrDefault("Action")
  valid_595099 = validateParameter(valid_595099, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_595099 != nil:
    section.add "Action", valid_595099
  var valid_595100 = query.getOrDefault("Version")
  valid_595100 = validateParameter(valid_595100, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595100 != nil:
    section.add "Version", valid_595100
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
  var valid_595101 = header.getOrDefault("X-Amz-Signature")
  valid_595101 = validateParameter(valid_595101, JString, required = false,
                                 default = nil)
  if valid_595101 != nil:
    section.add "X-Amz-Signature", valid_595101
  var valid_595102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595102 = validateParameter(valid_595102, JString, required = false,
                                 default = nil)
  if valid_595102 != nil:
    section.add "X-Amz-Content-Sha256", valid_595102
  var valid_595103 = header.getOrDefault("X-Amz-Date")
  valid_595103 = validateParameter(valid_595103, JString, required = false,
                                 default = nil)
  if valid_595103 != nil:
    section.add "X-Amz-Date", valid_595103
  var valid_595104 = header.getOrDefault("X-Amz-Credential")
  valid_595104 = validateParameter(valid_595104, JString, required = false,
                                 default = nil)
  if valid_595104 != nil:
    section.add "X-Amz-Credential", valid_595104
  var valid_595105 = header.getOrDefault("X-Amz-Security-Token")
  valid_595105 = validateParameter(valid_595105, JString, required = false,
                                 default = nil)
  if valid_595105 != nil:
    section.add "X-Amz-Security-Token", valid_595105
  var valid_595106 = header.getOrDefault("X-Amz-Algorithm")
  valid_595106 = validateParameter(valid_595106, JString, required = false,
                                 default = nil)
  if valid_595106 != nil:
    section.add "X-Amz-Algorithm", valid_595106
  var valid_595107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595107 = validateParameter(valid_595107, JString, required = false,
                                 default = nil)
  if valid_595107 != nil:
    section.add "X-Amz-SignedHeaders", valid_595107
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_595108 = formData.getOrDefault("TagKeys")
  valid_595108 = validateParameter(valid_595108, JArray, required = true, default = nil)
  if valid_595108 != nil:
    section.add "TagKeys", valid_595108
  var valid_595109 = formData.getOrDefault("ResourceArns")
  valid_595109 = validateParameter(valid_595109, JArray, required = true, default = nil)
  if valid_595109 != nil:
    section.add "ResourceArns", valid_595109
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595110: Call_PostRemoveTags_595096; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_595110.validator(path, query, header, formData, body)
  let scheme = call_595110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595110.url(scheme.get, call_595110.host, call_595110.base,
                         call_595110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595110, url, valid)

proc call*(call_595111: Call_PostRemoveTags_595096; TagKeys: JsonNode;
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
  var query_595112 = newJObject()
  var formData_595113 = newJObject()
  if TagKeys != nil:
    formData_595113.add "TagKeys", TagKeys
  if ResourceArns != nil:
    formData_595113.add "ResourceArns", ResourceArns
  add(query_595112, "Action", newJString(Action))
  add(query_595112, "Version", newJString(Version))
  result = call_595111.call(nil, query_595112, nil, formData_595113, nil)

var postRemoveTags* = Call_PostRemoveTags_595096(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_595097,
    base: "/", url: url_PostRemoveTags_595098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_595079 = ref object of OpenApiRestCall_593389
proc url_GetRemoveTags_595081(protocol: Scheme; host: string; base: string;
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

proc validate_GetRemoveTags_595080(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595082 = query.getOrDefault("ResourceArns")
  valid_595082 = validateParameter(valid_595082, JArray, required = true, default = nil)
  if valid_595082 != nil:
    section.add "ResourceArns", valid_595082
  var valid_595083 = query.getOrDefault("TagKeys")
  valid_595083 = validateParameter(valid_595083, JArray, required = true, default = nil)
  if valid_595083 != nil:
    section.add "TagKeys", valid_595083
  var valid_595084 = query.getOrDefault("Action")
  valid_595084 = validateParameter(valid_595084, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_595084 != nil:
    section.add "Action", valid_595084
  var valid_595085 = query.getOrDefault("Version")
  valid_595085 = validateParameter(valid_595085, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595085 != nil:
    section.add "Version", valid_595085
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
  var valid_595086 = header.getOrDefault("X-Amz-Signature")
  valid_595086 = validateParameter(valid_595086, JString, required = false,
                                 default = nil)
  if valid_595086 != nil:
    section.add "X-Amz-Signature", valid_595086
  var valid_595087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595087 = validateParameter(valid_595087, JString, required = false,
                                 default = nil)
  if valid_595087 != nil:
    section.add "X-Amz-Content-Sha256", valid_595087
  var valid_595088 = header.getOrDefault("X-Amz-Date")
  valid_595088 = validateParameter(valid_595088, JString, required = false,
                                 default = nil)
  if valid_595088 != nil:
    section.add "X-Amz-Date", valid_595088
  var valid_595089 = header.getOrDefault("X-Amz-Credential")
  valid_595089 = validateParameter(valid_595089, JString, required = false,
                                 default = nil)
  if valid_595089 != nil:
    section.add "X-Amz-Credential", valid_595089
  var valid_595090 = header.getOrDefault("X-Amz-Security-Token")
  valid_595090 = validateParameter(valid_595090, JString, required = false,
                                 default = nil)
  if valid_595090 != nil:
    section.add "X-Amz-Security-Token", valid_595090
  var valid_595091 = header.getOrDefault("X-Amz-Algorithm")
  valid_595091 = validateParameter(valid_595091, JString, required = false,
                                 default = nil)
  if valid_595091 != nil:
    section.add "X-Amz-Algorithm", valid_595091
  var valid_595092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595092 = validateParameter(valid_595092, JString, required = false,
                                 default = nil)
  if valid_595092 != nil:
    section.add "X-Amz-SignedHeaders", valid_595092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595093: Call_GetRemoveTags_595079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_595093.validator(path, query, header, formData, body)
  let scheme = call_595093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595093.url(scheme.get, call_595093.host, call_595093.base,
                         call_595093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595093, url, valid)

proc call*(call_595094: Call_GetRemoveTags_595079; ResourceArns: JsonNode;
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
  var query_595095 = newJObject()
  if ResourceArns != nil:
    query_595095.add "ResourceArns", ResourceArns
  if TagKeys != nil:
    query_595095.add "TagKeys", TagKeys
  add(query_595095, "Action", newJString(Action))
  add(query_595095, "Version", newJString(Version))
  result = call_595094.call(nil, query_595095, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_595079(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_595080,
    base: "/", url: url_GetRemoveTags_595081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetIpAddressType_595131 = ref object of OpenApiRestCall_593389
proc url_PostSetIpAddressType_595133(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetIpAddressType_595132(path: JsonNode; query: JsonNode;
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
  var valid_595134 = query.getOrDefault("Action")
  valid_595134 = validateParameter(valid_595134, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_595134 != nil:
    section.add "Action", valid_595134
  var valid_595135 = query.getOrDefault("Version")
  valid_595135 = validateParameter(valid_595135, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595135 != nil:
    section.add "Version", valid_595135
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
  var valid_595136 = header.getOrDefault("X-Amz-Signature")
  valid_595136 = validateParameter(valid_595136, JString, required = false,
                                 default = nil)
  if valid_595136 != nil:
    section.add "X-Amz-Signature", valid_595136
  var valid_595137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595137 = validateParameter(valid_595137, JString, required = false,
                                 default = nil)
  if valid_595137 != nil:
    section.add "X-Amz-Content-Sha256", valid_595137
  var valid_595138 = header.getOrDefault("X-Amz-Date")
  valid_595138 = validateParameter(valid_595138, JString, required = false,
                                 default = nil)
  if valid_595138 != nil:
    section.add "X-Amz-Date", valid_595138
  var valid_595139 = header.getOrDefault("X-Amz-Credential")
  valid_595139 = validateParameter(valid_595139, JString, required = false,
                                 default = nil)
  if valid_595139 != nil:
    section.add "X-Amz-Credential", valid_595139
  var valid_595140 = header.getOrDefault("X-Amz-Security-Token")
  valid_595140 = validateParameter(valid_595140, JString, required = false,
                                 default = nil)
  if valid_595140 != nil:
    section.add "X-Amz-Security-Token", valid_595140
  var valid_595141 = header.getOrDefault("X-Amz-Algorithm")
  valid_595141 = validateParameter(valid_595141, JString, required = false,
                                 default = nil)
  if valid_595141 != nil:
    section.add "X-Amz-Algorithm", valid_595141
  var valid_595142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595142 = validateParameter(valid_595142, JString, required = false,
                                 default = nil)
  if valid_595142 != nil:
    section.add "X-Amz-SignedHeaders", valid_595142
  result.add "header", section
  ## parameters in `formData` object:
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `IpAddressType` field"
  var valid_595143 = formData.getOrDefault("IpAddressType")
  valid_595143 = validateParameter(valid_595143, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_595143 != nil:
    section.add "IpAddressType", valid_595143
  var valid_595144 = formData.getOrDefault("LoadBalancerArn")
  valid_595144 = validateParameter(valid_595144, JString, required = true,
                                 default = nil)
  if valid_595144 != nil:
    section.add "LoadBalancerArn", valid_595144
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595145: Call_PostSetIpAddressType_595131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_595145.validator(path, query, header, formData, body)
  let scheme = call_595145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595145.url(scheme.get, call_595145.host, call_595145.base,
                         call_595145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595145, url, valid)

proc call*(call_595146: Call_PostSetIpAddressType_595131; LoadBalancerArn: string;
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
  var query_595147 = newJObject()
  var formData_595148 = newJObject()
  add(formData_595148, "IpAddressType", newJString(IpAddressType))
  add(query_595147, "Action", newJString(Action))
  add(query_595147, "Version", newJString(Version))
  add(formData_595148, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_595146.call(nil, query_595147, nil, formData_595148, nil)

var postSetIpAddressType* = Call_PostSetIpAddressType_595131(
    name: "postSetIpAddressType", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_PostSetIpAddressType_595132,
    base: "/", url: url_PostSetIpAddressType_595133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetIpAddressType_595114 = ref object of OpenApiRestCall_593389
proc url_GetSetIpAddressType_595116(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetIpAddressType_595115(path: JsonNode; query: JsonNode;
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
  var valid_595117 = query.getOrDefault("IpAddressType")
  valid_595117 = validateParameter(valid_595117, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_595117 != nil:
    section.add "IpAddressType", valid_595117
  var valid_595118 = query.getOrDefault("LoadBalancerArn")
  valid_595118 = validateParameter(valid_595118, JString, required = true,
                                 default = nil)
  if valid_595118 != nil:
    section.add "LoadBalancerArn", valid_595118
  var valid_595119 = query.getOrDefault("Action")
  valid_595119 = validateParameter(valid_595119, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_595119 != nil:
    section.add "Action", valid_595119
  var valid_595120 = query.getOrDefault("Version")
  valid_595120 = validateParameter(valid_595120, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595120 != nil:
    section.add "Version", valid_595120
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
  var valid_595121 = header.getOrDefault("X-Amz-Signature")
  valid_595121 = validateParameter(valid_595121, JString, required = false,
                                 default = nil)
  if valid_595121 != nil:
    section.add "X-Amz-Signature", valid_595121
  var valid_595122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595122 = validateParameter(valid_595122, JString, required = false,
                                 default = nil)
  if valid_595122 != nil:
    section.add "X-Amz-Content-Sha256", valid_595122
  var valid_595123 = header.getOrDefault("X-Amz-Date")
  valid_595123 = validateParameter(valid_595123, JString, required = false,
                                 default = nil)
  if valid_595123 != nil:
    section.add "X-Amz-Date", valid_595123
  var valid_595124 = header.getOrDefault("X-Amz-Credential")
  valid_595124 = validateParameter(valid_595124, JString, required = false,
                                 default = nil)
  if valid_595124 != nil:
    section.add "X-Amz-Credential", valid_595124
  var valid_595125 = header.getOrDefault("X-Amz-Security-Token")
  valid_595125 = validateParameter(valid_595125, JString, required = false,
                                 default = nil)
  if valid_595125 != nil:
    section.add "X-Amz-Security-Token", valid_595125
  var valid_595126 = header.getOrDefault("X-Amz-Algorithm")
  valid_595126 = validateParameter(valid_595126, JString, required = false,
                                 default = nil)
  if valid_595126 != nil:
    section.add "X-Amz-Algorithm", valid_595126
  var valid_595127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595127 = validateParameter(valid_595127, JString, required = false,
                                 default = nil)
  if valid_595127 != nil:
    section.add "X-Amz-SignedHeaders", valid_595127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595128: Call_GetSetIpAddressType_595114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_595128.validator(path, query, header, formData, body)
  let scheme = call_595128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595128.url(scheme.get, call_595128.host, call_595128.base,
                         call_595128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595128, url, valid)

proc call*(call_595129: Call_GetSetIpAddressType_595114; LoadBalancerArn: string;
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
  var query_595130 = newJObject()
  add(query_595130, "IpAddressType", newJString(IpAddressType))
  add(query_595130, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_595130, "Action", newJString(Action))
  add(query_595130, "Version", newJString(Version))
  result = call_595129.call(nil, query_595130, nil, nil, nil)

var getSetIpAddressType* = Call_GetSetIpAddressType_595114(
    name: "getSetIpAddressType", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_GetSetIpAddressType_595115,
    base: "/", url: url_GetSetIpAddressType_595116,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetRulePriorities_595165 = ref object of OpenApiRestCall_593389
proc url_PostSetRulePriorities_595167(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetRulePriorities_595166(path: JsonNode; query: JsonNode;
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
  var valid_595168 = query.getOrDefault("Action")
  valid_595168 = validateParameter(valid_595168, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_595168 != nil:
    section.add "Action", valid_595168
  var valid_595169 = query.getOrDefault("Version")
  valid_595169 = validateParameter(valid_595169, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595169 != nil:
    section.add "Version", valid_595169
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
  var valid_595170 = header.getOrDefault("X-Amz-Signature")
  valid_595170 = validateParameter(valid_595170, JString, required = false,
                                 default = nil)
  if valid_595170 != nil:
    section.add "X-Amz-Signature", valid_595170
  var valid_595171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595171 = validateParameter(valid_595171, JString, required = false,
                                 default = nil)
  if valid_595171 != nil:
    section.add "X-Amz-Content-Sha256", valid_595171
  var valid_595172 = header.getOrDefault("X-Amz-Date")
  valid_595172 = validateParameter(valid_595172, JString, required = false,
                                 default = nil)
  if valid_595172 != nil:
    section.add "X-Amz-Date", valid_595172
  var valid_595173 = header.getOrDefault("X-Amz-Credential")
  valid_595173 = validateParameter(valid_595173, JString, required = false,
                                 default = nil)
  if valid_595173 != nil:
    section.add "X-Amz-Credential", valid_595173
  var valid_595174 = header.getOrDefault("X-Amz-Security-Token")
  valid_595174 = validateParameter(valid_595174, JString, required = false,
                                 default = nil)
  if valid_595174 != nil:
    section.add "X-Amz-Security-Token", valid_595174
  var valid_595175 = header.getOrDefault("X-Amz-Algorithm")
  valid_595175 = validateParameter(valid_595175, JString, required = false,
                                 default = nil)
  if valid_595175 != nil:
    section.add "X-Amz-Algorithm", valid_595175
  var valid_595176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595176 = validateParameter(valid_595176, JString, required = false,
                                 default = nil)
  if valid_595176 != nil:
    section.add "X-Amz-SignedHeaders", valid_595176
  result.add "header", section
  ## parameters in `formData` object:
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RulePriorities` field"
  var valid_595177 = formData.getOrDefault("RulePriorities")
  valid_595177 = validateParameter(valid_595177, JArray, required = true, default = nil)
  if valid_595177 != nil:
    section.add "RulePriorities", valid_595177
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595178: Call_PostSetRulePriorities_595165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_595178.validator(path, query, header, formData, body)
  let scheme = call_595178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595178.url(scheme.get, call_595178.host, call_595178.base,
                         call_595178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595178, url, valid)

proc call*(call_595179: Call_PostSetRulePriorities_595165;
          RulePriorities: JsonNode; Action: string = "SetRulePriorities";
          Version: string = "2015-12-01"): Recallable =
  ## postSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595180 = newJObject()
  var formData_595181 = newJObject()
  if RulePriorities != nil:
    formData_595181.add "RulePriorities", RulePriorities
  add(query_595180, "Action", newJString(Action))
  add(query_595180, "Version", newJString(Version))
  result = call_595179.call(nil, query_595180, nil, formData_595181, nil)

var postSetRulePriorities* = Call_PostSetRulePriorities_595165(
    name: "postSetRulePriorities", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities",
    validator: validate_PostSetRulePriorities_595166, base: "/",
    url: url_PostSetRulePriorities_595167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetRulePriorities_595149 = ref object of OpenApiRestCall_593389
proc url_GetSetRulePriorities_595151(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetRulePriorities_595150(path: JsonNode; query: JsonNode;
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
  var valid_595152 = query.getOrDefault("RulePriorities")
  valid_595152 = validateParameter(valid_595152, JArray, required = true, default = nil)
  if valid_595152 != nil:
    section.add "RulePriorities", valid_595152
  var valid_595153 = query.getOrDefault("Action")
  valid_595153 = validateParameter(valid_595153, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_595153 != nil:
    section.add "Action", valid_595153
  var valid_595154 = query.getOrDefault("Version")
  valid_595154 = validateParameter(valid_595154, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595154 != nil:
    section.add "Version", valid_595154
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
  var valid_595155 = header.getOrDefault("X-Amz-Signature")
  valid_595155 = validateParameter(valid_595155, JString, required = false,
                                 default = nil)
  if valid_595155 != nil:
    section.add "X-Amz-Signature", valid_595155
  var valid_595156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595156 = validateParameter(valid_595156, JString, required = false,
                                 default = nil)
  if valid_595156 != nil:
    section.add "X-Amz-Content-Sha256", valid_595156
  var valid_595157 = header.getOrDefault("X-Amz-Date")
  valid_595157 = validateParameter(valid_595157, JString, required = false,
                                 default = nil)
  if valid_595157 != nil:
    section.add "X-Amz-Date", valid_595157
  var valid_595158 = header.getOrDefault("X-Amz-Credential")
  valid_595158 = validateParameter(valid_595158, JString, required = false,
                                 default = nil)
  if valid_595158 != nil:
    section.add "X-Amz-Credential", valid_595158
  var valid_595159 = header.getOrDefault("X-Amz-Security-Token")
  valid_595159 = validateParameter(valid_595159, JString, required = false,
                                 default = nil)
  if valid_595159 != nil:
    section.add "X-Amz-Security-Token", valid_595159
  var valid_595160 = header.getOrDefault("X-Amz-Algorithm")
  valid_595160 = validateParameter(valid_595160, JString, required = false,
                                 default = nil)
  if valid_595160 != nil:
    section.add "X-Amz-Algorithm", valid_595160
  var valid_595161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595161 = validateParameter(valid_595161, JString, required = false,
                                 default = nil)
  if valid_595161 != nil:
    section.add "X-Amz-SignedHeaders", valid_595161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595162: Call_GetSetRulePriorities_595149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_595162.validator(path, query, header, formData, body)
  let scheme = call_595162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595162.url(scheme.get, call_595162.host, call_595162.base,
                         call_595162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595162, url, valid)

proc call*(call_595163: Call_GetSetRulePriorities_595149; RulePriorities: JsonNode;
          Action: string = "SetRulePriorities"; Version: string = "2015-12-01"): Recallable =
  ## getSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595164 = newJObject()
  if RulePriorities != nil:
    query_595164.add "RulePriorities", RulePriorities
  add(query_595164, "Action", newJString(Action))
  add(query_595164, "Version", newJString(Version))
  result = call_595163.call(nil, query_595164, nil, nil, nil)

var getSetRulePriorities* = Call_GetSetRulePriorities_595149(
    name: "getSetRulePriorities", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities", validator: validate_GetSetRulePriorities_595150,
    base: "/", url: url_GetSetRulePriorities_595151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSecurityGroups_595199 = ref object of OpenApiRestCall_593389
proc url_PostSetSecurityGroups_595201(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetSecurityGroups_595200(path: JsonNode; query: JsonNode;
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
  var valid_595202 = query.getOrDefault("Action")
  valid_595202 = validateParameter(valid_595202, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_595202 != nil:
    section.add "Action", valid_595202
  var valid_595203 = query.getOrDefault("Version")
  valid_595203 = validateParameter(valid_595203, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595203 != nil:
    section.add "Version", valid_595203
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
  var valid_595204 = header.getOrDefault("X-Amz-Signature")
  valid_595204 = validateParameter(valid_595204, JString, required = false,
                                 default = nil)
  if valid_595204 != nil:
    section.add "X-Amz-Signature", valid_595204
  var valid_595205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595205 = validateParameter(valid_595205, JString, required = false,
                                 default = nil)
  if valid_595205 != nil:
    section.add "X-Amz-Content-Sha256", valid_595205
  var valid_595206 = header.getOrDefault("X-Amz-Date")
  valid_595206 = validateParameter(valid_595206, JString, required = false,
                                 default = nil)
  if valid_595206 != nil:
    section.add "X-Amz-Date", valid_595206
  var valid_595207 = header.getOrDefault("X-Amz-Credential")
  valid_595207 = validateParameter(valid_595207, JString, required = false,
                                 default = nil)
  if valid_595207 != nil:
    section.add "X-Amz-Credential", valid_595207
  var valid_595208 = header.getOrDefault("X-Amz-Security-Token")
  valid_595208 = validateParameter(valid_595208, JString, required = false,
                                 default = nil)
  if valid_595208 != nil:
    section.add "X-Amz-Security-Token", valid_595208
  var valid_595209 = header.getOrDefault("X-Amz-Algorithm")
  valid_595209 = validateParameter(valid_595209, JString, required = false,
                                 default = nil)
  if valid_595209 != nil:
    section.add "X-Amz-Algorithm", valid_595209
  var valid_595210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595210 = validateParameter(valid_595210, JString, required = false,
                                 default = nil)
  if valid_595210 != nil:
    section.add "X-Amz-SignedHeaders", valid_595210
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_595211 = formData.getOrDefault("SecurityGroups")
  valid_595211 = validateParameter(valid_595211, JArray, required = true, default = nil)
  if valid_595211 != nil:
    section.add "SecurityGroups", valid_595211
  var valid_595212 = formData.getOrDefault("LoadBalancerArn")
  valid_595212 = validateParameter(valid_595212, JString, required = true,
                                 default = nil)
  if valid_595212 != nil:
    section.add "LoadBalancerArn", valid_595212
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595213: Call_PostSetSecurityGroups_595199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_595213.validator(path, query, header, formData, body)
  let scheme = call_595213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595213.url(scheme.get, call_595213.host, call_595213.base,
                         call_595213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595213, url, valid)

proc call*(call_595214: Call_PostSetSecurityGroups_595199;
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
  var query_595215 = newJObject()
  var formData_595216 = newJObject()
  if SecurityGroups != nil:
    formData_595216.add "SecurityGroups", SecurityGroups
  add(query_595215, "Action", newJString(Action))
  add(query_595215, "Version", newJString(Version))
  add(formData_595216, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_595214.call(nil, query_595215, nil, formData_595216, nil)

var postSetSecurityGroups* = Call_PostSetSecurityGroups_595199(
    name: "postSetSecurityGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups",
    validator: validate_PostSetSecurityGroups_595200, base: "/",
    url: url_PostSetSecurityGroups_595201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSecurityGroups_595182 = ref object of OpenApiRestCall_593389
proc url_GetSetSecurityGroups_595184(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetSecurityGroups_595183(path: JsonNode; query: JsonNode;
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
  var valid_595185 = query.getOrDefault("LoadBalancerArn")
  valid_595185 = validateParameter(valid_595185, JString, required = true,
                                 default = nil)
  if valid_595185 != nil:
    section.add "LoadBalancerArn", valid_595185
  var valid_595186 = query.getOrDefault("SecurityGroups")
  valid_595186 = validateParameter(valid_595186, JArray, required = true, default = nil)
  if valid_595186 != nil:
    section.add "SecurityGroups", valid_595186
  var valid_595187 = query.getOrDefault("Action")
  valid_595187 = validateParameter(valid_595187, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_595187 != nil:
    section.add "Action", valid_595187
  var valid_595188 = query.getOrDefault("Version")
  valid_595188 = validateParameter(valid_595188, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595188 != nil:
    section.add "Version", valid_595188
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
  var valid_595189 = header.getOrDefault("X-Amz-Signature")
  valid_595189 = validateParameter(valid_595189, JString, required = false,
                                 default = nil)
  if valid_595189 != nil:
    section.add "X-Amz-Signature", valid_595189
  var valid_595190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595190 = validateParameter(valid_595190, JString, required = false,
                                 default = nil)
  if valid_595190 != nil:
    section.add "X-Amz-Content-Sha256", valid_595190
  var valid_595191 = header.getOrDefault("X-Amz-Date")
  valid_595191 = validateParameter(valid_595191, JString, required = false,
                                 default = nil)
  if valid_595191 != nil:
    section.add "X-Amz-Date", valid_595191
  var valid_595192 = header.getOrDefault("X-Amz-Credential")
  valid_595192 = validateParameter(valid_595192, JString, required = false,
                                 default = nil)
  if valid_595192 != nil:
    section.add "X-Amz-Credential", valid_595192
  var valid_595193 = header.getOrDefault("X-Amz-Security-Token")
  valid_595193 = validateParameter(valid_595193, JString, required = false,
                                 default = nil)
  if valid_595193 != nil:
    section.add "X-Amz-Security-Token", valid_595193
  var valid_595194 = header.getOrDefault("X-Amz-Algorithm")
  valid_595194 = validateParameter(valid_595194, JString, required = false,
                                 default = nil)
  if valid_595194 != nil:
    section.add "X-Amz-Algorithm", valid_595194
  var valid_595195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595195 = validateParameter(valid_595195, JString, required = false,
                                 default = nil)
  if valid_595195 != nil:
    section.add "X-Amz-SignedHeaders", valid_595195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595196: Call_GetSetSecurityGroups_595182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_595196.validator(path, query, header, formData, body)
  let scheme = call_595196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595196.url(scheme.get, call_595196.host, call_595196.base,
                         call_595196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595196, url, valid)

proc call*(call_595197: Call_GetSetSecurityGroups_595182; LoadBalancerArn: string;
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
  var query_595198 = newJObject()
  add(query_595198, "LoadBalancerArn", newJString(LoadBalancerArn))
  if SecurityGroups != nil:
    query_595198.add "SecurityGroups", SecurityGroups
  add(query_595198, "Action", newJString(Action))
  add(query_595198, "Version", newJString(Version))
  result = call_595197.call(nil, query_595198, nil, nil, nil)

var getSetSecurityGroups* = Call_GetSetSecurityGroups_595182(
    name: "getSetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups", validator: validate_GetSetSecurityGroups_595183,
    base: "/", url: url_GetSetSecurityGroups_595184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubnets_595235 = ref object of OpenApiRestCall_593389
proc url_PostSetSubnets_595237(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetSubnets_595236(path: JsonNode; query: JsonNode;
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
  var valid_595238 = query.getOrDefault("Action")
  valid_595238 = validateParameter(valid_595238, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_595238 != nil:
    section.add "Action", valid_595238
  var valid_595239 = query.getOrDefault("Version")
  valid_595239 = validateParameter(valid_595239, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595239 != nil:
    section.add "Version", valid_595239
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
  var valid_595240 = header.getOrDefault("X-Amz-Signature")
  valid_595240 = validateParameter(valid_595240, JString, required = false,
                                 default = nil)
  if valid_595240 != nil:
    section.add "X-Amz-Signature", valid_595240
  var valid_595241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595241 = validateParameter(valid_595241, JString, required = false,
                                 default = nil)
  if valid_595241 != nil:
    section.add "X-Amz-Content-Sha256", valid_595241
  var valid_595242 = header.getOrDefault("X-Amz-Date")
  valid_595242 = validateParameter(valid_595242, JString, required = false,
                                 default = nil)
  if valid_595242 != nil:
    section.add "X-Amz-Date", valid_595242
  var valid_595243 = header.getOrDefault("X-Amz-Credential")
  valid_595243 = validateParameter(valid_595243, JString, required = false,
                                 default = nil)
  if valid_595243 != nil:
    section.add "X-Amz-Credential", valid_595243
  var valid_595244 = header.getOrDefault("X-Amz-Security-Token")
  valid_595244 = validateParameter(valid_595244, JString, required = false,
                                 default = nil)
  if valid_595244 != nil:
    section.add "X-Amz-Security-Token", valid_595244
  var valid_595245 = header.getOrDefault("X-Amz-Algorithm")
  valid_595245 = validateParameter(valid_595245, JString, required = false,
                                 default = nil)
  if valid_595245 != nil:
    section.add "X-Amz-Algorithm", valid_595245
  var valid_595246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595246 = validateParameter(valid_595246, JString, required = false,
                                 default = nil)
  if valid_595246 != nil:
    section.add "X-Amz-SignedHeaders", valid_595246
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>You cannot specify Elastic IP addresses for your subnets.</p>
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  var valid_595247 = formData.getOrDefault("Subnets")
  valid_595247 = validateParameter(valid_595247, JArray, required = false,
                                 default = nil)
  if valid_595247 != nil:
    section.add "Subnets", valid_595247
  var valid_595248 = formData.getOrDefault("SubnetMappings")
  valid_595248 = validateParameter(valid_595248, JArray, required = false,
                                 default = nil)
  if valid_595248 != nil:
    section.add "SubnetMappings", valid_595248
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_595249 = formData.getOrDefault("LoadBalancerArn")
  valid_595249 = validateParameter(valid_595249, JString, required = true,
                                 default = nil)
  if valid_595249 != nil:
    section.add "LoadBalancerArn", valid_595249
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595250: Call_PostSetSubnets_595235; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  let valid = call_595250.validator(path, query, header, formData, body)
  let scheme = call_595250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595250.url(scheme.get, call_595250.host, call_595250.base,
                         call_595250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595250, url, valid)

proc call*(call_595251: Call_PostSetSubnets_595235; LoadBalancerArn: string;
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
  var query_595252 = newJObject()
  var formData_595253 = newJObject()
  if Subnets != nil:
    formData_595253.add "Subnets", Subnets
  add(query_595252, "Action", newJString(Action))
  if SubnetMappings != nil:
    formData_595253.add "SubnetMappings", SubnetMappings
  add(query_595252, "Version", newJString(Version))
  add(formData_595253, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_595251.call(nil, query_595252, nil, formData_595253, nil)

var postSetSubnets* = Call_PostSetSubnets_595235(name: "postSetSubnets",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_PostSetSubnets_595236,
    base: "/", url: url_PostSetSubnets_595237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubnets_595217 = ref object of OpenApiRestCall_593389
proc url_GetSetSubnets_595219(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetSubnets_595218(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595220 = query.getOrDefault("SubnetMappings")
  valid_595220 = validateParameter(valid_595220, JArray, required = false,
                                 default = nil)
  if valid_595220 != nil:
    section.add "SubnetMappings", valid_595220
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_595221 = query.getOrDefault("LoadBalancerArn")
  valid_595221 = validateParameter(valid_595221, JString, required = true,
                                 default = nil)
  if valid_595221 != nil:
    section.add "LoadBalancerArn", valid_595221
  var valid_595222 = query.getOrDefault("Action")
  valid_595222 = validateParameter(valid_595222, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_595222 != nil:
    section.add "Action", valid_595222
  var valid_595223 = query.getOrDefault("Subnets")
  valid_595223 = validateParameter(valid_595223, JArray, required = false,
                                 default = nil)
  if valid_595223 != nil:
    section.add "Subnets", valid_595223
  var valid_595224 = query.getOrDefault("Version")
  valid_595224 = validateParameter(valid_595224, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595224 != nil:
    section.add "Version", valid_595224
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
  var valid_595225 = header.getOrDefault("X-Amz-Signature")
  valid_595225 = validateParameter(valid_595225, JString, required = false,
                                 default = nil)
  if valid_595225 != nil:
    section.add "X-Amz-Signature", valid_595225
  var valid_595226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595226 = validateParameter(valid_595226, JString, required = false,
                                 default = nil)
  if valid_595226 != nil:
    section.add "X-Amz-Content-Sha256", valid_595226
  var valid_595227 = header.getOrDefault("X-Amz-Date")
  valid_595227 = validateParameter(valid_595227, JString, required = false,
                                 default = nil)
  if valid_595227 != nil:
    section.add "X-Amz-Date", valid_595227
  var valid_595228 = header.getOrDefault("X-Amz-Credential")
  valid_595228 = validateParameter(valid_595228, JString, required = false,
                                 default = nil)
  if valid_595228 != nil:
    section.add "X-Amz-Credential", valid_595228
  var valid_595229 = header.getOrDefault("X-Amz-Security-Token")
  valid_595229 = validateParameter(valid_595229, JString, required = false,
                                 default = nil)
  if valid_595229 != nil:
    section.add "X-Amz-Security-Token", valid_595229
  var valid_595230 = header.getOrDefault("X-Amz-Algorithm")
  valid_595230 = validateParameter(valid_595230, JString, required = false,
                                 default = nil)
  if valid_595230 != nil:
    section.add "X-Amz-Algorithm", valid_595230
  var valid_595231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595231 = validateParameter(valid_595231, JString, required = false,
                                 default = nil)
  if valid_595231 != nil:
    section.add "X-Amz-SignedHeaders", valid_595231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595232: Call_GetSetSubnets_595217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  let valid = call_595232.validator(path, query, header, formData, body)
  let scheme = call_595232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595232.url(scheme.get, call_595232.host, call_595232.base,
                         call_595232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595232, url, valid)

proc call*(call_595233: Call_GetSetSubnets_595217; LoadBalancerArn: string;
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
  var query_595234 = newJObject()
  if SubnetMappings != nil:
    query_595234.add "SubnetMappings", SubnetMappings
  add(query_595234, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_595234, "Action", newJString(Action))
  if Subnets != nil:
    query_595234.add "Subnets", Subnets
  add(query_595234, "Version", newJString(Version))
  result = call_595233.call(nil, query_595234, nil, nil, nil)

var getSetSubnets* = Call_GetSetSubnets_595217(name: "getSetSubnets",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_GetSetSubnets_595218,
    base: "/", url: url_GetSetSubnets_595219, schemes: {Scheme.Https, Scheme.Http})
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
