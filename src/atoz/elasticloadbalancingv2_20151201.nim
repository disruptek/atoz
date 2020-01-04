
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
  Call_PostAddListenerCertificates_601999 = ref object of OpenApiRestCall_601389
proc url_PostAddListenerCertificates_602001(protocol: Scheme; host: string;
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

proc validate_PostAddListenerCertificates_602000(path: JsonNode; query: JsonNode;
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
  var valid_602002 = query.getOrDefault("Action")
  valid_602002 = validateParameter(valid_602002, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_602002 != nil:
    section.add "Action", valid_602002
  var valid_602003 = query.getOrDefault("Version")
  valid_602003 = validateParameter(valid_602003, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602003 != nil:
    section.add "Version", valid_602003
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602004 = header.getOrDefault("X-Amz-Signature")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Signature", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Content-Sha256", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Date")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Date", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Credential")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Credential", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Security-Token")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Security-Token", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Algorithm")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Algorithm", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-SignedHeaders", valid_602010
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_602011 = formData.getOrDefault("Certificates")
  valid_602011 = validateParameter(valid_602011, JArray, required = true, default = nil)
  if valid_602011 != nil:
    section.add "Certificates", valid_602011
  var valid_602012 = formData.getOrDefault("ListenerArn")
  valid_602012 = validateParameter(valid_602012, JString, required = true,
                                 default = nil)
  if valid_602012 != nil:
    section.add "ListenerArn", valid_602012
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602013: Call_PostAddListenerCertificates_601999; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602013.validator(path, query, header, formData, body)
  let scheme = call_602013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602013.url(scheme.get, call_602013.host, call_602013.base,
                         call_602013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602013, url, valid)

proc call*(call_602014: Call_PostAddListenerCertificates_601999;
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
  var query_602015 = newJObject()
  var formData_602016 = newJObject()
  if Certificates != nil:
    formData_602016.add "Certificates", Certificates
  add(formData_602016, "ListenerArn", newJString(ListenerArn))
  add(query_602015, "Action", newJString(Action))
  add(query_602015, "Version", newJString(Version))
  result = call_602014.call(nil, query_602015, nil, formData_602016, nil)

var postAddListenerCertificates* = Call_PostAddListenerCertificates_601999(
    name: "postAddListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_PostAddListenerCertificates_602000, base: "/",
    url: url_PostAddListenerCertificates_602001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddListenerCertificates_601727 = ref object of OpenApiRestCall_601389
proc url_GetAddListenerCertificates_601729(protocol: Scheme; host: string;
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

proc validate_GetAddListenerCertificates_601728(path: JsonNode; query: JsonNode;
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
  var valid_601841 = query.getOrDefault("ListenerArn")
  valid_601841 = validateParameter(valid_601841, JString, required = true,
                                 default = nil)
  if valid_601841 != nil:
    section.add "ListenerArn", valid_601841
  var valid_601842 = query.getOrDefault("Certificates")
  valid_601842 = validateParameter(valid_601842, JArray, required = true, default = nil)
  if valid_601842 != nil:
    section.add "Certificates", valid_601842
  var valid_601856 = query.getOrDefault("Action")
  valid_601856 = validateParameter(valid_601856, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_601856 != nil:
    section.add "Action", valid_601856
  var valid_601857 = query.getOrDefault("Version")
  valid_601857 = validateParameter(valid_601857, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601857 != nil:
    section.add "Version", valid_601857
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601858 = header.getOrDefault("X-Amz-Signature")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Signature", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Content-Sha256", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Date")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Date", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Credential")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Credential", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Security-Token")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Security-Token", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Algorithm")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Algorithm", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-SignedHeaders", valid_601864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601887: Call_GetAddListenerCertificates_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601887.validator(path, query, header, formData, body)
  let scheme = call_601887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601887.url(scheme.get, call_601887.host, call_601887.base,
                         call_601887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601887, url, valid)

proc call*(call_601958: Call_GetAddListenerCertificates_601727;
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
  var query_601959 = newJObject()
  add(query_601959, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_601959.add "Certificates", Certificates
  add(query_601959, "Action", newJString(Action))
  add(query_601959, "Version", newJString(Version))
  result = call_601958.call(nil, query_601959, nil, nil, nil)

var getAddListenerCertificates* = Call_GetAddListenerCertificates_601727(
    name: "getAddListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_GetAddListenerCertificates_601728, base: "/",
    url: url_GetAddListenerCertificates_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTags_602034 = ref object of OpenApiRestCall_601389
proc url_PostAddTags_602036(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddTags_602035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602037 = query.getOrDefault("Action")
  valid_602037 = validateParameter(valid_602037, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_602037 != nil:
    section.add "Action", valid_602037
  var valid_602038 = query.getOrDefault("Version")
  valid_602038 = validateParameter(valid_602038, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602038 != nil:
    section.add "Version", valid_602038
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602039 = header.getOrDefault("X-Amz-Signature")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Signature", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Content-Sha256", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Date")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Date", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Credential")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Credential", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Security-Token")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Security-Token", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Algorithm")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Algorithm", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-SignedHeaders", valid_602045
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_602046 = formData.getOrDefault("ResourceArns")
  valid_602046 = validateParameter(valid_602046, JArray, required = true, default = nil)
  if valid_602046 != nil:
    section.add "ResourceArns", valid_602046
  var valid_602047 = formData.getOrDefault("Tags")
  valid_602047 = validateParameter(valid_602047, JArray, required = true, default = nil)
  if valid_602047 != nil:
    section.add "Tags", valid_602047
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602048: Call_PostAddTags_602034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_602048.validator(path, query, header, formData, body)
  let scheme = call_602048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602048.url(scheme.get, call_602048.host, call_602048.base,
                         call_602048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602048, url, valid)

proc call*(call_602049: Call_PostAddTags_602034; ResourceArns: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2015-12-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Version: string (required)
  var query_602050 = newJObject()
  var formData_602051 = newJObject()
  if ResourceArns != nil:
    formData_602051.add "ResourceArns", ResourceArns
  add(query_602050, "Action", newJString(Action))
  if Tags != nil:
    formData_602051.add "Tags", Tags
  add(query_602050, "Version", newJString(Version))
  result = call_602049.call(nil, query_602050, nil, formData_602051, nil)

var postAddTags* = Call_PostAddTags_602034(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_602035,
                                        base: "/", url: url_PostAddTags_602036,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_602017 = ref object of OpenApiRestCall_601389
proc url_GetAddTags_602019(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAddTags_602018(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602020 = query.getOrDefault("Tags")
  valid_602020 = validateParameter(valid_602020, JArray, required = true, default = nil)
  if valid_602020 != nil:
    section.add "Tags", valid_602020
  var valid_602021 = query.getOrDefault("ResourceArns")
  valid_602021 = validateParameter(valid_602021, JArray, required = true, default = nil)
  if valid_602021 != nil:
    section.add "ResourceArns", valid_602021
  var valid_602022 = query.getOrDefault("Action")
  valid_602022 = validateParameter(valid_602022, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_602022 != nil:
    section.add "Action", valid_602022
  var valid_602023 = query.getOrDefault("Version")
  valid_602023 = validateParameter(valid_602023, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602023 != nil:
    section.add "Version", valid_602023
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602024 = header.getOrDefault("X-Amz-Signature")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Signature", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Content-Sha256", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Date")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Date", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Credential")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Credential", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Security-Token")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Security-Token", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Algorithm")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Algorithm", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-SignedHeaders", valid_602030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602031: Call_GetAddTags_602017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_602031.validator(path, query, header, formData, body)
  let scheme = call_602031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602031.url(scheme.get, call_602031.host, call_602031.base,
                         call_602031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602031, url, valid)

proc call*(call_602032: Call_GetAddTags_602017; Tags: JsonNode;
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
  var query_602033 = newJObject()
  if Tags != nil:
    query_602033.add "Tags", Tags
  if ResourceArns != nil:
    query_602033.add "ResourceArns", ResourceArns
  add(query_602033, "Action", newJString(Action))
  add(query_602033, "Version", newJString(Version))
  result = call_602032.call(nil, query_602033, nil, nil, nil)

var getAddTags* = Call_GetAddTags_602017(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_602018,
                                      base: "/", url: url_GetAddTags_602019,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateListener_602073 = ref object of OpenApiRestCall_601389
proc url_PostCreateListener_602075(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateListener_602074(path: JsonNode; query: JsonNode;
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
  var valid_602076 = query.getOrDefault("Action")
  valid_602076 = validateParameter(valid_602076, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_602076 != nil:
    section.add "Action", valid_602076
  var valid_602077 = query.getOrDefault("Version")
  valid_602077 = validateParameter(valid_602077, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602077 != nil:
    section.add "Version", valid_602077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602078 = header.getOrDefault("X-Amz-Signature")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Signature", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Content-Sha256", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Date")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Date", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Credential")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Credential", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Security-Token")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Security-Token", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Algorithm")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Algorithm", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-SignedHeaders", valid_602084
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
  var valid_602085 = formData.getOrDefault("Port")
  valid_602085 = validateParameter(valid_602085, JInt, required = true, default = nil)
  if valid_602085 != nil:
    section.add "Port", valid_602085
  var valid_602086 = formData.getOrDefault("Certificates")
  valid_602086 = validateParameter(valid_602086, JArray, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "Certificates", valid_602086
  var valid_602087 = formData.getOrDefault("DefaultActions")
  valid_602087 = validateParameter(valid_602087, JArray, required = true, default = nil)
  if valid_602087 != nil:
    section.add "DefaultActions", valid_602087
  var valid_602088 = formData.getOrDefault("Protocol")
  valid_602088 = validateParameter(valid_602088, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_602088 != nil:
    section.add "Protocol", valid_602088
  var valid_602089 = formData.getOrDefault("SslPolicy")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "SslPolicy", valid_602089
  var valid_602090 = formData.getOrDefault("LoadBalancerArn")
  valid_602090 = validateParameter(valid_602090, JString, required = true,
                                 default = nil)
  if valid_602090 != nil:
    section.add "LoadBalancerArn", valid_602090
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602091: Call_PostCreateListener_602073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602091.validator(path, query, header, formData, body)
  let scheme = call_602091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602091.url(scheme.get, call_602091.host, call_602091.base,
                         call_602091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602091, url, valid)

proc call*(call_602092: Call_PostCreateListener_602073; Port: int;
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
  var query_602093 = newJObject()
  var formData_602094 = newJObject()
  add(formData_602094, "Port", newJInt(Port))
  if Certificates != nil:
    formData_602094.add "Certificates", Certificates
  if DefaultActions != nil:
    formData_602094.add "DefaultActions", DefaultActions
  add(formData_602094, "Protocol", newJString(Protocol))
  add(query_602093, "Action", newJString(Action))
  add(formData_602094, "SslPolicy", newJString(SslPolicy))
  add(query_602093, "Version", newJString(Version))
  add(formData_602094, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_602092.call(nil, query_602093, nil, formData_602094, nil)

var postCreateListener* = Call_PostCreateListener_602073(
    name: "postCreateListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=CreateListener",
    validator: validate_PostCreateListener_602074, base: "/",
    url: url_PostCreateListener_602075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateListener_602052 = ref object of OpenApiRestCall_601389
proc url_GetCreateListener_602054(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateListener_602053(path: JsonNode; query: JsonNode;
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
  var valid_602055 = query.getOrDefault("SslPolicy")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "SslPolicy", valid_602055
  var valid_602056 = query.getOrDefault("Certificates")
  valid_602056 = validateParameter(valid_602056, JArray, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "Certificates", valid_602056
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_602057 = query.getOrDefault("LoadBalancerArn")
  valid_602057 = validateParameter(valid_602057, JString, required = true,
                                 default = nil)
  if valid_602057 != nil:
    section.add "LoadBalancerArn", valid_602057
  var valid_602058 = query.getOrDefault("DefaultActions")
  valid_602058 = validateParameter(valid_602058, JArray, required = true, default = nil)
  if valid_602058 != nil:
    section.add "DefaultActions", valid_602058
  var valid_602059 = query.getOrDefault("Action")
  valid_602059 = validateParameter(valid_602059, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_602059 != nil:
    section.add "Action", valid_602059
  var valid_602060 = query.getOrDefault("Protocol")
  valid_602060 = validateParameter(valid_602060, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_602060 != nil:
    section.add "Protocol", valid_602060
  var valid_602061 = query.getOrDefault("Port")
  valid_602061 = validateParameter(valid_602061, JInt, required = true, default = nil)
  if valid_602061 != nil:
    section.add "Port", valid_602061
  var valid_602062 = query.getOrDefault("Version")
  valid_602062 = validateParameter(valid_602062, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602062 != nil:
    section.add "Version", valid_602062
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602063 = header.getOrDefault("X-Amz-Signature")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Signature", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Content-Sha256", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Date")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Date", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Credential")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Credential", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Security-Token")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Security-Token", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Algorithm")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Algorithm", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-SignedHeaders", valid_602069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602070: Call_GetCreateListener_602052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602070.validator(path, query, header, formData, body)
  let scheme = call_602070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602070.url(scheme.get, call_602070.host, call_602070.base,
                         call_602070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602070, url, valid)

proc call*(call_602071: Call_GetCreateListener_602052; LoadBalancerArn: string;
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
  var query_602072 = newJObject()
  add(query_602072, "SslPolicy", newJString(SslPolicy))
  if Certificates != nil:
    query_602072.add "Certificates", Certificates
  add(query_602072, "LoadBalancerArn", newJString(LoadBalancerArn))
  if DefaultActions != nil:
    query_602072.add "DefaultActions", DefaultActions
  add(query_602072, "Action", newJString(Action))
  add(query_602072, "Protocol", newJString(Protocol))
  add(query_602072, "Port", newJInt(Port))
  add(query_602072, "Version", newJString(Version))
  result = call_602071.call(nil, query_602072, nil, nil, nil)

var getCreateListener* = Call_GetCreateListener_602052(name: "getCreateListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateListener", validator: validate_GetCreateListener_602053,
    base: "/", url: url_GetCreateListener_602054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_602118 = ref object of OpenApiRestCall_601389
proc url_PostCreateLoadBalancer_602120(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateLoadBalancer_602119(path: JsonNode; query: JsonNode;
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
  var valid_602121 = query.getOrDefault("Action")
  valid_602121 = validateParameter(valid_602121, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_602121 != nil:
    section.add "Action", valid_602121
  var valid_602122 = query.getOrDefault("Version")
  valid_602122 = validateParameter(valid_602122, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602122 != nil:
    section.add "Version", valid_602122
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602123 = header.getOrDefault("X-Amz-Signature")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Signature", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Content-Sha256", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Date")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Date", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Credential")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Credential", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Security-Token")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Security-Token", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Algorithm")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Algorithm", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-SignedHeaders", valid_602129
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
  var valid_602130 = formData.getOrDefault("IpAddressType")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_602130 != nil:
    section.add "IpAddressType", valid_602130
  var valid_602131 = formData.getOrDefault("Scheme")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_602131 != nil:
    section.add "Scheme", valid_602131
  var valid_602132 = formData.getOrDefault("SecurityGroups")
  valid_602132 = validateParameter(valid_602132, JArray, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "SecurityGroups", valid_602132
  var valid_602133 = formData.getOrDefault("Subnets")
  valid_602133 = validateParameter(valid_602133, JArray, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "Subnets", valid_602133
  var valid_602134 = formData.getOrDefault("Type")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = newJString("application"))
  if valid_602134 != nil:
    section.add "Type", valid_602134
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_602135 = formData.getOrDefault("Name")
  valid_602135 = validateParameter(valid_602135, JString, required = true,
                                 default = nil)
  if valid_602135 != nil:
    section.add "Name", valid_602135
  var valid_602136 = formData.getOrDefault("Tags")
  valid_602136 = validateParameter(valid_602136, JArray, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "Tags", valid_602136
  var valid_602137 = formData.getOrDefault("SubnetMappings")
  valid_602137 = validateParameter(valid_602137, JArray, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "SubnetMappings", valid_602137
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602138: Call_PostCreateLoadBalancer_602118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602138.validator(path, query, header, formData, body)
  let scheme = call_602138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602138.url(scheme.get, call_602138.host, call_602138.base,
                         call_602138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602138, url, valid)

proc call*(call_602139: Call_PostCreateLoadBalancer_602118; Name: string;
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
  var query_602140 = newJObject()
  var formData_602141 = newJObject()
  add(formData_602141, "IpAddressType", newJString(IpAddressType))
  add(formData_602141, "Scheme", newJString(Scheme))
  if SecurityGroups != nil:
    formData_602141.add "SecurityGroups", SecurityGroups
  if Subnets != nil:
    formData_602141.add "Subnets", Subnets
  add(formData_602141, "Type", newJString(Type))
  add(query_602140, "Action", newJString(Action))
  add(formData_602141, "Name", newJString(Name))
  if Tags != nil:
    formData_602141.add "Tags", Tags
  if SubnetMappings != nil:
    formData_602141.add "SubnetMappings", SubnetMappings
  add(query_602140, "Version", newJString(Version))
  result = call_602139.call(nil, query_602140, nil, formData_602141, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_602118(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_602119, base: "/",
    url: url_PostCreateLoadBalancer_602120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_602095 = ref object of OpenApiRestCall_601389
proc url_GetCreateLoadBalancer_602097(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateLoadBalancer_602096(path: JsonNode; query: JsonNode;
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
  var valid_602098 = query.getOrDefault("SubnetMappings")
  valid_602098 = validateParameter(valid_602098, JArray, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "SubnetMappings", valid_602098
  var valid_602099 = query.getOrDefault("Type")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = newJString("application"))
  if valid_602099 != nil:
    section.add "Type", valid_602099
  var valid_602100 = query.getOrDefault("Tags")
  valid_602100 = validateParameter(valid_602100, JArray, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "Tags", valid_602100
  var valid_602101 = query.getOrDefault("Scheme")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_602101 != nil:
    section.add "Scheme", valid_602101
  var valid_602102 = query.getOrDefault("IpAddressType")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_602102 != nil:
    section.add "IpAddressType", valid_602102
  var valid_602103 = query.getOrDefault("SecurityGroups")
  valid_602103 = validateParameter(valid_602103, JArray, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "SecurityGroups", valid_602103
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_602104 = query.getOrDefault("Name")
  valid_602104 = validateParameter(valid_602104, JString, required = true,
                                 default = nil)
  if valid_602104 != nil:
    section.add "Name", valid_602104
  var valid_602105 = query.getOrDefault("Action")
  valid_602105 = validateParameter(valid_602105, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_602105 != nil:
    section.add "Action", valid_602105
  var valid_602106 = query.getOrDefault("Subnets")
  valid_602106 = validateParameter(valid_602106, JArray, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "Subnets", valid_602106
  var valid_602107 = query.getOrDefault("Version")
  valid_602107 = validateParameter(valid_602107, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602107 != nil:
    section.add "Version", valid_602107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602108 = header.getOrDefault("X-Amz-Signature")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Signature", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Content-Sha256", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Date")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Date", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Credential")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Credential", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Security-Token")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Security-Token", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Algorithm")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Algorithm", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-SignedHeaders", valid_602114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602115: Call_GetCreateLoadBalancer_602095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602115.validator(path, query, header, formData, body)
  let scheme = call_602115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602115.url(scheme.get, call_602115.host, call_602115.base,
                         call_602115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602115, url, valid)

proc call*(call_602116: Call_GetCreateLoadBalancer_602095; Name: string;
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
  var query_602117 = newJObject()
  if SubnetMappings != nil:
    query_602117.add "SubnetMappings", SubnetMappings
  add(query_602117, "Type", newJString(Type))
  if Tags != nil:
    query_602117.add "Tags", Tags
  add(query_602117, "Scheme", newJString(Scheme))
  add(query_602117, "IpAddressType", newJString(IpAddressType))
  if SecurityGroups != nil:
    query_602117.add "SecurityGroups", SecurityGroups
  add(query_602117, "Name", newJString(Name))
  add(query_602117, "Action", newJString(Action))
  if Subnets != nil:
    query_602117.add "Subnets", Subnets
  add(query_602117, "Version", newJString(Version))
  result = call_602116.call(nil, query_602117, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_602095(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_602096, base: "/",
    url: url_GetCreateLoadBalancer_602097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateRule_602161 = ref object of OpenApiRestCall_601389
proc url_PostCreateRule_602163(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateRule_602162(path: JsonNode; query: JsonNode;
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
  var valid_602164 = query.getOrDefault("Action")
  valid_602164 = validateParameter(valid_602164, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_602164 != nil:
    section.add "Action", valid_602164
  var valid_602165 = query.getOrDefault("Version")
  valid_602165 = validateParameter(valid_602165, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602165 != nil:
    section.add "Version", valid_602165
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602166 = header.getOrDefault("X-Amz-Signature")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Signature", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Content-Sha256", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Date")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Date", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Credential")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Credential", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Security-Token")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Security-Token", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Algorithm")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Algorithm", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-SignedHeaders", valid_602172
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
  var valid_602173 = formData.getOrDefault("Actions")
  valid_602173 = validateParameter(valid_602173, JArray, required = true, default = nil)
  if valid_602173 != nil:
    section.add "Actions", valid_602173
  var valid_602174 = formData.getOrDefault("Conditions")
  valid_602174 = validateParameter(valid_602174, JArray, required = true, default = nil)
  if valid_602174 != nil:
    section.add "Conditions", valid_602174
  var valid_602175 = formData.getOrDefault("ListenerArn")
  valid_602175 = validateParameter(valid_602175, JString, required = true,
                                 default = nil)
  if valid_602175 != nil:
    section.add "ListenerArn", valid_602175
  var valid_602176 = formData.getOrDefault("Priority")
  valid_602176 = validateParameter(valid_602176, JInt, required = true, default = nil)
  if valid_602176 != nil:
    section.add "Priority", valid_602176
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602177: Call_PostCreateRule_602161; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_602177.validator(path, query, header, formData, body)
  let scheme = call_602177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602177.url(scheme.get, call_602177.host, call_602177.base,
                         call_602177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602177, url, valid)

proc call*(call_602178: Call_PostCreateRule_602161; Actions: JsonNode;
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
  var query_602179 = newJObject()
  var formData_602180 = newJObject()
  if Actions != nil:
    formData_602180.add "Actions", Actions
  if Conditions != nil:
    formData_602180.add "Conditions", Conditions
  add(formData_602180, "ListenerArn", newJString(ListenerArn))
  add(formData_602180, "Priority", newJInt(Priority))
  add(query_602179, "Action", newJString(Action))
  add(query_602179, "Version", newJString(Version))
  result = call_602178.call(nil, query_602179, nil, formData_602180, nil)

var postCreateRule* = Call_PostCreateRule_602161(name: "postCreateRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_PostCreateRule_602162,
    base: "/", url: url_PostCreateRule_602163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateRule_602142 = ref object of OpenApiRestCall_601389
proc url_GetCreateRule_602144(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateRule_602143(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602145 = query.getOrDefault("Actions")
  valid_602145 = validateParameter(valid_602145, JArray, required = true, default = nil)
  if valid_602145 != nil:
    section.add "Actions", valid_602145
  var valid_602146 = query.getOrDefault("ListenerArn")
  valid_602146 = validateParameter(valid_602146, JString, required = true,
                                 default = nil)
  if valid_602146 != nil:
    section.add "ListenerArn", valid_602146
  var valid_602147 = query.getOrDefault("Priority")
  valid_602147 = validateParameter(valid_602147, JInt, required = true, default = nil)
  if valid_602147 != nil:
    section.add "Priority", valid_602147
  var valid_602148 = query.getOrDefault("Action")
  valid_602148 = validateParameter(valid_602148, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_602148 != nil:
    section.add "Action", valid_602148
  var valid_602149 = query.getOrDefault("Version")
  valid_602149 = validateParameter(valid_602149, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602149 != nil:
    section.add "Version", valid_602149
  var valid_602150 = query.getOrDefault("Conditions")
  valid_602150 = validateParameter(valid_602150, JArray, required = true, default = nil)
  if valid_602150 != nil:
    section.add "Conditions", valid_602150
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602151 = header.getOrDefault("X-Amz-Signature")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Signature", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Content-Sha256", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Date")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Date", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Credential")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Credential", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Security-Token")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Security-Token", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Algorithm")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Algorithm", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-SignedHeaders", valid_602157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602158: Call_GetCreateRule_602142; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_602158.validator(path, query, header, formData, body)
  let scheme = call_602158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602158.url(scheme.get, call_602158.host, call_602158.base,
                         call_602158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602158, url, valid)

proc call*(call_602159: Call_GetCreateRule_602142; Actions: JsonNode;
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
  var query_602160 = newJObject()
  if Actions != nil:
    query_602160.add "Actions", Actions
  add(query_602160, "ListenerArn", newJString(ListenerArn))
  add(query_602160, "Priority", newJInt(Priority))
  add(query_602160, "Action", newJString(Action))
  add(query_602160, "Version", newJString(Version))
  if Conditions != nil:
    query_602160.add "Conditions", Conditions
  result = call_602159.call(nil, query_602160, nil, nil, nil)

var getCreateRule* = Call_GetCreateRule_602142(name: "getCreateRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_GetCreateRule_602143,
    base: "/", url: url_GetCreateRule_602144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTargetGroup_602210 = ref object of OpenApiRestCall_601389
proc url_PostCreateTargetGroup_602212(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateTargetGroup_602211(path: JsonNode; query: JsonNode;
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
  var valid_602213 = query.getOrDefault("Action")
  valid_602213 = validateParameter(valid_602213, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_602213 != nil:
    section.add "Action", valid_602213
  var valid_602214 = query.getOrDefault("Version")
  valid_602214 = validateParameter(valid_602214, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602214 != nil:
    section.add "Version", valid_602214
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602215 = header.getOrDefault("X-Amz-Signature")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Signature", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Content-Sha256", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Date")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Date", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-Credential")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Credential", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Security-Token")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Security-Token", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Algorithm")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Algorithm", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-SignedHeaders", valid_602221
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
  var valid_602222 = formData.getOrDefault("HealthCheckProtocol")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_602222 != nil:
    section.add "HealthCheckProtocol", valid_602222
  var valid_602223 = formData.getOrDefault("Port")
  valid_602223 = validateParameter(valid_602223, JInt, required = false, default = nil)
  if valid_602223 != nil:
    section.add "Port", valid_602223
  var valid_602224 = formData.getOrDefault("HealthCheckPort")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "HealthCheckPort", valid_602224
  var valid_602225 = formData.getOrDefault("VpcId")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "VpcId", valid_602225
  var valid_602226 = formData.getOrDefault("HealthCheckEnabled")
  valid_602226 = validateParameter(valid_602226, JBool, required = false, default = nil)
  if valid_602226 != nil:
    section.add "HealthCheckEnabled", valid_602226
  var valid_602227 = formData.getOrDefault("HealthCheckPath")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "HealthCheckPath", valid_602227
  var valid_602228 = formData.getOrDefault("TargetType")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = newJString("instance"))
  if valid_602228 != nil:
    section.add "TargetType", valid_602228
  var valid_602229 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_602229 = validateParameter(valid_602229, JInt, required = false, default = nil)
  if valid_602229 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_602229
  var valid_602230 = formData.getOrDefault("HealthyThresholdCount")
  valid_602230 = validateParameter(valid_602230, JInt, required = false, default = nil)
  if valid_602230 != nil:
    section.add "HealthyThresholdCount", valid_602230
  var valid_602231 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_602231 = validateParameter(valid_602231, JInt, required = false, default = nil)
  if valid_602231 != nil:
    section.add "HealthCheckIntervalSeconds", valid_602231
  var valid_602232 = formData.getOrDefault("Protocol")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_602232 != nil:
    section.add "Protocol", valid_602232
  var valid_602233 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_602233 = validateParameter(valid_602233, JInt, required = false, default = nil)
  if valid_602233 != nil:
    section.add "UnhealthyThresholdCount", valid_602233
  var valid_602234 = formData.getOrDefault("Matcher.HttpCode")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "Matcher.HttpCode", valid_602234
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_602235 = formData.getOrDefault("Name")
  valid_602235 = validateParameter(valid_602235, JString, required = true,
                                 default = nil)
  if valid_602235 != nil:
    section.add "Name", valid_602235
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602236: Call_PostCreateTargetGroup_602210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602236.validator(path, query, header, formData, body)
  let scheme = call_602236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602236.url(scheme.get, call_602236.host, call_602236.base,
                         call_602236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602236, url, valid)

proc call*(call_602237: Call_PostCreateTargetGroup_602210; Name: string;
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
  var query_602238 = newJObject()
  var formData_602239 = newJObject()
  add(formData_602239, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_602239, "Port", newJInt(Port))
  add(formData_602239, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_602239, "VpcId", newJString(VpcId))
  add(formData_602239, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_602239, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_602239, "TargetType", newJString(TargetType))
  add(formData_602239, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_602239, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_602239, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_602239, "Protocol", newJString(Protocol))
  add(formData_602239, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_602239, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_602238, "Action", newJString(Action))
  add(formData_602239, "Name", newJString(Name))
  add(query_602238, "Version", newJString(Version))
  result = call_602237.call(nil, query_602238, nil, formData_602239, nil)

var postCreateTargetGroup* = Call_PostCreateTargetGroup_602210(
    name: "postCreateTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup",
    validator: validate_PostCreateTargetGroup_602211, base: "/",
    url: url_PostCreateTargetGroup_602212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTargetGroup_602181 = ref object of OpenApiRestCall_601389
proc url_GetCreateTargetGroup_602183(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateTargetGroup_602182(path: JsonNode; query: JsonNode;
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
  var valid_602184 = query.getOrDefault("HealthCheckPort")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "HealthCheckPort", valid_602184
  var valid_602185 = query.getOrDefault("TargetType")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = newJString("instance"))
  if valid_602185 != nil:
    section.add "TargetType", valid_602185
  var valid_602186 = query.getOrDefault("HealthCheckPath")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "HealthCheckPath", valid_602186
  var valid_602187 = query.getOrDefault("VpcId")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "VpcId", valid_602187
  var valid_602188 = query.getOrDefault("HealthCheckProtocol")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_602188 != nil:
    section.add "HealthCheckProtocol", valid_602188
  var valid_602189 = query.getOrDefault("Matcher.HttpCode")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "Matcher.HttpCode", valid_602189
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_602190 = query.getOrDefault("Name")
  valid_602190 = validateParameter(valid_602190, JString, required = true,
                                 default = nil)
  if valid_602190 != nil:
    section.add "Name", valid_602190
  var valid_602191 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_602191 = validateParameter(valid_602191, JInt, required = false, default = nil)
  if valid_602191 != nil:
    section.add "HealthCheckIntervalSeconds", valid_602191
  var valid_602192 = query.getOrDefault("HealthCheckEnabled")
  valid_602192 = validateParameter(valid_602192, JBool, required = false, default = nil)
  if valid_602192 != nil:
    section.add "HealthCheckEnabled", valid_602192
  var valid_602193 = query.getOrDefault("HealthyThresholdCount")
  valid_602193 = validateParameter(valid_602193, JInt, required = false, default = nil)
  if valid_602193 != nil:
    section.add "HealthyThresholdCount", valid_602193
  var valid_602194 = query.getOrDefault("UnhealthyThresholdCount")
  valid_602194 = validateParameter(valid_602194, JInt, required = false, default = nil)
  if valid_602194 != nil:
    section.add "UnhealthyThresholdCount", valid_602194
  var valid_602195 = query.getOrDefault("Action")
  valid_602195 = validateParameter(valid_602195, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_602195 != nil:
    section.add "Action", valid_602195
  var valid_602196 = query.getOrDefault("Protocol")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_602196 != nil:
    section.add "Protocol", valid_602196
  var valid_602197 = query.getOrDefault("Port")
  valid_602197 = validateParameter(valid_602197, JInt, required = false, default = nil)
  if valid_602197 != nil:
    section.add "Port", valid_602197
  var valid_602198 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_602198 = validateParameter(valid_602198, JInt, required = false, default = nil)
  if valid_602198 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_602198
  var valid_602199 = query.getOrDefault("Version")
  valid_602199 = validateParameter(valid_602199, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602199 != nil:
    section.add "Version", valid_602199
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602200 = header.getOrDefault("X-Amz-Signature")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Signature", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Content-Sha256", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Date")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Date", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-Credential")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-Credential", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-Security-Token")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Security-Token", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-Algorithm")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Algorithm", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-SignedHeaders", valid_602206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602207: Call_GetCreateTargetGroup_602181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602207.validator(path, query, header, formData, body)
  let scheme = call_602207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602207.url(scheme.get, call_602207.host, call_602207.base,
                         call_602207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602207, url, valid)

proc call*(call_602208: Call_GetCreateTargetGroup_602181; Name: string;
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
  var query_602209 = newJObject()
  add(query_602209, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_602209, "TargetType", newJString(TargetType))
  add(query_602209, "HealthCheckPath", newJString(HealthCheckPath))
  add(query_602209, "VpcId", newJString(VpcId))
  add(query_602209, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_602209, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_602209, "Name", newJString(Name))
  add(query_602209, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_602209, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_602209, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_602209, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_602209, "Action", newJString(Action))
  add(query_602209, "Protocol", newJString(Protocol))
  add(query_602209, "Port", newJInt(Port))
  add(query_602209, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_602209, "Version", newJString(Version))
  result = call_602208.call(nil, query_602209, nil, nil, nil)

var getCreateTargetGroup* = Call_GetCreateTargetGroup_602181(
    name: "getCreateTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup", validator: validate_GetCreateTargetGroup_602182,
    base: "/", url: url_GetCreateTargetGroup_602183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteListener_602256 = ref object of OpenApiRestCall_601389
proc url_PostDeleteListener_602258(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteListener_602257(path: JsonNode; query: JsonNode;
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
  var valid_602259 = query.getOrDefault("Action")
  valid_602259 = validateParameter(valid_602259, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_602259 != nil:
    section.add "Action", valid_602259
  var valid_602260 = query.getOrDefault("Version")
  valid_602260 = validateParameter(valid_602260, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602260 != nil:
    section.add "Version", valid_602260
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602261 = header.getOrDefault("X-Amz-Signature")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Signature", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Content-Sha256", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-Date")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Date", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Credential")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Credential", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-Security-Token")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Security-Token", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-Algorithm")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Algorithm", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-SignedHeaders", valid_602267
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_602268 = formData.getOrDefault("ListenerArn")
  valid_602268 = validateParameter(valid_602268, JString, required = true,
                                 default = nil)
  if valid_602268 != nil:
    section.add "ListenerArn", valid_602268
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602269: Call_PostDeleteListener_602256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_602269.validator(path, query, header, formData, body)
  let scheme = call_602269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602269.url(scheme.get, call_602269.host, call_602269.base,
                         call_602269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602269, url, valid)

proc call*(call_602270: Call_PostDeleteListener_602256; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602271 = newJObject()
  var formData_602272 = newJObject()
  add(formData_602272, "ListenerArn", newJString(ListenerArn))
  add(query_602271, "Action", newJString(Action))
  add(query_602271, "Version", newJString(Version))
  result = call_602270.call(nil, query_602271, nil, formData_602272, nil)

var postDeleteListener* = Call_PostDeleteListener_602256(
    name: "postDeleteListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=DeleteListener",
    validator: validate_PostDeleteListener_602257, base: "/",
    url: url_PostDeleteListener_602258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteListener_602240 = ref object of OpenApiRestCall_601389
proc url_GetDeleteListener_602242(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteListener_602241(path: JsonNode; query: JsonNode;
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
  var valid_602243 = query.getOrDefault("ListenerArn")
  valid_602243 = validateParameter(valid_602243, JString, required = true,
                                 default = nil)
  if valid_602243 != nil:
    section.add "ListenerArn", valid_602243
  var valid_602244 = query.getOrDefault("Action")
  valid_602244 = validateParameter(valid_602244, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_602244 != nil:
    section.add "Action", valid_602244
  var valid_602245 = query.getOrDefault("Version")
  valid_602245 = validateParameter(valid_602245, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602245 != nil:
    section.add "Version", valid_602245
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602246 = header.getOrDefault("X-Amz-Signature")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Signature", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Content-Sha256", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Date")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Date", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Credential")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Credential", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Security-Token")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Security-Token", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Algorithm")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Algorithm", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-SignedHeaders", valid_602252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602253: Call_GetDeleteListener_602240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_602253.validator(path, query, header, formData, body)
  let scheme = call_602253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602253.url(scheme.get, call_602253.host, call_602253.base,
                         call_602253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602253, url, valid)

proc call*(call_602254: Call_GetDeleteListener_602240; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602255 = newJObject()
  add(query_602255, "ListenerArn", newJString(ListenerArn))
  add(query_602255, "Action", newJString(Action))
  add(query_602255, "Version", newJString(Version))
  result = call_602254.call(nil, query_602255, nil, nil, nil)

var getDeleteListener* = Call_GetDeleteListener_602240(name: "getDeleteListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteListener", validator: validate_GetDeleteListener_602241,
    base: "/", url: url_GetDeleteListener_602242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_602289 = ref object of OpenApiRestCall_601389
proc url_PostDeleteLoadBalancer_602291(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteLoadBalancer_602290(path: JsonNode; query: JsonNode;
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
  var valid_602292 = query.getOrDefault("Action")
  valid_602292 = validateParameter(valid_602292, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_602292 != nil:
    section.add "Action", valid_602292
  var valid_602293 = query.getOrDefault("Version")
  valid_602293 = validateParameter(valid_602293, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602293 != nil:
    section.add "Version", valid_602293
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602294 = header.getOrDefault("X-Amz-Signature")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Signature", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Content-Sha256", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Date")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Date", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Credential")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Credential", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Security-Token")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Security-Token", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Algorithm")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Algorithm", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-SignedHeaders", valid_602300
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_602301 = formData.getOrDefault("LoadBalancerArn")
  valid_602301 = validateParameter(valid_602301, JString, required = true,
                                 default = nil)
  if valid_602301 != nil:
    section.add "LoadBalancerArn", valid_602301
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602302: Call_PostDeleteLoadBalancer_602289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_602302.validator(path, query, header, formData, body)
  let scheme = call_602302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602302.url(scheme.get, call_602302.host, call_602302.base,
                         call_602302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602302, url, valid)

proc call*(call_602303: Call_PostDeleteLoadBalancer_602289;
          LoadBalancerArn: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2015-12-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_602304 = newJObject()
  var formData_602305 = newJObject()
  add(query_602304, "Action", newJString(Action))
  add(query_602304, "Version", newJString(Version))
  add(formData_602305, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_602303.call(nil, query_602304, nil, formData_602305, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_602289(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_602290, base: "/",
    url: url_PostDeleteLoadBalancer_602291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_602273 = ref object of OpenApiRestCall_601389
proc url_GetDeleteLoadBalancer_602275(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteLoadBalancer_602274(path: JsonNode; query: JsonNode;
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
  var valid_602276 = query.getOrDefault("LoadBalancerArn")
  valid_602276 = validateParameter(valid_602276, JString, required = true,
                                 default = nil)
  if valid_602276 != nil:
    section.add "LoadBalancerArn", valid_602276
  var valid_602277 = query.getOrDefault("Action")
  valid_602277 = validateParameter(valid_602277, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_602277 != nil:
    section.add "Action", valid_602277
  var valid_602278 = query.getOrDefault("Version")
  valid_602278 = validateParameter(valid_602278, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602278 != nil:
    section.add "Version", valid_602278
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602279 = header.getOrDefault("X-Amz-Signature")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Signature", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Content-Sha256", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Date")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Date", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Credential")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Credential", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Security-Token")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Security-Token", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Algorithm")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Algorithm", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-SignedHeaders", valid_602285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602286: Call_GetDeleteLoadBalancer_602273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_602286.validator(path, query, header, formData, body)
  let scheme = call_602286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602286.url(scheme.get, call_602286.host, call_602286.base,
                         call_602286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602286, url, valid)

proc call*(call_602287: Call_GetDeleteLoadBalancer_602273; LoadBalancerArn: string;
          Action: string = "DeleteLoadBalancer"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602288 = newJObject()
  add(query_602288, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_602288, "Action", newJString(Action))
  add(query_602288, "Version", newJString(Version))
  result = call_602287.call(nil, query_602288, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_602273(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_602274, base: "/",
    url: url_GetDeleteLoadBalancer_602275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRule_602322 = ref object of OpenApiRestCall_601389
proc url_PostDeleteRule_602324(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteRule_602323(path: JsonNode; query: JsonNode;
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
  var valid_602325 = query.getOrDefault("Action")
  valid_602325 = validateParameter(valid_602325, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_602325 != nil:
    section.add "Action", valid_602325
  var valid_602326 = query.getOrDefault("Version")
  valid_602326 = validateParameter(valid_602326, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602326 != nil:
    section.add "Version", valid_602326
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602327 = header.getOrDefault("X-Amz-Signature")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Signature", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Content-Sha256", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Date")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Date", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Credential")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Credential", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Security-Token")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Security-Token", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Algorithm")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Algorithm", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-SignedHeaders", valid_602333
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_602334 = formData.getOrDefault("RuleArn")
  valid_602334 = validateParameter(valid_602334, JString, required = true,
                                 default = nil)
  if valid_602334 != nil:
    section.add "RuleArn", valid_602334
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602335: Call_PostDeleteRule_602322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_602335.validator(path, query, header, formData, body)
  let scheme = call_602335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602335.url(scheme.get, call_602335.host, call_602335.base,
                         call_602335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602335, url, valid)

proc call*(call_602336: Call_PostDeleteRule_602322; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602337 = newJObject()
  var formData_602338 = newJObject()
  add(formData_602338, "RuleArn", newJString(RuleArn))
  add(query_602337, "Action", newJString(Action))
  add(query_602337, "Version", newJString(Version))
  result = call_602336.call(nil, query_602337, nil, formData_602338, nil)

var postDeleteRule* = Call_PostDeleteRule_602322(name: "postDeleteRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_PostDeleteRule_602323,
    base: "/", url: url_PostDeleteRule_602324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRule_602306 = ref object of OpenApiRestCall_601389
proc url_GetDeleteRule_602308(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteRule_602307(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602309 = query.getOrDefault("RuleArn")
  valid_602309 = validateParameter(valid_602309, JString, required = true,
                                 default = nil)
  if valid_602309 != nil:
    section.add "RuleArn", valid_602309
  var valid_602310 = query.getOrDefault("Action")
  valid_602310 = validateParameter(valid_602310, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_602310 != nil:
    section.add "Action", valid_602310
  var valid_602311 = query.getOrDefault("Version")
  valid_602311 = validateParameter(valid_602311, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602311 != nil:
    section.add "Version", valid_602311
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602312 = header.getOrDefault("X-Amz-Signature")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Signature", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Content-Sha256", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Date")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Date", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Credential")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Credential", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Security-Token")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Security-Token", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Algorithm")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Algorithm", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-SignedHeaders", valid_602318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602319: Call_GetDeleteRule_602306; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_602319.validator(path, query, header, formData, body)
  let scheme = call_602319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602319.url(scheme.get, call_602319.host, call_602319.base,
                         call_602319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602319, url, valid)

proc call*(call_602320: Call_GetDeleteRule_602306; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602321 = newJObject()
  add(query_602321, "RuleArn", newJString(RuleArn))
  add(query_602321, "Action", newJString(Action))
  add(query_602321, "Version", newJString(Version))
  result = call_602320.call(nil, query_602321, nil, nil, nil)

var getDeleteRule* = Call_GetDeleteRule_602306(name: "getDeleteRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_GetDeleteRule_602307,
    base: "/", url: url_GetDeleteRule_602308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTargetGroup_602355 = ref object of OpenApiRestCall_601389
proc url_PostDeleteTargetGroup_602357(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteTargetGroup_602356(path: JsonNode; query: JsonNode;
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
  var valid_602358 = query.getOrDefault("Action")
  valid_602358 = validateParameter(valid_602358, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_602358 != nil:
    section.add "Action", valid_602358
  var valid_602359 = query.getOrDefault("Version")
  valid_602359 = validateParameter(valid_602359, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602359 != nil:
    section.add "Version", valid_602359
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602360 = header.getOrDefault("X-Amz-Signature")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Signature", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Content-Sha256", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Date")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Date", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Credential")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Credential", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Security-Token")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Security-Token", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Algorithm")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Algorithm", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-SignedHeaders", valid_602366
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_602367 = formData.getOrDefault("TargetGroupArn")
  valid_602367 = validateParameter(valid_602367, JString, required = true,
                                 default = nil)
  if valid_602367 != nil:
    section.add "TargetGroupArn", valid_602367
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602368: Call_PostDeleteTargetGroup_602355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_602368.validator(path, query, header, formData, body)
  let scheme = call_602368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602368.url(scheme.get, call_602368.host, call_602368.base,
                         call_602368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602368, url, valid)

proc call*(call_602369: Call_PostDeleteTargetGroup_602355; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_602370 = newJObject()
  var formData_602371 = newJObject()
  add(query_602370, "Action", newJString(Action))
  add(formData_602371, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_602370, "Version", newJString(Version))
  result = call_602369.call(nil, query_602370, nil, formData_602371, nil)

var postDeleteTargetGroup* = Call_PostDeleteTargetGroup_602355(
    name: "postDeleteTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup",
    validator: validate_PostDeleteTargetGroup_602356, base: "/",
    url: url_PostDeleteTargetGroup_602357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTargetGroup_602339 = ref object of OpenApiRestCall_601389
proc url_GetDeleteTargetGroup_602341(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteTargetGroup_602340(path: JsonNode; query: JsonNode;
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
  var valid_602342 = query.getOrDefault("TargetGroupArn")
  valid_602342 = validateParameter(valid_602342, JString, required = true,
                                 default = nil)
  if valid_602342 != nil:
    section.add "TargetGroupArn", valid_602342
  var valid_602343 = query.getOrDefault("Action")
  valid_602343 = validateParameter(valid_602343, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_602343 != nil:
    section.add "Action", valid_602343
  var valid_602344 = query.getOrDefault("Version")
  valid_602344 = validateParameter(valid_602344, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602344 != nil:
    section.add "Version", valid_602344
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602345 = header.getOrDefault("X-Amz-Signature")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Signature", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Content-Sha256", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Date")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Date", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Credential")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Credential", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Security-Token")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Security-Token", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Algorithm")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Algorithm", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-SignedHeaders", valid_602351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602352: Call_GetDeleteTargetGroup_602339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_602352.validator(path, query, header, formData, body)
  let scheme = call_602352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602352.url(scheme.get, call_602352.host, call_602352.base,
                         call_602352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602352, url, valid)

proc call*(call_602353: Call_GetDeleteTargetGroup_602339; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602354 = newJObject()
  add(query_602354, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_602354, "Action", newJString(Action))
  add(query_602354, "Version", newJString(Version))
  result = call_602353.call(nil, query_602354, nil, nil, nil)

var getDeleteTargetGroup* = Call_GetDeleteTargetGroup_602339(
    name: "getDeleteTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup", validator: validate_GetDeleteTargetGroup_602340,
    base: "/", url: url_GetDeleteTargetGroup_602341,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterTargets_602389 = ref object of OpenApiRestCall_601389
proc url_PostDeregisterTargets_602391(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeregisterTargets_602390(path: JsonNode; query: JsonNode;
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
  var valid_602392 = query.getOrDefault("Action")
  valid_602392 = validateParameter(valid_602392, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_602392 != nil:
    section.add "Action", valid_602392
  var valid_602393 = query.getOrDefault("Version")
  valid_602393 = validateParameter(valid_602393, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602393 != nil:
    section.add "Version", valid_602393
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602394 = header.getOrDefault("X-Amz-Signature")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Signature", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Content-Sha256", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Date")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Date", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Credential")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Credential", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Security-Token")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Security-Token", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Algorithm")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Algorithm", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-SignedHeaders", valid_602400
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_602401 = formData.getOrDefault("Targets")
  valid_602401 = validateParameter(valid_602401, JArray, required = true, default = nil)
  if valid_602401 != nil:
    section.add "Targets", valid_602401
  var valid_602402 = formData.getOrDefault("TargetGroupArn")
  valid_602402 = validateParameter(valid_602402, JString, required = true,
                                 default = nil)
  if valid_602402 != nil:
    section.add "TargetGroupArn", valid_602402
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602403: Call_PostDeregisterTargets_602389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_602403.validator(path, query, header, formData, body)
  let scheme = call_602403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602403.url(scheme.get, call_602403.host, call_602403.base,
                         call_602403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602403, url, valid)

proc call*(call_602404: Call_PostDeregisterTargets_602389; Targets: JsonNode;
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
  var query_602405 = newJObject()
  var formData_602406 = newJObject()
  if Targets != nil:
    formData_602406.add "Targets", Targets
  add(query_602405, "Action", newJString(Action))
  add(formData_602406, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_602405, "Version", newJString(Version))
  result = call_602404.call(nil, query_602405, nil, formData_602406, nil)

var postDeregisterTargets* = Call_PostDeregisterTargets_602389(
    name: "postDeregisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets",
    validator: validate_PostDeregisterTargets_602390, base: "/",
    url: url_PostDeregisterTargets_602391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterTargets_602372 = ref object of OpenApiRestCall_601389
proc url_GetDeregisterTargets_602374(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeregisterTargets_602373(path: JsonNode; query: JsonNode;
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
  var valid_602375 = query.getOrDefault("Targets")
  valid_602375 = validateParameter(valid_602375, JArray, required = true, default = nil)
  if valid_602375 != nil:
    section.add "Targets", valid_602375
  var valid_602376 = query.getOrDefault("TargetGroupArn")
  valid_602376 = validateParameter(valid_602376, JString, required = true,
                                 default = nil)
  if valid_602376 != nil:
    section.add "TargetGroupArn", valid_602376
  var valid_602377 = query.getOrDefault("Action")
  valid_602377 = validateParameter(valid_602377, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_602377 != nil:
    section.add "Action", valid_602377
  var valid_602378 = query.getOrDefault("Version")
  valid_602378 = validateParameter(valid_602378, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602378 != nil:
    section.add "Version", valid_602378
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602379 = header.getOrDefault("X-Amz-Signature")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Signature", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Content-Sha256", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-Date")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Date", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Credential")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Credential", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Security-Token")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Security-Token", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Algorithm")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Algorithm", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-SignedHeaders", valid_602385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602386: Call_GetDeregisterTargets_602372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_602386.validator(path, query, header, formData, body)
  let scheme = call_602386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602386.url(scheme.get, call_602386.host, call_602386.base,
                         call_602386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602386, url, valid)

proc call*(call_602387: Call_GetDeregisterTargets_602372; Targets: JsonNode;
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
  var query_602388 = newJObject()
  if Targets != nil:
    query_602388.add "Targets", Targets
  add(query_602388, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_602388, "Action", newJString(Action))
  add(query_602388, "Version", newJString(Version))
  result = call_602387.call(nil, query_602388, nil, nil, nil)

var getDeregisterTargets* = Call_GetDeregisterTargets_602372(
    name: "getDeregisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets", validator: validate_GetDeregisterTargets_602373,
    base: "/", url: url_GetDeregisterTargets_602374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_602424 = ref object of OpenApiRestCall_601389
proc url_PostDescribeAccountLimits_602426(protocol: Scheme; host: string;
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

proc validate_PostDescribeAccountLimits_602425(path: JsonNode; query: JsonNode;
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
  var valid_602427 = query.getOrDefault("Action")
  valid_602427 = validateParameter(valid_602427, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_602427 != nil:
    section.add "Action", valid_602427
  var valid_602428 = query.getOrDefault("Version")
  valid_602428 = validateParameter(valid_602428, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602428 != nil:
    section.add "Version", valid_602428
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602429 = header.getOrDefault("X-Amz-Signature")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Signature", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-Content-Sha256", valid_602430
  var valid_602431 = header.getOrDefault("X-Amz-Date")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Date", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-Credential")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Credential", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-Security-Token")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-Security-Token", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-Algorithm")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Algorithm", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-SignedHeaders", valid_602435
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_602436 = formData.getOrDefault("Marker")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "Marker", valid_602436
  var valid_602437 = formData.getOrDefault("PageSize")
  valid_602437 = validateParameter(valid_602437, JInt, required = false, default = nil)
  if valid_602437 != nil:
    section.add "PageSize", valid_602437
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602438: Call_PostDescribeAccountLimits_602424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602438.validator(path, query, header, formData, body)
  let scheme = call_602438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602438.url(scheme.get, call_602438.host, call_602438.base,
                         call_602438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602438, url, valid)

proc call*(call_602439: Call_PostDescribeAccountLimits_602424; Marker: string = "";
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
  var query_602440 = newJObject()
  var formData_602441 = newJObject()
  add(formData_602441, "Marker", newJString(Marker))
  add(query_602440, "Action", newJString(Action))
  add(formData_602441, "PageSize", newJInt(PageSize))
  add(query_602440, "Version", newJString(Version))
  result = call_602439.call(nil, query_602440, nil, formData_602441, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_602424(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_602425, base: "/",
    url: url_PostDescribeAccountLimits_602426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_602407 = ref object of OpenApiRestCall_601389
proc url_GetDescribeAccountLimits_602409(protocol: Scheme; host: string;
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

proc validate_GetDescribeAccountLimits_602408(path: JsonNode; query: JsonNode;
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
  var valid_602410 = query.getOrDefault("Marker")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "Marker", valid_602410
  var valid_602411 = query.getOrDefault("PageSize")
  valid_602411 = validateParameter(valid_602411, JInt, required = false, default = nil)
  if valid_602411 != nil:
    section.add "PageSize", valid_602411
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602412 = query.getOrDefault("Action")
  valid_602412 = validateParameter(valid_602412, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_602412 != nil:
    section.add "Action", valid_602412
  var valid_602413 = query.getOrDefault("Version")
  valid_602413 = validateParameter(valid_602413, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602413 != nil:
    section.add "Version", valid_602413
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602414 = header.getOrDefault("X-Amz-Signature")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Signature", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Content-Sha256", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Date")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Date", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Credential")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Credential", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Security-Token")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Security-Token", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-Algorithm")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-Algorithm", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-SignedHeaders", valid_602420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602421: Call_GetDescribeAccountLimits_602407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602421.validator(path, query, header, formData, body)
  let scheme = call_602421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602421.url(scheme.get, call_602421.host, call_602421.base,
                         call_602421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602421, url, valid)

proc call*(call_602422: Call_GetDescribeAccountLimits_602407; Marker: string = "";
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
  var query_602423 = newJObject()
  add(query_602423, "Marker", newJString(Marker))
  add(query_602423, "PageSize", newJInt(PageSize))
  add(query_602423, "Action", newJString(Action))
  add(query_602423, "Version", newJString(Version))
  result = call_602422.call(nil, query_602423, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_602407(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_602408, base: "/",
    url: url_GetDescribeAccountLimits_602409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListenerCertificates_602460 = ref object of OpenApiRestCall_601389
proc url_PostDescribeListenerCertificates_602462(protocol: Scheme; host: string;
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

proc validate_PostDescribeListenerCertificates_602461(path: JsonNode;
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
  var valid_602463 = query.getOrDefault("Action")
  valid_602463 = validateParameter(valid_602463, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_602463 != nil:
    section.add "Action", valid_602463
  var valid_602464 = query.getOrDefault("Version")
  valid_602464 = validateParameter(valid_602464, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602464 != nil:
    section.add "Version", valid_602464
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602465 = header.getOrDefault("X-Amz-Signature")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Signature", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Content-Sha256", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Date")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Date", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-Credential")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-Credential", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Security-Token")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Security-Token", valid_602469
  var valid_602470 = header.getOrDefault("X-Amz-Algorithm")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-Algorithm", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-SignedHeaders", valid_602471
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
  var valid_602472 = formData.getOrDefault("ListenerArn")
  valid_602472 = validateParameter(valid_602472, JString, required = true,
                                 default = nil)
  if valid_602472 != nil:
    section.add "ListenerArn", valid_602472
  var valid_602473 = formData.getOrDefault("Marker")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "Marker", valid_602473
  var valid_602474 = formData.getOrDefault("PageSize")
  valid_602474 = validateParameter(valid_602474, JInt, required = false, default = nil)
  if valid_602474 != nil:
    section.add "PageSize", valid_602474
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602475: Call_PostDescribeListenerCertificates_602460;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602475.validator(path, query, header, formData, body)
  let scheme = call_602475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602475.url(scheme.get, call_602475.host, call_602475.base,
                         call_602475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602475, url, valid)

proc call*(call_602476: Call_PostDescribeListenerCertificates_602460;
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
  var query_602477 = newJObject()
  var formData_602478 = newJObject()
  add(formData_602478, "ListenerArn", newJString(ListenerArn))
  add(formData_602478, "Marker", newJString(Marker))
  add(query_602477, "Action", newJString(Action))
  add(formData_602478, "PageSize", newJInt(PageSize))
  add(query_602477, "Version", newJString(Version))
  result = call_602476.call(nil, query_602477, nil, formData_602478, nil)

var postDescribeListenerCertificates* = Call_PostDescribeListenerCertificates_602460(
    name: "postDescribeListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_PostDescribeListenerCertificates_602461, base: "/",
    url: url_PostDescribeListenerCertificates_602462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListenerCertificates_602442 = ref object of OpenApiRestCall_601389
proc url_GetDescribeListenerCertificates_602444(protocol: Scheme; host: string;
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

proc validate_GetDescribeListenerCertificates_602443(path: JsonNode;
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
  var valid_602445 = query.getOrDefault("Marker")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "Marker", valid_602445
  assert query != nil,
        "query argument is necessary due to required `ListenerArn` field"
  var valid_602446 = query.getOrDefault("ListenerArn")
  valid_602446 = validateParameter(valid_602446, JString, required = true,
                                 default = nil)
  if valid_602446 != nil:
    section.add "ListenerArn", valid_602446
  var valid_602447 = query.getOrDefault("PageSize")
  valid_602447 = validateParameter(valid_602447, JInt, required = false, default = nil)
  if valid_602447 != nil:
    section.add "PageSize", valid_602447
  var valid_602448 = query.getOrDefault("Action")
  valid_602448 = validateParameter(valid_602448, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_602448 != nil:
    section.add "Action", valid_602448
  var valid_602449 = query.getOrDefault("Version")
  valid_602449 = validateParameter(valid_602449, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602449 != nil:
    section.add "Version", valid_602449
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602450 = header.getOrDefault("X-Amz-Signature")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-Signature", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Content-Sha256", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Date")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Date", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-Credential")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-Credential", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-Security-Token")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Security-Token", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Algorithm")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Algorithm", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-SignedHeaders", valid_602456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602457: Call_GetDescribeListenerCertificates_602442;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602457.validator(path, query, header, formData, body)
  let scheme = call_602457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602457.url(scheme.get, call_602457.host, call_602457.base,
                         call_602457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602457, url, valid)

proc call*(call_602458: Call_GetDescribeListenerCertificates_602442;
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
  var query_602459 = newJObject()
  add(query_602459, "Marker", newJString(Marker))
  add(query_602459, "ListenerArn", newJString(ListenerArn))
  add(query_602459, "PageSize", newJInt(PageSize))
  add(query_602459, "Action", newJString(Action))
  add(query_602459, "Version", newJString(Version))
  result = call_602458.call(nil, query_602459, nil, nil, nil)

var getDescribeListenerCertificates* = Call_GetDescribeListenerCertificates_602442(
    name: "getDescribeListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_GetDescribeListenerCertificates_602443, base: "/",
    url: url_GetDescribeListenerCertificates_602444,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListeners_602498 = ref object of OpenApiRestCall_601389
proc url_PostDescribeListeners_602500(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeListeners_602499(path: JsonNode; query: JsonNode;
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
  var valid_602501 = query.getOrDefault("Action")
  valid_602501 = validateParameter(valid_602501, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_602501 != nil:
    section.add "Action", valid_602501
  var valid_602502 = query.getOrDefault("Version")
  valid_602502 = validateParameter(valid_602502, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602502 != nil:
    section.add "Version", valid_602502
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602503 = header.getOrDefault("X-Amz-Signature")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-Signature", valid_602503
  var valid_602504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-Content-Sha256", valid_602504
  var valid_602505 = header.getOrDefault("X-Amz-Date")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Date", valid_602505
  var valid_602506 = header.getOrDefault("X-Amz-Credential")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-Credential", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-Security-Token")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Security-Token", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Algorithm")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Algorithm", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-SignedHeaders", valid_602509
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
  var valid_602510 = formData.getOrDefault("Marker")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "Marker", valid_602510
  var valid_602511 = formData.getOrDefault("PageSize")
  valid_602511 = validateParameter(valid_602511, JInt, required = false, default = nil)
  if valid_602511 != nil:
    section.add "PageSize", valid_602511
  var valid_602512 = formData.getOrDefault("LoadBalancerArn")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "LoadBalancerArn", valid_602512
  var valid_602513 = formData.getOrDefault("ListenerArns")
  valid_602513 = validateParameter(valid_602513, JArray, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "ListenerArns", valid_602513
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602514: Call_PostDescribeListeners_602498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_602514.validator(path, query, header, formData, body)
  let scheme = call_602514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602514.url(scheme.get, call_602514.host, call_602514.base,
                         call_602514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602514, url, valid)

proc call*(call_602515: Call_PostDescribeListeners_602498; Marker: string = "";
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
  var query_602516 = newJObject()
  var formData_602517 = newJObject()
  add(formData_602517, "Marker", newJString(Marker))
  add(query_602516, "Action", newJString(Action))
  add(formData_602517, "PageSize", newJInt(PageSize))
  add(query_602516, "Version", newJString(Version))
  add(formData_602517, "LoadBalancerArn", newJString(LoadBalancerArn))
  if ListenerArns != nil:
    formData_602517.add "ListenerArns", ListenerArns
  result = call_602515.call(nil, query_602516, nil, formData_602517, nil)

var postDescribeListeners* = Call_PostDescribeListeners_602498(
    name: "postDescribeListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners",
    validator: validate_PostDescribeListeners_602499, base: "/",
    url: url_PostDescribeListeners_602500, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListeners_602479 = ref object of OpenApiRestCall_601389
proc url_GetDescribeListeners_602481(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeListeners_602480(path: JsonNode; query: JsonNode;
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
  var valid_602482 = query.getOrDefault("Marker")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "Marker", valid_602482
  var valid_602483 = query.getOrDefault("LoadBalancerArn")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "LoadBalancerArn", valid_602483
  var valid_602484 = query.getOrDefault("ListenerArns")
  valid_602484 = validateParameter(valid_602484, JArray, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "ListenerArns", valid_602484
  var valid_602485 = query.getOrDefault("PageSize")
  valid_602485 = validateParameter(valid_602485, JInt, required = false, default = nil)
  if valid_602485 != nil:
    section.add "PageSize", valid_602485
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602486 = query.getOrDefault("Action")
  valid_602486 = validateParameter(valid_602486, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_602486 != nil:
    section.add "Action", valid_602486
  var valid_602487 = query.getOrDefault("Version")
  valid_602487 = validateParameter(valid_602487, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602487 != nil:
    section.add "Version", valid_602487
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602488 = header.getOrDefault("X-Amz-Signature")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-Signature", valid_602488
  var valid_602489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-Content-Sha256", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-Date")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-Date", valid_602490
  var valid_602491 = header.getOrDefault("X-Amz-Credential")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Credential", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-Security-Token")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-Security-Token", valid_602492
  var valid_602493 = header.getOrDefault("X-Amz-Algorithm")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-Algorithm", valid_602493
  var valid_602494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-SignedHeaders", valid_602494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602495: Call_GetDescribeListeners_602479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_602495.validator(path, query, header, formData, body)
  let scheme = call_602495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602495.url(scheme.get, call_602495.host, call_602495.base,
                         call_602495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602495, url, valid)

proc call*(call_602496: Call_GetDescribeListeners_602479; Marker: string = "";
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
  var query_602497 = newJObject()
  add(query_602497, "Marker", newJString(Marker))
  add(query_602497, "LoadBalancerArn", newJString(LoadBalancerArn))
  if ListenerArns != nil:
    query_602497.add "ListenerArns", ListenerArns
  add(query_602497, "PageSize", newJInt(PageSize))
  add(query_602497, "Action", newJString(Action))
  add(query_602497, "Version", newJString(Version))
  result = call_602496.call(nil, query_602497, nil, nil, nil)

var getDescribeListeners* = Call_GetDescribeListeners_602479(
    name: "getDescribeListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners", validator: validate_GetDescribeListeners_602480,
    base: "/", url: url_GetDescribeListeners_602481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_602534 = ref object of OpenApiRestCall_601389
proc url_PostDescribeLoadBalancerAttributes_602536(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancerAttributes_602535(path: JsonNode;
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
  var valid_602537 = query.getOrDefault("Action")
  valid_602537 = validateParameter(valid_602537, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_602537 != nil:
    section.add "Action", valid_602537
  var valid_602538 = query.getOrDefault("Version")
  valid_602538 = validateParameter(valid_602538, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602538 != nil:
    section.add "Version", valid_602538
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602539 = header.getOrDefault("X-Amz-Signature")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-Signature", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Content-Sha256", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-Date")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Date", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Credential")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Credential", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-Security-Token")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Security-Token", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Algorithm")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Algorithm", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-SignedHeaders", valid_602545
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_602546 = formData.getOrDefault("LoadBalancerArn")
  valid_602546 = validateParameter(valid_602546, JString, required = true,
                                 default = nil)
  if valid_602546 != nil:
    section.add "LoadBalancerArn", valid_602546
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602547: Call_PostDescribeLoadBalancerAttributes_602534;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602547.validator(path, query, header, formData, body)
  let scheme = call_602547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602547.url(scheme.get, call_602547.host, call_602547.base,
                         call_602547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602547, url, valid)

proc call*(call_602548: Call_PostDescribeLoadBalancerAttributes_602534;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_602549 = newJObject()
  var formData_602550 = newJObject()
  add(query_602549, "Action", newJString(Action))
  add(query_602549, "Version", newJString(Version))
  add(formData_602550, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_602548.call(nil, query_602549, nil, formData_602550, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_602534(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_602535, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_602536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_602518 = ref object of OpenApiRestCall_601389
proc url_GetDescribeLoadBalancerAttributes_602520(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancerAttributes_602519(path: JsonNode;
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
  var valid_602521 = query.getOrDefault("LoadBalancerArn")
  valid_602521 = validateParameter(valid_602521, JString, required = true,
                                 default = nil)
  if valid_602521 != nil:
    section.add "LoadBalancerArn", valid_602521
  var valid_602522 = query.getOrDefault("Action")
  valid_602522 = validateParameter(valid_602522, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_602522 != nil:
    section.add "Action", valid_602522
  var valid_602523 = query.getOrDefault("Version")
  valid_602523 = validateParameter(valid_602523, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602523 != nil:
    section.add "Version", valid_602523
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602524 = header.getOrDefault("X-Amz-Signature")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Signature", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Content-Sha256", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-Date")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-Date", valid_602526
  var valid_602527 = header.getOrDefault("X-Amz-Credential")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "X-Amz-Credential", valid_602527
  var valid_602528 = header.getOrDefault("X-Amz-Security-Token")
  valid_602528 = validateParameter(valid_602528, JString, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "X-Amz-Security-Token", valid_602528
  var valid_602529 = header.getOrDefault("X-Amz-Algorithm")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "X-Amz-Algorithm", valid_602529
  var valid_602530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-SignedHeaders", valid_602530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602531: Call_GetDescribeLoadBalancerAttributes_602518;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602531.validator(path, query, header, formData, body)
  let scheme = call_602531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602531.url(scheme.get, call_602531.host, call_602531.base,
                         call_602531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602531, url, valid)

proc call*(call_602532: Call_GetDescribeLoadBalancerAttributes_602518;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602533 = newJObject()
  add(query_602533, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_602533, "Action", newJString(Action))
  add(query_602533, "Version", newJString(Version))
  result = call_602532.call(nil, query_602533, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_602518(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_602519, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_602520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_602570 = ref object of OpenApiRestCall_601389
proc url_PostDescribeLoadBalancers_602572(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancers_602571(path: JsonNode; query: JsonNode;
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
  var valid_602573 = query.getOrDefault("Action")
  valid_602573 = validateParameter(valid_602573, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_602573 != nil:
    section.add "Action", valid_602573
  var valid_602574 = query.getOrDefault("Version")
  valid_602574 = validateParameter(valid_602574, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602574 != nil:
    section.add "Version", valid_602574
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602575 = header.getOrDefault("X-Amz-Signature")
  valid_602575 = validateParameter(valid_602575, JString, required = false,
                                 default = nil)
  if valid_602575 != nil:
    section.add "X-Amz-Signature", valid_602575
  var valid_602576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602576 = validateParameter(valid_602576, JString, required = false,
                                 default = nil)
  if valid_602576 != nil:
    section.add "X-Amz-Content-Sha256", valid_602576
  var valid_602577 = header.getOrDefault("X-Amz-Date")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-Date", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-Credential")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Credential", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-Security-Token")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Security-Token", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Algorithm")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Algorithm", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-SignedHeaders", valid_602581
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
  var valid_602582 = formData.getOrDefault("Names")
  valid_602582 = validateParameter(valid_602582, JArray, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "Names", valid_602582
  var valid_602583 = formData.getOrDefault("Marker")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "Marker", valid_602583
  var valid_602584 = formData.getOrDefault("PageSize")
  valid_602584 = validateParameter(valid_602584, JInt, required = false, default = nil)
  if valid_602584 != nil:
    section.add "PageSize", valid_602584
  var valid_602585 = formData.getOrDefault("LoadBalancerArns")
  valid_602585 = validateParameter(valid_602585, JArray, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "LoadBalancerArns", valid_602585
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602586: Call_PostDescribeLoadBalancers_602570; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_602586.validator(path, query, header, formData, body)
  let scheme = call_602586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602586.url(scheme.get, call_602586.host, call_602586.base,
                         call_602586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602586, url, valid)

proc call*(call_602587: Call_PostDescribeLoadBalancers_602570;
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
  var query_602588 = newJObject()
  var formData_602589 = newJObject()
  if Names != nil:
    formData_602589.add "Names", Names
  add(formData_602589, "Marker", newJString(Marker))
  add(query_602588, "Action", newJString(Action))
  add(formData_602589, "PageSize", newJInt(PageSize))
  add(query_602588, "Version", newJString(Version))
  if LoadBalancerArns != nil:
    formData_602589.add "LoadBalancerArns", LoadBalancerArns
  result = call_602587.call(nil, query_602588, nil, formData_602589, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_602570(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_602571, base: "/",
    url: url_PostDescribeLoadBalancers_602572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_602551 = ref object of OpenApiRestCall_601389
proc url_GetDescribeLoadBalancers_602553(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancers_602552(path: JsonNode; query: JsonNode;
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
  var valid_602554 = query.getOrDefault("Marker")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "Marker", valid_602554
  var valid_602555 = query.getOrDefault("PageSize")
  valid_602555 = validateParameter(valid_602555, JInt, required = false, default = nil)
  if valid_602555 != nil:
    section.add "PageSize", valid_602555
  var valid_602556 = query.getOrDefault("LoadBalancerArns")
  valid_602556 = validateParameter(valid_602556, JArray, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "LoadBalancerArns", valid_602556
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602557 = query.getOrDefault("Action")
  valid_602557 = validateParameter(valid_602557, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_602557 != nil:
    section.add "Action", valid_602557
  var valid_602558 = query.getOrDefault("Version")
  valid_602558 = validateParameter(valid_602558, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602558 != nil:
    section.add "Version", valid_602558
  var valid_602559 = query.getOrDefault("Names")
  valid_602559 = validateParameter(valid_602559, JArray, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "Names", valid_602559
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602560 = header.getOrDefault("X-Amz-Signature")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Signature", valid_602560
  var valid_602561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-Content-Sha256", valid_602561
  var valid_602562 = header.getOrDefault("X-Amz-Date")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-Date", valid_602562
  var valid_602563 = header.getOrDefault("X-Amz-Credential")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Credential", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-Security-Token")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-Security-Token", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-Algorithm")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Algorithm", valid_602565
  var valid_602566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "X-Amz-SignedHeaders", valid_602566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602567: Call_GetDescribeLoadBalancers_602551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_602567.validator(path, query, header, formData, body)
  let scheme = call_602567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602567.url(scheme.get, call_602567.host, call_602567.base,
                         call_602567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602567, url, valid)

proc call*(call_602568: Call_GetDescribeLoadBalancers_602551; Marker: string = "";
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
  var query_602569 = newJObject()
  add(query_602569, "Marker", newJString(Marker))
  add(query_602569, "PageSize", newJInt(PageSize))
  if LoadBalancerArns != nil:
    query_602569.add "LoadBalancerArns", LoadBalancerArns
  add(query_602569, "Action", newJString(Action))
  add(query_602569, "Version", newJString(Version))
  if Names != nil:
    query_602569.add "Names", Names
  result = call_602568.call(nil, query_602569, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_602551(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_602552, base: "/",
    url: url_GetDescribeLoadBalancers_602553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRules_602609 = ref object of OpenApiRestCall_601389
proc url_PostDescribeRules_602611(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeRules_602610(path: JsonNode; query: JsonNode;
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
  var valid_602612 = query.getOrDefault("Action")
  valid_602612 = validateParameter(valid_602612, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_602612 != nil:
    section.add "Action", valid_602612
  var valid_602613 = query.getOrDefault("Version")
  valid_602613 = validateParameter(valid_602613, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602613 != nil:
    section.add "Version", valid_602613
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602614 = header.getOrDefault("X-Amz-Signature")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-Signature", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-Content-Sha256", valid_602615
  var valid_602616 = header.getOrDefault("X-Amz-Date")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "X-Amz-Date", valid_602616
  var valid_602617 = header.getOrDefault("X-Amz-Credential")
  valid_602617 = validateParameter(valid_602617, JString, required = false,
                                 default = nil)
  if valid_602617 != nil:
    section.add "X-Amz-Credential", valid_602617
  var valid_602618 = header.getOrDefault("X-Amz-Security-Token")
  valid_602618 = validateParameter(valid_602618, JString, required = false,
                                 default = nil)
  if valid_602618 != nil:
    section.add "X-Amz-Security-Token", valid_602618
  var valid_602619 = header.getOrDefault("X-Amz-Algorithm")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "X-Amz-Algorithm", valid_602619
  var valid_602620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "X-Amz-SignedHeaders", valid_602620
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
  var valid_602621 = formData.getOrDefault("ListenerArn")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "ListenerArn", valid_602621
  var valid_602622 = formData.getOrDefault("Marker")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "Marker", valid_602622
  var valid_602623 = formData.getOrDefault("RuleArns")
  valid_602623 = validateParameter(valid_602623, JArray, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "RuleArns", valid_602623
  var valid_602624 = formData.getOrDefault("PageSize")
  valid_602624 = validateParameter(valid_602624, JInt, required = false, default = nil)
  if valid_602624 != nil:
    section.add "PageSize", valid_602624
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602625: Call_PostDescribeRules_602609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_602625.validator(path, query, header, formData, body)
  let scheme = call_602625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602625.url(scheme.get, call_602625.host, call_602625.base,
                         call_602625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602625, url, valid)

proc call*(call_602626: Call_PostDescribeRules_602609; ListenerArn: string = "";
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
  var query_602627 = newJObject()
  var formData_602628 = newJObject()
  add(formData_602628, "ListenerArn", newJString(ListenerArn))
  add(formData_602628, "Marker", newJString(Marker))
  if RuleArns != nil:
    formData_602628.add "RuleArns", RuleArns
  add(query_602627, "Action", newJString(Action))
  add(formData_602628, "PageSize", newJInt(PageSize))
  add(query_602627, "Version", newJString(Version))
  result = call_602626.call(nil, query_602627, nil, formData_602628, nil)

var postDescribeRules* = Call_PostDescribeRules_602609(name: "postDescribeRules",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_PostDescribeRules_602610,
    base: "/", url: url_PostDescribeRules_602611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRules_602590 = ref object of OpenApiRestCall_601389
proc url_GetDescribeRules_602592(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeRules_602591(path: JsonNode; query: JsonNode;
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
  var valid_602593 = query.getOrDefault("Marker")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "Marker", valid_602593
  var valid_602594 = query.getOrDefault("ListenerArn")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "ListenerArn", valid_602594
  var valid_602595 = query.getOrDefault("PageSize")
  valid_602595 = validateParameter(valid_602595, JInt, required = false, default = nil)
  if valid_602595 != nil:
    section.add "PageSize", valid_602595
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602596 = query.getOrDefault("Action")
  valid_602596 = validateParameter(valid_602596, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_602596 != nil:
    section.add "Action", valid_602596
  var valid_602597 = query.getOrDefault("Version")
  valid_602597 = validateParameter(valid_602597, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602597 != nil:
    section.add "Version", valid_602597
  var valid_602598 = query.getOrDefault("RuleArns")
  valid_602598 = validateParameter(valid_602598, JArray, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "RuleArns", valid_602598
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602599 = header.getOrDefault("X-Amz-Signature")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-Signature", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Content-Sha256", valid_602600
  var valid_602601 = header.getOrDefault("X-Amz-Date")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "X-Amz-Date", valid_602601
  var valid_602602 = header.getOrDefault("X-Amz-Credential")
  valid_602602 = validateParameter(valid_602602, JString, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "X-Amz-Credential", valid_602602
  var valid_602603 = header.getOrDefault("X-Amz-Security-Token")
  valid_602603 = validateParameter(valid_602603, JString, required = false,
                                 default = nil)
  if valid_602603 != nil:
    section.add "X-Amz-Security-Token", valid_602603
  var valid_602604 = header.getOrDefault("X-Amz-Algorithm")
  valid_602604 = validateParameter(valid_602604, JString, required = false,
                                 default = nil)
  if valid_602604 != nil:
    section.add "X-Amz-Algorithm", valid_602604
  var valid_602605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-SignedHeaders", valid_602605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602606: Call_GetDescribeRules_602590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_602606.validator(path, query, header, formData, body)
  let scheme = call_602606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602606.url(scheme.get, call_602606.host, call_602606.base,
                         call_602606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602606, url, valid)

proc call*(call_602607: Call_GetDescribeRules_602590; Marker: string = "";
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
  var query_602608 = newJObject()
  add(query_602608, "Marker", newJString(Marker))
  add(query_602608, "ListenerArn", newJString(ListenerArn))
  add(query_602608, "PageSize", newJInt(PageSize))
  add(query_602608, "Action", newJString(Action))
  add(query_602608, "Version", newJString(Version))
  if RuleArns != nil:
    query_602608.add "RuleArns", RuleArns
  result = call_602607.call(nil, query_602608, nil, nil, nil)

var getDescribeRules* = Call_GetDescribeRules_602590(name: "getDescribeRules",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_GetDescribeRules_602591,
    base: "/", url: url_GetDescribeRules_602592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSSLPolicies_602647 = ref object of OpenApiRestCall_601389
proc url_PostDescribeSSLPolicies_602649(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeSSLPolicies_602648(path: JsonNode; query: JsonNode;
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
  var valid_602650 = query.getOrDefault("Action")
  valid_602650 = validateParameter(valid_602650, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_602650 != nil:
    section.add "Action", valid_602650
  var valid_602651 = query.getOrDefault("Version")
  valid_602651 = validateParameter(valid_602651, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602651 != nil:
    section.add "Version", valid_602651
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602652 = header.getOrDefault("X-Amz-Signature")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "X-Amz-Signature", valid_602652
  var valid_602653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "X-Amz-Content-Sha256", valid_602653
  var valid_602654 = header.getOrDefault("X-Amz-Date")
  valid_602654 = validateParameter(valid_602654, JString, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "X-Amz-Date", valid_602654
  var valid_602655 = header.getOrDefault("X-Amz-Credential")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "X-Amz-Credential", valid_602655
  var valid_602656 = header.getOrDefault("X-Amz-Security-Token")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Security-Token", valid_602656
  var valid_602657 = header.getOrDefault("X-Amz-Algorithm")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-Algorithm", valid_602657
  var valid_602658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "X-Amz-SignedHeaders", valid_602658
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the policies.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_602659 = formData.getOrDefault("Names")
  valid_602659 = validateParameter(valid_602659, JArray, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "Names", valid_602659
  var valid_602660 = formData.getOrDefault("Marker")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "Marker", valid_602660
  var valid_602661 = formData.getOrDefault("PageSize")
  valid_602661 = validateParameter(valid_602661, JInt, required = false, default = nil)
  if valid_602661 != nil:
    section.add "PageSize", valid_602661
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602662: Call_PostDescribeSSLPolicies_602647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602662.validator(path, query, header, formData, body)
  let scheme = call_602662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602662.url(scheme.get, call_602662.host, call_602662.base,
                         call_602662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602662, url, valid)

proc call*(call_602663: Call_PostDescribeSSLPolicies_602647; Names: JsonNode = nil;
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
  var query_602664 = newJObject()
  var formData_602665 = newJObject()
  if Names != nil:
    formData_602665.add "Names", Names
  add(formData_602665, "Marker", newJString(Marker))
  add(query_602664, "Action", newJString(Action))
  add(formData_602665, "PageSize", newJInt(PageSize))
  add(query_602664, "Version", newJString(Version))
  result = call_602663.call(nil, query_602664, nil, formData_602665, nil)

var postDescribeSSLPolicies* = Call_PostDescribeSSLPolicies_602647(
    name: "postDescribeSSLPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_PostDescribeSSLPolicies_602648, base: "/",
    url: url_PostDescribeSSLPolicies_602649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSSLPolicies_602629 = ref object of OpenApiRestCall_601389
proc url_GetDescribeSSLPolicies_602631(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeSSLPolicies_602630(path: JsonNode; query: JsonNode;
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
  var valid_602632 = query.getOrDefault("Marker")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "Marker", valid_602632
  var valid_602633 = query.getOrDefault("PageSize")
  valid_602633 = validateParameter(valid_602633, JInt, required = false, default = nil)
  if valid_602633 != nil:
    section.add "PageSize", valid_602633
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602634 = query.getOrDefault("Action")
  valid_602634 = validateParameter(valid_602634, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_602634 != nil:
    section.add "Action", valid_602634
  var valid_602635 = query.getOrDefault("Version")
  valid_602635 = validateParameter(valid_602635, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602635 != nil:
    section.add "Version", valid_602635
  var valid_602636 = query.getOrDefault("Names")
  valid_602636 = validateParameter(valid_602636, JArray, required = false,
                                 default = nil)
  if valid_602636 != nil:
    section.add "Names", valid_602636
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602637 = header.getOrDefault("X-Amz-Signature")
  valid_602637 = validateParameter(valid_602637, JString, required = false,
                                 default = nil)
  if valid_602637 != nil:
    section.add "X-Amz-Signature", valid_602637
  var valid_602638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602638 = validateParameter(valid_602638, JString, required = false,
                                 default = nil)
  if valid_602638 != nil:
    section.add "X-Amz-Content-Sha256", valid_602638
  var valid_602639 = header.getOrDefault("X-Amz-Date")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "X-Amz-Date", valid_602639
  var valid_602640 = header.getOrDefault("X-Amz-Credential")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-Credential", valid_602640
  var valid_602641 = header.getOrDefault("X-Amz-Security-Token")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Security-Token", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Algorithm")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Algorithm", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-SignedHeaders", valid_602643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602644: Call_GetDescribeSSLPolicies_602629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602644.validator(path, query, header, formData, body)
  let scheme = call_602644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602644.url(scheme.get, call_602644.host, call_602644.base,
                         call_602644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602644, url, valid)

proc call*(call_602645: Call_GetDescribeSSLPolicies_602629; Marker: string = "";
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
  var query_602646 = newJObject()
  add(query_602646, "Marker", newJString(Marker))
  add(query_602646, "PageSize", newJInt(PageSize))
  add(query_602646, "Action", newJString(Action))
  add(query_602646, "Version", newJString(Version))
  if Names != nil:
    query_602646.add "Names", Names
  result = call_602645.call(nil, query_602646, nil, nil, nil)

var getDescribeSSLPolicies* = Call_GetDescribeSSLPolicies_602629(
    name: "getDescribeSSLPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_GetDescribeSSLPolicies_602630, base: "/",
    url: url_GetDescribeSSLPolicies_602631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_602682 = ref object of OpenApiRestCall_601389
proc url_PostDescribeTags_602684(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeTags_602683(path: JsonNode; query: JsonNode;
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
  var valid_602685 = query.getOrDefault("Action")
  valid_602685 = validateParameter(valid_602685, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_602685 != nil:
    section.add "Action", valid_602685
  var valid_602686 = query.getOrDefault("Version")
  valid_602686 = validateParameter(valid_602686, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602686 != nil:
    section.add "Version", valid_602686
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602687 = header.getOrDefault("X-Amz-Signature")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-Signature", valid_602687
  var valid_602688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602688 = validateParameter(valid_602688, JString, required = false,
                                 default = nil)
  if valid_602688 != nil:
    section.add "X-Amz-Content-Sha256", valid_602688
  var valid_602689 = header.getOrDefault("X-Amz-Date")
  valid_602689 = validateParameter(valid_602689, JString, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "X-Amz-Date", valid_602689
  var valid_602690 = header.getOrDefault("X-Amz-Credential")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Credential", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-Security-Token")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-Security-Token", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-Algorithm")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-Algorithm", valid_602692
  var valid_602693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "X-Amz-SignedHeaders", valid_602693
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_602694 = formData.getOrDefault("ResourceArns")
  valid_602694 = validateParameter(valid_602694, JArray, required = true, default = nil)
  if valid_602694 != nil:
    section.add "ResourceArns", valid_602694
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602695: Call_PostDescribeTags_602682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_602695.validator(path, query, header, formData, body)
  let scheme = call_602695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602695.url(scheme.get, call_602695.host, call_602695.base,
                         call_602695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602695, url, valid)

proc call*(call_602696: Call_PostDescribeTags_602682; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602697 = newJObject()
  var formData_602698 = newJObject()
  if ResourceArns != nil:
    formData_602698.add "ResourceArns", ResourceArns
  add(query_602697, "Action", newJString(Action))
  add(query_602697, "Version", newJString(Version))
  result = call_602696.call(nil, query_602697, nil, formData_602698, nil)

var postDescribeTags* = Call_PostDescribeTags_602682(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_602683,
    base: "/", url: url_PostDescribeTags_602684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_602666 = ref object of OpenApiRestCall_601389
proc url_GetDescribeTags_602668(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeTags_602667(path: JsonNode; query: JsonNode;
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
  var valid_602669 = query.getOrDefault("ResourceArns")
  valid_602669 = validateParameter(valid_602669, JArray, required = true, default = nil)
  if valid_602669 != nil:
    section.add "ResourceArns", valid_602669
  var valid_602670 = query.getOrDefault("Action")
  valid_602670 = validateParameter(valid_602670, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_602670 != nil:
    section.add "Action", valid_602670
  var valid_602671 = query.getOrDefault("Version")
  valid_602671 = validateParameter(valid_602671, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602671 != nil:
    section.add "Version", valid_602671
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602672 = header.getOrDefault("X-Amz-Signature")
  valid_602672 = validateParameter(valid_602672, JString, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "X-Amz-Signature", valid_602672
  var valid_602673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602673 = validateParameter(valid_602673, JString, required = false,
                                 default = nil)
  if valid_602673 != nil:
    section.add "X-Amz-Content-Sha256", valid_602673
  var valid_602674 = header.getOrDefault("X-Amz-Date")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "X-Amz-Date", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Credential")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Credential", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Security-Token")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Security-Token", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Algorithm")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Algorithm", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-SignedHeaders", valid_602678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602679: Call_GetDescribeTags_602666; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_602679.validator(path, query, header, formData, body)
  let scheme = call_602679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602679.url(scheme.get, call_602679.host, call_602679.base,
                         call_602679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602679, url, valid)

proc call*(call_602680: Call_GetDescribeTags_602666; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602681 = newJObject()
  if ResourceArns != nil:
    query_602681.add "ResourceArns", ResourceArns
  add(query_602681, "Action", newJString(Action))
  add(query_602681, "Version", newJString(Version))
  result = call_602680.call(nil, query_602681, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_602666(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_602667,
    base: "/", url: url_GetDescribeTags_602668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroupAttributes_602715 = ref object of OpenApiRestCall_601389
proc url_PostDescribeTargetGroupAttributes_602717(protocol: Scheme; host: string;
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

proc validate_PostDescribeTargetGroupAttributes_602716(path: JsonNode;
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
  var valid_602718 = query.getOrDefault("Action")
  valid_602718 = validateParameter(valid_602718, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_602718 != nil:
    section.add "Action", valid_602718
  var valid_602719 = query.getOrDefault("Version")
  valid_602719 = validateParameter(valid_602719, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602719 != nil:
    section.add "Version", valid_602719
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602720 = header.getOrDefault("X-Amz-Signature")
  valid_602720 = validateParameter(valid_602720, JString, required = false,
                                 default = nil)
  if valid_602720 != nil:
    section.add "X-Amz-Signature", valid_602720
  var valid_602721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602721 = validateParameter(valid_602721, JString, required = false,
                                 default = nil)
  if valid_602721 != nil:
    section.add "X-Amz-Content-Sha256", valid_602721
  var valid_602722 = header.getOrDefault("X-Amz-Date")
  valid_602722 = validateParameter(valid_602722, JString, required = false,
                                 default = nil)
  if valid_602722 != nil:
    section.add "X-Amz-Date", valid_602722
  var valid_602723 = header.getOrDefault("X-Amz-Credential")
  valid_602723 = validateParameter(valid_602723, JString, required = false,
                                 default = nil)
  if valid_602723 != nil:
    section.add "X-Amz-Credential", valid_602723
  var valid_602724 = header.getOrDefault("X-Amz-Security-Token")
  valid_602724 = validateParameter(valid_602724, JString, required = false,
                                 default = nil)
  if valid_602724 != nil:
    section.add "X-Amz-Security-Token", valid_602724
  var valid_602725 = header.getOrDefault("X-Amz-Algorithm")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "X-Amz-Algorithm", valid_602725
  var valid_602726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "X-Amz-SignedHeaders", valid_602726
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_602727 = formData.getOrDefault("TargetGroupArn")
  valid_602727 = validateParameter(valid_602727, JString, required = true,
                                 default = nil)
  if valid_602727 != nil:
    section.add "TargetGroupArn", valid_602727
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602728: Call_PostDescribeTargetGroupAttributes_602715;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602728.validator(path, query, header, formData, body)
  let scheme = call_602728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602728.url(scheme.get, call_602728.host, call_602728.base,
                         call_602728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602728, url, valid)

proc call*(call_602729: Call_PostDescribeTargetGroupAttributes_602715;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_602730 = newJObject()
  var formData_602731 = newJObject()
  add(query_602730, "Action", newJString(Action))
  add(formData_602731, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_602730, "Version", newJString(Version))
  result = call_602729.call(nil, query_602730, nil, formData_602731, nil)

var postDescribeTargetGroupAttributes* = Call_PostDescribeTargetGroupAttributes_602715(
    name: "postDescribeTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_PostDescribeTargetGroupAttributes_602716, base: "/",
    url: url_PostDescribeTargetGroupAttributes_602717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroupAttributes_602699 = ref object of OpenApiRestCall_601389
proc url_GetDescribeTargetGroupAttributes_602701(protocol: Scheme; host: string;
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

proc validate_GetDescribeTargetGroupAttributes_602700(path: JsonNode;
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
  var valid_602702 = query.getOrDefault("TargetGroupArn")
  valid_602702 = validateParameter(valid_602702, JString, required = true,
                                 default = nil)
  if valid_602702 != nil:
    section.add "TargetGroupArn", valid_602702
  var valid_602703 = query.getOrDefault("Action")
  valid_602703 = validateParameter(valid_602703, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_602703 != nil:
    section.add "Action", valid_602703
  var valid_602704 = query.getOrDefault("Version")
  valid_602704 = validateParameter(valid_602704, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602704 != nil:
    section.add "Version", valid_602704
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602705 = header.getOrDefault("X-Amz-Signature")
  valid_602705 = validateParameter(valid_602705, JString, required = false,
                                 default = nil)
  if valid_602705 != nil:
    section.add "X-Amz-Signature", valid_602705
  var valid_602706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "X-Amz-Content-Sha256", valid_602706
  var valid_602707 = header.getOrDefault("X-Amz-Date")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "X-Amz-Date", valid_602707
  var valid_602708 = header.getOrDefault("X-Amz-Credential")
  valid_602708 = validateParameter(valid_602708, JString, required = false,
                                 default = nil)
  if valid_602708 != nil:
    section.add "X-Amz-Credential", valid_602708
  var valid_602709 = header.getOrDefault("X-Amz-Security-Token")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "X-Amz-Security-Token", valid_602709
  var valid_602710 = header.getOrDefault("X-Amz-Algorithm")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-Algorithm", valid_602710
  var valid_602711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "X-Amz-SignedHeaders", valid_602711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602712: Call_GetDescribeTargetGroupAttributes_602699;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602712.validator(path, query, header, formData, body)
  let scheme = call_602712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602712.url(scheme.get, call_602712.host, call_602712.base,
                         call_602712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602712, url, valid)

proc call*(call_602713: Call_GetDescribeTargetGroupAttributes_602699;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602714 = newJObject()
  add(query_602714, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_602714, "Action", newJString(Action))
  add(query_602714, "Version", newJString(Version))
  result = call_602713.call(nil, query_602714, nil, nil, nil)

var getDescribeTargetGroupAttributes* = Call_GetDescribeTargetGroupAttributes_602699(
    name: "getDescribeTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_GetDescribeTargetGroupAttributes_602700, base: "/",
    url: url_GetDescribeTargetGroupAttributes_602701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroups_602752 = ref object of OpenApiRestCall_601389
proc url_PostDescribeTargetGroups_602754(protocol: Scheme; host: string;
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

proc validate_PostDescribeTargetGroups_602753(path: JsonNode; query: JsonNode;
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
  var valid_602755 = query.getOrDefault("Action")
  valid_602755 = validateParameter(valid_602755, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_602755 != nil:
    section.add "Action", valid_602755
  var valid_602756 = query.getOrDefault("Version")
  valid_602756 = validateParameter(valid_602756, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602756 != nil:
    section.add "Version", valid_602756
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602757 = header.getOrDefault("X-Amz-Signature")
  valid_602757 = validateParameter(valid_602757, JString, required = false,
                                 default = nil)
  if valid_602757 != nil:
    section.add "X-Amz-Signature", valid_602757
  var valid_602758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602758 = validateParameter(valid_602758, JString, required = false,
                                 default = nil)
  if valid_602758 != nil:
    section.add "X-Amz-Content-Sha256", valid_602758
  var valid_602759 = header.getOrDefault("X-Amz-Date")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-Date", valid_602759
  var valid_602760 = header.getOrDefault("X-Amz-Credential")
  valid_602760 = validateParameter(valid_602760, JString, required = false,
                                 default = nil)
  if valid_602760 != nil:
    section.add "X-Amz-Credential", valid_602760
  var valid_602761 = header.getOrDefault("X-Amz-Security-Token")
  valid_602761 = validateParameter(valid_602761, JString, required = false,
                                 default = nil)
  if valid_602761 != nil:
    section.add "X-Amz-Security-Token", valid_602761
  var valid_602762 = header.getOrDefault("X-Amz-Algorithm")
  valid_602762 = validateParameter(valid_602762, JString, required = false,
                                 default = nil)
  if valid_602762 != nil:
    section.add "X-Amz-Algorithm", valid_602762
  var valid_602763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602763 = validateParameter(valid_602763, JString, required = false,
                                 default = nil)
  if valid_602763 != nil:
    section.add "X-Amz-SignedHeaders", valid_602763
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
  var valid_602764 = formData.getOrDefault("Names")
  valid_602764 = validateParameter(valid_602764, JArray, required = false,
                                 default = nil)
  if valid_602764 != nil:
    section.add "Names", valid_602764
  var valid_602765 = formData.getOrDefault("Marker")
  valid_602765 = validateParameter(valid_602765, JString, required = false,
                                 default = nil)
  if valid_602765 != nil:
    section.add "Marker", valid_602765
  var valid_602766 = formData.getOrDefault("TargetGroupArns")
  valid_602766 = validateParameter(valid_602766, JArray, required = false,
                                 default = nil)
  if valid_602766 != nil:
    section.add "TargetGroupArns", valid_602766
  var valid_602767 = formData.getOrDefault("PageSize")
  valid_602767 = validateParameter(valid_602767, JInt, required = false, default = nil)
  if valid_602767 != nil:
    section.add "PageSize", valid_602767
  var valid_602768 = formData.getOrDefault("LoadBalancerArn")
  valid_602768 = validateParameter(valid_602768, JString, required = false,
                                 default = nil)
  if valid_602768 != nil:
    section.add "LoadBalancerArn", valid_602768
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602769: Call_PostDescribeTargetGroups_602752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_602769.validator(path, query, header, formData, body)
  let scheme = call_602769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602769.url(scheme.get, call_602769.host, call_602769.base,
                         call_602769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602769, url, valid)

proc call*(call_602770: Call_PostDescribeTargetGroups_602752;
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
  var query_602771 = newJObject()
  var formData_602772 = newJObject()
  if Names != nil:
    formData_602772.add "Names", Names
  add(formData_602772, "Marker", newJString(Marker))
  add(query_602771, "Action", newJString(Action))
  if TargetGroupArns != nil:
    formData_602772.add "TargetGroupArns", TargetGroupArns
  add(formData_602772, "PageSize", newJInt(PageSize))
  add(query_602771, "Version", newJString(Version))
  add(formData_602772, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_602770.call(nil, query_602771, nil, formData_602772, nil)

var postDescribeTargetGroups* = Call_PostDescribeTargetGroups_602752(
    name: "postDescribeTargetGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_PostDescribeTargetGroups_602753, base: "/",
    url: url_PostDescribeTargetGroups_602754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroups_602732 = ref object of OpenApiRestCall_601389
proc url_GetDescribeTargetGroups_602734(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeTargetGroups_602733(path: JsonNode; query: JsonNode;
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
  var valid_602735 = query.getOrDefault("Marker")
  valid_602735 = validateParameter(valid_602735, JString, required = false,
                                 default = nil)
  if valid_602735 != nil:
    section.add "Marker", valid_602735
  var valid_602736 = query.getOrDefault("LoadBalancerArn")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "LoadBalancerArn", valid_602736
  var valid_602737 = query.getOrDefault("PageSize")
  valid_602737 = validateParameter(valid_602737, JInt, required = false, default = nil)
  if valid_602737 != nil:
    section.add "PageSize", valid_602737
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602738 = query.getOrDefault("Action")
  valid_602738 = validateParameter(valid_602738, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_602738 != nil:
    section.add "Action", valid_602738
  var valid_602739 = query.getOrDefault("TargetGroupArns")
  valid_602739 = validateParameter(valid_602739, JArray, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "TargetGroupArns", valid_602739
  var valid_602740 = query.getOrDefault("Version")
  valid_602740 = validateParameter(valid_602740, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602740 != nil:
    section.add "Version", valid_602740
  var valid_602741 = query.getOrDefault("Names")
  valid_602741 = validateParameter(valid_602741, JArray, required = false,
                                 default = nil)
  if valid_602741 != nil:
    section.add "Names", valid_602741
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602742 = header.getOrDefault("X-Amz-Signature")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "X-Amz-Signature", valid_602742
  var valid_602743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602743 = validateParameter(valid_602743, JString, required = false,
                                 default = nil)
  if valid_602743 != nil:
    section.add "X-Amz-Content-Sha256", valid_602743
  var valid_602744 = header.getOrDefault("X-Amz-Date")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "X-Amz-Date", valid_602744
  var valid_602745 = header.getOrDefault("X-Amz-Credential")
  valid_602745 = validateParameter(valid_602745, JString, required = false,
                                 default = nil)
  if valid_602745 != nil:
    section.add "X-Amz-Credential", valid_602745
  var valid_602746 = header.getOrDefault("X-Amz-Security-Token")
  valid_602746 = validateParameter(valid_602746, JString, required = false,
                                 default = nil)
  if valid_602746 != nil:
    section.add "X-Amz-Security-Token", valid_602746
  var valid_602747 = header.getOrDefault("X-Amz-Algorithm")
  valid_602747 = validateParameter(valid_602747, JString, required = false,
                                 default = nil)
  if valid_602747 != nil:
    section.add "X-Amz-Algorithm", valid_602747
  var valid_602748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602748 = validateParameter(valid_602748, JString, required = false,
                                 default = nil)
  if valid_602748 != nil:
    section.add "X-Amz-SignedHeaders", valid_602748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602749: Call_GetDescribeTargetGroups_602732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_602749.validator(path, query, header, formData, body)
  let scheme = call_602749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602749.url(scheme.get, call_602749.host, call_602749.base,
                         call_602749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602749, url, valid)

proc call*(call_602750: Call_GetDescribeTargetGroups_602732; Marker: string = "";
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
  var query_602751 = newJObject()
  add(query_602751, "Marker", newJString(Marker))
  add(query_602751, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_602751, "PageSize", newJInt(PageSize))
  add(query_602751, "Action", newJString(Action))
  if TargetGroupArns != nil:
    query_602751.add "TargetGroupArns", TargetGroupArns
  add(query_602751, "Version", newJString(Version))
  if Names != nil:
    query_602751.add "Names", Names
  result = call_602750.call(nil, query_602751, nil, nil, nil)

var getDescribeTargetGroups* = Call_GetDescribeTargetGroups_602732(
    name: "getDescribeTargetGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_GetDescribeTargetGroups_602733, base: "/",
    url: url_GetDescribeTargetGroups_602734, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetHealth_602790 = ref object of OpenApiRestCall_601389
proc url_PostDescribeTargetHealth_602792(protocol: Scheme; host: string;
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

proc validate_PostDescribeTargetHealth_602791(path: JsonNode; query: JsonNode;
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
  var valid_602793 = query.getOrDefault("Action")
  valid_602793 = validateParameter(valid_602793, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_602793 != nil:
    section.add "Action", valid_602793
  var valid_602794 = query.getOrDefault("Version")
  valid_602794 = validateParameter(valid_602794, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602794 != nil:
    section.add "Version", valid_602794
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602795 = header.getOrDefault("X-Amz-Signature")
  valid_602795 = validateParameter(valid_602795, JString, required = false,
                                 default = nil)
  if valid_602795 != nil:
    section.add "X-Amz-Signature", valid_602795
  var valid_602796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602796 = validateParameter(valid_602796, JString, required = false,
                                 default = nil)
  if valid_602796 != nil:
    section.add "X-Amz-Content-Sha256", valid_602796
  var valid_602797 = header.getOrDefault("X-Amz-Date")
  valid_602797 = validateParameter(valid_602797, JString, required = false,
                                 default = nil)
  if valid_602797 != nil:
    section.add "X-Amz-Date", valid_602797
  var valid_602798 = header.getOrDefault("X-Amz-Credential")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "X-Amz-Credential", valid_602798
  var valid_602799 = header.getOrDefault("X-Amz-Security-Token")
  valid_602799 = validateParameter(valid_602799, JString, required = false,
                                 default = nil)
  if valid_602799 != nil:
    section.add "X-Amz-Security-Token", valid_602799
  var valid_602800 = header.getOrDefault("X-Amz-Algorithm")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "X-Amz-Algorithm", valid_602800
  var valid_602801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "X-Amz-SignedHeaders", valid_602801
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_602802 = formData.getOrDefault("Targets")
  valid_602802 = validateParameter(valid_602802, JArray, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "Targets", valid_602802
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_602803 = formData.getOrDefault("TargetGroupArn")
  valid_602803 = validateParameter(valid_602803, JString, required = true,
                                 default = nil)
  if valid_602803 != nil:
    section.add "TargetGroupArn", valid_602803
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602804: Call_PostDescribeTargetHealth_602790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_602804.validator(path, query, header, formData, body)
  let scheme = call_602804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602804.url(scheme.get, call_602804.host, call_602804.base,
                         call_602804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602804, url, valid)

proc call*(call_602805: Call_PostDescribeTargetHealth_602790;
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
  var query_602806 = newJObject()
  var formData_602807 = newJObject()
  if Targets != nil:
    formData_602807.add "Targets", Targets
  add(query_602806, "Action", newJString(Action))
  add(formData_602807, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_602806, "Version", newJString(Version))
  result = call_602805.call(nil, query_602806, nil, formData_602807, nil)

var postDescribeTargetHealth* = Call_PostDescribeTargetHealth_602790(
    name: "postDescribeTargetHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_PostDescribeTargetHealth_602791, base: "/",
    url: url_PostDescribeTargetHealth_602792, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetHealth_602773 = ref object of OpenApiRestCall_601389
proc url_GetDescribeTargetHealth_602775(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeTargetHealth_602774(path: JsonNode; query: JsonNode;
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
  var valid_602776 = query.getOrDefault("Targets")
  valid_602776 = validateParameter(valid_602776, JArray, required = false,
                                 default = nil)
  if valid_602776 != nil:
    section.add "Targets", valid_602776
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_602777 = query.getOrDefault("TargetGroupArn")
  valid_602777 = validateParameter(valid_602777, JString, required = true,
                                 default = nil)
  if valid_602777 != nil:
    section.add "TargetGroupArn", valid_602777
  var valid_602778 = query.getOrDefault("Action")
  valid_602778 = validateParameter(valid_602778, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_602778 != nil:
    section.add "Action", valid_602778
  var valid_602779 = query.getOrDefault("Version")
  valid_602779 = validateParameter(valid_602779, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602779 != nil:
    section.add "Version", valid_602779
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602780 = header.getOrDefault("X-Amz-Signature")
  valid_602780 = validateParameter(valid_602780, JString, required = false,
                                 default = nil)
  if valid_602780 != nil:
    section.add "X-Amz-Signature", valid_602780
  var valid_602781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602781 = validateParameter(valid_602781, JString, required = false,
                                 default = nil)
  if valid_602781 != nil:
    section.add "X-Amz-Content-Sha256", valid_602781
  var valid_602782 = header.getOrDefault("X-Amz-Date")
  valid_602782 = validateParameter(valid_602782, JString, required = false,
                                 default = nil)
  if valid_602782 != nil:
    section.add "X-Amz-Date", valid_602782
  var valid_602783 = header.getOrDefault("X-Amz-Credential")
  valid_602783 = validateParameter(valid_602783, JString, required = false,
                                 default = nil)
  if valid_602783 != nil:
    section.add "X-Amz-Credential", valid_602783
  var valid_602784 = header.getOrDefault("X-Amz-Security-Token")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "X-Amz-Security-Token", valid_602784
  var valid_602785 = header.getOrDefault("X-Amz-Algorithm")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-Algorithm", valid_602785
  var valid_602786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-SignedHeaders", valid_602786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602787: Call_GetDescribeTargetHealth_602773; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_602787.validator(path, query, header, formData, body)
  let scheme = call_602787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602787.url(scheme.get, call_602787.host, call_602787.base,
                         call_602787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602787, url, valid)

proc call*(call_602788: Call_GetDescribeTargetHealth_602773;
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
  var query_602789 = newJObject()
  if Targets != nil:
    query_602789.add "Targets", Targets
  add(query_602789, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_602789, "Action", newJString(Action))
  add(query_602789, "Version", newJString(Version))
  result = call_602788.call(nil, query_602789, nil, nil, nil)

var getDescribeTargetHealth* = Call_GetDescribeTargetHealth_602773(
    name: "getDescribeTargetHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_GetDescribeTargetHealth_602774, base: "/",
    url: url_GetDescribeTargetHealth_602775, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyListener_602829 = ref object of OpenApiRestCall_601389
proc url_PostModifyListener_602831(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyListener_602830(path: JsonNode; query: JsonNode;
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
  var valid_602832 = query.getOrDefault("Action")
  valid_602832 = validateParameter(valid_602832, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_602832 != nil:
    section.add "Action", valid_602832
  var valid_602833 = query.getOrDefault("Version")
  valid_602833 = validateParameter(valid_602833, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602833 != nil:
    section.add "Version", valid_602833
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602834 = header.getOrDefault("X-Amz-Signature")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-Signature", valid_602834
  var valid_602835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "X-Amz-Content-Sha256", valid_602835
  var valid_602836 = header.getOrDefault("X-Amz-Date")
  valid_602836 = validateParameter(valid_602836, JString, required = false,
                                 default = nil)
  if valid_602836 != nil:
    section.add "X-Amz-Date", valid_602836
  var valid_602837 = header.getOrDefault("X-Amz-Credential")
  valid_602837 = validateParameter(valid_602837, JString, required = false,
                                 default = nil)
  if valid_602837 != nil:
    section.add "X-Amz-Credential", valid_602837
  var valid_602838 = header.getOrDefault("X-Amz-Security-Token")
  valid_602838 = validateParameter(valid_602838, JString, required = false,
                                 default = nil)
  if valid_602838 != nil:
    section.add "X-Amz-Security-Token", valid_602838
  var valid_602839 = header.getOrDefault("X-Amz-Algorithm")
  valid_602839 = validateParameter(valid_602839, JString, required = false,
                                 default = nil)
  if valid_602839 != nil:
    section.add "X-Amz-Algorithm", valid_602839
  var valid_602840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602840 = validateParameter(valid_602840, JString, required = false,
                                 default = nil)
  if valid_602840 != nil:
    section.add "X-Amz-SignedHeaders", valid_602840
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
  var valid_602841 = formData.getOrDefault("Port")
  valid_602841 = validateParameter(valid_602841, JInt, required = false, default = nil)
  if valid_602841 != nil:
    section.add "Port", valid_602841
  var valid_602842 = formData.getOrDefault("Certificates")
  valid_602842 = validateParameter(valid_602842, JArray, required = false,
                                 default = nil)
  if valid_602842 != nil:
    section.add "Certificates", valid_602842
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_602843 = formData.getOrDefault("ListenerArn")
  valid_602843 = validateParameter(valid_602843, JString, required = true,
                                 default = nil)
  if valid_602843 != nil:
    section.add "ListenerArn", valid_602843
  var valid_602844 = formData.getOrDefault("DefaultActions")
  valid_602844 = validateParameter(valid_602844, JArray, required = false,
                                 default = nil)
  if valid_602844 != nil:
    section.add "DefaultActions", valid_602844
  var valid_602845 = formData.getOrDefault("Protocol")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_602845 != nil:
    section.add "Protocol", valid_602845
  var valid_602846 = formData.getOrDefault("SslPolicy")
  valid_602846 = validateParameter(valid_602846, JString, required = false,
                                 default = nil)
  if valid_602846 != nil:
    section.add "SslPolicy", valid_602846
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602847: Call_PostModifyListener_602829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ## 
  let valid = call_602847.validator(path, query, header, formData, body)
  let scheme = call_602847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602847.url(scheme.get, call_602847.host, call_602847.base,
                         call_602847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602847, url, valid)

proc call*(call_602848: Call_PostModifyListener_602829; ListenerArn: string;
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
  var query_602849 = newJObject()
  var formData_602850 = newJObject()
  add(formData_602850, "Port", newJInt(Port))
  if Certificates != nil:
    formData_602850.add "Certificates", Certificates
  add(formData_602850, "ListenerArn", newJString(ListenerArn))
  if DefaultActions != nil:
    formData_602850.add "DefaultActions", DefaultActions
  add(formData_602850, "Protocol", newJString(Protocol))
  add(query_602849, "Action", newJString(Action))
  add(formData_602850, "SslPolicy", newJString(SslPolicy))
  add(query_602849, "Version", newJString(Version))
  result = call_602848.call(nil, query_602849, nil, formData_602850, nil)

var postModifyListener* = Call_PostModifyListener_602829(
    name: "postModifyListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=ModifyListener",
    validator: validate_PostModifyListener_602830, base: "/",
    url: url_PostModifyListener_602831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyListener_602808 = ref object of OpenApiRestCall_601389
proc url_GetModifyListener_602810(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyListener_602809(path: JsonNode; query: JsonNode;
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
  var valid_602811 = query.getOrDefault("SslPolicy")
  valid_602811 = validateParameter(valid_602811, JString, required = false,
                                 default = nil)
  if valid_602811 != nil:
    section.add "SslPolicy", valid_602811
  assert query != nil,
        "query argument is necessary due to required `ListenerArn` field"
  var valid_602812 = query.getOrDefault("ListenerArn")
  valid_602812 = validateParameter(valid_602812, JString, required = true,
                                 default = nil)
  if valid_602812 != nil:
    section.add "ListenerArn", valid_602812
  var valid_602813 = query.getOrDefault("Certificates")
  valid_602813 = validateParameter(valid_602813, JArray, required = false,
                                 default = nil)
  if valid_602813 != nil:
    section.add "Certificates", valid_602813
  var valid_602814 = query.getOrDefault("DefaultActions")
  valid_602814 = validateParameter(valid_602814, JArray, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "DefaultActions", valid_602814
  var valid_602815 = query.getOrDefault("Action")
  valid_602815 = validateParameter(valid_602815, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_602815 != nil:
    section.add "Action", valid_602815
  var valid_602816 = query.getOrDefault("Port")
  valid_602816 = validateParameter(valid_602816, JInt, required = false, default = nil)
  if valid_602816 != nil:
    section.add "Port", valid_602816
  var valid_602817 = query.getOrDefault("Protocol")
  valid_602817 = validateParameter(valid_602817, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_602817 != nil:
    section.add "Protocol", valid_602817
  var valid_602818 = query.getOrDefault("Version")
  valid_602818 = validateParameter(valid_602818, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602818 != nil:
    section.add "Version", valid_602818
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602819 = header.getOrDefault("X-Amz-Signature")
  valid_602819 = validateParameter(valid_602819, JString, required = false,
                                 default = nil)
  if valid_602819 != nil:
    section.add "X-Amz-Signature", valid_602819
  var valid_602820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-Content-Sha256", valid_602820
  var valid_602821 = header.getOrDefault("X-Amz-Date")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "X-Amz-Date", valid_602821
  var valid_602822 = header.getOrDefault("X-Amz-Credential")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "X-Amz-Credential", valid_602822
  var valid_602823 = header.getOrDefault("X-Amz-Security-Token")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "X-Amz-Security-Token", valid_602823
  var valid_602824 = header.getOrDefault("X-Amz-Algorithm")
  valid_602824 = validateParameter(valid_602824, JString, required = false,
                                 default = nil)
  if valid_602824 != nil:
    section.add "X-Amz-Algorithm", valid_602824
  var valid_602825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602825 = validateParameter(valid_602825, JString, required = false,
                                 default = nil)
  if valid_602825 != nil:
    section.add "X-Amz-SignedHeaders", valid_602825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602826: Call_GetModifyListener_602808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ## 
  let valid = call_602826.validator(path, query, header, formData, body)
  let scheme = call_602826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602826.url(scheme.get, call_602826.host, call_602826.base,
                         call_602826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602826, url, valid)

proc call*(call_602827: Call_GetModifyListener_602808; ListenerArn: string;
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
  var query_602828 = newJObject()
  add(query_602828, "SslPolicy", newJString(SslPolicy))
  add(query_602828, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_602828.add "Certificates", Certificates
  if DefaultActions != nil:
    query_602828.add "DefaultActions", DefaultActions
  add(query_602828, "Action", newJString(Action))
  add(query_602828, "Port", newJInt(Port))
  add(query_602828, "Protocol", newJString(Protocol))
  add(query_602828, "Version", newJString(Version))
  result = call_602827.call(nil, query_602828, nil, nil, nil)

var getModifyListener* = Call_GetModifyListener_602808(name: "getModifyListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyListener", validator: validate_GetModifyListener_602809,
    base: "/", url: url_GetModifyListener_602810,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_602868 = ref object of OpenApiRestCall_601389
proc url_PostModifyLoadBalancerAttributes_602870(protocol: Scheme; host: string;
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

proc validate_PostModifyLoadBalancerAttributes_602869(path: JsonNode;
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
  var valid_602871 = query.getOrDefault("Action")
  valid_602871 = validateParameter(valid_602871, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_602871 != nil:
    section.add "Action", valid_602871
  var valid_602872 = query.getOrDefault("Version")
  valid_602872 = validateParameter(valid_602872, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602872 != nil:
    section.add "Version", valid_602872
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602873 = header.getOrDefault("X-Amz-Signature")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Signature", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Content-Sha256", valid_602874
  var valid_602875 = header.getOrDefault("X-Amz-Date")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-Date", valid_602875
  var valid_602876 = header.getOrDefault("X-Amz-Credential")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-Credential", valid_602876
  var valid_602877 = header.getOrDefault("X-Amz-Security-Token")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "X-Amz-Security-Token", valid_602877
  var valid_602878 = header.getOrDefault("X-Amz-Algorithm")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-Algorithm", valid_602878
  var valid_602879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "X-Amz-SignedHeaders", valid_602879
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_602880 = formData.getOrDefault("Attributes")
  valid_602880 = validateParameter(valid_602880, JArray, required = true, default = nil)
  if valid_602880 != nil:
    section.add "Attributes", valid_602880
  var valid_602881 = formData.getOrDefault("LoadBalancerArn")
  valid_602881 = validateParameter(valid_602881, JString, required = true,
                                 default = nil)
  if valid_602881 != nil:
    section.add "LoadBalancerArn", valid_602881
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602882: Call_PostModifyLoadBalancerAttributes_602868;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_602882.validator(path, query, header, formData, body)
  let scheme = call_602882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602882.url(scheme.get, call_602882.host, call_602882.base,
                         call_602882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602882, url, valid)

proc call*(call_602883: Call_PostModifyLoadBalancerAttributes_602868;
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
  var query_602884 = newJObject()
  var formData_602885 = newJObject()
  if Attributes != nil:
    formData_602885.add "Attributes", Attributes
  add(query_602884, "Action", newJString(Action))
  add(query_602884, "Version", newJString(Version))
  add(formData_602885, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_602883.call(nil, query_602884, nil, formData_602885, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_602868(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_602869, base: "/",
    url: url_PostModifyLoadBalancerAttributes_602870,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_602851 = ref object of OpenApiRestCall_601389
proc url_GetModifyLoadBalancerAttributes_602853(protocol: Scheme; host: string;
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

proc validate_GetModifyLoadBalancerAttributes_602852(path: JsonNode;
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
  var valid_602854 = query.getOrDefault("LoadBalancerArn")
  valid_602854 = validateParameter(valid_602854, JString, required = true,
                                 default = nil)
  if valid_602854 != nil:
    section.add "LoadBalancerArn", valid_602854
  var valid_602855 = query.getOrDefault("Attributes")
  valid_602855 = validateParameter(valid_602855, JArray, required = true, default = nil)
  if valid_602855 != nil:
    section.add "Attributes", valid_602855
  var valid_602856 = query.getOrDefault("Action")
  valid_602856 = validateParameter(valid_602856, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_602856 != nil:
    section.add "Action", valid_602856
  var valid_602857 = query.getOrDefault("Version")
  valid_602857 = validateParameter(valid_602857, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602857 != nil:
    section.add "Version", valid_602857
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602858 = header.getOrDefault("X-Amz-Signature")
  valid_602858 = validateParameter(valid_602858, JString, required = false,
                                 default = nil)
  if valid_602858 != nil:
    section.add "X-Amz-Signature", valid_602858
  var valid_602859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602859 = validateParameter(valid_602859, JString, required = false,
                                 default = nil)
  if valid_602859 != nil:
    section.add "X-Amz-Content-Sha256", valid_602859
  var valid_602860 = header.getOrDefault("X-Amz-Date")
  valid_602860 = validateParameter(valid_602860, JString, required = false,
                                 default = nil)
  if valid_602860 != nil:
    section.add "X-Amz-Date", valid_602860
  var valid_602861 = header.getOrDefault("X-Amz-Credential")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "X-Amz-Credential", valid_602861
  var valid_602862 = header.getOrDefault("X-Amz-Security-Token")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "X-Amz-Security-Token", valid_602862
  var valid_602863 = header.getOrDefault("X-Amz-Algorithm")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-Algorithm", valid_602863
  var valid_602864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602864 = validateParameter(valid_602864, JString, required = false,
                                 default = nil)
  if valid_602864 != nil:
    section.add "X-Amz-SignedHeaders", valid_602864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602865: Call_GetModifyLoadBalancerAttributes_602851;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_602865.validator(path, query, header, formData, body)
  let scheme = call_602865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602865.url(scheme.get, call_602865.host, call_602865.base,
                         call_602865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602865, url, valid)

proc call*(call_602866: Call_GetModifyLoadBalancerAttributes_602851;
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
  var query_602867 = newJObject()
  add(query_602867, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Attributes != nil:
    query_602867.add "Attributes", Attributes
  add(query_602867, "Action", newJString(Action))
  add(query_602867, "Version", newJString(Version))
  result = call_602866.call(nil, query_602867, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_602851(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_602852, base: "/",
    url: url_GetModifyLoadBalancerAttributes_602853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyRule_602904 = ref object of OpenApiRestCall_601389
proc url_PostModifyRule_602906(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyRule_602905(path: JsonNode; query: JsonNode;
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
  var valid_602907 = query.getOrDefault("Action")
  valid_602907 = validateParameter(valid_602907, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_602907 != nil:
    section.add "Action", valid_602907
  var valid_602908 = query.getOrDefault("Version")
  valid_602908 = validateParameter(valid_602908, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602908 != nil:
    section.add "Version", valid_602908
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602909 = header.getOrDefault("X-Amz-Signature")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Signature", valid_602909
  var valid_602910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Content-Sha256", valid_602910
  var valid_602911 = header.getOrDefault("X-Amz-Date")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-Date", valid_602911
  var valid_602912 = header.getOrDefault("X-Amz-Credential")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "X-Amz-Credential", valid_602912
  var valid_602913 = header.getOrDefault("X-Amz-Security-Token")
  valid_602913 = validateParameter(valid_602913, JString, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "X-Amz-Security-Token", valid_602913
  var valid_602914 = header.getOrDefault("X-Amz-Algorithm")
  valid_602914 = validateParameter(valid_602914, JString, required = false,
                                 default = nil)
  if valid_602914 != nil:
    section.add "X-Amz-Algorithm", valid_602914
  var valid_602915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602915 = validateParameter(valid_602915, JString, required = false,
                                 default = nil)
  if valid_602915 != nil:
    section.add "X-Amz-SignedHeaders", valid_602915
  result.add "header", section
  ## parameters in `formData` object:
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  var valid_602916 = formData.getOrDefault("Actions")
  valid_602916 = validateParameter(valid_602916, JArray, required = false,
                                 default = nil)
  if valid_602916 != nil:
    section.add "Actions", valid_602916
  var valid_602917 = formData.getOrDefault("Conditions")
  valid_602917 = validateParameter(valid_602917, JArray, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "Conditions", valid_602917
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_602918 = formData.getOrDefault("RuleArn")
  valid_602918 = validateParameter(valid_602918, JString, required = true,
                                 default = nil)
  if valid_602918 != nil:
    section.add "RuleArn", valid_602918
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602919: Call_PostModifyRule_602904; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_602919.validator(path, query, header, formData, body)
  let scheme = call_602919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602919.url(scheme.get, call_602919.host, call_602919.base,
                         call_602919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602919, url, valid)

proc call*(call_602920: Call_PostModifyRule_602904; RuleArn: string;
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
  var query_602921 = newJObject()
  var formData_602922 = newJObject()
  if Actions != nil:
    formData_602922.add "Actions", Actions
  if Conditions != nil:
    formData_602922.add "Conditions", Conditions
  add(formData_602922, "RuleArn", newJString(RuleArn))
  add(query_602921, "Action", newJString(Action))
  add(query_602921, "Version", newJString(Version))
  result = call_602920.call(nil, query_602921, nil, formData_602922, nil)

var postModifyRule* = Call_PostModifyRule_602904(name: "postModifyRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_PostModifyRule_602905,
    base: "/", url: url_PostModifyRule_602906, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyRule_602886 = ref object of OpenApiRestCall_601389
proc url_GetModifyRule_602888(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyRule_602887(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602889 = query.getOrDefault("RuleArn")
  valid_602889 = validateParameter(valid_602889, JString, required = true,
                                 default = nil)
  if valid_602889 != nil:
    section.add "RuleArn", valid_602889
  var valid_602890 = query.getOrDefault("Actions")
  valid_602890 = validateParameter(valid_602890, JArray, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "Actions", valid_602890
  var valid_602891 = query.getOrDefault("Action")
  valid_602891 = validateParameter(valid_602891, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_602891 != nil:
    section.add "Action", valid_602891
  var valid_602892 = query.getOrDefault("Version")
  valid_602892 = validateParameter(valid_602892, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602892 != nil:
    section.add "Version", valid_602892
  var valid_602893 = query.getOrDefault("Conditions")
  valid_602893 = validateParameter(valid_602893, JArray, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "Conditions", valid_602893
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602894 = header.getOrDefault("X-Amz-Signature")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "X-Amz-Signature", valid_602894
  var valid_602895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602895 = validateParameter(valid_602895, JString, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "X-Amz-Content-Sha256", valid_602895
  var valid_602896 = header.getOrDefault("X-Amz-Date")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "X-Amz-Date", valid_602896
  var valid_602897 = header.getOrDefault("X-Amz-Credential")
  valid_602897 = validateParameter(valid_602897, JString, required = false,
                                 default = nil)
  if valid_602897 != nil:
    section.add "X-Amz-Credential", valid_602897
  var valid_602898 = header.getOrDefault("X-Amz-Security-Token")
  valid_602898 = validateParameter(valid_602898, JString, required = false,
                                 default = nil)
  if valid_602898 != nil:
    section.add "X-Amz-Security-Token", valid_602898
  var valid_602899 = header.getOrDefault("X-Amz-Algorithm")
  valid_602899 = validateParameter(valid_602899, JString, required = false,
                                 default = nil)
  if valid_602899 != nil:
    section.add "X-Amz-Algorithm", valid_602899
  var valid_602900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-SignedHeaders", valid_602900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602901: Call_GetModifyRule_602886; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_602901.validator(path, query, header, formData, body)
  let scheme = call_602901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602901.url(scheme.get, call_602901.host, call_602901.base,
                         call_602901.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602901, url, valid)

proc call*(call_602902: Call_GetModifyRule_602886; RuleArn: string;
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
  var query_602903 = newJObject()
  add(query_602903, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    query_602903.add "Actions", Actions
  add(query_602903, "Action", newJString(Action))
  add(query_602903, "Version", newJString(Version))
  if Conditions != nil:
    query_602903.add "Conditions", Conditions
  result = call_602902.call(nil, query_602903, nil, nil, nil)

var getModifyRule* = Call_GetModifyRule_602886(name: "getModifyRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_GetModifyRule_602887,
    base: "/", url: url_GetModifyRule_602888, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroup_602948 = ref object of OpenApiRestCall_601389
proc url_PostModifyTargetGroup_602950(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyTargetGroup_602949(path: JsonNode; query: JsonNode;
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
  var valid_602951 = query.getOrDefault("Action")
  valid_602951 = validateParameter(valid_602951, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_602951 != nil:
    section.add "Action", valid_602951
  var valid_602952 = query.getOrDefault("Version")
  valid_602952 = validateParameter(valid_602952, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602952 != nil:
    section.add "Version", valid_602952
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602953 = header.getOrDefault("X-Amz-Signature")
  valid_602953 = validateParameter(valid_602953, JString, required = false,
                                 default = nil)
  if valid_602953 != nil:
    section.add "X-Amz-Signature", valid_602953
  var valid_602954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602954 = validateParameter(valid_602954, JString, required = false,
                                 default = nil)
  if valid_602954 != nil:
    section.add "X-Amz-Content-Sha256", valid_602954
  var valid_602955 = header.getOrDefault("X-Amz-Date")
  valid_602955 = validateParameter(valid_602955, JString, required = false,
                                 default = nil)
  if valid_602955 != nil:
    section.add "X-Amz-Date", valid_602955
  var valid_602956 = header.getOrDefault("X-Amz-Credential")
  valid_602956 = validateParameter(valid_602956, JString, required = false,
                                 default = nil)
  if valid_602956 != nil:
    section.add "X-Amz-Credential", valid_602956
  var valid_602957 = header.getOrDefault("X-Amz-Security-Token")
  valid_602957 = validateParameter(valid_602957, JString, required = false,
                                 default = nil)
  if valid_602957 != nil:
    section.add "X-Amz-Security-Token", valid_602957
  var valid_602958 = header.getOrDefault("X-Amz-Algorithm")
  valid_602958 = validateParameter(valid_602958, JString, required = false,
                                 default = nil)
  if valid_602958 != nil:
    section.add "X-Amz-Algorithm", valid_602958
  var valid_602959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602959 = validateParameter(valid_602959, JString, required = false,
                                 default = nil)
  if valid_602959 != nil:
    section.add "X-Amz-SignedHeaders", valid_602959
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
  var valid_602960 = formData.getOrDefault("HealthCheckProtocol")
  valid_602960 = validateParameter(valid_602960, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_602960 != nil:
    section.add "HealthCheckProtocol", valid_602960
  var valid_602961 = formData.getOrDefault("HealthCheckPort")
  valid_602961 = validateParameter(valid_602961, JString, required = false,
                                 default = nil)
  if valid_602961 != nil:
    section.add "HealthCheckPort", valid_602961
  var valid_602962 = formData.getOrDefault("HealthCheckEnabled")
  valid_602962 = validateParameter(valid_602962, JBool, required = false, default = nil)
  if valid_602962 != nil:
    section.add "HealthCheckEnabled", valid_602962
  var valid_602963 = formData.getOrDefault("HealthCheckPath")
  valid_602963 = validateParameter(valid_602963, JString, required = false,
                                 default = nil)
  if valid_602963 != nil:
    section.add "HealthCheckPath", valid_602963
  var valid_602964 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_602964 = validateParameter(valid_602964, JInt, required = false, default = nil)
  if valid_602964 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_602964
  var valid_602965 = formData.getOrDefault("HealthyThresholdCount")
  valid_602965 = validateParameter(valid_602965, JInt, required = false, default = nil)
  if valid_602965 != nil:
    section.add "HealthyThresholdCount", valid_602965
  var valid_602966 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_602966 = validateParameter(valid_602966, JInt, required = false, default = nil)
  if valid_602966 != nil:
    section.add "HealthCheckIntervalSeconds", valid_602966
  var valid_602967 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_602967 = validateParameter(valid_602967, JInt, required = false, default = nil)
  if valid_602967 != nil:
    section.add "UnhealthyThresholdCount", valid_602967
  var valid_602968 = formData.getOrDefault("Matcher.HttpCode")
  valid_602968 = validateParameter(valid_602968, JString, required = false,
                                 default = nil)
  if valid_602968 != nil:
    section.add "Matcher.HttpCode", valid_602968
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_602969 = formData.getOrDefault("TargetGroupArn")
  valid_602969 = validateParameter(valid_602969, JString, required = true,
                                 default = nil)
  if valid_602969 != nil:
    section.add "TargetGroupArn", valid_602969
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602970: Call_PostModifyTargetGroup_602948; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_602970.validator(path, query, header, formData, body)
  let scheme = call_602970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602970.url(scheme.get, call_602970.host, call_602970.base,
                         call_602970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602970, url, valid)

proc call*(call_602971: Call_PostModifyTargetGroup_602948; TargetGroupArn: string;
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
  var query_602972 = newJObject()
  var formData_602973 = newJObject()
  add(formData_602973, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_602973, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_602973, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_602973, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_602973, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_602973, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_602973, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_602973, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_602973, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_602972, "Action", newJString(Action))
  add(formData_602973, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_602972, "Version", newJString(Version))
  result = call_602971.call(nil, query_602972, nil, formData_602973, nil)

var postModifyTargetGroup* = Call_PostModifyTargetGroup_602948(
    name: "postModifyTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup",
    validator: validate_PostModifyTargetGroup_602949, base: "/",
    url: url_PostModifyTargetGroup_602950, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroup_602923 = ref object of OpenApiRestCall_601389
proc url_GetModifyTargetGroup_602925(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyTargetGroup_602924(path: JsonNode; query: JsonNode;
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
  var valid_602926 = query.getOrDefault("HealthCheckPort")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "HealthCheckPort", valid_602926
  var valid_602927 = query.getOrDefault("HealthCheckPath")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "HealthCheckPath", valid_602927
  var valid_602928 = query.getOrDefault("HealthCheckProtocol")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_602928 != nil:
    section.add "HealthCheckProtocol", valid_602928
  var valid_602929 = query.getOrDefault("Matcher.HttpCode")
  valid_602929 = validateParameter(valid_602929, JString, required = false,
                                 default = nil)
  if valid_602929 != nil:
    section.add "Matcher.HttpCode", valid_602929
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_602930 = query.getOrDefault("TargetGroupArn")
  valid_602930 = validateParameter(valid_602930, JString, required = true,
                                 default = nil)
  if valid_602930 != nil:
    section.add "TargetGroupArn", valid_602930
  var valid_602931 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_602931 = validateParameter(valid_602931, JInt, required = false, default = nil)
  if valid_602931 != nil:
    section.add "HealthCheckIntervalSeconds", valid_602931
  var valid_602932 = query.getOrDefault("HealthCheckEnabled")
  valid_602932 = validateParameter(valid_602932, JBool, required = false, default = nil)
  if valid_602932 != nil:
    section.add "HealthCheckEnabled", valid_602932
  var valid_602933 = query.getOrDefault("HealthyThresholdCount")
  valid_602933 = validateParameter(valid_602933, JInt, required = false, default = nil)
  if valid_602933 != nil:
    section.add "HealthyThresholdCount", valid_602933
  var valid_602934 = query.getOrDefault("UnhealthyThresholdCount")
  valid_602934 = validateParameter(valid_602934, JInt, required = false, default = nil)
  if valid_602934 != nil:
    section.add "UnhealthyThresholdCount", valid_602934
  var valid_602935 = query.getOrDefault("Action")
  valid_602935 = validateParameter(valid_602935, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_602935 != nil:
    section.add "Action", valid_602935
  var valid_602936 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_602936 = validateParameter(valid_602936, JInt, required = false, default = nil)
  if valid_602936 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_602936
  var valid_602937 = query.getOrDefault("Version")
  valid_602937 = validateParameter(valid_602937, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602937 != nil:
    section.add "Version", valid_602937
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602938 = header.getOrDefault("X-Amz-Signature")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Signature", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Content-Sha256", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-Date")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-Date", valid_602940
  var valid_602941 = header.getOrDefault("X-Amz-Credential")
  valid_602941 = validateParameter(valid_602941, JString, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "X-Amz-Credential", valid_602941
  var valid_602942 = header.getOrDefault("X-Amz-Security-Token")
  valid_602942 = validateParameter(valid_602942, JString, required = false,
                                 default = nil)
  if valid_602942 != nil:
    section.add "X-Amz-Security-Token", valid_602942
  var valid_602943 = header.getOrDefault("X-Amz-Algorithm")
  valid_602943 = validateParameter(valid_602943, JString, required = false,
                                 default = nil)
  if valid_602943 != nil:
    section.add "X-Amz-Algorithm", valid_602943
  var valid_602944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602944 = validateParameter(valid_602944, JString, required = false,
                                 default = nil)
  if valid_602944 != nil:
    section.add "X-Amz-SignedHeaders", valid_602944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602945: Call_GetModifyTargetGroup_602923; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_602945.validator(path, query, header, formData, body)
  let scheme = call_602945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602945.url(scheme.get, call_602945.host, call_602945.base,
                         call_602945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602945, url, valid)

proc call*(call_602946: Call_GetModifyTargetGroup_602923; TargetGroupArn: string;
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
  var query_602947 = newJObject()
  add(query_602947, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_602947, "HealthCheckPath", newJString(HealthCheckPath))
  add(query_602947, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_602947, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_602947, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_602947, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_602947, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_602947, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_602947, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_602947, "Action", newJString(Action))
  add(query_602947, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_602947, "Version", newJString(Version))
  result = call_602946.call(nil, query_602947, nil, nil, nil)

var getModifyTargetGroup* = Call_GetModifyTargetGroup_602923(
    name: "getModifyTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup", validator: validate_GetModifyTargetGroup_602924,
    base: "/", url: url_GetModifyTargetGroup_602925,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroupAttributes_602991 = ref object of OpenApiRestCall_601389
proc url_PostModifyTargetGroupAttributes_602993(protocol: Scheme; host: string;
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

proc validate_PostModifyTargetGroupAttributes_602992(path: JsonNode;
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
  var valid_602994 = query.getOrDefault("Action")
  valid_602994 = validateParameter(valid_602994, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_602994 != nil:
    section.add "Action", valid_602994
  var valid_602995 = query.getOrDefault("Version")
  valid_602995 = validateParameter(valid_602995, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602995 != nil:
    section.add "Version", valid_602995
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602996 = header.getOrDefault("X-Amz-Signature")
  valid_602996 = validateParameter(valid_602996, JString, required = false,
                                 default = nil)
  if valid_602996 != nil:
    section.add "X-Amz-Signature", valid_602996
  var valid_602997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602997 = validateParameter(valid_602997, JString, required = false,
                                 default = nil)
  if valid_602997 != nil:
    section.add "X-Amz-Content-Sha256", valid_602997
  var valid_602998 = header.getOrDefault("X-Amz-Date")
  valid_602998 = validateParameter(valid_602998, JString, required = false,
                                 default = nil)
  if valid_602998 != nil:
    section.add "X-Amz-Date", valid_602998
  var valid_602999 = header.getOrDefault("X-Amz-Credential")
  valid_602999 = validateParameter(valid_602999, JString, required = false,
                                 default = nil)
  if valid_602999 != nil:
    section.add "X-Amz-Credential", valid_602999
  var valid_603000 = header.getOrDefault("X-Amz-Security-Token")
  valid_603000 = validateParameter(valid_603000, JString, required = false,
                                 default = nil)
  if valid_603000 != nil:
    section.add "X-Amz-Security-Token", valid_603000
  var valid_603001 = header.getOrDefault("X-Amz-Algorithm")
  valid_603001 = validateParameter(valid_603001, JString, required = false,
                                 default = nil)
  if valid_603001 != nil:
    section.add "X-Amz-Algorithm", valid_603001
  var valid_603002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603002 = validateParameter(valid_603002, JString, required = false,
                                 default = nil)
  if valid_603002 != nil:
    section.add "X-Amz-SignedHeaders", valid_603002
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_603003 = formData.getOrDefault("Attributes")
  valid_603003 = validateParameter(valid_603003, JArray, required = true, default = nil)
  if valid_603003 != nil:
    section.add "Attributes", valid_603003
  var valid_603004 = formData.getOrDefault("TargetGroupArn")
  valid_603004 = validateParameter(valid_603004, JString, required = true,
                                 default = nil)
  if valid_603004 != nil:
    section.add "TargetGroupArn", valid_603004
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603005: Call_PostModifyTargetGroupAttributes_602991;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_603005.validator(path, query, header, formData, body)
  let scheme = call_603005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603005.url(scheme.get, call_603005.host, call_603005.base,
                         call_603005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603005, url, valid)

proc call*(call_603006: Call_PostModifyTargetGroupAttributes_602991;
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
  var query_603007 = newJObject()
  var formData_603008 = newJObject()
  if Attributes != nil:
    formData_603008.add "Attributes", Attributes
  add(query_603007, "Action", newJString(Action))
  add(formData_603008, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603007, "Version", newJString(Version))
  result = call_603006.call(nil, query_603007, nil, formData_603008, nil)

var postModifyTargetGroupAttributes* = Call_PostModifyTargetGroupAttributes_602991(
    name: "postModifyTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_PostModifyTargetGroupAttributes_602992, base: "/",
    url: url_PostModifyTargetGroupAttributes_602993,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroupAttributes_602974 = ref object of OpenApiRestCall_601389
proc url_GetModifyTargetGroupAttributes_602976(protocol: Scheme; host: string;
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

proc validate_GetModifyTargetGroupAttributes_602975(path: JsonNode;
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
  var valid_602977 = query.getOrDefault("TargetGroupArn")
  valid_602977 = validateParameter(valid_602977, JString, required = true,
                                 default = nil)
  if valid_602977 != nil:
    section.add "TargetGroupArn", valid_602977
  var valid_602978 = query.getOrDefault("Attributes")
  valid_602978 = validateParameter(valid_602978, JArray, required = true, default = nil)
  if valid_602978 != nil:
    section.add "Attributes", valid_602978
  var valid_602979 = query.getOrDefault("Action")
  valid_602979 = validateParameter(valid_602979, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_602979 != nil:
    section.add "Action", valid_602979
  var valid_602980 = query.getOrDefault("Version")
  valid_602980 = validateParameter(valid_602980, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602980 != nil:
    section.add "Version", valid_602980
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602981 = header.getOrDefault("X-Amz-Signature")
  valid_602981 = validateParameter(valid_602981, JString, required = false,
                                 default = nil)
  if valid_602981 != nil:
    section.add "X-Amz-Signature", valid_602981
  var valid_602982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602982 = validateParameter(valid_602982, JString, required = false,
                                 default = nil)
  if valid_602982 != nil:
    section.add "X-Amz-Content-Sha256", valid_602982
  var valid_602983 = header.getOrDefault("X-Amz-Date")
  valid_602983 = validateParameter(valid_602983, JString, required = false,
                                 default = nil)
  if valid_602983 != nil:
    section.add "X-Amz-Date", valid_602983
  var valid_602984 = header.getOrDefault("X-Amz-Credential")
  valid_602984 = validateParameter(valid_602984, JString, required = false,
                                 default = nil)
  if valid_602984 != nil:
    section.add "X-Amz-Credential", valid_602984
  var valid_602985 = header.getOrDefault("X-Amz-Security-Token")
  valid_602985 = validateParameter(valid_602985, JString, required = false,
                                 default = nil)
  if valid_602985 != nil:
    section.add "X-Amz-Security-Token", valid_602985
  var valid_602986 = header.getOrDefault("X-Amz-Algorithm")
  valid_602986 = validateParameter(valid_602986, JString, required = false,
                                 default = nil)
  if valid_602986 != nil:
    section.add "X-Amz-Algorithm", valid_602986
  var valid_602987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602987 = validateParameter(valid_602987, JString, required = false,
                                 default = nil)
  if valid_602987 != nil:
    section.add "X-Amz-SignedHeaders", valid_602987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602988: Call_GetModifyTargetGroupAttributes_602974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_602988.validator(path, query, header, formData, body)
  let scheme = call_602988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602988.url(scheme.get, call_602988.host, call_602988.base,
                         call_602988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602988, url, valid)

proc call*(call_602989: Call_GetModifyTargetGroupAttributes_602974;
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
  var query_602990 = newJObject()
  add(query_602990, "TargetGroupArn", newJString(TargetGroupArn))
  if Attributes != nil:
    query_602990.add "Attributes", Attributes
  add(query_602990, "Action", newJString(Action))
  add(query_602990, "Version", newJString(Version))
  result = call_602989.call(nil, query_602990, nil, nil, nil)

var getModifyTargetGroupAttributes* = Call_GetModifyTargetGroupAttributes_602974(
    name: "getModifyTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_GetModifyTargetGroupAttributes_602975, base: "/",
    url: url_GetModifyTargetGroupAttributes_602976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterTargets_603026 = ref object of OpenApiRestCall_601389
proc url_PostRegisterTargets_603028(protocol: Scheme; host: string; base: string;
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

proc validate_PostRegisterTargets_603027(path: JsonNode; query: JsonNode;
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
  var valid_603029 = query.getOrDefault("Action")
  valid_603029 = validateParameter(valid_603029, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_603029 != nil:
    section.add "Action", valid_603029
  var valid_603030 = query.getOrDefault("Version")
  valid_603030 = validateParameter(valid_603030, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603030 != nil:
    section.add "Version", valid_603030
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603031 = header.getOrDefault("X-Amz-Signature")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-Signature", valid_603031
  var valid_603032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Content-Sha256", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-Date")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-Date", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Credential")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Credential", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-Security-Token")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-Security-Token", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-Algorithm")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-Algorithm", valid_603036
  var valid_603037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "X-Amz-SignedHeaders", valid_603037
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_603038 = formData.getOrDefault("Targets")
  valid_603038 = validateParameter(valid_603038, JArray, required = true, default = nil)
  if valid_603038 != nil:
    section.add "Targets", valid_603038
  var valid_603039 = formData.getOrDefault("TargetGroupArn")
  valid_603039 = validateParameter(valid_603039, JString, required = true,
                                 default = nil)
  if valid_603039 != nil:
    section.add "TargetGroupArn", valid_603039
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603040: Call_PostRegisterTargets_603026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_603040.validator(path, query, header, formData, body)
  let scheme = call_603040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603040.url(scheme.get, call_603040.host, call_603040.base,
                         call_603040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603040, url, valid)

proc call*(call_603041: Call_PostRegisterTargets_603026; Targets: JsonNode;
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
  var query_603042 = newJObject()
  var formData_603043 = newJObject()
  if Targets != nil:
    formData_603043.add "Targets", Targets
  add(query_603042, "Action", newJString(Action))
  add(formData_603043, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603042, "Version", newJString(Version))
  result = call_603041.call(nil, query_603042, nil, formData_603043, nil)

var postRegisterTargets* = Call_PostRegisterTargets_603026(
    name: "postRegisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_PostRegisterTargets_603027, base: "/",
    url: url_PostRegisterTargets_603028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterTargets_603009 = ref object of OpenApiRestCall_601389
proc url_GetRegisterTargets_603011(protocol: Scheme; host: string; base: string;
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

proc validate_GetRegisterTargets_603010(path: JsonNode; query: JsonNode;
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
  var valid_603012 = query.getOrDefault("Targets")
  valid_603012 = validateParameter(valid_603012, JArray, required = true, default = nil)
  if valid_603012 != nil:
    section.add "Targets", valid_603012
  var valid_603013 = query.getOrDefault("TargetGroupArn")
  valid_603013 = validateParameter(valid_603013, JString, required = true,
                                 default = nil)
  if valid_603013 != nil:
    section.add "TargetGroupArn", valid_603013
  var valid_603014 = query.getOrDefault("Action")
  valid_603014 = validateParameter(valid_603014, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_603014 != nil:
    section.add "Action", valid_603014
  var valid_603015 = query.getOrDefault("Version")
  valid_603015 = validateParameter(valid_603015, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603015 != nil:
    section.add "Version", valid_603015
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603016 = header.getOrDefault("X-Amz-Signature")
  valid_603016 = validateParameter(valid_603016, JString, required = false,
                                 default = nil)
  if valid_603016 != nil:
    section.add "X-Amz-Signature", valid_603016
  var valid_603017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603017 = validateParameter(valid_603017, JString, required = false,
                                 default = nil)
  if valid_603017 != nil:
    section.add "X-Amz-Content-Sha256", valid_603017
  var valid_603018 = header.getOrDefault("X-Amz-Date")
  valid_603018 = validateParameter(valid_603018, JString, required = false,
                                 default = nil)
  if valid_603018 != nil:
    section.add "X-Amz-Date", valid_603018
  var valid_603019 = header.getOrDefault("X-Amz-Credential")
  valid_603019 = validateParameter(valid_603019, JString, required = false,
                                 default = nil)
  if valid_603019 != nil:
    section.add "X-Amz-Credential", valid_603019
  var valid_603020 = header.getOrDefault("X-Amz-Security-Token")
  valid_603020 = validateParameter(valid_603020, JString, required = false,
                                 default = nil)
  if valid_603020 != nil:
    section.add "X-Amz-Security-Token", valid_603020
  var valid_603021 = header.getOrDefault("X-Amz-Algorithm")
  valid_603021 = validateParameter(valid_603021, JString, required = false,
                                 default = nil)
  if valid_603021 != nil:
    section.add "X-Amz-Algorithm", valid_603021
  var valid_603022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603022 = validateParameter(valid_603022, JString, required = false,
                                 default = nil)
  if valid_603022 != nil:
    section.add "X-Amz-SignedHeaders", valid_603022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603023: Call_GetRegisterTargets_603009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_603023.validator(path, query, header, formData, body)
  let scheme = call_603023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603023.url(scheme.get, call_603023.host, call_603023.base,
                         call_603023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603023, url, valid)

proc call*(call_603024: Call_GetRegisterTargets_603009; Targets: JsonNode;
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
  var query_603025 = newJObject()
  if Targets != nil:
    query_603025.add "Targets", Targets
  add(query_603025, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603025, "Action", newJString(Action))
  add(query_603025, "Version", newJString(Version))
  result = call_603024.call(nil, query_603025, nil, nil, nil)

var getRegisterTargets* = Call_GetRegisterTargets_603009(
    name: "getRegisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_GetRegisterTargets_603010, base: "/",
    url: url_GetRegisterTargets_603011, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveListenerCertificates_603061 = ref object of OpenApiRestCall_601389
proc url_PostRemoveListenerCertificates_603063(protocol: Scheme; host: string;
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

proc validate_PostRemoveListenerCertificates_603062(path: JsonNode;
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
  var valid_603064 = query.getOrDefault("Action")
  valid_603064 = validateParameter(valid_603064, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_603064 != nil:
    section.add "Action", valid_603064
  var valid_603065 = query.getOrDefault("Version")
  valid_603065 = validateParameter(valid_603065, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603065 != nil:
    section.add "Version", valid_603065
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603066 = header.getOrDefault("X-Amz-Signature")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Signature", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Content-Sha256", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Date")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Date", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Credential")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Credential", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Security-Token")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Security-Token", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Algorithm")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Algorithm", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-SignedHeaders", valid_603072
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_603073 = formData.getOrDefault("Certificates")
  valid_603073 = validateParameter(valid_603073, JArray, required = true, default = nil)
  if valid_603073 != nil:
    section.add "Certificates", valid_603073
  var valid_603074 = formData.getOrDefault("ListenerArn")
  valid_603074 = validateParameter(valid_603074, JString, required = true,
                                 default = nil)
  if valid_603074 != nil:
    section.add "ListenerArn", valid_603074
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603075: Call_PostRemoveListenerCertificates_603061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_603075.validator(path, query, header, formData, body)
  let scheme = call_603075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603075.url(scheme.get, call_603075.host, call_603075.base,
                         call_603075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603075, url, valid)

proc call*(call_603076: Call_PostRemoveListenerCertificates_603061;
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
  var query_603077 = newJObject()
  var formData_603078 = newJObject()
  if Certificates != nil:
    formData_603078.add "Certificates", Certificates
  add(formData_603078, "ListenerArn", newJString(ListenerArn))
  add(query_603077, "Action", newJString(Action))
  add(query_603077, "Version", newJString(Version))
  result = call_603076.call(nil, query_603077, nil, formData_603078, nil)

var postRemoveListenerCertificates* = Call_PostRemoveListenerCertificates_603061(
    name: "postRemoveListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_PostRemoveListenerCertificates_603062, base: "/",
    url: url_PostRemoveListenerCertificates_603063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveListenerCertificates_603044 = ref object of OpenApiRestCall_601389
proc url_GetRemoveListenerCertificates_603046(protocol: Scheme; host: string;
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

proc validate_GetRemoveListenerCertificates_603045(path: JsonNode; query: JsonNode;
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
  var valid_603047 = query.getOrDefault("ListenerArn")
  valid_603047 = validateParameter(valid_603047, JString, required = true,
                                 default = nil)
  if valid_603047 != nil:
    section.add "ListenerArn", valid_603047
  var valid_603048 = query.getOrDefault("Certificates")
  valid_603048 = validateParameter(valid_603048, JArray, required = true, default = nil)
  if valid_603048 != nil:
    section.add "Certificates", valid_603048
  var valid_603049 = query.getOrDefault("Action")
  valid_603049 = validateParameter(valid_603049, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_603049 != nil:
    section.add "Action", valid_603049
  var valid_603050 = query.getOrDefault("Version")
  valid_603050 = validateParameter(valid_603050, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603050 != nil:
    section.add "Version", valid_603050
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603051 = header.getOrDefault("X-Amz-Signature")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Signature", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Content-Sha256", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-Date")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-Date", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-Credential")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-Credential", valid_603054
  var valid_603055 = header.getOrDefault("X-Amz-Security-Token")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "X-Amz-Security-Token", valid_603055
  var valid_603056 = header.getOrDefault("X-Amz-Algorithm")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "X-Amz-Algorithm", valid_603056
  var valid_603057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-SignedHeaders", valid_603057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603058: Call_GetRemoveListenerCertificates_603044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_603058.validator(path, query, header, formData, body)
  let scheme = call_603058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603058.url(scheme.get, call_603058.host, call_603058.base,
                         call_603058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603058, url, valid)

proc call*(call_603059: Call_GetRemoveListenerCertificates_603044;
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
  var query_603060 = newJObject()
  add(query_603060, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_603060.add "Certificates", Certificates
  add(query_603060, "Action", newJString(Action))
  add(query_603060, "Version", newJString(Version))
  result = call_603059.call(nil, query_603060, nil, nil, nil)

var getRemoveListenerCertificates* = Call_GetRemoveListenerCertificates_603044(
    name: "getRemoveListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_GetRemoveListenerCertificates_603045, base: "/",
    url: url_GetRemoveListenerCertificates_603046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_603096 = ref object of OpenApiRestCall_601389
proc url_PostRemoveTags_603098(protocol: Scheme; host: string; base: string;
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

proc validate_PostRemoveTags_603097(path: JsonNode; query: JsonNode;
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
  var valid_603099 = query.getOrDefault("Action")
  valid_603099 = validateParameter(valid_603099, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_603099 != nil:
    section.add "Action", valid_603099
  var valid_603100 = query.getOrDefault("Version")
  valid_603100 = validateParameter(valid_603100, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603100 != nil:
    section.add "Version", valid_603100
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603101 = header.getOrDefault("X-Amz-Signature")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Signature", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Content-Sha256", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Date")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Date", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Credential")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Credential", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Security-Token")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Security-Token", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Algorithm")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Algorithm", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-SignedHeaders", valid_603107
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_603108 = formData.getOrDefault("TagKeys")
  valid_603108 = validateParameter(valid_603108, JArray, required = true, default = nil)
  if valid_603108 != nil:
    section.add "TagKeys", valid_603108
  var valid_603109 = formData.getOrDefault("ResourceArns")
  valid_603109 = validateParameter(valid_603109, JArray, required = true, default = nil)
  if valid_603109 != nil:
    section.add "ResourceArns", valid_603109
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603110: Call_PostRemoveTags_603096; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_603110.validator(path, query, header, formData, body)
  let scheme = call_603110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603110.url(scheme.get, call_603110.host, call_603110.base,
                         call_603110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603110, url, valid)

proc call*(call_603111: Call_PostRemoveTags_603096; TagKeys: JsonNode;
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
  var query_603112 = newJObject()
  var formData_603113 = newJObject()
  if TagKeys != nil:
    formData_603113.add "TagKeys", TagKeys
  if ResourceArns != nil:
    formData_603113.add "ResourceArns", ResourceArns
  add(query_603112, "Action", newJString(Action))
  add(query_603112, "Version", newJString(Version))
  result = call_603111.call(nil, query_603112, nil, formData_603113, nil)

var postRemoveTags* = Call_PostRemoveTags_603096(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_603097,
    base: "/", url: url_PostRemoveTags_603098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_603079 = ref object of OpenApiRestCall_601389
proc url_GetRemoveTags_603081(protocol: Scheme; host: string; base: string;
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

proc validate_GetRemoveTags_603080(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603082 = query.getOrDefault("ResourceArns")
  valid_603082 = validateParameter(valid_603082, JArray, required = true, default = nil)
  if valid_603082 != nil:
    section.add "ResourceArns", valid_603082
  var valid_603083 = query.getOrDefault("TagKeys")
  valid_603083 = validateParameter(valid_603083, JArray, required = true, default = nil)
  if valid_603083 != nil:
    section.add "TagKeys", valid_603083
  var valid_603084 = query.getOrDefault("Action")
  valid_603084 = validateParameter(valid_603084, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_603084 != nil:
    section.add "Action", valid_603084
  var valid_603085 = query.getOrDefault("Version")
  valid_603085 = validateParameter(valid_603085, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603085 != nil:
    section.add "Version", valid_603085
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603086 = header.getOrDefault("X-Amz-Signature")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Signature", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Content-Sha256", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Date")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Date", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Credential")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Credential", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Security-Token")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Security-Token", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Algorithm")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Algorithm", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-SignedHeaders", valid_603092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603093: Call_GetRemoveTags_603079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_603093.validator(path, query, header, formData, body)
  let scheme = call_603093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603093.url(scheme.get, call_603093.host, call_603093.base,
                         call_603093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603093, url, valid)

proc call*(call_603094: Call_GetRemoveTags_603079; ResourceArns: JsonNode;
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
  var query_603095 = newJObject()
  if ResourceArns != nil:
    query_603095.add "ResourceArns", ResourceArns
  if TagKeys != nil:
    query_603095.add "TagKeys", TagKeys
  add(query_603095, "Action", newJString(Action))
  add(query_603095, "Version", newJString(Version))
  result = call_603094.call(nil, query_603095, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_603079(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_603080,
    base: "/", url: url_GetRemoveTags_603081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetIpAddressType_603131 = ref object of OpenApiRestCall_601389
proc url_PostSetIpAddressType_603133(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetIpAddressType_603132(path: JsonNode; query: JsonNode;
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
  var valid_603134 = query.getOrDefault("Action")
  valid_603134 = validateParameter(valid_603134, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_603134 != nil:
    section.add "Action", valid_603134
  var valid_603135 = query.getOrDefault("Version")
  valid_603135 = validateParameter(valid_603135, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603135 != nil:
    section.add "Version", valid_603135
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603136 = header.getOrDefault("X-Amz-Signature")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Signature", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Content-Sha256", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Date")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Date", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Credential")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Credential", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Security-Token")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Security-Token", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Algorithm")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Algorithm", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-SignedHeaders", valid_603142
  result.add "header", section
  ## parameters in `formData` object:
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `IpAddressType` field"
  var valid_603143 = formData.getOrDefault("IpAddressType")
  valid_603143 = validateParameter(valid_603143, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_603143 != nil:
    section.add "IpAddressType", valid_603143
  var valid_603144 = formData.getOrDefault("LoadBalancerArn")
  valid_603144 = validateParameter(valid_603144, JString, required = true,
                                 default = nil)
  if valid_603144 != nil:
    section.add "LoadBalancerArn", valid_603144
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603145: Call_PostSetIpAddressType_603131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_603145.validator(path, query, header, formData, body)
  let scheme = call_603145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603145.url(scheme.get, call_603145.host, call_603145.base,
                         call_603145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603145, url, valid)

proc call*(call_603146: Call_PostSetIpAddressType_603131; LoadBalancerArn: string;
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
  var query_603147 = newJObject()
  var formData_603148 = newJObject()
  add(formData_603148, "IpAddressType", newJString(IpAddressType))
  add(query_603147, "Action", newJString(Action))
  add(query_603147, "Version", newJString(Version))
  add(formData_603148, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_603146.call(nil, query_603147, nil, formData_603148, nil)

var postSetIpAddressType* = Call_PostSetIpAddressType_603131(
    name: "postSetIpAddressType", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_PostSetIpAddressType_603132,
    base: "/", url: url_PostSetIpAddressType_603133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetIpAddressType_603114 = ref object of OpenApiRestCall_601389
proc url_GetSetIpAddressType_603116(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetIpAddressType_603115(path: JsonNode; query: JsonNode;
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
  var valid_603117 = query.getOrDefault("IpAddressType")
  valid_603117 = validateParameter(valid_603117, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_603117 != nil:
    section.add "IpAddressType", valid_603117
  var valid_603118 = query.getOrDefault("LoadBalancerArn")
  valid_603118 = validateParameter(valid_603118, JString, required = true,
                                 default = nil)
  if valid_603118 != nil:
    section.add "LoadBalancerArn", valid_603118
  var valid_603119 = query.getOrDefault("Action")
  valid_603119 = validateParameter(valid_603119, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_603119 != nil:
    section.add "Action", valid_603119
  var valid_603120 = query.getOrDefault("Version")
  valid_603120 = validateParameter(valid_603120, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603120 != nil:
    section.add "Version", valid_603120
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603121 = header.getOrDefault("X-Amz-Signature")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Signature", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Content-Sha256", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Date")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Date", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Credential")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Credential", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Security-Token")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Security-Token", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Algorithm")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Algorithm", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-SignedHeaders", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603128: Call_GetSetIpAddressType_603114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_603128.validator(path, query, header, formData, body)
  let scheme = call_603128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603128.url(scheme.get, call_603128.host, call_603128.base,
                         call_603128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603128, url, valid)

proc call*(call_603129: Call_GetSetIpAddressType_603114; LoadBalancerArn: string;
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
  var query_603130 = newJObject()
  add(query_603130, "IpAddressType", newJString(IpAddressType))
  add(query_603130, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603130, "Action", newJString(Action))
  add(query_603130, "Version", newJString(Version))
  result = call_603129.call(nil, query_603130, nil, nil, nil)

var getSetIpAddressType* = Call_GetSetIpAddressType_603114(
    name: "getSetIpAddressType", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_GetSetIpAddressType_603115,
    base: "/", url: url_GetSetIpAddressType_603116,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetRulePriorities_603165 = ref object of OpenApiRestCall_601389
proc url_PostSetRulePriorities_603167(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetRulePriorities_603166(path: JsonNode; query: JsonNode;
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
  var valid_603168 = query.getOrDefault("Action")
  valid_603168 = validateParameter(valid_603168, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_603168 != nil:
    section.add "Action", valid_603168
  var valid_603169 = query.getOrDefault("Version")
  valid_603169 = validateParameter(valid_603169, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603169 != nil:
    section.add "Version", valid_603169
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Content-Sha256", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Date")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Date", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Credential")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Credential", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Security-Token")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Security-Token", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Algorithm")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Algorithm", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-SignedHeaders", valid_603176
  result.add "header", section
  ## parameters in `formData` object:
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RulePriorities` field"
  var valid_603177 = formData.getOrDefault("RulePriorities")
  valid_603177 = validateParameter(valid_603177, JArray, required = true, default = nil)
  if valid_603177 != nil:
    section.add "RulePriorities", valid_603177
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603178: Call_PostSetRulePriorities_603165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_603178.validator(path, query, header, formData, body)
  let scheme = call_603178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603178.url(scheme.get, call_603178.host, call_603178.base,
                         call_603178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603178, url, valid)

proc call*(call_603179: Call_PostSetRulePriorities_603165;
          RulePriorities: JsonNode; Action: string = "SetRulePriorities";
          Version: string = "2015-12-01"): Recallable =
  ## postSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603180 = newJObject()
  var formData_603181 = newJObject()
  if RulePriorities != nil:
    formData_603181.add "RulePriorities", RulePriorities
  add(query_603180, "Action", newJString(Action))
  add(query_603180, "Version", newJString(Version))
  result = call_603179.call(nil, query_603180, nil, formData_603181, nil)

var postSetRulePriorities* = Call_PostSetRulePriorities_603165(
    name: "postSetRulePriorities", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities",
    validator: validate_PostSetRulePriorities_603166, base: "/",
    url: url_PostSetRulePriorities_603167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetRulePriorities_603149 = ref object of OpenApiRestCall_601389
proc url_GetSetRulePriorities_603151(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetRulePriorities_603150(path: JsonNode; query: JsonNode;
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
  var valid_603152 = query.getOrDefault("RulePriorities")
  valid_603152 = validateParameter(valid_603152, JArray, required = true, default = nil)
  if valid_603152 != nil:
    section.add "RulePriorities", valid_603152
  var valid_603153 = query.getOrDefault("Action")
  valid_603153 = validateParameter(valid_603153, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_603153 != nil:
    section.add "Action", valid_603153
  var valid_603154 = query.getOrDefault("Version")
  valid_603154 = validateParameter(valid_603154, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603154 != nil:
    section.add "Version", valid_603154
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Content-Sha256", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Date")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Date", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Credential")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Credential", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-Security-Token")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Security-Token", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-Algorithm")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Algorithm", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-SignedHeaders", valid_603161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603162: Call_GetSetRulePriorities_603149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_603162.validator(path, query, header, formData, body)
  let scheme = call_603162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603162.url(scheme.get, call_603162.host, call_603162.base,
                         call_603162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603162, url, valid)

proc call*(call_603163: Call_GetSetRulePriorities_603149; RulePriorities: JsonNode;
          Action: string = "SetRulePriorities"; Version: string = "2015-12-01"): Recallable =
  ## getSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603164 = newJObject()
  if RulePriorities != nil:
    query_603164.add "RulePriorities", RulePriorities
  add(query_603164, "Action", newJString(Action))
  add(query_603164, "Version", newJString(Version))
  result = call_603163.call(nil, query_603164, nil, nil, nil)

var getSetRulePriorities* = Call_GetSetRulePriorities_603149(
    name: "getSetRulePriorities", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities", validator: validate_GetSetRulePriorities_603150,
    base: "/", url: url_GetSetRulePriorities_603151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSecurityGroups_603199 = ref object of OpenApiRestCall_601389
proc url_PostSetSecurityGroups_603201(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetSecurityGroups_603200(path: JsonNode; query: JsonNode;
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
  var valid_603202 = query.getOrDefault("Action")
  valid_603202 = validateParameter(valid_603202, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_603202 != nil:
    section.add "Action", valid_603202
  var valid_603203 = query.getOrDefault("Version")
  valid_603203 = validateParameter(valid_603203, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603203 != nil:
    section.add "Version", valid_603203
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603204 = header.getOrDefault("X-Amz-Signature")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Signature", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Content-Sha256", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Date")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Date", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Credential")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Credential", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Security-Token")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Security-Token", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Algorithm")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Algorithm", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-SignedHeaders", valid_603210
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_603211 = formData.getOrDefault("SecurityGroups")
  valid_603211 = validateParameter(valid_603211, JArray, required = true, default = nil)
  if valid_603211 != nil:
    section.add "SecurityGroups", valid_603211
  var valid_603212 = formData.getOrDefault("LoadBalancerArn")
  valid_603212 = validateParameter(valid_603212, JString, required = true,
                                 default = nil)
  if valid_603212 != nil:
    section.add "LoadBalancerArn", valid_603212
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603213: Call_PostSetSecurityGroups_603199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_603213.validator(path, query, header, formData, body)
  let scheme = call_603213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603213.url(scheme.get, call_603213.host, call_603213.base,
                         call_603213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603213, url, valid)

proc call*(call_603214: Call_PostSetSecurityGroups_603199;
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
  var query_603215 = newJObject()
  var formData_603216 = newJObject()
  if SecurityGroups != nil:
    formData_603216.add "SecurityGroups", SecurityGroups
  add(query_603215, "Action", newJString(Action))
  add(query_603215, "Version", newJString(Version))
  add(formData_603216, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_603214.call(nil, query_603215, nil, formData_603216, nil)

var postSetSecurityGroups* = Call_PostSetSecurityGroups_603199(
    name: "postSetSecurityGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups",
    validator: validate_PostSetSecurityGroups_603200, base: "/",
    url: url_PostSetSecurityGroups_603201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSecurityGroups_603182 = ref object of OpenApiRestCall_601389
proc url_GetSetSecurityGroups_603184(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetSecurityGroups_603183(path: JsonNode; query: JsonNode;
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
  var valid_603185 = query.getOrDefault("LoadBalancerArn")
  valid_603185 = validateParameter(valid_603185, JString, required = true,
                                 default = nil)
  if valid_603185 != nil:
    section.add "LoadBalancerArn", valid_603185
  var valid_603186 = query.getOrDefault("SecurityGroups")
  valid_603186 = validateParameter(valid_603186, JArray, required = true, default = nil)
  if valid_603186 != nil:
    section.add "SecurityGroups", valid_603186
  var valid_603187 = query.getOrDefault("Action")
  valid_603187 = validateParameter(valid_603187, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_603187 != nil:
    section.add "Action", valid_603187
  var valid_603188 = query.getOrDefault("Version")
  valid_603188 = validateParameter(valid_603188, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603188 != nil:
    section.add "Version", valid_603188
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603189 = header.getOrDefault("X-Amz-Signature")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Signature", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Content-Sha256", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Date")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Date", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Credential")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Credential", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Security-Token")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Security-Token", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Algorithm")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Algorithm", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-SignedHeaders", valid_603195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603196: Call_GetSetSecurityGroups_603182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_603196.validator(path, query, header, formData, body)
  let scheme = call_603196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603196.url(scheme.get, call_603196.host, call_603196.base,
                         call_603196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603196, url, valid)

proc call*(call_603197: Call_GetSetSecurityGroups_603182; LoadBalancerArn: string;
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
  var query_603198 = newJObject()
  add(query_603198, "LoadBalancerArn", newJString(LoadBalancerArn))
  if SecurityGroups != nil:
    query_603198.add "SecurityGroups", SecurityGroups
  add(query_603198, "Action", newJString(Action))
  add(query_603198, "Version", newJString(Version))
  result = call_603197.call(nil, query_603198, nil, nil, nil)

var getSetSecurityGroups* = Call_GetSetSecurityGroups_603182(
    name: "getSetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups", validator: validate_GetSetSecurityGroups_603183,
    base: "/", url: url_GetSetSecurityGroups_603184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubnets_603235 = ref object of OpenApiRestCall_601389
proc url_PostSetSubnets_603237(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetSubnets_603236(path: JsonNode; query: JsonNode;
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
  var valid_603238 = query.getOrDefault("Action")
  valid_603238 = validateParameter(valid_603238, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_603238 != nil:
    section.add "Action", valid_603238
  var valid_603239 = query.getOrDefault("Version")
  valid_603239 = validateParameter(valid_603239, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603239 != nil:
    section.add "Version", valid_603239
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603240 = header.getOrDefault("X-Amz-Signature")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Signature", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Content-Sha256", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Date")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Date", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Credential")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Credential", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Security-Token")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Security-Token", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Algorithm")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Algorithm", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. If you need static IP addresses for your internet-facing load balancer, you can specify one Elastic IP address per subnet. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  var valid_603247 = formData.getOrDefault("Subnets")
  valid_603247 = validateParameter(valid_603247, JArray, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "Subnets", valid_603247
  var valid_603248 = formData.getOrDefault("SubnetMappings")
  valid_603248 = validateParameter(valid_603248, JArray, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "SubnetMappings", valid_603248
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_603249 = formData.getOrDefault("LoadBalancerArn")
  valid_603249 = validateParameter(valid_603249, JString, required = true,
                                 default = nil)
  if valid_603249 != nil:
    section.add "LoadBalancerArn", valid_603249
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603250: Call_PostSetSubnets_603235; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ## 
  let valid = call_603250.validator(path, query, header, formData, body)
  let scheme = call_603250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603250.url(scheme.get, call_603250.host, call_603250.base,
                         call_603250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603250, url, valid)

proc call*(call_603251: Call_PostSetSubnets_603235; LoadBalancerArn: string;
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
  var query_603252 = newJObject()
  var formData_603253 = newJObject()
  if Subnets != nil:
    formData_603253.add "Subnets", Subnets
  add(query_603252, "Action", newJString(Action))
  if SubnetMappings != nil:
    formData_603253.add "SubnetMappings", SubnetMappings
  add(query_603252, "Version", newJString(Version))
  add(formData_603253, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_603251.call(nil, query_603252, nil, formData_603253, nil)

var postSetSubnets* = Call_PostSetSubnets_603235(name: "postSetSubnets",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_PostSetSubnets_603236,
    base: "/", url: url_PostSetSubnets_603237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubnets_603217 = ref object of OpenApiRestCall_601389
proc url_GetSetSubnets_603219(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetSubnets_603218(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603220 = query.getOrDefault("SubnetMappings")
  valid_603220 = validateParameter(valid_603220, JArray, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "SubnetMappings", valid_603220
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_603221 = query.getOrDefault("LoadBalancerArn")
  valid_603221 = validateParameter(valid_603221, JString, required = true,
                                 default = nil)
  if valid_603221 != nil:
    section.add "LoadBalancerArn", valid_603221
  var valid_603222 = query.getOrDefault("Action")
  valid_603222 = validateParameter(valid_603222, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_603222 != nil:
    section.add "Action", valid_603222
  var valid_603223 = query.getOrDefault("Subnets")
  valid_603223 = validateParameter(valid_603223, JArray, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "Subnets", valid_603223
  var valid_603224 = query.getOrDefault("Version")
  valid_603224 = validateParameter(valid_603224, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603224 != nil:
    section.add "Version", valid_603224
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603225 = header.getOrDefault("X-Amz-Signature")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Signature", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Content-Sha256", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Date")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Date", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Credential")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Credential", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Security-Token")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Security-Token", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Algorithm")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Algorithm", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603232: Call_GetSetSubnets_603217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ## 
  let valid = call_603232.validator(path, query, header, formData, body)
  let scheme = call_603232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603232.url(scheme.get, call_603232.host, call_603232.base,
                         call_603232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603232, url, valid)

proc call*(call_603233: Call_GetSetSubnets_603217; LoadBalancerArn: string;
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
  var query_603234 = newJObject()
  if SubnetMappings != nil:
    query_603234.add "SubnetMappings", SubnetMappings
  add(query_603234, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603234, "Action", newJString(Action))
  if Subnets != nil:
    query_603234.add "Subnets", Subnets
  add(query_603234, "Version", newJString(Version))
  result = call_603233.call(nil, query_603234, nil, nil, nil)

var getSetSubnets* = Call_GetSetSubnets_603217(name: "getSetSubnets",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_GetSetSubnets_603218,
    base: "/", url: url_GetSetSubnets_603219, schemes: {Scheme.Https, Scheme.Http})
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
