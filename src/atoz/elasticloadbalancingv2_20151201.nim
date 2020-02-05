
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_PostAddListenerCertificates_613268 = ref object of OpenApiRestCall_612658
proc url_PostAddListenerCertificates_613270(protocol: Scheme; host: string;
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

proc validate_PostAddListenerCertificates_613269(path: JsonNode; query: JsonNode;
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
  var valid_613271 = query.getOrDefault("Action")
  valid_613271 = validateParameter(valid_613271, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_613271 != nil:
    section.add "Action", valid_613271
  var valid_613272 = query.getOrDefault("Version")
  valid_613272 = validateParameter(valid_613272, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613272 != nil:
    section.add "Version", valid_613272
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613273 = header.getOrDefault("X-Amz-Signature")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Signature", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Content-Sha256", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Date")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Date", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Credential")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Credential", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Security-Token")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Security-Token", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Algorithm")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Algorithm", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-SignedHeaders", valid_613279
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_613280 = formData.getOrDefault("Certificates")
  valid_613280 = validateParameter(valid_613280, JArray, required = true, default = nil)
  if valid_613280 != nil:
    section.add "Certificates", valid_613280
  var valid_613281 = formData.getOrDefault("ListenerArn")
  valid_613281 = validateParameter(valid_613281, JString, required = true,
                                 default = nil)
  if valid_613281 != nil:
    section.add "ListenerArn", valid_613281
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613282: Call_PostAddListenerCertificates_613268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613282.validator(path, query, header, formData, body)
  let scheme = call_613282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613282.url(scheme.get, call_613282.host, call_613282.base,
                         call_613282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613282, url, valid)

proc call*(call_613283: Call_PostAddListenerCertificates_613268;
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
  var query_613284 = newJObject()
  var formData_613285 = newJObject()
  if Certificates != nil:
    formData_613285.add "Certificates", Certificates
  add(formData_613285, "ListenerArn", newJString(ListenerArn))
  add(query_613284, "Action", newJString(Action))
  add(query_613284, "Version", newJString(Version))
  result = call_613283.call(nil, query_613284, nil, formData_613285, nil)

var postAddListenerCertificates* = Call_PostAddListenerCertificates_613268(
    name: "postAddListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_PostAddListenerCertificates_613269, base: "/",
    url: url_PostAddListenerCertificates_613270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddListenerCertificates_612996 = ref object of OpenApiRestCall_612658
proc url_GetAddListenerCertificates_612998(protocol: Scheme; host: string;
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

proc validate_GetAddListenerCertificates_612997(path: JsonNode; query: JsonNode;
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
  var valid_613110 = query.getOrDefault("ListenerArn")
  valid_613110 = validateParameter(valid_613110, JString, required = true,
                                 default = nil)
  if valid_613110 != nil:
    section.add "ListenerArn", valid_613110
  var valid_613111 = query.getOrDefault("Certificates")
  valid_613111 = validateParameter(valid_613111, JArray, required = true, default = nil)
  if valid_613111 != nil:
    section.add "Certificates", valid_613111
  var valid_613125 = query.getOrDefault("Action")
  valid_613125 = validateParameter(valid_613125, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_613125 != nil:
    section.add "Action", valid_613125
  var valid_613126 = query.getOrDefault("Version")
  valid_613126 = validateParameter(valid_613126, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613126 != nil:
    section.add "Version", valid_613126
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613127 = header.getOrDefault("X-Amz-Signature")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Signature", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Content-Sha256", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Date")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Date", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Credential")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Credential", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-Security-Token")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-Security-Token", valid_613131
  var valid_613132 = header.getOrDefault("X-Amz-Algorithm")
  valid_613132 = validateParameter(valid_613132, JString, required = false,
                                 default = nil)
  if valid_613132 != nil:
    section.add "X-Amz-Algorithm", valid_613132
  var valid_613133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613133 = validateParameter(valid_613133, JString, required = false,
                                 default = nil)
  if valid_613133 != nil:
    section.add "X-Amz-SignedHeaders", valid_613133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613156: Call_GetAddListenerCertificates_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613156.validator(path, query, header, formData, body)
  let scheme = call_613156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613156.url(scheme.get, call_613156.host, call_613156.base,
                         call_613156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613156, url, valid)

proc call*(call_613227: Call_GetAddListenerCertificates_612996;
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
  var query_613228 = newJObject()
  add(query_613228, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_613228.add "Certificates", Certificates
  add(query_613228, "Action", newJString(Action))
  add(query_613228, "Version", newJString(Version))
  result = call_613227.call(nil, query_613228, nil, nil, nil)

var getAddListenerCertificates* = Call_GetAddListenerCertificates_612996(
    name: "getAddListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_GetAddListenerCertificates_612997, base: "/",
    url: url_GetAddListenerCertificates_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTags_613303 = ref object of OpenApiRestCall_612658
proc url_PostAddTags_613305(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddTags_613304(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613306 = query.getOrDefault("Action")
  valid_613306 = validateParameter(valid_613306, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_613306 != nil:
    section.add "Action", valid_613306
  var valid_613307 = query.getOrDefault("Version")
  valid_613307 = validateParameter(valid_613307, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613307 != nil:
    section.add "Version", valid_613307
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613308 = header.getOrDefault("X-Amz-Signature")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Signature", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Content-Sha256", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Date")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Date", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Credential")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Credential", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Security-Token")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Security-Token", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Algorithm")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Algorithm", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-SignedHeaders", valid_613314
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_613315 = formData.getOrDefault("ResourceArns")
  valid_613315 = validateParameter(valid_613315, JArray, required = true, default = nil)
  if valid_613315 != nil:
    section.add "ResourceArns", valid_613315
  var valid_613316 = formData.getOrDefault("Tags")
  valid_613316 = validateParameter(valid_613316, JArray, required = true, default = nil)
  if valid_613316 != nil:
    section.add "Tags", valid_613316
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613317: Call_PostAddTags_613303; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_613317.validator(path, query, header, formData, body)
  let scheme = call_613317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613317.url(scheme.get, call_613317.host, call_613317.base,
                         call_613317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613317, url, valid)

proc call*(call_613318: Call_PostAddTags_613303; ResourceArns: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2015-12-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Version: string (required)
  var query_613319 = newJObject()
  var formData_613320 = newJObject()
  if ResourceArns != nil:
    formData_613320.add "ResourceArns", ResourceArns
  add(query_613319, "Action", newJString(Action))
  if Tags != nil:
    formData_613320.add "Tags", Tags
  add(query_613319, "Version", newJString(Version))
  result = call_613318.call(nil, query_613319, nil, formData_613320, nil)

var postAddTags* = Call_PostAddTags_613303(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_613304,
                                        base: "/", url: url_PostAddTags_613305,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_613286 = ref object of OpenApiRestCall_612658
proc url_GetAddTags_613288(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAddTags_613287(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613289 = query.getOrDefault("Tags")
  valid_613289 = validateParameter(valid_613289, JArray, required = true, default = nil)
  if valid_613289 != nil:
    section.add "Tags", valid_613289
  var valid_613290 = query.getOrDefault("ResourceArns")
  valid_613290 = validateParameter(valid_613290, JArray, required = true, default = nil)
  if valid_613290 != nil:
    section.add "ResourceArns", valid_613290
  var valid_613291 = query.getOrDefault("Action")
  valid_613291 = validateParameter(valid_613291, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_613291 != nil:
    section.add "Action", valid_613291
  var valid_613292 = query.getOrDefault("Version")
  valid_613292 = validateParameter(valid_613292, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613292 != nil:
    section.add "Version", valid_613292
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613293 = header.getOrDefault("X-Amz-Signature")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Signature", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Content-Sha256", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Date")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Date", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Credential")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Credential", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Security-Token")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Security-Token", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Algorithm")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Algorithm", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-SignedHeaders", valid_613299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613300: Call_GetAddTags_613286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_613300.validator(path, query, header, formData, body)
  let scheme = call_613300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613300.url(scheme.get, call_613300.host, call_613300.base,
                         call_613300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613300, url, valid)

proc call*(call_613301: Call_GetAddTags_613286; Tags: JsonNode;
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
  var query_613302 = newJObject()
  if Tags != nil:
    query_613302.add "Tags", Tags
  if ResourceArns != nil:
    query_613302.add "ResourceArns", ResourceArns
  add(query_613302, "Action", newJString(Action))
  add(query_613302, "Version", newJString(Version))
  result = call_613301.call(nil, query_613302, nil, nil, nil)

var getAddTags* = Call_GetAddTags_613286(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_613287,
                                      base: "/", url: url_GetAddTags_613288,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateListener_613342 = ref object of OpenApiRestCall_612658
proc url_PostCreateListener_613344(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateListener_613343(path: JsonNode; query: JsonNode;
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
  var valid_613345 = query.getOrDefault("Action")
  valid_613345 = validateParameter(valid_613345, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_613345 != nil:
    section.add "Action", valid_613345
  var valid_613346 = query.getOrDefault("Version")
  valid_613346 = validateParameter(valid_613346, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613346 != nil:
    section.add "Version", valid_613346
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613347 = header.getOrDefault("X-Amz-Signature")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Signature", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Content-Sha256", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Date")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Date", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-Credential")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Credential", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Security-Token")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Security-Token", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-Algorithm")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Algorithm", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-SignedHeaders", valid_613353
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
  var valid_613354 = formData.getOrDefault("Port")
  valid_613354 = validateParameter(valid_613354, JInt, required = true, default = nil)
  if valid_613354 != nil:
    section.add "Port", valid_613354
  var valid_613355 = formData.getOrDefault("Certificates")
  valid_613355 = validateParameter(valid_613355, JArray, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "Certificates", valid_613355
  var valid_613356 = formData.getOrDefault("DefaultActions")
  valid_613356 = validateParameter(valid_613356, JArray, required = true, default = nil)
  if valid_613356 != nil:
    section.add "DefaultActions", valid_613356
  var valid_613357 = formData.getOrDefault("Protocol")
  valid_613357 = validateParameter(valid_613357, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_613357 != nil:
    section.add "Protocol", valid_613357
  var valid_613358 = formData.getOrDefault("SslPolicy")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "SslPolicy", valid_613358
  var valid_613359 = formData.getOrDefault("LoadBalancerArn")
  valid_613359 = validateParameter(valid_613359, JString, required = true,
                                 default = nil)
  if valid_613359 != nil:
    section.add "LoadBalancerArn", valid_613359
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613360: Call_PostCreateListener_613342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613360.validator(path, query, header, formData, body)
  let scheme = call_613360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613360.url(scheme.get, call_613360.host, call_613360.base,
                         call_613360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613360, url, valid)

proc call*(call_613361: Call_PostCreateListener_613342; Port: int;
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
  var query_613362 = newJObject()
  var formData_613363 = newJObject()
  add(formData_613363, "Port", newJInt(Port))
  if Certificates != nil:
    formData_613363.add "Certificates", Certificates
  if DefaultActions != nil:
    formData_613363.add "DefaultActions", DefaultActions
  add(formData_613363, "Protocol", newJString(Protocol))
  add(query_613362, "Action", newJString(Action))
  add(formData_613363, "SslPolicy", newJString(SslPolicy))
  add(query_613362, "Version", newJString(Version))
  add(formData_613363, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_613361.call(nil, query_613362, nil, formData_613363, nil)

var postCreateListener* = Call_PostCreateListener_613342(
    name: "postCreateListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=CreateListener",
    validator: validate_PostCreateListener_613343, base: "/",
    url: url_PostCreateListener_613344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateListener_613321 = ref object of OpenApiRestCall_612658
proc url_GetCreateListener_613323(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateListener_613322(path: JsonNode; query: JsonNode;
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
  var valid_613324 = query.getOrDefault("SslPolicy")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "SslPolicy", valid_613324
  var valid_613325 = query.getOrDefault("Certificates")
  valid_613325 = validateParameter(valid_613325, JArray, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "Certificates", valid_613325
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_613326 = query.getOrDefault("LoadBalancerArn")
  valid_613326 = validateParameter(valid_613326, JString, required = true,
                                 default = nil)
  if valid_613326 != nil:
    section.add "LoadBalancerArn", valid_613326
  var valid_613327 = query.getOrDefault("DefaultActions")
  valid_613327 = validateParameter(valid_613327, JArray, required = true, default = nil)
  if valid_613327 != nil:
    section.add "DefaultActions", valid_613327
  var valid_613328 = query.getOrDefault("Action")
  valid_613328 = validateParameter(valid_613328, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_613328 != nil:
    section.add "Action", valid_613328
  var valid_613329 = query.getOrDefault("Protocol")
  valid_613329 = validateParameter(valid_613329, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_613329 != nil:
    section.add "Protocol", valid_613329
  var valid_613330 = query.getOrDefault("Port")
  valid_613330 = validateParameter(valid_613330, JInt, required = true, default = nil)
  if valid_613330 != nil:
    section.add "Port", valid_613330
  var valid_613331 = query.getOrDefault("Version")
  valid_613331 = validateParameter(valid_613331, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613331 != nil:
    section.add "Version", valid_613331
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613332 = header.getOrDefault("X-Amz-Signature")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Signature", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Content-Sha256", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Date")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Date", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Credential")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Credential", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-Security-Token")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Security-Token", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-Algorithm")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Algorithm", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-SignedHeaders", valid_613338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613339: Call_GetCreateListener_613321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613339.validator(path, query, header, formData, body)
  let scheme = call_613339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613339.url(scheme.get, call_613339.host, call_613339.base,
                         call_613339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613339, url, valid)

proc call*(call_613340: Call_GetCreateListener_613321; LoadBalancerArn: string;
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
  var query_613341 = newJObject()
  add(query_613341, "SslPolicy", newJString(SslPolicy))
  if Certificates != nil:
    query_613341.add "Certificates", Certificates
  add(query_613341, "LoadBalancerArn", newJString(LoadBalancerArn))
  if DefaultActions != nil:
    query_613341.add "DefaultActions", DefaultActions
  add(query_613341, "Action", newJString(Action))
  add(query_613341, "Protocol", newJString(Protocol))
  add(query_613341, "Port", newJInt(Port))
  add(query_613341, "Version", newJString(Version))
  result = call_613340.call(nil, query_613341, nil, nil, nil)

var getCreateListener* = Call_GetCreateListener_613321(name: "getCreateListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateListener", validator: validate_GetCreateListener_613322,
    base: "/", url: url_GetCreateListener_613323,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_613387 = ref object of OpenApiRestCall_612658
proc url_PostCreateLoadBalancer_613389(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateLoadBalancer_613388(path: JsonNode; query: JsonNode;
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
  var valid_613390 = query.getOrDefault("Action")
  valid_613390 = validateParameter(valid_613390, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_613390 != nil:
    section.add "Action", valid_613390
  var valid_613391 = query.getOrDefault("Version")
  valid_613391 = validateParameter(valid_613391, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613391 != nil:
    section.add "Version", valid_613391
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613392 = header.getOrDefault("X-Amz-Signature")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Signature", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Content-Sha256", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Date")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Date", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Credential")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Credential", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-Security-Token")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Security-Token", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-Algorithm")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-Algorithm", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-SignedHeaders", valid_613398
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
  var valid_613399 = formData.getOrDefault("IpAddressType")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_613399 != nil:
    section.add "IpAddressType", valid_613399
  var valid_613400 = formData.getOrDefault("Scheme")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_613400 != nil:
    section.add "Scheme", valid_613400
  var valid_613401 = formData.getOrDefault("SecurityGroups")
  valid_613401 = validateParameter(valid_613401, JArray, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "SecurityGroups", valid_613401
  var valid_613402 = formData.getOrDefault("Subnets")
  valid_613402 = validateParameter(valid_613402, JArray, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "Subnets", valid_613402
  var valid_613403 = formData.getOrDefault("Type")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = newJString("application"))
  if valid_613403 != nil:
    section.add "Type", valid_613403
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_613404 = formData.getOrDefault("Name")
  valid_613404 = validateParameter(valid_613404, JString, required = true,
                                 default = nil)
  if valid_613404 != nil:
    section.add "Name", valid_613404
  var valid_613405 = formData.getOrDefault("Tags")
  valid_613405 = validateParameter(valid_613405, JArray, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "Tags", valid_613405
  var valid_613406 = formData.getOrDefault("SubnetMappings")
  valid_613406 = validateParameter(valid_613406, JArray, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "SubnetMappings", valid_613406
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613407: Call_PostCreateLoadBalancer_613387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613407.validator(path, query, header, formData, body)
  let scheme = call_613407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613407.url(scheme.get, call_613407.host, call_613407.base,
                         call_613407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613407, url, valid)

proc call*(call_613408: Call_PostCreateLoadBalancer_613387; Name: string;
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
  var query_613409 = newJObject()
  var formData_613410 = newJObject()
  add(formData_613410, "IpAddressType", newJString(IpAddressType))
  add(formData_613410, "Scheme", newJString(Scheme))
  if SecurityGroups != nil:
    formData_613410.add "SecurityGroups", SecurityGroups
  if Subnets != nil:
    formData_613410.add "Subnets", Subnets
  add(formData_613410, "Type", newJString(Type))
  add(query_613409, "Action", newJString(Action))
  add(formData_613410, "Name", newJString(Name))
  if Tags != nil:
    formData_613410.add "Tags", Tags
  if SubnetMappings != nil:
    formData_613410.add "SubnetMappings", SubnetMappings
  add(query_613409, "Version", newJString(Version))
  result = call_613408.call(nil, query_613409, nil, formData_613410, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_613387(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_613388, base: "/",
    url: url_PostCreateLoadBalancer_613389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_613364 = ref object of OpenApiRestCall_612658
proc url_GetCreateLoadBalancer_613366(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateLoadBalancer_613365(path: JsonNode; query: JsonNode;
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
  var valid_613367 = query.getOrDefault("SubnetMappings")
  valid_613367 = validateParameter(valid_613367, JArray, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "SubnetMappings", valid_613367
  var valid_613368 = query.getOrDefault("Type")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = newJString("application"))
  if valid_613368 != nil:
    section.add "Type", valid_613368
  var valid_613369 = query.getOrDefault("Tags")
  valid_613369 = validateParameter(valid_613369, JArray, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "Tags", valid_613369
  var valid_613370 = query.getOrDefault("Scheme")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_613370 != nil:
    section.add "Scheme", valid_613370
  var valid_613371 = query.getOrDefault("IpAddressType")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_613371 != nil:
    section.add "IpAddressType", valid_613371
  var valid_613372 = query.getOrDefault("SecurityGroups")
  valid_613372 = validateParameter(valid_613372, JArray, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "SecurityGroups", valid_613372
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_613373 = query.getOrDefault("Name")
  valid_613373 = validateParameter(valid_613373, JString, required = true,
                                 default = nil)
  if valid_613373 != nil:
    section.add "Name", valid_613373
  var valid_613374 = query.getOrDefault("Action")
  valid_613374 = validateParameter(valid_613374, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_613374 != nil:
    section.add "Action", valid_613374
  var valid_613375 = query.getOrDefault("Subnets")
  valid_613375 = validateParameter(valid_613375, JArray, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "Subnets", valid_613375
  var valid_613376 = query.getOrDefault("Version")
  valid_613376 = validateParameter(valid_613376, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613376 != nil:
    section.add "Version", valid_613376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613377 = header.getOrDefault("X-Amz-Signature")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Signature", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Content-Sha256", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Date")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Date", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Credential")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Credential", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Security-Token")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Security-Token", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Algorithm")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Algorithm", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-SignedHeaders", valid_613383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613384: Call_GetCreateLoadBalancer_613364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613384.validator(path, query, header, formData, body)
  let scheme = call_613384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613384.url(scheme.get, call_613384.host, call_613384.base,
                         call_613384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613384, url, valid)

proc call*(call_613385: Call_GetCreateLoadBalancer_613364; Name: string;
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
  var query_613386 = newJObject()
  if SubnetMappings != nil:
    query_613386.add "SubnetMappings", SubnetMappings
  add(query_613386, "Type", newJString(Type))
  if Tags != nil:
    query_613386.add "Tags", Tags
  add(query_613386, "Scheme", newJString(Scheme))
  add(query_613386, "IpAddressType", newJString(IpAddressType))
  if SecurityGroups != nil:
    query_613386.add "SecurityGroups", SecurityGroups
  add(query_613386, "Name", newJString(Name))
  add(query_613386, "Action", newJString(Action))
  if Subnets != nil:
    query_613386.add "Subnets", Subnets
  add(query_613386, "Version", newJString(Version))
  result = call_613385.call(nil, query_613386, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_613364(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_613365, base: "/",
    url: url_GetCreateLoadBalancer_613366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateRule_613430 = ref object of OpenApiRestCall_612658
proc url_PostCreateRule_613432(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateRule_613431(path: JsonNode; query: JsonNode;
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
  var valid_613433 = query.getOrDefault("Action")
  valid_613433 = validateParameter(valid_613433, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_613433 != nil:
    section.add "Action", valid_613433
  var valid_613434 = query.getOrDefault("Version")
  valid_613434 = validateParameter(valid_613434, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613434 != nil:
    section.add "Version", valid_613434
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613435 = header.getOrDefault("X-Amz-Signature")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Signature", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Content-Sha256", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Date")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Date", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Credential")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Credential", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Security-Token")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Security-Token", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-Algorithm")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-Algorithm", valid_613440
  var valid_613441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-SignedHeaders", valid_613441
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
  var valid_613442 = formData.getOrDefault("Actions")
  valid_613442 = validateParameter(valid_613442, JArray, required = true, default = nil)
  if valid_613442 != nil:
    section.add "Actions", valid_613442
  var valid_613443 = formData.getOrDefault("Conditions")
  valid_613443 = validateParameter(valid_613443, JArray, required = true, default = nil)
  if valid_613443 != nil:
    section.add "Conditions", valid_613443
  var valid_613444 = formData.getOrDefault("ListenerArn")
  valid_613444 = validateParameter(valid_613444, JString, required = true,
                                 default = nil)
  if valid_613444 != nil:
    section.add "ListenerArn", valid_613444
  var valid_613445 = formData.getOrDefault("Priority")
  valid_613445 = validateParameter(valid_613445, JInt, required = true, default = nil)
  if valid_613445 != nil:
    section.add "Priority", valid_613445
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613446: Call_PostCreateRule_613430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_613446.validator(path, query, header, formData, body)
  let scheme = call_613446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613446.url(scheme.get, call_613446.host, call_613446.base,
                         call_613446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613446, url, valid)

proc call*(call_613447: Call_PostCreateRule_613430; Actions: JsonNode;
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
  var query_613448 = newJObject()
  var formData_613449 = newJObject()
  if Actions != nil:
    formData_613449.add "Actions", Actions
  if Conditions != nil:
    formData_613449.add "Conditions", Conditions
  add(formData_613449, "ListenerArn", newJString(ListenerArn))
  add(formData_613449, "Priority", newJInt(Priority))
  add(query_613448, "Action", newJString(Action))
  add(query_613448, "Version", newJString(Version))
  result = call_613447.call(nil, query_613448, nil, formData_613449, nil)

var postCreateRule* = Call_PostCreateRule_613430(name: "postCreateRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_PostCreateRule_613431,
    base: "/", url: url_PostCreateRule_613432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateRule_613411 = ref object of OpenApiRestCall_612658
proc url_GetCreateRule_613413(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateRule_613412(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613414 = query.getOrDefault("Actions")
  valid_613414 = validateParameter(valid_613414, JArray, required = true, default = nil)
  if valid_613414 != nil:
    section.add "Actions", valid_613414
  var valid_613415 = query.getOrDefault("ListenerArn")
  valid_613415 = validateParameter(valid_613415, JString, required = true,
                                 default = nil)
  if valid_613415 != nil:
    section.add "ListenerArn", valid_613415
  var valid_613416 = query.getOrDefault("Priority")
  valid_613416 = validateParameter(valid_613416, JInt, required = true, default = nil)
  if valid_613416 != nil:
    section.add "Priority", valid_613416
  var valid_613417 = query.getOrDefault("Action")
  valid_613417 = validateParameter(valid_613417, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_613417 != nil:
    section.add "Action", valid_613417
  var valid_613418 = query.getOrDefault("Version")
  valid_613418 = validateParameter(valid_613418, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613418 != nil:
    section.add "Version", valid_613418
  var valid_613419 = query.getOrDefault("Conditions")
  valid_613419 = validateParameter(valid_613419, JArray, required = true, default = nil)
  if valid_613419 != nil:
    section.add "Conditions", valid_613419
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613420 = header.getOrDefault("X-Amz-Signature")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Signature", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Content-Sha256", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Date")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Date", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Credential")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Credential", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Security-Token")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Security-Token", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-Algorithm")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Algorithm", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-SignedHeaders", valid_613426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613427: Call_GetCreateRule_613411; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_GetCreateRule_613411; Actions: JsonNode;
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
  var query_613429 = newJObject()
  if Actions != nil:
    query_613429.add "Actions", Actions
  add(query_613429, "ListenerArn", newJString(ListenerArn))
  add(query_613429, "Priority", newJInt(Priority))
  add(query_613429, "Action", newJString(Action))
  add(query_613429, "Version", newJString(Version))
  if Conditions != nil:
    query_613429.add "Conditions", Conditions
  result = call_613428.call(nil, query_613429, nil, nil, nil)

var getCreateRule* = Call_GetCreateRule_613411(name: "getCreateRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_GetCreateRule_613412,
    base: "/", url: url_GetCreateRule_613413, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTargetGroup_613479 = ref object of OpenApiRestCall_612658
proc url_PostCreateTargetGroup_613481(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateTargetGroup_613480(path: JsonNode; query: JsonNode;
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
  var valid_613482 = query.getOrDefault("Action")
  valid_613482 = validateParameter(valid_613482, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_613482 != nil:
    section.add "Action", valid_613482
  var valid_613483 = query.getOrDefault("Version")
  valid_613483 = validateParameter(valid_613483, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613483 != nil:
    section.add "Version", valid_613483
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613484 = header.getOrDefault("X-Amz-Signature")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Signature", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Content-Sha256", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Date")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Date", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-Credential")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Credential", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-Security-Token")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-Security-Token", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-Algorithm")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Algorithm", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-SignedHeaders", valid_613490
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
  var valid_613491 = formData.getOrDefault("HealthCheckProtocol")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_613491 != nil:
    section.add "HealthCheckProtocol", valid_613491
  var valid_613492 = formData.getOrDefault("Port")
  valid_613492 = validateParameter(valid_613492, JInt, required = false, default = nil)
  if valid_613492 != nil:
    section.add "Port", valid_613492
  var valid_613493 = formData.getOrDefault("HealthCheckPort")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "HealthCheckPort", valid_613493
  var valid_613494 = formData.getOrDefault("VpcId")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "VpcId", valid_613494
  var valid_613495 = formData.getOrDefault("HealthCheckEnabled")
  valid_613495 = validateParameter(valid_613495, JBool, required = false, default = nil)
  if valid_613495 != nil:
    section.add "HealthCheckEnabled", valid_613495
  var valid_613496 = formData.getOrDefault("HealthCheckPath")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "HealthCheckPath", valid_613496
  var valid_613497 = formData.getOrDefault("TargetType")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = newJString("instance"))
  if valid_613497 != nil:
    section.add "TargetType", valid_613497
  var valid_613498 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_613498 = validateParameter(valid_613498, JInt, required = false, default = nil)
  if valid_613498 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_613498
  var valid_613499 = formData.getOrDefault("HealthyThresholdCount")
  valid_613499 = validateParameter(valid_613499, JInt, required = false, default = nil)
  if valid_613499 != nil:
    section.add "HealthyThresholdCount", valid_613499
  var valid_613500 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_613500 = validateParameter(valid_613500, JInt, required = false, default = nil)
  if valid_613500 != nil:
    section.add "HealthCheckIntervalSeconds", valid_613500
  var valid_613501 = formData.getOrDefault("Protocol")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_613501 != nil:
    section.add "Protocol", valid_613501
  var valid_613502 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_613502 = validateParameter(valid_613502, JInt, required = false, default = nil)
  if valid_613502 != nil:
    section.add "UnhealthyThresholdCount", valid_613502
  var valid_613503 = formData.getOrDefault("Matcher.HttpCode")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "Matcher.HttpCode", valid_613503
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_613504 = formData.getOrDefault("Name")
  valid_613504 = validateParameter(valid_613504, JString, required = true,
                                 default = nil)
  if valid_613504 != nil:
    section.add "Name", valid_613504
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613505: Call_PostCreateTargetGroup_613479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613505.validator(path, query, header, formData, body)
  let scheme = call_613505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613505.url(scheme.get, call_613505.host, call_613505.base,
                         call_613505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613505, url, valid)

proc call*(call_613506: Call_PostCreateTargetGroup_613479; Name: string;
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
  var query_613507 = newJObject()
  var formData_613508 = newJObject()
  add(formData_613508, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_613508, "Port", newJInt(Port))
  add(formData_613508, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_613508, "VpcId", newJString(VpcId))
  add(formData_613508, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_613508, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_613508, "TargetType", newJString(TargetType))
  add(formData_613508, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_613508, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_613508, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_613508, "Protocol", newJString(Protocol))
  add(formData_613508, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_613508, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_613507, "Action", newJString(Action))
  add(formData_613508, "Name", newJString(Name))
  add(query_613507, "Version", newJString(Version))
  result = call_613506.call(nil, query_613507, nil, formData_613508, nil)

var postCreateTargetGroup* = Call_PostCreateTargetGroup_613479(
    name: "postCreateTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup",
    validator: validate_PostCreateTargetGroup_613480, base: "/",
    url: url_PostCreateTargetGroup_613481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTargetGroup_613450 = ref object of OpenApiRestCall_612658
proc url_GetCreateTargetGroup_613452(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateTargetGroup_613451(path: JsonNode; query: JsonNode;
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
  var valid_613453 = query.getOrDefault("HealthCheckPort")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "HealthCheckPort", valid_613453
  var valid_613454 = query.getOrDefault("TargetType")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = newJString("instance"))
  if valid_613454 != nil:
    section.add "TargetType", valid_613454
  var valid_613455 = query.getOrDefault("HealthCheckPath")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "HealthCheckPath", valid_613455
  var valid_613456 = query.getOrDefault("VpcId")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "VpcId", valid_613456
  var valid_613457 = query.getOrDefault("HealthCheckProtocol")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_613457 != nil:
    section.add "HealthCheckProtocol", valid_613457
  var valid_613458 = query.getOrDefault("Matcher.HttpCode")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "Matcher.HttpCode", valid_613458
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_613459 = query.getOrDefault("Name")
  valid_613459 = validateParameter(valid_613459, JString, required = true,
                                 default = nil)
  if valid_613459 != nil:
    section.add "Name", valid_613459
  var valid_613460 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_613460 = validateParameter(valid_613460, JInt, required = false, default = nil)
  if valid_613460 != nil:
    section.add "HealthCheckIntervalSeconds", valid_613460
  var valid_613461 = query.getOrDefault("HealthCheckEnabled")
  valid_613461 = validateParameter(valid_613461, JBool, required = false, default = nil)
  if valid_613461 != nil:
    section.add "HealthCheckEnabled", valid_613461
  var valid_613462 = query.getOrDefault("HealthyThresholdCount")
  valid_613462 = validateParameter(valid_613462, JInt, required = false, default = nil)
  if valid_613462 != nil:
    section.add "HealthyThresholdCount", valid_613462
  var valid_613463 = query.getOrDefault("UnhealthyThresholdCount")
  valid_613463 = validateParameter(valid_613463, JInt, required = false, default = nil)
  if valid_613463 != nil:
    section.add "UnhealthyThresholdCount", valid_613463
  var valid_613464 = query.getOrDefault("Action")
  valid_613464 = validateParameter(valid_613464, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_613464 != nil:
    section.add "Action", valid_613464
  var valid_613465 = query.getOrDefault("Protocol")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_613465 != nil:
    section.add "Protocol", valid_613465
  var valid_613466 = query.getOrDefault("Port")
  valid_613466 = validateParameter(valid_613466, JInt, required = false, default = nil)
  if valid_613466 != nil:
    section.add "Port", valid_613466
  var valid_613467 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_613467 = validateParameter(valid_613467, JInt, required = false, default = nil)
  if valid_613467 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_613467
  var valid_613468 = query.getOrDefault("Version")
  valid_613468 = validateParameter(valid_613468, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613468 != nil:
    section.add "Version", valid_613468
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613469 = header.getOrDefault("X-Amz-Signature")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Signature", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Content-Sha256", valid_613470
  var valid_613471 = header.getOrDefault("X-Amz-Date")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-Date", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-Credential")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-Credential", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-Security-Token")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Security-Token", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-Algorithm")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Algorithm", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-SignedHeaders", valid_613475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613476: Call_GetCreateTargetGroup_613450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613476.validator(path, query, header, formData, body)
  let scheme = call_613476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613476.url(scheme.get, call_613476.host, call_613476.base,
                         call_613476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613476, url, valid)

proc call*(call_613477: Call_GetCreateTargetGroup_613450; Name: string;
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
  var query_613478 = newJObject()
  add(query_613478, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_613478, "TargetType", newJString(TargetType))
  add(query_613478, "HealthCheckPath", newJString(HealthCheckPath))
  add(query_613478, "VpcId", newJString(VpcId))
  add(query_613478, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_613478, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_613478, "Name", newJString(Name))
  add(query_613478, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_613478, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_613478, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_613478, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_613478, "Action", newJString(Action))
  add(query_613478, "Protocol", newJString(Protocol))
  add(query_613478, "Port", newJInt(Port))
  add(query_613478, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_613478, "Version", newJString(Version))
  result = call_613477.call(nil, query_613478, nil, nil, nil)

var getCreateTargetGroup* = Call_GetCreateTargetGroup_613450(
    name: "getCreateTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup", validator: validate_GetCreateTargetGroup_613451,
    base: "/", url: url_GetCreateTargetGroup_613452,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteListener_613525 = ref object of OpenApiRestCall_612658
proc url_PostDeleteListener_613527(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteListener_613526(path: JsonNode; query: JsonNode;
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
  var valid_613528 = query.getOrDefault("Action")
  valid_613528 = validateParameter(valid_613528, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_613528 != nil:
    section.add "Action", valid_613528
  var valid_613529 = query.getOrDefault("Version")
  valid_613529 = validateParameter(valid_613529, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613529 != nil:
    section.add "Version", valid_613529
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613530 = header.getOrDefault("X-Amz-Signature")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Signature", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Content-Sha256", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-Date")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Date", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-Credential")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Credential", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-Security-Token")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-Security-Token", valid_613534
  var valid_613535 = header.getOrDefault("X-Amz-Algorithm")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "X-Amz-Algorithm", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-SignedHeaders", valid_613536
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_613537 = formData.getOrDefault("ListenerArn")
  valid_613537 = validateParameter(valid_613537, JString, required = true,
                                 default = nil)
  if valid_613537 != nil:
    section.add "ListenerArn", valid_613537
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613538: Call_PostDeleteListener_613525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_613538.validator(path, query, header, formData, body)
  let scheme = call_613538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613538.url(scheme.get, call_613538.host, call_613538.base,
                         call_613538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613538, url, valid)

proc call*(call_613539: Call_PostDeleteListener_613525; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613540 = newJObject()
  var formData_613541 = newJObject()
  add(formData_613541, "ListenerArn", newJString(ListenerArn))
  add(query_613540, "Action", newJString(Action))
  add(query_613540, "Version", newJString(Version))
  result = call_613539.call(nil, query_613540, nil, formData_613541, nil)

var postDeleteListener* = Call_PostDeleteListener_613525(
    name: "postDeleteListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=DeleteListener",
    validator: validate_PostDeleteListener_613526, base: "/",
    url: url_PostDeleteListener_613527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteListener_613509 = ref object of OpenApiRestCall_612658
proc url_GetDeleteListener_613511(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteListener_613510(path: JsonNode; query: JsonNode;
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
  var valid_613512 = query.getOrDefault("ListenerArn")
  valid_613512 = validateParameter(valid_613512, JString, required = true,
                                 default = nil)
  if valid_613512 != nil:
    section.add "ListenerArn", valid_613512
  var valid_613513 = query.getOrDefault("Action")
  valid_613513 = validateParameter(valid_613513, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_613513 != nil:
    section.add "Action", valid_613513
  var valid_613514 = query.getOrDefault("Version")
  valid_613514 = validateParameter(valid_613514, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613514 != nil:
    section.add "Version", valid_613514
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613515 = header.getOrDefault("X-Amz-Signature")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Signature", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Content-Sha256", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Date")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Date", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Credential")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Credential", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Security-Token")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Security-Token", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Algorithm")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Algorithm", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-SignedHeaders", valid_613521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613522: Call_GetDeleteListener_613509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_613522.validator(path, query, header, formData, body)
  let scheme = call_613522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613522.url(scheme.get, call_613522.host, call_613522.base,
                         call_613522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613522, url, valid)

proc call*(call_613523: Call_GetDeleteListener_613509; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613524 = newJObject()
  add(query_613524, "ListenerArn", newJString(ListenerArn))
  add(query_613524, "Action", newJString(Action))
  add(query_613524, "Version", newJString(Version))
  result = call_613523.call(nil, query_613524, nil, nil, nil)

var getDeleteListener* = Call_GetDeleteListener_613509(name: "getDeleteListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteListener", validator: validate_GetDeleteListener_613510,
    base: "/", url: url_GetDeleteListener_613511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_613558 = ref object of OpenApiRestCall_612658
proc url_PostDeleteLoadBalancer_613560(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteLoadBalancer_613559(path: JsonNode; query: JsonNode;
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
  var valid_613561 = query.getOrDefault("Action")
  valid_613561 = validateParameter(valid_613561, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_613561 != nil:
    section.add "Action", valid_613561
  var valid_613562 = query.getOrDefault("Version")
  valid_613562 = validateParameter(valid_613562, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613562 != nil:
    section.add "Version", valid_613562
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613563 = header.getOrDefault("X-Amz-Signature")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Signature", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-Content-Sha256", valid_613564
  var valid_613565 = header.getOrDefault("X-Amz-Date")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-Date", valid_613565
  var valid_613566 = header.getOrDefault("X-Amz-Credential")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Credential", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-Security-Token")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Security-Token", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-Algorithm")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Algorithm", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-SignedHeaders", valid_613569
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_613570 = formData.getOrDefault("LoadBalancerArn")
  valid_613570 = validateParameter(valid_613570, JString, required = true,
                                 default = nil)
  if valid_613570 != nil:
    section.add "LoadBalancerArn", valid_613570
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613571: Call_PostDeleteLoadBalancer_613558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_613571.validator(path, query, header, formData, body)
  let scheme = call_613571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613571.url(scheme.get, call_613571.host, call_613571.base,
                         call_613571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613571, url, valid)

proc call*(call_613572: Call_PostDeleteLoadBalancer_613558;
          LoadBalancerArn: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2015-12-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_613573 = newJObject()
  var formData_613574 = newJObject()
  add(query_613573, "Action", newJString(Action))
  add(query_613573, "Version", newJString(Version))
  add(formData_613574, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_613572.call(nil, query_613573, nil, formData_613574, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_613558(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_613559, base: "/",
    url: url_PostDeleteLoadBalancer_613560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_613542 = ref object of OpenApiRestCall_612658
proc url_GetDeleteLoadBalancer_613544(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteLoadBalancer_613543(path: JsonNode; query: JsonNode;
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
  var valid_613545 = query.getOrDefault("LoadBalancerArn")
  valid_613545 = validateParameter(valid_613545, JString, required = true,
                                 default = nil)
  if valid_613545 != nil:
    section.add "LoadBalancerArn", valid_613545
  var valid_613546 = query.getOrDefault("Action")
  valid_613546 = validateParameter(valid_613546, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_613546 != nil:
    section.add "Action", valid_613546
  var valid_613547 = query.getOrDefault("Version")
  valid_613547 = validateParameter(valid_613547, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613547 != nil:
    section.add "Version", valid_613547
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613548 = header.getOrDefault("X-Amz-Signature")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Signature", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-Content-Sha256", valid_613549
  var valid_613550 = header.getOrDefault("X-Amz-Date")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-Date", valid_613550
  var valid_613551 = header.getOrDefault("X-Amz-Credential")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "X-Amz-Credential", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-Security-Token")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Security-Token", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Algorithm")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Algorithm", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-SignedHeaders", valid_613554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613555: Call_GetDeleteLoadBalancer_613542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_613555.validator(path, query, header, formData, body)
  let scheme = call_613555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613555.url(scheme.get, call_613555.host, call_613555.base,
                         call_613555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613555, url, valid)

proc call*(call_613556: Call_GetDeleteLoadBalancer_613542; LoadBalancerArn: string;
          Action: string = "DeleteLoadBalancer"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613557 = newJObject()
  add(query_613557, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_613557, "Action", newJString(Action))
  add(query_613557, "Version", newJString(Version))
  result = call_613556.call(nil, query_613557, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_613542(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_613543, base: "/",
    url: url_GetDeleteLoadBalancer_613544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRule_613591 = ref object of OpenApiRestCall_612658
proc url_PostDeleteRule_613593(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteRule_613592(path: JsonNode; query: JsonNode;
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
  var valid_613594 = query.getOrDefault("Action")
  valid_613594 = validateParameter(valid_613594, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_613594 != nil:
    section.add "Action", valid_613594
  var valid_613595 = query.getOrDefault("Version")
  valid_613595 = validateParameter(valid_613595, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613595 != nil:
    section.add "Version", valid_613595
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613596 = header.getOrDefault("X-Amz-Signature")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-Signature", valid_613596
  var valid_613597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "X-Amz-Content-Sha256", valid_613597
  var valid_613598 = header.getOrDefault("X-Amz-Date")
  valid_613598 = validateParameter(valid_613598, JString, required = false,
                                 default = nil)
  if valid_613598 != nil:
    section.add "X-Amz-Date", valid_613598
  var valid_613599 = header.getOrDefault("X-Amz-Credential")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Credential", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Security-Token")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Security-Token", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Algorithm")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Algorithm", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-SignedHeaders", valid_613602
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_613603 = formData.getOrDefault("RuleArn")
  valid_613603 = validateParameter(valid_613603, JString, required = true,
                                 default = nil)
  if valid_613603 != nil:
    section.add "RuleArn", valid_613603
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613604: Call_PostDeleteRule_613591; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_613604.validator(path, query, header, formData, body)
  let scheme = call_613604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613604.url(scheme.get, call_613604.host, call_613604.base,
                         call_613604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613604, url, valid)

proc call*(call_613605: Call_PostDeleteRule_613591; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613606 = newJObject()
  var formData_613607 = newJObject()
  add(formData_613607, "RuleArn", newJString(RuleArn))
  add(query_613606, "Action", newJString(Action))
  add(query_613606, "Version", newJString(Version))
  result = call_613605.call(nil, query_613606, nil, formData_613607, nil)

var postDeleteRule* = Call_PostDeleteRule_613591(name: "postDeleteRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_PostDeleteRule_613592,
    base: "/", url: url_PostDeleteRule_613593, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRule_613575 = ref object of OpenApiRestCall_612658
proc url_GetDeleteRule_613577(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteRule_613576(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613578 = query.getOrDefault("RuleArn")
  valid_613578 = validateParameter(valid_613578, JString, required = true,
                                 default = nil)
  if valid_613578 != nil:
    section.add "RuleArn", valid_613578
  var valid_613579 = query.getOrDefault("Action")
  valid_613579 = validateParameter(valid_613579, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_613579 != nil:
    section.add "Action", valid_613579
  var valid_613580 = query.getOrDefault("Version")
  valid_613580 = validateParameter(valid_613580, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613580 != nil:
    section.add "Version", valid_613580
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613581 = header.getOrDefault("X-Amz-Signature")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-Signature", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-Content-Sha256", valid_613582
  var valid_613583 = header.getOrDefault("X-Amz-Date")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Date", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Credential")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Credential", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Security-Token")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Security-Token", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Algorithm")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Algorithm", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-SignedHeaders", valid_613587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613588: Call_GetDeleteRule_613575; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_613588.validator(path, query, header, formData, body)
  let scheme = call_613588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613588.url(scheme.get, call_613588.host, call_613588.base,
                         call_613588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613588, url, valid)

proc call*(call_613589: Call_GetDeleteRule_613575; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613590 = newJObject()
  add(query_613590, "RuleArn", newJString(RuleArn))
  add(query_613590, "Action", newJString(Action))
  add(query_613590, "Version", newJString(Version))
  result = call_613589.call(nil, query_613590, nil, nil, nil)

var getDeleteRule* = Call_GetDeleteRule_613575(name: "getDeleteRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_GetDeleteRule_613576,
    base: "/", url: url_GetDeleteRule_613577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTargetGroup_613624 = ref object of OpenApiRestCall_612658
proc url_PostDeleteTargetGroup_613626(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteTargetGroup_613625(path: JsonNode; query: JsonNode;
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
  var valid_613627 = query.getOrDefault("Action")
  valid_613627 = validateParameter(valid_613627, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_613627 != nil:
    section.add "Action", valid_613627
  var valid_613628 = query.getOrDefault("Version")
  valid_613628 = validateParameter(valid_613628, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613628 != nil:
    section.add "Version", valid_613628
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613629 = header.getOrDefault("X-Amz-Signature")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Signature", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Content-Sha256", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Date")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Date", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Credential")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Credential", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Security-Token")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Security-Token", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Algorithm")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Algorithm", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-SignedHeaders", valid_613635
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_613636 = formData.getOrDefault("TargetGroupArn")
  valid_613636 = validateParameter(valid_613636, JString, required = true,
                                 default = nil)
  if valid_613636 != nil:
    section.add "TargetGroupArn", valid_613636
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613637: Call_PostDeleteTargetGroup_613624; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_613637.validator(path, query, header, formData, body)
  let scheme = call_613637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613637.url(scheme.get, call_613637.host, call_613637.base,
                         call_613637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613637, url, valid)

proc call*(call_613638: Call_PostDeleteTargetGroup_613624; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_613639 = newJObject()
  var formData_613640 = newJObject()
  add(query_613639, "Action", newJString(Action))
  add(formData_613640, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_613639, "Version", newJString(Version))
  result = call_613638.call(nil, query_613639, nil, formData_613640, nil)

var postDeleteTargetGroup* = Call_PostDeleteTargetGroup_613624(
    name: "postDeleteTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup",
    validator: validate_PostDeleteTargetGroup_613625, base: "/",
    url: url_PostDeleteTargetGroup_613626, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTargetGroup_613608 = ref object of OpenApiRestCall_612658
proc url_GetDeleteTargetGroup_613610(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteTargetGroup_613609(path: JsonNode; query: JsonNode;
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
  var valid_613611 = query.getOrDefault("TargetGroupArn")
  valid_613611 = validateParameter(valid_613611, JString, required = true,
                                 default = nil)
  if valid_613611 != nil:
    section.add "TargetGroupArn", valid_613611
  var valid_613612 = query.getOrDefault("Action")
  valid_613612 = validateParameter(valid_613612, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_613612 != nil:
    section.add "Action", valid_613612
  var valid_613613 = query.getOrDefault("Version")
  valid_613613 = validateParameter(valid_613613, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613613 != nil:
    section.add "Version", valid_613613
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613614 = header.getOrDefault("X-Amz-Signature")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Signature", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Content-Sha256", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Date")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Date", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Credential")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Credential", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Security-Token")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Security-Token", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Algorithm")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Algorithm", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-SignedHeaders", valid_613620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613621: Call_GetDeleteTargetGroup_613608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_613621.validator(path, query, header, formData, body)
  let scheme = call_613621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613621.url(scheme.get, call_613621.host, call_613621.base,
                         call_613621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613621, url, valid)

proc call*(call_613622: Call_GetDeleteTargetGroup_613608; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613623 = newJObject()
  add(query_613623, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_613623, "Action", newJString(Action))
  add(query_613623, "Version", newJString(Version))
  result = call_613622.call(nil, query_613623, nil, nil, nil)

var getDeleteTargetGroup* = Call_GetDeleteTargetGroup_613608(
    name: "getDeleteTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup", validator: validate_GetDeleteTargetGroup_613609,
    base: "/", url: url_GetDeleteTargetGroup_613610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterTargets_613658 = ref object of OpenApiRestCall_612658
proc url_PostDeregisterTargets_613660(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeregisterTargets_613659(path: JsonNode; query: JsonNode;
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
  var valid_613661 = query.getOrDefault("Action")
  valid_613661 = validateParameter(valid_613661, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_613661 != nil:
    section.add "Action", valid_613661
  var valid_613662 = query.getOrDefault("Version")
  valid_613662 = validateParameter(valid_613662, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613662 != nil:
    section.add "Version", valid_613662
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613663 = header.getOrDefault("X-Amz-Signature")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Signature", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Content-Sha256", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-Date")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Date", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Credential")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Credential", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Security-Token")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Security-Token", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Algorithm")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Algorithm", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-SignedHeaders", valid_613669
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_613670 = formData.getOrDefault("Targets")
  valid_613670 = validateParameter(valid_613670, JArray, required = true, default = nil)
  if valid_613670 != nil:
    section.add "Targets", valid_613670
  var valid_613671 = formData.getOrDefault("TargetGroupArn")
  valid_613671 = validateParameter(valid_613671, JString, required = true,
                                 default = nil)
  if valid_613671 != nil:
    section.add "TargetGroupArn", valid_613671
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613672: Call_PostDeregisterTargets_613658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_613672.validator(path, query, header, formData, body)
  let scheme = call_613672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613672.url(scheme.get, call_613672.host, call_613672.base,
                         call_613672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613672, url, valid)

proc call*(call_613673: Call_PostDeregisterTargets_613658; Targets: JsonNode;
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
  var query_613674 = newJObject()
  var formData_613675 = newJObject()
  if Targets != nil:
    formData_613675.add "Targets", Targets
  add(query_613674, "Action", newJString(Action))
  add(formData_613675, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_613674, "Version", newJString(Version))
  result = call_613673.call(nil, query_613674, nil, formData_613675, nil)

var postDeregisterTargets* = Call_PostDeregisterTargets_613658(
    name: "postDeregisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets",
    validator: validate_PostDeregisterTargets_613659, base: "/",
    url: url_PostDeregisterTargets_613660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterTargets_613641 = ref object of OpenApiRestCall_612658
proc url_GetDeregisterTargets_613643(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeregisterTargets_613642(path: JsonNode; query: JsonNode;
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
  var valid_613644 = query.getOrDefault("Targets")
  valid_613644 = validateParameter(valid_613644, JArray, required = true, default = nil)
  if valid_613644 != nil:
    section.add "Targets", valid_613644
  var valid_613645 = query.getOrDefault("TargetGroupArn")
  valid_613645 = validateParameter(valid_613645, JString, required = true,
                                 default = nil)
  if valid_613645 != nil:
    section.add "TargetGroupArn", valid_613645
  var valid_613646 = query.getOrDefault("Action")
  valid_613646 = validateParameter(valid_613646, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_613646 != nil:
    section.add "Action", valid_613646
  var valid_613647 = query.getOrDefault("Version")
  valid_613647 = validateParameter(valid_613647, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613647 != nil:
    section.add "Version", valid_613647
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613648 = header.getOrDefault("X-Amz-Signature")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Signature", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Content-Sha256", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-Date")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Date", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Credential")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Credential", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Security-Token")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Security-Token", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Algorithm")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Algorithm", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-SignedHeaders", valid_613654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613655: Call_GetDeregisterTargets_613641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_613655.validator(path, query, header, formData, body)
  let scheme = call_613655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613655.url(scheme.get, call_613655.host, call_613655.base,
                         call_613655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613655, url, valid)

proc call*(call_613656: Call_GetDeregisterTargets_613641; Targets: JsonNode;
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
  var query_613657 = newJObject()
  if Targets != nil:
    query_613657.add "Targets", Targets
  add(query_613657, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_613657, "Action", newJString(Action))
  add(query_613657, "Version", newJString(Version))
  result = call_613656.call(nil, query_613657, nil, nil, nil)

var getDeregisterTargets* = Call_GetDeregisterTargets_613641(
    name: "getDeregisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets", validator: validate_GetDeregisterTargets_613642,
    base: "/", url: url_GetDeregisterTargets_613643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_613693 = ref object of OpenApiRestCall_612658
proc url_PostDescribeAccountLimits_613695(protocol: Scheme; host: string;
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

proc validate_PostDescribeAccountLimits_613694(path: JsonNode; query: JsonNode;
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
  var valid_613696 = query.getOrDefault("Action")
  valid_613696 = validateParameter(valid_613696, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_613696 != nil:
    section.add "Action", valid_613696
  var valid_613697 = query.getOrDefault("Version")
  valid_613697 = validateParameter(valid_613697, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613697 != nil:
    section.add "Version", valid_613697
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613698 = header.getOrDefault("X-Amz-Signature")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-Signature", valid_613698
  var valid_613699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-Content-Sha256", valid_613699
  var valid_613700 = header.getOrDefault("X-Amz-Date")
  valid_613700 = validateParameter(valid_613700, JString, required = false,
                                 default = nil)
  if valid_613700 != nil:
    section.add "X-Amz-Date", valid_613700
  var valid_613701 = header.getOrDefault("X-Amz-Credential")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "X-Amz-Credential", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-Security-Token")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-Security-Token", valid_613702
  var valid_613703 = header.getOrDefault("X-Amz-Algorithm")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-Algorithm", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-SignedHeaders", valid_613704
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_613705 = formData.getOrDefault("Marker")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "Marker", valid_613705
  var valid_613706 = formData.getOrDefault("PageSize")
  valid_613706 = validateParameter(valid_613706, JInt, required = false, default = nil)
  if valid_613706 != nil:
    section.add "PageSize", valid_613706
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613707: Call_PostDescribeAccountLimits_613693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613707.validator(path, query, header, formData, body)
  let scheme = call_613707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613707.url(scheme.get, call_613707.host, call_613707.base,
                         call_613707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613707, url, valid)

proc call*(call_613708: Call_PostDescribeAccountLimits_613693; Marker: string = "";
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
  var query_613709 = newJObject()
  var formData_613710 = newJObject()
  add(formData_613710, "Marker", newJString(Marker))
  add(query_613709, "Action", newJString(Action))
  add(formData_613710, "PageSize", newJInt(PageSize))
  add(query_613709, "Version", newJString(Version))
  result = call_613708.call(nil, query_613709, nil, formData_613710, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_613693(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_613694, base: "/",
    url: url_PostDescribeAccountLimits_613695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_613676 = ref object of OpenApiRestCall_612658
proc url_GetDescribeAccountLimits_613678(protocol: Scheme; host: string;
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

proc validate_GetDescribeAccountLimits_613677(path: JsonNode; query: JsonNode;
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
  var valid_613679 = query.getOrDefault("Marker")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "Marker", valid_613679
  var valid_613680 = query.getOrDefault("PageSize")
  valid_613680 = validateParameter(valid_613680, JInt, required = false, default = nil)
  if valid_613680 != nil:
    section.add "PageSize", valid_613680
  var valid_613681 = query.getOrDefault("Action")
  valid_613681 = validateParameter(valid_613681, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_613681 != nil:
    section.add "Action", valid_613681
  var valid_613682 = query.getOrDefault("Version")
  valid_613682 = validateParameter(valid_613682, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613682 != nil:
    section.add "Version", valid_613682
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613683 = header.getOrDefault("X-Amz-Signature")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Signature", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-Content-Sha256", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-Date")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Date", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-Credential")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Credential", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-Security-Token")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Security-Token", valid_613687
  var valid_613688 = header.getOrDefault("X-Amz-Algorithm")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-Algorithm", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-SignedHeaders", valid_613689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613690: Call_GetDescribeAccountLimits_613676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613690.validator(path, query, header, formData, body)
  let scheme = call_613690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613690.url(scheme.get, call_613690.host, call_613690.base,
                         call_613690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613690, url, valid)

proc call*(call_613691: Call_GetDescribeAccountLimits_613676; Marker: string = "";
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
  var query_613692 = newJObject()
  add(query_613692, "Marker", newJString(Marker))
  add(query_613692, "PageSize", newJInt(PageSize))
  add(query_613692, "Action", newJString(Action))
  add(query_613692, "Version", newJString(Version))
  result = call_613691.call(nil, query_613692, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_613676(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_613677, base: "/",
    url: url_GetDescribeAccountLimits_613678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListenerCertificates_613729 = ref object of OpenApiRestCall_612658
proc url_PostDescribeListenerCertificates_613731(protocol: Scheme; host: string;
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

proc validate_PostDescribeListenerCertificates_613730(path: JsonNode;
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
  var valid_613732 = query.getOrDefault("Action")
  valid_613732 = validateParameter(valid_613732, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_613732 != nil:
    section.add "Action", valid_613732
  var valid_613733 = query.getOrDefault("Version")
  valid_613733 = validateParameter(valid_613733, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613733 != nil:
    section.add "Version", valid_613733
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613734 = header.getOrDefault("X-Amz-Signature")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Signature", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-Content-Sha256", valid_613735
  var valid_613736 = header.getOrDefault("X-Amz-Date")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "X-Amz-Date", valid_613736
  var valid_613737 = header.getOrDefault("X-Amz-Credential")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-Credential", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Security-Token")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Security-Token", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Algorithm")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Algorithm", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-SignedHeaders", valid_613740
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
  var valid_613741 = formData.getOrDefault("ListenerArn")
  valid_613741 = validateParameter(valid_613741, JString, required = true,
                                 default = nil)
  if valid_613741 != nil:
    section.add "ListenerArn", valid_613741
  var valid_613742 = formData.getOrDefault("Marker")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "Marker", valid_613742
  var valid_613743 = formData.getOrDefault("PageSize")
  valid_613743 = validateParameter(valid_613743, JInt, required = false, default = nil)
  if valid_613743 != nil:
    section.add "PageSize", valid_613743
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613744: Call_PostDescribeListenerCertificates_613729;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613744.validator(path, query, header, formData, body)
  let scheme = call_613744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613744.url(scheme.get, call_613744.host, call_613744.base,
                         call_613744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613744, url, valid)

proc call*(call_613745: Call_PostDescribeListenerCertificates_613729;
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
  var query_613746 = newJObject()
  var formData_613747 = newJObject()
  add(formData_613747, "ListenerArn", newJString(ListenerArn))
  add(formData_613747, "Marker", newJString(Marker))
  add(query_613746, "Action", newJString(Action))
  add(formData_613747, "PageSize", newJInt(PageSize))
  add(query_613746, "Version", newJString(Version))
  result = call_613745.call(nil, query_613746, nil, formData_613747, nil)

var postDescribeListenerCertificates* = Call_PostDescribeListenerCertificates_613729(
    name: "postDescribeListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_PostDescribeListenerCertificates_613730, base: "/",
    url: url_PostDescribeListenerCertificates_613731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListenerCertificates_613711 = ref object of OpenApiRestCall_612658
proc url_GetDescribeListenerCertificates_613713(protocol: Scheme; host: string;
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

proc validate_GetDescribeListenerCertificates_613712(path: JsonNode;
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
  var valid_613714 = query.getOrDefault("Marker")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "Marker", valid_613714
  assert query != nil,
        "query argument is necessary due to required `ListenerArn` field"
  var valid_613715 = query.getOrDefault("ListenerArn")
  valid_613715 = validateParameter(valid_613715, JString, required = true,
                                 default = nil)
  if valid_613715 != nil:
    section.add "ListenerArn", valid_613715
  var valid_613716 = query.getOrDefault("PageSize")
  valid_613716 = validateParameter(valid_613716, JInt, required = false, default = nil)
  if valid_613716 != nil:
    section.add "PageSize", valid_613716
  var valid_613717 = query.getOrDefault("Action")
  valid_613717 = validateParameter(valid_613717, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_613717 != nil:
    section.add "Action", valid_613717
  var valid_613718 = query.getOrDefault("Version")
  valid_613718 = validateParameter(valid_613718, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613718 != nil:
    section.add "Version", valid_613718
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613719 = header.getOrDefault("X-Amz-Signature")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Signature", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Content-Sha256", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Date")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Date", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Credential")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Credential", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Security-Token")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Security-Token", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Algorithm")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Algorithm", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-SignedHeaders", valid_613725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613726: Call_GetDescribeListenerCertificates_613711;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613726.validator(path, query, header, formData, body)
  let scheme = call_613726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613726.url(scheme.get, call_613726.host, call_613726.base,
                         call_613726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613726, url, valid)

proc call*(call_613727: Call_GetDescribeListenerCertificates_613711;
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
  var query_613728 = newJObject()
  add(query_613728, "Marker", newJString(Marker))
  add(query_613728, "ListenerArn", newJString(ListenerArn))
  add(query_613728, "PageSize", newJInt(PageSize))
  add(query_613728, "Action", newJString(Action))
  add(query_613728, "Version", newJString(Version))
  result = call_613727.call(nil, query_613728, nil, nil, nil)

var getDescribeListenerCertificates* = Call_GetDescribeListenerCertificates_613711(
    name: "getDescribeListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_GetDescribeListenerCertificates_613712, base: "/",
    url: url_GetDescribeListenerCertificates_613713,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListeners_613767 = ref object of OpenApiRestCall_612658
proc url_PostDescribeListeners_613769(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeListeners_613768(path: JsonNode; query: JsonNode;
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
  var valid_613770 = query.getOrDefault("Action")
  valid_613770 = validateParameter(valid_613770, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_613770 != nil:
    section.add "Action", valid_613770
  var valid_613771 = query.getOrDefault("Version")
  valid_613771 = validateParameter(valid_613771, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613771 != nil:
    section.add "Version", valid_613771
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613772 = header.getOrDefault("X-Amz-Signature")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "X-Amz-Signature", valid_613772
  var valid_613773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-Content-Sha256", valid_613773
  var valid_613774 = header.getOrDefault("X-Amz-Date")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-Date", valid_613774
  var valid_613775 = header.getOrDefault("X-Amz-Credential")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-Credential", valid_613775
  var valid_613776 = header.getOrDefault("X-Amz-Security-Token")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Security-Token", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Algorithm")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Algorithm", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-SignedHeaders", valid_613778
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
  var valid_613779 = formData.getOrDefault("Marker")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "Marker", valid_613779
  var valid_613780 = formData.getOrDefault("PageSize")
  valid_613780 = validateParameter(valid_613780, JInt, required = false, default = nil)
  if valid_613780 != nil:
    section.add "PageSize", valid_613780
  var valid_613781 = formData.getOrDefault("LoadBalancerArn")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "LoadBalancerArn", valid_613781
  var valid_613782 = formData.getOrDefault("ListenerArns")
  valid_613782 = validateParameter(valid_613782, JArray, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "ListenerArns", valid_613782
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613783: Call_PostDescribeListeners_613767; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_613783.validator(path, query, header, formData, body)
  let scheme = call_613783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613783.url(scheme.get, call_613783.host, call_613783.base,
                         call_613783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613783, url, valid)

proc call*(call_613784: Call_PostDescribeListeners_613767; Marker: string = "";
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
  var query_613785 = newJObject()
  var formData_613786 = newJObject()
  add(formData_613786, "Marker", newJString(Marker))
  add(query_613785, "Action", newJString(Action))
  add(formData_613786, "PageSize", newJInt(PageSize))
  add(query_613785, "Version", newJString(Version))
  add(formData_613786, "LoadBalancerArn", newJString(LoadBalancerArn))
  if ListenerArns != nil:
    formData_613786.add "ListenerArns", ListenerArns
  result = call_613784.call(nil, query_613785, nil, formData_613786, nil)

var postDescribeListeners* = Call_PostDescribeListeners_613767(
    name: "postDescribeListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners",
    validator: validate_PostDescribeListeners_613768, base: "/",
    url: url_PostDescribeListeners_613769, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListeners_613748 = ref object of OpenApiRestCall_612658
proc url_GetDescribeListeners_613750(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeListeners_613749(path: JsonNode; query: JsonNode;
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
  var valid_613751 = query.getOrDefault("Marker")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "Marker", valid_613751
  var valid_613752 = query.getOrDefault("LoadBalancerArn")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "LoadBalancerArn", valid_613752
  var valid_613753 = query.getOrDefault("ListenerArns")
  valid_613753 = validateParameter(valid_613753, JArray, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "ListenerArns", valid_613753
  var valid_613754 = query.getOrDefault("PageSize")
  valid_613754 = validateParameter(valid_613754, JInt, required = false, default = nil)
  if valid_613754 != nil:
    section.add "PageSize", valid_613754
  var valid_613755 = query.getOrDefault("Action")
  valid_613755 = validateParameter(valid_613755, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_613755 != nil:
    section.add "Action", valid_613755
  var valid_613756 = query.getOrDefault("Version")
  valid_613756 = validateParameter(valid_613756, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613756 != nil:
    section.add "Version", valid_613756
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613757 = header.getOrDefault("X-Amz-Signature")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Signature", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Content-Sha256", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-Date")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-Date", valid_613759
  var valid_613760 = header.getOrDefault("X-Amz-Credential")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-Credential", valid_613760
  var valid_613761 = header.getOrDefault("X-Amz-Security-Token")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "X-Amz-Security-Token", valid_613761
  var valid_613762 = header.getOrDefault("X-Amz-Algorithm")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-Algorithm", valid_613762
  var valid_613763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613763 = validateParameter(valid_613763, JString, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "X-Amz-SignedHeaders", valid_613763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613764: Call_GetDescribeListeners_613748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_613764.validator(path, query, header, formData, body)
  let scheme = call_613764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613764.url(scheme.get, call_613764.host, call_613764.base,
                         call_613764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613764, url, valid)

proc call*(call_613765: Call_GetDescribeListeners_613748; Marker: string = "";
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
  var query_613766 = newJObject()
  add(query_613766, "Marker", newJString(Marker))
  add(query_613766, "LoadBalancerArn", newJString(LoadBalancerArn))
  if ListenerArns != nil:
    query_613766.add "ListenerArns", ListenerArns
  add(query_613766, "PageSize", newJInt(PageSize))
  add(query_613766, "Action", newJString(Action))
  add(query_613766, "Version", newJString(Version))
  result = call_613765.call(nil, query_613766, nil, nil, nil)

var getDescribeListeners* = Call_GetDescribeListeners_613748(
    name: "getDescribeListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners", validator: validate_GetDescribeListeners_613749,
    base: "/", url: url_GetDescribeListeners_613750,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_613803 = ref object of OpenApiRestCall_612658
proc url_PostDescribeLoadBalancerAttributes_613805(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancerAttributes_613804(path: JsonNode;
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
  var valid_613806 = query.getOrDefault("Action")
  valid_613806 = validateParameter(valid_613806, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_613806 != nil:
    section.add "Action", valid_613806
  var valid_613807 = query.getOrDefault("Version")
  valid_613807 = validateParameter(valid_613807, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613807 != nil:
    section.add "Version", valid_613807
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613808 = header.getOrDefault("X-Amz-Signature")
  valid_613808 = validateParameter(valid_613808, JString, required = false,
                                 default = nil)
  if valid_613808 != nil:
    section.add "X-Amz-Signature", valid_613808
  var valid_613809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Content-Sha256", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-Date")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Date", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Credential")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Credential", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Security-Token")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Security-Token", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Algorithm")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Algorithm", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-SignedHeaders", valid_613814
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_613815 = formData.getOrDefault("LoadBalancerArn")
  valid_613815 = validateParameter(valid_613815, JString, required = true,
                                 default = nil)
  if valid_613815 != nil:
    section.add "LoadBalancerArn", valid_613815
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613816: Call_PostDescribeLoadBalancerAttributes_613803;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613816.validator(path, query, header, formData, body)
  let scheme = call_613816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613816.url(scheme.get, call_613816.host, call_613816.base,
                         call_613816.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613816, url, valid)

proc call*(call_613817: Call_PostDescribeLoadBalancerAttributes_613803;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  var query_613818 = newJObject()
  var formData_613819 = newJObject()
  add(query_613818, "Action", newJString(Action))
  add(query_613818, "Version", newJString(Version))
  add(formData_613819, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_613817.call(nil, query_613818, nil, formData_613819, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_613803(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_613804, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_613805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_613787 = ref object of OpenApiRestCall_612658
proc url_GetDescribeLoadBalancerAttributes_613789(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancerAttributes_613788(path: JsonNode;
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
  var valid_613790 = query.getOrDefault("LoadBalancerArn")
  valid_613790 = validateParameter(valid_613790, JString, required = true,
                                 default = nil)
  if valid_613790 != nil:
    section.add "LoadBalancerArn", valid_613790
  var valid_613791 = query.getOrDefault("Action")
  valid_613791 = validateParameter(valid_613791, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_613791 != nil:
    section.add "Action", valid_613791
  var valid_613792 = query.getOrDefault("Version")
  valid_613792 = validateParameter(valid_613792, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613792 != nil:
    section.add "Version", valid_613792
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613793 = header.getOrDefault("X-Amz-Signature")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-Signature", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Content-Sha256", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-Date")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Date", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Credential")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Credential", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Security-Token")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Security-Token", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Algorithm")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Algorithm", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-SignedHeaders", valid_613799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613800: Call_GetDescribeLoadBalancerAttributes_613787;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613800.validator(path, query, header, formData, body)
  let scheme = call_613800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613800.url(scheme.get, call_613800.host, call_613800.base,
                         call_613800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613800, url, valid)

proc call*(call_613801: Call_GetDescribeLoadBalancerAttributes_613787;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613802 = newJObject()
  add(query_613802, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_613802, "Action", newJString(Action))
  add(query_613802, "Version", newJString(Version))
  result = call_613801.call(nil, query_613802, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_613787(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_613788, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_613789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_613839 = ref object of OpenApiRestCall_612658
proc url_PostDescribeLoadBalancers_613841(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancers_613840(path: JsonNode; query: JsonNode;
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
  var valid_613842 = query.getOrDefault("Action")
  valid_613842 = validateParameter(valid_613842, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_613842 != nil:
    section.add "Action", valid_613842
  var valid_613843 = query.getOrDefault("Version")
  valid_613843 = validateParameter(valid_613843, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613843 != nil:
    section.add "Version", valid_613843
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613844 = header.getOrDefault("X-Amz-Signature")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Signature", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-Content-Sha256", valid_613845
  var valid_613846 = header.getOrDefault("X-Amz-Date")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-Date", valid_613846
  var valid_613847 = header.getOrDefault("X-Amz-Credential")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Credential", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Security-Token")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Security-Token", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-Algorithm")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Algorithm", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-SignedHeaders", valid_613850
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
  var valid_613851 = formData.getOrDefault("Names")
  valid_613851 = validateParameter(valid_613851, JArray, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "Names", valid_613851
  var valid_613852 = formData.getOrDefault("Marker")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "Marker", valid_613852
  var valid_613853 = formData.getOrDefault("PageSize")
  valid_613853 = validateParameter(valid_613853, JInt, required = false, default = nil)
  if valid_613853 != nil:
    section.add "PageSize", valid_613853
  var valid_613854 = formData.getOrDefault("LoadBalancerArns")
  valid_613854 = validateParameter(valid_613854, JArray, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "LoadBalancerArns", valid_613854
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613855: Call_PostDescribeLoadBalancers_613839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_613855.validator(path, query, header, formData, body)
  let scheme = call_613855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613855.url(scheme.get, call_613855.host, call_613855.base,
                         call_613855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613855, url, valid)

proc call*(call_613856: Call_PostDescribeLoadBalancers_613839;
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
  var query_613857 = newJObject()
  var formData_613858 = newJObject()
  if Names != nil:
    formData_613858.add "Names", Names
  add(formData_613858, "Marker", newJString(Marker))
  add(query_613857, "Action", newJString(Action))
  add(formData_613858, "PageSize", newJInt(PageSize))
  add(query_613857, "Version", newJString(Version))
  if LoadBalancerArns != nil:
    formData_613858.add "LoadBalancerArns", LoadBalancerArns
  result = call_613856.call(nil, query_613857, nil, formData_613858, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_613839(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_613840, base: "/",
    url: url_PostDescribeLoadBalancers_613841,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_613820 = ref object of OpenApiRestCall_612658
proc url_GetDescribeLoadBalancers_613822(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancers_613821(path: JsonNode; query: JsonNode;
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
  var valid_613823 = query.getOrDefault("Marker")
  valid_613823 = validateParameter(valid_613823, JString, required = false,
                                 default = nil)
  if valid_613823 != nil:
    section.add "Marker", valid_613823
  var valid_613824 = query.getOrDefault("PageSize")
  valid_613824 = validateParameter(valid_613824, JInt, required = false, default = nil)
  if valid_613824 != nil:
    section.add "PageSize", valid_613824
  var valid_613825 = query.getOrDefault("LoadBalancerArns")
  valid_613825 = validateParameter(valid_613825, JArray, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "LoadBalancerArns", valid_613825
  var valid_613826 = query.getOrDefault("Action")
  valid_613826 = validateParameter(valid_613826, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_613826 != nil:
    section.add "Action", valid_613826
  var valid_613827 = query.getOrDefault("Version")
  valid_613827 = validateParameter(valid_613827, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613827 != nil:
    section.add "Version", valid_613827
  var valid_613828 = query.getOrDefault("Names")
  valid_613828 = validateParameter(valid_613828, JArray, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "Names", valid_613828
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613829 = header.getOrDefault("X-Amz-Signature")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Signature", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-Content-Sha256", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-Date")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-Date", valid_613831
  var valid_613832 = header.getOrDefault("X-Amz-Credential")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Credential", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Security-Token")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Security-Token", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-Algorithm")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Algorithm", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-SignedHeaders", valid_613835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613836: Call_GetDescribeLoadBalancers_613820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_613836.validator(path, query, header, formData, body)
  let scheme = call_613836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613836.url(scheme.get, call_613836.host, call_613836.base,
                         call_613836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613836, url, valid)

proc call*(call_613837: Call_GetDescribeLoadBalancers_613820; Marker: string = "";
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
  var query_613838 = newJObject()
  add(query_613838, "Marker", newJString(Marker))
  add(query_613838, "PageSize", newJInt(PageSize))
  if LoadBalancerArns != nil:
    query_613838.add "LoadBalancerArns", LoadBalancerArns
  add(query_613838, "Action", newJString(Action))
  add(query_613838, "Version", newJString(Version))
  if Names != nil:
    query_613838.add "Names", Names
  result = call_613837.call(nil, query_613838, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_613820(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_613821, base: "/",
    url: url_GetDescribeLoadBalancers_613822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRules_613878 = ref object of OpenApiRestCall_612658
proc url_PostDescribeRules_613880(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeRules_613879(path: JsonNode; query: JsonNode;
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
  var valid_613881 = query.getOrDefault("Action")
  valid_613881 = validateParameter(valid_613881, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_613881 != nil:
    section.add "Action", valid_613881
  var valid_613882 = query.getOrDefault("Version")
  valid_613882 = validateParameter(valid_613882, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613882 != nil:
    section.add "Version", valid_613882
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613883 = header.getOrDefault("X-Amz-Signature")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-Signature", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-Content-Sha256", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-Date")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-Date", valid_613885
  var valid_613886 = header.getOrDefault("X-Amz-Credential")
  valid_613886 = validateParameter(valid_613886, JString, required = false,
                                 default = nil)
  if valid_613886 != nil:
    section.add "X-Amz-Credential", valid_613886
  var valid_613887 = header.getOrDefault("X-Amz-Security-Token")
  valid_613887 = validateParameter(valid_613887, JString, required = false,
                                 default = nil)
  if valid_613887 != nil:
    section.add "X-Amz-Security-Token", valid_613887
  var valid_613888 = header.getOrDefault("X-Amz-Algorithm")
  valid_613888 = validateParameter(valid_613888, JString, required = false,
                                 default = nil)
  if valid_613888 != nil:
    section.add "X-Amz-Algorithm", valid_613888
  var valid_613889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613889 = validateParameter(valid_613889, JString, required = false,
                                 default = nil)
  if valid_613889 != nil:
    section.add "X-Amz-SignedHeaders", valid_613889
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
  var valid_613890 = formData.getOrDefault("ListenerArn")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "ListenerArn", valid_613890
  var valid_613891 = formData.getOrDefault("Marker")
  valid_613891 = validateParameter(valid_613891, JString, required = false,
                                 default = nil)
  if valid_613891 != nil:
    section.add "Marker", valid_613891
  var valid_613892 = formData.getOrDefault("RuleArns")
  valid_613892 = validateParameter(valid_613892, JArray, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "RuleArns", valid_613892
  var valid_613893 = formData.getOrDefault("PageSize")
  valid_613893 = validateParameter(valid_613893, JInt, required = false, default = nil)
  if valid_613893 != nil:
    section.add "PageSize", valid_613893
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613894: Call_PostDescribeRules_613878; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_613894.validator(path, query, header, formData, body)
  let scheme = call_613894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613894.url(scheme.get, call_613894.host, call_613894.base,
                         call_613894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613894, url, valid)

proc call*(call_613895: Call_PostDescribeRules_613878; ListenerArn: string = "";
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
  var query_613896 = newJObject()
  var formData_613897 = newJObject()
  add(formData_613897, "ListenerArn", newJString(ListenerArn))
  add(formData_613897, "Marker", newJString(Marker))
  if RuleArns != nil:
    formData_613897.add "RuleArns", RuleArns
  add(query_613896, "Action", newJString(Action))
  add(formData_613897, "PageSize", newJInt(PageSize))
  add(query_613896, "Version", newJString(Version))
  result = call_613895.call(nil, query_613896, nil, formData_613897, nil)

var postDescribeRules* = Call_PostDescribeRules_613878(name: "postDescribeRules",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_PostDescribeRules_613879,
    base: "/", url: url_PostDescribeRules_613880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRules_613859 = ref object of OpenApiRestCall_612658
proc url_GetDescribeRules_613861(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeRules_613860(path: JsonNode; query: JsonNode;
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
  var valid_613862 = query.getOrDefault("Marker")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "Marker", valid_613862
  var valid_613863 = query.getOrDefault("ListenerArn")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "ListenerArn", valid_613863
  var valid_613864 = query.getOrDefault("PageSize")
  valid_613864 = validateParameter(valid_613864, JInt, required = false, default = nil)
  if valid_613864 != nil:
    section.add "PageSize", valid_613864
  var valid_613865 = query.getOrDefault("Action")
  valid_613865 = validateParameter(valid_613865, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_613865 != nil:
    section.add "Action", valid_613865
  var valid_613866 = query.getOrDefault("Version")
  valid_613866 = validateParameter(valid_613866, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613866 != nil:
    section.add "Version", valid_613866
  var valid_613867 = query.getOrDefault("RuleArns")
  valid_613867 = validateParameter(valid_613867, JArray, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "RuleArns", valid_613867
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613868 = header.getOrDefault("X-Amz-Signature")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-Signature", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-Content-Sha256", valid_613869
  var valid_613870 = header.getOrDefault("X-Amz-Date")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "X-Amz-Date", valid_613870
  var valid_613871 = header.getOrDefault("X-Amz-Credential")
  valid_613871 = validateParameter(valid_613871, JString, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "X-Amz-Credential", valid_613871
  var valid_613872 = header.getOrDefault("X-Amz-Security-Token")
  valid_613872 = validateParameter(valid_613872, JString, required = false,
                                 default = nil)
  if valid_613872 != nil:
    section.add "X-Amz-Security-Token", valid_613872
  var valid_613873 = header.getOrDefault("X-Amz-Algorithm")
  valid_613873 = validateParameter(valid_613873, JString, required = false,
                                 default = nil)
  if valid_613873 != nil:
    section.add "X-Amz-Algorithm", valid_613873
  var valid_613874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613874 = validateParameter(valid_613874, JString, required = false,
                                 default = nil)
  if valid_613874 != nil:
    section.add "X-Amz-SignedHeaders", valid_613874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613875: Call_GetDescribeRules_613859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_613875.validator(path, query, header, formData, body)
  let scheme = call_613875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613875.url(scheme.get, call_613875.host, call_613875.base,
                         call_613875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613875, url, valid)

proc call*(call_613876: Call_GetDescribeRules_613859; Marker: string = "";
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
  var query_613877 = newJObject()
  add(query_613877, "Marker", newJString(Marker))
  add(query_613877, "ListenerArn", newJString(ListenerArn))
  add(query_613877, "PageSize", newJInt(PageSize))
  add(query_613877, "Action", newJString(Action))
  add(query_613877, "Version", newJString(Version))
  if RuleArns != nil:
    query_613877.add "RuleArns", RuleArns
  result = call_613876.call(nil, query_613877, nil, nil, nil)

var getDescribeRules* = Call_GetDescribeRules_613859(name: "getDescribeRules",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_GetDescribeRules_613860,
    base: "/", url: url_GetDescribeRules_613861,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSSLPolicies_613916 = ref object of OpenApiRestCall_612658
proc url_PostDescribeSSLPolicies_613918(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeSSLPolicies_613917(path: JsonNode; query: JsonNode;
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
  var valid_613919 = query.getOrDefault("Action")
  valid_613919 = validateParameter(valid_613919, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_613919 != nil:
    section.add "Action", valid_613919
  var valid_613920 = query.getOrDefault("Version")
  valid_613920 = validateParameter(valid_613920, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613920 != nil:
    section.add "Version", valid_613920
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613921 = header.getOrDefault("X-Amz-Signature")
  valid_613921 = validateParameter(valid_613921, JString, required = false,
                                 default = nil)
  if valid_613921 != nil:
    section.add "X-Amz-Signature", valid_613921
  var valid_613922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613922 = validateParameter(valid_613922, JString, required = false,
                                 default = nil)
  if valid_613922 != nil:
    section.add "X-Amz-Content-Sha256", valid_613922
  var valid_613923 = header.getOrDefault("X-Amz-Date")
  valid_613923 = validateParameter(valid_613923, JString, required = false,
                                 default = nil)
  if valid_613923 != nil:
    section.add "X-Amz-Date", valid_613923
  var valid_613924 = header.getOrDefault("X-Amz-Credential")
  valid_613924 = validateParameter(valid_613924, JString, required = false,
                                 default = nil)
  if valid_613924 != nil:
    section.add "X-Amz-Credential", valid_613924
  var valid_613925 = header.getOrDefault("X-Amz-Security-Token")
  valid_613925 = validateParameter(valid_613925, JString, required = false,
                                 default = nil)
  if valid_613925 != nil:
    section.add "X-Amz-Security-Token", valid_613925
  var valid_613926 = header.getOrDefault("X-Amz-Algorithm")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-Algorithm", valid_613926
  var valid_613927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "X-Amz-SignedHeaders", valid_613927
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the policies.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_613928 = formData.getOrDefault("Names")
  valid_613928 = validateParameter(valid_613928, JArray, required = false,
                                 default = nil)
  if valid_613928 != nil:
    section.add "Names", valid_613928
  var valid_613929 = formData.getOrDefault("Marker")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "Marker", valid_613929
  var valid_613930 = formData.getOrDefault("PageSize")
  valid_613930 = validateParameter(valid_613930, JInt, required = false, default = nil)
  if valid_613930 != nil:
    section.add "PageSize", valid_613930
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613931: Call_PostDescribeSSLPolicies_613916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613931.validator(path, query, header, formData, body)
  let scheme = call_613931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613931.url(scheme.get, call_613931.host, call_613931.base,
                         call_613931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613931, url, valid)

proc call*(call_613932: Call_PostDescribeSSLPolicies_613916; Names: JsonNode = nil;
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
  var query_613933 = newJObject()
  var formData_613934 = newJObject()
  if Names != nil:
    formData_613934.add "Names", Names
  add(formData_613934, "Marker", newJString(Marker))
  add(query_613933, "Action", newJString(Action))
  add(formData_613934, "PageSize", newJInt(PageSize))
  add(query_613933, "Version", newJString(Version))
  result = call_613932.call(nil, query_613933, nil, formData_613934, nil)

var postDescribeSSLPolicies* = Call_PostDescribeSSLPolicies_613916(
    name: "postDescribeSSLPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_PostDescribeSSLPolicies_613917, base: "/",
    url: url_PostDescribeSSLPolicies_613918, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSSLPolicies_613898 = ref object of OpenApiRestCall_612658
proc url_GetDescribeSSLPolicies_613900(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeSSLPolicies_613899(path: JsonNode; query: JsonNode;
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
  var valid_613901 = query.getOrDefault("Marker")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "Marker", valid_613901
  var valid_613902 = query.getOrDefault("PageSize")
  valid_613902 = validateParameter(valid_613902, JInt, required = false, default = nil)
  if valid_613902 != nil:
    section.add "PageSize", valid_613902
  var valid_613903 = query.getOrDefault("Action")
  valid_613903 = validateParameter(valid_613903, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_613903 != nil:
    section.add "Action", valid_613903
  var valid_613904 = query.getOrDefault("Version")
  valid_613904 = validateParameter(valid_613904, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613904 != nil:
    section.add "Version", valid_613904
  var valid_613905 = query.getOrDefault("Names")
  valid_613905 = validateParameter(valid_613905, JArray, required = false,
                                 default = nil)
  if valid_613905 != nil:
    section.add "Names", valid_613905
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613906 = header.getOrDefault("X-Amz-Signature")
  valid_613906 = validateParameter(valid_613906, JString, required = false,
                                 default = nil)
  if valid_613906 != nil:
    section.add "X-Amz-Signature", valid_613906
  var valid_613907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613907 = validateParameter(valid_613907, JString, required = false,
                                 default = nil)
  if valid_613907 != nil:
    section.add "X-Amz-Content-Sha256", valid_613907
  var valid_613908 = header.getOrDefault("X-Amz-Date")
  valid_613908 = validateParameter(valid_613908, JString, required = false,
                                 default = nil)
  if valid_613908 != nil:
    section.add "X-Amz-Date", valid_613908
  var valid_613909 = header.getOrDefault("X-Amz-Credential")
  valid_613909 = validateParameter(valid_613909, JString, required = false,
                                 default = nil)
  if valid_613909 != nil:
    section.add "X-Amz-Credential", valid_613909
  var valid_613910 = header.getOrDefault("X-Amz-Security-Token")
  valid_613910 = validateParameter(valid_613910, JString, required = false,
                                 default = nil)
  if valid_613910 != nil:
    section.add "X-Amz-Security-Token", valid_613910
  var valid_613911 = header.getOrDefault("X-Amz-Algorithm")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "X-Amz-Algorithm", valid_613911
  var valid_613912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-SignedHeaders", valid_613912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613913: Call_GetDescribeSSLPolicies_613898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613913.validator(path, query, header, formData, body)
  let scheme = call_613913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613913.url(scheme.get, call_613913.host, call_613913.base,
                         call_613913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613913, url, valid)

proc call*(call_613914: Call_GetDescribeSSLPolicies_613898; Marker: string = "";
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
  var query_613915 = newJObject()
  add(query_613915, "Marker", newJString(Marker))
  add(query_613915, "PageSize", newJInt(PageSize))
  add(query_613915, "Action", newJString(Action))
  add(query_613915, "Version", newJString(Version))
  if Names != nil:
    query_613915.add "Names", Names
  result = call_613914.call(nil, query_613915, nil, nil, nil)

var getDescribeSSLPolicies* = Call_GetDescribeSSLPolicies_613898(
    name: "getDescribeSSLPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_GetDescribeSSLPolicies_613899, base: "/",
    url: url_GetDescribeSSLPolicies_613900, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_613951 = ref object of OpenApiRestCall_612658
proc url_PostDescribeTags_613953(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeTags_613952(path: JsonNode; query: JsonNode;
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
  var valid_613954 = query.getOrDefault("Action")
  valid_613954 = validateParameter(valid_613954, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_613954 != nil:
    section.add "Action", valid_613954
  var valid_613955 = query.getOrDefault("Version")
  valid_613955 = validateParameter(valid_613955, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613955 != nil:
    section.add "Version", valid_613955
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613956 = header.getOrDefault("X-Amz-Signature")
  valid_613956 = validateParameter(valid_613956, JString, required = false,
                                 default = nil)
  if valid_613956 != nil:
    section.add "X-Amz-Signature", valid_613956
  var valid_613957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613957 = validateParameter(valid_613957, JString, required = false,
                                 default = nil)
  if valid_613957 != nil:
    section.add "X-Amz-Content-Sha256", valid_613957
  var valid_613958 = header.getOrDefault("X-Amz-Date")
  valid_613958 = validateParameter(valid_613958, JString, required = false,
                                 default = nil)
  if valid_613958 != nil:
    section.add "X-Amz-Date", valid_613958
  var valid_613959 = header.getOrDefault("X-Amz-Credential")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "X-Amz-Credential", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Security-Token")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Security-Token", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-Algorithm")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Algorithm", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-SignedHeaders", valid_613962
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_613963 = formData.getOrDefault("ResourceArns")
  valid_613963 = validateParameter(valid_613963, JArray, required = true, default = nil)
  if valid_613963 != nil:
    section.add "ResourceArns", valid_613963
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613964: Call_PostDescribeTags_613951; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_613964.validator(path, query, header, formData, body)
  let scheme = call_613964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613964.url(scheme.get, call_613964.host, call_613964.base,
                         call_613964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613964, url, valid)

proc call*(call_613965: Call_PostDescribeTags_613951; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613966 = newJObject()
  var formData_613967 = newJObject()
  if ResourceArns != nil:
    formData_613967.add "ResourceArns", ResourceArns
  add(query_613966, "Action", newJString(Action))
  add(query_613966, "Version", newJString(Version))
  result = call_613965.call(nil, query_613966, nil, formData_613967, nil)

var postDescribeTags* = Call_PostDescribeTags_613951(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_613952,
    base: "/", url: url_PostDescribeTags_613953,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_613935 = ref object of OpenApiRestCall_612658
proc url_GetDescribeTags_613937(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeTags_613936(path: JsonNode; query: JsonNode;
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
  var valid_613938 = query.getOrDefault("ResourceArns")
  valid_613938 = validateParameter(valid_613938, JArray, required = true, default = nil)
  if valid_613938 != nil:
    section.add "ResourceArns", valid_613938
  var valid_613939 = query.getOrDefault("Action")
  valid_613939 = validateParameter(valid_613939, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_613939 != nil:
    section.add "Action", valid_613939
  var valid_613940 = query.getOrDefault("Version")
  valid_613940 = validateParameter(valid_613940, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613940 != nil:
    section.add "Version", valid_613940
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613941 = header.getOrDefault("X-Amz-Signature")
  valid_613941 = validateParameter(valid_613941, JString, required = false,
                                 default = nil)
  if valid_613941 != nil:
    section.add "X-Amz-Signature", valid_613941
  var valid_613942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613942 = validateParameter(valid_613942, JString, required = false,
                                 default = nil)
  if valid_613942 != nil:
    section.add "X-Amz-Content-Sha256", valid_613942
  var valid_613943 = header.getOrDefault("X-Amz-Date")
  valid_613943 = validateParameter(valid_613943, JString, required = false,
                                 default = nil)
  if valid_613943 != nil:
    section.add "X-Amz-Date", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-Credential")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Credential", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Security-Token")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Security-Token", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Algorithm")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Algorithm", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-SignedHeaders", valid_613947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613948: Call_GetDescribeTags_613935; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_613948.validator(path, query, header, formData, body)
  let scheme = call_613948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613948.url(scheme.get, call_613948.host, call_613948.base,
                         call_613948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613948, url, valid)

proc call*(call_613949: Call_GetDescribeTags_613935; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613950 = newJObject()
  if ResourceArns != nil:
    query_613950.add "ResourceArns", ResourceArns
  add(query_613950, "Action", newJString(Action))
  add(query_613950, "Version", newJString(Version))
  result = call_613949.call(nil, query_613950, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_613935(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_613936,
    base: "/", url: url_GetDescribeTags_613937, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroupAttributes_613984 = ref object of OpenApiRestCall_612658
proc url_PostDescribeTargetGroupAttributes_613986(protocol: Scheme; host: string;
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

proc validate_PostDescribeTargetGroupAttributes_613985(path: JsonNode;
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
  var valid_613987 = query.getOrDefault("Action")
  valid_613987 = validateParameter(valid_613987, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_613987 != nil:
    section.add "Action", valid_613987
  var valid_613988 = query.getOrDefault("Version")
  valid_613988 = validateParameter(valid_613988, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613988 != nil:
    section.add "Version", valid_613988
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613989 = header.getOrDefault("X-Amz-Signature")
  valid_613989 = validateParameter(valid_613989, JString, required = false,
                                 default = nil)
  if valid_613989 != nil:
    section.add "X-Amz-Signature", valid_613989
  var valid_613990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613990 = validateParameter(valid_613990, JString, required = false,
                                 default = nil)
  if valid_613990 != nil:
    section.add "X-Amz-Content-Sha256", valid_613990
  var valid_613991 = header.getOrDefault("X-Amz-Date")
  valid_613991 = validateParameter(valid_613991, JString, required = false,
                                 default = nil)
  if valid_613991 != nil:
    section.add "X-Amz-Date", valid_613991
  var valid_613992 = header.getOrDefault("X-Amz-Credential")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-Credential", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-Security-Token")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Security-Token", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Algorithm")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Algorithm", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-SignedHeaders", valid_613995
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_613996 = formData.getOrDefault("TargetGroupArn")
  valid_613996 = validateParameter(valid_613996, JString, required = true,
                                 default = nil)
  if valid_613996 != nil:
    section.add "TargetGroupArn", valid_613996
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613997: Call_PostDescribeTargetGroupAttributes_613984;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613997.validator(path, query, header, formData, body)
  let scheme = call_613997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613997.url(scheme.get, call_613997.host, call_613997.base,
                         call_613997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613997, url, valid)

proc call*(call_613998: Call_PostDescribeTargetGroupAttributes_613984;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_613999 = newJObject()
  var formData_614000 = newJObject()
  add(query_613999, "Action", newJString(Action))
  add(formData_614000, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_613999, "Version", newJString(Version))
  result = call_613998.call(nil, query_613999, nil, formData_614000, nil)

var postDescribeTargetGroupAttributes* = Call_PostDescribeTargetGroupAttributes_613984(
    name: "postDescribeTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_PostDescribeTargetGroupAttributes_613985, base: "/",
    url: url_PostDescribeTargetGroupAttributes_613986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroupAttributes_613968 = ref object of OpenApiRestCall_612658
proc url_GetDescribeTargetGroupAttributes_613970(protocol: Scheme; host: string;
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

proc validate_GetDescribeTargetGroupAttributes_613969(path: JsonNode;
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
  var valid_613971 = query.getOrDefault("TargetGroupArn")
  valid_613971 = validateParameter(valid_613971, JString, required = true,
                                 default = nil)
  if valid_613971 != nil:
    section.add "TargetGroupArn", valid_613971
  var valid_613972 = query.getOrDefault("Action")
  valid_613972 = validateParameter(valid_613972, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_613972 != nil:
    section.add "Action", valid_613972
  var valid_613973 = query.getOrDefault("Version")
  valid_613973 = validateParameter(valid_613973, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_613973 != nil:
    section.add "Version", valid_613973
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613974 = header.getOrDefault("X-Amz-Signature")
  valid_613974 = validateParameter(valid_613974, JString, required = false,
                                 default = nil)
  if valid_613974 != nil:
    section.add "X-Amz-Signature", valid_613974
  var valid_613975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613975 = validateParameter(valid_613975, JString, required = false,
                                 default = nil)
  if valid_613975 != nil:
    section.add "X-Amz-Content-Sha256", valid_613975
  var valid_613976 = header.getOrDefault("X-Amz-Date")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "X-Amz-Date", valid_613976
  var valid_613977 = header.getOrDefault("X-Amz-Credential")
  valid_613977 = validateParameter(valid_613977, JString, required = false,
                                 default = nil)
  if valid_613977 != nil:
    section.add "X-Amz-Credential", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-Security-Token")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Security-Token", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-Algorithm")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-Algorithm", valid_613979
  var valid_613980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "X-Amz-SignedHeaders", valid_613980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613981: Call_GetDescribeTargetGroupAttributes_613968;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613981.validator(path, query, header, formData, body)
  let scheme = call_613981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613981.url(scheme.get, call_613981.host, call_613981.base,
                         call_613981.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613981, url, valid)

proc call*(call_613982: Call_GetDescribeTargetGroupAttributes_613968;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613983 = newJObject()
  add(query_613983, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_613983, "Action", newJString(Action))
  add(query_613983, "Version", newJString(Version))
  result = call_613982.call(nil, query_613983, nil, nil, nil)

var getDescribeTargetGroupAttributes* = Call_GetDescribeTargetGroupAttributes_613968(
    name: "getDescribeTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_GetDescribeTargetGroupAttributes_613969, base: "/",
    url: url_GetDescribeTargetGroupAttributes_613970,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroups_614021 = ref object of OpenApiRestCall_612658
proc url_PostDescribeTargetGroups_614023(protocol: Scheme; host: string;
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

proc validate_PostDescribeTargetGroups_614022(path: JsonNode; query: JsonNode;
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
  var valid_614024 = query.getOrDefault("Action")
  valid_614024 = validateParameter(valid_614024, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_614024 != nil:
    section.add "Action", valid_614024
  var valid_614025 = query.getOrDefault("Version")
  valid_614025 = validateParameter(valid_614025, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614025 != nil:
    section.add "Version", valid_614025
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614026 = header.getOrDefault("X-Amz-Signature")
  valid_614026 = validateParameter(valid_614026, JString, required = false,
                                 default = nil)
  if valid_614026 != nil:
    section.add "X-Amz-Signature", valid_614026
  var valid_614027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614027 = validateParameter(valid_614027, JString, required = false,
                                 default = nil)
  if valid_614027 != nil:
    section.add "X-Amz-Content-Sha256", valid_614027
  var valid_614028 = header.getOrDefault("X-Amz-Date")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-Date", valid_614028
  var valid_614029 = header.getOrDefault("X-Amz-Credential")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "X-Amz-Credential", valid_614029
  var valid_614030 = header.getOrDefault("X-Amz-Security-Token")
  valid_614030 = validateParameter(valid_614030, JString, required = false,
                                 default = nil)
  if valid_614030 != nil:
    section.add "X-Amz-Security-Token", valid_614030
  var valid_614031 = header.getOrDefault("X-Amz-Algorithm")
  valid_614031 = validateParameter(valid_614031, JString, required = false,
                                 default = nil)
  if valid_614031 != nil:
    section.add "X-Amz-Algorithm", valid_614031
  var valid_614032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614032 = validateParameter(valid_614032, JString, required = false,
                                 default = nil)
  if valid_614032 != nil:
    section.add "X-Amz-SignedHeaders", valid_614032
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
  var valid_614033 = formData.getOrDefault("Names")
  valid_614033 = validateParameter(valid_614033, JArray, required = false,
                                 default = nil)
  if valid_614033 != nil:
    section.add "Names", valid_614033
  var valid_614034 = formData.getOrDefault("Marker")
  valid_614034 = validateParameter(valid_614034, JString, required = false,
                                 default = nil)
  if valid_614034 != nil:
    section.add "Marker", valid_614034
  var valid_614035 = formData.getOrDefault("TargetGroupArns")
  valid_614035 = validateParameter(valid_614035, JArray, required = false,
                                 default = nil)
  if valid_614035 != nil:
    section.add "TargetGroupArns", valid_614035
  var valid_614036 = formData.getOrDefault("PageSize")
  valid_614036 = validateParameter(valid_614036, JInt, required = false, default = nil)
  if valid_614036 != nil:
    section.add "PageSize", valid_614036
  var valid_614037 = formData.getOrDefault("LoadBalancerArn")
  valid_614037 = validateParameter(valid_614037, JString, required = false,
                                 default = nil)
  if valid_614037 != nil:
    section.add "LoadBalancerArn", valid_614037
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614038: Call_PostDescribeTargetGroups_614021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_614038.validator(path, query, header, formData, body)
  let scheme = call_614038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614038.url(scheme.get, call_614038.host, call_614038.base,
                         call_614038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614038, url, valid)

proc call*(call_614039: Call_PostDescribeTargetGroups_614021;
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
  var query_614040 = newJObject()
  var formData_614041 = newJObject()
  if Names != nil:
    formData_614041.add "Names", Names
  add(formData_614041, "Marker", newJString(Marker))
  add(query_614040, "Action", newJString(Action))
  if TargetGroupArns != nil:
    formData_614041.add "TargetGroupArns", TargetGroupArns
  add(formData_614041, "PageSize", newJInt(PageSize))
  add(query_614040, "Version", newJString(Version))
  add(formData_614041, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_614039.call(nil, query_614040, nil, formData_614041, nil)

var postDescribeTargetGroups* = Call_PostDescribeTargetGroups_614021(
    name: "postDescribeTargetGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_PostDescribeTargetGroups_614022, base: "/",
    url: url_PostDescribeTargetGroups_614023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroups_614001 = ref object of OpenApiRestCall_612658
proc url_GetDescribeTargetGroups_614003(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeTargetGroups_614002(path: JsonNode; query: JsonNode;
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
  var valid_614004 = query.getOrDefault("Marker")
  valid_614004 = validateParameter(valid_614004, JString, required = false,
                                 default = nil)
  if valid_614004 != nil:
    section.add "Marker", valid_614004
  var valid_614005 = query.getOrDefault("LoadBalancerArn")
  valid_614005 = validateParameter(valid_614005, JString, required = false,
                                 default = nil)
  if valid_614005 != nil:
    section.add "LoadBalancerArn", valid_614005
  var valid_614006 = query.getOrDefault("PageSize")
  valid_614006 = validateParameter(valid_614006, JInt, required = false, default = nil)
  if valid_614006 != nil:
    section.add "PageSize", valid_614006
  var valid_614007 = query.getOrDefault("Action")
  valid_614007 = validateParameter(valid_614007, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_614007 != nil:
    section.add "Action", valid_614007
  var valid_614008 = query.getOrDefault("TargetGroupArns")
  valid_614008 = validateParameter(valid_614008, JArray, required = false,
                                 default = nil)
  if valid_614008 != nil:
    section.add "TargetGroupArns", valid_614008
  var valid_614009 = query.getOrDefault("Version")
  valid_614009 = validateParameter(valid_614009, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614009 != nil:
    section.add "Version", valid_614009
  var valid_614010 = query.getOrDefault("Names")
  valid_614010 = validateParameter(valid_614010, JArray, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "Names", valid_614010
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614011 = header.getOrDefault("X-Amz-Signature")
  valid_614011 = validateParameter(valid_614011, JString, required = false,
                                 default = nil)
  if valid_614011 != nil:
    section.add "X-Amz-Signature", valid_614011
  var valid_614012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614012 = validateParameter(valid_614012, JString, required = false,
                                 default = nil)
  if valid_614012 != nil:
    section.add "X-Amz-Content-Sha256", valid_614012
  var valid_614013 = header.getOrDefault("X-Amz-Date")
  valid_614013 = validateParameter(valid_614013, JString, required = false,
                                 default = nil)
  if valid_614013 != nil:
    section.add "X-Amz-Date", valid_614013
  var valid_614014 = header.getOrDefault("X-Amz-Credential")
  valid_614014 = validateParameter(valid_614014, JString, required = false,
                                 default = nil)
  if valid_614014 != nil:
    section.add "X-Amz-Credential", valid_614014
  var valid_614015 = header.getOrDefault("X-Amz-Security-Token")
  valid_614015 = validateParameter(valid_614015, JString, required = false,
                                 default = nil)
  if valid_614015 != nil:
    section.add "X-Amz-Security-Token", valid_614015
  var valid_614016 = header.getOrDefault("X-Amz-Algorithm")
  valid_614016 = validateParameter(valid_614016, JString, required = false,
                                 default = nil)
  if valid_614016 != nil:
    section.add "X-Amz-Algorithm", valid_614016
  var valid_614017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614017 = validateParameter(valid_614017, JString, required = false,
                                 default = nil)
  if valid_614017 != nil:
    section.add "X-Amz-SignedHeaders", valid_614017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614018: Call_GetDescribeTargetGroups_614001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_614018.validator(path, query, header, formData, body)
  let scheme = call_614018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614018.url(scheme.get, call_614018.host, call_614018.base,
                         call_614018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614018, url, valid)

proc call*(call_614019: Call_GetDescribeTargetGroups_614001; Marker: string = "";
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
  var query_614020 = newJObject()
  add(query_614020, "Marker", newJString(Marker))
  add(query_614020, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_614020, "PageSize", newJInt(PageSize))
  add(query_614020, "Action", newJString(Action))
  if TargetGroupArns != nil:
    query_614020.add "TargetGroupArns", TargetGroupArns
  add(query_614020, "Version", newJString(Version))
  if Names != nil:
    query_614020.add "Names", Names
  result = call_614019.call(nil, query_614020, nil, nil, nil)

var getDescribeTargetGroups* = Call_GetDescribeTargetGroups_614001(
    name: "getDescribeTargetGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_GetDescribeTargetGroups_614002, base: "/",
    url: url_GetDescribeTargetGroups_614003, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetHealth_614059 = ref object of OpenApiRestCall_612658
proc url_PostDescribeTargetHealth_614061(protocol: Scheme; host: string;
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

proc validate_PostDescribeTargetHealth_614060(path: JsonNode; query: JsonNode;
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
  var valid_614062 = query.getOrDefault("Action")
  valid_614062 = validateParameter(valid_614062, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_614062 != nil:
    section.add "Action", valid_614062
  var valid_614063 = query.getOrDefault("Version")
  valid_614063 = validateParameter(valid_614063, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614063 != nil:
    section.add "Version", valid_614063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614064 = header.getOrDefault("X-Amz-Signature")
  valid_614064 = validateParameter(valid_614064, JString, required = false,
                                 default = nil)
  if valid_614064 != nil:
    section.add "X-Amz-Signature", valid_614064
  var valid_614065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614065 = validateParameter(valid_614065, JString, required = false,
                                 default = nil)
  if valid_614065 != nil:
    section.add "X-Amz-Content-Sha256", valid_614065
  var valid_614066 = header.getOrDefault("X-Amz-Date")
  valid_614066 = validateParameter(valid_614066, JString, required = false,
                                 default = nil)
  if valid_614066 != nil:
    section.add "X-Amz-Date", valid_614066
  var valid_614067 = header.getOrDefault("X-Amz-Credential")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "X-Amz-Credential", valid_614067
  var valid_614068 = header.getOrDefault("X-Amz-Security-Token")
  valid_614068 = validateParameter(valid_614068, JString, required = false,
                                 default = nil)
  if valid_614068 != nil:
    section.add "X-Amz-Security-Token", valid_614068
  var valid_614069 = header.getOrDefault("X-Amz-Algorithm")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "X-Amz-Algorithm", valid_614069
  var valid_614070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614070 = validateParameter(valid_614070, JString, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "X-Amz-SignedHeaders", valid_614070
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_614071 = formData.getOrDefault("Targets")
  valid_614071 = validateParameter(valid_614071, JArray, required = false,
                                 default = nil)
  if valid_614071 != nil:
    section.add "Targets", valid_614071
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_614072 = formData.getOrDefault("TargetGroupArn")
  valid_614072 = validateParameter(valid_614072, JString, required = true,
                                 default = nil)
  if valid_614072 != nil:
    section.add "TargetGroupArn", valid_614072
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614073: Call_PostDescribeTargetHealth_614059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_614073.validator(path, query, header, formData, body)
  let scheme = call_614073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614073.url(scheme.get, call_614073.host, call_614073.base,
                         call_614073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614073, url, valid)

proc call*(call_614074: Call_PostDescribeTargetHealth_614059;
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
  var query_614075 = newJObject()
  var formData_614076 = newJObject()
  if Targets != nil:
    formData_614076.add "Targets", Targets
  add(query_614075, "Action", newJString(Action))
  add(formData_614076, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_614075, "Version", newJString(Version))
  result = call_614074.call(nil, query_614075, nil, formData_614076, nil)

var postDescribeTargetHealth* = Call_PostDescribeTargetHealth_614059(
    name: "postDescribeTargetHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_PostDescribeTargetHealth_614060, base: "/",
    url: url_PostDescribeTargetHealth_614061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetHealth_614042 = ref object of OpenApiRestCall_612658
proc url_GetDescribeTargetHealth_614044(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeTargetHealth_614043(path: JsonNode; query: JsonNode;
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
  var valid_614045 = query.getOrDefault("Targets")
  valid_614045 = validateParameter(valid_614045, JArray, required = false,
                                 default = nil)
  if valid_614045 != nil:
    section.add "Targets", valid_614045
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_614046 = query.getOrDefault("TargetGroupArn")
  valid_614046 = validateParameter(valid_614046, JString, required = true,
                                 default = nil)
  if valid_614046 != nil:
    section.add "TargetGroupArn", valid_614046
  var valid_614047 = query.getOrDefault("Action")
  valid_614047 = validateParameter(valid_614047, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_614047 != nil:
    section.add "Action", valid_614047
  var valid_614048 = query.getOrDefault("Version")
  valid_614048 = validateParameter(valid_614048, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614048 != nil:
    section.add "Version", valid_614048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614049 = header.getOrDefault("X-Amz-Signature")
  valid_614049 = validateParameter(valid_614049, JString, required = false,
                                 default = nil)
  if valid_614049 != nil:
    section.add "X-Amz-Signature", valid_614049
  var valid_614050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614050 = validateParameter(valid_614050, JString, required = false,
                                 default = nil)
  if valid_614050 != nil:
    section.add "X-Amz-Content-Sha256", valid_614050
  var valid_614051 = header.getOrDefault("X-Amz-Date")
  valid_614051 = validateParameter(valid_614051, JString, required = false,
                                 default = nil)
  if valid_614051 != nil:
    section.add "X-Amz-Date", valid_614051
  var valid_614052 = header.getOrDefault("X-Amz-Credential")
  valid_614052 = validateParameter(valid_614052, JString, required = false,
                                 default = nil)
  if valid_614052 != nil:
    section.add "X-Amz-Credential", valid_614052
  var valid_614053 = header.getOrDefault("X-Amz-Security-Token")
  valid_614053 = validateParameter(valid_614053, JString, required = false,
                                 default = nil)
  if valid_614053 != nil:
    section.add "X-Amz-Security-Token", valid_614053
  var valid_614054 = header.getOrDefault("X-Amz-Algorithm")
  valid_614054 = validateParameter(valid_614054, JString, required = false,
                                 default = nil)
  if valid_614054 != nil:
    section.add "X-Amz-Algorithm", valid_614054
  var valid_614055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "X-Amz-SignedHeaders", valid_614055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614056: Call_GetDescribeTargetHealth_614042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_614056.validator(path, query, header, formData, body)
  let scheme = call_614056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614056.url(scheme.get, call_614056.host, call_614056.base,
                         call_614056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614056, url, valid)

proc call*(call_614057: Call_GetDescribeTargetHealth_614042;
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
  var query_614058 = newJObject()
  if Targets != nil:
    query_614058.add "Targets", Targets
  add(query_614058, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_614058, "Action", newJString(Action))
  add(query_614058, "Version", newJString(Version))
  result = call_614057.call(nil, query_614058, nil, nil, nil)

var getDescribeTargetHealth* = Call_GetDescribeTargetHealth_614042(
    name: "getDescribeTargetHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_GetDescribeTargetHealth_614043, base: "/",
    url: url_GetDescribeTargetHealth_614044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyListener_614098 = ref object of OpenApiRestCall_612658
proc url_PostModifyListener_614100(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyListener_614099(path: JsonNode; query: JsonNode;
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
  var valid_614101 = query.getOrDefault("Action")
  valid_614101 = validateParameter(valid_614101, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_614101 != nil:
    section.add "Action", valid_614101
  var valid_614102 = query.getOrDefault("Version")
  valid_614102 = validateParameter(valid_614102, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614102 != nil:
    section.add "Version", valid_614102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614103 = header.getOrDefault("X-Amz-Signature")
  valid_614103 = validateParameter(valid_614103, JString, required = false,
                                 default = nil)
  if valid_614103 != nil:
    section.add "X-Amz-Signature", valid_614103
  var valid_614104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614104 = validateParameter(valid_614104, JString, required = false,
                                 default = nil)
  if valid_614104 != nil:
    section.add "X-Amz-Content-Sha256", valid_614104
  var valid_614105 = header.getOrDefault("X-Amz-Date")
  valid_614105 = validateParameter(valid_614105, JString, required = false,
                                 default = nil)
  if valid_614105 != nil:
    section.add "X-Amz-Date", valid_614105
  var valid_614106 = header.getOrDefault("X-Amz-Credential")
  valid_614106 = validateParameter(valid_614106, JString, required = false,
                                 default = nil)
  if valid_614106 != nil:
    section.add "X-Amz-Credential", valid_614106
  var valid_614107 = header.getOrDefault("X-Amz-Security-Token")
  valid_614107 = validateParameter(valid_614107, JString, required = false,
                                 default = nil)
  if valid_614107 != nil:
    section.add "X-Amz-Security-Token", valid_614107
  var valid_614108 = header.getOrDefault("X-Amz-Algorithm")
  valid_614108 = validateParameter(valid_614108, JString, required = false,
                                 default = nil)
  if valid_614108 != nil:
    section.add "X-Amz-Algorithm", valid_614108
  var valid_614109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "X-Amz-SignedHeaders", valid_614109
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
  var valid_614110 = formData.getOrDefault("Port")
  valid_614110 = validateParameter(valid_614110, JInt, required = false, default = nil)
  if valid_614110 != nil:
    section.add "Port", valid_614110
  var valid_614111 = formData.getOrDefault("Certificates")
  valid_614111 = validateParameter(valid_614111, JArray, required = false,
                                 default = nil)
  if valid_614111 != nil:
    section.add "Certificates", valid_614111
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_614112 = formData.getOrDefault("ListenerArn")
  valid_614112 = validateParameter(valid_614112, JString, required = true,
                                 default = nil)
  if valid_614112 != nil:
    section.add "ListenerArn", valid_614112
  var valid_614113 = formData.getOrDefault("DefaultActions")
  valid_614113 = validateParameter(valid_614113, JArray, required = false,
                                 default = nil)
  if valid_614113 != nil:
    section.add "DefaultActions", valid_614113
  var valid_614114 = formData.getOrDefault("Protocol")
  valid_614114 = validateParameter(valid_614114, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_614114 != nil:
    section.add "Protocol", valid_614114
  var valid_614115 = formData.getOrDefault("SslPolicy")
  valid_614115 = validateParameter(valid_614115, JString, required = false,
                                 default = nil)
  if valid_614115 != nil:
    section.add "SslPolicy", valid_614115
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614116: Call_PostModifyListener_614098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ## 
  let valid = call_614116.validator(path, query, header, formData, body)
  let scheme = call_614116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614116.url(scheme.get, call_614116.host, call_614116.base,
                         call_614116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614116, url, valid)

proc call*(call_614117: Call_PostModifyListener_614098; ListenerArn: string;
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
  var query_614118 = newJObject()
  var formData_614119 = newJObject()
  add(formData_614119, "Port", newJInt(Port))
  if Certificates != nil:
    formData_614119.add "Certificates", Certificates
  add(formData_614119, "ListenerArn", newJString(ListenerArn))
  if DefaultActions != nil:
    formData_614119.add "DefaultActions", DefaultActions
  add(formData_614119, "Protocol", newJString(Protocol))
  add(query_614118, "Action", newJString(Action))
  add(formData_614119, "SslPolicy", newJString(SslPolicy))
  add(query_614118, "Version", newJString(Version))
  result = call_614117.call(nil, query_614118, nil, formData_614119, nil)

var postModifyListener* = Call_PostModifyListener_614098(
    name: "postModifyListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=ModifyListener",
    validator: validate_PostModifyListener_614099, base: "/",
    url: url_PostModifyListener_614100, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyListener_614077 = ref object of OpenApiRestCall_612658
proc url_GetModifyListener_614079(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyListener_614078(path: JsonNode; query: JsonNode;
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
  var valid_614080 = query.getOrDefault("SslPolicy")
  valid_614080 = validateParameter(valid_614080, JString, required = false,
                                 default = nil)
  if valid_614080 != nil:
    section.add "SslPolicy", valid_614080
  assert query != nil,
        "query argument is necessary due to required `ListenerArn` field"
  var valid_614081 = query.getOrDefault("ListenerArn")
  valid_614081 = validateParameter(valid_614081, JString, required = true,
                                 default = nil)
  if valid_614081 != nil:
    section.add "ListenerArn", valid_614081
  var valid_614082 = query.getOrDefault("Certificates")
  valid_614082 = validateParameter(valid_614082, JArray, required = false,
                                 default = nil)
  if valid_614082 != nil:
    section.add "Certificates", valid_614082
  var valid_614083 = query.getOrDefault("DefaultActions")
  valid_614083 = validateParameter(valid_614083, JArray, required = false,
                                 default = nil)
  if valid_614083 != nil:
    section.add "DefaultActions", valid_614083
  var valid_614084 = query.getOrDefault("Action")
  valid_614084 = validateParameter(valid_614084, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_614084 != nil:
    section.add "Action", valid_614084
  var valid_614085 = query.getOrDefault("Port")
  valid_614085 = validateParameter(valid_614085, JInt, required = false, default = nil)
  if valid_614085 != nil:
    section.add "Port", valid_614085
  var valid_614086 = query.getOrDefault("Protocol")
  valid_614086 = validateParameter(valid_614086, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_614086 != nil:
    section.add "Protocol", valid_614086
  var valid_614087 = query.getOrDefault("Version")
  valid_614087 = validateParameter(valid_614087, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614087 != nil:
    section.add "Version", valid_614087
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614088 = header.getOrDefault("X-Amz-Signature")
  valid_614088 = validateParameter(valid_614088, JString, required = false,
                                 default = nil)
  if valid_614088 != nil:
    section.add "X-Amz-Signature", valid_614088
  var valid_614089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "X-Amz-Content-Sha256", valid_614089
  var valid_614090 = header.getOrDefault("X-Amz-Date")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "X-Amz-Date", valid_614090
  var valid_614091 = header.getOrDefault("X-Amz-Credential")
  valid_614091 = validateParameter(valid_614091, JString, required = false,
                                 default = nil)
  if valid_614091 != nil:
    section.add "X-Amz-Credential", valid_614091
  var valid_614092 = header.getOrDefault("X-Amz-Security-Token")
  valid_614092 = validateParameter(valid_614092, JString, required = false,
                                 default = nil)
  if valid_614092 != nil:
    section.add "X-Amz-Security-Token", valid_614092
  var valid_614093 = header.getOrDefault("X-Amz-Algorithm")
  valid_614093 = validateParameter(valid_614093, JString, required = false,
                                 default = nil)
  if valid_614093 != nil:
    section.add "X-Amz-Algorithm", valid_614093
  var valid_614094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614094 = validateParameter(valid_614094, JString, required = false,
                                 default = nil)
  if valid_614094 != nil:
    section.add "X-Amz-SignedHeaders", valid_614094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614095: Call_GetModifyListener_614077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified listener. Any properties that you do not specify remain unchanged.</p> <p>Changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p>
  ## 
  let valid = call_614095.validator(path, query, header, formData, body)
  let scheme = call_614095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614095.url(scheme.get, call_614095.host, call_614095.base,
                         call_614095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614095, url, valid)

proc call*(call_614096: Call_GetModifyListener_614077; ListenerArn: string;
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
  var query_614097 = newJObject()
  add(query_614097, "SslPolicy", newJString(SslPolicy))
  add(query_614097, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_614097.add "Certificates", Certificates
  if DefaultActions != nil:
    query_614097.add "DefaultActions", DefaultActions
  add(query_614097, "Action", newJString(Action))
  add(query_614097, "Port", newJInt(Port))
  add(query_614097, "Protocol", newJString(Protocol))
  add(query_614097, "Version", newJString(Version))
  result = call_614096.call(nil, query_614097, nil, nil, nil)

var getModifyListener* = Call_GetModifyListener_614077(name: "getModifyListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyListener", validator: validate_GetModifyListener_614078,
    base: "/", url: url_GetModifyListener_614079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_614137 = ref object of OpenApiRestCall_612658
proc url_PostModifyLoadBalancerAttributes_614139(protocol: Scheme; host: string;
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

proc validate_PostModifyLoadBalancerAttributes_614138(path: JsonNode;
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
  var valid_614140 = query.getOrDefault("Action")
  valid_614140 = validateParameter(valid_614140, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_614140 != nil:
    section.add "Action", valid_614140
  var valid_614141 = query.getOrDefault("Version")
  valid_614141 = validateParameter(valid_614141, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614141 != nil:
    section.add "Version", valid_614141
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614142 = header.getOrDefault("X-Amz-Signature")
  valid_614142 = validateParameter(valid_614142, JString, required = false,
                                 default = nil)
  if valid_614142 != nil:
    section.add "X-Amz-Signature", valid_614142
  var valid_614143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614143 = validateParameter(valid_614143, JString, required = false,
                                 default = nil)
  if valid_614143 != nil:
    section.add "X-Amz-Content-Sha256", valid_614143
  var valid_614144 = header.getOrDefault("X-Amz-Date")
  valid_614144 = validateParameter(valid_614144, JString, required = false,
                                 default = nil)
  if valid_614144 != nil:
    section.add "X-Amz-Date", valid_614144
  var valid_614145 = header.getOrDefault("X-Amz-Credential")
  valid_614145 = validateParameter(valid_614145, JString, required = false,
                                 default = nil)
  if valid_614145 != nil:
    section.add "X-Amz-Credential", valid_614145
  var valid_614146 = header.getOrDefault("X-Amz-Security-Token")
  valid_614146 = validateParameter(valid_614146, JString, required = false,
                                 default = nil)
  if valid_614146 != nil:
    section.add "X-Amz-Security-Token", valid_614146
  var valid_614147 = header.getOrDefault("X-Amz-Algorithm")
  valid_614147 = validateParameter(valid_614147, JString, required = false,
                                 default = nil)
  if valid_614147 != nil:
    section.add "X-Amz-Algorithm", valid_614147
  var valid_614148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614148 = validateParameter(valid_614148, JString, required = false,
                                 default = nil)
  if valid_614148 != nil:
    section.add "X-Amz-SignedHeaders", valid_614148
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_614149 = formData.getOrDefault("Attributes")
  valid_614149 = validateParameter(valid_614149, JArray, required = true, default = nil)
  if valid_614149 != nil:
    section.add "Attributes", valid_614149
  var valid_614150 = formData.getOrDefault("LoadBalancerArn")
  valid_614150 = validateParameter(valid_614150, JString, required = true,
                                 default = nil)
  if valid_614150 != nil:
    section.add "LoadBalancerArn", valid_614150
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614151: Call_PostModifyLoadBalancerAttributes_614137;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_614151.validator(path, query, header, formData, body)
  let scheme = call_614151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614151.url(scheme.get, call_614151.host, call_614151.base,
                         call_614151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614151, url, valid)

proc call*(call_614152: Call_PostModifyLoadBalancerAttributes_614137;
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
  var query_614153 = newJObject()
  var formData_614154 = newJObject()
  if Attributes != nil:
    formData_614154.add "Attributes", Attributes
  add(query_614153, "Action", newJString(Action))
  add(query_614153, "Version", newJString(Version))
  add(formData_614154, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_614152.call(nil, query_614153, nil, formData_614154, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_614137(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_614138, base: "/",
    url: url_PostModifyLoadBalancerAttributes_614139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_614120 = ref object of OpenApiRestCall_612658
proc url_GetModifyLoadBalancerAttributes_614122(protocol: Scheme; host: string;
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

proc validate_GetModifyLoadBalancerAttributes_614121(path: JsonNode;
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
  var valid_614123 = query.getOrDefault("LoadBalancerArn")
  valid_614123 = validateParameter(valid_614123, JString, required = true,
                                 default = nil)
  if valid_614123 != nil:
    section.add "LoadBalancerArn", valid_614123
  var valid_614124 = query.getOrDefault("Attributes")
  valid_614124 = validateParameter(valid_614124, JArray, required = true, default = nil)
  if valid_614124 != nil:
    section.add "Attributes", valid_614124
  var valid_614125 = query.getOrDefault("Action")
  valid_614125 = validateParameter(valid_614125, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_614125 != nil:
    section.add "Action", valid_614125
  var valid_614126 = query.getOrDefault("Version")
  valid_614126 = validateParameter(valid_614126, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614126 != nil:
    section.add "Version", valid_614126
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614127 = header.getOrDefault("X-Amz-Signature")
  valid_614127 = validateParameter(valid_614127, JString, required = false,
                                 default = nil)
  if valid_614127 != nil:
    section.add "X-Amz-Signature", valid_614127
  var valid_614128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614128 = validateParameter(valid_614128, JString, required = false,
                                 default = nil)
  if valid_614128 != nil:
    section.add "X-Amz-Content-Sha256", valid_614128
  var valid_614129 = header.getOrDefault("X-Amz-Date")
  valid_614129 = validateParameter(valid_614129, JString, required = false,
                                 default = nil)
  if valid_614129 != nil:
    section.add "X-Amz-Date", valid_614129
  var valid_614130 = header.getOrDefault("X-Amz-Credential")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "X-Amz-Credential", valid_614130
  var valid_614131 = header.getOrDefault("X-Amz-Security-Token")
  valid_614131 = validateParameter(valid_614131, JString, required = false,
                                 default = nil)
  if valid_614131 != nil:
    section.add "X-Amz-Security-Token", valid_614131
  var valid_614132 = header.getOrDefault("X-Amz-Algorithm")
  valid_614132 = validateParameter(valid_614132, JString, required = false,
                                 default = nil)
  if valid_614132 != nil:
    section.add "X-Amz-Algorithm", valid_614132
  var valid_614133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614133 = validateParameter(valid_614133, JString, required = false,
                                 default = nil)
  if valid_614133 != nil:
    section.add "X-Amz-SignedHeaders", valid_614133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614134: Call_GetModifyLoadBalancerAttributes_614120;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_614134.validator(path, query, header, formData, body)
  let scheme = call_614134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614134.url(scheme.get, call_614134.host, call_614134.base,
                         call_614134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614134, url, valid)

proc call*(call_614135: Call_GetModifyLoadBalancerAttributes_614120;
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
  var query_614136 = newJObject()
  add(query_614136, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Attributes != nil:
    query_614136.add "Attributes", Attributes
  add(query_614136, "Action", newJString(Action))
  add(query_614136, "Version", newJString(Version))
  result = call_614135.call(nil, query_614136, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_614120(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_614121, base: "/",
    url: url_GetModifyLoadBalancerAttributes_614122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyRule_614173 = ref object of OpenApiRestCall_612658
proc url_PostModifyRule_614175(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyRule_614174(path: JsonNode; query: JsonNode;
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
  var valid_614176 = query.getOrDefault("Action")
  valid_614176 = validateParameter(valid_614176, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_614176 != nil:
    section.add "Action", valid_614176
  var valid_614177 = query.getOrDefault("Version")
  valid_614177 = validateParameter(valid_614177, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614177 != nil:
    section.add "Version", valid_614177
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614178 = header.getOrDefault("X-Amz-Signature")
  valid_614178 = validateParameter(valid_614178, JString, required = false,
                                 default = nil)
  if valid_614178 != nil:
    section.add "X-Amz-Signature", valid_614178
  var valid_614179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614179 = validateParameter(valid_614179, JString, required = false,
                                 default = nil)
  if valid_614179 != nil:
    section.add "X-Amz-Content-Sha256", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-Date")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-Date", valid_614180
  var valid_614181 = header.getOrDefault("X-Amz-Credential")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "X-Amz-Credential", valid_614181
  var valid_614182 = header.getOrDefault("X-Amz-Security-Token")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-Security-Token", valid_614182
  var valid_614183 = header.getOrDefault("X-Amz-Algorithm")
  valid_614183 = validateParameter(valid_614183, JString, required = false,
                                 default = nil)
  if valid_614183 != nil:
    section.add "X-Amz-Algorithm", valid_614183
  var valid_614184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614184 = validateParameter(valid_614184, JString, required = false,
                                 default = nil)
  if valid_614184 != nil:
    section.add "X-Amz-SignedHeaders", valid_614184
  result.add "header", section
  ## parameters in `formData` object:
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>, and it must be the last action to be performed.</p> <p>If the action type is <code>forward</code>, you specify one or more target groups. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  var valid_614185 = formData.getOrDefault("Actions")
  valid_614185 = validateParameter(valid_614185, JArray, required = false,
                                 default = nil)
  if valid_614185 != nil:
    section.add "Actions", valid_614185
  var valid_614186 = formData.getOrDefault("Conditions")
  valid_614186 = validateParameter(valid_614186, JArray, required = false,
                                 default = nil)
  if valid_614186 != nil:
    section.add "Conditions", valid_614186
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_614187 = formData.getOrDefault("RuleArn")
  valid_614187 = validateParameter(valid_614187, JString, required = true,
                                 default = nil)
  if valid_614187 != nil:
    section.add "RuleArn", valid_614187
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614188: Call_PostModifyRule_614173; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_614188.validator(path, query, header, formData, body)
  let scheme = call_614188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614188.url(scheme.get, call_614188.host, call_614188.base,
                         call_614188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614188, url, valid)

proc call*(call_614189: Call_PostModifyRule_614173; RuleArn: string;
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
  var query_614190 = newJObject()
  var formData_614191 = newJObject()
  if Actions != nil:
    formData_614191.add "Actions", Actions
  if Conditions != nil:
    formData_614191.add "Conditions", Conditions
  add(formData_614191, "RuleArn", newJString(RuleArn))
  add(query_614190, "Action", newJString(Action))
  add(query_614190, "Version", newJString(Version))
  result = call_614189.call(nil, query_614190, nil, formData_614191, nil)

var postModifyRule* = Call_PostModifyRule_614173(name: "postModifyRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_PostModifyRule_614174,
    base: "/", url: url_PostModifyRule_614175, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyRule_614155 = ref object of OpenApiRestCall_612658
proc url_GetModifyRule_614157(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyRule_614156(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614158 = query.getOrDefault("RuleArn")
  valid_614158 = validateParameter(valid_614158, JString, required = true,
                                 default = nil)
  if valid_614158 != nil:
    section.add "RuleArn", valid_614158
  var valid_614159 = query.getOrDefault("Actions")
  valid_614159 = validateParameter(valid_614159, JArray, required = false,
                                 default = nil)
  if valid_614159 != nil:
    section.add "Actions", valid_614159
  var valid_614160 = query.getOrDefault("Action")
  valid_614160 = validateParameter(valid_614160, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_614160 != nil:
    section.add "Action", valid_614160
  var valid_614161 = query.getOrDefault("Version")
  valid_614161 = validateParameter(valid_614161, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614161 != nil:
    section.add "Version", valid_614161
  var valid_614162 = query.getOrDefault("Conditions")
  valid_614162 = validateParameter(valid_614162, JArray, required = false,
                                 default = nil)
  if valid_614162 != nil:
    section.add "Conditions", valid_614162
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614163 = header.getOrDefault("X-Amz-Signature")
  valid_614163 = validateParameter(valid_614163, JString, required = false,
                                 default = nil)
  if valid_614163 != nil:
    section.add "X-Amz-Signature", valid_614163
  var valid_614164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614164 = validateParameter(valid_614164, JString, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "X-Amz-Content-Sha256", valid_614164
  var valid_614165 = header.getOrDefault("X-Amz-Date")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "X-Amz-Date", valid_614165
  var valid_614166 = header.getOrDefault("X-Amz-Credential")
  valid_614166 = validateParameter(valid_614166, JString, required = false,
                                 default = nil)
  if valid_614166 != nil:
    section.add "X-Amz-Credential", valid_614166
  var valid_614167 = header.getOrDefault("X-Amz-Security-Token")
  valid_614167 = validateParameter(valid_614167, JString, required = false,
                                 default = nil)
  if valid_614167 != nil:
    section.add "X-Amz-Security-Token", valid_614167
  var valid_614168 = header.getOrDefault("X-Amz-Algorithm")
  valid_614168 = validateParameter(valid_614168, JString, required = false,
                                 default = nil)
  if valid_614168 != nil:
    section.add "X-Amz-Algorithm", valid_614168
  var valid_614169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614169 = validateParameter(valid_614169, JString, required = false,
                                 default = nil)
  if valid_614169 != nil:
    section.add "X-Amz-SignedHeaders", valid_614169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614170: Call_GetModifyRule_614155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the specified properties of the specified rule. Any properties that you do not specify are unchanged.</p> <p>To add an item to a list, remove an item from a list, or update an item in a list, you must provide the entire list. For example, to add an action, specify a list with the current actions plus the new action.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_614170.validator(path, query, header, formData, body)
  let scheme = call_614170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614170.url(scheme.get, call_614170.host, call_614170.base,
                         call_614170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614170, url, valid)

proc call*(call_614171: Call_GetModifyRule_614155; RuleArn: string;
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
  var query_614172 = newJObject()
  add(query_614172, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    query_614172.add "Actions", Actions
  add(query_614172, "Action", newJString(Action))
  add(query_614172, "Version", newJString(Version))
  if Conditions != nil:
    query_614172.add "Conditions", Conditions
  result = call_614171.call(nil, query_614172, nil, nil, nil)

var getModifyRule* = Call_GetModifyRule_614155(name: "getModifyRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_GetModifyRule_614156,
    base: "/", url: url_GetModifyRule_614157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroup_614217 = ref object of OpenApiRestCall_612658
proc url_PostModifyTargetGroup_614219(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyTargetGroup_614218(path: JsonNode; query: JsonNode;
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
  var valid_614220 = query.getOrDefault("Action")
  valid_614220 = validateParameter(valid_614220, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_614220 != nil:
    section.add "Action", valid_614220
  var valid_614221 = query.getOrDefault("Version")
  valid_614221 = validateParameter(valid_614221, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614221 != nil:
    section.add "Version", valid_614221
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614222 = header.getOrDefault("X-Amz-Signature")
  valid_614222 = validateParameter(valid_614222, JString, required = false,
                                 default = nil)
  if valid_614222 != nil:
    section.add "X-Amz-Signature", valid_614222
  var valid_614223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614223 = validateParameter(valid_614223, JString, required = false,
                                 default = nil)
  if valid_614223 != nil:
    section.add "X-Amz-Content-Sha256", valid_614223
  var valid_614224 = header.getOrDefault("X-Amz-Date")
  valid_614224 = validateParameter(valid_614224, JString, required = false,
                                 default = nil)
  if valid_614224 != nil:
    section.add "X-Amz-Date", valid_614224
  var valid_614225 = header.getOrDefault("X-Amz-Credential")
  valid_614225 = validateParameter(valid_614225, JString, required = false,
                                 default = nil)
  if valid_614225 != nil:
    section.add "X-Amz-Credential", valid_614225
  var valid_614226 = header.getOrDefault("X-Amz-Security-Token")
  valid_614226 = validateParameter(valid_614226, JString, required = false,
                                 default = nil)
  if valid_614226 != nil:
    section.add "X-Amz-Security-Token", valid_614226
  var valid_614227 = header.getOrDefault("X-Amz-Algorithm")
  valid_614227 = validateParameter(valid_614227, JString, required = false,
                                 default = nil)
  if valid_614227 != nil:
    section.add "X-Amz-Algorithm", valid_614227
  var valid_614228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614228 = validateParameter(valid_614228, JString, required = false,
                                 default = nil)
  if valid_614228 != nil:
    section.add "X-Amz-SignedHeaders", valid_614228
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
  var valid_614229 = formData.getOrDefault("HealthCheckProtocol")
  valid_614229 = validateParameter(valid_614229, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_614229 != nil:
    section.add "HealthCheckProtocol", valid_614229
  var valid_614230 = formData.getOrDefault("HealthCheckPort")
  valid_614230 = validateParameter(valid_614230, JString, required = false,
                                 default = nil)
  if valid_614230 != nil:
    section.add "HealthCheckPort", valid_614230
  var valid_614231 = formData.getOrDefault("HealthCheckEnabled")
  valid_614231 = validateParameter(valid_614231, JBool, required = false, default = nil)
  if valid_614231 != nil:
    section.add "HealthCheckEnabled", valid_614231
  var valid_614232 = formData.getOrDefault("HealthCheckPath")
  valid_614232 = validateParameter(valid_614232, JString, required = false,
                                 default = nil)
  if valid_614232 != nil:
    section.add "HealthCheckPath", valid_614232
  var valid_614233 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_614233 = validateParameter(valid_614233, JInt, required = false, default = nil)
  if valid_614233 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_614233
  var valid_614234 = formData.getOrDefault("HealthyThresholdCount")
  valid_614234 = validateParameter(valid_614234, JInt, required = false, default = nil)
  if valid_614234 != nil:
    section.add "HealthyThresholdCount", valid_614234
  var valid_614235 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_614235 = validateParameter(valid_614235, JInt, required = false, default = nil)
  if valid_614235 != nil:
    section.add "HealthCheckIntervalSeconds", valid_614235
  var valid_614236 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_614236 = validateParameter(valid_614236, JInt, required = false, default = nil)
  if valid_614236 != nil:
    section.add "UnhealthyThresholdCount", valid_614236
  var valid_614237 = formData.getOrDefault("Matcher.HttpCode")
  valid_614237 = validateParameter(valid_614237, JString, required = false,
                                 default = nil)
  if valid_614237 != nil:
    section.add "Matcher.HttpCode", valid_614237
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_614238 = formData.getOrDefault("TargetGroupArn")
  valid_614238 = validateParameter(valid_614238, JString, required = true,
                                 default = nil)
  if valid_614238 != nil:
    section.add "TargetGroupArn", valid_614238
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614239: Call_PostModifyTargetGroup_614217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_614239.validator(path, query, header, formData, body)
  let scheme = call_614239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614239.url(scheme.get, call_614239.host, call_614239.base,
                         call_614239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614239, url, valid)

proc call*(call_614240: Call_PostModifyTargetGroup_614217; TargetGroupArn: string;
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
  var query_614241 = newJObject()
  var formData_614242 = newJObject()
  add(formData_614242, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_614242, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_614242, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_614242, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_614242, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_614242, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_614242, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_614242, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_614242, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_614241, "Action", newJString(Action))
  add(formData_614242, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_614241, "Version", newJString(Version))
  result = call_614240.call(nil, query_614241, nil, formData_614242, nil)

var postModifyTargetGroup* = Call_PostModifyTargetGroup_614217(
    name: "postModifyTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup",
    validator: validate_PostModifyTargetGroup_614218, base: "/",
    url: url_PostModifyTargetGroup_614219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroup_614192 = ref object of OpenApiRestCall_612658
proc url_GetModifyTargetGroup_614194(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyTargetGroup_614193(path: JsonNode; query: JsonNode;
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
  var valid_614195 = query.getOrDefault("HealthCheckPort")
  valid_614195 = validateParameter(valid_614195, JString, required = false,
                                 default = nil)
  if valid_614195 != nil:
    section.add "HealthCheckPort", valid_614195
  var valid_614196 = query.getOrDefault("HealthCheckPath")
  valid_614196 = validateParameter(valid_614196, JString, required = false,
                                 default = nil)
  if valid_614196 != nil:
    section.add "HealthCheckPath", valid_614196
  var valid_614197 = query.getOrDefault("HealthCheckProtocol")
  valid_614197 = validateParameter(valid_614197, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_614197 != nil:
    section.add "HealthCheckProtocol", valid_614197
  var valid_614198 = query.getOrDefault("Matcher.HttpCode")
  valid_614198 = validateParameter(valid_614198, JString, required = false,
                                 default = nil)
  if valid_614198 != nil:
    section.add "Matcher.HttpCode", valid_614198
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_614199 = query.getOrDefault("TargetGroupArn")
  valid_614199 = validateParameter(valid_614199, JString, required = true,
                                 default = nil)
  if valid_614199 != nil:
    section.add "TargetGroupArn", valid_614199
  var valid_614200 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_614200 = validateParameter(valid_614200, JInt, required = false, default = nil)
  if valid_614200 != nil:
    section.add "HealthCheckIntervalSeconds", valid_614200
  var valid_614201 = query.getOrDefault("HealthCheckEnabled")
  valid_614201 = validateParameter(valid_614201, JBool, required = false, default = nil)
  if valid_614201 != nil:
    section.add "HealthCheckEnabled", valid_614201
  var valid_614202 = query.getOrDefault("HealthyThresholdCount")
  valid_614202 = validateParameter(valid_614202, JInt, required = false, default = nil)
  if valid_614202 != nil:
    section.add "HealthyThresholdCount", valid_614202
  var valid_614203 = query.getOrDefault("UnhealthyThresholdCount")
  valid_614203 = validateParameter(valid_614203, JInt, required = false, default = nil)
  if valid_614203 != nil:
    section.add "UnhealthyThresholdCount", valid_614203
  var valid_614204 = query.getOrDefault("Action")
  valid_614204 = validateParameter(valid_614204, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_614204 != nil:
    section.add "Action", valid_614204
  var valid_614205 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_614205 = validateParameter(valid_614205, JInt, required = false, default = nil)
  if valid_614205 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_614205
  var valid_614206 = query.getOrDefault("Version")
  valid_614206 = validateParameter(valid_614206, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614206 != nil:
    section.add "Version", valid_614206
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614207 = header.getOrDefault("X-Amz-Signature")
  valid_614207 = validateParameter(valid_614207, JString, required = false,
                                 default = nil)
  if valid_614207 != nil:
    section.add "X-Amz-Signature", valid_614207
  var valid_614208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614208 = validateParameter(valid_614208, JString, required = false,
                                 default = nil)
  if valid_614208 != nil:
    section.add "X-Amz-Content-Sha256", valid_614208
  var valid_614209 = header.getOrDefault("X-Amz-Date")
  valid_614209 = validateParameter(valid_614209, JString, required = false,
                                 default = nil)
  if valid_614209 != nil:
    section.add "X-Amz-Date", valid_614209
  var valid_614210 = header.getOrDefault("X-Amz-Credential")
  valid_614210 = validateParameter(valid_614210, JString, required = false,
                                 default = nil)
  if valid_614210 != nil:
    section.add "X-Amz-Credential", valid_614210
  var valid_614211 = header.getOrDefault("X-Amz-Security-Token")
  valid_614211 = validateParameter(valid_614211, JString, required = false,
                                 default = nil)
  if valid_614211 != nil:
    section.add "X-Amz-Security-Token", valid_614211
  var valid_614212 = header.getOrDefault("X-Amz-Algorithm")
  valid_614212 = validateParameter(valid_614212, JString, required = false,
                                 default = nil)
  if valid_614212 != nil:
    section.add "X-Amz-Algorithm", valid_614212
  var valid_614213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614213 = validateParameter(valid_614213, JString, required = false,
                                 default = nil)
  if valid_614213 != nil:
    section.add "X-Amz-SignedHeaders", valid_614213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614214: Call_GetModifyTargetGroup_614192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_614214.validator(path, query, header, formData, body)
  let scheme = call_614214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614214.url(scheme.get, call_614214.host, call_614214.base,
                         call_614214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614214, url, valid)

proc call*(call_614215: Call_GetModifyTargetGroup_614192; TargetGroupArn: string;
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
  var query_614216 = newJObject()
  add(query_614216, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_614216, "HealthCheckPath", newJString(HealthCheckPath))
  add(query_614216, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_614216, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_614216, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_614216, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_614216, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_614216, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_614216, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_614216, "Action", newJString(Action))
  add(query_614216, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_614216, "Version", newJString(Version))
  result = call_614215.call(nil, query_614216, nil, nil, nil)

var getModifyTargetGroup* = Call_GetModifyTargetGroup_614192(
    name: "getModifyTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup", validator: validate_GetModifyTargetGroup_614193,
    base: "/", url: url_GetModifyTargetGroup_614194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroupAttributes_614260 = ref object of OpenApiRestCall_612658
proc url_PostModifyTargetGroupAttributes_614262(protocol: Scheme; host: string;
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

proc validate_PostModifyTargetGroupAttributes_614261(path: JsonNode;
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
  var valid_614263 = query.getOrDefault("Action")
  valid_614263 = validateParameter(valid_614263, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_614263 != nil:
    section.add "Action", valid_614263
  var valid_614264 = query.getOrDefault("Version")
  valid_614264 = validateParameter(valid_614264, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614264 != nil:
    section.add "Version", valid_614264
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614265 = header.getOrDefault("X-Amz-Signature")
  valid_614265 = validateParameter(valid_614265, JString, required = false,
                                 default = nil)
  if valid_614265 != nil:
    section.add "X-Amz-Signature", valid_614265
  var valid_614266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614266 = validateParameter(valid_614266, JString, required = false,
                                 default = nil)
  if valid_614266 != nil:
    section.add "X-Amz-Content-Sha256", valid_614266
  var valid_614267 = header.getOrDefault("X-Amz-Date")
  valid_614267 = validateParameter(valid_614267, JString, required = false,
                                 default = nil)
  if valid_614267 != nil:
    section.add "X-Amz-Date", valid_614267
  var valid_614268 = header.getOrDefault("X-Amz-Credential")
  valid_614268 = validateParameter(valid_614268, JString, required = false,
                                 default = nil)
  if valid_614268 != nil:
    section.add "X-Amz-Credential", valid_614268
  var valid_614269 = header.getOrDefault("X-Amz-Security-Token")
  valid_614269 = validateParameter(valid_614269, JString, required = false,
                                 default = nil)
  if valid_614269 != nil:
    section.add "X-Amz-Security-Token", valid_614269
  var valid_614270 = header.getOrDefault("X-Amz-Algorithm")
  valid_614270 = validateParameter(valid_614270, JString, required = false,
                                 default = nil)
  if valid_614270 != nil:
    section.add "X-Amz-Algorithm", valid_614270
  var valid_614271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614271 = validateParameter(valid_614271, JString, required = false,
                                 default = nil)
  if valid_614271 != nil:
    section.add "X-Amz-SignedHeaders", valid_614271
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_614272 = formData.getOrDefault("Attributes")
  valid_614272 = validateParameter(valid_614272, JArray, required = true, default = nil)
  if valid_614272 != nil:
    section.add "Attributes", valid_614272
  var valid_614273 = formData.getOrDefault("TargetGroupArn")
  valid_614273 = validateParameter(valid_614273, JString, required = true,
                                 default = nil)
  if valid_614273 != nil:
    section.add "TargetGroupArn", valid_614273
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614274: Call_PostModifyTargetGroupAttributes_614260;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_614274.validator(path, query, header, formData, body)
  let scheme = call_614274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614274.url(scheme.get, call_614274.host, call_614274.base,
                         call_614274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614274, url, valid)

proc call*(call_614275: Call_PostModifyTargetGroupAttributes_614260;
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
  var query_614276 = newJObject()
  var formData_614277 = newJObject()
  if Attributes != nil:
    formData_614277.add "Attributes", Attributes
  add(query_614276, "Action", newJString(Action))
  add(formData_614277, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_614276, "Version", newJString(Version))
  result = call_614275.call(nil, query_614276, nil, formData_614277, nil)

var postModifyTargetGroupAttributes* = Call_PostModifyTargetGroupAttributes_614260(
    name: "postModifyTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_PostModifyTargetGroupAttributes_614261, base: "/",
    url: url_PostModifyTargetGroupAttributes_614262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroupAttributes_614243 = ref object of OpenApiRestCall_612658
proc url_GetModifyTargetGroupAttributes_614245(protocol: Scheme; host: string;
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

proc validate_GetModifyTargetGroupAttributes_614244(path: JsonNode;
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
  var valid_614246 = query.getOrDefault("TargetGroupArn")
  valid_614246 = validateParameter(valid_614246, JString, required = true,
                                 default = nil)
  if valid_614246 != nil:
    section.add "TargetGroupArn", valid_614246
  var valid_614247 = query.getOrDefault("Attributes")
  valid_614247 = validateParameter(valid_614247, JArray, required = true, default = nil)
  if valid_614247 != nil:
    section.add "Attributes", valid_614247
  var valid_614248 = query.getOrDefault("Action")
  valid_614248 = validateParameter(valid_614248, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_614248 != nil:
    section.add "Action", valid_614248
  var valid_614249 = query.getOrDefault("Version")
  valid_614249 = validateParameter(valid_614249, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614249 != nil:
    section.add "Version", valid_614249
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614250 = header.getOrDefault("X-Amz-Signature")
  valid_614250 = validateParameter(valid_614250, JString, required = false,
                                 default = nil)
  if valid_614250 != nil:
    section.add "X-Amz-Signature", valid_614250
  var valid_614251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614251 = validateParameter(valid_614251, JString, required = false,
                                 default = nil)
  if valid_614251 != nil:
    section.add "X-Amz-Content-Sha256", valid_614251
  var valid_614252 = header.getOrDefault("X-Amz-Date")
  valid_614252 = validateParameter(valid_614252, JString, required = false,
                                 default = nil)
  if valid_614252 != nil:
    section.add "X-Amz-Date", valid_614252
  var valid_614253 = header.getOrDefault("X-Amz-Credential")
  valid_614253 = validateParameter(valid_614253, JString, required = false,
                                 default = nil)
  if valid_614253 != nil:
    section.add "X-Amz-Credential", valid_614253
  var valid_614254 = header.getOrDefault("X-Amz-Security-Token")
  valid_614254 = validateParameter(valid_614254, JString, required = false,
                                 default = nil)
  if valid_614254 != nil:
    section.add "X-Amz-Security-Token", valid_614254
  var valid_614255 = header.getOrDefault("X-Amz-Algorithm")
  valid_614255 = validateParameter(valid_614255, JString, required = false,
                                 default = nil)
  if valid_614255 != nil:
    section.add "X-Amz-Algorithm", valid_614255
  var valid_614256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614256 = validateParameter(valid_614256, JString, required = false,
                                 default = nil)
  if valid_614256 != nil:
    section.add "X-Amz-SignedHeaders", valid_614256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614257: Call_GetModifyTargetGroupAttributes_614243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_614257.validator(path, query, header, formData, body)
  let scheme = call_614257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614257.url(scheme.get, call_614257.host, call_614257.base,
                         call_614257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614257, url, valid)

proc call*(call_614258: Call_GetModifyTargetGroupAttributes_614243;
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
  var query_614259 = newJObject()
  add(query_614259, "TargetGroupArn", newJString(TargetGroupArn))
  if Attributes != nil:
    query_614259.add "Attributes", Attributes
  add(query_614259, "Action", newJString(Action))
  add(query_614259, "Version", newJString(Version))
  result = call_614258.call(nil, query_614259, nil, nil, nil)

var getModifyTargetGroupAttributes* = Call_GetModifyTargetGroupAttributes_614243(
    name: "getModifyTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_GetModifyTargetGroupAttributes_614244, base: "/",
    url: url_GetModifyTargetGroupAttributes_614245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterTargets_614295 = ref object of OpenApiRestCall_612658
proc url_PostRegisterTargets_614297(protocol: Scheme; host: string; base: string;
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

proc validate_PostRegisterTargets_614296(path: JsonNode; query: JsonNode;
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
  var valid_614298 = query.getOrDefault("Action")
  valid_614298 = validateParameter(valid_614298, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_614298 != nil:
    section.add "Action", valid_614298
  var valid_614299 = query.getOrDefault("Version")
  valid_614299 = validateParameter(valid_614299, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614299 != nil:
    section.add "Version", valid_614299
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614300 = header.getOrDefault("X-Amz-Signature")
  valid_614300 = validateParameter(valid_614300, JString, required = false,
                                 default = nil)
  if valid_614300 != nil:
    section.add "X-Amz-Signature", valid_614300
  var valid_614301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614301 = validateParameter(valid_614301, JString, required = false,
                                 default = nil)
  if valid_614301 != nil:
    section.add "X-Amz-Content-Sha256", valid_614301
  var valid_614302 = header.getOrDefault("X-Amz-Date")
  valid_614302 = validateParameter(valid_614302, JString, required = false,
                                 default = nil)
  if valid_614302 != nil:
    section.add "X-Amz-Date", valid_614302
  var valid_614303 = header.getOrDefault("X-Amz-Credential")
  valid_614303 = validateParameter(valid_614303, JString, required = false,
                                 default = nil)
  if valid_614303 != nil:
    section.add "X-Amz-Credential", valid_614303
  var valid_614304 = header.getOrDefault("X-Amz-Security-Token")
  valid_614304 = validateParameter(valid_614304, JString, required = false,
                                 default = nil)
  if valid_614304 != nil:
    section.add "X-Amz-Security-Token", valid_614304
  var valid_614305 = header.getOrDefault("X-Amz-Algorithm")
  valid_614305 = validateParameter(valid_614305, JString, required = false,
                                 default = nil)
  if valid_614305 != nil:
    section.add "X-Amz-Algorithm", valid_614305
  var valid_614306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614306 = validateParameter(valid_614306, JString, required = false,
                                 default = nil)
  if valid_614306 != nil:
    section.add "X-Amz-SignedHeaders", valid_614306
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_614307 = formData.getOrDefault("Targets")
  valid_614307 = validateParameter(valid_614307, JArray, required = true, default = nil)
  if valid_614307 != nil:
    section.add "Targets", valid_614307
  var valid_614308 = formData.getOrDefault("TargetGroupArn")
  valid_614308 = validateParameter(valid_614308, JString, required = true,
                                 default = nil)
  if valid_614308 != nil:
    section.add "TargetGroupArn", valid_614308
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614309: Call_PostRegisterTargets_614295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_614309.validator(path, query, header, formData, body)
  let scheme = call_614309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614309.url(scheme.get, call_614309.host, call_614309.base,
                         call_614309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614309, url, valid)

proc call*(call_614310: Call_PostRegisterTargets_614295; Targets: JsonNode;
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
  var query_614311 = newJObject()
  var formData_614312 = newJObject()
  if Targets != nil:
    formData_614312.add "Targets", Targets
  add(query_614311, "Action", newJString(Action))
  add(formData_614312, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_614311, "Version", newJString(Version))
  result = call_614310.call(nil, query_614311, nil, formData_614312, nil)

var postRegisterTargets* = Call_PostRegisterTargets_614295(
    name: "postRegisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_PostRegisterTargets_614296, base: "/",
    url: url_PostRegisterTargets_614297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterTargets_614278 = ref object of OpenApiRestCall_612658
proc url_GetRegisterTargets_614280(protocol: Scheme; host: string; base: string;
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

proc validate_GetRegisterTargets_614279(path: JsonNode; query: JsonNode;
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
  var valid_614281 = query.getOrDefault("Targets")
  valid_614281 = validateParameter(valid_614281, JArray, required = true, default = nil)
  if valid_614281 != nil:
    section.add "Targets", valid_614281
  var valid_614282 = query.getOrDefault("TargetGroupArn")
  valid_614282 = validateParameter(valid_614282, JString, required = true,
                                 default = nil)
  if valid_614282 != nil:
    section.add "TargetGroupArn", valid_614282
  var valid_614283 = query.getOrDefault("Action")
  valid_614283 = validateParameter(valid_614283, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_614283 != nil:
    section.add "Action", valid_614283
  var valid_614284 = query.getOrDefault("Version")
  valid_614284 = validateParameter(valid_614284, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614284 != nil:
    section.add "Version", valid_614284
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614285 = header.getOrDefault("X-Amz-Signature")
  valid_614285 = validateParameter(valid_614285, JString, required = false,
                                 default = nil)
  if valid_614285 != nil:
    section.add "X-Amz-Signature", valid_614285
  var valid_614286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614286 = validateParameter(valid_614286, JString, required = false,
                                 default = nil)
  if valid_614286 != nil:
    section.add "X-Amz-Content-Sha256", valid_614286
  var valid_614287 = header.getOrDefault("X-Amz-Date")
  valid_614287 = validateParameter(valid_614287, JString, required = false,
                                 default = nil)
  if valid_614287 != nil:
    section.add "X-Amz-Date", valid_614287
  var valid_614288 = header.getOrDefault("X-Amz-Credential")
  valid_614288 = validateParameter(valid_614288, JString, required = false,
                                 default = nil)
  if valid_614288 != nil:
    section.add "X-Amz-Credential", valid_614288
  var valid_614289 = header.getOrDefault("X-Amz-Security-Token")
  valid_614289 = validateParameter(valid_614289, JString, required = false,
                                 default = nil)
  if valid_614289 != nil:
    section.add "X-Amz-Security-Token", valid_614289
  var valid_614290 = header.getOrDefault("X-Amz-Algorithm")
  valid_614290 = validateParameter(valid_614290, JString, required = false,
                                 default = nil)
  if valid_614290 != nil:
    section.add "X-Amz-Algorithm", valid_614290
  var valid_614291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614291 = validateParameter(valid_614291, JString, required = false,
                                 default = nil)
  if valid_614291 != nil:
    section.add "X-Amz-SignedHeaders", valid_614291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614292: Call_GetRegisterTargets_614278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_614292.validator(path, query, header, formData, body)
  let scheme = call_614292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614292.url(scheme.get, call_614292.host, call_614292.base,
                         call_614292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614292, url, valid)

proc call*(call_614293: Call_GetRegisterTargets_614278; Targets: JsonNode;
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
  var query_614294 = newJObject()
  if Targets != nil:
    query_614294.add "Targets", Targets
  add(query_614294, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_614294, "Action", newJString(Action))
  add(query_614294, "Version", newJString(Version))
  result = call_614293.call(nil, query_614294, nil, nil, nil)

var getRegisterTargets* = Call_GetRegisterTargets_614278(
    name: "getRegisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_GetRegisterTargets_614279, base: "/",
    url: url_GetRegisterTargets_614280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveListenerCertificates_614330 = ref object of OpenApiRestCall_612658
proc url_PostRemoveListenerCertificates_614332(protocol: Scheme; host: string;
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

proc validate_PostRemoveListenerCertificates_614331(path: JsonNode;
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
  var valid_614333 = query.getOrDefault("Action")
  valid_614333 = validateParameter(valid_614333, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_614333 != nil:
    section.add "Action", valid_614333
  var valid_614334 = query.getOrDefault("Version")
  valid_614334 = validateParameter(valid_614334, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614334 != nil:
    section.add "Version", valid_614334
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614335 = header.getOrDefault("X-Amz-Signature")
  valid_614335 = validateParameter(valid_614335, JString, required = false,
                                 default = nil)
  if valid_614335 != nil:
    section.add "X-Amz-Signature", valid_614335
  var valid_614336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614336 = validateParameter(valid_614336, JString, required = false,
                                 default = nil)
  if valid_614336 != nil:
    section.add "X-Amz-Content-Sha256", valid_614336
  var valid_614337 = header.getOrDefault("X-Amz-Date")
  valid_614337 = validateParameter(valid_614337, JString, required = false,
                                 default = nil)
  if valid_614337 != nil:
    section.add "X-Amz-Date", valid_614337
  var valid_614338 = header.getOrDefault("X-Amz-Credential")
  valid_614338 = validateParameter(valid_614338, JString, required = false,
                                 default = nil)
  if valid_614338 != nil:
    section.add "X-Amz-Credential", valid_614338
  var valid_614339 = header.getOrDefault("X-Amz-Security-Token")
  valid_614339 = validateParameter(valid_614339, JString, required = false,
                                 default = nil)
  if valid_614339 != nil:
    section.add "X-Amz-Security-Token", valid_614339
  var valid_614340 = header.getOrDefault("X-Amz-Algorithm")
  valid_614340 = validateParameter(valid_614340, JString, required = false,
                                 default = nil)
  if valid_614340 != nil:
    section.add "X-Amz-Algorithm", valid_614340
  var valid_614341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614341 = validateParameter(valid_614341, JString, required = false,
                                 default = nil)
  if valid_614341 != nil:
    section.add "X-Amz-SignedHeaders", valid_614341
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_614342 = formData.getOrDefault("Certificates")
  valid_614342 = validateParameter(valid_614342, JArray, required = true, default = nil)
  if valid_614342 != nil:
    section.add "Certificates", valid_614342
  var valid_614343 = formData.getOrDefault("ListenerArn")
  valid_614343 = validateParameter(valid_614343, JString, required = true,
                                 default = nil)
  if valid_614343 != nil:
    section.add "ListenerArn", valid_614343
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614344: Call_PostRemoveListenerCertificates_614330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_614344.validator(path, query, header, formData, body)
  let scheme = call_614344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614344.url(scheme.get, call_614344.host, call_614344.base,
                         call_614344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614344, url, valid)

proc call*(call_614345: Call_PostRemoveListenerCertificates_614330;
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
  var query_614346 = newJObject()
  var formData_614347 = newJObject()
  if Certificates != nil:
    formData_614347.add "Certificates", Certificates
  add(formData_614347, "ListenerArn", newJString(ListenerArn))
  add(query_614346, "Action", newJString(Action))
  add(query_614346, "Version", newJString(Version))
  result = call_614345.call(nil, query_614346, nil, formData_614347, nil)

var postRemoveListenerCertificates* = Call_PostRemoveListenerCertificates_614330(
    name: "postRemoveListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_PostRemoveListenerCertificates_614331, base: "/",
    url: url_PostRemoveListenerCertificates_614332,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveListenerCertificates_614313 = ref object of OpenApiRestCall_612658
proc url_GetRemoveListenerCertificates_614315(protocol: Scheme; host: string;
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

proc validate_GetRemoveListenerCertificates_614314(path: JsonNode; query: JsonNode;
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
  var valid_614316 = query.getOrDefault("ListenerArn")
  valid_614316 = validateParameter(valid_614316, JString, required = true,
                                 default = nil)
  if valid_614316 != nil:
    section.add "ListenerArn", valid_614316
  var valid_614317 = query.getOrDefault("Certificates")
  valid_614317 = validateParameter(valid_614317, JArray, required = true, default = nil)
  if valid_614317 != nil:
    section.add "Certificates", valid_614317
  var valid_614318 = query.getOrDefault("Action")
  valid_614318 = validateParameter(valid_614318, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_614318 != nil:
    section.add "Action", valid_614318
  var valid_614319 = query.getOrDefault("Version")
  valid_614319 = validateParameter(valid_614319, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614319 != nil:
    section.add "Version", valid_614319
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614320 = header.getOrDefault("X-Amz-Signature")
  valid_614320 = validateParameter(valid_614320, JString, required = false,
                                 default = nil)
  if valid_614320 != nil:
    section.add "X-Amz-Signature", valid_614320
  var valid_614321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614321 = validateParameter(valid_614321, JString, required = false,
                                 default = nil)
  if valid_614321 != nil:
    section.add "X-Amz-Content-Sha256", valid_614321
  var valid_614322 = header.getOrDefault("X-Amz-Date")
  valid_614322 = validateParameter(valid_614322, JString, required = false,
                                 default = nil)
  if valid_614322 != nil:
    section.add "X-Amz-Date", valid_614322
  var valid_614323 = header.getOrDefault("X-Amz-Credential")
  valid_614323 = validateParameter(valid_614323, JString, required = false,
                                 default = nil)
  if valid_614323 != nil:
    section.add "X-Amz-Credential", valid_614323
  var valid_614324 = header.getOrDefault("X-Amz-Security-Token")
  valid_614324 = validateParameter(valid_614324, JString, required = false,
                                 default = nil)
  if valid_614324 != nil:
    section.add "X-Amz-Security-Token", valid_614324
  var valid_614325 = header.getOrDefault("X-Amz-Algorithm")
  valid_614325 = validateParameter(valid_614325, JString, required = false,
                                 default = nil)
  if valid_614325 != nil:
    section.add "X-Amz-Algorithm", valid_614325
  var valid_614326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614326 = validateParameter(valid_614326, JString, required = false,
                                 default = nil)
  if valid_614326 != nil:
    section.add "X-Amz-SignedHeaders", valid_614326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614327: Call_GetRemoveListenerCertificates_614313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_614327.validator(path, query, header, formData, body)
  let scheme = call_614327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614327.url(scheme.get, call_614327.host, call_614327.base,
                         call_614327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614327, url, valid)

proc call*(call_614328: Call_GetRemoveListenerCertificates_614313;
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
  var query_614329 = newJObject()
  add(query_614329, "ListenerArn", newJString(ListenerArn))
  if Certificates != nil:
    query_614329.add "Certificates", Certificates
  add(query_614329, "Action", newJString(Action))
  add(query_614329, "Version", newJString(Version))
  result = call_614328.call(nil, query_614329, nil, nil, nil)

var getRemoveListenerCertificates* = Call_GetRemoveListenerCertificates_614313(
    name: "getRemoveListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_GetRemoveListenerCertificates_614314, base: "/",
    url: url_GetRemoveListenerCertificates_614315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_614365 = ref object of OpenApiRestCall_612658
proc url_PostRemoveTags_614367(protocol: Scheme; host: string; base: string;
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

proc validate_PostRemoveTags_614366(path: JsonNode; query: JsonNode;
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
  var valid_614368 = query.getOrDefault("Action")
  valid_614368 = validateParameter(valid_614368, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_614368 != nil:
    section.add "Action", valid_614368
  var valid_614369 = query.getOrDefault("Version")
  valid_614369 = validateParameter(valid_614369, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614369 != nil:
    section.add "Version", valid_614369
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614370 = header.getOrDefault("X-Amz-Signature")
  valid_614370 = validateParameter(valid_614370, JString, required = false,
                                 default = nil)
  if valid_614370 != nil:
    section.add "X-Amz-Signature", valid_614370
  var valid_614371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614371 = validateParameter(valid_614371, JString, required = false,
                                 default = nil)
  if valid_614371 != nil:
    section.add "X-Amz-Content-Sha256", valid_614371
  var valid_614372 = header.getOrDefault("X-Amz-Date")
  valid_614372 = validateParameter(valid_614372, JString, required = false,
                                 default = nil)
  if valid_614372 != nil:
    section.add "X-Amz-Date", valid_614372
  var valid_614373 = header.getOrDefault("X-Amz-Credential")
  valid_614373 = validateParameter(valid_614373, JString, required = false,
                                 default = nil)
  if valid_614373 != nil:
    section.add "X-Amz-Credential", valid_614373
  var valid_614374 = header.getOrDefault("X-Amz-Security-Token")
  valid_614374 = validateParameter(valid_614374, JString, required = false,
                                 default = nil)
  if valid_614374 != nil:
    section.add "X-Amz-Security-Token", valid_614374
  var valid_614375 = header.getOrDefault("X-Amz-Algorithm")
  valid_614375 = validateParameter(valid_614375, JString, required = false,
                                 default = nil)
  if valid_614375 != nil:
    section.add "X-Amz-Algorithm", valid_614375
  var valid_614376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614376 = validateParameter(valid_614376, JString, required = false,
                                 default = nil)
  if valid_614376 != nil:
    section.add "X-Amz-SignedHeaders", valid_614376
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_614377 = formData.getOrDefault("TagKeys")
  valid_614377 = validateParameter(valid_614377, JArray, required = true, default = nil)
  if valid_614377 != nil:
    section.add "TagKeys", valid_614377
  var valid_614378 = formData.getOrDefault("ResourceArns")
  valid_614378 = validateParameter(valid_614378, JArray, required = true, default = nil)
  if valid_614378 != nil:
    section.add "ResourceArns", valid_614378
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614379: Call_PostRemoveTags_614365; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_614379.validator(path, query, header, formData, body)
  let scheme = call_614379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614379.url(scheme.get, call_614379.host, call_614379.base,
                         call_614379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614379, url, valid)

proc call*(call_614380: Call_PostRemoveTags_614365; TagKeys: JsonNode;
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
  var query_614381 = newJObject()
  var formData_614382 = newJObject()
  if TagKeys != nil:
    formData_614382.add "TagKeys", TagKeys
  if ResourceArns != nil:
    formData_614382.add "ResourceArns", ResourceArns
  add(query_614381, "Action", newJString(Action))
  add(query_614381, "Version", newJString(Version))
  result = call_614380.call(nil, query_614381, nil, formData_614382, nil)

var postRemoveTags* = Call_PostRemoveTags_614365(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_614366,
    base: "/", url: url_PostRemoveTags_614367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_614348 = ref object of OpenApiRestCall_612658
proc url_GetRemoveTags_614350(protocol: Scheme; host: string; base: string;
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

proc validate_GetRemoveTags_614349(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614351 = query.getOrDefault("ResourceArns")
  valid_614351 = validateParameter(valid_614351, JArray, required = true, default = nil)
  if valid_614351 != nil:
    section.add "ResourceArns", valid_614351
  var valid_614352 = query.getOrDefault("TagKeys")
  valid_614352 = validateParameter(valid_614352, JArray, required = true, default = nil)
  if valid_614352 != nil:
    section.add "TagKeys", valid_614352
  var valid_614353 = query.getOrDefault("Action")
  valid_614353 = validateParameter(valid_614353, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_614353 != nil:
    section.add "Action", valid_614353
  var valid_614354 = query.getOrDefault("Version")
  valid_614354 = validateParameter(valid_614354, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614354 != nil:
    section.add "Version", valid_614354
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614355 = header.getOrDefault("X-Amz-Signature")
  valid_614355 = validateParameter(valid_614355, JString, required = false,
                                 default = nil)
  if valid_614355 != nil:
    section.add "X-Amz-Signature", valid_614355
  var valid_614356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614356 = validateParameter(valid_614356, JString, required = false,
                                 default = nil)
  if valid_614356 != nil:
    section.add "X-Amz-Content-Sha256", valid_614356
  var valid_614357 = header.getOrDefault("X-Amz-Date")
  valid_614357 = validateParameter(valid_614357, JString, required = false,
                                 default = nil)
  if valid_614357 != nil:
    section.add "X-Amz-Date", valid_614357
  var valid_614358 = header.getOrDefault("X-Amz-Credential")
  valid_614358 = validateParameter(valid_614358, JString, required = false,
                                 default = nil)
  if valid_614358 != nil:
    section.add "X-Amz-Credential", valid_614358
  var valid_614359 = header.getOrDefault("X-Amz-Security-Token")
  valid_614359 = validateParameter(valid_614359, JString, required = false,
                                 default = nil)
  if valid_614359 != nil:
    section.add "X-Amz-Security-Token", valid_614359
  var valid_614360 = header.getOrDefault("X-Amz-Algorithm")
  valid_614360 = validateParameter(valid_614360, JString, required = false,
                                 default = nil)
  if valid_614360 != nil:
    section.add "X-Amz-Algorithm", valid_614360
  var valid_614361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614361 = validateParameter(valid_614361, JString, required = false,
                                 default = nil)
  if valid_614361 != nil:
    section.add "X-Amz-SignedHeaders", valid_614361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614362: Call_GetRemoveTags_614348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_614362.validator(path, query, header, formData, body)
  let scheme = call_614362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614362.url(scheme.get, call_614362.host, call_614362.base,
                         call_614362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614362, url, valid)

proc call*(call_614363: Call_GetRemoveTags_614348; ResourceArns: JsonNode;
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
  var query_614364 = newJObject()
  if ResourceArns != nil:
    query_614364.add "ResourceArns", ResourceArns
  if TagKeys != nil:
    query_614364.add "TagKeys", TagKeys
  add(query_614364, "Action", newJString(Action))
  add(query_614364, "Version", newJString(Version))
  result = call_614363.call(nil, query_614364, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_614348(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_614349,
    base: "/", url: url_GetRemoveTags_614350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetIpAddressType_614400 = ref object of OpenApiRestCall_612658
proc url_PostSetIpAddressType_614402(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetIpAddressType_614401(path: JsonNode; query: JsonNode;
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
  var valid_614403 = query.getOrDefault("Action")
  valid_614403 = validateParameter(valid_614403, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_614403 != nil:
    section.add "Action", valid_614403
  var valid_614404 = query.getOrDefault("Version")
  valid_614404 = validateParameter(valid_614404, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614404 != nil:
    section.add "Version", valid_614404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614405 = header.getOrDefault("X-Amz-Signature")
  valid_614405 = validateParameter(valid_614405, JString, required = false,
                                 default = nil)
  if valid_614405 != nil:
    section.add "X-Amz-Signature", valid_614405
  var valid_614406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614406 = validateParameter(valid_614406, JString, required = false,
                                 default = nil)
  if valid_614406 != nil:
    section.add "X-Amz-Content-Sha256", valid_614406
  var valid_614407 = header.getOrDefault("X-Amz-Date")
  valid_614407 = validateParameter(valid_614407, JString, required = false,
                                 default = nil)
  if valid_614407 != nil:
    section.add "X-Amz-Date", valid_614407
  var valid_614408 = header.getOrDefault("X-Amz-Credential")
  valid_614408 = validateParameter(valid_614408, JString, required = false,
                                 default = nil)
  if valid_614408 != nil:
    section.add "X-Amz-Credential", valid_614408
  var valid_614409 = header.getOrDefault("X-Amz-Security-Token")
  valid_614409 = validateParameter(valid_614409, JString, required = false,
                                 default = nil)
  if valid_614409 != nil:
    section.add "X-Amz-Security-Token", valid_614409
  var valid_614410 = header.getOrDefault("X-Amz-Algorithm")
  valid_614410 = validateParameter(valid_614410, JString, required = false,
                                 default = nil)
  if valid_614410 != nil:
    section.add "X-Amz-Algorithm", valid_614410
  var valid_614411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614411 = validateParameter(valid_614411, JString, required = false,
                                 default = nil)
  if valid_614411 != nil:
    section.add "X-Amz-SignedHeaders", valid_614411
  result.add "header", section
  ## parameters in `formData` object:
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  var valid_614412 = formData.getOrDefault("IpAddressType")
  valid_614412 = validateParameter(valid_614412, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_614412 != nil:
    section.add "IpAddressType", valid_614412
  var valid_614413 = formData.getOrDefault("LoadBalancerArn")
  valid_614413 = validateParameter(valid_614413, JString, required = true,
                                 default = nil)
  if valid_614413 != nil:
    section.add "LoadBalancerArn", valid_614413
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614414: Call_PostSetIpAddressType_614400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_614414.validator(path, query, header, formData, body)
  let scheme = call_614414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614414.url(scheme.get, call_614414.host, call_614414.base,
                         call_614414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614414, url, valid)

proc call*(call_614415: Call_PostSetIpAddressType_614400; LoadBalancerArn: string;
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
  var query_614416 = newJObject()
  var formData_614417 = newJObject()
  add(formData_614417, "IpAddressType", newJString(IpAddressType))
  add(query_614416, "Action", newJString(Action))
  add(query_614416, "Version", newJString(Version))
  add(formData_614417, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_614415.call(nil, query_614416, nil, formData_614417, nil)

var postSetIpAddressType* = Call_PostSetIpAddressType_614400(
    name: "postSetIpAddressType", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_PostSetIpAddressType_614401,
    base: "/", url: url_PostSetIpAddressType_614402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetIpAddressType_614383 = ref object of OpenApiRestCall_612658
proc url_GetSetIpAddressType_614385(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetIpAddressType_614384(path: JsonNode; query: JsonNode;
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
  var valid_614386 = query.getOrDefault("IpAddressType")
  valid_614386 = validateParameter(valid_614386, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_614386 != nil:
    section.add "IpAddressType", valid_614386
  var valid_614387 = query.getOrDefault("LoadBalancerArn")
  valid_614387 = validateParameter(valid_614387, JString, required = true,
                                 default = nil)
  if valid_614387 != nil:
    section.add "LoadBalancerArn", valid_614387
  var valid_614388 = query.getOrDefault("Action")
  valid_614388 = validateParameter(valid_614388, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_614388 != nil:
    section.add "Action", valid_614388
  var valid_614389 = query.getOrDefault("Version")
  valid_614389 = validateParameter(valid_614389, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614389 != nil:
    section.add "Version", valid_614389
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614390 = header.getOrDefault("X-Amz-Signature")
  valid_614390 = validateParameter(valid_614390, JString, required = false,
                                 default = nil)
  if valid_614390 != nil:
    section.add "X-Amz-Signature", valid_614390
  var valid_614391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614391 = validateParameter(valid_614391, JString, required = false,
                                 default = nil)
  if valid_614391 != nil:
    section.add "X-Amz-Content-Sha256", valid_614391
  var valid_614392 = header.getOrDefault("X-Amz-Date")
  valid_614392 = validateParameter(valid_614392, JString, required = false,
                                 default = nil)
  if valid_614392 != nil:
    section.add "X-Amz-Date", valid_614392
  var valid_614393 = header.getOrDefault("X-Amz-Credential")
  valid_614393 = validateParameter(valid_614393, JString, required = false,
                                 default = nil)
  if valid_614393 != nil:
    section.add "X-Amz-Credential", valid_614393
  var valid_614394 = header.getOrDefault("X-Amz-Security-Token")
  valid_614394 = validateParameter(valid_614394, JString, required = false,
                                 default = nil)
  if valid_614394 != nil:
    section.add "X-Amz-Security-Token", valid_614394
  var valid_614395 = header.getOrDefault("X-Amz-Algorithm")
  valid_614395 = validateParameter(valid_614395, JString, required = false,
                                 default = nil)
  if valid_614395 != nil:
    section.add "X-Amz-Algorithm", valid_614395
  var valid_614396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614396 = validateParameter(valid_614396, JString, required = false,
                                 default = nil)
  if valid_614396 != nil:
    section.add "X-Amz-SignedHeaders", valid_614396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614397: Call_GetSetIpAddressType_614383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_614397.validator(path, query, header, formData, body)
  let scheme = call_614397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614397.url(scheme.get, call_614397.host, call_614397.base,
                         call_614397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614397, url, valid)

proc call*(call_614398: Call_GetSetIpAddressType_614383; LoadBalancerArn: string;
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
  var query_614399 = newJObject()
  add(query_614399, "IpAddressType", newJString(IpAddressType))
  add(query_614399, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_614399, "Action", newJString(Action))
  add(query_614399, "Version", newJString(Version))
  result = call_614398.call(nil, query_614399, nil, nil, nil)

var getSetIpAddressType* = Call_GetSetIpAddressType_614383(
    name: "getSetIpAddressType", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_GetSetIpAddressType_614384,
    base: "/", url: url_GetSetIpAddressType_614385,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetRulePriorities_614434 = ref object of OpenApiRestCall_612658
proc url_PostSetRulePriorities_614436(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetRulePriorities_614435(path: JsonNode; query: JsonNode;
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
  var valid_614437 = query.getOrDefault("Action")
  valid_614437 = validateParameter(valid_614437, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_614437 != nil:
    section.add "Action", valid_614437
  var valid_614438 = query.getOrDefault("Version")
  valid_614438 = validateParameter(valid_614438, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614438 != nil:
    section.add "Version", valid_614438
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614439 = header.getOrDefault("X-Amz-Signature")
  valid_614439 = validateParameter(valid_614439, JString, required = false,
                                 default = nil)
  if valid_614439 != nil:
    section.add "X-Amz-Signature", valid_614439
  var valid_614440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614440 = validateParameter(valid_614440, JString, required = false,
                                 default = nil)
  if valid_614440 != nil:
    section.add "X-Amz-Content-Sha256", valid_614440
  var valid_614441 = header.getOrDefault("X-Amz-Date")
  valid_614441 = validateParameter(valid_614441, JString, required = false,
                                 default = nil)
  if valid_614441 != nil:
    section.add "X-Amz-Date", valid_614441
  var valid_614442 = header.getOrDefault("X-Amz-Credential")
  valid_614442 = validateParameter(valid_614442, JString, required = false,
                                 default = nil)
  if valid_614442 != nil:
    section.add "X-Amz-Credential", valid_614442
  var valid_614443 = header.getOrDefault("X-Amz-Security-Token")
  valid_614443 = validateParameter(valid_614443, JString, required = false,
                                 default = nil)
  if valid_614443 != nil:
    section.add "X-Amz-Security-Token", valid_614443
  var valid_614444 = header.getOrDefault("X-Amz-Algorithm")
  valid_614444 = validateParameter(valid_614444, JString, required = false,
                                 default = nil)
  if valid_614444 != nil:
    section.add "X-Amz-Algorithm", valid_614444
  var valid_614445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614445 = validateParameter(valid_614445, JString, required = false,
                                 default = nil)
  if valid_614445 != nil:
    section.add "X-Amz-SignedHeaders", valid_614445
  result.add "header", section
  ## parameters in `formData` object:
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RulePriorities` field"
  var valid_614446 = formData.getOrDefault("RulePriorities")
  valid_614446 = validateParameter(valid_614446, JArray, required = true, default = nil)
  if valid_614446 != nil:
    section.add "RulePriorities", valid_614446
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614447: Call_PostSetRulePriorities_614434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_614447.validator(path, query, header, formData, body)
  let scheme = call_614447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614447.url(scheme.get, call_614447.host, call_614447.base,
                         call_614447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614447, url, valid)

proc call*(call_614448: Call_PostSetRulePriorities_614434;
          RulePriorities: JsonNode; Action: string = "SetRulePriorities";
          Version: string = "2015-12-01"): Recallable =
  ## postSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614449 = newJObject()
  var formData_614450 = newJObject()
  if RulePriorities != nil:
    formData_614450.add "RulePriorities", RulePriorities
  add(query_614449, "Action", newJString(Action))
  add(query_614449, "Version", newJString(Version))
  result = call_614448.call(nil, query_614449, nil, formData_614450, nil)

var postSetRulePriorities* = Call_PostSetRulePriorities_614434(
    name: "postSetRulePriorities", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities",
    validator: validate_PostSetRulePriorities_614435, base: "/",
    url: url_PostSetRulePriorities_614436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetRulePriorities_614418 = ref object of OpenApiRestCall_612658
proc url_GetSetRulePriorities_614420(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetRulePriorities_614419(path: JsonNode; query: JsonNode;
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
  var valid_614421 = query.getOrDefault("RulePriorities")
  valid_614421 = validateParameter(valid_614421, JArray, required = true, default = nil)
  if valid_614421 != nil:
    section.add "RulePriorities", valid_614421
  var valid_614422 = query.getOrDefault("Action")
  valid_614422 = validateParameter(valid_614422, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_614422 != nil:
    section.add "Action", valid_614422
  var valid_614423 = query.getOrDefault("Version")
  valid_614423 = validateParameter(valid_614423, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614423 != nil:
    section.add "Version", valid_614423
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614424 = header.getOrDefault("X-Amz-Signature")
  valid_614424 = validateParameter(valid_614424, JString, required = false,
                                 default = nil)
  if valid_614424 != nil:
    section.add "X-Amz-Signature", valid_614424
  var valid_614425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614425 = validateParameter(valid_614425, JString, required = false,
                                 default = nil)
  if valid_614425 != nil:
    section.add "X-Amz-Content-Sha256", valid_614425
  var valid_614426 = header.getOrDefault("X-Amz-Date")
  valid_614426 = validateParameter(valid_614426, JString, required = false,
                                 default = nil)
  if valid_614426 != nil:
    section.add "X-Amz-Date", valid_614426
  var valid_614427 = header.getOrDefault("X-Amz-Credential")
  valid_614427 = validateParameter(valid_614427, JString, required = false,
                                 default = nil)
  if valid_614427 != nil:
    section.add "X-Amz-Credential", valid_614427
  var valid_614428 = header.getOrDefault("X-Amz-Security-Token")
  valid_614428 = validateParameter(valid_614428, JString, required = false,
                                 default = nil)
  if valid_614428 != nil:
    section.add "X-Amz-Security-Token", valid_614428
  var valid_614429 = header.getOrDefault("X-Amz-Algorithm")
  valid_614429 = validateParameter(valid_614429, JString, required = false,
                                 default = nil)
  if valid_614429 != nil:
    section.add "X-Amz-Algorithm", valid_614429
  var valid_614430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614430 = validateParameter(valid_614430, JString, required = false,
                                 default = nil)
  if valid_614430 != nil:
    section.add "X-Amz-SignedHeaders", valid_614430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614431: Call_GetSetRulePriorities_614418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_614431.validator(path, query, header, formData, body)
  let scheme = call_614431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614431.url(scheme.get, call_614431.host, call_614431.base,
                         call_614431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614431, url, valid)

proc call*(call_614432: Call_GetSetRulePriorities_614418; RulePriorities: JsonNode;
          Action: string = "SetRulePriorities"; Version: string = "2015-12-01"): Recallable =
  ## getSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614433 = newJObject()
  if RulePriorities != nil:
    query_614433.add "RulePriorities", RulePriorities
  add(query_614433, "Action", newJString(Action))
  add(query_614433, "Version", newJString(Version))
  result = call_614432.call(nil, query_614433, nil, nil, nil)

var getSetRulePriorities* = Call_GetSetRulePriorities_614418(
    name: "getSetRulePriorities", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities", validator: validate_GetSetRulePriorities_614419,
    base: "/", url: url_GetSetRulePriorities_614420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSecurityGroups_614468 = ref object of OpenApiRestCall_612658
proc url_PostSetSecurityGroups_614470(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetSecurityGroups_614469(path: JsonNode; query: JsonNode;
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
  var valid_614471 = query.getOrDefault("Action")
  valid_614471 = validateParameter(valid_614471, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_614471 != nil:
    section.add "Action", valid_614471
  var valid_614472 = query.getOrDefault("Version")
  valid_614472 = validateParameter(valid_614472, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614472 != nil:
    section.add "Version", valid_614472
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614473 = header.getOrDefault("X-Amz-Signature")
  valid_614473 = validateParameter(valid_614473, JString, required = false,
                                 default = nil)
  if valid_614473 != nil:
    section.add "X-Amz-Signature", valid_614473
  var valid_614474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614474 = validateParameter(valid_614474, JString, required = false,
                                 default = nil)
  if valid_614474 != nil:
    section.add "X-Amz-Content-Sha256", valid_614474
  var valid_614475 = header.getOrDefault("X-Amz-Date")
  valid_614475 = validateParameter(valid_614475, JString, required = false,
                                 default = nil)
  if valid_614475 != nil:
    section.add "X-Amz-Date", valid_614475
  var valid_614476 = header.getOrDefault("X-Amz-Credential")
  valid_614476 = validateParameter(valid_614476, JString, required = false,
                                 default = nil)
  if valid_614476 != nil:
    section.add "X-Amz-Credential", valid_614476
  var valid_614477 = header.getOrDefault("X-Amz-Security-Token")
  valid_614477 = validateParameter(valid_614477, JString, required = false,
                                 default = nil)
  if valid_614477 != nil:
    section.add "X-Amz-Security-Token", valid_614477
  var valid_614478 = header.getOrDefault("X-Amz-Algorithm")
  valid_614478 = validateParameter(valid_614478, JString, required = false,
                                 default = nil)
  if valid_614478 != nil:
    section.add "X-Amz-Algorithm", valid_614478
  var valid_614479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614479 = validateParameter(valid_614479, JString, required = false,
                                 default = nil)
  if valid_614479 != nil:
    section.add "X-Amz-SignedHeaders", valid_614479
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_614480 = formData.getOrDefault("SecurityGroups")
  valid_614480 = validateParameter(valid_614480, JArray, required = true, default = nil)
  if valid_614480 != nil:
    section.add "SecurityGroups", valid_614480
  var valid_614481 = formData.getOrDefault("LoadBalancerArn")
  valid_614481 = validateParameter(valid_614481, JString, required = true,
                                 default = nil)
  if valid_614481 != nil:
    section.add "LoadBalancerArn", valid_614481
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614482: Call_PostSetSecurityGroups_614468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_614482.validator(path, query, header, formData, body)
  let scheme = call_614482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614482.url(scheme.get, call_614482.host, call_614482.base,
                         call_614482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614482, url, valid)

proc call*(call_614483: Call_PostSetSecurityGroups_614468;
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
  var query_614484 = newJObject()
  var formData_614485 = newJObject()
  if SecurityGroups != nil:
    formData_614485.add "SecurityGroups", SecurityGroups
  add(query_614484, "Action", newJString(Action))
  add(query_614484, "Version", newJString(Version))
  add(formData_614485, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_614483.call(nil, query_614484, nil, formData_614485, nil)

var postSetSecurityGroups* = Call_PostSetSecurityGroups_614468(
    name: "postSetSecurityGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups",
    validator: validate_PostSetSecurityGroups_614469, base: "/",
    url: url_PostSetSecurityGroups_614470, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSecurityGroups_614451 = ref object of OpenApiRestCall_612658
proc url_GetSetSecurityGroups_614453(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetSecurityGroups_614452(path: JsonNode; query: JsonNode;
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
  var valid_614454 = query.getOrDefault("LoadBalancerArn")
  valid_614454 = validateParameter(valid_614454, JString, required = true,
                                 default = nil)
  if valid_614454 != nil:
    section.add "LoadBalancerArn", valid_614454
  var valid_614455 = query.getOrDefault("SecurityGroups")
  valid_614455 = validateParameter(valid_614455, JArray, required = true, default = nil)
  if valid_614455 != nil:
    section.add "SecurityGroups", valid_614455
  var valid_614456 = query.getOrDefault("Action")
  valid_614456 = validateParameter(valid_614456, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_614456 != nil:
    section.add "Action", valid_614456
  var valid_614457 = query.getOrDefault("Version")
  valid_614457 = validateParameter(valid_614457, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614457 != nil:
    section.add "Version", valid_614457
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614458 = header.getOrDefault("X-Amz-Signature")
  valid_614458 = validateParameter(valid_614458, JString, required = false,
                                 default = nil)
  if valid_614458 != nil:
    section.add "X-Amz-Signature", valid_614458
  var valid_614459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614459 = validateParameter(valid_614459, JString, required = false,
                                 default = nil)
  if valid_614459 != nil:
    section.add "X-Amz-Content-Sha256", valid_614459
  var valid_614460 = header.getOrDefault("X-Amz-Date")
  valid_614460 = validateParameter(valid_614460, JString, required = false,
                                 default = nil)
  if valid_614460 != nil:
    section.add "X-Amz-Date", valid_614460
  var valid_614461 = header.getOrDefault("X-Amz-Credential")
  valid_614461 = validateParameter(valid_614461, JString, required = false,
                                 default = nil)
  if valid_614461 != nil:
    section.add "X-Amz-Credential", valid_614461
  var valid_614462 = header.getOrDefault("X-Amz-Security-Token")
  valid_614462 = validateParameter(valid_614462, JString, required = false,
                                 default = nil)
  if valid_614462 != nil:
    section.add "X-Amz-Security-Token", valid_614462
  var valid_614463 = header.getOrDefault("X-Amz-Algorithm")
  valid_614463 = validateParameter(valid_614463, JString, required = false,
                                 default = nil)
  if valid_614463 != nil:
    section.add "X-Amz-Algorithm", valid_614463
  var valid_614464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614464 = validateParameter(valid_614464, JString, required = false,
                                 default = nil)
  if valid_614464 != nil:
    section.add "X-Amz-SignedHeaders", valid_614464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614465: Call_GetSetSecurityGroups_614451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_614465.validator(path, query, header, formData, body)
  let scheme = call_614465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614465.url(scheme.get, call_614465.host, call_614465.base,
                         call_614465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614465, url, valid)

proc call*(call_614466: Call_GetSetSecurityGroups_614451; LoadBalancerArn: string;
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
  var query_614467 = newJObject()
  add(query_614467, "LoadBalancerArn", newJString(LoadBalancerArn))
  if SecurityGroups != nil:
    query_614467.add "SecurityGroups", SecurityGroups
  add(query_614467, "Action", newJString(Action))
  add(query_614467, "Version", newJString(Version))
  result = call_614466.call(nil, query_614467, nil, nil, nil)

var getSetSecurityGroups* = Call_GetSetSecurityGroups_614451(
    name: "getSetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups", validator: validate_GetSetSecurityGroups_614452,
    base: "/", url: url_GetSetSecurityGroups_614453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubnets_614504 = ref object of OpenApiRestCall_612658
proc url_PostSetSubnets_614506(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetSubnets_614505(path: JsonNode; query: JsonNode;
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
  var valid_614507 = query.getOrDefault("Action")
  valid_614507 = validateParameter(valid_614507, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_614507 != nil:
    section.add "Action", valid_614507
  var valid_614508 = query.getOrDefault("Version")
  valid_614508 = validateParameter(valid_614508, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614508 != nil:
    section.add "Version", valid_614508
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614509 = header.getOrDefault("X-Amz-Signature")
  valid_614509 = validateParameter(valid_614509, JString, required = false,
                                 default = nil)
  if valid_614509 != nil:
    section.add "X-Amz-Signature", valid_614509
  var valid_614510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614510 = validateParameter(valid_614510, JString, required = false,
                                 default = nil)
  if valid_614510 != nil:
    section.add "X-Amz-Content-Sha256", valid_614510
  var valid_614511 = header.getOrDefault("X-Amz-Date")
  valid_614511 = validateParameter(valid_614511, JString, required = false,
                                 default = nil)
  if valid_614511 != nil:
    section.add "X-Amz-Date", valid_614511
  var valid_614512 = header.getOrDefault("X-Amz-Credential")
  valid_614512 = validateParameter(valid_614512, JString, required = false,
                                 default = nil)
  if valid_614512 != nil:
    section.add "X-Amz-Credential", valid_614512
  var valid_614513 = header.getOrDefault("X-Amz-Security-Token")
  valid_614513 = validateParameter(valid_614513, JString, required = false,
                                 default = nil)
  if valid_614513 != nil:
    section.add "X-Amz-Security-Token", valid_614513
  var valid_614514 = header.getOrDefault("X-Amz-Algorithm")
  valid_614514 = validateParameter(valid_614514, JString, required = false,
                                 default = nil)
  if valid_614514 != nil:
    section.add "X-Amz-Algorithm", valid_614514
  var valid_614515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614515 = validateParameter(valid_614515, JString, required = false,
                                 default = nil)
  if valid_614515 != nil:
    section.add "X-Amz-SignedHeaders", valid_614515
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. If you need static IP addresses for your internet-facing load balancer, you can specify one Elastic IP address per subnet. For internal load balancers, you can specify one private IP address per subnet from the IPv4 range of the subnet.</p>
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  var valid_614516 = formData.getOrDefault("Subnets")
  valid_614516 = validateParameter(valid_614516, JArray, required = false,
                                 default = nil)
  if valid_614516 != nil:
    section.add "Subnets", valid_614516
  var valid_614517 = formData.getOrDefault("SubnetMappings")
  valid_614517 = validateParameter(valid_614517, JArray, required = false,
                                 default = nil)
  if valid_614517 != nil:
    section.add "SubnetMappings", valid_614517
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_614518 = formData.getOrDefault("LoadBalancerArn")
  valid_614518 = validateParameter(valid_614518, JString, required = true,
                                 default = nil)
  if valid_614518 != nil:
    section.add "LoadBalancerArn", valid_614518
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614519: Call_PostSetSubnets_614504; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ## 
  let valid = call_614519.validator(path, query, header, formData, body)
  let scheme = call_614519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614519.url(scheme.get, call_614519.host, call_614519.base,
                         call_614519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614519, url, valid)

proc call*(call_614520: Call_PostSetSubnets_614504; LoadBalancerArn: string;
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
  var query_614521 = newJObject()
  var formData_614522 = newJObject()
  if Subnets != nil:
    formData_614522.add "Subnets", Subnets
  add(query_614521, "Action", newJString(Action))
  if SubnetMappings != nil:
    formData_614522.add "SubnetMappings", SubnetMappings
  add(query_614521, "Version", newJString(Version))
  add(formData_614522, "LoadBalancerArn", newJString(LoadBalancerArn))
  result = call_614520.call(nil, query_614521, nil, formData_614522, nil)

var postSetSubnets* = Call_PostSetSubnets_614504(name: "postSetSubnets",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_PostSetSubnets_614505,
    base: "/", url: url_PostSetSubnets_614506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubnets_614486 = ref object of OpenApiRestCall_612658
proc url_GetSetSubnets_614488(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetSubnets_614487(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614489 = query.getOrDefault("SubnetMappings")
  valid_614489 = validateParameter(valid_614489, JArray, required = false,
                                 default = nil)
  if valid_614489 != nil:
    section.add "SubnetMappings", valid_614489
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerArn` field"
  var valid_614490 = query.getOrDefault("LoadBalancerArn")
  valid_614490 = validateParameter(valid_614490, JString, required = true,
                                 default = nil)
  if valid_614490 != nil:
    section.add "LoadBalancerArn", valid_614490
  var valid_614491 = query.getOrDefault("Action")
  valid_614491 = validateParameter(valid_614491, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_614491 != nil:
    section.add "Action", valid_614491
  var valid_614492 = query.getOrDefault("Subnets")
  valid_614492 = validateParameter(valid_614492, JArray, required = false,
                                 default = nil)
  if valid_614492 != nil:
    section.add "Subnets", valid_614492
  var valid_614493 = query.getOrDefault("Version")
  valid_614493 = validateParameter(valid_614493, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_614493 != nil:
    section.add "Version", valid_614493
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614494 = header.getOrDefault("X-Amz-Signature")
  valid_614494 = validateParameter(valid_614494, JString, required = false,
                                 default = nil)
  if valid_614494 != nil:
    section.add "X-Amz-Signature", valid_614494
  var valid_614495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614495 = validateParameter(valid_614495, JString, required = false,
                                 default = nil)
  if valid_614495 != nil:
    section.add "X-Amz-Content-Sha256", valid_614495
  var valid_614496 = header.getOrDefault("X-Amz-Date")
  valid_614496 = validateParameter(valid_614496, JString, required = false,
                                 default = nil)
  if valid_614496 != nil:
    section.add "X-Amz-Date", valid_614496
  var valid_614497 = header.getOrDefault("X-Amz-Credential")
  valid_614497 = validateParameter(valid_614497, JString, required = false,
                                 default = nil)
  if valid_614497 != nil:
    section.add "X-Amz-Credential", valid_614497
  var valid_614498 = header.getOrDefault("X-Amz-Security-Token")
  valid_614498 = validateParameter(valid_614498, JString, required = false,
                                 default = nil)
  if valid_614498 != nil:
    section.add "X-Amz-Security-Token", valid_614498
  var valid_614499 = header.getOrDefault("X-Amz-Algorithm")
  valid_614499 = validateParameter(valid_614499, JString, required = false,
                                 default = nil)
  if valid_614499 != nil:
    section.add "X-Amz-Algorithm", valid_614499
  var valid_614500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614500 = validateParameter(valid_614500, JString, required = false,
                                 default = nil)
  if valid_614500 != nil:
    section.add "X-Amz-SignedHeaders", valid_614500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614501: Call_GetSetSubnets_614486; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zones for the specified public subnets for the specified load balancer. The specified subnets replace the previously enabled subnets.</p> <p>When you specify subnets for a Network Load Balancer, you must include all subnets that were enabled previously, with their existing configurations, plus any additional subnets.</p>
  ## 
  let valid = call_614501.validator(path, query, header, formData, body)
  let scheme = call_614501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614501.url(scheme.get, call_614501.host, call_614501.base,
                         call_614501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614501, url, valid)

proc call*(call_614502: Call_GetSetSubnets_614486; LoadBalancerArn: string;
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
  var query_614503 = newJObject()
  if SubnetMappings != nil:
    query_614503.add "SubnetMappings", SubnetMappings
  add(query_614503, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_614503, "Action", newJString(Action))
  if Subnets != nil:
    query_614503.add "Subnets", Subnets
  add(query_614503, "Version", newJString(Version))
  result = call_614502.call(nil, query_614503, nil, nil, nil)

var getSetSubnets* = Call_GetSetSubnets_614486(name: "getSetSubnets",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_GetSetSubnets_614487,
    base: "/", url: url_GetSetSubnets_614488, schemes: {Scheme.Https, Scheme.Http})
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
